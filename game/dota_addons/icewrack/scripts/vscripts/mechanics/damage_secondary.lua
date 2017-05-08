--[[
    Icewrack Damage
	
	Primary damage is damage from direct hits, and can be blocked, resisted, crit, and triggers any and all on damage effects on both the victim
	and the attacker.
	
	Secondary damage is damage from status effects and damage over time abilities, and can only be resisted. It cannot be blocked, crit, and will
	not trigger on damage/kill effects on both the victim and the attacker.
	
	Attack damage is a subset of primary damage. It benefits from strength and can be dodged unless otherwise specified.
]]

require("mechanics/damage_types")
require("ext_entity")

function DealSecondaryDamage(self, keys)
	local hVictim = keys.target
	local hAttacker = keys.attacker
	local hSource = keys.source or hAttacker
	if not hVictim or not hVictim:IsAlive() or hVictim:IsInvulnerable() then
		return false
	end
	if IsValidExtendedEntity(hVictim) and IsValidExtendedEntity(hAttacker) then
		local bDamageResult = false
		for k,v in pairs(stIcewrackDamageTypeEnum) do
			local nDamageType = v
			local fDamageAmount = 0
			if keys.damage and keys.damage[nDamageType] then
				fDamageAmount = RandomFloat(keys.damage[nDamageType].min, keys.damage[nDamageType].max)
				fDamageAmount = fDamageAmount * hSource:GetDamageModifier(nDamageType)
				fDamageAmount = fDamageAmount * hVictim:GetDamageEffectiveness()
				if nDamageType ~= IW_DAMAGE_TYPE_PURE then
					local fDamageResistMax = hVictim:GetMaxResistance(nDamageType)
					local fDamageResist = hVictim:GetResistance(nDamageType)
					fDamageResist = math.min(1.0, fDamageResist, fDamageResistMax)
					fDamageAmount =  math.max(0, fDamageAmount * (1.0 - fDamageResist))
				end
				fDamageAmount = math.max(0, math.floor(fDamageAmount))
				if fDamageAmount > 0 then
					hVictim:ModifyHealth(hVictim:GetHealth() - fDamageAmount, hAttacker, true, 0)
					bDamageResult = true
				end
			end
		end
		return bDamageResult
	end
	return false
end