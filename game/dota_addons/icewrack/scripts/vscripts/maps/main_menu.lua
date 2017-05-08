if CIcewrackMainMenu == nil then
	CIcewrackMainMenu = class({})
end

function Precache(context)
end


function Activate()
	CIcewrackMainMenu:InitMap()
end

function CIcewrackMainMenu:OnGameRulesStateChange(keys)
	local nGameState = GameRules:State_Get()
	if nGameState == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
		Convars:SetFloat("dota_time_of_day_rate", 0.0)
		GameRules:SetTimeOfDay(0.8)
	end
end

function CIcewrackMainMenu:InitMap()
    ListenToGameEvent("game_rules_state_change", Dynamic_Wrap(CIcewrackMainMenu, "OnGameRulesStateChange"), self)
end