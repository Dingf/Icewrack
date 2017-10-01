iw_dragon_knight_shield_slam = class({})

function iw_dragon_knight_shield_slam:CastFilterResultTarget(hTarget)
	if IsServer() then
		self._bEquipFailed = false
		local hEntity = self:GetCaster()
		if hEntity.GetInventory then
			local hInventory = hEntity:GetInventory()
			for i = 1,IW_INVENTORY_SLOT_QUICK1-1 do
				local hItem = hInventory:GetEquippedItem(i)
				if hItem then
					local nItemType = hItem:GetItemType()
					if bit32.btest(nItemType, 131072) then
						return UF_SUCCESS
					end
				end
			end
		end
		self._bEquipFailed = true
		return UF_FAIL_CUSTOM
	end
end

function iw_dragon_knight_shield_slam:GetCustomCastErrorTarget(hTarget)
	if self._bEquipFailed then return "#iw_error_cast_shield" end
end

function iw_dragon_knight_shield_slam:OnSpellStart()
	local hEntity = self:GetCaster()
	local hTarget = self:GetCursorTarget()
	
	local fDamageAmount = 0
	if hEntity.GetInventory then
		local hInventory = hEntity:GetInventory()
		for i = 1,IW_INVENTORY_SLOT_QUICK1-1 do
			local hItem = hInventory:GetEquippedItem(i)
			if hItem then
				local nItemType = hItem:GetItemType()
				if bit32.btest(nItemType, 131072) then
					fDamageAmount = fDamageAmount + hItem:GetBasePropertyValue(IW_PROPERTY_ARMOR_CRUSH_FLAT) * (1.0 + hEntity:GetPropertyValue(IW_PROPERTY_ARMOR_CRUSH_PCT)/100.0)
					fDamageAmount = fDamageAmount + hItem:GetBasePropertyValue(IW_PROPERTY_ARMOR_SLASH_FLAT) * (1.0 + hEntity:GetPropertyValue(IW_PROPERTY_ARMOR_SLASH_PCT)/100.0)
					fDamageAmount = fDamageAmount + hItem:GetBasePropertyValue(IW_PROPERTY_ARMOR_PIERCE_FLAT) * (1.0 + hEntity:GetPropertyValue(IW_PROPERTY_ARMOR_PIERCE_PCT)/100.0)		
					break
				end
			end
		end
	end
	
	fDamageAmount = fDamageAmount * self:GetSpecialValueFor("damage")/100
	self:SetPropertyValue(IW_PROPERTY_CHANCE_BASH, self:GetSpecialValueFor("bash_chance"))

	local tDamageTable =
	{
		attacker = hEntity,
		target = hTarget,
		source = self,
		ThreatMultiplier = self:GetSpecialValueFor("threat") + 1.0,
		DamageEffectBonus = self:GetSpecialValueFor("damage_effect")/100.0,
		damage =
		{
			[IW_DAMAGE_TYPE_CRUSH] = 
			{
				min = fDamageAmount,
				max = fDamageAmount,
			}
		}
	}
	DealPrimaryDamage(self, tDamageTable)
	
	local nParticleID = ParticleManager:CreateParticle("particles/units/heroes/hero_dragon_knight/dragon_knight_shield_slam.vpcf", PATTACH_CUSTOMORIGIN, hEntity)
	ParticleManager:SetParticleControlEnt(nParticleID, 2, hEntity, PATTACH_POINT_FOLLOW, "attach_attack2", hEntity:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(nParticleID, 3, hTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", hTarget:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(nParticleID, 4, hTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", hTarget:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(nParticleID)
	
	EmitSoundOn("Hero_DragonKnight.DragonTail.Target", hTarget)
end