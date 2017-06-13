iw_lina_pyrotheosis = class({})

function iw_lina_pyrotheosis:OnSpellStart()
	local hEntity = self:GetCaster()
	local tModifierArgs =
	{
		fire_damage = self:GetSpecialValueFor("lifesteal"),
		duration = self:GetSpecialValueFor("duration"),
	}
	hEntity:AddNewModifier(hEntity, self, "modifier_iw_lina_pyrotheosis", tModifierArgs)
end