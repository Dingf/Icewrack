if not CContainer then

require("instance")
require("interactable")
require("inventory")
require("loot_list")

local stInteractableData = LoadKeyValues("scripts/npc/npc_interactables_extended.txt")

CContainer = setmetatable(ext_class({}), { __call =
	function(self, hEntity, nInstanceID, bGenerateLootTable)
		LogAssert(IsInstanceOf(hEntity, CDOTA_BaseNPC), LOG_MESSAGE_ASSERT_TYPE, "CDOTA_BaseNPC", type(hEntity))
		if hEntity._bIsContainer then
			return hEntity
		end
		
		local tInteractableTemplate = stInteractableData[hEntity:GetUnitName()] or {}
		hEntity = CInteractable(hEntity, nInstanceID)
		ExtendIndexTable(hEntity, CContainer)
		
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
    return (IsValidEntity(hEntity) and IsInstanceOf(hEntity, CContainer))
end

end