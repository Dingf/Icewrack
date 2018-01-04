if not CWorldObject then

require("instance")
require("entity_base")

local stWorldObjectData = LoadKeyValues("scripts/npc/npc_world_objects.txt")

local stWorldObjectScriptData = {}
CWorldObject = setmetatable(ext_class({}), { __call =
	function(self, hEntity, nInstanceID)
		LogAssert(IsInstanceOf(hEntity, CDOTA_BaseNPC), LOG_MESSAGE_ASSERT_TYPE, "CDOTA_BaseNPC")
		if IsInstanceOf(hEntity, CWorldObject) then
			LogMessage(LOG_MESSAGE_WARN_EXISTS, LOG_SEVERITY_WARNING, "CWorldObject", hEntity:GetUnitName())
			return hEntity
		end
		
		local szEntityName = hEntity:GetUnitName()
		local tWorldObjectTemplate = stWorldObjectData[hEntity:GetUnitName()]
		LogAssert(tWorldObjectTemplate, LOG_MESSAGE_ASSERT_TEMPLATE, hEntity:GetUnitName())
		
		hEntity = CEntityBase(hEntity, nInstanceID)
		--hEntity = CInteractable(hEntity, nInstanceID)
		ExtendIndexTable(hEntity, CWorldObject)
		
		hEntity._fObjectState = 0
		hEntity._hPrecondition = LoadFunctionSnippet(tWorldObjectTemplate.Precondition)
		hEntity._hPostcondition = LoadFunctionSnippet(tWorldObjectTemplate.Postcondition)
		
		hEntity:SetInteractRange(tWorldObjectTemplate.InteractRange)
		hEntity:SetInteractZone(tWorldObjectTemplate.InteractZone)
		
		local szScriptFilename = tWorldObjectTemplate.ScriptFile
		if szScriptFilename then
			szScriptFilename = string.gsub(szScriptFilename, "\\", "/")
			szScriptFilename = string.gsub(szScriptFilename, "scripts/vscripts/", "")
			szScriptFilename = string.gsub(szScriptFilename, ".lua", "")
			
			local tContext = getfenv()
			local tScriptData = nil
			if stWorldObjectScriptData[szScriptFilename] then
				tScriptData = stWorldObjectScriptData[szScriptFilename]
			else
				tScriptData = setmetatable({}, { __index = tContext })
				setfenv(1, tScriptData)
				dofile(szScriptFilename)
				setfenv(1, tContext)
				stWorldObjectScriptData[szScriptFilename] = tScriptData
			end
			
			if tScriptData then
				setfenv(1, tScriptData)
				local tBaseClass = tScriptData[szEntityName]
				if tBaseClass then
					for k,v in pairs(tBaseClass) do
						hEntity[k] = v
					end
				end
				setfenv(1, tContext)
			end
		end
		
		hEntity:OnCreated()
		
		return hEntity
	end
})

function CWorldObject:GetObjectState()
	return self._fObjectState
end

function CWorldObject:SetObjectState(fState)
	if type(fState) == "number" then
		self._fObjectState = fState
		self:OnChangeState(fState)
	end
end

function CWorldObject:OnCreated()
end

function CWorldObject:OnChangeState(fNewState)
end

function CWorldObject:Interact(hEntity)
	local bResult = true
	if self.OnInteract then
		bResult = self:OnInteract(hEntity)
	end
	local hPostcondition = self._hPostcondition
	if hPostcondition then
		hPostcondition()
	end
	return bResult
end

function CWorldObject:InteractFilterExclude(hEntity)
	local hPrecondition = self._hPrecondition
	if (hPrecondition and not hPrecondition()) then
		return false
	elseif self.OnInteractFilterExclude then
		return self:OnInteractFilterExclude(hEntity)
	end
	return true
end

function CWorldObject:InteractFilterInclude(hEntity)
	if self.OnInteractFilterInclude then
		return self:OnInteractFilterInclude(hEntity)
	end
	return false
end

function CWorldObject:GetCustomInteractError(hEntity)
	local hPrecondition = self._hPrecondition
	if (hPrecondition and not hPrecondition()) then
		return "TODO: The precondition failed. Replace me."
	elseif self.OnGetCustomInteractError then
		return self:OnGetCustomInteractError(hEntity)
	end
end

function IsValidWorldObject(hEntity)
    return (IsValidEntity(hEntity) and IsInstanceOf(hEntity, CWorldObject))
end

end