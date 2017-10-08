if not CContainerEntity then

require("instance")
require("entity_base")
--require("interactable")
--require("inventory")
require("loot_list")

CContainerEntity = setmetatable(ext_class({}), { __call =
	function(self, hEntity, nInstanceID)
		LogAssert(IsInstanceOf(hEntity, CDOTA_BaseNPC), LOG_MESSAGE_ASSERT_TYPE, "CDOTA_BaseNPC", type(hEntity))
		if IsInstanceOf(hEntity, CContainerEntity) then
			LogMessage("Tried to create a CContainerEntity from \"" .. hEntity:GetUnitName() .."\", which is already a CContainerEntity", LOG_SEVERITY_WARNING)
			return hEntity
		end
		
		--local tInteractableTemplate = stInteractableData[hEntity:GetUnitName()] or {}
		hEntity = CEntityBase(hEntity, nInstanceID)
		--hEntity = CInteractable(hEntity, nInstanceID)
		ExtendIndexTable(hEntity, CContainerEntity)
		
		hEntity._tItemList = {}
		hEntity._tInventoryUnits = {}
		hEntity._tEquippedItems = {}
		hEntity._nEquipFlags = 0
		
		hEntity._nGoldAmount = 0
		hEntity._bIgnoreCarryWeight = false
		
		--hEntity._tNetTableItemList = {}
		--hEntity._tNetTableEquippedItems = {}
		hEntity._tInventoryNetTable =
		{
			item_list = {},
			equipped = {},
		}
		
		--[[local hLootList = CLootList(tInteractableTemplate.LootList)
		if bGenerateLootTable and hInventory and hLootList then
			local tLootList = hLootList:GenerateLootList()
			for k,v in pairs(tLootList) do
				hInventory:AddItemToInventory(v)
			end
		end]]
		
		return hEntity
	end
})
	
--[[function CContainerEntity:GetInventory()
	return self._hInventory
end]]

function CContainerEntity:Interact(hEntity)
	if hEntity:IsRealHero() then
		CustomGameEventManager:Send_ServerToAllClients("iw_lootable_interact", { entindex = hEntity:entindex(), lootable = self:entindex() })
		return true
	end
end

function CContainerEntity:InteractFilterInclude(hEntity)
	return hEntity:IsRealHero()
end

function CContainerEntity:GetCustomInteractError(hEntity)
end

function CContainerEntity:GenerateLootList(szLootListName)
	local hLootList = CLootList(szLootListName)
	if hLootList and self:IsInventoryEmpty() then
		for k,v in pairs(hLootList:GenerateLootList()) do
			self:AddItemToInventory(v)
		end
	end
end

function CContainerEntity:UpdateInventoryNetTable()
	--self._tNetTable.item_list = self._tNetTableItemList
	--self._tNetTable.equipped = self._tNetTableEquippedItems
	self._tInventoryNetTable.weight = self:GetCurrentWeight()
	self._tInventoryNetTable.weight_max = self._bIgnoreWeight and -1 or self:GetCarryCapacity()
	self._tInventoryNetTable.gold = self:GetGoldAmount()
	CustomNetTables:SetTableValue("inventory", tostring(self:entindex()), self._tInventoryNetTable)
end

function CContainerEntity:RefreshInventory(hEntity)
	if IsValidContainer(hEntity) then
		if self:GetCurrentWeight() > self:GetCarryCapacity() then
			--TODO: Create a rooted modifier here for when the entity is overencumbered
		end
		local tNetTableItemList = hEntity._tNetTable.item_list
		for k,v in pairs(hEntity._tEquippedItems) do
			v:UpdateNetTable()
			tNetTableItemList[v:entindex()] = true
		end
		hEntity:UpdateInventoryNetTable()
	end
end

function CContainerEntity:OnEntityRefresh()
	self:RefreshInventory()
end

function CContainerEntity:GetCurrentWeight()
    local fWeight = 0.0
    for k,v in pairs(self._tItemList) do
		if not k:IsNull() then
			fWeight = fWeight + k:GetRealWeight()
		end
    end
    return fWeight
end

function CContainerEntity:GetCarryCapacity()
	return (self:GetAttributeValue(IW_ATTRIBUTE_STRENGTH) * 2.0)
end

function CContainerEntity:GetEquipFlags()
	return self._nEquipFlags
end

function CContainerEntity:GetEquippedItem(nSlot)
	return self._tEquippedItems[nSlot]
end

function CContainerEntity:GetItemList()
	return self._tItemList
end

function CContainerEntity:IsInventoryEmpty()
	return (next(self._tItemList) == nil)
end

function CContainerEntity:GetGoldAmount()
	return self._nGoldAmount
end

function CContainerEntity:SetGoldAmount(nAmount)
	if type(nAmount) == "number" then
		self._nGoldAmount = nAmount
		self:UpdateInventoryNetTable()
	end
end

function CContainerEntity:AddGoldAmount(nAmount)
	if type(nAmount) == "number" then
		self._nGoldAmount = self._nGoldAmount + nAmount
		self:UpdateInventoryNetTable()
	end
end

function CContainerEntity:SetIgnoreWeight(bValue)
	if type(bValue) == "boolean" then
		self._bIgnoreWeight = bValue
		self:UpdateInventoryNetTable()
	end
end

function CContainerEntity:SetEquipFlags(nEquipFlags)
	if type(nEquipFlags) == "number" then
		self._nEquipFlags = nEquipFlags
	end
end

function CContainerEntity:EquipItem(hItem, nSlot)
	local nItemSlots = hItem:GetItemSlots()
    if IsValidContainer(self) and IsValidExtendedItem(hItem) and self._tItemList[hItem] then
		if nSlot and bit32.band(nItemSlots, bit32.lshift(1, nSlot - 1)) == 0 then
			return false
		elseif bit32.band(hItem:GetItemType(), self:GetEquipFlags()) ~= hItem:GetItemType() then
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
					--[[if bit32.band(hItem:GetItemFlags(), IW_ITEM_FLAG_IS_ATTACK_SOURCE) ~= 0 then
						hEntity:AddAttackSource(hItem, 1)
					end]]
					if hItem:IsAttackSource() then
						hItem:AddChild(self)
					else
						self:AddChild(hItem)
					end
					hItem:ApplyModifiers(IW_MODIFIER_ON_EQUIP, self)
				end
				hItem:UpdateNetTable()
				self._tEquippedItems[i] = hItem
				self._tInventoryNetTable.item_list[hItem:entindex()] = true
				self._tNetTable.equipped[i] = hItem:entindex()
				self:RefreshEntity()
				self:RefreshLoadout()
				
				local tEntityMetatable = getmetatable(self).__index
				while type(tEntityMetatable) == "table" do
					local hEventFunction = rawget(tEntityMetatable, "OnEquip")
					if hEventFunction then
						hEventFunction(self, hItem, i)
					end
					local tParentMetatable = getmetatable(tEntityMetatable)
					if tParentMetatable then
						tEntityMetatable = tParentMetatable.__index
					else
						break
					end
				end
				return true
			end
		end
	end
	return false
end

function CContainerEntity:UnequipItem(nSlot)
    local hItem = self._tEquippedItems[nSlot]
	if IsValidExtendedEntity(self) and IsValidExtendedItem(hItem) then
		if bit32.band(hItem:GetItemFlags(), IW_ITEM_FLAG_CANNOT_UNEQUIP) ~= 0 then return false end
		--[[if nSlot == IW_INVENTORY_SLOT_MAIN_HAND or nSlot == IW_INVENTORY_SLOT_OFF_HAND then
			hEntity:RemoveAttackSource(hItem, 1)
		end]]
		if hItem:IsAttackSource() then
			hItem:RemoveChild(self)
		else
			self:RemoveChild(hItem)
		end
		hItem:RemoveModifiers(IW_MODIFIER_ON_EQUIP)
		hItem:UpdateNetTable()
		self._tEquippedItems[nSlot] = nil
		self._tInventoryNetTable.item_list[hItem:entindex()] = true
		self._tInventoryNetTable.equipped[nSlot] = nil
		self:RefreshEntity()
		self:RefreshLoadout()
		
		local tEntityMetatable = getmetatable(self).__index
		while type(tEntityMetatable) == "table" do
			local hEventFunction = rawget(tEntityMetatable, "OnUnequip")
			if hEventFunction then
				hEventFunction(self, hItem)
			end
			local tParentMetatable = getmetatable(tEntityMetatable)
			if tParentMetatable then
				tEntityMetatable = tParentMetatable.__index
			else
				break
			end
		end
		return true
	end
	return false
end

function CContainerEntity:DropItem(hItem)
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
		
		hItem:RemoveModifiers(IW_MODIFIER_ON_ACQUIRE, self)
		local vDropPosition = self._hEntity:GetAbsOrigin() + RandomVector(32.0)
		hInventoryUnit:DropItemAtPositionImmediate(hItem, GetGroundPosition(vDropPosition, self._hEntity))
		local hItemContainer = hItem:GetContainer()
		if not hItemContainer then
			CreateItemOnPositionSync(vDropPosition, hItem)
		end
		self._tItemList[hItem] = nil
		self._tInventoryNetTable.item_list[hItem:entindex()] = nil
		self:RefreshInventory()
	end
end

function CContainerEntity:RemoveItem(hItem)
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
		
		hItem:RemoveModifiers(IW_MODIFIER_ON_ACQUIRE, self)
		self._tItemList[hItem] = nil
		self._tInventoryNetTable.item_list[hItem:entindex()] = nil
		self:RefreshInventory()
    end
end

function CContainerEntity:TransferItem(hItem, hTarget)
	if self._tItemList[hItem] and IsValidContainer(hTarget) and hTarget ~= self then
		local nItemIndex = hItem:entindex()
		if hTarget:AddItemToInventory(hItem) then
			self:RemoveItem(hItem)
		else
			hItem:UpdateNetTable()
			self._tInventoryNetTable.item_list[nItemIndex] = true
			self:RefreshInventory()
		end
	end
end

local function MoveItemToDummy(hEntity, hItem)
	for k,v in pairs(hEntity._tInventoryUnits) do
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
		hEntity._tInventoryUnits[hInventoryUnit] = 0
		hItem:SetPurchaser(hInventoryUnit)
		hInventoryUnit:AddItem(hItem)
		hEntity:DropItemAtPositionImmediate(hItem, hEntity:GetAbsOrigin())
		local hContainer = hItem:GetContainer()
		if hContainer then hContainer:RemoveSelf() end
		return hInventoryUnit
	end
end

function CContainerEntity:AddItemToInventory(hItem)
	if IsValidExtendedItem(hItem) then
		local nAmount = hItem:GetStackCount()
		if not self._bIgnoreWeight and self:GetCarryCapacity() > 0 then
			nAmount = math.min(nAmount, math.floor((self:GetCarryCapacity() - self:GetCurrentWeight())/hItem:GetWeight()))
		end
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
					self._tInventoryNetTable.item_list[hInventoryItem:entindex()] = true
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
				hItem = CExtItem(CreateItem(szItemName, self, self))
				bIsNewStack = true
			else
				return false
			end
		end
			
		local hInventoryUnit = MoveItemToDummy(self, hItem)
		--TODO: Change this to have a context menu for identifying instead.
		--[[if self:GetPropertyValue(IW_PROPERTY_SKILL_LORE) >= hItem:GetIdentifyLevel() then
			hItem:Identify()
		end]]
		hItem:ApplyModifiers(IW_MODIFIER_ON_ACQUIRE, self._hEntity)
		hItem:SetPurchaser(self._hEntity)
		hItem:SetStackCount(nAmount)
		hItem:UpdateNetTable()
		self._tItemList[hItem] = hInventoryUnit
		self._tInventoryNetTable.item_list[hItem:entindex()] = true
		self._tInventoryUnits[hInventoryUnit] = self._tInventoryUnits[hInventoryUnit] + 1
		self:EquipItem(hItem)
		self:RefreshInventory()
		return not bIsNewStack
	end
	return false
end

function IsValidContainer(hEntity)
    return (IsValidEntity(hEntity) and IsInstanceOf(hEntity, CContainerEntity))
end

local function OnInventoryEquipEvent(args)
	local hEntity = EntIndexToHScript(args.entindex)
	if IsValidContainer(hEntity) and hInventory then
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

local function OnInventoryDropEvent(args)
	local hEntity = EntIndexToHScript(args.entindex)
	if IsValidContainer(hEntity) then
		local hItem = EntIndexToHScript(args.itemindex)
		hEntity:DropItem(hItem)
	end
end

local function OnInventoryUseEvent(args)
	local hEntity = EntIndexToHScript(args.entindex)
	if IsValidContainer(hEntity) then
		local hItem = EntIndexToHScript(args.itemindex)
		local hInventoryUnit = hEntity._tItemList[hItem]
		if hItem and hInventoryUnit then
			--[[if not hEntity:HasItemInInventory(hItem:GetAbilityName()) then
				hEntity:AddItem(hItem)
			end]]
			CustomGameEventManager:Send_ServerToAllClients("iw_inventory_use_item", args)
		end
	end
end

local function OnInventoryUseFinishEvent(args)
	local hEntity = EntIndexToHScript(args.entindex)
	local hOwner = hEntity:GetOwner()
	if IsValidContainer(hEntity) then
		local hItem = EntIndexToHScript(args.itemindex)
		if hItem and hEntity._tItemList[hItem] then
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

local function OnLootableTakeEvent(args)
	local hEntity = EntIndexToHScript(args.entindex)
	local hLootable = EntIndexToHScript(args.lootable)
	if IsValidContainer(hEntity) and IsValidContainer(hLootable) then
		local hItem = EntIndexToHScript(args.itemindex)
		hLootable:TransferItem(hItem, hEntity)
	end
end

local function OnLootableStoreEvent(args)
	local hEntity = EntIndexToHScript(args.entindex)
	local hLootable = EntIndexToHScript(args.lootable)
	if IsValidContainer(hEntity) and IsValidContainer(hLootable) then
		local hItem = EntIndexToHScript(args.itemindex)
		hEntity:TransferItem(hItem, hLootable)
	end
end

CustomGameEventManager:RegisterListener("iw_inventory_equip_item", OnInventoryEquipEvent)
CustomGameEventManager:RegisterListener("iw_inventory_drop_item", OnInventoryDropEvent)
CustomGameEventManager:RegisterListener("iw_inventory_use_item", OnInventoryUseEvent)
CustomGameEventManager:RegisterListener("iw_inventory_use_finish", OnInventoryUseFinishEvent)
CustomGameEventManager:RegisterListener("iw_lootable_take_item", OnLootableTakeEvent)
CustomGameEventManager:RegisterListener("iw_lootable_store_item", OnLootableStoreEvent)

end