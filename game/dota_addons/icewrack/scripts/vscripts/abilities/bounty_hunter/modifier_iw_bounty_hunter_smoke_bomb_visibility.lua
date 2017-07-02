modifier_iw_bounty_hunter_smoke_bomb_visibility = class({})

function modifier_iw_bounty_hunter_smoke_bomb_visibility:IsAura()
	--Delay applying aura on other units by 0.1s to ensure that the parent modifier is created first
	return self:GetParent() == self:GetCaster() and GameRules:GetGameTime() - self:GetCreationTime() > 0.1
end

function modifier_iw_bounty_hunter_smoke_bomb_visibility:GetModifierAura()
	return "modifier_iw_bounty_hunter_smoke_bomb_visibility"
end

function modifier_iw_bounty_hunter_smoke_bomb_visibility:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_BOTH
end

function modifier_iw_bounty_hunter_smoke_bomb_visibility:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_iw_bounty_hunter_smoke_bomb_visibility:GetAuraRadius()
	return self:GetAbility():GetAOERadius()
end

function modifier_iw_bounty_hunter_smoke_bomb_visibility:IsAuraActiveOnDeath()
	return false
end

function modifier_iw_bounty_hunter_smoke_bomb_visibility:OnCreated(args)
	local hAbility = self:GetAbility()
	if IsServer() then
		if self:GetParent() == self:GetCaster() then
			hAbility._hParentModifier = self
			self:SetPropertyValue(IW_PROPERTY_VISIBILITY_PCT, args.visibility)
		else
			self:SetPropertyValue(IW_PROPERTY_VISIBILITY_PCT, hAbility._hParentModifier:GetBasePropertyValue(IW_PROPERTY_VISIBILITY_PCT))
		end
	end
end