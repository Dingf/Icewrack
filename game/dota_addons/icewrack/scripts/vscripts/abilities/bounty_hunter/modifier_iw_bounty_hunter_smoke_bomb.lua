modifier_iw_bounty_hunter_smoke_bomb = class({})

function modifier_iw_bounty_hunter_smoke_bomb:IsAura()
	--Delay applying aura on other units by 0.1s to ensure that the parent modifier is created first
	return self:GetParent() == self:GetCaster() and GameRules:GetGameTime() - self:GetCreationTime() > 0.1
end

function modifier_iw_bounty_hunter_smoke_bomb:GetModifierAura()
	return "modifier_iw_bounty_hunter_smoke_bomb"
end

function modifier_iw_bounty_hunter_smoke_bomb:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_BOTH
end

function modifier_iw_bounty_hunter_smoke_bomb:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_iw_bounty_hunter_smoke_bomb:GetAuraRadius()
	return self:GetAbility():GetAOERadius()
end

function modifier_iw_bounty_hunter_smoke_bomb:GetAuraEntityReject(hEntity)
	return hEntity:GetUnitName() == "npc_dota_hero_bounty_hunter"
end

function modifier_iw_bounty_hunter_smoke_bomb:IsAuraActiveOnDeath()
	return false
end

function modifier_iw_bounty_hunter_smoke_bomb:OnCreated(args)
	local hAbility = self:GetAbility()
	if IsServer() then
		if self:GetParent() == self:GetCaster() then
			hAbility._hParentModifier = self
			self:SetPropertyValue(IW_PROPERTY_ACCURACY_PCT, args.accuracy)
			
			local fRadius = self:GetAuraRadius()
			local nParticleID = ParticleManager:CreateParticle("particles/units/heroes/hero_bounty_hunter/bounty_hunter_smoke_bomb.vpcf", PATTACH_WORLDORIGIN, self)
			ParticleManager:SetParticleControl(nParticleID, 0, self:GetParent():GetAbsOrigin())
			ParticleManager:SetParticleControl(nParticleID, 1, Vector(fRadius, fRadius, fRadius))
			self:AddParticle(nParticleID, false, false, -1, false, false)
			
			CTimer(args.duration, function()
				local hAvoidanceZone = self._hAvoidanceZone
				local hBlockerZone = self._hBlockerZone
				if hAvoidanceZone then
					hAvoidanceZone:RemoveSelf()
				end
				if hBlockerZone then
					hBlockerZone:RemoveSelf()
				end
				self:GetParent():RemoveSelf()
			end)
		else
			self:SetPropertyValue(IW_PROPERTY_ACCURACY_PCT, hAbility._hParentModifier:GetBasePropertyValue(IW_PROPERTY_ACCURACY_PCT))
		end
	else
		if self:GetParent() == self:GetCaster() then
			hAbility._hParentModifier = self
		else
			self._szTextureArgsString = hAbility._hParentModifier._szTextureArgsString
		end
	end
end