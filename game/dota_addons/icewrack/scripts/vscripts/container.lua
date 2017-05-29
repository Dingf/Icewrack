if not CContainer then

require("instance")
require("interactable")
require("inventory")
require("loot_list")

local stInteractableData = LoadKeyValues("scripts/npc/npc_interactables_extended.txt")

local tIndexTableList = {}
CContainer = setmetatable({}, { __call =
	function(self, hEntity, nInstanceID, bGenerateLootTable)
		LogAssert(IsInstanceOf(hEntity, CDOTA_BaseNPC), "Type mismatch (expected \"%s\", got %s)", "CDOTA_BaseNPC", type(hEntity))
		if hEntity._bIsContainer then
			return hEntity
		end
		
		local tInteractableTemplate = stInteractableData[hEntity:GetUnitName()] or {}
		if not IsValidInstance(hEntity) then
			hEntity = CInstance(hEntity, nInstanceID)
		end
		hEntity = CInteractable(hEntity)
		
		local tBaseIndexTable = getmetatable(hEntity).__index
		local tExtIndexTable = tIndexTableList[tBaseIndexTable]
		if not tExtIndexTable then
			tExtIndexTable = ExtendIndexTable(hEntity, CContainer)
			tExtIndexTable.__index._bIsContainer = true
			tIndexTableList[tBaseIndexTable] = tExtIndexTable
		end
		setmetatable(hEntity, tExtIndexTable)
		
		hEntity._bIsContainer = true
		
		local hInventory = CInventory(hEntity)
		local hLootList = CLootList(tInteractableTemplate.LootList)
		if bGenerateLootTable and hInventory and hLootList then
			local tLootList = hLootList:GenerateLootList()
			for k,v in pairs(tLootList) do
				hInventory:AddItemToInventory(v)
			end
		end
		
		return hEntity
	end
})

function CContainer:Interact(hEntity)
	if hEntity:IsRealHero() then
		CustomGameEventManager:Send_ServerToAllClients("iw_lootable_interact", { entindex = hEntity:entindex(), lootable = self:entindex() })
		return true
	end
end

function CContainer:InteractFilterInclude(hEntity)
	return hEntity:IsRealHero()
end

function CContainer:GetCustomInteractError(hEntity)
end

function IsValidContainer(hEntity)
    return (IsValidInstance(hEntity) and IsValidEntity(hEntity) and hEntity._bIsContainer == true)
end

end