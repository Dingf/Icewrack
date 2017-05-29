if not CDialogueEntity then

require("expression")
require("interactable")
require("ext_entity")

--TODO: Silence the player hero or do something to stop them from using abilities/items during dialogue

local function CreateDialogueNode(nDialogueID)
	local hDialogueNode = CDialogueEntity._tDialogueNodeList[nDialogueID]
	if not hDialogueNode then
		local tDialogueNodeTemplate = stDialogueNodeData[tostring(nDialogueID)]
		LogAssert(tDialogueNodeTemplate, "Failed to load template \"%d\" - no data exists for this entry.", nDialogueID)
		
		hDialogueNode = {}
		hDialogueNode._nDialogueID = nDialogueID
		hDialogueNode._szText = tDialogueNodeTemplate.Text
		hDialogueNode._nInstanceID = tonumber(tDialogueNodeTemplate.InstanceID) or -1
		hDialogueNode._hPrecondition = CExpression(tDialogueNodeTemplate.Precondition or "")
				
		hDialogueNode._tOptionsList = {}
		for k,v in pairs(tDialogueNodeTemplate.Options or {}) do
			local nOptionValue = tonumber(k)
			if nOptionValue and not hDialogueNode._tOptionsList[nOptionValue] then
				local hDialogueOption = {}
				hDialogueOption._szText = v.Text
				hDialogueOption._nNextNodeID = tonumber(v.NextNode) or 0
				hDialogueOption._hPrecondition = CExpression(v.Precondition or "")
				hDialogueOption._hPostcondition = CExpression(v.Postcondition or "")
				hDialogueNode._tOptionsList[nOptionValue] = hDialogueOption
			end
		end
		CDialogueEntity._tDialogueNodeList[nDialogueID] = hDialogueNode
	end
	return hDialogueNode
end

stDialogueNodeData = LoadKeyValues("scripts/npc/iw_dialogue_nodes.txt")
stDialogueData = LoadKeyValues("scripts/npc/iw_dialogue_list.txt")
CDialogueEntity = setmetatable({ _tDialogueNodeList = {} }, { __call =
	function(self, hEntity)
		LogAssert(IsValidExtendedEntity(hEntity), "Type mismatch (expected \"%s\", got %s)", "CExtEntity", type(hEntity))
		if hEntity._bIsDialogueEntity then
			return hEntity
		end
		
		local tDialogueTemplate = stDialogueData[tostring(hEntity:GetInstanceID())]
		if not tDialogueTemplate then
			return hEntity
		end
		
		hEntity = CInteractable(hEntity)
		
		local tEntityMetatable = setmetatable({}, { __index = getmetatable(hEntity).__index } )
		for k,v in pairs(CDialogueEntity) do if type(v) == "function" then tEntityMetatable[k] = v end end
		hEntity = setmetatable(hEntity, { __index = tEntityMetatable })
		
		hEntity._bIsDialogueEntity = true
		hEntity._fInteractRange = tDialogueTemplate.InteractRange
		hEntity._szInteractZone = tDialogueTemplate.InteractZone
		
		hEntity._tDialogueList = {}
		for k in string.gmatch(tDialogueTemplate.Nodes or "", "(%d+)") do
			local nDialogueID = tonumber(k)
			table.insert(hEntity._tDialogueList, tonumber(k))
			if not CDialogueEntity._tDialogueNodeList[nDialogueID] then
				CreateDialogueNode(nDialogueID)
			end
		end
		
		return hEntity
	end})
	
CustomGameEventManager:RegisterListener("iw_dialogue_option", Dynamic_Wrap(CDialogueEntity, "OnDialogueOption"))

local function ShowDialogueNode(nDialogueID)
	local hDialogueNode = CDialogueEntity._tDialogueNodeList[nDialogueID] or CreateDialogueNode(nDialogueID)
	local hDialogueEntity = GetInstanceByID(hDialogueNode._nInstanceID)
	if hDialogueNode._hPrecondition:EvaluateExpression(hDialogueEntity) then
		CustomGameEventManager:Send_ServerToAllClients("iw_dialogue_start", { id = nDialogueID, entindex = hDialogueEntity:entindex(), text = hDialogueNode._szText, })
		for k,v in ipairs(hDialogueNode._tOptionsList) do
			if v._hPrecondition:EvaluateExpression(hEntity) then
				CustomGameEventManager:Send_ServerToAllClients("iw_dialogue_option", { value = k, text = v._szText, })
			end
		end
		CustomGameEventManager:Send_ServerToAllClients("iw_dialogue_end", {})
		return true
	end
	return false
end

function CDialogueEntity:InteractFilterInclude(hEntity)
	return self:IsAlive() and hEntity == GameRules:GetPlayerHero()
end

function CDialogueEntity:OnInteract(hEntity)
	for k,v in ipairs(self._tDialogueList) do
		if ShowDialogueNode(v) then
			local vPosition = self:GetAbsOrigin()
			self:SetAbsOrigin(vPosition + (vPosition - hEntity:GetAbsOrigin()):Normalized())
			self:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, nil, vPosition, false)
			PlayerResource:SetCameraTarget(0, hEntity)
			return true
		end
	end
end

function CDialogueEntity:OnGetCustomInteractError(hEntity)
	return nil
end

function CDialogueEntity:OnDialogueOption(args)
	local hDialogueNode = CDialogueEntity._tDialogueNodeList[tonumber(args.text)]
	if hDialogueNode then
		local hDialogueOption = hDialogueNode._tOptionsList[args.value]
		if hDialogueOption then
			hDialogueOption._hPostcondition:EvaluateExpression()
			
			local nNextNodeID = hDialogueOption._nNextNodeID
			if nNextNodeID <= 0 then
				CustomGameEventManager:Send_ServerToAllClients("iw_dialogue_hide", {})
				PlayerResource:SetCameraTarget(0, nil)
			else
				CustomGameEventManager:Send_ServerToAllClients("iw_dialogue_next", {})
				ShowDialogueNode(nNextNodeID)
			end
		end
	end
end

end