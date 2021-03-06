iw_axe_counter_helix = class({})

function iw_axe_counter_helix:GetCastAnimation()
	return ACT_DOTA_OVERRIDE_ABILITY_3
end

function iw_axe_counter_helix:GetPlaybackRateOverride()
	return self._fAttackRate
end

function iw_axe_counter_helix:GetAOERadius()
	local hEntity = self:GetCaster()
	return hEntity:GetAttackRange() + 64.0
end

function iw_axe_counter_helix:OnAbilityPhaseStart()
	local hEntity = self:GetCaster()
	local fBaseAttackInterval = self:GetSpecialValueFor("attack_interval")
	self._fAttackRate = math.max(-0.9, math.min(1.0 + hEntity:GetIncreasedAttackSpeed(), 5.0))/fBaseAttackInterval
	return true
end

function iw_axe_counter_helix:OnSpellStart()
	if IsServer() then
		local hEntity = self:GetCaster()
		local hAttackSource = hEntity:GetCurrentAttackSource()
		local fTotalDamage = 0
		for k,v in pairs(stIcewrackDamageTypeEnum) do
			local fMinDamage = hAttackSource:GetDamageMin(v)
			local fMaxDamage = hAttackSource:GetDamageMax(v)
			--Strength bonus physical attack damage
			if v >= IW_DAMAGE_TYPE_CRUSH and v <= IW_DAMAGE_TYPE_PIERCE then
				fMinDamage = fMinDamage * (1.0 + hEntity:GetAttributeValue(IW_ATTRIBUTE_STRENGTH)/100.0)
				fMaxDamage = fMaxDamage * (1.0 + hEntity:GetAttributeValue(IW_ATTRIBUTE_STRENGTH)/100.0)
			end
			fTotalDamage = fTotalDamage + (fMinDamage + fMaxDamage)/2.0
		end
		
		local fBaseAttackInterval = self:GetSpecialValueFor("attack_interval")
		local fAvoidanceValue = fTotalDamage * fBaseAttackInterval/self._fAttackRate * self:GetSpecialValueFor("avoidance_factor")
		
		local tModifierArgs = 
		{
			avoidance = fAvoidanceValue,
			move_speed = self:GetSpecialValueFor("move_speed"),
			damage = self:GetSpecialValueFor("damage"),
		}
		self._fLastChannelTime = 0
		hEntity:AddNewModifier(hEntity, self, "modifier_iw_axe_counter_helix", tModifierArgs)
		EmitSoundOn("Hero_Axe.CounterHelix.Start", hEntity)
	end
end

function iw_axe_counter_helix:CastFilterResult()
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

function iw_axe_counter_helix:GetCustomCastError()
	if self._bEquipFailed then return "#iw_error_cast_2h_melee" end
end

function iw_axe_counter_helix:OnChannelThink(fThinkRate)
	local hEntity = self:GetCaster()
	local fBaseAttackInterval = self:GetSpecialValueFor("attack_interval")
	local fAttackRate = math.max(-0.9, math.min(1.0 + hEntity:GetIncreasedAttackSpeed(), 5.0))/fBaseAttackInterval
	local fRealAttackInterval = 1.0/fAttackRate
	
	self._fAttackRate = fAttackRate
	
	local fCurrentTime = GameRules:GetGameTime()
	if fCurrentTime - self._fLastChannelTime >= fRealAttackInterval then
		local tDamageTable =
		{
			attacker = hEntity,
			Percent = self:GetSpecialValueFor("damage"),
			CanDodge = true,
		}
		
		local hNearbyEntities = FindUnitsInRadius(hEntity:GetTeamNumber(), hEntity:GetAbsOrigin(), nil, self:GetAOERadius(), DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, 0, 0, false)
		for k,v in pairs(hNearbyEntities) do
			if v ~= hEntity and IsValidExtendedEntity(v) then
				tDamageTable.target = v
				DealAttackDamage(hEntity, tDamageTable)
			end
		end
		self._fLastChannelTime = fCurrentTime
		EmitSoundOn("Hero_Axe.CounterHelix", hEntity)
	end
	--Disable stamina regen time during channel
	hEntity:SpendStamina(0)
end

function iw_axe_counter_helix:OnChannelFinish(bInterrupted)
	local hEntity = self:GetCaster()
	hEntity:RemoveModifierByName("modifier_iw_axe_counter_helix")
end