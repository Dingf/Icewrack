if IsServer() and not modifier_internal_attack then

require("ext_entity")
require("ext_item")
require("npc")
require("mechanics/accuracy")

local shMissModifier = CreateItem("internal_miss_debuff", nil, nil)

modifier_internal_attack = class({})
modifier_internal_attack._tDeclareFunctionList =
{
	MODIFIER_PROPERTY_ATTACK_RANGE_BONUS
}

function modifier_internal_attack:GetModifierAttackRangeBonus(args)
	local hEntity = self:GetParent()
	if IsValidExtendedEntity(hEntity) then
		local _, hAttackSource = next(hEntity._tAttackSourceTable)
		if hAttackSource then
			return hAttackSource:GetBasePropertyValue(IW_PROPERTY_ATTACK_RANGE)
		else
			return hEntity:GetBasePropertyValue(IW_PROPERTY_ATTACK_RANGE)
		end
	end
	return 0
end

function OnAttack(self, keys)
	local hEntity = keys.entity
	local hTarget = keys.target
	if IsValidExtendedEntity(hEntity) and IsValidExtendedEntity(hTarget) then
		local hSource = table.remove(hEntity._tAttackSourceTable, 1)
		if not hSource then
			hSource = hEntity
		else
			table.insert(hEntity._tAttackSourceTable, hSource)
			_, hSource = next(hEntity._tAttackSourceTable)
			hEntity:RefreshEntity()	
		end
		
		local fAttackCost = hSource:GetBasePropertyValue(IW_PROPERTY_ATTACK_SP_FLAT) * (hEntity:GetFatigueMultiplier() + hSource:GetPropertyValue(IW_PROPERTY_ATTACK_SP_PCT)/100.0)
		hEntity:SpendStamina(fAttackCost)
		
		local fBaseAttackTime = hSource:GetBasePropertyValue(IW_PROPERTY_BASE_ATTACK_TIME)
		if #hEntity._tAttackSourceTable >= 2 then	--Increased BAT while dualwielding
			fBaseAttackTime = fBaseAttackTime * 0.5
		end
		if fBaseAttackTime > 0 then
			hEntity:SetBaseAttackTime(fBaseAttackTime)
		end
	end
end

function OnAttackStart(self, keys)
	local hTarget = keys.target
	local hAttacker = keys.attacker
	if IsValidExtendedEntity(hTarget) and IsValidExtendedEntity(hAttacker) then
		hAttacker:SetAttacking(hTarget)
		local fBonusAccuracy = keys.BonusAccuracy or 0
		if not PerformAccuracyCheck(hTarget, hAttacker, fBonusAccuracy) then
			shMissModifier:ApplyDataDrivenModifier(hAttacker, hAttacker, "modifier_internal_miss_debuff", {})
		else
			hAttacker:RemoveModifierByName("modifier_internal_miss_debuff")
		end
	end
end

end