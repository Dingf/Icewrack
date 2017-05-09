--[[
	Icewrack Save Manager
]]

if not CSaveManager then

if _VERSION < "Lua 5.2" then
    bit = require("lib/numberlua")
    bit32 = bit.bit32
end

require("instance")
require("bind_manager")
require("game_states")
require("ext_ability")
require("ext_item")
require("ext_entity")
require("interactable")
require("container")
require("world_object")
require("npc")
require("dialogue")
require("spellbook")
require("inventory")
require("aam")
require("expression")
require("party")

IW_SAVE_VERSION = 900

IW_SAVE_MODE_NORMAL = 0
IW_SAVE_MODE_QUICKSAVE = 1
IW_SAVE_MODE_AUTOSAVE = 2

IW_SAVE_STATE_DISABLED = 0
IW_SAVE_STATE_ENABLED = 1
IW_SAVE_STATE_PERSISTENT = 2

local function TableToSaveString(tData, bIsChild)
	local tSaveTable = {}
	if bIsChild then tSaveTable[#tSaveTable+1] = "{" end
	for k,v in pairs(tData) do
		tSaveTable[#tSaveTable+1] = tostring(k)
		if type(v) == "table" then
			tSaveTable[#tSaveTable+1] = TableToSaveString(v, true)
		elseif type(v) == "userdata" then
			tSaveTable[#tSaveTable+1] = (v.x .. " " .. v.y .. " " .. v.z)
		else
			tSaveTable[#tSaveTable+1] = (v == "" and "null" or tostring(v))
		end
	end
	if bIsChild then tSaveTable[#tSaveTable+1] = "}" end
	return table.concat(tSaveTable, "\t")
end

local function OutputToScaleform(szFilename, szSaveString)
	FireGameEvent("iw_sfs_save_start", { filename = CSaveManager._szSaveDirectory .. szFilename })
	local nSaveLength = string.len(szSaveString)
	
	--Each game event can hold up to 1024 bytes; we do 1000 just to be safe
	local nCurrentIndex = 1
	while nCurrentIndex < nSaveLength do
		local nEndIndex = math.min(1000, nSaveLength - nCurrentIndex + 1)
		FireGameEvent("iw_sfs_save_data", { data = string.sub(szSaveString, nCurrentIndex, nCurrentIndex + nEndIndex - 1) })
		nCurrentIndex = nCurrentIndex + nEndIndex
	end
	FireGameEvent("iw_sfs_save_end", {})
end

CSaveManager =
{
	_szSaveDirectory = ICEWRACK_GAME_DIR .. "saves\\",
	_tSaveData = {},
	_tInstanceData = {},
	
	_nTimePlayed = 0,
	_szCurrentSave = nil,
	_tSaveFiles = {},
	_tSaveSpecial =
	{
		Latest = "",
		Autosave = "",
		Quicksave = "",
		Loading = "",
	}
}
	
InitLogFile(CSaveManager._szSaveDirectory, "")		--This creates the saves folder if it doesn't exist

ListenToGameEvent("iw_save_game", Dynamic_Wrap(CSaveManager, "OnSaveGame"), CSaveManager)
ListenToGameEvent("iw_map_transition", Dynamic_Wrap(CSaveManager, "OnMapTransition"), CSaveManager)

local tSaveListInfo = LoadKeyValues(CSaveManager._szSaveDirectory .. "iw_savelist.txt")
if tSaveListInfo then
	for k,v in pairs(tSaveListInfo) do
		if k == "Latest" then CSaveManager._tSaveSpecial.Latest = v == " " and "" or v
		elseif k == "Autosave" then CSaveManager._tSaveSpecial.Autosave = v == " " and "" or v
		elseif k == "Quicksave" then CSaveManager._tSaveSpecial.Quicksave = v == " " and "" or v
		elseif k == "Loading" then CSaveManager._tSaveSpecial.Loading = v == " " and "" or v
		elseif k == "Files" then
			for k2,v2 in pairs(v) do
				CSaveManager._tSaveFiles[k2] = true
			end
		end
	end
	
	if not GameRules:GetMapInfo():IsOverride() then
		LogMessage("Loading save file \"" .. CSaveManager._tSaveSpecial.Loading .. "\"")
		CSaveManager._tSaveData = LoadKeyValues(CSaveManager._szSaveDirectory .. CSaveManager._tSaveSpecial.Loading) or {}
		if not CSaveManager._tSaveData then
			LogMessage("Save file \"" .. CSaveManager._tSaveSpecial.Loading .. "\" not found in save directory", LOG_SEVERITY_ERROR)
		else
			LogMessage("Successfully loaded save file \"" .. CSaveManager._tSaveSpecial.Loading .. "\"")
		end
	end
	LogMessage("Loading instance list for map \"" .. GetMapName() .. "\"")
	CSaveManager._tInstanceData = LoadKeyValues("scripts/npc/maps/instances_" .. GetMapName() .. ".txt")
	if not CSaveManager._tInstanceData then
		LogMessage("Instance list for map \"" .. CSaveManager._tSaveSpecial.Loading .. "\" not found", LOG_SEVERITY_ERROR)
	else
		LogMessage("Successfully loaded instance list for map \"" .. GetMapName() .. "\"")
	end
elseif GetMapName() ~= "main_menu" then
	LogMessage("Save list not found in save directory (" .. CSaveManager._szSaveDirectory .. ")", LOG_SEVERITY_ERROR)
	FireGameEventLocal("iw_quit", {})
end

local tSaveNetTable =
{
	special = CSaveManager._tSaveSpecial,
	files = CSaveManager._tSaveFiles,
}
CustomNetTables:SetTableValue("game", "saves", tSaveNetTable)

local stInstanceData = LoadKeyValues("scripts/npc/npc_instances.txt")
for k,v in pairs(stInstanceData) do
	v.Type = stInstanceTypeEnum[v.Type]
	v.Team = _G[v.Team] or 0
end

function CSaveManager:GetPrecacheList()
	local tPrecacheList = {}
	for k,v in pairs(CSaveManager._tInstanceData) do
		tPrecacheList[stInstanceData[k].Name] = true
	end
	--TODO: Incorporate saved units in the precache list (so far only including party members)
	if CSaveManager._tSaveData and CSaveManager._tSaveData.Party then
		for k,v in pairs(CSaveManager._tSaveData.Party.Members) do
			tPrecacheList[stInstanceData[tostring(v)].Name] = true
		end
	end
	local tEntitySaveList = CSaveManager._tSaveData.Entities or {}
	for k,v in pairs(tEntitySaveList) do
		local nInstanceState = v.State
		if nInstanceState == IW_SAVE_STATE_PERSISTENT then
			tPrecacheList[v.UnitName] = true
		end
	end
	return tPrecacheList
end

function CSaveManager:GetPlayerHeroName()
	if CSaveManager._tSaveData and CSaveManager._tSaveData.Party then
		local tEntityData = stInstanceData[tostring(CSaveManager._tSaveData.GameStates["game.hero_selection"])]
		if tEntityData then
			return tEntityData.Name
		end
	end
	return nil
end

function CSaveManager:GetBindsForCurrentPlayer()
	return LoadKeyValues(CSaveManager._szSaveDirectory .. "iw_bindlist.txt")
end

function CSaveManager:CreateSaveList(keys)
	local tSaveData = 
	{
		Latest = CSaveManager._tSaveSpecial.Latest, 
		Autosave = CSaveManager._tSaveSpecial.Autosave, 
		Quicksave = CSaveManager._tSaveSpecial.Quicksave,
		Loading = CSaveManager._tSaveSpecial.Loading,
		Files = CSaveManager._tSaveFiles,
	}
	OutputToScaleform("iw_savelist.txt", TableToSaveString(tSaveData))
end

function CSaveManager:CreateBindList(keys)
	local tBindData = {}
	for k,v in pairs(CBindManager._tBindTable) do
		tBindData[v] = k
	end
	OutputToScaleform("iw_bindlist.txt", TableToSaveString(tBindData))
end

function CSaveManager:OnSaveGame(keys)
	if keys.mode == IW_SAVE_MODE_NORMAL then
		CSaveManager:SaveGame(keys.filename)
	elseif keys.mode == IW_SAVE_MODE_QUICKSAVE then
		CSaveManager:QuicksaveGame()
	elseif keys.mode == IW_SAVE_MODE_AUTOSAVE then
		CSaveManager:AutosaveGame()
	end
end

function CSaveManager:OnMapTransition(keys)
	local szSaveName = CSaveManager:SaveGame()
	if szSaveName then
		CSaveManager._tSaveSpecial.Loading = szSaveName
		CSaveManager:CreateSaveList()
		CSaveManager:CreateBindList()
		CTimer(0.1, FireGameEventLocal, "iw_change_level", { map = keys.map })
	end
end

local function SaveInventoryData(hInstance)
	local hInventory = hInstance:GetInventory()
	if hInventory then
		local tInventoryTable = {}
		tInventoryTable.Gold = hInventory:GetGoldAmount()
		tInventoryTable.Equipped = {}
		for k,v in pairs(hInventory._tEquippedItems) do
			tInventoryTable.Equipped[k] = v:GetInstanceID()
		end
		for k,v in pairs(hInventory._tItemList) do
			table.insert(tInventoryTable, k:GetInstanceID())
		end
		return tInventoryTable
	end
end

local function SaveSpellbookData(hInstance)
	local hSpellbook = hInstance:GetSpellbook()
	if hSpellbook then
		local tSpellbookTable = {}
		tSpellbookTable.Binds = {}
		for k,v in pairs(hSpellbook._tBindTable) do
			local hAbility = EntIndexToHScript(v)
			if hAbility then
				tSpellbookTable.Binds[k] = hAbility:GetAbilityName()
			end
		end
		for k,v in pairs(hSpellbook._tSpellList) do
			local hSpellUnit = v
			local hAbility = v:FindAbilityByName(k)
			if hAbility then
				local tAbilityTable = {}
				tAbilityTable.Level = hAbility:GetLevel()
				tAbilityTable.Cooldown = math.max(0, hAbility:GetCooldownTimeRemaining())
				tAbilityTable.IsAutoCast = hAbility:GetAutoCastState() and 1 or 0
				tAbilityTable.IsToggled = hAbility:GetToggleState() and 1 or 0
				tSpellbookTable[hAbility:GetAbilityName()] = tAbilityTable
			end
		end
		return tSpellbookTable
	end
end

local function SaveModifierData(hInstance)
	if IsValidExtendedEntity(hInstance) then
		local tModifierList = {}
		for k,v in pairs(hInstance._tExtModifierTable) do
			if not v:IsHidden() then
				local tModifierTable = {}
				tModifierTable.Name = v:GetAbilityName() .. ":" .. v:GetName()
				tModifierTable.Duration = v:GetRemainingTime()
				tModifierTable.StackCount = v:GetStackCount()
						
				local hParent = v:GetCaster()
				tModifierTable.Source = IsValidInstance(hParent) and hParent:GetInstanceID() or 0
				tModifierTable.ModifierArgs = {}
				for k2,v2 in pairs(v._tModifierArgs) do
					tModifierTable.ModifierArgs[k2] = (type(v2) == "table") and v2:GetInstanceID() or v2
				end
				tModifierTable.Properties = {}
				for k2,v2 in pairs(stIcewrackPropertyEnum) do
					tModifierTable.Properties[v2] = rawget(v._tPropertyValues, v2)
				end
				table.insert(tModifierList, tModifierTable)
			end
		end
		return tModifierList
	end
end

local function SaveEntityData(hInstance)
	local tEntityTable = {}
	tEntityTable.UnitName = hInstance:GetUnitName()
	tEntityTable.Position = hInstance:GetAbsOrigin()
	tEntityTable.Forward = hInstance:GetForwardVector()
	tEntityTable.Health = hInstance:IsAlive() and hInstance:GetHealth() or 0
	tEntityTable.Mana = hInstance:IsAlive() and hInstance:GetMana() or 0
	tEntityTable.Stamina = hInstance:IsAlive() and hInstance:GetStamina() or 0
	tEntityTable.Team = hInstance:GetTeamNumber()
	tEntityTable.State = (hInstance:GetMainControllingPlayer() == 0) and IW_SAVE_STATE_PERSISTENT or IW_SAVE_STATE_ENABLED
	tEntityTable.LastMap = GetMapName()
	tEntityTable.RunMode = hInstance:GetRunMode() and 1 or 0
	
	tEntityTable.Properties = {}
	for k,v in pairs(stIcewrackPropertyEnum) do
		tEntityTable.Properties[v] = rawget(hInstance._tPropertyValues, v)
	end
	
	if IsValidNPCEntity(hInstance) then
		tEntityTable.InitialPos = hInstance._vInitialPos
		tEntityTable.ThreatTable = {}
		for k,v in pairs(hInstance._tThreatTable) do
			local hEntity = EntIndexToHScript(k)
			if IsValidExtendedEntity(hEntity) then
				local nInstanceID = hEntity:GetInstanceID()
				tEntityTable.ThreatTable[nInstanceID] = v
			end
		end
		tEntityTable.DetectTable = {}
		local fCurrentTime = GameRules:GetGameTime()
		for k,v in pairs(hInstance._tDetectTable) do
			local hEntity = EntIndexToHScript(k)
			if IsValidExtendedEntity(hEntity) and v >= fCurrentTime then
				local nInstanceID = hEntity:GetInstanceID()
				tEntityTable.DetectTable[nInstanceID] = v - fCurrentTime
			end
		end
		tEntityTable.NoiseTable = {}
		for k,v in pairs(hInstance._tNoiseTable) do
			local tNoiseData =
			{
				value    = v.value,
				origin   = v.origin,
				speed    = v.speed,
				time     = v.time - fCurrentTime,
				duration = v.duration
			}
			table.insert(tEntityTable.NoiseTable, tNoiseData)
		end
		tEntityTable.LastWaypoint = hInstance._nLastWaypoint
		tEntityTable.NextWaypoint = hInstance._nNextWaypoint
	end
			
	tEntityTable.Inventory = SaveInventoryData(hInstance)
	tEntityTable.Spellbook = SaveSpellbookData(hInstance)	
	tEntityTable.Modifiers = SaveModifierData(hInstance)
	
	return tEntityTable
end

local function SaveItemData(hInstance)
	local tItemTable = {}
	tItemTable.ItemName = hInstance:GetAbilityName()
	tItemTable.StackCount = hInstance:GetStackCount()
	tItemTable.State = IW_SAVE_STATE_ENABLED

	local hContainer = hInstance:GetContainer()
	if hContainer then
		tItemTable.Position = hInstance:GetAbsOrigin()
	end
	
	tItemTable.ModifierSeeds = {}
	for k,v in pairs(hInstance._tModifierSeeds) do
		local tModifierSeeds = {}
		for k2,v2 in pairs(v) do
			tModifierSeeds[k2] = v2
		end
		tItemTable.ModifierSeeds[k] = tModifierSeeds
	end
	
	tItemTable.PropertySeeds = {}
	for k,v in pairs(hInstance._tPropertySeeds) do
		tItemTable.PropertySeeds[k] = v
	end
	
	tItemTable.ComponentList = {}
	for k,v in pairs(hInstance._tComponentList) do
		tItemTable.ComponentList[k:GetInstanceID()] = v
	end
	return tItemTable
end

local function SaveInteractableData(hInstance)
	local tInteractableData = {}
	tInteractableData.UnitName = hInstance:GetUnitName()
	tInteractableData.Position = hInstance:GetAbsOrigin()
	tInteractableData.Forward = hInstance:GetForwardVector()
	tInteractableData.State = IW_SAVE_STATE_ENABLED
	if IsValidContainer(hInstance) then
		tInteractableData.Type = IW_INTERACTABLE_TYPE_CONTAINER
		tInteractableData.Inventory = SaveInventoryData(hInstance)
		return tInteractableData
	elseif IsValidProp(hInstance) then
		tInteractableData.Type = IW_INTERACTABLE_TYPE_WORLD_OBJECT
		tInteractableData.ObjectState = hInstance._nObjectState 
		return tInteractableData
	end
end

function CSaveManager:SaveGame(szSaveName)
	if GameRules:IsInCombat() then
		GameRules:SendCustomMessage("#iw_error_save_combat", DOTA_TEAM_GOODGUYS, 0)
		return nil
	end
	
	while (CSaveManager._tSaveFiles[szSaveName] or not szSaveName) do
		szSaveName = PlayerResource:GetSteamAccountID(0) .. DoUniqueString(".txt")
	end
	
	local tSaveData = CSaveManager._tSaveData or {}
	if not tSaveData.GameStates then tSaveData.GameStates = {} end
	if not tSaveData.Entities then tSaveData.Entities = {} end
	if not tSaveData.Interactables then tSaveData.Interactables = {} end
	if not tSaveData.Items then tSaveData.Items = {} end
	if not tSaveData.Party then tSaveData.Party = {} end
	
	tSaveData["Version"] = IW_SAVE_VERSION
	tSaveData["SaveDate"] = GetSystemDate()
	tSaveData["SaveTime"] = GetSystemTime()
	tSaveData["Difficulty"] = GameRules:GetCustomGameDifficulty()
	tSaveData["TimeOfDay"] = GameRules:GetTimeOfDay()
	tSaveData["CurrentMap"] = GetMapName()
	tSaveData["TimePlayed"] = Time() + CSaveManager._nTimePlayed 
	tSaveData["NextInstanceID"] = CInstance._nNextDynamicID
	
	for k,v in pairs(CGameState._tChangedValues) do
		tSaveData.GameStates[k] = v
	end
	
	for _,hInstance in pairs(CInstance:GetInstanceList()) do
		local szInstanceName = tostring(hInstance:GetInstanceID())
		if hInstance:GetInstanceID() == 0 then
			--Do nothing; this is the "default" property instance used by CExtEntity
		elseif hInstance:IsNull() or not IsValidEntity(hInstance) then
			local tSaveValue = nil
			if hInstance:GetInstanceID() < IW_INSTANCE_DYNAMIC_BASE then
				tSaveValue = { State = IW_SAVE_STATE_DISABLED }
			end
			if hInstance._bIsExtendedEntity then
				tSaveData.Entities[szInstanceName] = tSaveValue
			elseif hInstance._bIsExtendedItem then
				tSaveData.Items[szInstanceName] = tSaveValue
			elseif hInstance._bIsInteractable then
				tSaveData.Interactables[szInstanceName] = tSaveValue
			end
		elseif IsValidExtendedEntity(hInstance) then
			tSaveData.Entities[szInstanceName] = SaveEntityData(hInstance)
		elseif IsValidExtendedItem(hInstance) then
			tSaveData.Items[szInstanceName] = SaveItemData(hInstance)
		elseif IsValidInteractable(hInstance) then
			tSaveData.Interactables[szInstanceName] = SaveInteractableData(hInstance)
		elseif IsValidExtendedAbility(hInstance) then
			--Do nothing; ability data is saved in the per-unit spellbook
		else
			LogMessage("Unknown type for instance with ID " .. szInstanceName .. ".", LOG_SEVERITY_ERROR)
		end
	end
	
	if not tSaveData.Party.Members then tSaveData.Party.Members = {} end
	if not tSaveData.Party.GridStates then tSaveData.Party.GridStates = {} end
	if not tSaveData.Party.AAM then tSaveData.Party.AAM = {} end
	for k,v in pairs(CParty._tMembers) do
		local hInstance = GetInstanceByID(v)
		if hInstance then
			tSaveData.Party.Members[k] = v
			local hAutomator = hInstance:GetAbilityAutomator()
			if hAutomator then
				local tAAMData = {}
				tAAMData.ActiveAutomator = hAutomator._szActiveAutomatorName
				tAAMData.State = hAutomator._tNetTable.State
				tAAMData.Automators = {}
				for k2,v2 in pairs(hAutomator._tAutomatorList or {}) do
					local tAutomatorData = {}
					for k3,v3 in pairs(v2) do
						table.insert(tAutomatorData, v3:GetSaveTable())
					end
					tAAMData.Automators[k2] = tAutomatorData
				end
				tSaveData.Party.AAM[tostring(v)] = tAAMData
			end
		end
	end
	
	local szSaveString = TableToSaveString(tSaveData)
	OutputToScaleform(szSaveName, szSaveString)
	
	CSaveManager._tSaveFiles[szSaveName] = true
	CSaveManager._tSaveSpecial.Latest = szSaveName
	CSaveManager:CreateSaveList()
	return szSaveName
end

function CSaveManager:QuicksaveGame()
	if GameRules:IsInCombat() then
		GameRules:SendCustomMessage("#iw_error_save_combat", 0, 0)
		return
	end
	GameRules:SendCustomMessage("#iw_ui_quicksave_start", 0, 0)
	local szSaveName = CSaveManager:SaveGame()
	CSaveManager._tSaveFiles[szSaveName] = true
	CSaveManager._tSaveSpecial.Quicksave = szSaveName
	CSaveManager:CreateSaveList()
	GameRules:SendCustomMessage("#iw_ui_quicksave_complete", 0, 0)
end

function CSaveManager:LoadSave(szSaveName)
	if szSaveName and CSaveManager._tSaveFiles[szSaveName] then
		local tSaveData = LoadKeyValues(CSaveManager._szSaveDirectory .. szSaveName)
		local szMapName = tSaveData.CurrentMap
		CSaveManager._tSaveSpecial.Loading = szSaveName
		CSaveManager:CreateSaveList()
		CTimer(0.1, FireGameEventLocal, "iw_change_level", { map = szMapName })
	end
end

local function LoadGlobalData()
	if CSaveManager._tSaveData.Difficulty then
		GameRules:SetCustomGameDifficulty(CSaveManager._tSaveData.Difficulty)
	end
	if CSaveManager._tSaveData.TimeOfDay then
		GameRules:SetTimeOfDay(CSaveManager._tSaveData.TimeOfDay)
	end
	
	CSaveManager._nTimePlayed = CSaveManager._tSaveData.TimePlayed or 0
	CSaveManager._szCurrentSave = CSaveManager._tSaveSpecial.Loading
	
	CInstance._nNextDynamicID = tonumber(CSaveManager._tSaveData.NextInstanceID) or IW_INSTANCE_DYNAMIC_BASE
end

local function LoadGameStates()
	local tGameStates = CSaveManager._tSaveData.GameStates or {}
	for k,v in pairs(tGameStates) do
		CGameState:SetGameStateValue(k, v)
	end
end

local function LoadItemData(nItemIndex, tItemData)
	if tItemData then
		local tItemSaveList = CSaveManager._tSaveData.Items or {}
		local hItem = CExtItem(CreateItem(tItemData.ItemName, nil, nil), tonumber(nItemIndex))
		hItem:SetStackCount(tItemData.StackCount)
		for k,v in pairs(tItemData.ModifierSeeds or {}) do
			for k2,v2 in pairs(v) do
				hItem._tModifierSeeds[k][tonumber(k2)] = v2
			end
		end
		for k,v in pairs(tItemData.PropertySeeds or {}) do
			local nPropertyID = tonumber(k)
			local tPropertyTable = hItem._tPropertyList[nPropertyID]
			if tPropertyTable then
				local k2,v2 = next(tPropertyTable)
				k2 = tonumber(k2)
				v2 = tonumber(v2)
				hItem:SetPropertyValue(nPropertyID, k2 + (v % v2))
			end
			hItem._tPropertySeeds[nPropertyID] = v
		end
		for k,v in pairs(tItemData.ComponentList or {}) do
			local hComponent = LoadItemData(k, tItemSaveList[k])
			if IsValidExtendedItem(hComponent) then
				hItem._tComponentList[hComponent] = tonumber(v)
				hItem:AddChild(hComponent)
			end
		end
		return hItem
	end
end

local function LoadPhysicalItems()
	local tItemSaveList = CSaveManager._tSaveData.Items or {}
	for k,v in pairs(tItemSaveList) do
		if v.Position then
			local hItem = LoadItemData(k, v)
			local vPosition = StringToVector(v.Position)
			CreateItemOnPositionSync(vPosition, hItem)
		end
	end
end

local function LoadInventoryData(hEntity, tInventoryData)
	local hInventory = hEntity:GetInventory()
	local tItemSaveList = CSaveManager._tSaveData.Items or {}
	hInventory:SetGoldAmount(tInventoryData.Gold)
	for k,v in pairs(tInventoryData) do
		if k ~= "Equipped" and k ~= "Gold" then
			local hItem = LoadItemData(v, tItemSaveList[v])
			if hItem then
				hInventory:AddItemToInventory(hItem)
			end
		end
	end
	for i = 1,IW_MAX_INVENTORY_SLOT-1 do
		hInventory:UnequipItem(i)
	end
	for k,v in pairs(tInventoryData.Equipped or {}) do
		local hItem = GetInstanceByID(tonumber(v))
		if hItem then
			hInventory:EquipItem(hItem, tonumber(k))
		end
	end
	hInventory:OnEntityRefresh()
end

local function LoadEntityData(hEntity, tEntityData)
	if IsValidExtendedEntity(hEntity) and tEntityData then
		for k,v in pairs(tEntityData.Properties or {}) do
			hEntity:SetPropertyValue(tonumber(k), v)
		end
		if tEntityData.Inventory then
			LoadInventoryData(hEntity, tEntityData.Inventory)
		end
		hEntity:RefreshEntity()
	else
		LogMessage("LoadEntityData() called with invalid entity data", LOG_SEVERITY_ERROR)
	end
end

local function LoadMapEntities()
	local tEntitySaveList = CSaveManager._tSaveData.Entities or {}
	for k,v in pairs(CSaveManager._tInstanceData) do
		local nInstanceID = tonumber(k)
		local hPrecondition = CExpression(v.Precondition or "")
		if stInstanceData[k] and stInstanceData[k].Type == IW_INSTANCE_EXT_ENTITY and hPrecondition:EvaluateExpression() then
			local tEntityData = tEntitySaveList[k]
			if not tEntityData or tEntityData.State == IW_SAVE_STATE_ENABLED then
				local hEntity = nil
				if nInstanceID == CGameState:GetGameStateValue("game.hero_selection") then
					hEntity = CExtEntity(GameRules:GetPlayerHero(), nInstanceID)
				else
					local szUnitName = stInstanceData[k].Name
					local nUnitTeam = stInstanceData[k].Team
					hEntity = CExtEntity(CreateUnitByName(szUnitName, Vector(0, 0, 0), false, nil, nil, nUnitTeam), nInstanceID)
					hEntity = CDialogueEntity(hEntity)
				end
				if IsValidExtendedEntity(hEntity) and tEntityData then
					LoadEntityData(hEntity, tEntityData)
				end
			end
		end
	end
end

local function LoadPlayerEntities()
	local tEntitySaveList = CSaveManager._tSaveData.Entities or {}
	for k,v in pairs(tEntitySaveList) do
		local nInstanceID = tonumber(k)
		local nInstanceState = v.State
		if nInstanceState == IW_SAVE_STATE_PERSISTENT and (v.Health ~= 0 or v.LastMap == GetMapName()) then
			local hEntity = GetInstanceByID(nInstanceID)
			if not hEntity then
				if nInstanceID == CGameState:GetGameStateValue("game.hero_selection") then
					hEntity = CExtEntity(GameRules:GetPlayerHero(), nInstanceID)
				else
					hEntity = CExtEntity(CreateUnitByName(v.UnitName, Vector(0, 0, 0), false, nil, nil, v.Team), nInstanceID)
					hEntity = CDialogueEntity(hEntity)
				end
			end
			if IsValidExtendedEntity(hEntity) then
				LoadEntityData(hEntity, v)
				hEntity:SetControllableByPlayer(0, true)
			end
		end
	end
end

local function LoadSavedContainers()
	local tInteractableSaveList = CSaveManager._tSaveData.Interactables or {}
	for k,v in pairs(CSaveManager._tInstanceData) do
		local nInstanceID = tonumber(k)
		local hPrecondition = CExpression(v.Precondition or "")
		if stInstanceData[k] and stInstanceData[k].Type == IW_INSTANCE_CONTAINER and hPrecondition:EvaluateExpression() then
			local tContainerData = tInteractableSaveList[k]
			if tContainerData and tContainerData.State ~= IW_SAVE_STATE_DISABLED then
				local szUnitName = stInstanceData[k].Name
				local nUnitTeam = stInstanceData[k].Team
				local hContainer = CContainer(CreateUnitByName(szUnitName, StringToVector(v.Position), false, nil, nil, nUnitTeam), nInstanceID, false)
				LoadInventoryData(hContainer, tContainerData.Inventory)
				hContainer:SetForwardVector(StringToVector(v.Forward))
			end
		end
	end
end

local function LoadWorldObjects()
	local tInteractableSaveList = CSaveManager._tSaveData.Interactables or {}
	for k,v in pairs(CSaveManager._tInstanceData) do
		local nInstanceID = tonumber(k)
		local hPrecondition = CExpression(v.Precondition or "")
		if stInstanceData[k] and stInstanceData[k].Type == IW_INSTANCE_PROP and hPrecondition:EvaluateExpression() then
			local tPropData = tInteractableSaveList[k]
			if not tPropData or tPropData.State ~= IW_SAVE_STATE_DISABLED then
				local szUnitName = stInstanceData[k].Name
				local nUnitTeam = stInstanceData[k].Team
				local hObject = CWorldObject(CreateUnitByName(szUnitName, StringToVector(v.Position), false, nil, nil, nUnitTeam), nInstanceID)
				if tPropData and tPropData.ObjectState then
					hObject._nObjectState = tPropData.ObjectState
				end
				hObject:SetForwardVector(StringToVector(v.Forward))
			end
		end
	end
end

local function LoadAbilities()
	local tEntitySaveList = CSaveManager._tSaveData.Entities or {}
	for k,v in pairs(tEntitySaveList) do
		local nInstanceID = tonumber(k)
		local hEntity = GetInstanceByID(nInstanceID)
		if IsValidExtendedEntity(hEntity) then
			local hSpellbook = hEntity:GetSpellbook()
			local tSpellbookData = v.Spellbook or {}
			for k2,v2 in pairs(tSpellbookData) do
				if k2 ~= "Binds" then
					local hAbility = hSpellbook:LearnAbility(k2, v2.Level)
					if hAbility then
						if v2.Cooldown > 0 then
							hAbility:StartCooldown(v2.Cooldown)
						end
						if v2.IsAutoCast == 1 then
							hAbility:ToggleAutoCast()
						end
						if v2.IsToggled == 1 then
							hAbility:ToggleAbility()
						end
					end
				end
			end
			for k2,v2 in pairs(tSpellbookData.Binds or {}) do
				local hAbility = hSpellbook:FindAbilityByName(v2)
				if hAbility then
					FireGameEventLocal("iw_actionbar_bind", { entindex = hEntity:entindex(), ability = hAbility:entindex(), slot = tonumber(k2) })
				end
			end
			hSpellbook:OnEntityRefresh()
		end
	end
end

local function LoadParty()
	if CSaveManager._tSaveData.Party then
		if CSaveManager._tSaveData.Party.Members then
			local tMemberData = CSaveManager._tSaveData.Party.Members
			for k,v in pairs(tMemberData) do
				if tonumber(k) then
					tMemberData[tonumber(k)] = v
				end
			end
			for k,v in ipairs(tMemberData) do
				local hEntity = GetInstanceByID(v)
				if hEntity then
					CParty:AddToParty(hEntity)
				end
			end
		end
		if CSaveManager._tSaveData.Party.AAM then
			for k,v in pairs(CSaveManager._tSaveData.Party.AAM) do
				local hEntity = GetInstanceByID(tonumber(k))
				local hAutomator = hEntity:GetAbilityAutomator()
				if hAutomator then
					for k2,v2 in pairs(v.Automators or {}) do
						local tSortedIndices = {}
						for k3,v3 in pairs(v2) do
							table.insert(tSortedIndices, k3)
						end
						table.sort(tSortedIndices)
						for k3,v3 in ipairs(tSortedIndices) do
							local tConditionData = v2[v3]
							local szAction = tConditionData.ActionName
							local nFlags1 = tonumber(tConditionData.Flags1)
							local nFlags2 = tonumber(tConditionData.Flags2)
							local nInvMask = tonumber(tConditionData.InverseMask)
							hAutomator:InsertCondition(k2, CAutomatorCondition(hEntity, szAction, nFlags1, nFlags2, nInvMask))
						end
					end
					hAutomator:SetActiveAutomator(v.ActiveAutomator)
					hAutomator:SetEnabled(v.State == AAM_STATE_ENABLED)
					hAutomator._tNetTable.State = v.State
					hAutomator:OnEntityRefresh()
				end
			end
		end
	end
end


local function LoadSavedModifierData(hEntity, tModifierData)
	local _, _, szAbilityName, szModifierName = string.find(tModifierData.Name, "([%w_]+):([%w_]+)")
	local hSource = GetInstanceByID(tonumber(tModifierData.Source))
	local hModifier = AddModifier(szAbilityName, szModifierName, hEntity, hSource, tModifierData.ModifierArgs)
	if hModifier then
		local nStackCount = tModifierData.StackCount or 0
		if nStackCount > 0 then
			hModifier:SetStackCount(nStackCount)
		end
		CDOTA_Buff.SetDuration(hModifier, tModifierData.Duration, true)
		for k,v in pairs(tModifierData.Properties or {}) do
			hModifier:SetPropertyValues(k,v)
		end
	end
end

local function LoadEntityPositions()
	local tEntitySaveList = CSaveManager._tSaveData.Entities or {}
	local hEntity = Entities:First()
	while hEntity do
		if IsValidExtendedEntity(hEntity) then
			local nInstanceID = hEntity:GetInstanceID()
			local tEntityData = tEntitySaveList[tostring(nInstanceID)]
			local tInstanceData = CSaveManager._tInstanceData[tostring(nInstanceID)]
			if tEntityData and tEntityData.State == IW_SAVE_STATE_PERSISTENT then
				if tEntityData.Health > 0 and tEntityData.LastMap ~= GetMapName() then
					local hDefaultSpawn = Entities:FindByName(nil, "spawnloc_" .. CSaveManager._tSaveData.CurrentMap)
					if not hDefaultSpawn then hDefaultSpawn = Entities:FindByName(nil, "spawnloc_" .. nInstanceID) end
					if not hDefaultSpawn then hDefaultSpawn = Entities:FindByName(nil, "spawnloc_default") end
					if not hDefaultSpawn then LogMessage("No default spawn location present on map!") end
					FindClearSpaceForUnit(hEntity, hDefaultSpawn:GetAbsOrigin(), false)
					hEntity:SetForwardVector(hDefaultSpawn:GetForwardVector())
				else
					hEntity:SetAbsOrigin(StringToVector(tEntityData.Position))
					hEntity:SetForwardVector(StringToVector(tEntityData.Forward))
				end
			elseif tInstanceData then
				if tEntityData and tEntityData.LastMap == GetMapName() then
					hEntity:SetAbsOrigin(StringToVector(tEntityData.Position))
					hEntity:SetForwardVector(StringToVector(tEntityData.Forward))
				else
					local vPosition = StringToVector(tInstanceData.Position)
					if tInstanceData.UseAbsolutePosition ~= "1" then
						vPosition = GetGroundPosition(vPosition, hEntity)
					end
					hEntity:SetAbsOrigin(vPosition)
					hEntity:SetForwardVector(StringToVector(tInstanceData.Forward))
					if IsValidNPCEntity(hEntity) then
						hEntity._vInitialPos = vPosition
						hEntity._nLastWaypoint = tInstanceData.LastWaypoint or 0
						hEntity._nNextWaypoint = tInstanceData.NextWaypoint or 0
					end
				end
			end
		end
		hEntity = Entities:Next(hEntity)
	end
end

local function ClearNoisePoint(self, nIndex)
	self._tNoiseTable[nIndex] = nil
end

local function LoadEntityValues()
	local tEntitySaveList = CSaveManager._tSaveData.Entities or {}
	local hEntity = Entities:First()
	while hEntity do
		if IsValidExtendedEntity(hEntity) then
			local nInstanceID = hEntity:GetInstanceID()
			local tEntityData = tEntitySaveList[tostring(nInstanceID)]
			if tEntityData then
				hEntity._vInitialPos = StringToVector(tEntityData.InitialPos)
				if tEntityData.Health == 0 then
					hEntity:ForceKill(false)
				else
					hEntity:SetHealth(tEntityData.Health)
				end
				hEntity:SetMana(tEntityData.Mana)
				hEntity:SetStamina(tEntityData.Stamina)
				if tEntityData.RunMode == 1 then
					hEntity:SetRunMode(true)
				end
				
				if IsValidNPCEntity(hEntity) then
					local fCurrentTime = GameRules:GetGameTime()
					for k,v in pairs(tEntityData.ThreatTable or {}) do
						local hThreatEntity = GetInstanceByID(k)
						if IsValidExtendedEntity(hThreatEntity) then
							hEntity._tThreatTable[hThreatEntity:entindex()] = v
						end
					end
					for k,v in pairs(tEntityData.DetectTable or {}) do
						local hDetectEntity = GetInstanceByID(k)
						if IsValidEntity(hDetectEntity) then
							hEntity._tDetectTable[hDetectEntity:entindex()] = fCurrentTime + v
						end
					end
					for k,v in pairs(tEntityData.NoiseTable or {}) do
						hEntity._tNoiseTable[hEntity._nNoiseTableIndex] =
						{
							value    = v.value,
							origin   = StringToVector(v.origin),
							speed    = v.speed,	
							time     = fCurrentTime + v.time,
							duration = v.duration,
						}
						CTimer(fCurrentTime + v.time + v.duration, ClearNoisePoint, hEntity, hEntity._nNoiseTableIndex)
						hEntity._nNoiseTableIndex = hEntity._nNoiseTableIndex + 1
					end
					hEntity._nLastWaypoint = tEntityData.LastWaypoint
					hEntity._nNextWaypoint = tEntityData.NextWaypoint
				end
			end
		end
		hEntity = Entities:Next(hEntity)
	end	
end

local function LoadModifiers()
	local tEntitySaveList = CSaveManager._tSaveData.Entities or {}
	for k,v in pairs(CSaveManager._tInstanceData) do
		local nInstanceID = tonumber(k)
		local hInstance = GetInstanceByID(nInstanceID)
		local tEntityData = tEntitySaveList[k]
		if hInstance and tEntityData then
			for k2,v2 in pairs(tEntityData.Modifiers or {}) do
				LoadSavedModifierData(hInstance, v2)
			end
		end
		if IsValidExtendedEntity(hInstance) then
			for k2,v2 in pairs(v.Modifiers or {}) do
				_, _, szAbilityName, szModifierName = string.find(k2, "([%w_]+):([%w_]+)")
				if szAbilityName and szModifierName then
					for k3,v3 in pairs(v2) do
						if type(v3) == "string" and _G[v3] then
							v2[k3] = _G[v3]
						end
					end
					
					AddModifier(szAbilityName, szModifierName, hInstance, hInstance, v2)
				end
			end
		end
	end
	
	for k,v in pairs(tEntitySaveList) do
		local nInstanceID = tonumber(k)
		local nInstanceState = v.State
		if nInstanceState == 2 or (nInstanceState == 1 and bIsCurrentMap) then
			local hInstance = GetInstanceByID(nInstanceID)
			if IsValidExtendedEntity(hEntity) then
				for k2,v2 in pairs(v.Modifiers or {}) do
					LoadSavedModifierData(hInstance, v2)
				end
			end
		end
	end
end

local function LoadMapContainers()
	local tInteractableSaveList = CSaveManager._tSaveData.Interactables or {}
	for k,v in pairs(CSaveManager._tInstanceData) do
		local nInstanceID = tonumber(k)
		local hPrecondition = CExpression(v.Precondition or "")
		if stInstanceData[k] and stInstanceData[k].Type == IW_INSTANCE_CONTAINER and hPrecondition:EvaluateExpression() then
			local tContainerData = tInteractableSaveList[k]
			if not tContainerData then
				local szUnitName = stInstanceData[k].Name
				local nUnitTeam = stInstanceData[k].Team
				local hContainer = CContainer(CreateUnitByName(szUnitName, StringToVector(v.Position), false, nil, nil, nUnitTeam), nInstanceID, true)
				hContainer:SetForwardVector(StringToVector(v.Forward))
			end
		end
	end
end

function CSaveManager:LoadGame()
	--TODO: Save and load party formation
	CInstance:SetAllowDynamicInstances(false)
	LoadGlobalData()
	LoadGameStates()
	LoadPhysicalItems()
	LoadMapEntities()
	LoadPlayerEntities()
	LoadSavedContainers()
	LoadWorldObjects()
	LoadAbilities()
	LoadParty()
	LoadEntityPositions()
	LoadEntityValues()
	LoadMapContainers()
	LoadModifiers()
	CInstance:SetAllowDynamicInstances(true)
end

end