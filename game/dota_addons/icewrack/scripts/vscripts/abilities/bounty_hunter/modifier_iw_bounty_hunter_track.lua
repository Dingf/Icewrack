modifier_iw_bounty_hunter_track = class({})

function modifier_iw_bounty_hunter_track:IsAura()
	return true
end

function modifier_iw_bounty_hunter_track:GetModifierAura()
	return "modifier_iw_bounty_hunter_track_target"
end

function modifier_iw_bounty_hunter_track:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_iw_bounty_hunter_track:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_iw_bounty_hunter_track:GetAuraRadius()
	return self:GetAbility():GetAOERadius()
end

function modifier_iw_bounty_hunter_track:GetAuraEntityReject(hEntity)
	local hCaster = self:GetCaster()
	return not hEntity:IsAlive() or hCaster:CanEntityBeSeenByMyTeam(hEntity)
end

function modifier_iw_bounty_hunter_track:IsAuraActiveOnDeath()
	return false
end