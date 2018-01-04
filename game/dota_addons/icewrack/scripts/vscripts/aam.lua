--[[
    Ability Automator Module
]]

if not CAbilityAutomatorModule then

require("mechanics/difficulty")
require("mechanics/zone_avoid")
require("aam_condition")
require("aam_special")

local stAAMStateEnum =
{
	AAM_STATE_DISABLED = 0,
	AAM_STATE_ENABLED = 1,
	AAM_STATE_ENABLED_WHILE_NOT_SELECTED = 2,
}

for k,v in pairs(stAAMStateEnum) do _G[k] = v end

local stAbilityAutomatorData = LoadKeyValues("scripts/npc/npc_aam.txt")
CAbilityAutomatorModule = setmetatable(ext_class({}), { __call = 
	function(self, hEntity)
		LogAssert(IsInstanceOf(hEntity, CEntityBase), LOG_MESSAGE_ASSERT_TYPE, "CEntityBase")
		if IsInstanceOf(hEntity, CAbilityAutomatorModule) then
			LogMessage(LOG_MESSAGE_WARN_EXISTS, LOG_SEVERITY_WARNING, "CAbilityAutomatorModule", hEntity:GetName())
			return hEntity
		end
			
		ExtendIndexTable(hEntity, CAbilityAutomatorModule)
		
		hEntity._bIsAutomatorEnabled = false
		
		hEntity._tAutomatorList = {}
		hEntity._szActiveAutomatorName = nil
		
		hEntity._tRememberedUnitList = {}
		hEntity._tAutomatorNetTable =
		{
			Enabled = self._bIsAutomatorEnabled,
			State = AAM_STATE_DISABLED,
			ActiveAutomator = "",
			AutomatorList = {}
		}
		
		hEntity._tSpecialActions = setmetatable({}, { __index = stAAMSpecialActionTable })

		local tAbilityAutomatorTemplate = stAbilityAutomatorData[hEntity:GetUnitName()]
		if tAbilityAutomatorTemplate then
			for k,v in pairs(tAbilityAutomatorTemplate) do
				local szAutomatorName = k
				local tConditionList = {}
				for k2,v2 in pairs(v) do
					local nPriority = tonumber(k2)
					if nPriority then
						tConditionList[nPriority] = CAutomatorCondition(hEntity, v2.Action, v2.Flags1, v2.Flags2, v2.Inverse)
					end
				end
				for k2,v2 in ipairs(tConditionList) do
					hEntity:InsertAutomatorCondition(k, v2)
				end
				
				if not hEntity._szActiveAutomatorName then
					hEntity:SetActiveAutomator(k)
				end
			end
			hEntity:SetAutomatorEnabled(true)
		end
		
		hEntity:SetThink("OnAAMThink", hEntity, "AAMThink", 0.03)
		
		hEntity:UpdateAAMNetTable()
		
		return hEntity
	end})

function CAbilityAutomatorModule:SetAutomatorEnabled(bState)
	if type(bState) == "boolean" then
		self._bIsAutomatorEnabled = bState
	end
end

function CAbilityAutomatorModule:IsAutomatorEnabled()
	return self._bIsAutomatorEnabled
end
	
function CAbilityAutomatorModule:UpdateAAMNetTable()
	CustomNetTables:SetTableValue("aam", tostring(self:entindex()), self._tAutomatorNetTable)
end

function CAbilityAutomatorModule:OnRefreshEntity()
	self:UpdateAAMNetTable()
end

function CAbilityAutomatorModule:SetActiveAutomator(szAutomatorName)
	if szAutomatorName == nil or type(szAutomatorName) == "string" then
		self._szActiveAutomatorName = szAutomatorName
		self._tAutomatorNetTable.ActiveAutomator = szAutomatorName or ""
		self:UpdateAAMNetTable()
	end
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

function CAbilityAutomatorModule:InsertAutomatorCondition(szAutomatorName, hCondition, nPriority)
	local hAutomator = nil
	hAutomator = self._tAutomatorList[szAutomatorName]
	if not hAutomator then
		self._tAutomatorList[szAutomatorName] = {}
		self._tAutomatorNetTable.AutomatorList[szAutomatorName] = {}
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
	table.insert(self._tAutomatorNetTable.AutomatorList[szAutomatorName], nPriority,
	{
		Ability = hCondition._szActionName,
		Flags1  = hCondition._nFlags1,
		Flags2  = hCondition._nFlags2,
		InverseMask = hCondition._nInverseMask
	})
end

function CAbilityAutomatorModule:InsertSpecialAction(szActionName, hFunction)
	if type(szActionName) == "string" and type(hFunction) == "function" then
		local hAbility = self:AddAbility(szActionName)	--This is mostly so that the client will have an ability to reference for tooltips
		if hAbility then
			self._tSpecialActions[szActionName] = hFunction
		end
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
				table.remove(self._tAutomatorNetTable.AutomatorList[szAutomatorName], k)
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
		table.remove(self._tAutomatorNetTable.AutomatorList[szAutomatorName], nPriority)
		return hCondition
	end
	return nil
end

function CAbilityAutomatorModule:CastFilterAbility(szAbilityName, hTarget, vPosition)
	local hAbility = nil
	if type(szAbilityName) == "string" then
		hAbility = self:FindAbilityByName(szAbilityName)
	elseif type(hAbility) == "table" then
		hAbility = szAbilityName
	end
	if hAbility and hAbility:IsFullyCastable() then
		if self:IsHoldingPosition() then
			local fDistance = (hTarget:GetAbsOrigin() - self:GetAbsOrigin()):Length2D()
			if fDistance > hAbility:GetCastRange() then
				return false
			end
		end
	
		local nBehavior = hAbility:GetBehavior()
		if bit32.btest(nBehavior, DOTA_ABILITY_BEHAVIOR_NO_TARGET) then
			if hAbility.CastFilterResult and hAbility:CastFilterResult() ~= UF_SUCCESS then
				return false
			end
			self:IssueOrder(DOTA_UNIT_ORDER_CAST_NO_TARGET, nil, hAbility, nil, false)
			return true
		elseif bit32.btest(nBehavior, DOTA_ABILITY_BEHAVIOR_UNIT_TARGET) then
			if ExtUnitFilter(self, hTarget, hAbility:GetAbilityTargetTeam(), hAbility:GetAbilityTargetType(), hAbility:GetAbilityTargetFlags()) == UF_SUCCESS then
				if hAbility.CastFilterResultTarget and hAbility:CastFilterResultTarget(hTarget) ~= UF_SUCCESS then
					return false
				end
				self:IssueOrder(DOTA_UNIT_ORDER_CAST_TARGET, hTarget, hAbility, nil, false)
				return true
			end
		elseif bit32.btest(nBehavior, DOTA_ABILITY_BEHAVIOR_POINT) or bit32.btest(nBehavior, DOTA_ABILITY_BEHAVIOR_AOE) then
			if hAbility.CastFilterResultLocation and hAbility:CastFilterResultLocation(hTarget:GetAbsOrigin()) ~= UF_SUCCESS then 
				return false
			end
			self:IssueOrder(DOTA_UNIT_ORDER_CAST_POSITION, nil, hAbility, hTarget:GetAbsOrigin(), false)
			return true
		end
	end
	return false
end

function CAbilityAutomatorModule:OnAAMThink()
	local hActiveAutomator = self:GetActiveAutomator()
	if hActiveAutomator and self:IsAutomatorEnabled() and not GameRules:IsGamePaused() then
		if self:IsAlive() and self:GetCurrentActiveAbility() == nil and self:AttackReady() then
			self._nCurrentStep = 1
			for k,v in pairs(self._tRememberedUnitList) do
				self._tRememberedUnitList[k] = nil
			end
			while hActiveAutomator[self._nCurrentStep] do
				local hCondition = hActiveAutomator[self._nCurrentStep]
				local hTarget = hCondition:SelectTarget(self, self._tRememberedUnitList)
				if hTarget then
					local szActionName = hCondition:GetActionName()
					local hSpecialAction = self._tSpecialActions[szActionName]
					if hSpecialAction then
						if hSpecialAction(self, self, hTarget, hCondition:GetSpecialValue()) then
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
	return self:IsControllableByAnyPlayer() and 0.03 or GameRules:GetNPCThinkRate()
end


local CAutomatorEventHandler = {}
function CAutomatorEventHandler:OnChangeState(args)
	local hEntity = EntIndexToHScript(args.entindex)
	if IsInstanceOf(hEntity, CAbilityAutomatorModule) then
		hEntity:SetAutomatorEnabled(args.state ~= AAM_STATE_DISABLED)
		if not args.hidden or args.hidden == 0 then
			hEntity._tAutomatorNetTable.State = args.state
			hEntity:UpdateAAMNetTable()
		end
	end
end

function CAutomatorEventHandler:OnUpdate(args)
	local hEntity = EntIndexToHScript(args.entindex)
	if IsInstanceOf(hEntity, CAbilityAutomatorModule) then
		local szAutomatorName = hEntity:GetActiveAutomatorName()
		local hAutomator = hEntity:GetActiveAutomator()
		if hAutomator and hAutomator[args.priority] then
			local hCondition = hAutomator[args.priority]
			hCondition._szActionName = args.ability
			hCondition._nFlags1 = args.flags1
			hCondition._nFlags2 = args.flags2
			hCondition._nInverseMask = args.invmask
			
			local tConditionData = hEntity._tAutomatorNetTable.AutomatorList[szAutomatorName]
			tConditionData[args.priority].Ability = args.ability
			tConditionData[args.priority].Flags1 = args.flags1
			tConditionData[args.priority].Flags2 = args.flags2
			tConditionData[args.priority].InverseMask = args.invmask
			hEntity:UpdateAAMNetTable()
		else
			hEntity:InsertAutomatorCondition(szAutomatorName, CAutomatorCondition(hEntity, args.ability, args.flags1, args.flags2, args.invmask))
			hEntity:UpdateAAMNetTable()
		end
	end
end

function CAutomatorEventHandler:OnMove(args)
	local hEntity = EntIndexToHScript(args.entindex)
	if IsInstanceOf(hEntity, CAbilityAutomatorModule) then
		local szAutomatorName = hEntity:GetActiveAutomatorName()
		local hCondition = hEntity:RemoveConditionByPriority(szAutomatorName, args.old_priority)
		
		local hAutomator = nil
		if szAutomatorName and type(szAutomatorName) == "string" then
			hAutomator = hEntity._tAutomatorList[szAutomatorName]
		end
		hEntity:InsertAutomatorCondition(szAutomatorName, hCondition, args.new_priority)
		hEntity:UpdateAAMNetTable()
	end
end

function CAutomatorEventHandler:OnDelete(args)
	local hEntity = EntIndexToHScript(args.entindex)
	if IsInstanceOf(hEntity, CAbilityAutomatorModule) then
		local szAutomatorName = hEntity._szActiveAutomatorName
		hEntity:RemoveConditionByPriority(szAutomatorName, args.priority)
		hEntity:UpdateAAMNetTable()
	end
end

function CAutomatorEventHandler:OnSave(args)
	local hEntity = EntIndexToHScript(args.entindex)
	if IsInstanceOf(hEntity, CAbilityAutomatorModule) then
		if hEntity:GetActiveAutomatorName() ~= args.name then
			hEntity._tAutomatorList[args.name] = {}
			hEntity._tAutomatorNetTable.AutomatorList[args.name] = {}
			local hActiveAutomator = hEntity:GetActiveAutomator()
			if hActiveAutomator then
				for k,v in ipairs(hActiveAutomator) do
					hEntity:InsertAutomatorCondition(args.name, v)
				end
			end
		end
		hEntity:SetActiveAutomator(args.name)
		hEntity:UpdateAAMNetTable()
	end
end

function CAutomatorEventHandler:OnLoad(args)
	local hEntity = EntIndexToHScript(args.entindex)
	if IsInstanceOf(hEntity, CAbilityAutomatorModule) then
		hEntity:SetActiveAutomator(args.name)
		self:UpdateAAMNetTable()
	end
end

function CAutomatorEventHandler:OnDeleteAutomator(args)
	local hEntity = EntIndexToHScript(args.entindex)
	if IsInstanceOf(hEntity, CAbilityAutomatorModule) then
		hEntity._tAutomatorList[args.name] = nil
		hEntity._tAutomatorNetTable.AutomatorList[args.name] = nil
		if hEntity:GetActiveAutomatorName() == args.name then
			local szNextAutomator,_ = next(hEntity._tAutomatorList)
			hEntity:SetActiveAutomator(szNextAutomator)
		end
		self:UpdateAAMNetTable()
	end
end

CustomGameEventManager:RegisterListener("iw_aam_change_state", CAutomatorEventHandler.OnChangeState)
CustomGameEventManager:RegisterListener("iw_aam_update_condition", CAutomatorEventHandler.OnUpdate)
CustomGameEventManager:RegisterListener("iw_aam_move_condition", CAutomatorEventHandler.OnMove)
CustomGameEventManager:RegisterListener("iw_aam_delete_condition", CAutomatorEventHandler.OnDelete)
CustomGameEventManager:RegisterListener("iw_aam_save", CAutomatorEventHandler.OnSave)
CustomGameEventManager:RegisterListener("iw_aam_load", CAutomatorEventHandler.OnLoad)
CustomGameEventManager:RegisterListener("iw_aam_delete_automator", CAutomatorEventHandler.OnDeleteAutomator)

end