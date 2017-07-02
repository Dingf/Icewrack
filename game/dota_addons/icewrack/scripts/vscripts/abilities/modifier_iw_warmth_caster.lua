modifier_iw_warmth_caster = class({})

function modifier_iw_warmth_caster:IsAura()
	--Delay applying aura on other units by 0.1s to ensure that the parent modifier is created first
	return self:GetCaster() == self:GetParent() and GameRules:GetGameTime() - self:GetCreationTime() > 0.1
end

function modifier_iw_warmth_caster:GetModifierAura()
	return "modifier_iw_warmth"
end

function modifier_iw_warmth_caster:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY + DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_iw_warmth_caster:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_iw_warmth_caster:GetAuraRadius()
	return self:GetAbility():GetAOERadius()
end

function modifier_iw_warmth_caster:GetAuraEntityReject(hEntity)
	return not hEntity:IsAlive() or hEntity == self:GetCaster()
end

function modifier_iw_warmth_caster:IsAuraActiveOnDeath()
	return false
end

function modifier_iw_warmth_caster:OnCreated(args)
	if IsServer() then
		local hEntity = self:GetParent()
		local nParticleID = ParticleManager:CreateParticle("particles/units/heroes/hero_lina/lina_warmth.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
		self:AddParticle(nParticleID, false, false, -1, false, false)
		self:SetDuration(args.duration, true)
		hEntity:DispelModifiers(IW_STATUS_MASK_FREEZE + IW_STATUS_MASK_CHILL + IW_STATUS_MASK_WET)
	else
		local hAbility = self:GetAbility()
		hAbility._hParentModifier = self
	end
end