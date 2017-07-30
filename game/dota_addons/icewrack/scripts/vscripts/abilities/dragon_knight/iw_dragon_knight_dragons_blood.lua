iw_dragon_knight_dragons_blood = class({})

function iw_dragon_knight_dragons_blood:OnSpellStart()
	local hEntity = self:GetCaster()
	local tModifierArgs =
	{
		health_regen = self:GetSpecialValueFor("health_regen") + self:GetSpecialValueFor("health_regen_bonus") * hEntity:GetSpellpower(),
		duration = self:GetSpecialValueFor("duration"),
	}
	hEntity:AddNewModifier(hEntity, self, "modifier_iw_dragon_knight_dragons_blood", tModifierArgs)
	EmitSoundOn("Hero_DragonKnight.DragonsBlood", hEntity)
end