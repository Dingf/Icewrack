--[[
    Icewrack Entity Base
]]


if not CEntityBase then

IW_PLAYER_FACTION = 1
IW_DEFAULT_INTERACT_RANGE = 128

local stInteractableResultEnum =
{
	IW_INTERACTABLE_RESULT_FAIL = 0,
	IW_INTERACTABLE_RESULT_SUCCESS = 1,
	IW_INTERACTABLE_RESULT_EN_ROUTE = 2,
}

for k,v in pairs(stInteractableResultEnum) do _G[k] = v end

local stFactionList = {}
local stFactionData = LoadKeyValues("scripts/npc/iw_faction_list.txt")
for k,v in pairs(stFactionData) do
	local nFactionID = tonumber(k)
	local fDefaultWeight = v.WeightDefault
	if nFactionID and type(fDefaultWeight) == "number" then
		local tFactionWeights = setmetatable({}, { __index = function() return fDefaultWeight end })
		for k2,v2 in pairs(v.WeightOverride or {}) do
			local nTargetID = tonumber(k2)
			if nTargetID and type(v2) == "number" then
				tFactionWeights[nTargetID] = v2
			end
		end
		stFactionList[nFactionID] = tFactionWeights
	end
end

CEntityBase = setmetatable(ext_class({}), { __call = 
	function(self, hEntity, nInstanceID)
		LogAssert(IsInstanceOf(hEntity, CDOTA_BaseNPC), LOG_MESSAGE_ASSERT_TYPE, "CDOTA_BaseNPC")
		if IsInstanceOf(hEntity, CEntityBase) then
			return hEntity
		end
		
		hEntity = CInstance(hEntity, nInstanceID)
		ExtendIndexTable(hEntity, CEntityBase)
		
		hEntity._nFactionID = 0
		hEntity._tFactionWeights = {}
		
		hEntity._nLastOrderID = 0
		hEntity._tOrderTable = { UnitIndex = hEntity:entindex() }
		
		hEntity._fInteractRange = IW_DEFAULT_INTERACT_RANGE
		hEntity._szInteractZone = nil
		
		hEntity._tExtModifierEventTable = {}
		hEntity._tExtModifierEventIndex = {}
		
		hEntity._tRefreshList = {}
		
		return hEntity
	end})

function CEntityBase:GetFactionID()
	return self._nFactionID
end

function CEntityBase:SetFactionID(nFactionID)
	if type(nFactionID) == "number" then
		self._nFactionID = nFactionID
		self._tFactionWeights = setmetatable(self._tFactionWeights, { __index = stFactionList[nFactionID] })
		local nPlayerFactionWeight = self:GetPlayerFactionWeight()
		if nPlayerFactionWeight < 0.0 then
			self:SetTeam(DOTA_TEAM_BADGUYS)
		elseif nPlayerFactionWeight == 0.0 then
			self:SetTeam(DOTA_TEAM_NEUTRALS)
		else
			self:SetTeam(DOTA_TEAM_GOODGUYS)
		end
	end
end

function CEntityBase:GetFactionWeight(nFactionID)
	if nFactionID == self:GetFactionID() then
		return 100.0
	else
		return self._tFactionWeights[nFactionID]
	end
end

function CEntityBase:GetPlayerFactionWeight()
	return self:GetFactionWeight(IW_PLAYER_FACTION)
end

function CEntityBase:SetOverrideFactionWeight(nFactionID, nWeight)
	if stFactionList[nFactionID] and type(nWeight) == "number" then
		self._tFactionWeights[nFactionID] = nWeight
		if nWeight < 0.0 then
			self:SetTeam(DOTA_TEAM_BADGUYS)
		elseif nWeight == 0.0 then
			self:SetTeam(DOTA_TEAM_NEUTRALS)
		else
			self:SetTeam(DOTA_TEAM_GOODGUYS)
		end
	end
end
	
function CEntityBase:IsTargetEnemy(hTarget)
	if IsInstanceOf(hTarget, CEntityBase) then
		local fTargetWeight = self:GetFactionWeight(hTarget:GetFactionID())
		if type(fTargetWeight) == "number" then
			return fTargetWeight < 0.0
		end
	end
	return false
end
	
function CEntityBase:IsTargetTeam(hTarget, nTargetTeam)
	if IsInstanceOf(hTarget, CEntityBase) then
		local fTargetWeight = self:GetFactionWeight(hTarget:GetFactionID())
		if type(fTargetWeight) == "number" then
			local nUnitTeamFlag = (fTargetWeight < 0.0) and DOTA_UNIT_TARGET_TEAM_ENEMY or DOTA_UNIT_TARGET_TEAM_FRIENDLY
			return bit32.btest(nTargetTeam, nUnitTeamFlag)
		end
	end
	return false
end

function CEntityBase:IssueOrder(nOrder, hTarget, hAbility, vPosition, bQueue, bRepeatOnly)
    local tOrderTable = self._tOrderTable
	local nTargetEntindex = IsValidEntity(hTarget) and hTarget:entindex() or 0
	local nAbilityEntindex = IsValidEntity(hAbility) and hAbility:entindex() or 0
	if bRepeatOnly == true then
		if tOrderTable.OrderType ~= nOrder then
			return false
		elseif hTarget and tOrderTable.TargetIndex ~= nTargetEntindex then
			return false
		elseif hAbility and tOrderTable.AbilityIndex ~= nAbilityEntindex then
			return false
		elseif vPosition and tOrderTable.Position ~= vPosition then
			return false
		end
	end
	
	tOrderTable.OrderType = nOrder
	tOrderTable.TargetIndex = nTargetEntindex
	tOrderTable.AbilityIndex = nAbilityEntindex
	tOrderTable.Position = vPosition
	tOrderTable.Queue = bQueue
    ExecuteOrderFromTable(tOrderTable)
	return true
end

function CEntityBase:AddToRefreshList(hEntity)
	table.insert(self._tRefreshList, 1, hEntity)
end

function CEntityBase:RemoveFromRefreshList(hEntity)
	for k,v in ipairs(self._tRefreshList) do
		if v == hEntity then
			table.remove(self._tRefreshList, k)
			break
		end
	end
end

function CEntityBase:RefreshEntity()
	for k,v in ipairs(self._tRefreshList) do
		v:OnRefreshEntity()
	end
	
	local tRefreshStack = {}
	local tEntityMetatable = getmetatable(self).__index
	while type(tEntityMetatable) == "table" do
		local hEventFunction = rawget(tEntityMetatable, "OnRefreshEntity")
		if hEventFunction then
			table.insert(tRefreshStack, 1, hEventFunction)
		end
		local tParentMetatable = getmetatable(tEntityMetatable)
		if tParentMetatable then
			tEntityMetatable = tParentMetatable.__index
		else
			break
		end
	end
	for k,v in ipairs(tRefreshStack) do
		v(self)
	end
end

function CEntityBase:IsInInteractRange(hEntity)
	local fDistance = self:GetRangeToUnit(hEntity) - self:GetHullRadius() - hEntity:GetHullRadius()
	if fDistance > self:GetInteractRange() then
		return false
	end
	if self._szInteractZone then
		local hTrigger = Entities:FindByName(nil, self._szInteractZone)
		if IsInstanceOf(hTrigger, CBaseTrigger) and not hTrigger:IsTouching(hEntity) then
			return false
		end
	end
	return true
end

function CEntityBase:InteractFilterInclude(hEntity)
	return false
end

function CEntityBase:InteractFilterExclude(hEntity)
	return false
end

function CEntityBase:Interact(hEntity)
	return false
end

function CEntityBase:GetCustomInteractError(hEntity)
	return nil
end

function CEntityBase:GetInteractRange()
	return self._fInteractRange
end

function CEntityBase:GetInteractZone()
	if self._szInteractZone then
		local hTrigger = Entities:FindByName(nil, self._szInteractZone)
		if hTrigger and hTrigger.IsTouching then
			return hTrigger
		end
	end
end

function CEntityBase:SetInteractRange(fRange)
	if type(fRange) == "number" then
		self._fInteractRange = fRange
	end
end

function CEntityBase:SetInteractZone(szInteractZone)
	if type(szInteractZone) == "string" then
		self._szInteractZone = szInteractZone
	end
end

function CEntityBase:OnInteractFilter(hEntity)
	if not (hEntity:IsControllableByAnyPlayer() and hEntity:IsRealHero()) then
		return false
	end
	local tIndexMetatable = self
	while tIndexMetatable do
		local hFilterFunction = rawget(tIndexMetatable, "InteractFilter")
		if hFilterFunction and hFilterFunction(self, hEntity) then
			return true
		end
		tIndexMetatable = getmetatable(tIndexMetatable).__index
	end
	return false
end

function CEntityBase:OnInteract(hEntity)
	if not (hEntity:IsControllableByAnyPlayer() and hEntity:IsRealHero()) then
		return false
	end
	local tIndexMetatable = self
	while tIndexMetatable do
		local hInteractFunction = rawget(tIndexMetatable, "Interact")
		local hFilterFunction = rawget(tIndexMetatable, "InteractFilter")
		if hInteractFunction and hFilterFunction and hFilterFunction(self, hEntity) then
			local bResult = hInteractFunction(self, hEntity)
			if type(bResult) == "boolean" then return bResult end
		end
		tIndexMetatable = getmetatable(tIndexMetatable).__index
	end
	return true
end

function CEntityBase:OnGetCustomInteractError(hEntity)
	local tIndexMetatable = self
	while tIndexMetatable do
		local hFunction = rawget(tIndexMetatable, "GetCustomInteractError")
		if hFunction then
			local szMessage = hFunction(self, hEntity)
			if type(szMessage) == "boolean" then return szMessage end
		end
		tIndexMetatable = getmetatable(tIndexMetatable).__index
	end
	return true
end

function CEntityBase:TriggerExtendedEvent(nEventID, args)
	local szEventAlias = stExtModifierEventAliases[nEventID]
	if szEventAlias and self._tExtModifierEventIndex[nEventID] then
		for k,v in ipairs(self._tExtModifierEventIndex[nEventID]) do
			local hEventFunction = v[szEventAlias]
			if type(hEventFunction) == "function" then
				local result = hEventFunction(v, args)
				if result ~= nil then
					return result
				end
			end
		end
	end
end

function ExtUnitFilter(hEntity, hTarget, nTargetTeam, nTargetType, nTargetFlags)
	if IsInstanceOf(hEntity, CEntityBase) and IsInstanceOf(hTarget, CEntityBase) then
		if not hEntity:IsControllableByAnyPlayer() and not hTarget:IsControllableByAnyPlayer() then
			local nResult = UnitFilter(hTarget, DOTA_UNIT_TARGET_TEAM_BOTH, nTargetType, nTargetFlags, hEntity:GetTeamNumber())
			if nResult == UF_SUCCESS then
				local bIsEnemy = hEntity:IsTargetEnemy(hTarget)
				if nTargetTeam == DOTA_UNIT_TARGET_TEAM_FRIENDLY and bIsEnemy then
					return UF_FAIL_ENEMY
				elseif nTargetTeam == DOTA_UNIT_TARGET_TEAM_ENEMY and not bIsEnemy then
					return UF_FAIL_FRIENDLY
				end
			end
			return nResult
		else
			local nResult = UnitFilter(hTarget, nTargetTeam, nTargetType, nTargetFlags, hEntity:GetTeamNumber())
			return nResult
		end
	end
	return UF_FAIL_OTHER
end

end