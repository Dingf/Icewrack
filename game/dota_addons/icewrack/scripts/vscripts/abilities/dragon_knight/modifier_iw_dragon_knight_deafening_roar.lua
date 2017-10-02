modifier_iw_dragon_knight_deafening_roar = class({})

function modifier_iw_dragon_knight_deafening_roar:OnCreated(args)
	--if IsServer() then
		local fDuration = self:GetDuration()
		self:StartIntervalThink(fDuration/8)
	--end
end

function modifier_iw_dragon_knight_deafening_roar:OnIntervalThink()
	local hEntity = self:GetParent()
	local fEffectBonus = self:GetAbility():GetSpecialValueFor("effect_bonus")
	self._tModifierArgs["move_speed"] = self._tModifierArgs["move_speed"] + fEffectBonus
	self._tModifierArgs["attack_speed"] = self._tModifierArgs["attack_speed"] + fEffectBonus
	self:BuildTextureArgsString()
	if IsServer() then
		hEntity:RefreshEntity()
	end
end