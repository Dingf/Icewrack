--[[
    Ability Automator Module
]]

if not CAbilityAutomatorModule then

require("mechanics/difficulty")
require("ext_entity")
require("aam_special")
require("aam_condition")

local stAAMStateEnum =
{
	AAM_STATE_DISABLED = 0,
	AAM_STATE_ENABLED = 1,
	AAM_STATE_ENABLED_WHILE_NOT_SELECTED = 2,
}

for k,v in pairs(stAAMStateEnum) do _G[k] = v end

local function GetAbilityAutomator(self)
	return self._hAutomator
end

--TODO: Load default AAM data from a kv file
--stAbilityAutomatorData = LoadKeyValues("scripts/npc/npc_units_aam.txt")
CAbilityAutomatorModule = setmetatable({}, { __call = 
	function(self, hEntity)
		LogAssert(IsValidExtendedEntity(hEntity), LOG_MESSAGE_ASSERT_TYPE, "CExtEntity", type(hEntity))
		if hEntity._hAutomator and hEntity._hAutomator._bIsAutomator then
			return hEntity._hAutomator
		end
			
		local tAbilityAutomatorTemplate = {}--stAbilityAutomatorData[hEntity:GetUnitName()] or {}
		
		self = setmetatable({}, {__index =
			function(self, k)
				return CAbilityAutomatorModule[k] or nil
			end})
		
		hEntity._hAutomator = self
		hEntity.GetAbilityAutomator = GetAbilityAutomator
		hEntity:AddToRefreshList(self)
		
		self._bIsAutomator = true
		self._bIsEnabled = false
		self._hEntity = hEntity
		self._szName = szName
		
		self._nAutomatorSize = 0
		self._tAutomatorList = {}
		self._szActiveAutomatorName = nil
		
		self._tRememberedUnitList = {}
		self._tNetTable =
		{
			Enabled = self._bIsEnabled,
			State = AAM_STATE_DISABLED,
			ActiveAutomator = "",
			AutomatorList = {}
		}
		
		self._tSpecialActions = setmetatable({}, { __index = stAAMSpecialActionTable })

		for k,v in pairs(tAbilityAutomatorTemplate) do
			local szAutomatorName = k
			for k2,v2 in pairs(v) do
				if v2.Ability and v2.Flags1 and v2.Flags2 and v2.InverseMask then
					self:InsertCondition(k, CAutomatorCondition(hENtity, v2.Ability, v2.Flags1, v2.Flags2, v2.InverseMask))
				end
			end
			if not self._szActiveAutomatorName then
				self:SetActiveAutomator(k)
			end
		end
		self:UpdateNetTable()
		
		hEntity.OnAAMThink = self.OnThink
		hEntity:SetThink("OnAAMThink", self, "AAMThink", 0.03)
		
		return self
	end})
	

function CAbilityAutomatorModule:SetEnabled(bState)
	if type(bState) == "boolean" then
		self._bIsEnabled = bState
	end
end

function CAbilityAutomatorModule:IsEnabled()
	return self._bIsEnabled
end

function CAbilityAutomatorModule:UpdateNetTable()
	local hEntity = self._hEntity
	CustomNetTables:SetTableValue("aam", tostring(hEntity:entindex()), self._tNetTable)
end

function CAbilityAutomatorModule:OnEntityRefresh()
	self:UpdateNetTable()
end

function CAbilityAutomatorModule:SetActiveAutomator(szAutomatorName)
	self._szActiveAutomatorName = szAutomatorName
	self._tNetTable.ActiveAutomator = szAutomatorName or ""
end

function CAbilityAutomatorModule:GetActiveAutomatorName()
	return self._szActiveAutomatorName or ""
end

function CAbilityAutomatorModule:GetActiveAutomator()
	if self._szActiveAutomatorName then
		return self._tAutomatorList[self._szActiveAutomatorName]
	end
	return nil
end

function CAbilityAutomatorModule:InsertCondition(szAutomatorName, hCondition, nPriority)
	local hAutomator = nil
	hAutomator = self._tAutomatorList[szAutomatorName]
	if not hAutomator then
		self._nAutomatorSize = self._nAutomatorSize + 1
		self._tAutomatorList[szAutomatorName] = {}
		self._tNetTable.AutomatorList[szAutomatorName] = {}
		hAutomator = self._tAutomatorList[szAutomatorName]
		if not self._szActiveAutomatorName then
			self:SetActiveAutomator(szAutomatorName)
		end
	end
	
	local nConditionCount = #hAutomator
	nPriority = nPriority or nConditionCount + 1
	if nPriority < 1 then nPriority = 1 end
	if nPriority > nConditionCount + 1 then nPriority = nConditionCount + 1 end
	
	local hAutomator = self._tAutomatorList[szAutomatorName]
	table.insert(self._tAutomatorList[szAutomatorName], nPriority, hCondition)
	table.insert(self._tNetTable.AutomatorList[szAutomatorName], nPriority,
	{
		Ability = hCondition._szActionName,
		Flags1  = hCondition._nFlags1,
		Flags2  = hCondition._nFlags2,
		InverseMask = hCondition._nInverseMask
	})
end

function CAbilityAutomatorModule:InsertSpecialAction(szActionName, hFunction)
	if type(szActionName) == "string" and type(hFunction) == "function" then
		self._tSpecialActions[szActionName] = hFunction
	end
end

function CAbilityAutomatorModule:RemoveConditionByHandle(szAutomatorName, hCondition)
	local hAutomator = nil
	if szAutomatorName and type(szAutomatorName) == "string" then
		hAutomator = self._tAutomatorList[szAutomatorName]
	end
	
	if hAutomator then
		for k,v in pairs(hAutomator) do
			if hCondition == v then
				table.remove(hAutomator, k)
				table.remove(self._tNetTable.AutomatorList[szAutomatorName], k)
				return hCondition
			end
		end
	end
	return nil
end

function CAbilityAutomatorModule:RemoveConditionByPriority(szAutomatorName, nPriority)
	local hAutomator = nil
	if szAutomatorName and type(szAutomatorName) == "string" then
		hAutomator = self._tAutomatorList[szAutomatorName]
	end
	
	if hAutomator then
		local hCondition = hAutomator[nPriority]
		table.remove(hAutomator, nPriority)
		table.remove(self._tNetTable.AutomatorList[szAutomatorName], nPriority)
		return hCondition
	end
	return nil
end

function CAbilityAutomatorModule:CastFilterAbility(szAbilityName, hTarget, vPosition)
	local hEntity = self._hEntity
	local hAbility = nil
	if type(szAbilityName) == "string" then
		hAbility = hEntity:FindAbilityByName(szAbilityName)
	elseif type(hAbility) == "table" then
		hAbility = szAbilityName
	end
	if hAbility and hAbility:IsFullyCastable() then
		if hEntity:IsHoldPosition() then
			local fDistance = (hTarget:GetAbsOrigin() - hEntity:GetAbsOrigin()):Length2D()
			if fDistance > hAbility:GetCastRange() then
				return false
			end
		end
	
		local nBehavior = hAbility:GetBehavior()
		if bit32.btest(nBehavior, DOTA_ABILITY_BEHAVIOR_NO_TARGET) then
			if hAbility.CastFilterResult and hAbility:CastFilterResult() ~= UF_SUCCESS then
				return false
			end
			hEntity:IssueOrder(DOTA_UNIT_ORDER_CAST_NO_TARGET, nil, hAbility, nil, false)
			return true
		elseif bit32.btest(nBehavior, DOTA_ABILITY_BEHAVIOR_UNIT_TARGET) then
			if UnitFilter(hTarget, hAbility:GetAbilityTargetTeam(), hAbility:GetAbilityTargetType(), hAbility:GetAbilityTargetFlags(), hEntity:GetTeamNumber()) == UF_SUCCESS then
				if hAbility.CastFilterResultTarget and hAbility:CastFilterResultTarget(hTarget) ~= UF_SUCCESS then
					return false
				end
				hEntity:IssueOrder(DOTA_UNIT_ORDER_CAST_TARGET, hTarget, hAbility, nil, false)
				return true
			end
		elseif bit32.btest(nBehavior, DOTA_ABILITY_BEHAVIOR_POINT) or bit32.btest(nBehavior, DOTA_ABILITY_BEHAVIOR_AOE) then
			if hAbility.CastFilterResultLocation and hAbility:CastFilterResultLocation(hTarget:GetAbsOrigin()) ~= UF_SUCCESS then 
				return false
			end
			hEntity:IssueOrder(DOTA_UNIT_ORDER_CAST_POSITION, nil, hAbility, hTarget:GetAbsOrigin(), false)
			return true
		end
	end
	return false
end

function CAbilityAutomatorModule:OnAAMThink()
	local hEntity = self._hEntity
	local hActiveAutomator = self:GetActiveAutomator()
	if hActiveAutomator and self:IsEnabled() and not GameRules:IsGamePaused() then
		if hEntity:IsAlive() and hEntity:GetCurrentActiveAbility() == nil and hEntity:AttackReady() then
			self._nCurrentStep = 1
			for k,v in pairs(self._tRememberedUnitList) do
				self._tRememberedUnitList[k] = nil
			end
			while hActiveAutomator[self._nCurrentStep] do
				local hCondition = hActiveAutomator[self._nCurrentStep]
				local hTarget = hCondition:SelectTarget(hEntity, self._tRememberedUnitList)
				if hTarget then
					local szActionName = hCondition:GetActionName()
					local hSpecialAction = self._tSpecialActions[szActionName]
					if hSpecialAction then
						if hSpecialAction(hEntity, self, hTarget) then
							break
						end
					else
						if self:CastFilterAbility(szActionName, hTarget, hTarget:GetAbsOrigin()) then
							break
						end
					end
				end
				self._nCurrentStep = self._nCurrentStep + 1
			end
		end
	end
	return hEntity:IsControllableByAnyPlayer() and 0.03 or stAAMNPCThinkRates[GameRules:GetCustomGameDifficulty()]
end

function CAbilityAutomatorModule:OnChangeState(args)
	local hEntity = EntIndexToHScript(args.entindex)
	local hAutomatorModule = hEntity:GetAbilityAutomator()
	if hAutomatorModule then
		hAutomatorModule:SetEnabled(args.state ~= AAM_STATE_DISABLED)
		if not args.hidden or args.hidden == 0 then
			hAutomatorModule._tNetTable.State = args.state
			hAutomatorModule:UpdateNetTable()
		end
	end
end

function CAbilityAutomatorModule:OnUpdate(args)
	local hEntity = EntIndexToHScript(args.entindex)
	local hAutomatorModule = hEntity:GetAbilityAutomator()
	if hAutomatorModule then
		local szAutomatorName = hAutomatorModule:GetActiveAutomatorName()
		local hAutomator = hAutomatorModule:GetActiveAutomator()
		if hAutomator and hAutomator[args.priority] then
			local hCondition = hAutomator[args.priority]
			hCondition._szActionName = args.ability
			hCondition._nFlags1 = args.flags1
			hCondition._nFlags2 = args.flags2
			hCondition._nInverseMask = args.invmask
			
			local tConditionData = hAutomatorModule._tNetTable.AutomatorList[szAutomatorName]
			tConditionData[args.priority].Ability = args.ability
			tConditionData[args.priority].Flags1 = args.flags1
			tConditionData[args.priority].Flags2 = args.flags2
			tConditionData[args.priority].InverseMask = args.invmask
			hAutomatorModule:UpdateNetTable()
		else
			hAutomatorModule:InsertCondition(szAutomatorName, CAutomatorCondition(hEntity, args.ability, args.flags1, args.flags2, args.invmask))
			hAutomatorModule:UpdateNetTable()
		end
	end
end

function CAbilityAutomatorModule:OnMove(args)
	local hEntity = EntIndexToHScript(args.entindex)
	local hAutomatorModule = hEntity:GetAbilityAutomator()
	if hAutomatorModule then
		local szAutomatorName = hAutomatorModule:GetActiveAutomatorName()
		local hCondition = hAutomatorModule:RemoveConditionByPriority(szAutomatorName, args.old_priority)
		
		local hAutomator = nil
		if szAutomatorName and type(szAutomatorName) == "string" then
			hAutomator = hAutomatorModule._tAutomatorList[szAutomatorName]
		end
		hAutomatorModule:InsertCondition(szAutomatorName, hCondition, args.new_priority)
		hAutomatorModule:UpdateNetTable()
	end
end

function CAbilityAutomatorModule:OnDelete(args)
	local hEntity = EntIndexToHScript(args.entindex)
	local hAutomatorModule = hEntity:GetAbilityAutomator()
	if hAutomatorModule then
		local szAutomatorName = hAutomatorModule._szActiveAutomatorName
		hAutomatorModule:RemoveConditionByPriority(szAutomatorName, args.priority)
		hAutomatorModule:UpdateNetTable()
	end
end

function CAbilityAutomatorModule:OnSave(args)
	local hEntity = EntIndexToHScript(args.entindex)
	local hAutomatorModule = hEntity:GetAbilityAutomator()
	if hAutomatorModule then
		if hAutomatorModule:GetActiveAutomatorName() ~= args.name then
			hAutomatorModule._tAutomatorList[args.name] = {}
			hAutomatorModule._tNetTable.AutomatorList[args.name] = {}
			local hActiveAutomator = hAutomatorModule:GetActiveAutomator()
			if hActiveAutomator then
				for k,v in ipairs(hActiveAutomator) do
					hAutomatorModule:InsertCondition(args.name, v)
				end
			end
		end
		hAutomatorModule:SetActiveAutomator(args.name)
		hAutomatorModule:UpdateNetTable()
	end
end

function CAbilityAutomatorModule:OnLoad(args)
	local hEntity = EntIndexToHScript(args.entindex)
	local hAutomatorModule = hEntity:GetAbilityAutomator()
	if hAutomatorModule then
		hAutomatorModule:SetActiveAutomator(args.name)
		hAutomatorModule:UpdateNetTable()
	end
end

function CAbilityAutomatorModule:OnDeleteAutomator(args)
	local hEntity = EntIndexToHScript(args.entindex)
	local hAutomatorModule = hEntity:GetAbilityAutomator()
	if hAutomatorModule then
		hAutomatorModule._tAutomatorList[args.name] = nil
		hAutomatorModule._tNetTable.AutomatorList[args.name] = nil
		if hAutomatorModule:GetActiveAutomatorName() == args.name then
			local szNextAutomator,_ = next(hAutomatorModule._tAutomatorList)
			hAutomatorModule:SetActiveAutomator(szNextAutomator)
		end
		hAutomatorModule:UpdateNetTable()
	end
end

function CAbilityAutomatorModule:OnEntityLoad(args)
	local hEntity = EntIndexToHScript(args.entindex)
	if hEntity then
		return CAbilityAutomatorModule(EntIndexToHScript(args.entindex))
	else
		LogMessage("Failed to retrieve entity with enindex \"" .. args.entindex .. "\"", LOG_SEVERITY_ERROR)
	end
end

CustomGameEventManager:RegisterListener("iw_aam_change_state", Dynamic_Wrap(CAbilityAutomatorModule, "OnChangeState"))
CustomGameEventManager:RegisterListener("iw_aam_update_condition", Dynamic_Wrap(CAbilityAutomatorModule, "OnUpdate"))
CustomGameEventManager:RegisterListener("iw_aam_move_condition", Dynamic_Wrap(CAbilityAutomatorModule, "OnMove"))
CustomGameEventManager:RegisterListener("iw_aam_delete_condition", Dynamic_Wrap(CAbilityAutomatorModule, "OnDelete"))
CustomGameEventManager:RegisterListener("iw_aam_save", Dynamic_Wrap(CAbilityAutomatorModule, "OnSave"))
CustomGameEventManager:RegisterListener("iw_aam_load", Dynamic_Wrap(CAbilityAutomatorModule, "OnLoad"))
CustomGameEventManager:RegisterListener("iw_aam_delete_automator", Dynamic_Wrap(CAbilityAutomatorModule, "OnDeleteAutomator"))

ListenToGameEvent("iw_ext_entity_load", Dynamic_Wrap(CAbilityAutomatorModule, "OnEntityLoad"), CAbilityAutomatorModule)

end