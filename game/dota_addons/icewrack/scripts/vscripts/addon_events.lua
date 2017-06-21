if _VERSION < "Lua 5.2" then
    bit = require("lib/numberlua")
    bit32 = bit.bit32
end

require("mechanics/effect_shatter")
require("mechanics/combat")
require("timer")
require("map_info")
require("ext_ability")
require("ext_item")
require("ext_entity")
require("ext_modifier")
require("party")
require("interactable")
require("inventory")

--TODO: Remove the trace() statements from the SFS

function CIcewrackGameMode:OnEntitySpawned(keys)
    local hEntity = EntIndexToHScript(keys.entindex)
	if hEntity:GetUnitName() == "npc_dota_hero_base" then
		hEntity:AddAbility("internal_dummy_buff")
		hEntity:FindAbilityByName("internal_dummy_buff"):ApplyDataDrivenModifier(hEntity, hEntity, "modifier_internal_dummy_buff", {})
		hEntity:RemoveAbility("internal_dummy_buff")
		hEntity:SetDayTimeVisionRange(0.0)
		hEntity:SetNightTimeVisionRange(0.0)
		hEntity:SetBaseMoveSpeed(0)
		hEntity:AddEffects(EF_NODRAW)
	end
	
	--TODO: Testing code; Delete me
	if hEntity:GetUnitName() == "npc_dota_hero_windrunner" then
		hEntity:SetControllableByPlayer(0, true)
		FireGameEvent("iw_ability_combo", { name="iw_combo_shatter" })
		CTimer(3.0, function() 
		CParty:AddToParty(hEntity) end)
	end
	--[[if hEntity:GetUnitName() == "npc_dota_hero_dragon_knight" then
		hEntity:SetControllableByPlayer(0, true)
		CTimer(3.0, function() 
		CParty:AddToParty(hEntity) end)
	end]]
end

function CIcewrackGameMode:OnEntityKilled(keys)
    local hEntity = EntIndexToHScript(keys.entindex_killed)
	if IsValidExtendedEntity(hEntity) then
		if bit32.band(hEntity:GetUnitFlags(), IW_UNIT_FLAG_NO_CORPSE) == 0 and not TriggerShatter(hEntity) then
			--TODO: Make it so that on lower difficulties, player heroes can be revived
			--TODO: Make it so that on higher difficulties, the game ends when the player hero dies
			if hEntity == GameRules:GetPlayerHero() and GameRules:GetCustomGameDifficulty() >= IW_DIFFICULTY_HARD then
			else
				local nDeathFrames = hEntity:GetPropertyValue(IW_PROPERTY_CORPSE_TIME)
				local fDeathTime = (nDeathFrames - 1)/30.0
				CTimer(fDeathTime, CExtEntity.CreateCorpse, hEntity);
			end
		end
	end
end

function CIcewrackGameMode:OnGameRulesStateChange(keys)
	local nGameState = GameRules:State_Get()
	if nGameState == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
		PlayerResource:SetCustomTeamAssignment(0, DOTA_TEAM_GOODGUYS)
		GameRules:GetGameModeEntity():SetCustomGameForceHero("npc_dota_hero_base")
		Tutorial:SelectHero("npc_dota_hero_base")	--A bit of a hack that lets us bypass the hero selection screen while still picking a hero
		local szHeroName = CSaveManager:GetPlayerHeroName() or "npc_dota_hero_base"
		local hPlayerHero = CreateHeroForPlayer(szHeroName, PlayerResource:GetPlayer(0))
		GameRules.GetPlayerHero = function() return hPlayerHero end
		CSaveManager:LoadGame()
		GameRules:FinishCustomGameSetup()
	elseif nGameState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		CSaveManager._tSaveSpecial.Loading = nil
		CSaveManager:CreateSaveList(self, keys)
		CSaveManager:CreateBindList(self, keys)
		
		if CSaveManager:GetPlayerHeroName() then
			CTimer(0.03, function() GameRules:GetPlayerHero():AddExperience(100) return 0.03 end)
		end
	end
end

local function OnMoveToPosition(hEntity, vPosition)
	return true
end

local function OnInteractableActivate(hEntity, hTarget)
	local hBestEntity = nil
	local fBestDistance = 0.0
	if next(GameRules.SharedUnitList) then
		for k,v in pairs(GameRules.SharedUnitList) do
			local hSelectedEntity = EntIndexToHScript(v)
			if hTarget:OnInteractFilter(hSelectedEntity) then
				local fDistance = hSelectedEntity:GetRangeToUnit(hTarget) - hTarget:GetHullRadius() - hSelectedEntity:GetHullRadius()
				if not hBestEntity or fDistance < fBestDistance then
					hBestEntity = hSelectedEntity
					fBestDistance = fDistance
				end
			end
		end
	elseif hTarget:OnInteractFilter(hEntity) then
		hBestEntity = hEntity
	end
	
	if hEntity == hBestEntity then
		if hTarget:IsInInteractRange(hEntity) then
			hEntity:Stop()
			local vPosition = hEntity:GetAbsOrigin()
			hEntity:SetAbsOrigin(vPosition + (vPosition - hTarget:GetAbsOrigin()):Normalized())
			hEntity:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, nil, vPosition, false)
			
			if not hTarget:OnInteract(hEntity) then
				local szErrorMessage = hTarget:OnGetCustomInteractError(hEntity)
				if szErrorMessage then
					--TODO: Implement the error message here
				end
			end
			return IW_INTERACTABLE_RESULT_SUCCESS
		else
			CTimer(0.03, CExtEntity.IssueOrder, hEntity, DOTA_UNIT_ORDER_MOVE_TO_TARGET, hTarget, nil, nil, false, true)
			return IW_INTERACTABLE_RESULT_EN_ROUTE
		end
	end
	return IW_INTERACTABLE_RESULT_FAIL
end

local function OnMoveToTarget(hEntity, hTarget)
	if IsValidInteractable(hTarget) and OnInteractableActivate(hEntity, hTarget) ~= IW_INTERACTABLE_RESULT_FAIL then
		return true
	end
	return true
end

local function OnAttackTargetVisionThink(hEntity, hTarget, nOrderID)
	if hEntity:GetLastOrderID() == nOrderID then
		local fAttackRange = hEntity:GetAttackRange()
		local fDistance = (hEntity:GetAbsOrigin() - hTarget:GetAbsOrigin()):Length2D()
		if hEntity:IsTargetInLOS(hTarget) and hEntity:CanEntityBeSeenByMyTeam(hTarget) and fDistance <= fAttackRange then
			hEntity:Stop()
			hEntity:IssueOrder(DOTA_UNIT_ORDER_ATTACK_TARGET, hTarget, nil, nil, false)
		else
			CTimer(0.03, OnAttackTargetVisionThink, hEntity, hTarget, nOrderID)
		end
	end
end

local function OnAttackTargetCostThink(hEntity, hTarget, nOrderID)
	if hEntity:GetLastOrderID() == nOrderID then
		if hEntity:CanPayAttackCosts() then
			hEntity:SetIdleAcquire(true)
			hEntity:IssueOrder(DOTA_UNIT_ORDER_ATTACK_TARGET, hTarget, nil, nil, false)
		else
			hEntity:SetIdleAcquire(false)
			CTimer(0.03, OnAttackTargetCostThink, hEntity, hTarget, nOrderID)
		end
	end
end

local function OnAttackTarget(hEntity, hTarget)
	if IsValidExtendedEntity(hEntity) then 
		if IsValidInteractable(hTarget) then
			local nResult = OnInteractableActivate(hEntity, hTarget)
			if nResult == IW_INTERACTABLE_RESULT_EN_ROUTE then
				hEntity:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_TARGET, hTarget, nil, nil, false)
				return false
			elseif nResult == IW_INTERACTABLE_RESULT_SUCCESS then
				return false
			end
		end
		
		if hEntity:GetOrbAttackSource() then
			hEntity:OnOrbPreAttack()
		end
		
		if not hEntity:IsTargetInLOS(hTarget) and hEntity:CanEntityBeSeenByMyTeam(hTarget) then
			hEntity:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_TARGET, hTarget, nil, nil, false)
			CTimer(0.03, OnAttackTargetVisionThink, hEntity, hTarget, hEntity:GetLastOrderID())
			return false
		end
		if not hEntity:CanPayAttackCosts() then
			CTimer(0.03, OnAttackTargetCostThink, hEntity, hTarget, hEntity:GetLastOrderID())
			return false
		end
		
		if hEntity:GetOrbAttackSource() then
			hEntity:OnOrbPostAttack()
		end
	end
	return true
end

local function OnCastPositionVisionThink(hAbility, hEntity, vPosition, nOrderID)
	if hEntity:GetLastOrderID() == nOrderID then
		local fCastRange = hAbility:GetCastRange()
		local fDistance = (hEntity:GetAbsOrigin() - vPosition):Length2D()
		if hEntity:IsTargetInLOS(vPosition) and fDistance <= fCastRange then
			hEntity:Stop()
			hEntity:IssueOrder(DOTA_UNIT_ORDER_CAST_POSITION, nil, hAbility, vPosition, false)
		else
			CTimer(0.03, OnCastPositionVisionThink, hAbility, hEntity, vPosition, nOrderID)
		end
	end
end

local function OnCastPosition(hEntity, hAbility, vPosition)
	if IsValidExtendedAbility(hAbility) then
		if not bit32.btest(hAbility:GetAbilityFlags(), IW_ABILITY_FLAG_DOES_NOT_REQ_VISION) and vPosition then
			local fCastRange = hAbility:GetCastRange()
			local fDistance = (hEntity:GetAbsOrigin() - vPosition):Length2D()
			if not hEntity:IsTargetInLOS(vPosition) or fDistance > fCastRange then
				hEntity:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, nil, vPosition, false)
				CTimer(0.03, OnCastPositionVisionThink, hAbility, hEntity, vPosition, hEntity:GetLastOrderID())
				return false
			end
		end
	end
	return true
end

local function OnCastTargetVisionThink(hAbility, hEntity, hTarget, nOrderID)
	if hEntity:GetLastOrderID() == nOrderID then
		local fCastRange = hAbility:GetCastRange()
		local fDistance = (hEntity:GetAbsOrigin() - hTarget:GetAbsOrigin()):Length2D()
		if hEntity:IsTargetInLOS(hTarget) and fDistance <= fCastRange then
			hEntity:Stop()
			hEntity:IssueOrder(DOTA_UNIT_ORDER_CAST_TARGET, hTarget, hAbility, nil, false)
		else
			CTimer(0.03, OnCastTargetVisionThink, hAbility, hEntity, hTarget, nOrderID)
		end
	end
end

local function OnCastTarget(hEntity, hAbility, hTarget)
	if IsValidExtendedAbility(hAbility) then
		local fCastRange = hAbility:GetCastRange()
		local fDistance = (hEntity:GetAbsOrigin() - hTarget:GetAbsOrigin()):Length2D()
		if not bit32.btest(hAbility:GetAbilityFlags(), IW_ABILITY_FLAG_DOES_NOT_REQ_VISION) and hTarget then
			if not hEntity:IsTargetInLOS(hTarget) or fDistance > fCastRange then
				hEntity:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, nil, hTarget:GetAbsOrigin(), false)
				CTimer(0.03, OnCastTargetVisionThink, hAbility, hEntity, hTarget, hEntity:GetLastOrderID())
				return false
			end
		end
		if bit32.btest(hAbility:GetBehavior(), DOTA_ABILITY_BEHAVIOR_AUTOCAST) and fDistance <= fCastRange then
			return hAbility:OnSpellStartAutoCast(hTarget)
		end
	end
	return true
end

local function OnToggleAutoCast(hEntity, hAbility)
	if bit32.btest(hAbility:GetBehavior(), DOTA_ABILITY_BEHAVIOR_AUTOCAST) and hAbility.OnToggleAutoCast then
		return hAbility:OnToggleAutoCast() or true
	end
	return true
end

function CIcewrackGameMode:ExecuteOrderFilter(keys)
	local nOrderType = keys.order_type
	local hTarget = EntIndexToHScript(keys.entindex_target)
	local hAbility = (keys.entindex_ability > 0) and EntIndexToHScript(keys.entindex_ability) or nil
	local vPosition = Vector(keys.position_x, keys.position_y, keys.position_z)
	
    local nUnitListSize = 0
	local tUnitList = keys.units
	for k,v in pairs(tUnitList) do
		nUnitListSize = nUnitListSize + 1
	end
	
	if nUnitListSize > 1 then
		GameRules.SharedUnitList = tUnitList
		for k,v in pairs(tUnitList) do
			local hEntity = EntIndexToHScript(v)
			hEntity:IssueOrder(nOrderType, hTarget, hAbility, vPosition, false)
		end
		GameRules.SharedUnitList = {}
		return false
	elseif nUnitListSize == 0 then
		return false
	end
	
	local hEntity = EntIndexToHScript(keys.units["0"])
	if hEntity:GetUnitName() == "npc_dota_hero_base" then
		return false
	end
	
	local tOrderTable = hEntity._tOrderTable
	if keys.queue == 0 and tOrderTable then
		tOrderTable.OrderType = nOrderType
		tOrderTable.TargetIndex = keys.entindex_target
		tOrderTable.AbilityIndex = keys.entindex_ability
		tOrderTable.Position = vPosition
		tOrderTable.Queue = false
		hEntity._nLastOrderID = hEntity._nLastOrderID + 1
		
		if nOrderType == DOTA_UNIT_ORDER_MOVE_TO_POSITION then
			return OnMoveToPosition(hEntity, vPosition)
		elseif nOrderType == DOTA_UNIT_ORDER_MOVE_TO_TARGET then
			return OnMoveToTarget(hEntity, hTarget)
		elseif nOrderType == DOTA_UNIT_ORDER_ATTACK_TARGET then
			return OnAttackTarget(hEntity, hTarget)
		elseif nOrderType == DOTA_UNIT_ORDER_CAST_POSITION then
			return OnCastPosition(hEntity, hAbility, vPosition)
		elseif nOrderType == DOTA_UNIT_ORDER_CAST_TARGET then
			return OnCastTarget(hEntity, hAbility, hTarget)
		elseif nOrderType == DOTA_UNIT_ORDER_CAST_TOGGLE_AUTO then
			return OnToggleAutoCast(hEntity, hAbility)
		end
	end
	return true
end

function CIcewrackGameMode:ItemAddedToInventoryFilter(keys)
	local hEntity = EntIndexToHScript(keys.inventory_parent_entindex_const)
    local hItem = EntIndexToHScript(keys.item_entindex_const)
	
	if string.find(hItem:GetAbilityName(), "internal_") == 1 then
		return true
	else
		if not IsValidExtendedItem(hItem) then
			hItem = CExtItem(hItem)
		end
		if IsValidExtendedEntity(hEntity) then
			local hInventory = hEntity:GetInventory()
			if hInventory then
				if not hInventory:AddItemToInventory(hItem) then
					CTimer(0.03, CExtEntity.IssueOrder, hEntity, DOTA_UNIT_ORDER_DROP_ITEM, hEntity, hItem, hEntity:GetAbsOrigin(), false)
					return true
				end
			end
		end
	end
	return false
end

function CIcewrackGameMode:ModifyExperienceFilter(keys)
	print("TODO: DELETEME")
	for k,v in pairs(keys) do print(k,v) end
	return true
end

function CIcewrackGameMode:OnQuit(keys)
	SendToServerConsole("disconnect")
end

function CIcewrackGameMode:OnPause(keys)
	if GameRules.OverridePauseLevel then
		GameRules.OverridePauseLevel = GameRules.OverridePauseLevel + 1
		PauseGame(true)
	end
end

function CIcewrackGameMode:OnUnpause(keys)
	if GameRules.OverridePauseLevel then
		GameRules.OverridePauseLevel = GameRules.OverridePauseLevel - 1
		PauseGame(GameRules.PauseState or (GameRules.OverridePauseLevel > 0))
	end
end

function CIcewrackGameMode:OnChangeLevel(keys)
	if keys.map then
		SendToServerConsole("dota_launch_custom_game " .. ICEWRACK_GAME_MODE_ID .. " " .. keys.map)
	end
end

function CIcewrackGameMode:OnPartySelect(keys)
	local hEntity = EntIndexToHScript(keys.value)
	if hEntity and not GameRules:GetMapInfo():IsOverride() then
		PlayerResource:SetCameraTarget(0, hEntity)
		CTimer(0.1, PlayerResource.SetCameraTarget, PlayerResource, 0, {})
	end
end