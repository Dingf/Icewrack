if not CWorldObject then

require("instance")
require("expression")
require("interactable")

local stInteractableData = LoadKeyValues("scripts/npc/npc_interactables_extended.txt")

local tIndexTableList = {}
local stWorldObjectScriptData = {}
CWorldObject = setmetatable({}, { __call =
	function(self, hEntity, nInstanceID)
		LogAssert(IsInstanceOf(hEntity, CDOTA_BaseNPC), "Type mismatch (expected \"%s\", got %s)", "CDOTA_BaseNPC", type(hEntity))
		if hEntity._bIsWorldObject then
			return hEntity
		end
		
		local szEntityName = hEntity:GetUnitName()
		local tInteractableTemplate = stInteractableData[hEntity:GetUnitName()]
		LogAssert(tInteractableTemplate, "Failed to load template \"%d\" - no data exists for this entry.", hEntity:GetUnitName())
		
		hEntity = CInteractable(hEntity, nInstanceID)
		local tBaseIndexTable = getmetatable(hEntity).__index
		local tExtIndexTable = tIndexTableList[tBaseIndexTable]
		if not tExtIndexTable then
			tExtIndexTable = ExtendIndexTable(hEntity, CWorldObject)
			tIndexTableList[tBaseIndexTable] = tExtIndexTable
		end
		setmetatable(hEntity, tExtIndexTable)
		
		hEntity._bIsWorldObject = true
		hEntity._fObjectState = 0
		hEntity._hPrecondition = CExpression(tInteractableTemplate.Precondition or "")
		hEntity._hPostcondition = CExpression(tInteractableTemplate.Postcondition or "")
		
		local szScriptFilename = tInteractableTemplate.ScriptFile
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
	if self._hPostcondition then
		self._hPostcondition:EvaluateExpression()
	end
	if self.OnInteract then
		return self:OnInteract(hEntity)
	end
	return true
end

function CWorldObject:InteractFilterExclude(hEntity)
	if not self._hPrecondition:EvaluateExpression() then
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
	if not self._hPrecondition:EvaluateExpression() then
		return "TODO: The precondition failed. Replace me."
	elseif self.OnGetCustomInteractError then
		return self:OnGetCustomInteractError(hEntity)
	end
end

function IsValidWorldObject(hEntity)
    return (IsValidInstance(hEntity) and IsValidEntity(hEntity) and hEntity._bIsWorldObject == true)
end

end