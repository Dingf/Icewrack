modifier_iw_dragon_knight_endurance_aura = class({})

function modifier_iw_dragon_knight_endurance_aura:IsAura()
	--Delay applying aura on other units by 0.1s to ensure that the parent modifier is created first
	return self:GetCaster() == self:GetParent() and GameRules:GetGameTime() - self:GetCreationTime() > 0.1
end

function modifier_iw_dragon_knight_endurance_aura:GetModifierAura()
	return "modifier_iw_dragon_knight_endurance_aura"
end

function modifier_iw_dragon_knight_endurance_aura:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_iw_dragon_knight_endurance_aura:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_iw_dragon_knight_endurance_aura:GetAuraRadius()
	return self:GetAbility():GetAOERadius()
end

function modifier_iw_dragon_knight_endurance_aura:GetAuraEntityReject(hEntity)
	return not hEntity:IsAlive()
end

function modifier_iw_dragon_knight_endurance_aura:IsAuraActiveOnDeath()
	return false
end

function modifier_iw_dragon_knight_endurance_aura:OnCreated(args)
	if IsServer() then
		if self:GetParent() == self:GetCaster() then
			self:SetPropertyValue(IW_PROPERTY_HP_REGEN_FLAT, args.health_regen)
			self:SetPropertyValue(IW_PROPERTY_SP_REGEN_FLAT, args.stamina_regen)
			self:SetPropertyValue(IW_PROPERTY_RESIST_PHYS, args.phys_resist)
			local nParticleID = ParticleManager:CreateParticle("particles/units/heroes/hero_dragon_knight/dragon_knight_endurance_aura_caster.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
			self:AddParticle(nParticleID, false, false, -1, false, false)
		else
			local hParentModifier = self:GetCaster():FindModifierByName(self:GetName())
			self:SetPropertyValue(IW_PROPERTY_HP_REGEN_FLAT, hParentModifier:GetBasePropertyValue(IW_PROPERTY_HP_REGEN_FLAT))
			self:SetPropertyValue(IW_PROPERTY_SP_REGEN_FLAT, hParentModifier:GetBasePropertyValue(IW_PROPERTY_SP_REGEN_FLAT))
			self:SetPropertyValue(IW_PROPERTY_RESIST_PHYS, hParentModifier:GetBasePropertyValue(IW_PROPERTY_RESIST_PHYS))
			local nParticleID = ParticleManager:CreateParticle("particles/units/heroes/hero_dragon_knight/dragon_knight_endurance_aura_recipient.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
			self:AddParticle(nParticleID, false, false, -1, false, false)
		end
	else
		local hAbility = self:GetAbility()
		if self:GetParent() == self:GetCaster() then
			hAbility._hParentModifier = self
		else
			self._szTextureArgsString = hAbility._hParentModifier._szTextureArgsString
		end
	end
end
