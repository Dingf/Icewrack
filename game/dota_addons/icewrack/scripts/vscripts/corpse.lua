if not CCorpseEntity then

require("ext_entity")
require("container")
require("loot_list")

local function CorpseDelayedFunction(hEntity)
	hEntity:RespawnUnit()
	hEntity:SetTeam(DOTA_TEAM_GOODGUYS)
	hEntity:AddItem(hEntity._hCorpseItem)
	
	local hInventory = hEntity:GetInventory()		
	if hInventory:IsEmpty() then
		hEntity._hCorpseItem:ApplyDataDrivenModifier(hEntity, hEntity, "modifier_internal_corpse_unselectable", {})
	else
		hEntity._nCorpseListener = CustomGameEventManager:RegisterListener("iw_lootable_interact", function(_, keys) hEntity:OnCorpseLootableInteract(keys) end)
	end
end

CCorpseEntity = setmetatable({}, { __call = 
	function(self, hEntity, bGenerateLootTable)
		LogAssert(IsValidExtendedEntity(hEntity), "Type mismatch (expected \"%s\", got %s)", "CExtEntity", type(hEntity))
		if hEntity._bIsCorpseEntity then
			return hEntity
		end
	
		hEntity = CContainer(hEntity, nil, bGenerateLootTable)
		
		local tEntityMetatable = setmetatable({}, { __index = getmetatable(hEntity).__index } )
		for k,v in pairs(CCorpseEntity) do if type(v) == "function" then tEntityMetatable[k] = v end end
		hEntity = setmetatable(hEntity, { __index = tEntityMetatable })
		
		hEntity._bIsCorpseEntity = true
		hEntity._hCorpseItem = CreateItem("internal_corpse", nil, nil)
		
		local nDeathFrames = hEntity:GetPropertyValue(IW_PROPERTY_CORPSE_TIME)
		local fDeathTime = (nDeathFrames - 1)/30.0
	
		CTimer(fDeathTime, CorpseDelayedFunction, hEntity);
		
		return hEntity
	end})

function CCorpseEntity:IsAlive()
	return false
end

function CCorpseEntity:InteractFilter(hEntity)
	return (hEntity:IsRealHero() and self:HasItemInInventory("internal_corpse"))
end

function CCorpseEntity:OnCorpseLootableInteract(keys)
	if keys.lootable == self:entindex() then
		local hInventory = self:GetInventory()
		if hInventory:IsEmpty() then
			self._hCorpseItem:ApplyDataDrivenModifier(self, self, "modifier_internal_corpse_unselectable", {})
			CustomGameEventManager:UnregisterListener(self._nCorpseListener)
		end
	end
end

function CCorpseEntity:GetCustomInteractError(hEntity)
	return nil
end

function IsCorpseEntity(hEntity)
    return (IsValidExtendedEntity(hEntity) and IsValidEntity(hEntity) and hEntity._bIsCorpseEntity == true)
end

end