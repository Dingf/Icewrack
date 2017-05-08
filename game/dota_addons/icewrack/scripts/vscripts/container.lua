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

function CContainer:OnInteract(hEntity)
	CustomGameEventManager:Send_ServerToAllClients("iw_lootable_interact", { entindex = hEntity:entindex(), lootable = self:entindex() })
end

function CContainer:InteractFilter(hEntity)
	return hEntity:IsRealHero()
end

function CContainer:GetCustomInteractError(hEntity)
end

function IsValidContainer(hProp)
    return (IsValidInstance(hProp) and IsValidEntity(hProp) and hProp._bIsContainer == true)
end

end