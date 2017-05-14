if CIcewrackGameMode == nil then
	_G.CIcewrackGameMode = class({})
	
end

require("map_info")
require("bind_manager")
require("save_manager")

function Precache(context)
	local tPrecacheList = CSaveManager:GetPrecacheList()
	for k,_ in pairs(tPrecacheList) do
		PrecacheUnitByNameSync(k, context)
	end
	PrecacheResource("soundfile", "soundevents/game_sounds_main.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_ambient.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_ui.vsndevts", context)
end

function Activate()
	require("addon_events")
	CIcewrackGameMode:InitGameMode()
end

function CIcewrackGameMode:InitGameMode()
	LogMessage("Loading Icewrack mod...")
	
    GameRules.SharedUnitList = {}
	GameRules.OverridePauseLevel = 0
	GameRules.PauseState = false
	
    Convars:SetInt("dota_hud_healthbars", 0)
    Convars:SetInt("dota_combine_models", 0)
	
	--Set day cycle to 1 hour instead of 8 
	Convars:SetFloat("dota_time_of_day_rate", 0.000278)
	Convars:SetFloat("fow_tile_update_time", 0.03)
	Convars:SetInt("dota_camera_mousewheel_delay_reset_interval", 0)
	Convars:SetInt("dota_allow_orders_while_paused", 1)
	Convars:SetInt("dota_allow_invalid_orders", 1)
	Convars:SetInt("dota_pause_game_pause_silently", 1)
	
	local tBindData = CSaveManager:GetBindsForCurrentPlayer()
	CBindManager:RegisterDefaultBinds(tBindData)
	
	local hGameModeEntity = GameRules:GetGameModeEntity()
	local tXPValuesTable = {}
	local tXPValuesData = LoadKeyValues("scripts/npc/iw_xp_list.txt")
	local nMaxLevel = 1
	for k,v in pairs(tXPValuesData) do
		local nLevel = tonumber(k)
		if nLevel then
			tXPValuesTable[nLevel] = v
			if nLevel > nMaxLevel then
				nMaxLevel = nLevel
			end
		end
	end
    hGameModeEntity:SetCustomXPRequiredToReachNextLevel(tXPValuesTable)
	tXPValuesTable.max_level = nMaxLevel
	GameRules.XPTable = tXPValuesTable
	CustomNetTables:SetTableValue("game", "xp", tXPValuesTable)
	
	if not GameRules:GetMapInfo():IsRevealed() then
		hGameModeEntity:SetUnseenFogOfWarEnabled(true)
	end
    hGameModeEntity:SetUseCustomHeroLevels(true)
	hGameModeEntity:SetAnnouncerDisabled(true)
    hGameModeEntity:SetBuybackEnabled(false)
	
	hGameModeEntity:SetExecuteOrderFilter(Dynamic_Wrap(CIcewrackGameMode, "ExecuteOrderFilter"), self)
	hGameModeEntity:SetItemAddedToInventoryFilter(Dynamic_Wrap(CIcewrackGameMode, "ItemAddedToInventoryFilter"), self)
	hGameModeEntity:SetModifyExperienceFilter(Dynamic_Wrap(CIcewrackGameMode, "ModifyExperienceFilter"), self)
	
    GameRules:SetGoldTickTime(60.0)
    GameRules:SetGoldPerTick(0)
    GameRules:SetPreGameTime(0.0)
    GameRules:SetHeroRespawnEnabled(false)
	
	ListenToGameEvent("iw_quit", Dynamic_Wrap(CIcewrackGameMode, "OnQuit"), self)
	ListenToGameEvent("iw_party_select", Dynamic_Wrap(CIcewrackGameMode, "OnPartySelect"), self)
	ListenToGameEvent("iw_change_level", Dynamic_Wrap(CIcewrackGameMode, "OnChangeLevel"), self)
	ListenToGameEvent("entity_killed", Dynamic_Wrap(CIcewrackGameMode, "OnEntityKilled"), self)
    ListenToGameEvent("npc_spawned", Dynamic_Wrap(CIcewrackGameMode, "OnEntitySpawned"), self)
    ListenToGameEvent("game_rules_state_change", Dynamic_Wrap(CIcewrackGameMode, "OnGameRulesStateChange"), self)

	CustomGameEventManager:RegisterListener("iw_quit", Dynamic_Wrap(CIcewrackGameMode, "OnQuit"))
	CustomGameEventManager:RegisterListener("iw_pause", Dynamic_Wrap(CIcewrackGameMode, "OnPause"))
	CustomGameEventManager:RegisterListener("iw_unpause", Dynamic_Wrap(CIcewrackGameMode, "OnUnpause"))
	CustomGameEventManager:RegisterListener("iw_change_level", Dynamic_Wrap(CIcewrackGameMode, "OnChangeLevel"))
	CustomGameEventManager:RegisterListener("iw_party_select", Dynamic_Wrap(CIcewrackGameMode, "OnPartySelect"))
	
	LogMessage("Icewrack mod loaded.")
end