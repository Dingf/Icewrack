iw_lina_warmth = class({})

function iw_lina_warmth:OnSpellStart()
	local hEntity = self:GetCaster()
	local fDuration = self:GetSpecialValueFor("duration")
	local tModifierArgs =
	{
		mana_regen = self:GetSpecialValueFor("mana_regen") + (hEntity:GetSpellpower() * self:GetSpecialValueFor("mana_regen_bonus")),
		cold_resist = self:GetSpecialValueFor("cold_resist") + (hEntity:GetSpellpower() * self:GetSpecialValueFor("cold_resist_bonus")),
		duration = fDuration,
	}
	
	hEntity:RemoveModifierByName("modifier_iw_lina_warmth")
	hEntity:AddNewModifier(hEntity, self, "modifier_iw_lina_warmth_caster", tModifierArgs)
		
	EmitSoundOn("Hero_Lina.Warmth", hEntity)
end