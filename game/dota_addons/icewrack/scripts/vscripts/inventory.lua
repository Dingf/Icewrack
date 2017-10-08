--[[
    Icewrack Inventory
]]

--TODO: Make it so that you can't equip non-weapons while in combat or make item sets that you can swap to

if not CInventory then

require("mechanics/attributes")
require("mechanics/modifier_triggers")
require("ext_item")
require("ext_modifier")

CInventory = setmetatable({}, { __call = 
	function(self, hEntity)
		LogAssert(IsInstanceOf(hEntity, CDOTA_BaseNPC), LOG_MESSAGE_ASSERT_TYPE, "CDOTA_BaseNPC", type(hEntity))
		if hEntity._hInventory and hEntity._hInventory._bIsInventory then
			return hEntity._hInventory
		end
			
		self = setmetatable({ _bIsInventory = true }, {__index = CInventory})
		
		self._bIsInventory = true
		self._hEntity = hEntity
		
		self._tItemList = {}
		self._tInventoryUnits = {}
		self._tEquippedItems = {}
		
		self._nGoldAmount = 0
		self._bIgnoreWeight = false
		
		self._tNetTableItemList = {}
		self._tNetTableEquippedItems = {}
		self._tNetTable = {}
		
		self:UpdateNetTable()
								
		return self
	end})

function CInventory:UpdateNetTable()
	self._tNetTable.item_list = self._tNetTableItemList
	self._tNetTable.equipped = self._tNetTableEquippedItems
	self._tNetTable.weight = self:GetCurrentWeight()
	self._tNetTable.weight_max = self._bIgnoreWeight and -1 or self:GetCarryCapacity()
	self._tNetTable.gold = self:GetGoldAmount()
	CustomNetTables:SetTableValue("inventory", tostring(self._hEntity:entindex()), self._tNetTable)
end

function CInventory:RefreshInventory()
	local hEntity = self._hEntity
	if self:GetCurrentWeight() > self:GetCarryCapacity() then
		--TODO: Create a rooted modifier here for when the entity is overencumbered
	else
	end
	for k,v in pairs(self._tEquippedItems) do
		v:UpdateNetTable()
		self._tNetTableItemList[v:entindex()] = true
	end
	self:UpdateNetTable()
end

function CInventory:OnEntityRefresh()
	self:RefreshInventory()
end

function CInventory:GetCurrentWeight()
    local fWeight = 0.0
    for k,v in pairs(self._tItemList) do
		if not k:IsNull() then
			fWeight = fWeight + k:GetRealWeight()
		end
    end
    return fWeight
end

function CInventory:GetCarryCapacity()
	local hEntity = self._hEntity
	return (hEntity:GetAttributeValue(IW_ATTRIBUTE_STRENGTH) * 2.0)
end

function CInventory:GetEquippedItem(nSlot)
	return self._tEquippedItems[nSlot]
end

function CInventory:GetItemList()
	return self._tItemList
end

function CInventory:IsEmpty()
	return (next(self._tItemList) == nil)
end

function CInventory:GetCanCarryAmount(hItem)
	local nAmount = hItem:GetStackCount()
	if not self._bIgnoreWeight and self:GetCarryCapacity() > 0 then
		nAmount = math.min(nAmount, math.floor((self:GetCarryCapacity() - self:GetCurrentWeight())/hItem:GetWeight()))
	end
	return nAmount
end

function CInventory:GetGoldAmount()
	return self._nGoldAmount
end

function CInventory:SetGoldAmount(nAmount)
	if type(nAmount) == "number" then
		self._nGoldAmount = nAmount
		self:UpdateNetTable()
	end
end

function CInventory:AddGoldAmount(nAmount)
	if type(nAmount) == "number" then
		self._nGoldAmount = self._nGoldAmount + nAmount
		self:UpdateNetTable()
	end
end

function CInventory:SetIgnoreWeight(bValue)
	if type(bValue) == "boolean" then
		self._bIgnoreWeight = bValue
	end
end

function CInventory:EquipItem(hItem, nSlot)
	local hEntity = self._hEntity
	local nItemSlots = hItem:GetItemSlots()
    if IsValidExtendedEntity(hEntity) and IsValidExtendedItem(hItem) and self._tItemList[hItem] then
		if nSlot and bit32.band(nItemSlots, bit32.lshift(1, nSlot - 1)) == 0 then
			return false
		elseif bit32.band(hItem:GetItemType(), hEntity:GetEquipFlags()) ~= hItem:GetItemType() then
			return false
		end
		for i = 1,IW_MAX_INVENTORY_SLOT-1 do
			if self._tEquippedItems[i] == hItem then
				self:UnequipItem(i)
				break
			end
		end
		for i = 1,IW_MAX_INVENTORY_SLOT-1 do
			if i == nSlot or (not nSlot and not self._tEquippedItems[i] and bit32.band(nItemSlots, bit32.lshift(1, i - 1)) ~= 0) then
				if self._tEquippedItems[i] then
					if not self:UnequipItem(i) then
						return false
					end
				end
				
				if i < IW_INVENTORY_SLOT_QUICK1 then
					if bit32.band(hItem:GetItemFlags(), IW_ITEM_FLAG_IS_ATTACK_SOURCE) ~= 0 then
						hEntity:AddAttackSource(hItem, 1)
					end
					if hItem:IsAttackSource() then
						hItem:AddChild(hEntity)
					else
						hEntity:AddChild(hItem)
					end
					hItem:ApplyModifiers(IW_MODIFIER_ON_EQUIP, hEntity)
				end
				hItem:UpdateNetTable()
				self._tEquippedItems[i] = hItem
				self._tNetTableItemList[hItem:entindex()] = true
				self._tNetTableEquippedItems[i] = hItem:entindex()
				self:RefreshInventory()
				hEntity:RefreshEntity()
				hEntity:RefreshLoadout()
				return true
			end
		end
	end
	return false
end

function CInventory:UnequipItem(nSlot)
	local hEntity = self._hEntity
    local hItem = self._tEquippedItems[nSlot]
	if IsValidExtendedEntity(hEntity) and IsValidExtendedItem(hItem) then
		if bit32.band(hItem:GetItemFlags(), IW_ITEM_FLAG_CANNOT_UNEQUIP) ~= 0 then return false end
		if nSlot == IW_INVENTORY_SLOT_MAIN_HAND or nSlot == IW_INVENTORY_SLOT_OFF_HAND then
			hEntity:RemoveAttackSource(hItem, 1)
		end
		if hItem:IsAttackSource() then
			hItem:RemoveChild(hEntity)
		else
			hEntity:RemoveChild(hItem)
		end
		hItem:RemoveModifiers(IW_MODIFIER_ON_EQUIP)
		hItem:UpdateNetTable()
		self._tEquippedItems[nSlot] = nil
		self._tNetTableItemList[hItem:entindex()] = true
		self._tNetTableEquippedItems[nSlot] = nil
		self:RefreshInventory()
		hEntity:RefreshEntity()
		hEntity:RefreshLoadout()
		return true
	end
	return false
end

function CInventory:DropItem(hItem)
    local hInventoryUnit = self._tItemList[hItem]
    if hInventoryUnit then
		for i = 1,IW_MAX_INVENTORY_SLOT-1 do
			if self._tEquippedItems[i] == hItem then
				if not self:UnequipItem(i) then
					--TODO: Print an error here about not being able to unequip item
					return false
				end
				break
			end
		end
		
		hItem:RemoveModifiers(IW_MODIFIER_ON_ACQUIRE, hEntity)
		local vDropPosition = self._hEntity:GetAbsOrigin() + RandomVector(32.0)
		hInventoryUnit:DropItemAtPositionImmediate(hItem, GetGroundPosition(vDropPosition, self._hEntity))
		local hItemContainer = hItem:GetContainer()
		if not hItemContainer then
			CreateItemOnPositionSync(vDropPosition, hItem)
		end
		self._tItemList[hItem] = nil
		self._tNetTableItemList[hItem:entindex()] = nil
		self:RefreshInventory()
	end
end

function CInventory:RemoveItem(hItem)
    local hInventoryUnit = self._tItemList[hItem]
    if hInventoryUnit then
		for i = 1,IW_MAX_INVENTORY_SLOT-1 do
			if self._tEquippedItems[i] == hItem then
				if not self:UnequipItem(i) then
					--TODO: Print an error here about not being able to unequip item
					return false
				end
				break
			end
		end
		
		local hEntity = self._hEntity
		hItem:RemoveModifiers(IW_MODIFIER_ON_ACQUIRE, hEntity)
		self._tItemList[hItem] = nil
		self._tNetTableItemList[hItem:entindex()] = nil
		self:RefreshInventory()
    end
end

function CInventory:TransferItem(hItem, hEntity)
	local hInventory = hEntity:GetInventory()
	if self._tItemList[hItem] and hInventory and hInventory ~= self then
		local nItemIndex = hItem:entindex()
		if hInventory:AddItemToInventory(hItem) then
			for i = 1,IW_MAX_INVENTORY_SLOT-1 do
				if self._tEquippedItems[i] == hItem then
					if not self:UnequipItem(i) then
						--TODO: Print an error here about not being able to unequip item
						return false
					end
					break
				end
			end
			self._tItemList[hItem] = nil
			self._tNetTableItemList[nItemIndex] = nil
		else
			hItem:UpdateNetTable()
			self._tNetTableItemList[nItemIndex] = true
		end
		self:RefreshInventory()
	end
end

function CInventory:MoveItemToDummy(hItem)
	local hEntity = self._hEntity
	for k,v in pairs(self._tInventoryUnits) do
		if v < 6 then
			k:AddItem(hItem)
			hEntity:DropItemAtPositionImmediate(hItem, hEntity:GetAbsOrigin())
			local hContainer = hItem:GetContainer()
			if hContainer then hContainer:RemoveSelf() end
			return k
		end
	end
	
	local hInventoryUnit = CreateDummyUnit(hEntity:GetAbsOrigin(), hEntity:GetOwner(), hEntity:GetTeamNumber())
	if hInventoryUnit and IsValidEntity(hInventoryUnit) then
		self._tInventoryUnits[hInventoryUnit] = 0
		--hInventoryUnit._hReplaceTarget = hEntity
		--hInventoryUnit:SetControllableByPlayer(hEntity:GetPlayerID(), true)
		
		hItem:SetPurchaser(hInventoryUnit)
		hInventoryUnit:AddItem(hItem)
		hEntity:DropItemAtPositionImmediate(hItem, hEntity:GetAbsOrigin())
		local hContainer = hItem:GetContainer()
		if hContainer then hContainer:RemoveSelf() end
		return hInventoryUnit
	end
end

function CInventory:AddItemToInventory(hItem)
	if IsValidExtendedItem(hItem) then
		local hEntity = self._hEntity
		local nAmount = self:GetCanCarryAmount(hItem)
		if nAmount < 1 then
			return false
		end
		
		if bit32.btest(hItem:GetItemFlags(), IW_ITEM_FLAG_UNIQUE) then
			for k,v in pairs(self._tItemList) do
				if v:GetName() == hItem:GetName() then
					return false
				end
			end
		end
		
		if hItem:GetMaxStacks() > 1 then
			for k,v in pairs(self._tItemList) do
				local hInventoryItem = k
				if hInventoryItem and hInventoryItem:GetName() == hItem:GetName() and hInventoryItem:GetStackCount() < hInventoryItem:GetMaxStacks() then
					local nOverflow = hInventoryItem:ModifyStackCount(nAmount)
					hInventoryItem:UpdateNetTable()
					self._tNetTableItemList[hInventoryItem:entindex()] = true
					if nOverflow > 0 then
						nAmount = nOverflow
						hItem:SetStackCount(nOverflow)
					else
						hItem:SetThink(function() hItem:RemoveSelf() end, "ItemStackRemove", 0.03)
						self:RefreshInventory()
						return true
					end
				end
			end
		end
		
		local bIsNewStack = false
		if nAmount < hItem:GetStackCount() then
			if nAmount > 0 then
				local szItemName = hItem:GetAbilityName()
				hItem:ModifyStackCount(-nAmount)
				hItem = CExtItem(CreateItem(szItemName, hEntity, hEntity))
				bIsNewStack = true
			else
				return false
			end
		end
			
		local hInventoryUnit = self:MoveItemToDummy(hItem)
		if hEntity:GetPropertyValue(IW_PROPERTY_SKILL_LORE) >= hItem:GetIdentifyLevel() then
			hItem:Identify()
		end
		hItem:ApplyModifiers(IW_MODIFIER_ON_ACQUIRE, self._hEntity)
		hItem:SetPurchaser(self._hEntity)
		hItem:SetStackCount(nAmount)
		hItem:UpdateNetTable()
		self._tItemList[hItem] = hInventoryUnit
		self._tNetTableItemList[hItem:entindex()] = true
		self._tInventoryUnits[hInventoryUnit] = self._tInventoryUnits[hInventoryUnit] + 1
		self:EquipItem(hItem)
		self:RefreshInventory()
		return not bIsNewStack
	end
	return false
end

function CInventory:OnEquip(args)
	local hEntity = EntIndexToHScript(args.entindex)
	local hInventory = hEntity:GetInventory()
	if IsValidExtendedEntity(hEntity) and hInventory then
		if args.itemindex == -1 then
			hInventory:UnequipItem(args.slot)
		else
			local hItem = EntIndexToHScript(args.itemindex)
			if hItem then
				local nSourceSlot = nil
				for i = 1,IW_MAX_INVENTORY_SLOT-1 do
					if hInventory._tEquippedItems[i] == hItem then
						nSourceSlot = i
						break
					end
				end
				if nSourceSlot then
					local hItem2 = hInventory._tEquippedItems[args.slot]
					if hItem2 then
						hInventory:EquipItem(hItem2, nSourceSlot)
					end
					hInventory:EquipItem(hItem, args.slot)
				else
					hInventory:EquipItem(hItem, args.slot)
				end
			end
		end
	end
end

function CInventory:OnDrop(args)
	local hEntity = EntIndexToHScript(args.entindex)
	local hInventory = hEntity:GetInventory()
	if IsValidExtendedEntity(hEntity) and hInventory then
		local hItem = EntIndexToHScript(args.itemindex)
		hInventory:DropItem(hItem)
	end
end

function CInventory:OnUse(args)
	local hEntity = EntIndexToHScript(args.entindex)
	local hInventory = hEntity:GetInventory()
	if IsValidExtendedEntity(hEntity) and hInventory then
		local hItem = EntIndexToHScript(args.itemindex)
		local hInventoryUnit = hInventory._tItemList[hItem]
		if hItem and hInventoryUnit then
			--[[if not hEntity:HasItemInInventory(hItem:GetAbilityName()) then
				hEntity:AddItem(hItem)
			end]]
			CustomGameEventManager:Send_ServerToAllClients("iw_inventory_use_item", args)
		end
	end
end

function CInventory:OnUseFinish(args)
	local hEntity = EntIndexToHScript(args.entindex)
	local hOwner = hEntity:GetOwner()
	local hInventory = hEntity:GetInventory()
	if IsValidExtendedEntity(hEntity) and hInventory then
		local hItem = EntIndexToHScript(args.itemindex)
		if hItem and hInventory._tItemList[hItem] then
			--[[if hEntity:GetCurrentAction() == hItem:GetAbilityName() then
				hEntity:SetThink(function()
					if not hItem or hItem:IsNull() then return nil
					elseif bit32.btest(hItem:GetItemFlags(), IW_ITEM_FLAG_QUEST) then
						--TODO: Throw an error to the client about the item being an undroppable quest item
						return nil
					elseif hEntity:GetCurrentAction() ~= hItem:GetAbilityName() then
						hEntity:DropItemAtPositionImmediate(hItem, hEntity:GetAbsOrigin())
						local hContainer = hItem:GetContainer()
						if hContainer then hContainer:RemoveSelf() end
						return nil
					else
						return 0.03
					end
				end, DoUniqueString("InventoryDummyReturnItem"), 0.03)
			else
				hEntity:DropItemAtPositionImmediate(hItem, hEntity:GetAbsOrigin())
				local hContainer = hItem:GetContainer()
				hContainer:RemoveSelf()
			end]]
		end
	end
end

function CInventory:OnTake(args)
	local hEntity = EntIndexToHScript(args.entindex)
	local hLootable = EntIndexToHScript(args.lootable)
	local hEntityInventory = hEntity:GetInventory()
	local hLootableInventory = hLootable:GetInventory()
	if IsValidExtendedEntity(hEntity) and hLootable and hEntityInventory and hLootableInventory then
		local hItem = EntIndexToHScript(args.itemindex)
		hLootableInventory:TransferItem(hItem, hEntity)
	end
end

function CInventory:OnStore(args)
	local hEntity = EntIndexToHScript(args.entindex)
	local hLootable = EntIndexToHScript(args.lootable)
	local hEntityInventory = hEntity:GetInventory()
	local hLootableInventory = hLootable:GetInventory()
	if IsValidExtendedEntity(hEntity) and hLootable and hEntityInventory and hLootableInventory then
		local hItem = EntIndexToHScript(args.itemindex)
		hEntityInventory:TransferItem(hItem, hLootable)
	end
end

CustomGameEventManager:RegisterListener("iw_inventory_equip_item", Dynamic_Wrap(CInventory, "OnEquip"))
CustomGameEventManager:RegisterListener("iw_inventory_drop_item", Dynamic_Wrap(CInventory, "OnDrop"))
CustomGameEventManager:RegisterListener("iw_inventory_use_item", Dynamic_Wrap(CInventory, "OnUse"))
CustomGameEventManager:RegisterListener("iw_inventory_use_finish", Dynamic_Wrap(CInventory, "OnUseFinish"))
CustomGameEventManager:RegisterListener("iw_lootable_take_item", Dynamic_Wrap(CInventory, "OnTake"))
CustomGameEventManager:RegisterListener("iw_lootable_store_item", Dynamic_Wrap(CInventory, "OnStore"))

end