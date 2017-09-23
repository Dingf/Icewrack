iw_lina_inner_fire = class({})

function iw_lina_inner_fire:OnSpellStart()
	local hEntity = self:GetCaster()
	local hTarget = self:GetCursorTarget()
	local tModifierArgs =
	{
		attack_speed = self:GetSpecialValueFor("attack_speed") + self:GetSpecialValueFor("attack_speed_bonus") * hEntity:GetSpellpower(),
		stamina_regen_pct = self:GetSpecialValueFor("stamina_regen_pct") + self:GetSpecialValueFor("stamina_regen_pct_bonus") * hEntity:GetSpellpower(),
		stamina_regen = self:GetSpecialValueFor("stamina_regen"),
		duration = self:GetSpecialValueFor("duration"),
	}
	hTarget:AddNewModifier(hEntity, self, "modifier_iw_lina_inner_fire", tModifierArgs)
	EmitSoundOn("Hero_Lina.InnerFire", hTarget)
end