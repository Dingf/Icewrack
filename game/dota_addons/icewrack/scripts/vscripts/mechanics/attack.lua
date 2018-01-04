if IsServer() and not modifier_internal_attack then

require("ext_entity")
require("ext_item")
--require("interactable")
require("mechanics/accuracy")

local shMissModifier = CreateItem("item_internal_miss_debuff", nil, nil)

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
	if bit32.btest(hEntity:GetUnitFlags(), IW_UNIT_FLAG_REQ_ATTACK_SOURCE) then
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
		local fHealthCost  = math.max(0, hAttackSource:GetBasePropertyValue(IW_PROPERTY_ATTACK_HP_FLAT) * (1.0 + hEntity:GetPropertyValue(IW_PROPERTY_HP_COST_PCT)/100.0))
		local fManaCost    = math.max(0, hAttackSource:GetBasePropertyValue(IW_PROPERTY_ATTACK_MP_FLAT) * (1.0 + hEntity:GetPropertyValue(IW_PROPERTY_MP_COST_PCT)/100.0))
		local fStaminaCost = math.max(0, hAttackSource:GetBasePropertyValue(IW_PROPERTY_ATTACK_SP_FLAT) * (1.0 + hEntity:GetPropertyValue(IW_PROPERTY_SP_COST_PCT)/100.0))
		
		hEntity:SetHealth(hEntity:GetHealth() - fHealthCost)
		hEntity:SetMana(hEntity:GetMana() - fManaCost)
		hEntity:SpendStamina(fStaminaCost)
		
		hEntity:Stop()
		hEntity:IssueOrder(DOTA_UNIT_ORDER_ATTACK_TARGET, hTarget, nil, nil, false)
		hEntity:TriggerExtendedEvent(IW_MODIFIER_EVENT_ON_ATTACK_EVENT_START)
		hEntity:RefreshEntity()
		
		table.insert(hEntity._tAttackQueue, hAttackSource)
	end
end


function modifier_internal_attack:OnAttackStart(keys)
	local hEntity = keys.attacker
	local hTarget = keys.target
	if hEntity == self:GetParent() and IsValidExtendedEntity(hEntity) then
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
	if hEntity == self:GetParent() and IsInstanceOf(hTarget, CEntityBase) and IsValidExtendedEntity(hEntity) then
		keys.Percent = 100
		_,keys.source = next(hEntity._tAttackQueue)
		DealAttackDamage(self, keys)
		if not hEntity:IsTargetEnemy(hTarget) and not hTarget:IsControllableByAnyPlayer() then
			local nFactionWeight = hTarget:GetPlayerFactionWeight()
			hTarget:SetOverrideFactionWeight(IW_PLAYER_FACTION, nFactionWeight - 20.0)
		end
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