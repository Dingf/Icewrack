modifier_iw_lina_pyrotheosis_cooldown = class({})

function modifier_iw_lina_pyrotheosis_cooldown:DeclareExtEvents()
	local funcs =
	{
		[IW_MODIFIER_EVENT_ON_POST_ABILITY_CAST] = 1,
	}
	return funcs
end

function modifier_iw_lina_pyrotheosis_cooldown:OnPostAbilityCast(hAbility)
	if hAbility:IsSkillRequired(IW_SKILL_FIRE) then
		local hParentAbility = self:GetAbility()
		local fCooldownReduction = hParentAbility:GetSpecialValueFor("cooldown_reduction")
		local fCooldownRemaining = hParentAbility:GetCooldownTimeRemaining()
		
		hParentAbility:EndCooldown()
		if fCooldownRemaining > fCooldownReduction then
			hParentAbility:StartCooldown(fCooldownRemaining - fCooldownReduction)
		end
	end
end