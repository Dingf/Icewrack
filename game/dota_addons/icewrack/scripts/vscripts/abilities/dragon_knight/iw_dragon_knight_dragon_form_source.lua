iw_dragon_knight_dragon_form_source = class({})

function iw_dragon_knight_dragon_form_source:OnRefreshEntity()
	local hEntity = self:GetOwner()
	local hAbility = self._hParentAbility
	if hAbility and hEntity then
		local hBreatheFireAbility = hEntity:FindAbilityByName("iw_dragon_knight_breathe_fire")
		if hBreatheFireAbility then
			local fDamageMin = hBreatheFireAbility:GetSpecialValueFor("damage_min") + (hEntity:GetSpellpower() * hBreatheFireAbility:GetSpecialValueFor("damage_min_bonus"))
			local fDamageMax = hBreatheFireAbility:GetSpecialValueFor("damage_max") + (hEntity:GetSpellpower() * hBreatheFireAbility:GetSpecialValueFor("damage_max_bonus"))
			self:SetPropertyValue(IW_PROPERTY_DMG_FIRE_BASE, fDamageMin)
			self:SetPropertyValue(IW_PROPERTY_DMG_FIRE_VAR, fDamageMax - fDamageMin)
			self:UpdateItemNetTable()
		end
	end
end