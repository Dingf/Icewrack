if not CContainer then

require("entity_base")
require("ext_item")

local stItemListData = LoadKeyValues("scripts/npc/iw_item_lists.txt")
local stContainerData = LoadKeyValues("scripts/npc/npc_containers.txt")

local shItemDeniableModifier = CreateItem("item_internal_deniable", nil, nil)

CContainer = setmetatable(ext_class({}), { __call =
	function(self, hEntity, nInstanceID)
		LogAssert(IsInstanceOf(hEntity, CDOTA_BaseNPC), LOG_MESSAGE_ASSERT_TYPE, "CDOTA_BaseNPC")
		if IsInstanceOf(hEntity, CContainer) then
			LogMessage(LOG_MESSAGE_WARN_EXISTS, LOG_SEVERITY_WARNING, "CContainer", hEntity:GetUnitName())
			return hEntity
		end
		
		local tContainerTemplate = stContainerData[hEntity:GetUnitName()] or {}
		
		if not IsInstanceOf(hEntity, CEntityBase) then
			hEntity = CEntityBase(hEntity, nInstanceID)
		end
		ExtendIndexTable(hEntity, CContainer)
		
		hEntity._tItemList = {}
		hEntity._tInventoryUnits = {}
		hEntity._tEquippedItems = {}
		hEntity._nEquipFlags = 0
		
		hEntity._nGoldAmount = 0
		hEntity._bCanExceedCapacity = false
		hEntity._nLockLevel = tContainerTemplate.LockLevel or 0
		hEntity._fCarryCapacity = tContainerTemplate.CarryCapacity or 0
		
		hEntity:SetInteractRange(tContainerTemplate.InteractRange)
		hEntity:SetInteractZone(tContainerTemplate.InteractZone)
		
		hEntity:AddNewModifier(hEntity, shItemDeniableModifier, "modifier_internal_deniable", {})
		
		hEntity._tInventoryNetTable =
		{
			item_list = {},
			equipped = {},
		}
		
		return hEntity
	end
})

function CContainer:Interact(hEntity)
	if hEntity:IsRealHero() then
		if self:GetLockLevel() > 0 then
	
		else
			CustomGameEventManager:Send_ServerToAllClients("iw_lootable_interact", { entindex = hEntity:entindex(), lootable = self:entindex() })
		end
		return true
	end
end

function CContainer:InteractFilter(hEntity)
	return not self:IsAlive()
end

function CContainer:GetCustomInteractError(hEntity)
end

function CContainer:GenerateItemList()
	local tContainerTemplate = stContainerData[self:GetUnitName()] or {}
	if tContainerTemplate and tContainerTemplate.ItemList then
		for k,v in pairs(tContainerTemplate.ItemList) do
			local hPrecondition = LoadFunctionSnippet(v.Precondition)
			if RandomFloat(0.0, 100.0) < v.Chance and (not hPrecondition or hPrecondition()) then
				local tItemList = stItemListData[v.Name]
				if tItemList then
					local nWeightSum = 0
					for k2,v2 in pairs(tItemList) do
						nWeightSum = nWeightSum + v2.Weight
					end
					local fResult = RandomFloat(0.0, nWeightSum)
					for k2,v2 in pairs(tItemList) do
						fResult = fResult - v2.Weight
						if fResult <= 0 then
							local hItem = CExtItem(CreateItem(k2, nil, nil))
							hItem:SetStackCount(RandomInt(v2.Min, v2.Max))
							self:AddItemToInventory(hItem)
							break
						end
					end
				end
			end
		end
	end
end

function CContainer:UpdateInventoryNetTable()
	self._tInventoryNetTable.weight = self:GetCarryWeight()
	self._tInventoryNetTable.weight_max = self:GetCarryCapacity()
	self._tInventoryNetTable.gold = self:GetGoldAmount()
	CustomNetTables:SetTableValue("inventory", tostring(self:entindex()), self._tInventoryNetTable)
end

function CContainer:RefreshInventory()
	local tNetTableItemList = self._tInventoryNetTable.item_list
	for k,v in pairs(self._tEquippedItems) do
		v:UpdateItemNetTable()
		tNetTableItemList[v:entindex()] = true
	end
	self:UpdateInventoryNetTable()
end

function CContainer:OnRefreshEntity()
	self:RefreshInventory()
end

function CContainer:GetCarryWeight()
    local fWeight = 0.0
    for k,v in pairs(self._tItemList) do
		if not k:IsNull() then
			fWeight = fWeight + k:GetRealWeight()
		end
    end
    return fWeight
end

function CContainer:GetCarryCapacity()
	return self._fCarryCapacity
end

function CContainer:GetEquipFlags()
	return self._nEquipFlags
end

function CContainer:GetEquippedItem(nSlot)
	return self._tEquippedItems[nSlot]
end

function CContainer:GetItemList()
	return self._tItemList
end

function CContainer:GetCanCarryAmount(hItem)
	local nAmount = hItem:GetStackCount()
	if self:GetCarryCapacity() > 0 and not self:CanExceedCarryCapacity() then
		nAmount = math.min(nAmount, math.floor((self:GetCarryCapacity() - self:GetCarryWeight())/hItem:GetWeight()))
	end
	return nAmount
end

function CContainer:IsInventoryEmpty()
	for k,v in pairs(self._tItemList) do
		if not bit32.btest(k:GetItemFlags(), IW_ITEM_FLAG_HIDDEN) then
			return false
		end
	end
	return true
end

function CContainer:IsAlive()
	return false
end

function CContainer:CanExceedCarryCapacity()
	return self._bCanExceedCapacity
end

function CContainer:GetGoldAmount()
	return self._nGoldAmount
end

function CContainer:SetGoldAmount(nAmount)
	if type(nAmount) == "number" then
		self._nGoldAmount = nAmount
		self:UpdateInventoryNetTable()
	end
end

function CContainer:AddGoldAmount(nAmount)
	if type(nAmount) == "number" then
		self._nGoldAmount = self._nGoldAmount + nAmount
		self:UpdateInventoryNetTable()
	end
end

function CContainer:GetLockLevel(nLockLevel)
	return self._nLockLevel
end

function CContainer:SetLockLevel(nLockLevel)
	if type(nLockLevel) == "number" then
		self._nLockLevel = nLockLevel
	end
end

function CContainer:SetEquipFlags(nEquipFlags)
	if type(nEquipFlags) == "number" then
		self._nEquipFlags = nEquipFlags
	end
end

function CContainer:EquipItem(hItem, nSlot)
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
				hItem:UpdateItemNetTable()
				self._tEquippedItems[i] = hItem
				self._tInventoryNetTable.item_list[hItem:entindex()] = true
				self._tInventoryNetTable.equipped[i] = hItem:entindex()
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

function CContainer:UnequipItem(nSlot)
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
		hItem:UpdateItemNetTable()
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

function CContainer:DropItem(hItem)
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
		
		hItem:SetOwner(nil)
		hItem:RemoveModifiers(IW_MODIFIER_ON_ACQUIRE, self)
		local vDropPosition = self:GetAbsOrigin() + RandomVector(32.0)
		hInventoryUnit:DropItemAtPositionImmediate(hItem, GetGroundPosition(vDropPosition, self))
		local hItemContainer = hItem:GetContainer()
		if not hItemContainer then
			CreateItemOnPositionSync(vDropPosition, hItem)
		end
		self._tItemList[hItem] = nil
		self._tInventoryNetTable.item_list[hItem:entindex()] = nil
		self:RefreshEntity()
	end
end

function CContainer:RemoveItem(hItem, bSkipRefresh)
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
		
		hItem:SetOwner(nil)
		hItem:RemoveModifiers(IW_MODIFIER_ON_ACQUIRE, self)
		self._tItemList[hItem] = nil
		self._tInventoryNetTable.item_list[hItem:entindex()] = nil
		if not bSkipRefresh then
			self:RefreshEntity()
		end
    end
end

function CContainer:TransferItem(hItem, hTarget)
	if self._tItemList[hItem] and IsValidContainer(hTarget) and hTarget ~= self then
		local nItemIndex = hItem:entindex()
		if hTarget:AddItemToInventory(hItem) then
			self:RemoveItem(hItem)
		else
			hItem:UpdateItemNetTable()
			self._tInventoryNetTable.item_list[nItemIndex] = true
			self:RefreshEntity()
		end
	end
end

function CContainer:TransferAllItems(hTarget)
	if IsValidContainer(hTarget) and hTarget ~= self then
		for k,v in pairs(self._tItemList) do
			if hTarget:AddItemToInventory(k, true) then
				self:RemoveItem(k, true)
			else
				k:UpdateItemNetTable()
				self._tInventoryNetTable.item_list[nItemIndex] = true
			end
		end
		self:RefreshEntity()
		hTarget:RefreshEntity()
	end
end

local function MoveItemToDummy(hEntity, hItem)
	for k,v in pairs(hEntity._tInventoryUnits) do
		if v < 6 then
			k:AddItem(hItem)
			return k
		end
	end
	
	local hInventoryUnit = CreateDummyUnit(hEntity:GetAbsOrigin(), hEntity:GetOwner(), hEntity:GetTeamNumber(), true)
	if hInventoryUnit and IsValidEntity(hInventoryUnit) then
		hInventoryUnit:SetControllableByPlayer(0, false)
		hInventoryUnit:SetThink(function() hInventoryUnit:SetAbsOrigin(hEntity:GetAbsOrigin() + Vector(100, 0, 0)) return 0.1 end)
		hEntity._tInventoryUnits[hInventoryUnit] = 0
		hItem:SetPurchaser(hInventoryUnit)
		hInventoryUnit:AddItem(hItem)
		hEntity:DropItemAtPositionImmediate(hItem, hEntity:GetAbsOrigin())
		local hContainer = hItem:GetContainer()
		if hContainer then hContainer:RemoveSelf() end
		return hInventoryUnit
	end
end

function CContainer:AddItemToInventory(hItem, bSkipRefresh)
	if IsValidExtendedItem(hItem) then
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
					hInventoryItem:UpdateItemNetTable()
					self._tInventoryNetTable.item_list[hInventoryItem:entindex()] = true
					if nOverflow > 0 then
						nAmount = nOverflow
						hItem:SetStackCount(nOverflow)
					else
						hItem:SetThink(function() hItem:RemoveSelf() end, "ItemStackRemove", 0.03)
						self:RefreshEntity()
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
		hItem:ApplyModifiers(IW_MODIFIER_ON_ACQUIRE, self)
		hItem:SetPurchaser(self)
		hItem:SetOwner(self)
		hItem:SetStackCount(nAmount)
		hItem:UpdateItemNetTable()
		self._tItemList[hItem] = hInventoryUnit
		self._tInventoryUnits[hInventoryUnit] = self._tInventoryUnits[hInventoryUnit] + 1
		self._tInventoryNetTable.item_list[hItem:entindex()] = true
		self:EquipItem(hItem)	--TODO: Make an autoequip option that will change whether or not this gets called
		if not bSkipRefresh then
			self:RefreshEntity()
		end
		return not bIsNewStack
	end
	return false
end

function CContainer:OnContainerDestroyed()
	local tItemList = {}
	for k,v in pairs(self._tItemList) do
		table.insert(tItemList, k)
	end
	
	for k,v in pairs(tItemList) do
		if RandomFloat(0.0, 100.0) < 50.0 then	--TODO: Make this not just 50%, but determined based on item or something?
			self:DropItem(v)
			local nPosIterations = 0
			local vTargetPos = self:GetAbsOrigin() + RandomVector(RandomFloat(50, 150))
			while not GridNav:IsTraversable(vTargetPos) and nPosIterations < 10 do
				nPosIterations = nPosIterations + 1
				vTargetPos = self:GetAbsOrigin() + RandomVector(RandomFloat(10, 150))
			end
			local fLaunchHeight = RandomFloat(200.0, 300.0)
			v:LaunchLoot(false, fLaunchHeight, fLaunchHeight * 0.0025, vTargetPos)
		end
	end
	
	for k,v in pairs(self._tInventoryUnits) do
		k:RemoveSelf()
	end
	
	self:SetInstanceState(false)
	CustomNetTables:SetTableValue("inventory", tostring(self:entindex()), nil)
end

function IsValidContainer(hEntity)
    return (IsValidEntity(hEntity) and IsInstanceOf(hEntity, CContainer))
end

local CContainerEventHandler = {}
function CContainerEventHandler:OnInventoryEquipEvent(args)
	local hEntity = EntIndexToHScript(args.entindex)
	if IsValidContainer(hEntity) then
		if args.itemindex == -1 then
			hEntity:UnequipItem(args.slot)
		else
			local hItem = EntIndexToHScript(args.itemindex)
			if hItem then
				local nSourceSlot = nil
				for i = 1,IW_MAX_INVENTORY_SLOT-1 do
					if hEntity._tEquippedItems[i] == hItem then
						nSourceSlot = i
						break
					end
				end
				if nSourceSlot then
					local hItem2 = hEntity._tEquippedItems[args.slot]
					if hItem2 then
						hEntity:EquipItem(hItem2, nSourceSlot)
					end
					hEntity:EquipItem(hItem, args.slot)
				else
					hEntity:EquipItem(hItem, args.slot)
				end
			end
		end
	end
end

function CContainerEventHandler:OnInventoryDropEvent(args)
	local hEntity = EntIndexToHScript(args.entindex)
	if IsValidContainer(hEntity) then
		local hItem = EntIndexToHScript(args.itemindex)
		hEntity:DropItem(hItem)
	end
end

function CContainerEventHandler:OnInventoryUseEvent(args)
	local hEntity = EntIndexToHScript(args.entindex)
	if IsValidContainer(hEntity) then
		local hItem = EntIndexToHScript(args.itemindex)
		local hInventoryUnit = hEntity._tItemList[hItem]
		if hItem and hInventoryUnit then
			if hEntity._hInventoryItem then
				hEntity:DropItemAtPositionImmediate(hEntity._hInventoryItem, hEntity:GetAbsOrigin())
				local hContainer = hEntity._hInventoryItem:GetContainer()
				if hContainer then hContainer:RemoveSelf() end
			end
			if not hEntity:HasItemInInventory(hItem:GetAbilityName()) then
				hEntity:AddItem(hItem)
				hEntity._hInventoryItem = hItem
			end
			CustomGameEventManager:Send_ServerToAllClients("iw_inventory_use_item", args)
		end
	end
end

function CContainerEventHandler:OnInventoryUseFinishEvent(args)
	local hEntity = EntIndexToHScript(args.entindex)
	local hOwner = hEntity:GetOwner()
	if IsValidContainer(hEntity) then
		local hItem = EntIndexToHScript(args.itemindex)
		if hItem and hEntity._tItemList[hItem] then
			--[[if hEntity:GetCurrentAction() == hItem:GetAbilityName() then
				hEntity:SetThink(function()
					if not hItem or hItem:IsNull() then return nil
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

function CContainerEventHandler:OnLootableTakeEvent(args)
	local hEntity = EntIndexToHScript(args.entindex)
	local hLootable = EntIndexToHScript(args.lootable)
	if IsValidContainer(hEntity) and IsValidContainer(hLootable) then
		local hItem = EntIndexToHScript(args.itemindex)
		hLootable:TransferItem(hItem, hEntity)
	end
end

function CContainerEventHandler:OnLootableStoreEvent(args)
	local hEntity = EntIndexToHScript(args.entindex)
	local hLootable = EntIndexToHScript(args.lootable)
	if IsValidContainer(hEntity) and IsValidContainer(hLootable) then
		local hItem = EntIndexToHScript(args.itemindex)
		hEntity:TransferItem(hItem, hLootable)
	end
end

function CContainerEventHandler:OnLootableTakeAllEvent(args)
	local hEntity = EntIndexToHScript(args.entindex)
	local hLootable = EntIndexToHScript(args.lootable)
	if IsValidContainer(hEntity) and IsValidContainer(hLootable) then
		hLootable:TransferAllItems(hEntity)
	end
end

CustomGameEventManager:RegisterListener("iw_inventory_equip_item", CContainerEventHandler.OnInventoryEquipEvent)
CustomGameEventManager:RegisterListener("iw_inventory_drop_item", CContainerEventHandler.OnInventoryDropEvent)
CustomGameEventManager:RegisterListener("iw_inventory_use_item", CContainerEventHandler.OnInventoryUseEvent)
CustomGameEventManager:RegisterListener("iw_inventory_use_finish", CContainerEventHandler.OnInventoryUseFinishEvent)
CustomGameEventManager:RegisterListener("iw_lootable_take_item", CContainerEventHandler.OnLootableTakeEvent)
CustomGameEventManager:RegisterListener("iw_lootable_store_item", CContainerEventHandler.OnLootableStoreEvent)
CustomGameEventManager:RegisterListener("iw_lootable_take_all", CContainerEventHandler.OnLootableTakeAllEvent)

end