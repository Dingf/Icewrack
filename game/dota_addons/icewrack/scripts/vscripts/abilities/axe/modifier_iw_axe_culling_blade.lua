modifier_iw_axe_culling_blade = class({})

function modifier_iw_axe_culling_blade:DeclareExtEvents()
	local funcs =
	{
		[IW_MODIFIER_EVENT_ON_POST_ATTACK_DAMAGE] = 10,
	}
	return funcs
end

function modifier_iw_axe_culling_blade:OnPostAttackDamage(args)
	local hTarget = args.target
	local hEntity = self:GetParent()
	if IsValidExtendedEntity(hTarget) and hEntity and args.result then
		local hAbility = self:GetAbility()
		local nUnitClass = hTarget:GetUnitClass()
		local fThreshold = hAbility:GetSpecialValueFor("threshold")/100.0
		if nUnitClass == IW_UNIT_CLASS_ELITE then
			fThreshold = hAbility:GetSpecialValueFor("threshold_elite")/100.0
		elseif nUnitClass == IW_UNIT_CLASS_BOSS or nUnitClass == IW_UNIT_CLASS_ACT_BOSS then
			fThreshold = hAbility:GetSpecialValueFor("threshold_boss")/100.0
		end
		local fTargetHealth = hTarget:GetHealth()/hTarget:GetMaxHealth()
		if fTargetHealth < fThreshold then
			hTarget:ModifyHealth(0, hEntity, true, 0)
		end
	end
end
