modifier_iw_lina_pyrotheosis = class({})

function modifier_iw_lina_pyrotheosis:DeclareExtEvents()
	local funcs =
	{
		[IW_MODIFIER_EVENT_ON_POST_ABILITY_CAST] = 10,
	}
	return funcs
end

function modifier_iw_lina_pyrotheosis:OnPostAbilityCast(hAbility)
	local hParentAbility = self:GetAbility()
	if hAbility:IsSkillRequired(IW_SKILL_FIRE) and hAbility ~= hParentAbility then
		hAbility:EndCooldown()
	end
end