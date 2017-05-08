--[[
	Map 101 - Expedition Base Camp
]]

require("maps/transition")
require("game_states")

if CIcewrackMap1_01 == nil then
	CIcewrackMap1_01 = class({})
end

function Precache(context)
	PrecacheResource("particle", "particles/rain_fx/econ_snow_heavy.vpcf", context)
end

function Activate()
	CIcewrackMap1_01:InitMap()
end

function CIcewrackMap1_01:InitMap()
    ListenToGameEvent("game_rules_state_change", Dynamic_Wrap(CIcewrackMap1_01, "OnGameRulesStateChange"), self)
end

function CIcewrackMap1_01:OnGameRulesStateChange(keys)
	local nGameState = GameRules:State_Get()
	if nGameState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		local hCampDummy = CreateDummyUnit(Vector(0, 0, 0), nil, DOTA_TEAM_GOODGUYS)
		hCampDummy:SetAbsOrigin(Vector(192, -720, 568))
		hCampDummy:SetDayTimeVisionRange(4000)
		hCampDummy:SetNightTimeVisionRange(4000)
		if hCampDummy and IsValidEntity(hCampDummy) then
			ParticleManager:CreateParticle("particles/rain_fx/econ_snow_heavy.vpcf", PATTACH_EYES_FOLLOW, hCampDummy)
		end
		
		local hTrigger = Entities:FindByName(nil, "herotent" .. CGameState:GetGameStateValue("game.hero_selection") .. "_trigger3")
		if hTrigger then
			hTrigger:FireOutput("OnKilled", hEntity, hTrigger, nil, 0.0)
			hTrigger:Destroy()
		end
	end
end

--function CIcewrackMap1_01:OnPlayerHeroLoaded(keys)
--end


