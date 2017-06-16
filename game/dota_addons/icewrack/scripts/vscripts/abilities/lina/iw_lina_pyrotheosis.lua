iw_lina_pyrotheosis = class({})

function iw_lina_pyrotheosis:OnSpellStart()
	local hEntity = self:GetCaster()
	local tModifierArgs =
	{
		fire_damage = self:GetSpecialValueFor("fire_damage"),
		duration = self:GetSpecialValueFor("duration"),
	}
	hEntity:AddNewModifier(hEntity, self, "modifier_iw_lina_pyrotheosis", tModifierArgs)
	EmitSoundOn("Hero_Lina.Pyrotheosis", hEntity)
	EmitSoundOn("Hero_Lina.Pyrotheosis.Loop", hEntity)
end