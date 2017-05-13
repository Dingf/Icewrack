iw_axe_culling_blade = class({})

function iw_axe_culling_blade:CastFilterResult()
	self._bEquipFailed = false
	local hEntity = self:GetCaster()
	if hEntity.GetInventory then
		local hInventory = hEntity:GetInventory()
		for i = 1,IW_INVENTORY_SLOT_QUICK1-1 do
			local hItem = hInventory:GetEquippedItem(i)
			if hItem and bit32.btest(hItem:GetItemType(), IW_ITEM_TYPE_WEAPON_2H) then
				return UF_SUCCESS
			end
		end
	end
	self._bEquipFailed = true
	return UF_FAIL_CUSTOM
end

function iw_axe_culling_blade:GetCustomCastError()
	if self._bEquipFailed then return "#iw_error_cast_equip" end
end

function iw_axe_culling_blade:OnSpellStart()
	local hEntity = self:GetCaster()
	local hTarget = self:GetCursorTarget()
	
	if hTarget then
		local vTargetPosition = hTarget:GetAbsOrigin()
		local fDoubleThreshold = self:GetSpecialValueFor("threshold")
		local fDamagePercent = self:GetSpecialValueFor("damage")
		
		local fHealthPercent = 100 - hTarget:GetHealthPercent()
		while fHealthPercent > fDoubleThreshold do
			fHealthPercent = fHealthPercent - fDoubleThreshold
			fDamagePercent = fDamagePercent * 2
		end
		
		local tDamageTable =
		{
			attacker = hEntity,
			target = hTarget,
			Percent = fDamagePercent,
		}
		
		local nHitParticleID = ParticleManager:CreateParticle("particles/units/heroes/hero_axe/axe_culling_blade.vpcf", PATTACH_CUSTOMORIGIN, hEntity)
		ParticleManager:SetParticleControlEnt(nHitParticleID, 0, hTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", vTargetPosition, true)
		
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
