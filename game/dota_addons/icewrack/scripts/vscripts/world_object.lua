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
		
		if not IsValidInstance(hEntity) then
			hEntity = CInstance(hEntity, nInstanceID)
		end
		hEntity = CInteractable(hEntity)
		local tBaseIndexTable = getmetatable(hEntity).__index
		local tExtIndexTable = tIndexTableList[tBaseIndexTable]
		if not tExtIndexTable then
			tExtIndexTable = ExtendIndexTable(hEntity, CWorldObject)
			tIndexTableList[tBaseIndexTable] = tExtIndexTable
		end
		
		hEntity._bIsWorldObject = true
		hEntity._nObjectState = 0
		hEntity._hPrecondition = CExpression(tInteractableTemplate.Precondition or "")
		hEntity._hPostcondition = CExpression(tInteractableTemplate.Postcondition or "")
		
		local szScriptFilename = tInteractableTemplate.ScriptFile
		if szScriptFilename then
			szScriptFilename = string.gsub(szScriptFilename, "\\", "/")
			szScriptFilename = string.gsub(szScriptFilename, "scripts/vscripts/", "")
			szScriptFilename = string.gsub(szScriptFilename, ".lua", "")
			local hScriptFile = nil
			if stWorldObjectScriptData[szScriptFilename] then
				hScriptFile = stWorldObjectScriptData[szScriptFilename]
			else
				hScriptFile = assert(loadfile(szScriptFilename))
				stWorldObjectScriptData[szScriptFilename] = hScriptFile
			end
			
			local tContext = getfenv()
			local tSandbox = setmetatable({}, { __index = tContext })
			setfenv(1, tSandbox)
			hScriptFile()
			hEntity.ScriptOnCreated = type(tSandbox.OnCreated) == "function" and tSandbox.OnCreated or nil
			hEntity.ScriptOnInteract = type(tSandbox.OnInteract) == "function" and tSandbox.OnInteract or nil
			hEntity.ScriptInteractFilter = type(tSandbox.InteractFilter) == "function" and tSandbox.InteractFilter or nil
			hEntity.ScriptGetCustomInteractError = type(tSandbox.GetCustomInteractError) == "function" and tSandbox.GetCustomInteractError or nil
			setfenv(1, tContext)
		end
		
		hEntity:OnCreated()
		
		return hEntity
	end
})

function CWorldObject:OnCreated()
	if self.ScriptOnCreated then
		self:ScriptOnCreated()
	end
end

function CWorldObject:OnInteract(hEntity)
	if self._hPostcondition then
		self._hPostcondition:EvaluateExpression()
	end
	if self.ScriptOnInteract then
		self:ScriptOnInteract(hEntity)
	end
end

function CWorldObject:InteractFilter(hEntity)
	if not self._hPrecondition:EvaluateExpression() then
		return false
	elseif self.ScriptInteractFilter then
		return self:ScriptInteractFilter(hEntity)
	end
	return true
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