iw_axe_counter_helix = class({})

function iw_axe_counter_helix:OnAbilityPhaseStart()
	local hEntity = self:GetCaster()
	EmitSoundOn("Hero_Axe.CounterHelix", hEntity)
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

function iw_axe_counter_helix:GetCustomCastError()
	if self._bEquipFailed then return "#iw_error_cast_equip" end
end

function iw_axe_counter_helix:OnSpellStart()
	local hEntity = self:GetCaster()
	local tDamageTable =
	{
		attacker = hEntity,
		Percent = self:GetSpecialValueFor("damage"),
		CanDodge = true,
	}
	
	local hNearbyEntities = Entities:FindAllInSphere(hEntity:GetAbsOrigin(), self:GetAOERadius())
	for k,v in pairs(hNearbyEntities) do
		if v ~= hEntity and IsValidExtendedEntity(v) then
			tDamageTable.target = v
			if DealAttackDamage(hEntity, tDamageTable) then
				v:Interrupt()
			end
		end
	end
end