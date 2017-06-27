modifier_iw_lina_warmth = class({})

function modifier_iw_lina_warmth:OnCreated(args)
	if IsServer() then
		local hEntity = self:GetParent()
		local hParentModifier = self:GetCaster():FindModifierByName("modifier_iw_lina_warmth_caster")
		self:SetPropertyValue(IW_PROPERTY_MP_REGEN_PCT, hParentModifier:GetBasePropertyValue(IW_PROPERTY_MP_REGEN_PCT))
		self:SetPropertyValue(IW_PROPERTY_RESIST_COLD, hParentModifier:GetBasePropertyValue(IW_PROPERTY_RESIST_COLD))
		hEntity:DispelModifiers(IW_STATUS_MASK_FREEZE + IW_STATUS_MASK_CHILL + IW_STATUS_MASK_WET)
	else
		local hAbility = self:GetAbility()
		self._szTextureArgsString = hAbility._hParentModifier._szTextureArgsString
	end
end