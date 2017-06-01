iw_axe_counter_helix = class({})

function iw_axe_counter_helix:OnAbilityPhaseStart()
	local hEntity = self:GetCaster()
	EmitSoundOn("Hero_Axe.CounterHelix", hEntity)
	hEntity:TriggerExtendedEvent(IW_MODIFIER_EVENT_ON_PRE_ATTACK_EVENT)
	return true
end

function iw_axe_counter_helix:OnAbilityPhaseInterrupted()
	local hEntity = self:GetCaster()
	StopSoundOn("Hero_Axe.CounterHelix", hEntity)
end

function iw_axe_counter_helix:GetAOERadius()
	local hEntity = self:GetCaster()
	return hEntity:GetAttackRange() + 64.0
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

function iw_axe_counter_helix:OnSpellStart()
	local hEntity = self:GetCaster()
	local tDamageTable =
	{
		attacker = hEntity,
		Percent = self:GetSpecialValueFor("damage"),
		CanDodge = true,
	}
	
	hEntity:TriggerExtendedEvent(IW_MODIFIER_EVENT_ON_ATTACK_EVENT_START)
	local hNearbyEntities = Entities:FindAllInSphere(hEntity:GetAbsOrigin(), self:GetAOERadius())
	for k,v in pairs(hNearbyEntities) do
		if v ~= hEntity and IsValidExtendedEntity(v) then
			tDamageTable.target = v
			if DealAttackDamage(hEntity, tDamageTable) then
				v:AddNewModifier(hEntity, self, "modifier_iw_axe_counter_helix", {})
			end
		end
	end
end