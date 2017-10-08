if not CInteractable then

DEFAULT_INTERACT_RANGE = 128

local stInteractableResultEnum =
{
	IW_INTERACTABLE_RESULT_FAIL = 0,
	IW_INTERACTABLE_RESULT_SUCCESS = 1,
	IW_INTERACTABLE_RESULT_EN_ROUTE = 2,
}

for k,v in pairs(stInteractableResultEnum) do _G[k] = v end

local stInteractableData = LoadKeyValues("scripts/npc/npc_interactables_extended.txt")

CInteractable = setmetatable(ext_class({}), { __call =
	function(self, hEntity, nInstanceID)
		LogAssert(IsInstanceOf(hEntity, CDOTA_BaseNPC), LOG_MESSAGE_ASSERT_TYPE, "CDOTA_BaseNPC", type(hEntity))
		if IsInstanceOf(hEntity, CInteractable) then
			LogMessage("Tried to create a CInteractable from \"" .. hEntity:GetUnitName() .."\", which is already a CInteractable", LOG_SEVERITY_WARNING)
			return hEntity
		end
		
		ExtendIndexTable(hEntity, CInteractable)
		
		local tInteractableTemplate = stInteractableData[hEntity:GetUnitName()] or {}
		hEntity._fInteractRange = tInteractableTemplate.InteractRange or DEFAULT_INTERACT_RANGE
		hEntity._szInteractZone = tInteractableTemplate.InteractZone
		
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

function CInteractable:InteractFilterInclude(hEntity)
	return false
end

function CInteractable:InteractFilterExclude(hEntity)
	return false
end

function CInteractable:Interact(hEntity)
	return false
end

function CInteractable:GetCustomInteractError(hEntity)
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

function CInteractable:OnInteractFilter(hEntity)
	local tIndexMetatable = self
	while tIndexMetatable do
		local hIncludeFunction = rawget(tIndexMetatable, "InteractFilterInclude")
		local hExcludeFunction = rawget(tIndexMetatable, "InteractFilterExclude")
		if hIncludeFunction and hIncludeFunction(self, hEntity) then
			return true
		elseif hExcludeFunction and not hExcludeFunction(self, hEntity) then
			return false
		end
		tIndexMetatable = getmetatable(tIndexMetatable).__index
	end
	return false
end

function CInteractable:OnInteract(hEntity)
	local tIndexMetatable = self
	while tIndexMetatable do
		local hFunction = rawget(tIndexMetatable, "Interact")
		if hFunction then
			local bResult = hFunction(self, hEntity)
			if type(bResult) == "boolean" then return bResult end
		end
		tIndexMetatable = getmetatable(tIndexMetatable).__index
	end
	return true
end

function CInteractable:OnGetCustomInteractError(hEntity)
	local tIndexMetatable = self
	while tIndexMetatable do
		local hFunction = rawget(tIndexMetatable, "GetCustomInteractError")
		if hFunction then
			local szMessage = hFunction(self, hEntity)
			if type(szMessage) == "boolean" then return szMessage end
		end
		tIndexMetatable = getmetatable(tIndexMetatable).__index
	end
	return true
end

function IsValidInteractable(hEntity)
    return (hEntity ~= nil and type(hEntity) == "table" and not (hEntity.IsNull and hEntity:IsNull()) and IsValidEntity(hEntity) and IsInstanceOf(hEntity, CInteractable))
end

end