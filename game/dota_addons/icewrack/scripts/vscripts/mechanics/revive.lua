internal_revive = class({})

function internal_revive:OnChannelFinish(bInterrupted)
	local hTombstone = self._hTombstone
	if not bInterrupted then
		local hTarget = self._hTarget
		hTarget:RemoveModifierByName("modifier_internal_corpse_state")
		hTarget:RemoveModifierByName("modifier_internal_corpse_unselectable")
		hTarget:RemoveModifierByName("modifier_elder_titan_echo_stomp")
		
		hTarget:SetHealth(GameRules:GetReviveHealthPercent() * hTarget:GetMaxHealth())
		hTarget:SetMana(GameRules:GetReviveManaStaminaPercent() * hTarget:GetMaxMana())
		hTarget:SetStamina(GameRules:GetReviveManaStaminaPercent() * hTarget:GetMaxStamina())
		hTarget:SpendStamina(0)
		
		local nParticleID = ParticleManager:CreateParticle("particles/generic_hero_status/respawn.vpcf", PATTACH_POINT, hTarget)
		ParticleManager:ReleaseParticleIndex(nParticleID)
		hTombstone:RemoveSelf()
	else
		self:SetOwner(nil)
	end
	ParticleManager:DestroyParticle(self._nProgressRingID, false)
	ParticleManager:ReleaseParticleIndex(self._nProgressRingID)
	self._nProgressRingID = nil
end

function internal_revive:OnChannelThink(fThinkRate)
	local nParticleID = self._nProgressRingID
	if nParticleID then
		local fChannelPercent = (GameRules:GetGameTime() - self:GetChannelStartTime())/self:GetChannelTime()
		ParticleManager:SetParticleControl(nParticleID, 1, Vector(100, fChannelPercent, 0))
	end
end

function internal_revive:OnSpellStart()
	if self._nProgressRingID then
		ParticleManager:DestroyParticle(self._nProgressRingID, false)
		ParticleManager:ReleaseParticleIndex(self._nProgressRingID)
	end

	self._hTombstone = self:GetCursorTarget()
	self._hTarget = self._hTombstone._hTarget
	
	self._nProgressRingID = ParticleManager:CreateParticle("particles/econ/generic/generic_progress_meter/generic_progress_circle.vpcf", PATTACH_POINT, self._hTarget)
	ParticleManager:SetParticleControl(self._nProgressRingID, 0, self._hTarget:GetAbsOrigin() + Vector(0, 0, 256))
	ParticleManager:SetParticleControl(self._nProgressRingID, 1, Vector(48, 0, 0))
end

function internal_revive:CastFilterResultTarget(hTarget)
	if IsServer() and IsValidExtendedEntity(hEntity) then
		self._bCombatFailed = false
		if GameRules:IsInCombat() then
			self._bCombatFailed = true
			return UF_FAIL_CUSTOM
		end
		
		--[[self._bCasterFailed = false
		if self._hCurrentCaster then
			self._bCasterFailed = true
			return UF_FAIL_CUSTOM
		end]]
	end
end

function internal_revive:GetCustomCastErrorTarget(hTarget)
	if self._bEquipFailed then
		return "#iw_error_cant_revive_in_combat"
	end
end

function CreateReviveTombstone(hEntity)
	local hTombstone = CWorldObject(CreateUnitByName("npc_iw_revive_tombstone", hEntity:GetAbsOrigin(), false, hEntity, hEntity, DOTA_TEAM_GOODGUYS))
	hTombstone._hTarget = hEntity
	hTombstone:SetForwardVector(hEntity:GetForwardVector())
	hTombstone:SetUnitName(hEntity:GetUnitName())
	local hAbility = hTombstone:FindAbilityByName("internal_revive")
	hTombstone:AddNewModifier(hEntity, hAbility, "modifier_internal_revive", {})
	return hTombstone
end