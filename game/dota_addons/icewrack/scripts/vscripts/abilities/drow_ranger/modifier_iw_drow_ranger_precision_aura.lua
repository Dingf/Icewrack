modifier_iw_drow_ranger_precision_aura = class({})

function modifier_iw_drow_ranger_precision_aura:IsAura()
	--Delay applying aura on other units by 0.1s to ensure that the parent modifier is created first
	return self:GetCaster() == self:GetParent() and GameRules:GetGameTime() - self:GetCreationTime() > 0.1
end

function modifier_iw_drow_ranger_precision_aura:GetModifierAura()
	return "modifier_iw_drow_ranger_precision_aura"
end

function modifier_iw_drow_ranger_precision_aura:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_iw_drow_ranger_precision_aura:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_iw_drow_ranger_precision_aura:GetAuraRadius()
	return self:GetAbility():GetAOERadius()
end

function modifier_iw_drow_ranger_precision_aura:GetAuraEntityReject(hEntity)
	return not hEntity:IsAlive()
end

function modifier_iw_drow_ranger_precision_aura:IsAuraActiveOnDeath()
	return false
end

function modifier_iw_drow_ranger_precision_aura:OnCreated(args)
	if IsServer() then
		if self:GetParent() == self:GetCaster() then
			self:SetPropertyValue(IW_PROPERTY_ACCURACY_PCT, args.accuracy)
			self:SetPropertyValue(IW_PROPERTY_CRIT_CHANCE_PCT, args.crit_chance)
			local nParticleID = ParticleManager:CreateParticle("particles/units/heroes/hero_drow/drow_precision_aura_caster.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
			self:AddParticle(nParticleID, false, false, -1, false, false)
		else
			local hParentModifier = self:GetCaster():FindModifierByName(self:GetName())
			self:SetPropertyValue(IW_PROPERTY_ACCURACY_PCT, hParentModifier:GetBasePropertyValue(IW_PROPERTY_ACCURACY_PCT))
			self:SetPropertyValue(IW_PROPERTY_CRIT_CHANCE_PCT, hParentModifier:GetBasePropertyValue(IW_PROPERTY_CRIT_CHANCE_PCT))
			local nParticleID = ParticleManager:CreateParticle("particles/units/heroes/hero_drow/drow_precision_aura_recipient.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
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
