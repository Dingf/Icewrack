if IsServer() and not modifier_internal_attack then

require("ext_entity")
require("ext_item")
require("interactable")
require("npc")
require("mechanics/accuracy")

local shMissModifier = CreateItem("internal_miss_debuff", nil, nil)

modifier_internal_attack = class({})
function modifier_internal_attack:DeclareFunctions()
	local funcs =
	{
		MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
		MODIFIER_EVENT_ON_ATTACK,
		MODIFIER_EVENT_ON_ATTACK_START,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_EVENT_ON_ATTACK_FAIL,
	}
	return funcs
end

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

function modifier_internal_attack:OnRefresh()
	local hEntity = self:GetParent()
	if bit32.band(hEntity:GetUnitFlags(), IW_UNIT_FLAG_REQ_ATTACK_SOURCE) ~= 0 then
		local hAttackSource = hEntity:GetCurrentAttackSource()
		local bIsDisarmed = hEntity:HasModifier("modifier_internal_attack_disarm")
		if not hAttackSource and not bIsDisarmed then
			local hAbility = self:GetAbility()
			hEntity:AddNewModifier(hEntity, hAbility, "modifier_internal_attack_disarm", {})
		elseif hAttackSource and bIsDisarmed then
			hEntity:RemoveModifierByName("modifier_internal_attack_disarm")
		end
	end
end

function modifier_internal_attack:OnAttack(keys)
	local hEntity = keys.attacker
	local hTarget = keys.target
	if hEntity == self:GetParent() and IsValidExtendedEntity(hEntity) and IsValidExtendedEntity(hTarget) then
		local hAttackSource = hEntity:GetCurrentAttackSource(true) or hEntity
		hEntity:RefreshEntity()
		
		hEntity:SetHealth(hEntity:GetHealth() - hAttackSource:GetAttackHealthCost())
		hEntity:SetMana(hEntity:GetMana() - hAttackSource:GetAttackManaCost())
		hEntity:SpendStamina(hAttackSource:GetAttackStaminaCost())
		
		hEntity:Stop()
		hEntity:IssueOrder(DOTA_UNIT_ORDER_ATTACK_TARGET, hTarget, nil, nil, false)
		hEntity:TriggerExtendedEvent(IW_MODIFIER_EVENT_ON_ATTACK_EVENT_START)
		
		table.insert(hEntity._tAttackQueue, hAttackSource)
	end
end


function modifier_internal_attack:OnAttackStart(keys)
	local hEntity = keys.attacker
	local hTarget = keys.target
	if hEntity == self:GetParent() and IsValidExtendedEntity(hTarget) and IsValidExtendedEntity(hEntity) and not hTarget:IsCorpse() then
		if not hEntity:CanPayAttackCosts() then
			hEntity:Stop()
			hEntity:IssueOrder(DOTA_UNIT_ORDER_ATTACK_TARGET, hTarget, nil, nil, false)
		elseif not hEntity:IsTargetInLOS(hTarget) then
			hEntity:Stop()
			hEntity:IssueOrder(DOTA_UNIT_ORDER_ATTACK_TARGET, hTarget, nil, nil, false)
		else
			hEntity:SetAttacking(hTarget)
			local fBonusAccuracy = keys.BonusAccuracy or 0
			if not PerformAccuracyCheck(hTarget, hEntity, fBonusAccuracy) then
				shMissModifier:ApplyDataDrivenModifier(hEntity, hEntity, "modifier_internal_miss_debuff", {})
				hTarget:TriggerExtendedEvent(IW_MODIFIER_EVENT_ON_DODGE_ATTACK, keys)
			else
				hEntity:RemoveModifierByName("modifier_internal_miss_debuff")
			end
			hEntity:TriggerExtendedEvent(IW_MODIFIER_EVENT_ON_PRE_ATTACK_EVENT)
		end
	end
end

function modifier_internal_attack:OnAttackLanded(keys)
	local hEntity = keys.attacker
	local hTarget = keys.target
	if hEntity == self:GetParent() and IsValidExtendedEntity(hTarget) and IsValidExtendedEntity(hEntity) then
		keys.Percent = 100
		_,keys.source = next(hEntity._tAttackQueue)
		DealAttackDamage(self, keys)
		table.remove(hEntity._tAttackQueue, 1)
	end
end

function modifier_internal_attack:OnAttackFail(keys)
	local hEntity = keys.attacker
	if hEntity == self:GetParent() and IsValidExtendedEntity(hEntity) then
		table.remove(hEntity._tAttackQueue, 1)
	end
end

end