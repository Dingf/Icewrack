--[[
	Map 103 - Abandoned Cave
]]

require("maps/transition")
require("mechanics/effect_wet")

if CIcewrackMap1_03 == nil then
	CIcewrackMap1_03 = class({})
end

function Precache(context)
end

function Activate()
	CIcewrackMap1_03:InitMap()
end

function CIcewrackMap1_03:InitMap()
    ListenToGameEvent("game_rules_state_change", Dynamic_Wrap(CIcewrackMap1_03, "OnGameRulesStateChange"), self)
end

function CIcewrackMap1_03:OnGameRulesStateChange(keys)
	local nGameState = GameRules:State_Get()
	if nGameState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		--Give vision to the cave entrance if we came in from there
		local hTrigger = Entities:FindByName(nil, "entrance_vision_trigger")
		if IsInstanceOf(hTrigger, CBaseTrigger) and hTrigger:IsTouching(GameRules:GetPlayerHero()) then
			AddFOWViewer(DOTA_TEAM_GOODGUYS, Vector(-1536, -2976, 2240), 1200, 0.03, true)
		end
	end
end