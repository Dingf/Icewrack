iw_axe_culling_blade = class({})

function iw_axe_culling_blade:OnAbilityPhaseStart()
	local hEntity = self:GetCaster()
	hEntity:TriggerExtendedEvent(IW_MODIFIER_EVENT_ON_PRE_ATTACK_EVENT)
	return true
end

function iw_axe_culling_blade:CastFilterResultTarget(hTarget)
	if IsServer() then
		local hEntity = self:GetCaster()
		local hAttackSource = hEntity:GetCurrentAttackSource()
		local nItemType = hAttackSource and hAttackSource:GetItemType() or 0
		
		self._bEquipFailed = false
		if bit32.btest(nItemType, 2) and bit32.btest(nItemType, 124) then
			return UF_SUCCESS
		end
		self._bEquipFailed = true
		return UF_FAIL_CUSTOM
	end
end

function iw_axe_culling_blade:GetCustomCastErrorTarget(hTarget)
	if self._bEquipFailed then return "#iw_error_cast_2h_melee" end
end

function iw_axe_culling_blade:OnSpellStart()
	local hEntity = self:GetCaster()
	local hTarget = self:GetCursorTarget()
	
	if hTarget then
		local vTargetPosition = hTarget:GetAbsOrigin()
		local fDamagePerMissingHP = self:GetSpecialValueFor("damage_missing")
		local fDamagePercent = self:GetSpecialValueFor("damage") + ((100 - hTarget:GetHealthPercent()) * fDamagePerMissingHP)
		local tDamageTable =
		{
			attacker = hEntity,
			target = hTarget,
			Percent = fDamagePercent,
		}
		
		local nHitParticleID = ParticleManager:CreateParticle("particles/units/heroes/hero_axe/axe_culling_blade.vpcf", PATTACH_CUSTOMORIGIN, hEntity)
		ParticleManager:SetParticleControlEnt(nHitParticleID, 0, hTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", vTargetPosition, true)
		ParticleManager:ReleaseParticleIndex(nHitParticleID)
		
		hEntity:TriggerExtendedEvent(IW_MODIFIER_EVENT_ON_ATTACK_EVENT_START)
		if DealAttackDamage(hEntity, tDamageTable) then
			if hTarget:GetHealth() == 0 then
				local nKillParticleID = ParticleManager:CreateParticle("particles/units/heroes/hero_axe/axe_culling_blade_kill.vpcf", PATTACH_CUSTOMORIGIN, hEntity)
				ParticleManager:SetParticleControlEnt(nKillParticleID, 0, hTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", vTargetPosition, true)
				ParticleManager:SetParticleControlEnt(nKillParticleID, 1, hTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", vTargetPosition, true)
				ParticleManager:SetParticleControlEnt(nKillParticleID, 2, hTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", vTargetPosition, true)
				ParticleManager:SetParticleControlEnt(nKillParticleID, 4, hTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", vTargetPosition, true)
				ParticleManager:SetParticleControlEnt(nKillParticleID, 8, hTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", vTargetPosition, true)
				ParticleManager:ReleaseParticleIndex(nKillParticleID)
				
				EmitSoundOn("Hero_Axe.Culling_Blade_Success", hTarget)
				self:EndCooldown()
				return
			end
		end
		EmitSoundOn("Hero_Axe.Culling_Blade_Fail", hTarget)
	end
end
