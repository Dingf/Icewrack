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
		hEntity._nObjectState = 0
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
				hEntity.ScriptOnCreated = OnCreated
				hEntity.ScriptOnInteract = OnInteract
				hEntity.ScriptInteractFilterExclude = OnInteractFilterExclude
				hEntity.ScriptInteractFilterInclude = OnInteractFilterInclude
				hEntity.ScriptGetCustomInteractError = OnGetCustomInteractError
				setfenv(1, tContext)
			end
		end
		
		hEntity:OnCreated()
		
		return hEntity
	end
})

function CWorldObject:GetObjectState()
	return self._nObjectState
end

function CWorldObject:SetObjectState(nState)
	if type(nState) == "number" then
		self._nObjectState = nState
	end
end

function CWorldObject:OnCreated()
	if self.ScriptOnCreated then
		self:ScriptOnCreated()
	end
end

function CWorldObject:Interact(hEntity)
	if self._hPostcondition then
		self._hPostcondition:EvaluateExpression()
	end
	if self.ScriptOnInteract then
		return self:ScriptOnInteract(hEntity)
	end
	return true
end

function CWorldObject:InteractFilterExclude(hEntity)
	if not self._hPrecondition:EvaluateExpression() then
		return false
	elseif self.ScriptInteractFilterExclude then
		return self:ScriptInteractFilterExclude(hEntity)
	end
	return true
end

function CWorldObject:InteractFilterInclude(hEntity)
	if self.ScriptInteractFilterInclude then
		return self:ScriptInteractFilterInclude(hEntity)
	end
	return false
end

function CWorldObject:GetCustomInteractError(hEntity)
	if not self._hPrecondition:EvaluateExpression() then
		return "TODO: The precondition failed. Replace me."
	elseif self.ScriptGetCustomInteractError then
		return self:ScriptGetCustomInteractError(hEntity)
	end
end

function IsValidWorldObject(hEntity)
    return (IsValidInstance(hEntity) and IsValidEntity(hEntity) and hEntity._bIsWorldObject == true)
end

end