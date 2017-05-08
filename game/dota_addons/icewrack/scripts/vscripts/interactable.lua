if not CInteractable then

DEFAULT_INTERACT_RANGE = 128

local stInteractableTypeEnum =
{
	IW_INTERACTABLE_TYPE_NONE = 0,
    IW_INTERACTABLE_TYPE_CONTAINER = 1,
	IW_INTERACTABLE_TYPE_WORLD_OBJECT = 2,
}

for k,v in pairs(stInteractableTypeEnum) do _G[k] = v end

local stInteractableData = LoadKeyValues("scripts/npc/npc_interactables_extended.txt")

local tIndexTableList = {}
CInteractable = setmetatable({}, { __call =
	function(self, hEntity)
		LogAssert(IsInstanceOf(hEntity, CDOTA_BaseNPC), "Type mismatch (expected \"%s\", got %s)", "CDOTA_BaseNPC", type(hEntity))
		if hEntity._bIsInteractable then
			return hEntity
		end
		
		local tInteractableTemplate = stInteractableData[hEntity:GetUnitName()] or {}
		hEntity._nInteractType = stInteractableTypeEnum[tInteractableTemplate.Type] or IW_INTERACTABLE_TYPE_NONE
		hEntity._fInteractRange = tInteractableTemplate.InteractRange or DEFAULT_INTERACT_RANGE
		hEntity._szInteractZone = tInteractableTemplate.InteractZone
		
		local tBaseIndexTable = getmetatable(hEntity).__index
		local tExtIndexTable = tIndexTableList[tBaseIndexTable]
		if not tExtIndexTable then
			tExtIndexTable = ExtendIndexTable(hEntity, CInteractable)
			tIndexTableList[tBaseIndexTable] = tExtIndexTable
		end
		setmetatable(hEntity, tExtIndexTable)
		
		hEntity._bIsInteractable = true
		return hEntity
	end})

function CInteractable:IsInInteractRange(hEntity)
	local fDistance = self:GetRangeToUnit(hEntity) - self:GetHullRadius() - hEntity:GetHullRadius()
	if fDistance > self:GetInteractRange() then
		return false
	end
	if self._szInteractZone then
		local hTrigger = Entities:FindByName(nil, self._szInteractZone)
		if IsInstanceOf(hTrigger, CBaseTrigger) and not hTrigger:IsTouching(hEntity) then
			return false
		end
	end
	return true
end

function CInteractable:InteractFilter(hEntity)
	LogMessage("Tried to access virtual function CInteractable:InteractFilter()", LOG_SEVERITY_WARNING)
	return true
end

function CInteractable:OnInteract(hEntity)
	LogMessage("Tried to access virtual function CInteractable:OnInteract()", LOG_SEVERITY_WARNING)
end

function CInteractable:GetCustomInteractError(hEntity)
	LogMessage("Tried to access virtual function CInteractable:GetCustomInteractError()", LOG_SEVERITY_WARNING)
	return nil
end

function CInteractable:GetInteractRange()
	return self._fInteractRange or DEFAULT_INTERACT_RANGE
end

function CInteractable:GetInteractZone()
	if self._szInteractZone then
		local hTrigger = Entities:FindByName(nil, self._szInteractZone)
		if hTrigger and hTrigger.IsTouching then
			return hTrigger
		end
	end
end

function IsValidInteractable(hEntity)
    return (hEntity ~= nil and type(hEntity) == "table" and not (hEntity.IsNull and hEntity:IsNull()) and IsValidEntity(hEntity) and hEntity._bIsInteractable == true)
end

end