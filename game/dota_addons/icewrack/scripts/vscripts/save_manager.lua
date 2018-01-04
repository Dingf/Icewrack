--[[
	Icewrack Save Manager
]]

--TODO: Save NPC/ext_entity stuff like threat, detected entities, noise points, etc.
if not CSaveManager then

if _VERSION < "Lua 5.2" then
    bit = require("lib/numberlua")
    bit32 = bit.bit32
end

require("instance")
require("bind_manager")
require("game_states")
require("container")
require("ext_ability")
require("ext_item")
require("ext_entity")
require("ext_hero")
require("world_object")
require("dialogue")
require("spellbook")
require("aam")
require("party")

IW_SAVE_VERSION = 900

IW_SAVE_MODE_NORMAL = 0
IW_SAVE_MODE_QUICKSAVE = 1
IW_SAVE_MODE_AUTOSAVE = 2

IW_SAVE_STATE_DISABLED = 0		--This instance won't spawn at all
IW_SAVE_STATE_ENABLED = 1		--This instance will spawn if the map has it listed in its instance list or if it is not an ext_entity/interactable
IW_SAVE_STATE_PERSISTENT = 2	--This instance is player-controlled and will always spawn if its not disabled/dead

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

function CSaveManager:PrecacheSaveEntities(hContext)
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
	
	local stExtEntityData = LoadKeyValues("scripts/npc/npc_units_extended.txt")
	for k,_ in pairs(tPrecacheList) do
		PrecacheUnitByNameSync(k, hContext)
		local tExtEntityTemplate = stExtEntityData[k]
		if tExtEntityTemplate then
			if tExtEntityTemplate.SoundEvents then
				PrecacheResource("soundfile", stExtEntityData[k].SoundEvents, hContext)
			end
			if tExtEntityTemplate.Animation then
				for k2,v2 in pairs(tExtEntityTemplate.Animation) do
					RegisterCustomAnimationScriptForModel(k2, v2)
				end
			end
		end
	end
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
		CTimer(0.1, FireGameEventLocal, "iw_change_level", { map = keys.map })
	end
end

local function SaveInventoryData(hInstance)
	if IsValidContainer(hInstance) then
		local tInventoryTable = {}
		tInventoryTable.Gold = hInstance:GetGoldAmount()
		tInventoryTable.Equipped = {}
		for k,v in pairs(hInstance._tEquippedItems) do
			tInventoryTable.Equipped[k] = v:GetInstanceID()
		end
		for k,v in pairs(hInstance._tItemList) do
			table.insert(tInventoryTable, k:GetInstanceID())
		end
		return tInventoryTable
	end
end

local function SaveSpellbookData(hInstance)
	if IsInstanceOf(hInstance, CSpellbook) then
		local tSpellbookTable = {}
		for k,v in pairs(hInstance._tSpellList) do
			local hSpellUnit = v
			local hAbility = v:FindAbilityByName(k)
			if hAbility then
				local tAbilityTable = {}
				tAbilityTable.Name = hAbility:GetAbilityName()
				tAbilityTable.Level = hAbility:GetLevel()
				tAbilityTable.Cooldown = math.max(0, hAbility:GetCooldownTimeRemaining())
				tAbilityTable.IsAutoCast = hAbility:GetAutoCastState() and 1 or 0
				tAbilityTable.IsToggled = hAbility:GetToggleState() and 1 or 0
				tAbilityTable.IsActivated = hAbility:IsActivated() and 1 or 0
				tSpellbookTable[hAbility:GetInstanceID()] = tAbilityTable
			end
		end
		return tSpellbookTable
	end
end

local function SaveModifierData(hInstance)
	if IsValidExtendedEntity(hInstance) then
		local tSaveModifierList = {}
		local tEntityModifierList = hInstance:FindAllModifiers()
		for k,v in pairs(tEntityModifierList) do
			if IsValidExtendedModifier(v) and not v:IsHidden() and not v:IsProvidedByAura() then
				local tModifierTable = {}
				tModifierTable.Name = v:GetAbilityName() .. ":" .. v:GetName()
				tModifierTable.Duration = v:GetRemainingTime()
				tModifierTable.StackCount = v:GetStackCount()
						
				local hAbility = v:GetAbility()
				tModifierTable.Source = IsValidExtendedAbility(hAbility) and hAbility:GetInstanceID() or 0
				tModifierTable.Caster = v:GetCaster():GetInstanceID() or 0
				tModifierTable.ModifierArgs = {}
				for k2,v2 in pairs(v._tModifierArgs) do
					tModifierTable.ModifierArgs[k2] = (type(v2) == "table") and v2:GetInstanceID() or v2
				end
				tModifierTable.Properties = {}
				for k2,v2 in pairs(stIcewrackPropertyEnum) do
					tModifierTable.Properties[v2] = rawget(v._tPropertyValues, v2)
				end
				table.insert(tSaveModifierList, tModifierTable)
			end
		end
		return tSaveModifierList
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
	tEntityTable.StaminaTime = hInstance:GetStaminaRegenTime() - GameRules:GetGameTime()
	tEntityTable.FactionID = hInstance:GetFactionID()
	tEntityTable.LastMap = GetMapName()
	tEntityTable.RunMode = hInstance:IsRunning() and 1 or 0
	tEntityTable.HoldMode = hInstance:IsHoldingPosition() and 1 or 0
	tEntityTable.State = (hInstance:IsControllableByAnyPlayer()) and IW_SAVE_STATE_PERSISTENT or IW_SAVE_STATE_ENABLED
	
	if IsValidExtendedHero(hInstance) then
		tEntityTable.Experience = hInstance:GetTotalExperience()
	end
	
	tEntityTable.Properties = {}
	for k,v in pairs(stIcewrackPropertyEnum) do
		tEntityTable.Properties[v] = rawget(hInstance._tPropertyValues, v)
	end
	
	tEntityTable.FactionWeights = {}
	for k,v in pairs(hInstance._tFactionWeights) do
		tEntityTable.FactionWeights[k] = v
	end
	
	if IsValidExtendedEntity(hInstance) then
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
		tEntityTable.NoiseTable = hInstance._tNoiseTable
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
		tItemTable.Position = hContainer:GetAbsOrigin()
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
	tInteractableData.LastMap = GetMapName()
	tInteractableData.FactionID = hInstance:GetFactionID()
	tInteractableData.State = IW_SAVE_STATE_ENABLED
	
	local hOwner = hInstance:GetOwner()
	if hOwner then
		tInteractableData.Owner = hOwner:GetInstanceID()
	end
	if IsValidContainer(hInstance) then
		tInteractableData.Type = IW_INSTANCE_CONTAINER
		tInteractableData.LockLevel = hInstance:GetLockLevel()
		tInteractableData.Inventory = SaveInventoryData(hInstance)
		return tInteractableData
	elseif IsValidWorldObject(hInstance) then
		tInteractableData.Type = IW_INSTANCE_WORLD_OBJECT
		tInteractableData.ObjectState = hInstance._fObjectState 
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
	if not tSaveData.Binds then tSaveData.Binds = {} end
	
	tSaveData["Version"] = IW_SAVE_VERSION
	tSaveData["SaveDate"] = GetSystemDate()
	tSaveData["SaveTime"] = GetSystemTime()
	tSaveData["Difficulty"] = GameRules:GetCustomGameDifficulty()
	tSaveData["TimeOfDay"] = GameRules:GetTimeOfDay()
	tSaveData["CurrentMap"] = GetMapName()
	tSaveData["TimePlayed"] = Time() + CSaveManager._nTimePlayed 
	tSaveData["NextInstanceID"] = CInstance._nNextDynamicID
	
	for k,v in pairs(GameRules:GetModifiedGameStates()) do
		tSaveData.GameStates[k] = v
	end
	
	for _,hInstance in pairs(CInstance:GetInstanceList()) do
		local nInstanceID = hInstance:GetInstanceID()
		local szInstanceName = tostring(nInstanceID)
		if nInstanceID == 0 then
			--Do nothing; this is the "default" property instance used by CExtEntity
		elseif hInstance:IsNull() or not IsValidEntity(hInstance) or not hInstance:GetInstanceState() then
			local tSaveValue = nil
			if nInstanceID < IW_INSTANCE_DYNAMIC_BASE then
				tSaveValue = { State = IW_SAVE_STATE_DISABLED }
			end
			if IsInstanceOf(hInstance, CExtEntity) then
				tSaveData.Entities[szInstanceName] = tSaveValue
			elseif IsInstanceOf(hInstance, CExtItem) then
				tSaveData.Items[szInstanceName] = tSaveValue
			elseif IsInstanceOf(hInstance, CContainer) or IsInstanceOf(hInstance, CWorldObject) then
				tSaveData.Interactables[szInstanceName] = tSaveValue
			end
		elseif IsValidExtendedEntity(hInstance) then
			tSaveData.Entities[szInstanceName] = SaveEntityData(hInstance)
		elseif IsValidExtendedItem(hInstance) then
			if not bit32.btest(hInstance:GetItemFlags(), IW_ITEM_FLAG_DONT_SAVE) then
				tSaveData.Items[szInstanceName] = SaveItemData(hInstance)
			end
		elseif IsValidContainer(hInstance) or IsValidWorldObject(hInstance) then
			tSaveData.Interactables[szInstanceName] = SaveInteractableData(hInstance)
		elseif IsValidExtendedAbility(hInstance) then
			--Do nothing; ability data is saved in the per-unit spellbook
		else
			LogMessage("Unknown type for instance with ID " .. szInstanceName .. ".", LOG_SEVERITY_ERROR)
		end
	end
	
	for k,v in pairs(CBindManager._tActionBinds) do
		local hEntity = EntIndexToHScript(k)
		if IsValidExtendedEntity(hEntity) and hEntity:IsControllableByAnyPlayer() then
			local tEntityBindTable = {}
			for k2,v2 in pairs(v) do
				tEntityBindTable[k2] = v2
			end
			tSaveData.Binds[tostring(hEntity:GetInstanceID())] = tEntityBindTable
		end
	end
	
	if not tSaveData.Party.Members then tSaveData.Party.Members = {} end
	if not tSaveData.Party.GridStates then tSaveData.Party.GridStates = {} end
	if not tSaveData.Party.AAM then tSaveData.Party.AAM = {} end
	for k,v in pairs(CParty._tMembers) do
		local hInstance = GetInstanceByID(v)
		if hInstance then
			local tAAMData = {}
			tAAMData.ActiveAutomator = hInstance._szActiveAutomatorName
			tAAMData.State = hInstance._tAutomatorNetTable.State
			tAAMData.Automators = {}
			for k2,v2 in pairs(hInstance._tAutomatorList or {}) do
				local tAutomatorData = {}
				for k3,v3 in pairs(v2) do
					table.insert(tAutomatorData, v3:GetSaveTable())
				end
				tAAMData.Automators[k2] = tAutomatorData
			end
			tSaveData.Party.AAM[tostring(v)] = tAAMData
			tSaveData.Party.Members[k] = v
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
		GameRules:SetGameState(k, v)
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
	if IsValidContainer(hEntity) then
		local tItemSaveList = CSaveManager._tSaveData.Items or {}
		hEntity:SetGoldAmount(tInventoryData.Gold)
		for k,v in pairs(tInventoryData) do
			if k ~= "Equipped" and k ~= "Gold" then
				local hItem = LoadItemData(v, tItemSaveList[v])
				if hItem then
					hEntity:AddItemToInventory(hItem)
				end
			end
		end
		for i = 1,IW_MAX_INVENTORY_SLOT-1 do
			hEntity:UnequipItem(i)
		end
		for k,v in pairs(tInventoryData.Equipped or {}) do
			local hItem = GetInstanceByID(tonumber(v))
			if hItem then
				hEntity:EquipItem(hItem, tonumber(k))
			end
		end
		hEntity:RefreshInventory()
	end
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

local function LoadStaticEntities()
	local tEntitySaveList = CSaveManager._tSaveData.Entities or {}
	for k,v in pairs(CSaveManager._tInstanceData) do
		local nInstanceID = tonumber(k)
		local hPrecondition = LoadFunctionSnippet(v.Precondition)
		if stInstanceData[k] and stInstanceData[k].Type == IW_INSTANCE_EXT_ENTITY and (not hPrecondition or hPrecondition()) then
			local tEntityData = tEntitySaveList[k]
			if not tEntityData or tEntityData.State == IW_SAVE_STATE_ENABLED then
				local hEntity = nil
				if nInstanceID ~= GameRules:GetGameState("game.hero_selection") then
					local szUnitName = stInstanceData[k].Name
					local nFactionID = tEntityData and tEntityData.FactionID or stInstanceData[k].FactionID
					hEntity = CExtEntity(CreateUnitByName(szUnitName, Vector(0, 0, 0), false, nil, nil, DOTA_TEAM_GOODGUYS), nInstanceID)
					if IsInstanceOf(hEntity, CDOTA_BaseNPC_Hero) then
						hEntity = CExtHero(hEntity)
					end
					hEntity:SetFactionID(nFactionID)
				end
				if IsValidExtendedEntity(hEntity) then
					if tEntityData then
						LoadEntityData(hEntity, tEntityData)
					else
						hEntity:GenerateItemList()
					end
				end
			end
		end
	end
end

local function LoadDynamicEntities()
	local tEntitySaveList = CSaveManager._tSaveData.Entities or {}
	for k,v in pairs(tEntitySaveList) do
		local nInstanceID = tonumber(k)
		local bIsPersistentInstance = (v.State == IW_SAVE_STATE_PERSISTENT and (v.Health > 0 or v.LastMap == GetMapName()))
		local bIsMapDynamicInstance = (v.State == IW_SAVE_STATE_ENABLED and nInstanceID >= IW_INSTANCE_DYNAMIC_BASE and v.LastMap == GetMapName())
		if bIsPersistentInstance or bIsMapDynamicInstance then
			local hEntity = GetInstanceByID(nInstanceID)
			if not hEntity then
				if nInstanceID ~= GameRules:GetGameState("game.hero_selection") then
					local szUnitName = v.UnitName
					local nFactionID = v.FactionID
					hEntity = CExtEntity(CreateUnitByName(szUnitName, Vector(0, 0, 0), false, nil, nil, DOTA_TEAM_GOODGUYS), nInstanceID)
					if IsInstanceOf(hEntity, CDOTA_BaseNPC_Hero) then
						hEntity = CExtHero(hEntity)
					end
					hEntity:SetFactionID(nFactionID)
				end
			end
			if IsValidExtendedEntity(hEntity) then
				LoadEntityData(hEntity, v)
				if bIsPersistentInstance then
					hEntity:SetControllableByPlayer(0, true)
				end
			end
		end
	end
end

local function LoadStaticInteractables()
	local tInteractableSaveList = CSaveManager._tSaveData.Interactables or {}
	for k,v in pairs(CSaveManager._tInstanceData) do
		local nInstanceID = tonumber(k)
		local hPrecondition = LoadFunctionSnippet(v.Precondition)
		if stInstanceData[k] and (not hPrecondition or hPrecondition()) then
			local tInteractableData = tInteractableSaveList[k]
			local szUnitName = stInstanceData[k].Name
			local nFactionID = stInstanceData[k].FactionID
			local hOwner = tInteractableData and GetInstanceByID(tInteractableData.Owner) or nil
			local vPosition = StringToVector(v.Position)
			local vForward = StringToVector(v.Forward)
			if stInstanceData[k].Type == IW_INSTANCE_CONTAINER then
				if tInteractableData and tInteractableData.State == IW_SAVE_STATE_ENABLED then
					local hContainer = CContainer(CreateUnitByName(szUnitName, vPosition, false, hOwner, hOwner, DOTA_TEAM_GOODGUYS), nInstanceID)
					if tInteractableData then
						LoadInventoryData(hContainer, tInteractableData.Inventory)
						hContainer:SetLockLevel(tInteractableData.LockLevel)
					end
					hContainer:SetAbsOrigin(vPosition)
					hContainer:SetForwardVector(vForward)
					hContainer:SetFactionID(nFactionID)
				end
			elseif stInstanceData[k].Type == IW_INSTANCE_WORLD_OBJECT then
				local tInteractableData = tInteractableSaveList[k]
				if not tInteractableData or tInteractableData.State == IW_SAVE_STATE_ENABLED then
					local hWorldObject = CWorldObject(CreateUnitByName(szUnitName, vPosition, false, hOwner, hOwner, DOTA_TEAM_GOODGUYS), nInstanceID)
					if tInteractableData then
						hWorldObject:SetObjectState(tInteractableData.ObjectState)
					end
					hWorldObject:SetAbsOrigin(vPosition)
					hWorldObject:SetForwardVector(vForward)
					hWorldObject:SetFactionID(nFactionID)
				end
			end
		end
	end
end

local function LoadDynamicInteractables()
	local tInteractableSaveList = CSaveManager._tSaveData.Interactables or {}
	for k,v in pairs(tInteractableSaveList) do
		local nInstanceID = tonumber(k)
		local bIsPersistentInstance = (v.State == IW_SAVE_STATE_PERSISTENT and (v.Health > 0 or v.LastMap == GetMapName()))
		local bIsMapDynamicInstance = (v.State == IW_SAVE_STATE_ENABLED and nInstanceID >= IW_INSTANCE_DYNAMIC_BASE and v.LastMap == GetMapName())
		if bIsPersistentInstance or bIsMapDynamicInstance then
			local szUnitName = v.UnitName
			local nFactionID = v.FactionID
			local hOwner = GetInstanceByID(v.Owner)
			local vPosition = StringToVector(v.Position)
			local vForward = StringToVector(v.Forward)
			if v.Type == IW_INSTANCE_CONTAINER then
				local hContainer = CContainer(CreateUnitByName(szUnitName, vPosition, false, hOwner, hOwner, DOTA_TEAM_GOODGUYS), nInstanceID)
				LoadInventoryData(hContainer, v.Inventory)
				hContainer:SetLockLevel(v.LockLevel)
				hContainer:SetAbsOrigin(vPosition)
				hContainer:SetForwardVector(vForward)
				hContainer:SetFactionID(nFactionID)
			elseif v.Type == IW_INSTANCE_WORLD_OBJECT then
				local hWorldObject = CWorldObject(CreateUnitByName(szUnitName, vPosition, false, hOwner, hOwner, DOTA_TEAM_GOODGUYS), nInstanceID)
				hWorldObject:SetObjectState(v.ObjectState)
				hWorldObject:SetAbsOrigin(vPosition)
				hWorldObject:SetForwardVector(vForward)
				hWorldObject:SetFactionID(nFactionID)
			end
		end
	end
end

local function LoadAbilitiesForEntity(hEntity, tSpellbookData)
	for k,v in pairs(tSpellbookData) do
		local nInstanceID = tonumber(k)
		if nInstanceID then
			local hAbility = hEntity:LearnAbility(v.Name, nInstanceID)
			if hAbility then
				hAbility:SetLevel(v.Level)
				if v.Cooldown > 0 then
					hAbility:StartCooldown(v.Cooldown)
				end
				if v.IsAutoCast == 1 then
					hAbility:OnToggleAutoCast()
					hAbility:ToggleAutoCast()
				end
				if v.IsToggled == 1 then
					hAbility:ToggleAbility()
				end
				hAbility:SetActivated(v.IsActivated == 1)
			end
		end
	end
	hEntity:UpdateSpellbookNetTable()
end

local function LoadAbilities()
	local tEntitySaveList = CSaveManager._tSaveData.Entities or {}
	for k,v in pairs(tEntitySaveList) do
		local nInstanceID = tonumber(k)
		local hEntity = GetInstanceByID(nInstanceID)
		local tSpellbookData = v.Spellbook
		if IsValidExtendedEntity(hEntity) and tSpellbookData then
			LoadAbilitiesForEntity(hEntity, v.Spellbook)
			--local hSpellbook = hEntity:GetSpellbook()
			
			--[[for k2,v2 in pairs(tSpellbookData.Binds or {}) do
				local hAbility = hEntity:FindAbilityByName(v2)
				if hAbility then
					FireGameEventLocal("iw_actionbar_bind", { entindex = hEntity:entindex(), ability = hAbility:entindex(), slot = tonumber(k2) })
				end
			end]]
		end
	end
end

local function LoadAAMData(hEntity, tAAMData)
	if IsInstanceOf(hEntity, CAbilityAutomatorModule) and IsValidExtendedHero(hEntity) then
		hEntity._tAutomatorList = {}
		hEntity._szActiveAutomatorName = nil
			
		for k,v in pairs(tAAMData.Automators or {}) do
			local tSortedIndices = {}
			for k2,v2 in pairs(v) do
				table.insert(tSortedIndices, k2)
			end
			table.sort(tSortedIndices)
			for k2,v2 in ipairs(tSortedIndices) do
				local tConditionData = v[v2]
				local szAction = tConditionData.ActionName
				local nFlags1 = tonumber(tConditionData.Flags1)
				local nFlags2 = tonumber(tConditionData.Flags2)
				local nInvMask = tonumber(tConditionData.InverseMask)
				hEntity:InsertAutomatorCondition(k, CAutomatorCondition(hEntity, szAction, nFlags1, nFlags2, nInvMask))
			end
		end
		hEntity._tNetTable.State = tAAMData.State
		hEntity:SetActiveAutomator(tAAMData.ActiveAutomator)
		hEntity:SetAutomatorEnabled(tAAMData.State == AAM_STATE_ENABLED)
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
				if hEntity then
					LoadAAMData(hEntity, v)
				end
			end
		end
	end
end


local function LoadSavedModifierData(hEntity, tModifierData, nInstanceID)
	local _, _, szAbilityName, szModifierName = string.find(tModifierData.Name, "([%w_]+):([%w_]+)")
	
	local hSource = GetInstanceByID(tonumber(tModifierData.Source))
	local hCaster = GetInstanceByID(tonumber(tModifierData.Caster)) or hEntity
	local hModifier = nil
	if hSource then
		local hModifier = hEntity:AddNewModifier(hCaster, hSource, szModifierName, tModifierData.ModifierArgs)
		local nStackCount = tModifierData.StackCount or 0
		if nStackCount > 0 then
			hModifier:SetStackCount(nStackCount)
		end
		CDOTA_Buff.SetDuration(hModifier, tModifierData.Duration, true)
		for k,v in pairs(tModifierData.Properties or {}) do
			hModifier:SetPropertyValue(k,v)
		end
	end
end

local function LoadEntityPositions(hEntity)
	local tEntitySaveList = CSaveManager._tSaveData.Entities or {}
	if IsValidExtendedEntity(hEntity) then
		local nInstanceID = hEntity:GetInstanceID()
		local tEntityData = tEntitySaveList[tostring(nInstanceID)]
		local tInstanceData = CSaveManager._tInstanceData[tostring(nInstanceID)]
		if tEntityData and tEntityData.State == IW_SAVE_STATE_PERSISTENT then
			if tEntityData.Health > 0 and tEntityData.LastMap ~= GetMapName() then
				local hDefaultSpawn = Entities:FindByName(nil, "spawnloc_" .. CSaveManager._tSaveData.CurrentMap)
				if not hDefaultSpawn then hDefaultSpawn = Entities:FindByName(nil, "spawnloc_" .. nInstanceID) end
				if not hDefaultSpawn then hDefaultSpawn = Entities:FindByName(nil, "spawnloc_default") end
				if not hDefaultSpawn then LogMessage("No default spawn location present on map!", LOG_SEVERITY_WARNING) end
				if hDefaultSpawn then
					FindClearSpaceForUnit(hEntity, hDefaultSpawn:GetAbsOrigin(), false)
					hEntity:SetForwardVector(hDefaultSpawn:GetForwardVector())
				end
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
				if vPosition.z == 0 then
					vPosition = GetGroundPosition(vPosition, hEntity)
				end
				hEntity:SetAbsOrigin(vPosition)
				hEntity:SetForwardVector(StringToVector(tInstanceData.Forward))
				if IsValidExtendedEntity(hEntity) then
					hEntity._vInitialPos = vPosition
					hEntity._nLastWaypoint = tInstanceData.LastWaypoint or 0
					hEntity._nNextWaypoint = tInstanceData.NextWaypoint or 0
				end
			end
		end
	end
end

local function LoadEntityValues(hEntity)
	local tEntitySaveList = CSaveManager._tSaveData.Entities or {}
	if IsValidExtendedEntity(hEntity) then
		local nInstanceID = hEntity:GetInstanceID()
		local tEntityData = tEntitySaveList[tostring(nInstanceID)]
		if tEntityData then
			if tEntityData.Health == 0 then
				hEntity:ForceKill(false)
			else
				hEntity:SetHealth(tEntityData.Health)
			end
			hEntity:SetMana(tEntityData.Mana)
			hEntity:SetStamina(tEntityData.Stamina)
			hEntity._fStaminaRegenTime = GameRules:GetGameTime() + tEntityData.StaminaTime
			
			if hEntity:IsRealHero() then
				if tEntityData.RunMode == 1 then
					hEntity:SetRunMode(true)
				end
				if tEntityData.HoldMode == 1 then
					hEntity:SetHoldPosition(true)
				end
				CDOTA_BaseNPC_Hero.AddExperience(hEntity, tEntityData.Experience, DOTA_ModifyXP_Unspecified, false, true)
				hEntity._fTotalXP = tEntityData.Experience
				hEntity._fLevelXP = hEntity._fTotalXP - GameRules.XPTable[hEntity:GetLevel()]
			end
			
			if IsValidExtendedEntity(hEntity) then
				hEntity._vInitialPos = StringToVector(tEntityData.InitialPos)
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
					local tNoiseTable = hEntity._tNoiseTable
					tNoiseTable[k] = v
				end
				hEntity._nLastWaypoint = tEntityData.LastWaypoint
				hEntity._nNextWaypoint = tEntityData.NextWaypoint
			end
		end
	end
end

local function LoadEntityPositionsAndValues()
	local hEntity = Entities:First()
	while hEntity do
		LoadEntityPositions(hEntity)
		LoadEntityValues(hEntity)
		hEntity = Entities:Next(hEntity)
	end	
end

local function LoadMapContainers()
	local tInteractableSaveList = CSaveManager._tSaveData.Interactables or {}
	for k,v in pairs(CSaveManager._tInstanceData) do
		local nInstanceID = tonumber(k)
		local hPrecondition = LoadFunctionSnippet(v.Precondition)
		if stInstanceData[k] and stInstanceData[k].Type == IW_INSTANCE_CONTAINER and (not hPrecondition or hPrecondition()) then
			local tContainerData = tInteractableSaveList[k]
			if not tContainerData then
				local szUnitName = stInstanceData[k].Name
				local nFactionID = stInstanceData[k].FactionID
				local vForward = StringToVector(v.Forward)
				local vPosition = StringToVector(v.Position)
				if vPosition.z == 0 then
					vPosition = GetGroundPosition(vPosition, hEntity)
				end
				local hContainer = CContainer(CreateUnitByName(szUnitName, vPosition, false, nil, nil, DOTA_TEAM_GOODGUYS), nInstanceID)
				hContainer:SetFactionID(stInstanceData.FactionID)
				hContainer:SetAbsOrigin(vPosition)
				hContainer:SetForwardVector(vForward)
				hContainer:GenerateItemList()
			end
		end
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
	
	for k,v in pairs(tEntitySaveList) do
		local nInstanceID = tonumber(k)
		local nInstanceState = v.State
		if nInstanceState == 2 or (nInstanceState == 1 and bIsCurrentMap) then
			local hInstance = GetInstanceByID(nInstanceID)
			for k2,v2 in pairs(v.Modifiers or {}) do
				LoadSavedModifierData(hInstance, v2, tonumber(k2))
			end
		end
	end
end

local function RefreshAllEntities()
	for _,hInstance in pairs(CInstance:GetInstanceList()) do
		if IsValidExtendedEntity(hInstance) then
			hInstance:RefreshEntity()
		end
	end
end

function CSaveManager:LoadGame()
	--TODO: Save and load party formation
	--CInstance:SetAllowDynamicInstances(false)
	LoadGlobalData()
	LoadGameStates()
	LoadStaticEntities()
	LoadDynamicEntities()
	LoadStaticInteractables()
	LoadDynamicInteractables()
	LoadPhysicalItems()
	LoadAbilities()
	LoadParty()
	LoadEntityPositionsAndValues()
	LoadMapContainers()
	LoadModifiers()
	RefreshAllEntities()
	--CInstance:SetAllowDynamicInstances(true)
end

--This is an annoying workaround but we have to do it since the player hero isn't loaded until much, much later...
function CSaveManager:LoadPlayerHero(hEntity, nPlayerID)
	if hEntity:GetUnitName() == CSaveManager:GetPlayerHeroName() and hEntity:IsRealHero() then
		local nInstanceID = GameRules:GetGameState("game.hero_selection")
		hEntity = CExtHero(hEntity, nInstanceID)
		hEntity:SetFactionID(1)
		
		local tEntitySaveList = CSaveManager._tSaveData.Entities or {}
		local tEntityData = tEntitySaveList[tostring(nInstanceID)]
		local tSpellbookData = tEntity
		if tEntityData then
			LoadEntityData(hEntity, tEntityData)
			LoadAbilitiesForEntity(hEntity, tEntityData.Spellbook)
		end
		
		for k,v in pairs(tEntitySaveList) do
			local nInstanceID = tonumber(k)
			local nInstanceState = v.State
			if nInstanceState == 2 or (nInstanceState == 1 and bIsCurrentMap) then
				local hInstance = GetInstanceByID(nInstanceID)
				if IsValidExtendedEntity(hInstance) then
					for k2,v2 in pairs(v.Modifiers or {}) do
						if tonumber(v2.Caster) == nInstanceID then
							LoadSavedModifierData(hInstance, v2, tonumber(k2))
						end
					end
				end
			end
		end
		
		CParty:AddToParty(hEntity, nPlayerID + 1)
		local tAAMData = CSaveManager._tSaveData.Party.AAM
		if tAAMData then
			LoadAAMData(hEntity, tAAMData[tostring(nInstanceID)])
		end
		GameRules.GetPlayerHero = function() return hEntity end
		
		--Because for some reason the position gets overwritten immediately after spawning the entity...
		CTimer(0.03, function()
			LoadEntityPositions(hEntity)
			LoadEntityValues(hEntity)
		end)
	end	
end

ListenToGameEvent("iw_save_game", Dynamic_Wrap(CSaveManager, "OnSaveGame"), CSaveManager)
ListenToGameEvent("iw_map_transition", Dynamic_Wrap(CSaveManager, "OnMapTransition"), CSaveManager)

end