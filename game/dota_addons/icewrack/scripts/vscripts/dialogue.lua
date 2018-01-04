if not CDialogue then

local stDialogueSpeakerEnum =
{
	IW_DIALOGUE_SPEAKER_NONE = 0,
	IW_DIALOGUE_SPEAKER_LEFT = 1,
	IW_DIALOGUE_SPEAKER_RIGHT = 2,
}

local stDialogueNodeData = LoadKeyValues("scripts/npc/iw_dialogue_nodes.txt")
local stDialogueEntityData = LoadKeyValues("scripts/npc/npc_dialogue.txt")

local shItemDialogueBuff = CreateItem("item_internal_dialogue", nil, nil)

local szEntityPrefix = "local entity = args[1] "
local szNodePrefix = "local left = args[1]._tTargetTable[1] \
					  local right = args[1]._tTargetTable[2] \
					  local entity = args[1]._hDialogue._hEntity \
					  local listeners = args[1]._hDialogue._tListeningEntities "

CDialogueNode = setmetatable({}, { __call =
	function(self, hDialogue, nNodeID)
		local tDialogueNodeTemplate = stDialogueNodeData[tostring(nNodeID)]
		LogAssert(tDialogueNodeTemplate, LOG_MESSAGE_ASSERT_TEMPLATE, nNodeID)
		
		hDialogueNode = setmetatable({}, { __index = CDialogueNode })
		hDialogueNode._nNodeID = nNodeID
		hDialogueNode._hDialogue = hDialogue
		
		hDialogueNode._tTargetTable = {}
		local tDialogueTargetTable = { "LeftID", "RightID" }
		for k,v in pairs(tDialogueTargetTable) do
			local nTargetID = tDialogueNodeTemplate[v]
			local hTarget = (nTargetID == 0) and hDialogue._hEntity or GetInstanceByID(nTargetID)
			LogAssert(IsInstanceOf(hTarget, CEntityBase), "Failed to find entity with instance ID \"" .. nTargetID .. "\" in dialogue node \"" .. nNodeID .. "\"")
			hDialogueNode._tTargetTable[k] = hTarget
		end
	
		hDialogueNode._tTextValues = {}
		for k,v in pairs(tDialogueNodeTemplate.Text or {}) do
			local nTextID = tonumber(k)
			if nTextID then
				hDialogueNode._tTextValues[nTextID] =
				{
					Speaker = hDialogueNode._tTargetTable[stDialogueSpeakerEnum[v.Speaker]],
					Text = v.Text or "",
					Precondition = LoadFunctionSnippet(v.Precondition, szNodePrefix),
				}
			end
		end
		
		hDialogueNode._tOptionValues = {}
		for k,v in pairs(tDialogueNodeTemplate.Options or {}) do
			local nOptionID = tonumber(k)
			if nOptionID then
				hDialogueNode._tOptionValues[nOptionID] =
				{
					Text = v.Text or "",
					Precondition = LoadFunctionSnippet(v.Precondition, szNodePrefix),
				}
				
				local tResultsTable = {}
				for k2,v2 in pairs(v.Results) do
					local nResultID = tonumber(k2)
					if nResultID then
						tResultsTable[nResultID] =
						{
							NextNode = tonumber(v2.NextNode) or 0,
							Precondition = LoadFunctionSnippet(v2.Precondition, szNodePrefix),
							Postcondition = LoadFunctionSnippet(v2.Postcondition, szNodePrefix),
						}
					end
				end
				hDialogueNode._tOptionValues[nOptionID].Results = tResultsTable
			elseif k == "Speaker" then
				hDialogueNode._hOptionSpeaker = hDialogueNode._tTargetTable[stDialogueSpeakerEnum[v]]
			end
		end
		return hDialogueNode
	end})
	
function CDialogueNode:GetNetTable()		
	local tNodeTable =
	{
		LeftID = self._tTargetTable[1]:entindex(),
		RightID = self._tTargetTable[2]:entindex(),
		Text = {},
		Options = {},
		OptionSpeaker = self._hOptionSpeaker and self._hOptionSpeaker:entindex() or 0,
	}
	for k,v in ipairs(hDialogueNode._tTextValues) do
		local hTextPrecondition = v.Precondition
		if not hTextPrecondition or hTextPrecondition(self) then
			tNodeTable.Text[k] = 
			{
				Speaker = v.Speaker and v.Speaker:entindex() or 0,
				Text = v.Text,
			}
		end
	end
	for k,v in pairs(hDialogueNode._tOptionValues) do
		local hOptionPrecondition = v.Precondition
		if not hOptionPrecondition or hOptionPrecondition(self) then
			tNodeTable.Options[k] = v.Text
		end
	end
	return tNodeTable
end

CDialogue = setmetatable({ _stDialogueList = {} }, { __call = 
	function(self, hEntity)
		hDialogue = setmetatable({}, {__index = CDialogue })
		table.insert(CDialogue._stDialogueList, hDialogue)
		
		hDialogue._nDialogueID = #CDialogue._stDialogueList
		
		hDialogue._nPlayerID = hEntity:GetMainControllingPlayer()
		hDialogue._hEntity = hEntity
		hDialogue._hCurrentNode = nil
		hDialogue._tListeningEntities = {}
		
		hDialogue._tNetTable =
		{
			History = {},
			Listeners = {},
			PlayerID = hDialogue._nPlayerID,
			CurrentNode = nil,
		}
		
		return hDialogue
	end})
	
function CDialogue:GetDialogueID()
	return self._nDialogueID
end

function CDialogue:GetCurrentNode()
	return self._hCurrentNode
end

function CDialogue:SetCurrentNode(nNodeID)
	self._hCurrentNode = nil
	self._tNetTable.CurrentNode = nil
	local hNode = CDialogueNode(self, nNodeID)
	if hNode then
		self._hCurrentNode = hNode
		self._tNetTable.CurrentNode = hNode:GetNetTable()
		CustomNetTables:SetTableValue("dialogue", tostring(self:GetDialogueID()), self._tNetTable)
	end
end

CDialogueEntity = setmetatable(ext_class({}), { __call =
	function(self, hEntity)
		LogAssert(IsInstanceOf(hEntity, CEntityBase), LOG_MESSAGE_ASSERT_TYPE, "CEntityBase")
		if IsInstanceOf(hEntity, CDialogueEntity) then
			LogMessage(LOG_MESSAGE_WARN_EXISTS, LOG_SEVERITY_WARNING, "CDialogueEntity", hEntity:GetUnitName())
			return hEntity
		end
		
		ExtendIndexTable(hEntity, CDialogueEntity)
		
		hEntity._tDialogueNodeList = {}
		hEntity._tDialoguePreconditionList = {}

		local tDialogueEntityTemplate = stDialogueEntityData[tostring(hEntity:GetInstanceID())]
		if tDialogueEntityTemplate then
			hEntity:SetInteractRange(tDialogueEntityTemplate.InteractRange)
			hEntity:SetInteractZone(tDialogueEntityTemplate.InteractZone)
			for k in string.gmatch(tDialogueEntityTemplate.Nodes or "", "(%d+)") do
				local nDialogueID = tonumber(k)
				local tDialogueNodeTemplate = stDialogueNodeData[tostring(nDialogueID)]
				if nDialogueID and tDialogueNodeTemplate then
					table.insert(hEntity._tDialogueNodeList, nDialogueID)
					table.insert(hEntity._tDialoguePreconditionList, LoadFunctionSnippet(tDialogueNodeTemplate.Precondition, szEntityPrefix) or false)
				end
			end
		end
		return hEntity
	end})
	

function CDialogueEntity:InteractFilter(hEntity)
	return #self._tDialogueNodeList > 0 and self:IsAlive()
end

function CDialogueEntity:Interact(hEntity)
	local nEntityIndex = hEntity:entindex()
	--TODO: Add like some sort of modifier here that prevents commands and also causes dialogue to stop when attacked
	--if not CDialogue._tNetTable.Entities[nEntityIndex] then
		for k,v in ipairs(self._tDialogueNodeList) do
			local hPrecondition = self._tDialoguePreconditionList[k]
			if not hPrecondition or hPrecondition(hEntity) then
				local hDialogue = CDialogue(hEntity)
				hDialogue._tListeningEntities[self:entindex()] = true
				hDialogue._tListeningEntities[hEntity:entindex()] = true
				hDialogue._tNetTable.Listeners[self:entindex()] = true
				hDialogue._tNetTable.Listeners[hEntity:entindex()] = true
				hDialogue:SetCurrentNode(v)
				
				local vSelfPosition = self:GetAbsOrigin()
				local vEntityPosition = hEntity:GetAbsOrigin()
				self:AddNewModifier(self, shItemDialogueBuff, "modifier_internal_dialogue", {})
				hEntity:AddNewModifier(hEntity, shItemDialogueBuff, "modifier_internal_dialogue", {})
				self:SetAbsOrigin(vSelfPosition + (vSelfPosition - vEntityPosition):Normalized())
				self:MoveToPosition(vSelfPosition)
				return true
			end
		end
	--end
end

function CDialogueEntity:OnGetCustomInteractError(hEntity)
	return nil
end


function CDialogue:OnDialogueOption(args)
	local hDialogue = CDialogue._stDialogueList[tonumber(args.id)]
	if hDialogue then
		local hCurrentNode = hDialogue:GetCurrentNode()
		local tDialogueOption = hCurrentNode._tOptionValues[tonumber(args.option)]
		if tDialogueOption then
			local nNextNodeID = 0
			for k,v in ipairs(tDialogueOption.Results) do
				local hPrecondition = v.Precondition
				if not hPrecondition or hPrecondition(hCurrentNode) then
					local hPostcondition = v.Postcondition
					if hPostcondition then
						hPostcondition(hCurrentNode)
					end
					nNextNodeID = v.NextNode
					break
				end
			end
			if nNextNodeID == 0 then
				CustomNetTables:SetTableValue("dialogue", tostring(hDialogue:GetDialogueID()), nil)
				CDialogue._stDialogueList[hDialogue:GetDialogueID()] = nil
				for k,v in pairs(hDialogue._tListeningEntities) do
					local hEntity = EntIndexToHScript(k)
					hEntity:RemoveModifierByName("modifier_internal_dialogue")
				end
			else
				local tHistoryTable = hDialogue._tNetTable.History
				local tTextTable = hDialogue._tNetTable.CurrentNode.Text
				for k,v in pairs(tTextTable) do
					if v.Speaker ~= 0 then
						table.insert(tHistoryTable, { Speaker=v.Speaker, Text=v.Text })
					end
				end
				if hCurrentNode._hOptionSpeaker then
					table.insert(tHistoryTable, { Speaker=hCurrentNode._hOptionSpeaker:entindex(), Text=tDialogueOption.Text })
				end
				hDialogue:SetCurrentNode(nNextNodeID)
			end
		end
	end
end

CustomGameEventManager:RegisterListener("iw_dialogue_option", Dynamic_Wrap(CDialogue, "OnDialogueOption"))

end