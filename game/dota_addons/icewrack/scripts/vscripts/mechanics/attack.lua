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
		local hAttackSource = hEntity:GetCurrentAttackSource()
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
		local hAttackSource = hEntity:GetCurrentAttackSource(true)
		if not hAttackSource then
			hAttackSource = hEntity
		else
			hEntity:RefreshEntity()	
		end
		
		local fAttackCost = hAttackSource:GetBasePropertyValue(IW_PROPERTY_ATTACK_SP_FLAT) * (hEntity:GetFatigueMultiplier() + hAttackSource:GetPropertyValue(IW_PROPERTY_ATTACK_SP_PCT)/100.0)
		hEntity:SpendStamina(fAttackCost)
		hEntity:Stop()
		hEntity:IssueOrder(DOTA_UNIT_ORDER_ATTACK_TARGET, hTarget, nil, nil, false)
	end
end

function OnAttackStart(self, keys)
	local hTarget = keys.target
	local hAttacker = keys.attacker
	if IsValidExtendedEntity(hTarget) and IsValidExtendedEntity(hAttacker) then
		if not hAttacker:IsTargetInLOS(hTarget) then
			hAttacker:Stop()
			hAttacker:IssueOrder(DOTA_UNIT_ORDER_ATTACK_TARGET, hTarget, nil, nil, false)
		else
			hAttacker:SetAttacking(hTarget)
			local fBonusAccuracy = keys.BonusAccuracy or 0
			if not PerformAccuracyCheck(hTarget, hAttacker, fBonusAccuracy) then
				shMissModifier:ApplyDataDrivenModifier(hAttacker, hAttacker, "modifier_internal_miss_debuff", {})
				hTarget:TriggerExtendedEvent(IW_MODIFIER_EVENT_ON_DODGE_ATTACK, keys)
			else
				hAttacker:RemoveModifierByName("modifier_internal_miss_debuff")
			end
		end
	end
end

end