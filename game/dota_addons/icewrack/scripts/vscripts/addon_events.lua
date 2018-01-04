if _VERSION < "Lua 5.2" then
    bit = require("lib/numberlua")
    bit32 = bit.bit32
end

require("mechanics/effect_shatter")
require("mechanics/combat")
require("mechanics/corpse")
require("mechanics/revive")
require("timer")
require("map_info")
require("ext_ability")
require("ext_item")
require("ext_entity")
require("ext_modifier")
require("party")


--require("interactable")
--require("inventory")

--TODO: Remove the trace() statements from the SFS


function CIcewrackGameMode:OnEntitySpawned(keys)
    local hEntity = EntIndexToHScript(keys.entindex)
	local szEntityUnitName = hEntity:GetUnitName()
	if szEntityUnitName == CSaveManager:GetPlayerHeroName() and szEntityUnitName ~= "npc_dota_hero_base" and not IsValidExtendedEntity(hEntity) then
		CSaveManager:LoadPlayerHero(hEntity, 0)
	end
end

function CIcewrackGameMode:OnEntityKilled(keys)
    local hEntity = EntIndexToHScript(keys.entindex_killed)
	if IsValidExtendedEntity(hEntity) then
		for k,v in pairs(hEntity._tSpellList) do
			local hAbility = v:FindAbilityByName(k)
			hAbility:OnOwnerDied()
		end
		if not bit32.btest(hEntity:GetUnitFlags(), IW_UNIT_FLAG_NO_CORPSE) and not TriggerShatter(hEntity) then
			local nDeathFrames = hEntity:GetPropertyValue(IW_PROPERTY_CORPSE_TIME)
			CTimer((nDeathFrames - 1)/30.0, CreateCorpse, hEntity)
			if hEntity:IsRealHero() and CParty:IsPartyMember(hEntity) and GameRules:GetCustomGameDifficulty() < IW_DIFFICULTY_UNTHAW then
				CreateReviveTombstone(hEntity)
			end
		end
	elseif IsInstanceOf(hEntity, CContainer) then
		hEntity:OnContainerDestroyed()
	end
end

function CIcewrackGameMode:OnPlayerConnectFull(keys)
    local hPlayerInstance = PlayerInstanceFromIndex(keys.index + 1)
	if hPlayerInstance then
		--TODO: Either do something here or remove me
	end
end

function CIcewrackGameMode:OnGameRulesStateChange(keys)
	local nGameState = GameRules:State_Get()
	if nGameState == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
		PlayerResource:SetCustomTeamAssignment(0, DOTA_TEAM_GOODGUYS)
		GameRules:GetGameModeEntity():SetCustomGameForceHero(CSaveManager:GetPlayerHeroName() or "npc_dota_hero_base")
		CSaveManager:LoadGame()
		GameRules:FinishCustomGameSetup()
	elseif nGameState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		CSaveManager._tSaveSpecial.Loading = nil
		CSaveManager:CreateSaveList(self, keys)
	end
end

local function OnMoveToPosition(hEntity, vPosition, bIsManualOrder)
	if IsValidExtendedHero(hEntity) and bIsManualOrder then
		hEntity:SetHoldPosition(false)
	end
	return true
end

local function OnInteractableMoveThink(hEntity, hTarget, nOrderID)
	if hEntity:GetLastOrderID() == nOrderID then
		if hTarget:IsInInteractRange(hEntity) then
			hEntity:Stop()
			hEntity:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_TARGET, hTarget, nil, nil, false)
		else
			CTimer(0.03, OnInteractableMoveThink, hEntity, hTarget, nOrderID)
		end
	end
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
			if not hTarget:OnInteract(hEntity) then
				local szErrorMessage = hTarget:OnGetCustomInteractError(hEntity)
				if szErrorMessage then
					--TODO: Implement the error message here
				end
			end
			return IW_INTERACTABLE_RESULT_SUCCESS
		else
			CTimer(0.03, OnInteractableMoveThink, hEntity, hTarget, hEntity:GetLastOrderID())
			return IW_INTERACTABLE_RESULT_EN_ROUTE
		end
	end
	return IW_INTERACTABLE_RESULT_FAIL
end

local function OnMoveToTarget(hEntity, hTarget, bIsManualOrder)
	if IsValidExtendedHero(hEntity) and bIsManualOrder then
		hEntity:SetHoldPosition(false)
	end
	if IsInstanceOf(hTarget, CEntityBase) and OnInteractableActivate(hEntity, hTarget) == IW_INTERACTABLE_RESULT_SUCCESS then
		return false
	end
	return true
end

local function OnAttackMove(hEntity, vPosition, bIsManualOrder)
	if IsValidExtendedHero(hEntity) and bIsManualOrder then
		hEntity:SetHoldPosition(false)
	end
	return true
end

local function OnAttackTargetVisionThink(hEntity, hTarget, nOrderID)
	if hEntity:GetLastOrderID() == nOrderID then
		local fAttackRange = hEntity:GetAttackRange()
		local fDistance = (hEntity:GetAbsOrigin() - hTarget:GetAbsOrigin()):Length2D() - hEntity:GetHullRadius() - hTarget:GetHullRadius()
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

local function OnAttackTarget(hEntity, hTarget, bIsManualOrder)
	if IsValidExtendedEntity(hEntity) then
		if IsValidExtendedEntity(hTarget) and not hTarget:IsAlive() and CBaseEntity.IsAlive(hTarget) then
			hEntity:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_TARGET, hTarget, nil, nil, false)
			return false
		end
		
		local fAttackRange = hEntity:GetAttackRange()
		local fDistance = (hEntity:GetAbsOrigin() - hTarget:GetAbsOrigin()):Length2D() - hEntity:GetHullRadius() - hTarget:GetHullRadius()
		if not hEntity:IsTargetInLOS(hTarget) or fDistance > fAttackRange then
			if bIsManualOrder or not hEntity:IsHoldingPosition() then
				if IsValidExtendedHero(hEntity) then
					hEntity:SetHoldPosition(false)
				end
				hEntity:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_TARGET, hTarget, nil, nil, false)
				CTimer(0.03, OnAttackTargetVisionThink, hEntity, hTarget, hEntity:GetLastOrderID())
			else
				hEntity:IssueOrder(DOTA_UNIT_ORDER_STOP, nil, nil, nil, false)
			end
			return false
		end
		if not hEntity:CanPayAttackCosts() then
			CTimer(0.03, OnAttackTargetCostThink, hEntity, hTarget, hEntity:GetLastOrderID())
			return false
		end

		if hEntity:GetOrbAttackSource() then
			hEntity:OnOrbPreAttack()
		end
	end
	return true
end

local function OnCastPositionVisionThink(hAbility, hEntity, vPosition, nOrderID)
	if hEntity:GetLastOrderID() == nOrderID then
		local fCastRange = hAbility:GetCastRange()
		local fDistance = (hEntity:GetAbsOrigin() - vPosition):Length2D() - hEntity:GetHullRadius()
		local bIgnoreBlockers = bit32.btest(hAbility:GetAbilityFlags(), IW_ABILITY_FLAG_IGNORE_LOS_BLOCKERS)
		if hEntity:IsTargetInLOS(vPosition, bIgnoreBlockers) and fDistance <= fCastRange then
			hEntity:Stop()
			hEntity:IssueOrder(DOTA_UNIT_ORDER_CAST_POSITION, nil, hAbility, vPosition, false)
		else
			CTimer(0.03, OnCastPositionVisionThink, hAbility, hEntity, vPosition, nOrderID)
		end
	end
end

local function OnCastPosition(hEntity, hAbility, vPosition, bIsManualOrder)
	if IsValidExtendedAbility(hAbility) and hAbility:CastFilterResultLocation(vPosition) == UF_SUCCESS then
		local fCastRange = hAbility:GetCastRange()
		local fDistance = (hEntity:GetAbsOrigin() - vPosition):Length2D() - hEntity:GetHullRadius()
		local bRequiresVision = not bit32.btest(hAbility:GetAbilityFlags(), IW_ABILITY_FLAG_DOES_NOT_REQ_VISION)
		local bIgnoreBlockers = bit32.btest(hAbility:GetAbilityFlags(), IW_ABILITY_FLAG_IGNORE_LOS_BLOCKERS)
		if (bRequiresVision and not hEntity:IsTargetInLOS(vPosition, bIgnoreBlockers)) or fDistance > fCastRange then
			if bIsManualOrder or not hEntity:IsHoldingPosition() then
				if IsValidExtendedHero(hEntity) then
					hEntity:SetHoldPosition(false)
				end
				hEntity:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, nil, vPosition, false)
				CTimer(0.03, OnCastPositionVisionThink, hAbility, hEntity, vPosition, hEntity:GetLastOrderID())
			end
			return false
		end
	end
	return true
end

local function OnCastTargetVisionThink(hAbility, hEntity, hTarget, nOrderID)
	if hEntity:GetLastOrderID() == nOrderID then
		local fCastRange = hAbility:GetCastRange()
		local fDistance = (hEntity:GetAbsOrigin() - hTarget:GetAbsOrigin()):Length2D() - hEntity:GetHullRadius() - hTarget:GetHullRadius()
		local bIgnoreBlockers = bit32.btest(hAbility:GetAbilityFlags(), IW_ABILITY_FLAG_IGNORE_LOS_BLOCKERS)
		if hEntity:IsTargetInLOS(hTarget, bIgnoreBlockers) and fDistance <= fCastRange then
			hEntity:Stop()
			hEntity:IssueOrder(DOTA_UNIT_ORDER_CAST_TARGET, hTarget, hAbility, nil, false)
		else
			CTimer(0.03, OnCastTargetVisionThink, hAbility, hEntity, hTarget, nOrderID)
		end
	end
end

local function OnCastTargetOrbThink(hAbility, hEntity, hTarget, nOrderID)
	if hEntity:GetLastOrderID() == nOrderID then
		CTimer(0.03, OnCastTargetOrbThink, hAbility, hEntity, vPosition, nOrderID)
	elseif hEntity:GetOrbAttackSource() then
		hEntity:OnOrbPostAttack()
	end
end

local function OnCastTarget(hEntity, hAbility, hTarget, bIsManualOrder)
	local nAbilityBehavior = hAbility:GetBehavior()
	if (IsValidExtendedAbility(hAbility) or IsValidExtendedItem(hAbility)) and hAbility:CastFilterResultTarget(hTarget) == UF_SUCCESS then
		local fCastRange = hAbility:GetCastRange()
		local fDistance = (hEntity:GetAbsOrigin() - hTarget:GetAbsOrigin()):Length2D() - hEntity:GetHullRadius() - hTarget:GetHullRadius()
		local bRequiresVision = not bit32.btest(hAbility:GetAbilityFlags(), IW_ABILITY_FLAG_DOES_NOT_REQ_VISION)
		local bIgnoreBlockers = bit32.btest(hAbility:GetAbilityFlags(), IW_ABILITY_FLAG_IGNORE_LOS_BLOCKERS)
		if (bRequiresVision and not hEntity:IsTargetInLOS(hTarget, bIgnoreBlockers)) or fDistance > fCastRange then
			if bIsManualOrder or not hEntity:IsHoldingPosition() then
				if IsValidExtendedHero(hEntity) then
					hEntity:SetHoldPosition(false)
				end
				hEntity:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_TARGET, hTarget, nil, nil, false)
				CTimer(0.03, OnCastTargetVisionThink, hAbility, hEntity, hTarget, hEntity:GetLastOrderID())
			end
			return false
		end
		
		if bit32.btest(nAbilityBehavior, DOTA_ABILITY_BEHAVIOR_AUTOCAST) then
			return hAbility:OnSpellStartAutoCast(hTarget)
		end
	elseif bit32.btest(nAbilityBehavior, DOTA_ABILITY_BEHAVIOR_AUTOCAST + DOTA_ABILITY_BEHAVIOR_ATTACK) then
		CTimer(0.03, OnCastTargetOrbThink, hAbility, hEntity, hTarget, hEntity:GetLastOrderID())
	end
	return true
end

local function OnToggleAutoCast(hEntity, hAbility, bIsManualOrder)
	if IsValidExtendedAbility(hAbility) then
		if bit32.btest(hAbility:GetBehavior(), DOTA_ABILITY_BEHAVIOR_AUTOCAST) and hAbility.OnToggleAutoCast then
			return hAbility:OnToggleAutoCast() or true
		end
	end
	return true
end

local function OnHoldPosition(hEntity, bIsManualOrder)
	if IsValidExtendedEntity(hEntity) and hEntity:IsControllableByAnyPlayer() and bIsManualOrder then
		--hEntity:ToggleHoldPosition()
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
			if IsValidExtendedEntity(hEntity) then
				hEntity:IssueOrder(nOrderType, hTarget, hAbility, vPosition, false)
			end
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
		local bIsManualOrder = (debug.getinfo(2) == nil)
		tOrderTable.OrderType = nOrderType
		tOrderTable.TargetIndex = keys.entindex_target
		tOrderTable.AbilityIndex = keys.entindex_ability
		tOrderTable.Position = vPosition
		tOrderTable.Queue = false
		tOrderTable.IsManualOrder = bIsManualOrder
		hEntity._nLastOrderID = hEntity._nLastOrderID + 1
		
		local bEventResult = hEntity:TriggerExtendedEvent(IW_MODIFIER_EVENT_ON_EXECUTE_ORDER, tOrderTable)
		if bEventResult == false then
			return false
		end
		
		if nOrderType == DOTA_UNIT_ORDER_MOVE_TO_POSITION then
			return OnMoveToPosition(hEntity, vPosition, bIsManualOrder)
		elseif nOrderType == DOTA_UNIT_ORDER_MOVE_TO_TARGET then
			return OnMoveToTarget(hEntity, hTarget, bIsManualOrder)
		elseif nOrderType == DOTA_UNIT_ORDER_ATTACK_MOVE then
			return OnAttackMove(hEntity, vPosition, bIsManualOrder)
		elseif nOrderType == DOTA_UNIT_ORDER_ATTACK_TARGET then
			return OnAttackTarget(hEntity, hTarget, bIsManualOrder)
		elseif nOrderType == DOTA_UNIT_ORDER_CAST_POSITION then
			return OnCastPosition(hEntity, hAbility, vPosition, bIsManualOrder)
		elseif nOrderType == DOTA_UNIT_ORDER_CAST_TARGET then
			return OnCastTarget(hEntity, hAbility, hTarget, bIsManualOrder)
		elseif nOrderType == DOTA_UNIT_ORDER_CAST_TOGGLE_AUTO then
			return OnToggleAutoCast(hEntity, hAbility, bIsManualOrder)
		elseif nOrderType == DOTA_UNIT_ORDER_HOLD_POSITION then
			return OnHoldPosition(hEntity, bIsManualOrder)
		end
	end
	return true
end

function CIcewrackGameMode:ItemAddedToInventoryFilter(keys)
	local hEntity = EntIndexToHScript(keys.inventory_parent_entindex_const)
    local hItem = EntIndexToHScript(keys.item_entindex_const)
	
	if string.find(hItem:GetAbilityName(), "item_internal_") == 1 or hEntity:GetUnitName() == "npc_iw_generic_dummy" then
		return true
	elseif hItem:GetAbilityName() == "item_tpscroll" then
		return false	--TODO: Remove this once Valve stops giving everybody TP scrolls
	else
		if not IsValidExtendedItem(hItem) then
			hItem = CExtItem(hItem)
		end
		if IsInstanceOf(hEntity, CContainer) then
			if hEntity._tItemList[hItem] then
				return true
			elseif not hEntity:AddItemToInventory(hItem) then
				CTimer(0.03, CEntityBase.IssueOrder, hEntity, DOTA_UNIT_ORDER_DROP_ITEM, hEntity, hItem, hEntity:GetAbsOrigin(), false)
				return true
			end
			return false
		end
	end
	return true
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
	if not GameRules:GetMapInfo():IsOverride() and keys.PlayerID == 0 then
		GameRules.PauseState = (not GameRules.PauseState)
		PauseGame(GameRules.PauseState or (GameRules.OverridePauseLevel > 0))
	end
end

function CIcewrackGameMode:OnPauseOverride(keys)
	GameRules.OverridePauseLevel = GameRules.OverridePauseLevel + 1
	PauseGame(true)
end

function CIcewrackGameMode:OnUnpauseOverride(keys)
	GameRules.OverridePauseLevel = GameRules.OverridePauseLevel - 1
	PauseGame(GameRules.PauseState or (GameRules.OverridePauseLevel > 0))
end

function CIcewrackGameMode:OnQuicksave(keys)
	if not GameRules:GetMapInfo():IsOverride() and keys.PlayerID == 0 then
		FireGameEventLocal("iw_save_game", { mode = IW_SAVE_MODE_QUICKSAVE })
	end
end

function CIcewrackGameMode:OnQuickload(keys)
	if not GameRules:GetMapInfo():IsOverride() and keys.PlayerID == 0 then
		CSaveManager:LoadSave(CSaveManager._tSaveSpecial.Quicksave)
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
		CTimer(0.03, PlayerResource.SetCameraTarget, PlayerResource, 0, {})
	end
end