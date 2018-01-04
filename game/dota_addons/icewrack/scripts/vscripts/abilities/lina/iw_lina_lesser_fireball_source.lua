iw_lina_lesser_fireball_source = class({})

function iw_lina_lesser_fireball_source:OnRefreshEntity()
	local hEntity = self:GetOwner()
	local hAbility = self._hParentAbility
	if hAbility and hEntity then
		local fDamageMin = hAbility:GetSpecialValueFor("damage_min") + (hEntity:GetSpellpower() * hAbility:GetSpecialValueFor("damage_min_bonus"))
		local fDamageMax = hAbility:GetSpecialValueFor("damage_max") + (hEntity:GetSpellpower() * hAbility:GetSpecialValueFor("damage_max_bonus"))
		self:SetPropertyValue(IW_PROPERTY_DMG_FIRE_BASE, fDamageMin)
		self:SetPropertyValue(IW_PROPERTY_DMG_FIRE_VAR, fDamageMax - fDamageMin)
		self:SetPropertyValue(IW_PROPERTY_ATTACK_MP_FLAT, hAbility:GetBaseManaCost())
		self:UpdateItemNetTable()
	end
end