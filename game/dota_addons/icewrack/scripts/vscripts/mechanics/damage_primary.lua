--[[
    Icewrack Damage
	
	Primary damage is damage from direct hits, and can be blocked, resisted, crit, and triggers any and all on damage effects on both the victim
	and the attacker.
	
	Secondary damage is damage from status effects and damage over time abilities, and can only be resisted. It cannot be blocked, crit, and will
	not trigger on damage/kill effects on both the victim and the attacker.
	
	Attack damage is a subset of primary damage. It benefits from strength and can be dodged unless otherwise specified.
]]

require("mechanics/accuracy")
require("mechanics/combat")
require("mechanics/damage_types")
require("mechanics/effect_bash")
require("mechanics/effect_maim")
require("mechanics/effect_bleed")
require("mechanics/effect_burning")
require("mechanics/effect_chill")
require("mechanics/effect_shock")
require("mechanics/effect_weaken")
require("mechanics/effect_lifesteal")
require("mechanics/effect_manashield")
require("mechanics/effect_secondwind")
require("visuals/msg_fx")
require("ext_entity")
require("npc")

local stDamageInfoTable = {}
local stFriendlyFireMultipliers = { 0.0, 0.5, 1.0, 1.0 }

local function ApplyDamageEffect(hVictim, hAttacker, nDamageType, fDamage, fEffectBonus)
	local fEffectiveDamage = fDamage * (1.0 + fEffectBonus)
	local fDamagePercentHP = math.min(1.0, (math.max(fEffectiveDamage/hVictim:GetMaxHealth(), 0)))
	if nDamageType == IW_DAMAGE_TYPE_CRUSH then
		ApplyBash(hVictim, hAttacker, fDamagePercentHP)
	elseif nDamageType == IW_DAMAGE_TYPE_SLASH then
		ApplyMaim(hVictim, hAttacker, fDamagePercentHP)
	elseif nDamageType == IW_DAMAGE_TYPE_PIERCE then
		ApplyBleed(hVictim, hAttacker, fEffectiveDamage)
	elseif nDamageType == IW_DAMAGE_TYPE_FIRE then
		ApplyBurning(hVictim, hAttacker)
	elseif nDamageType == IW_DAMAGE_TYPE_COLD then
		ApplyChill(hVictim, hAttacker, fDamagePercentHP)
	elseif nDamageType == IW_DAMAGE_TYPE_LIGHTNING then
		ApplyShock(hVictim, hAttacker)
	elseif nDamageType == IW_DAMAGE_TYPE_DEATH then
		ApplyWeaken(hVictim, hAttacker, fDamagePercentHP)
	end
end


function DealPrimaryDamage(self, keys)
	local hVictim = keys.target
	local hAttacker = keys.attacker
	local hSource = keys.source or hAttacker
	if IsValidExtendedEntity(hVictim) and IsValidExtendedEntity(hAttacker) and hVictim:IsAlive() and not hVictim:IsInvulnerable() then
	
		--TODO: Add pre-damage effects here
		
		local bIsCrit = false
		local bDamageResult = false
		local fCritChance = hSource:GetCriticalStrikeChance()
		if RandomFloat(0.0, 1.0) < fCritChance and RandomFloat(0.0, 1.0) > hVictim:GetCriticalStrikeAvoidance() then
			bIsCrit = true
		end
		
		local fTotalDamage = 0
		stDamageInfoTable.attacker = hAttacker:entindex()
		stDamageInfoTable.victim = hVictim:entindex()
		stDamageInfoTable.crit = bIsCrit
		for k,v in pairs(stIcewrackDamageTypeEnum) do
			local nDamageType = v
			local fDamageAmount = 0
			if keys.damage and keys.damage[nDamageType] then
				fDamageAmount = RandomFloat(keys.damage[nDamageType].min, keys.damage[nDamageType].max)
				fDamageAmount = fDamageAmount * hSource:GetDamageModifier(nDamageType)
				fDamageAmount = fDamageAmount * hVictim:GetDamageEffectiveness()
				
				if nDamageType >= IW_DAMAGE_TYPE_CRUSH and nDamageType <= IW_DAMAGE_TYPE_PIERCE then
					local fArmor = hVictim:GetArmor(nDamageType)
					local fArmorIgnore = hSource:GetPropertyValue(IW_PROPERTY_IGNORE_ARMOR_FLAT) + (fArmor * hSource:GetPropertyValue(IW_PROPERTY_IGNORE_ARMOR_PCT)/100.0)
					fDamageAmount = math.max(0, fDamageAmount - math.max(0, fArmor - fArmorIgnore))
				end
				if nDamageType ~= IW_DAMAGE_TYPE_PURE then
					local fDamageResistMax = hVictim:GetMaxResistance(nDamageType)
					local fDamageResist = hVictim:GetResistance(nDamageType)
					fDamageResist = math.min(1.0, fDamageResist, fDamageResistMax)
					fDamageAmount =  math.max(0, fDamageAmount * (1.0 - fDamageResist))
				end
			end
			if hAttacker:GetTeamNumber() == hVictim:GetTeamNumber() then
				fDamageAmount = fDamageAmount * stFriendlyFireMultipliers[GameRules:GetCustomGameDifficulty()]
			end
			
			stDamageInfoTable[nDamageType] = fDamageAmount
			fTotalDamage = fTotalDamage + fDamageAmount
		end
		
		if fTotalDamage < 0 then
			return false
		end
		
		--TODO: Add on damage effects here
		
		for k,v in pairs(stIcewrackDamageTypeEnum) do
			local nDamageType = v
			local fDamageAmount = stDamageInfoTable[nDamageType]
			
			if bIsCrit then
				fDamageAmount = fDamageAmount * (1.0 + hSource:GetCriticalStrikeMultiplier())
				ShowDamageMessage(hVictim, nDamageType, fDamageAmount)
			end
			
			fDamageAmount = ApplyManaShield(hAttacker, hVictim, fDamageAmount)
			fDamageAmount = ApplySecondWind(hAttacker, hVictim, fDamageAmount)
			fDamageAmount = ApplyLifesteal(hAttacker, hVictim, fDamageAmount)
			
			if fDamageAmount > 0 then
				if nDamageType ~= IW_DAMAGE_TYPE_PURE then
					local fDamageEffectChance = hSource:GetDamageEffectChance(nDamageType)
					if bIsCrit then fDamageEffectChance = fDamageEffectChance + 1.0 end
					if RandomFloat(0.0, 1.0) <= fDamageEffectChance and RandomFloat(0.0, 1.0) > hVictim:GetDamageEffectAvoidance(nDamageType) then
						local fEffectBonus = keys.DamageEffectBonus or 0.0
						ApplyDamageEffect(hVictim, hAttacker, nDamageType, fDamageAmount, fEffectBonus)
					end
				end
				
				local fBonusThreat = keys.BonusThreat or 0.0
				local hVictimHealth = hVictim:GetHealth()
				fDamageAmount = math.max(0, math.floor(fDamageAmount))
				
				if IsValidNPCEntity(hVictim) then
					hVictim:DetectEntity(hAttacker, IW_COMBAT_LINGER_TIME)
					hVictim:AddThreat(hAttacker, fDamageAmount + fBonusThreat, true)
				end
				hVictim:ModifyHealth(math.max(0, hVictim:GetHealth() - fDamageAmount), hAttacker, true, 0)
				hVictim:SpendStamina(0)
				bDamageResult = true
			end
		end
		
		if bDamageResult then
			--TODO: Add post damage effects here
		end
		return bDamageResult
	end
	return false
end

function DealAttackDamage(self, keys)
	local hVictim = keys.target
	local hAttacker = keys.attacker
	if IsValidExtendedEntity(hVictim) and IsValidExtendedEntity(hAttacker) and hVictim:IsAlive() then
		local bIsUnarmed = false
		local _,hSource = next(hAttacker._tAttackSourceTable)
		if not hSource then
			hSource = hAttacker
			bIsUnarmed = true
		end
		keys.source = hSource
		
		local fTotalDamage = 0
		local fDamagePercent = (keys.Percent or 100)/100.0
		keys.damage = {}
		for k,v in pairs(stIcewrackDamageTypeEnum) do
			local fMinDamage = (bIsUnarmed and hSource:GetDamageMin(v) or hSource:GetBaseDamageMin(v)) * fDamagePercent
			local fMaxDamage = (bIsUnarmed and hSource:GetDamageMax(v) or hSource:GetBaseDamageMax(v)) * fDamagePercent
			--Strength bonus physical attack damage
			if v >= IW_DAMAGE_TYPE_CRUSH and v <= IW_DAMAGE_TYPE_PIERCE then
				fMinDamage = fMinDamage * (1.0 + hAttacker:GetAttributeValue(IW_ATTRIBUTE_STRENGTH)/100.0)
				fMaxDamage = fMaxDamage * (1.0 + hAttacker:GetAttributeValue(IW_ATTRIBUTE_STRENGTH)/100.0)
			end
			fTotalDamage = fTotalDamage + (fMinDamage + fMaxDamage)/2.0
			
			keys.damage[v] = {}
			keys.damage[v].min = fMinDamage
			keys.damage[v].max = fMaxDamage
		end
		
		if keys.CanDodge then
			local fBonusAccuracy = keys.BonusAccuracy or 0
			if not PerformAccuracyCheck(hVictim, hAttacker, fBonusAccuracy) then
				hVictim:DetectEntity(hAttacker, IW_COMBAT_LINGER_TIME)
				hVictim:AddThreat(hAttacker, fTotalDamage * 0.25, true)
				ShowMissMessage(hAttacker)
				return 0
			end
		end
		return DealPrimaryDamage(self, keys)
	end
	return false
end