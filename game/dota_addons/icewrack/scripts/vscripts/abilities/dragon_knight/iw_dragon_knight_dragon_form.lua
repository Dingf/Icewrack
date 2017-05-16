iw_dragon_knight_dragon_form = class({})

function iw_dragon_knight_dragon_form:OnSpellStart()
	local hEntity = self:GetCaster()
	
	if not self._hAttackSource then
		self._hAttackSource = CExtItem(CreateItem("iw_dragon_knight_dragon_form_source", nil, nil))
	end
	
	local tModifierArgs =
	{
		health_bonus = self:GetSpecialValueFor("health_bonus"),
		duration = self:GetSpecialValueFor("duration"),
		modelname = hEntity:GetModelName(),
	}
	hEntity:AddNewModifier(hEntity, self, "modifier_iw_dragon_knight_dragon_form", tModifierArgs)
end