--[[
    Icewrack Extended Item
]]

if not CExtItem then

if _VERSION < "Lua 5.2" then
    bit = require("lib/numberlua")
    bit32 = bit.bit32
end

require("instance")
require("link_ext_ability")

local stExtItemTypeEnum =
{
	IW_ITEM_TYPE_WEAPON_1H = 1,        IW_ITEM_TYPE_WEAPON_2H = 2,        IW_ITEM_TYPE_WEAPON_SWORD = 3,     IW_ITEM_TYPE_WEAPON_MACE = 4,
	IW_ITEM_TYPE_WEAPON_AXE = 5,       IW_ITEM_TYPE_WEAPON_DAGGER = 6,    IW_ITEM_TYPE_WEAPON_STAFF = 7,     IW_ITEM_TYPE_WEAPON_BOW = 8,
	IW_ITEM_TYPE_WEAPON_AMMO = 9,      IW_ITEM_TYPE_ARMOR_MAIL = 10,      IW_ITEM_TYPE_ARMOR_LEATHER = 11,   IW_ITEM_TYPE_ARMOR_CLOTH = 12,
	IW_ITEM_TYPE_ARMOR_HEAD = 13,      IW_ITEM_TYPE_ARMOR_BODY = 14,      IW_ITEM_TYPE_ARMOR_HANDS = 15,     IW_ITEM_TYPE_ARMOR_FEET = 16,
	IW_ITEM_TYPE_ARMOR_WAIST = 17,     IW_ITEM_TYPE_ARMOR_SHIELD = 18,    IW_ITEM_TYPE_JEWELRY_AMULET = 19,  IW_ITEM_TYPE_JEWELRY_RING = 20,
	IW_ITEM_TYPE_USEABLE_POTION = 21,  IW_ITEM_TYPE_USEABLE_ELIXIR = 22,  IW_ITEM_TYPE_USEABLE_WAND = 23,    IW_ITEM_TYPE_USEABLE_RECIPE = 24,
	IW_ITEM_TYPE_USEABLE_BOOK = 25,    IW_ITEM_TYPE_USEABLE_FOOD = 26,    IW_ITEM_TYPE_REAGENT_HERB = 27,    IW_ITEM_TYPE_REAGENT_METAL = 28,
	IW_ITEM_TYPE_REAGENT_LEATHER = 29, IW_ITEM_TYPE_REAGENT_CLOTH = 30,   IW_ITEM_TYPE_REAGENT_WOOD = 31,    IW_ITEM_TYPE_REAGENT_GEM = 32,     
}

local stExtItemSlotEnum = 
{
	IW_INVENTORY_SLOT_NONE = 0,    IW_INVENTORY_SLOT_MAIN_HAND = 1, IW_INVENTORY_SLOT_OFF_HAND = 2, IW_INVENTORY_SLOT_HEAD = 3,
	IW_INVENTORY_SLOT_BODY = 4,    IW_INVENTORY_SLOT_HANDS = 5,     IW_INVENTORY_SLOT_FEET = 6,     IW_INVENTORY_SLOT_WAIST = 7,
	IW_INVENTORY_SLOT_LRING = 8,   IW_INVENTORY_SLOT_RRING = 9,     IW_INVENTORY_SLOT_NECK = 10,    IW_INVENTORY_SLOT_QUICK1 = 11,
	IW_INVENTORY_SLOT_QUICK2 = 12, IW_INVENTORY_SLOT_QUICK3 = 13,   IW_INVENTORY_SLOT_QUICK4 = 14,  IW_MAX_INVENTORY_SLOT = 15
}

local stExtItemFlagEnum =
{
	IW_ITEM_FLAG_NONE = 0,
	IW_ITEM_FLAG_HIDDEN = 1,				--TODO: Do not display this item in the Inventory list
	IW_ITEM_FLAG_UNIQUE = 2,				--TODO: A character cannot carry more than one of this item at a time
	IW_ITEM_FLAG_QUEST = 4,					--TODO: Quest-related item, cannot be dropped
	IW_ITEM_FLAG_ATTACK_SOURCE = 8,			--Use the stats of this item when performing an attack
	IW_ITEM_FLAG_MAIN_HAND_ONLY = 16,		--TODO: This item can only be equipped in the main hand
	IW_ITEM_FLAG_OFF_HAND_ONLY = 32,		--TODO: This item can only be equipped in the off hand
	IW_ITEM_FLAG_CANNOT_UNEQUIP = 64,		--This item cannot be unequipped (TODO: Make it so that these items don't autoequip)
	IW_ITEM_FLAG_REQUIRES_AMMO = 128,		--TODO: If this item is an attack source, it needs ammo in the other hand to attack with
	IW_ITEM_FLAG_THROWN = 256,				--TODO: When attacking with this item, remove a stack
	IW_ITEM_FLAG_CAN_ACTIVATE = 512,		--This item has the "Activate" context menu option
	IW_ITEM_FLAG_CAN_READ = 1024,			--This item has the "Read" context menu option
}

for k,v in pairs(stExtItemTypeEnum) do _G[k] = v end
for k,v in pairs(stExtItemSlotEnum) do _G[k] = v end
for k,v in pairs(stExtItemFlagEnum) do _G[k] = v end

local stBaseItemData = LoadKeyValues("scripts/npc/npc_items_custom.txt")
local stExtItemData = LoadKeyValues("scripts/npc/npc_items_extended.txt")

local tIndexTableList = {}
CExtItem = setmetatable({}, { __call = 
	function(self, hItem, nInstanceID)
		LogAssert(IsInstanceOf(hItem, CDOTA_Item), "Type mismatch (expected \"%s\", got %s)", "CDOTA_Item", type(hItem))
		if hItem._bIsExtendedItem then
			return hItem
		end
		
		hItem = CInstance(hItem, nInstanceID)
		local tBaseIndexTable = getmetatable(hItem).__index
		local tExtIndexTable = tIndexTableList[tBaseIndexTable]
		if not tExtIndexTable then
			tExtIndexTable = ExtendIndexTable(hItem, CExtAbilityLinker, CExtItem)
			tIndexTableList[tBaseIndexTable] = tExtIndexTable
		end
		setmetatable(hItem, tExtIndexTable)
		
		local szItemName = hItem:GetName()
		local tBaseItemTemplate = stBaseItemData[szItemName]
		local tExtItemTemplate = stExtItemData[szItemName]
		LogAssert(tBaseItemTemplate, "Failed to load template \"%d\" - no data exists for this entry.", szItemName)
		LogAssert(tExtItemTemplate, "Failed to load template \"%d\" - no data exists for this entry.", szItemName)
		
		hItem._bIsExtendedItem = true
		
		hItem._nItemType  = GetBitshiftedFlagValue(tExtItemTemplate.ItemType, stExtItemTypeEnum)
		hItem._nItemSlots = GetBitshiftedFlagValue(tExtItemTemplate.ItemSlots, stExtItemSlotEnum)
		hItem._nItemFlags = GetFlagValue(tExtItemTemplate.ItemFlags, stExtItemFlagEnum)
		
		hItem._nIdentifyLevel = tonumber(tExtItemTemplate.IdentifyLevel) or 0
		hItem._bIsIdentified = (hItem._nIdentifyLevel == 0)
		hItem._nStackCount = 1
		hItem._nMaxStacks = tExtItemTemplate.MaxStacks or 1
		hItem._fWeight = tExtItemTemplate.ItemWeight or 0.0
		hItem._fValue = tExtItemTemplate.ItemValue or 0.0
		
		hItem._tModifierList = {}
		hItem._tActiveModifierList = {}
		hItem._tModifierSeeds = {}
		for k,v in pairs(tBaseItemTemplate.Modifiers or {}) do
			hItem._tModifierList[k] = _G[v]
			hItem._tModifierSeeds[k] = {}
		end
		
		hItem._tComponentList = {}
		hItem._tNetTableComponentList = {}
		if not nInstanceID then
			for k,v in pairs(tExtItemTemplate.ItemComponents or {}) do
				local nNumberIndex = string.find(k, "#")
				if nNumberIndex then k = string.sub(k, 0, nNumberIndex - 1) end
				local hComponent = CExtItem(CreateItem(k, hItem:GetOwner(), hItem:GetOwner()))
				if IsValidExtendedItem(hComponent) then
					hItem._tComponentList[hComponent] = v
					hItem._tNetTableComponentList[hComponent:entindex()] = v
					hItem:AddChild(hComponent)
				end
			end
		end
		
		hItem._tPropertySeeds = {}
		hItem._tPropertyList = {}
		for k,v in pairs(tExtItemTemplate.Properties or {}) do
			if stIcewrackPropertyEnum[k] then
				local nPropertyID = stIcewrackPropertyEnum[k]
				local szPropertyType = type(v)
				if szPropertyType == "table" then
					local k2,v2 = next(v)
					k2 = tonumber(k2)
					v2 = tonumber(v2)
					if type(k2) == "number" and type(v2) == "number" then
						hItem._tPropertySeeds[nPropertyID] = RandomInt(0, 2147483647)
						hItem._tPropertyList[nPropertyID] = v
						hItem:SetPropertyValue(nPropertyID, k2 + (hItem._tPropertySeeds[nPropertyID] % v2))
					end
				elseif szPropertyType == "number" then
					hItem:SetPropertyValue(nPropertyID, v)
				else
					LogMessage("Property \"" .. k .. "\" has invalid type \"" .. szPropertyType .. "\"", LOG_SEVERITY_WARNING)
				end
			else
				LogMessage("Unknown property \"" .. k .. "\" in item \"" .. szItemName .. "\"", LOG_SEVERITY_WARNING)
			end
		end
		
		hItem._tNetTable =
		{
			identified = hItem._bIsIdentified,
			modifiers = hItem._tModifierSeeds,
			components = hItem._tNetTableComponentList,
			properties_base = {},
			properties_bonus = {},
		}
		hItem:UpdateNetTable()
			
		return hItem
	end})

function CExtItem:GetItemType()
	return self._nItemType
end

function CExtItem:GetItemSlots()
	return self._nItemSlots
end

function CExtItem:GetItemFlags()
	return self._nItemFlags
end

function CExtItem:GetWeight()
    return self._fWeight
end

function CExtItem:GetRealWeight()
    return self._fWeight * self._nStackCount
end

function CExtItem:GetValue()
    return self._fValue
end

function CExtItem:GetStackCount()
    return self._nStackCount
end

function CExtItem:GetMaxStacks()
    return self._nMaxStacks
end

function CExtItem:GetIdentifyLevel()
	return self._nIdentifyLevel
end

function CExtItem:IsIdentified()
	return (self._bIsIdentified == true)
end

function CExtItem:Identify()
	if not self._bIsIdentified then
		self._bIsIdentified = true
	end
end

function CExtItem:SetStackCount(nStackCount)
    if type(nStackCount) == "number" then
        self._nStackCount = math.max(0, math.min(self._nMaxStacks, nStackCount))
		return nStackCount - self._nStackCount
    end
end

function CExtItem:ModifyStackCount(nStackCount)
    if type(nStackCount) == "number" then
        local nNewStackCount = self._nStackCount + nStackCount
        if nNewStackCount > self._nMaxStacks then
            self._nStackCount = self._nMaxStacks
            return nNewStackCount - self._nMaxStacks
        elseif nNewStackCount < 0 then
            self._nStackCount = 0
            return nNewStackCount
        else
            self._nStackCount = nNewStackCount
            return 0
        end
    end
end

function CExtItem:GetModifierSeed(szModifierName, nPropertyID)
	local tModifierSeeds = self._tModifierSeeds[szModifierName]
	if not tModifierSeeds[nPropertyID] then
		tModifierSeeds[nPropertyID] = RandomInt(0, 2147483647)
	end
	return tModifierSeeds[nPropertyID]
end

function CExtItem:UpdateNetTable()
	local tNetTable  = self._tNetTable
	tNetTable.type   = self:GetItemType()
	tNetTable.flags  = self:GetItemFlags()
	tNetTable.slots  = self:GetItemSlots()
	tNetTable.name   = self:GetAbilityName()
	tNetTable.stack  = self:GetStackCount()
	tNetTable.weight = self:GetWeight()
	tNetTable.value  = self:GetValue()

	local tPropertiesBase = tNetTable.properties_base
	local tPropertiesBonus = tNetTable.properties_bonus
	for k,v in pairs(stIcewrackPropertyEnum) do
		tPropertiesBase[v] = self:GetBasePropertyValue(v)
		tPropertiesBonus[v] = self:GetPropertyValue(v) - tPropertiesBase[v]
	end
	return tNetTable
end

function CExtItem:ApplyModifiers(hEntity, nTrigger)
	if hEntity then
		for k,v in pairs(self._tModifierList) do
			if not nTrigger or v == nTrigger then
				local hModifier = nil
				if IsInstanceOf(self, CDOTA_Item_Lua) then
					hModifier = hEntity:AddNewModifier(hEntity, self, k, {})
				else
					hModifier = self:ApplyDataDrivenModifier(hEntity, hEntity, k, {})
				end
				if hModifier then
					self._tActiveModifierList[hModifier] = v
				end
			end
		end
		for k,v in pairs(self._tComponentList) do
			k:ApplyModifiers(hEntity, nTrigger)
		end
	end
end

function CExtItem:RemoveModifiers(nTrigger)
	for k,v in pairs(self._tActiveModifierList) do
		if not nTrigger or v == nTrigger then
			k:Destroy()
			self._tActiveModifierList[k] = nil
		end
	end
	for k,v in pairs(self._tComponentList) do
		k:RemoveModifiers(nTrigger)
	end
end

function CExtItem:RemoveSelf()
	self:RemoveModifiers(IW_MODIFIER_ON_ACQUIRE)
	for k,v in pairs(self._tComponentList) do
		k:RemoveSelf()
	end
	CEntityInstance.RemoveSelf(self)
end

function IsValidExtendedItem(hItem)
    return (IsValidInstance(hItem) and IsValidEntity(hItem) and hItem._bIsExtendedItem)
end

for k,v in pairs(stBaseItemData) do
	if v.BaseClass == "item_lua" then
		CExtAbilityLinker:LinkExtAbility(k, v, stExtItemData[k] or {})
	end
end

end