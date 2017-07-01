--[[
	Map 0 (Character select screen)
]]

require("ext_entity")
require("game_states")

local stHeroAxeResponseLines =
{
	"axe_axe_firstblood_02",
	"axe_axe_respawn_06",
	"axe_axe_rare_02",
	"axe_axe_rare_03",
	"axe_axe_battlebegins_01",
	"axe_axe_spawn_02",
}

local stHeroDavionResponseLines =
{
	"dragon_knight_drag_spawn_02",
	"dragon_knight_drag_spawn_04",
	"dragon_knight_drag_ability_eldrag_06",
	"dragon_knight_drag_respawn_04",
	"dragon_knight_drag_rare_02",
	"dragon_knight_drag_rare_03",
}

local stHeroDrowResponseLines =
{
	"drowranger_drow_battlebegins_01",
	"drowranger_dro_spawn_04",
	"drowranger_dro_cast_02",
	"drowranger_dro_rare_01",
	"drowranger_dro_rare_02",
}

local stHeroBountyResponseLines =
{
	"bounty_hunter_bount_spawn_03",
	"bounty_hunter_bount_spawn_04",
	"bounty_hunter_bount_move_06",
	"bounty_hunter_bount_attack_13",
	"bounty_hunter_bount_cast_03",
}

local stHeroLinaResponseLines =
{
	"lina_lina_battlebegins_01",
	"lina_lina_spawn_08",
	"lina_lina_spawn_09",
	"lina_lina_respawn_08",
	"lina_lina_rare_02",
	"lina_lina_rare_04",
}

local stHeroOmniResponseLines =
{
	"omniknight_omni_spawn_04",
	"omniknight_omni_move_11",
	"omniknight_omni_ability_guard_03",
	"omniknight_omni_ability_guard_07",
	"omniknight_omni_kill_03",
	"omniknight_omni_respawn_10",
}

local stHeroResponseTable =
{
	npc_dota_hero_axe           = stHeroAxeResponseLines,
	npc_dota_hero_dragon_knight = stHeroDavionResponseLines,
	npc_dota_hero_drow_ranger   = stHeroDrowResponseLines,
	npc_dota_hero_bounty_hunter = stHeroBountyResponseLines,
	npc_dota_hero_lina          = stHeroLinaResponseLines,
	npc_dota_hero_omniknight    = stHeroOmniResponseLines,
}

--Prevents characters from spending stamina while running back and forth in the pick screen
local shItemStaminaBuffModifier = CreateItem("map000_stamina_buff", nil, nil)

if CIcewrack_Map0_00 == nil then
	CIcewrack_Map0_00 = class({})
end

function Precache(context)
	PrecacheResource("particle", "particles/rain_fx/econ_snow_light.vpcf", context)
end

function Activate()
	CIcewrack_Map0_00:InitMap()
end

function CIcewrack_Map0_00:OnCharacterSelectExamine(keys)
	if keys.entindex == -1 and CIcewrack_Map0_00._hSelectedCharacter then
		local szLastSoundName = CIcewrack_Map0_00._szLastSoundName
		if szLastSoundName then
			StopSoundOn(szLastSoundName, CIcewrack_Map0_00._hSelectedCharacter)
		end
		CIcewrack_Map0_00._hSelectedCharacter:Stop()
		CIcewrack_Map0_00._hSelectedCharacter:RemoveModifierByName("modifier_internal_animation")
		CIcewrack_Map0_00._hSelectedCharacter:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, nil, CIcewrack_Map0_00._hSelectedCharacter._vReturnPosition, false)
		CIcewrack_Map0_00._hSelectedCharacter:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, nil, CIcewrack_Map0_00._hSelectedCharacter._vOriginalPosition, true)
		CIcewrack_Map0_00._hSelectedCharacter = nil
	else
		local hEntity = EntIndexToHScript(keys.entindex)
		if hEntity then
			if CIcewrack_Map0_00._hSelectedCharacter then
				local szLastSoundName = CIcewrack_Map0_00._szLastSoundName
				if szLastSoundName then
					StopSoundOn(szLastSoundName, CIcewrack_Map0_00._hSelectedCharacter)
				end
				CIcewrack_Map0_00._hSelectedCharacter:Stop()
				CIcewrack_Map0_00._hSelectedCharacter:RemoveModifierByName("modifier_internal_animation")
				CIcewrack_Map0_00._hSelectedCharacter:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, nil, CIcewrack_Map0_00._hSelectedCharacter._vReturnPosition, false)
				CIcewrack_Map0_00._hSelectedCharacter:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, nil, CIcewrack_Map0_00._hSelectedCharacter._vOriginalPosition, true)
			end
			hEntity:Stop()
			hEntity:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, nil, Vector(64, -480, 128), false)
			if hEntity:GetUnitName() == "npc_dota_hero_axe" then
				hEntity:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, nil, Vector(70, -496, 128), true)
			else
				hEntity:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, nil, Vector(64, -496, 128), true)
			end
			hEntity:IssueOrder(DOTA_UNIT_ORDER_TAUNT, nil, nil, Vector(64, -448, 128), true)
			CIcewrack_Map0_00._hSelectedCharacter = hEntity
		end
	end
end

function CIcewrack_Map0_00:OnCharacterSelectStage(keys)
	PlayerResource:SetCameraTarget(0, CIcewrack_Map0_00._tLookTargets[keys.stage])
end

function CIcewrack_Map0_00:OnCharacterSelectStart(keys)
	local hEntity = EntIndexToHScript(keys.entindex)
	if hEntity and keys.difficulty then
		GameRules:SetCustomGameDifficulty(keys.difficulty)
		CGameState:SetGameStateValue("game.hero_selection", hEntity:GetInstanceID())
		CParty:AddToParty(hEntity)
		hEntity:SetControllableByPlayer(0, true)
		hEntity:GetInventory():SetGoldAmount(CGameState:GetGameStateValue("game.start_gold_" .. keys.difficulty))
		FireGameEventLocal("iw_map_transition", { map = "map101" })
	end
end

function CIcewrack_Map0_00:ExecuteOrderFilter(keys)
	local nOrderType = keys.order_type
	local hTarget = EntIndexToHScript(keys.entindex_target)
	local hAbility = keys.entindex_ability ~= -1 and EntIndexToHScript(keys.entindex_ability) or nil
	local vPosition = Vector(keys.position_x, keys.position_y, keys.position_z)
	
	for k,v in pairs(keys.units) do
		local hUnit = EntIndexToHScript(v)
		if nOrderType == DOTA_UNIT_ORDER_TAUNT and keys.queue == 0 then
			local szUnitName = hUnit:GetUnitName()
			if szUnitName == "npc_dota_hero_axe" then
				AddModifier("internal_animation", "modifier_internal_animation", hUnit, hUnit, { animation=ACT_DOTA_TAUNT, rate=1.0, weight=1.0, duration=10.8, translate="come_get_it" })
			elseif szUnitName == "npc_dota_hero_dragon_knight" then
				AddModifier("internal_animation", "modifier_internal_animation", hUnit, hUnit, { animation=ACT_DOTA_VICTORY, rate=1.0, weight=1.0, duration=2.6 })
			elseif szUnitName == "npc_dota_hero_drow_ranger" then
				AddModifier("internal_animation", "modifier_internal_animation", hUnit, hUnit, { animation=ACT_DOTA_ATTACK, rate=1.0, weight=1.0, duration=1.56, translate="frost_arrow" })
			elseif szUnitName == "npc_dota_hero_bounty_hunter" then
				AddModifier("internal_animation", "modifier_internal_animation", hUnit, hUnit, { animation=ACT_DOTA_IDLE_RARE, rate=1.0, weight=1.0, duration=2.67, translate="twinblade_idle_rare" })
			elseif szUnitName == "npc_dota_hero_lina" then
				AddModifier("internal_animation", "modifier_internal_animation", hUnit, hUnit, { animation=ACT_DOTA_VICTORY, rate=1.0, weight=1.0, duration=3.5 })
			elseif szUnitName == "npc_dota_hero_omniknight" then
				AddModifier("internal_animation", "modifier_internal_animation", hUnit, hUnit, { animation=ACT_DOTA_CAST_ABILITY_4, rate=0.6, weight=1.0, duration=3 })
			end
			local tResponseTable = stHeroResponseTable[szUnitName]
			if tResponseTable then
				local szResponseName = tResponseTable[RandomInt(1, #tResponseTable)]
				EmitSoundOn(szResponseName, hUnit)
				CIcewrack_Map0_00._szLastSoundName = szResponseName
			end
			return true
		end
	end
	return true
end

function CIcewrack_Map0_00:OnGameRulesStateChange(keys)
	local nGameState = GameRules:State_Get()
	if nGameState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		Convars:SetFloat("dota_time_of_day_rate", 0.0)
		
		local hEntity = Entities:First()
		while hEntity do
			if IsValidExtendedEntity(hEntity) and hEntity:IsHero() then
				hEntity._vOriginalPosition = hEntity:GetAbsOrigin()
				hEntity._vReturnPosition = hEntity:GetAbsOrigin() - (hEntity:GetForwardVector() * 32.0)
				hEntity:AddNewModifier(hEntity, shItemStaminaBuffModifier, "modifier_map000_stamina_buff", {})
				
				local hSpellbook = hEntity:GetSpellbook()
				if hSpellbook then
					for i = 0,hEntity:GetAbilityCount()-1 do
						local hAbility = hEntity:GetAbilityByIndex(i)
						if hAbility then
							local hSpellbookAbility = hSpellbook:LearnAbility(hAbility:GetAbilityName(), 1)
							if hSpellbookAbility then
								FireGameEventLocal("iw_actionbar_bind", { slot = i + 1, entindex = hEntity:entindex(), ability = hSpellbookAbility:entindex() });
								hEntity:RemoveAbility(hAbility:GetAbilityName())
							end
						end
					end
				end
				hEntity:SetDayTimeVisionRange(0.0)
				hEntity:SetNightTimeVisionRange(0.0)
				hEntity:Hold()
			end
			hEntity = Entities:Next(hEntity)
		end
	
		local hGameModeEntity = GameRules:GetGameModeEntity()
		hGameModeEntity:SetExecuteOrderFilter(Dynamic_Wrap(CIcewrack_Map0_00, "ExecuteOrderFilter"), self)
		
		
		local hCharacterSelectDummy = CreateDummyUnit(Vector(64, 288, 0), nil, DOTA_TEAM_GOODGUYS)
		local hDifficultyDummy = CreateDummyUnit(Vector(-224, -3400, 0), nil, DOTA_TEAM_GOODGUYS)
		
		GameRules:GetPlayerHero():SetDayTimeVisionRange(200.0)
		GameRules:GetPlayerHero():SetNightTimeVisionRange(200.0)
		
		local nParticleID = ParticleManager:CreateParticle("particles/rain_fx/econ_snow_light.vpcf", PATTACH_EYES_FOLLOW, hCharacterSelectDummy)
		ParticleManager:ReleaseParticleIndex(nParticleID)
		PlayerResource:SetCameraTarget(0, hCharacterSelectDummy)
		
		CIcewrack_Map0_00._tLookTargets = { hCharacterSelectDummy, hDifficultyDummy }
		EmitGlobalSound("Ambient.IcyWinds")
	end
end


function CIcewrack_Map0_00:InitMap()
    ListenToGameEvent("game_rules_state_change", Dynamic_Wrap(CIcewrack_Map0_00, "OnGameRulesStateChange"), self)
	CustomGameEventManager:RegisterListener("iw_character_select_examine", Dynamic_Wrap(CIcewrack_Map0_00, "OnCharacterSelectExamine"))
	CustomGameEventManager:RegisterListener("iw_character_select_stage", Dynamic_Wrap(CIcewrack_Map0_00, "OnCharacterSelectStage"))
	CustomGameEventManager:RegisterListener("iw_character_select_start", Dynamic_Wrap(CIcewrack_Map0_00, "OnCharacterSelectStart"))
end
