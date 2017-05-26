--[[
    Icewrack AAM Conditions
]]

-- 3b HP >= comparisons
-- 3b MP >= comparisons
-- 3b SP >= comparisons
-- 3b Unit class
-- 2b Unit type
-- 3b Unit subtype
-- 1b Unit is alive
-- 1b Unit is already affected
-- 1b Unit is self
-- 2b Unit has debuff
-- 5b Unit status effects
-- 1b Target is a remembered target
-- 1b Target is attacking a remembered target
-- 1b Target is attacked by a remembered target
-- 1b Unit is attacking any unit
-- 1b Unit is being attacked by any unit

-- 1b Target is using an ability on a remembered target
-- 1b Target is using an ability on any unit
-- 3b Unit position relative to caster
-- 8b Number of other units near the target
--    2b Unit relationship
--    3b Range
--    3b Number of units
-- 3b Unit Count
-- 1b Remember current target
-- 1b Party is in combat
-- 3b Target Min distance
-- 3b Target Max distance
-- 3b Target relationship
-- 4b Target selector
-- 1b Set as party focus target

if not CAutomatorCondition then

if _VERSION < "Lua 5.2" then
    bit = require("lib/numberlua")
    bit32 = bit.bit32
end

require("corpse")
require("ext_entity")
require("ext_ability")
require("party")

local stAAMConditionTeamEnum = 
{
    AAM_CONDITION_TEAM_FRIENDLY = 1, AAM_CONDITION_TEAM_ENEMY = 2,   AAM_CONDITION_TEAM_REMEMBERED_UNIT = 3, AAM_CONDITION_TEAM_PARTY_FOCUS_TARGET = 4,
	AAM_CONDITION_TEAM_PARTY_1 = 5,  AAM_CONDITION_TEAM_PARTY_2 = 6, AAM_CONDITION_TEAM_PARTY_3 = 7,         AAM_CONDITION_TEAM_PARTY_4 = 8,
}

local stAAMConditionTargetEnum =
{
    AAM_CONDITION_TARGET_NEAREST = 0,         AAM_CONDITION_TARGET_FARTHEST = 1,       AAM_CONDITION_TARGET_HIGHEST_ABS_HP = 2,  AAM_CONDITION_TARGET_LOWEST_ABS_HP = 3,
	AAM_CONDITION_TARGET_HIGHEST_PCT_HP = 4,  AAM_CONDITION_TARGET_LOWEST_PCT_HP = 5,  AAM_CONDITION_TARGET_HIGHEST_ABS_MP = 6,  AAM_CONDITION_TARGET_LOWEST_ABS_MP = 7,
	AAM_CONDITION_TARGET_HIGHEST_PCT_MP = 8,  AAM_CONDITION_TARGET_LOWEST_PCT_MP = 9,  AAM_CONDITION_TARGET_HIGHEST_ABS_SP = 10, AAM_CONDITION_TARGET_LOWEST_ABS_SP = 11,
	AAM_CONDITION_TARGET_HIGHEST_PCT_SP = 12, AAM_CONDITION_TARGET_LOWEST_PCT_SP = 13, AAM_CONDITION_TARGET_RANDOM = 14,         AAM_CONDITION_TARGET_HIGHEST_THREAT = 15,
}

local stDistanceTable  = { 0, 150, 300, 600, 900, 1200, 1800 }
local stThresholdTable = { 1.00, 0.90, 0.75, 0.50, 0.35, 0.25, 0.10 }

for k,v in pairs(stAAMConditionTeamEnum) do _G[k] = v end
for k,v in pairs(stAAMConditionTargetEnum) do _G[k] = v end

local function DoNothing(hCondition, nValue, tTargetList)
    return tTargetList
end

local function TargetValueGreq(nValue, szFuncName1, szFuncName2, tTargetList, bInverse)
	if nValue ~= 0 then
		local fThreshold = stThresholdTable[nValue]
		for k,v in pairs(tTargetList) do
			local fPercentValue = (tTargetList[k][szFuncName1])(v)/(tTargetList[k][szFuncName2])(v)
			if (bInverse or fPercentValue < fThreshold) and (not bInverse or fPercentValue >= fThreshold) then
				tTargetList[k] = nil
			end
		end
	end
	return tTargetList
end

local function TargetHPGreq(hCondition, nValue, tTargetList, bInverse)
	return TargetValueGreq(nValue, "GetHealth", "GetMaxHealth", tTargetList, bInverse)
end

local function TargetMPGreq(hCondition, nValue, tTargetList, bInverse)
	return TargetValueGreq(nValue, "GetMana", "GetMaxMana", tTargetList, bInverse)
end

local function TargetSPGreq(hCondition, nValue, tTargetList, bInverse)
	return TargetValueGreq(nValue, "GetStamina", "GetMaxStamina", tTargetList, bInverse)
end

local function TargetUnitClass(hCondition, nValue, tTargetList, bInverse)
	if nValue ~= 0 then
		for k,v in pairs(tTargetList) do
			if (v:GetUnitClass() < nValue or bInverse) and (v:GetUnitClass() > nValue or not bInverse) then
				tTargetList[k] = nil
			end
		end
	end
	return tTargetList
end

local function TargetUnitType(hCondition, nValue, tTargetList, bInverse)
	if nValue ~= 0 then
		for k,v in pairs(tTargetList) do
			if (v:GetUnitType() == nValue) == bInverse then
				tTargetList[k] = nil
			end
		end
	end
	return tTargetList
end

local function TargetUnitSubtype(hCondition, nValue, tTargetList, bInverse)
	if nValue ~= 0 then
		local tNewTargetList = {}
		for k,v in pairs(tTargetList) do
			if (v:GetUnitSubtype() == nValue) == bInverse then
				tTargetList[k] = nil
			end
		end
		return tNewTargetList
	end
	return tTargetList
end

local function TargetIsAlive(hCondition, nValue, tTargetList, bInverse)
	if nValue ~= 0 then
		for k,v in pairs(tTargetList) do
			if v:IsAlive() == bInverse then
				tTargetList[k] = nil
			end
		end
	end
	return tTargetList
end

local function TargetIsAffected(hCondition, nValue, tTargetList, bInverse)
	if nValue ~= 0 then
		local szActionName = hCondition:GetActionName()
		for k,v in pairs(tTargetList) do
			for k2,v2 in pairs(hAbility._tModifierList) do
				if v:HasModifier(k2) then
					tTargetList[k] = nil
					break
				end
			end
		end
		--TODO: For unthaw difficulty, make it so that multiple units won't cast the same ability on the same target simultaneously if bInverse is true
	end
	return tTargetList
end

local function TargetIsSelf(hCondition, nValue, tTargetList, bInverse)
	local hEntity = hCondition._hEntity
	if nValue ~= 0 then
		for k,v in pairs(tTargetList) do
			if (v == hEntity) == bInverse then
				tTargetList[k] = nil
			end
		end
	end
	return tTargetList
end

local function TargetHasDebuff(hCondition, nValue, tTargetList, bInverse)
	if nValue ~= 0 then
		for k,v in pairs(tTargetList) do
			local bHasDebuff = false
			local tModifierList = v:FindAllModifiers()
			for k2,v2 in pairs(tModifierList) do
				if IsValidExtendedModifier(v2) and v2:IsDebuff() then
					if nValue == IW_MODIFIER_CLASS_ANY or (v2:GetModifierClass() == nValue) then
						bHasDebuff = true
						break
					end
				end
			end
			if bHasDebuff == bInverse then
				tTargetList[k] = nil
			end
		end
	end
	return tTargetList
end

local function TargetHasStatusEffect(hCondition, nValue, tTargetList, bInverse)
	if nValue ~= 0 then
		for k,v in pairs(tTargetList) do
			local tModifierList = v:FindAllModifiers()
			local bHasStatusEffect = false
			for k2,v2 in pairs(tModifierList) do
				if IsValidExtendedModifier(v2) then
					local nStatusEffect = v2:GetStatusEffect()
					if nStatusEffect ~= IW_STATUS_EFFECT_NONE then
						if nValue == IW_STATUS_EFFECT_ANY or nStatusEffect == nValue then
							bHasStatusEffect = true
							break
						end
					end
				end
			end
			if bHasStatusEffect == bInverse then
				tTargetList[k] = nil
			end
		end
	end
	return tTargetList
end

local function TargetIsRemembered(hCondition, nValue, tTargetList, bInverse)
	if nValue ~= 0 then
		local tRememberedTargets = hCondition._tRememberedUnitList
		if not tRememberedTargets or not next(tRememberedTargets) then
			return bInverse and tTargetList or nil
		end
		for k,v in pairs(tTargetList) do
			if (tRememberedTargets[v] ~= nil) == bInverse then
				tTargetList[k] = nil
			end
		end
	end
	return tTargetList
end

local function TargetAttackingRemembered(hCondition, nValue, tTargetList, bInverse)
	if nValue ~= 0 then
		local tRememberedTargets = hCondition._tRememberedUnitList
		if not tRememberedTargets or not next(tRememberedTargets) then
			return bInverse and tTargetList or nil
		end
		for k,v in pairs(tTargetList) do
			local hResult = bInverse and v or nil
			if v._tAttackingTable then
				for k2,v2 in pairs(tRememberedTargets) do
					if v._tAttackingTable[k2:entindex()] then
						hResult = not bInverse and v or nil
						break
					end
				end
			end
			tTargetList[k] = hResult
		end
	end
	return tTargetList
end

local function TargetAttackedByRemembered(hCondition, nValue, tTargetList, bInverse)
	if nValue ~= 0 then
		local tRememberedTargets = hCondition._tRememberedUnitList
		if not tRememberedTargets or not next(tRememberedTargets) then
			return bInverse and tTargetList or nil
		end
		for k,v in pairs(tTargetList) do
			local hResult = bInverse and v or nil
			if v._tAttackedByTable then
				for k2,v2 in pairs(tRememberedTargets) do
					if v._tAttackedByTable[k2:entindex()] then
						hResult = not bInverse and v or nil
						break
					end
				end
			end
			tTargetList[k] = hResult
		end
	end
	return tTargetList
end

local function TargetIsAttacking(hCondition, nValue, tTargetList, bInverse)
	if nValue ~= 0 then
		for k,v in pairs(tTargetList) do
			if (next(v._tAttackingTable or {}) ~= nil) == bInverse then
				tTargetList[k] = nil
			end
		end
	end
	return tTargetList
end

local function TargetIsBeingAttacked(hCondition, nValue, tTargetList, bInverse)
	if nValue ~= 0 then
		for k,v in pairs(tTargetList) do
			if (next(v._tAttackedByTable or {}) ~= nil) == bInverse then
				tTargetList[k] = nil
			end
		end
	end
	return tTargetList
end

local function TargetIsCastingRemembered(hCondition, nValue, tTargetList, bInverse)
	if nValue ~= 0 then
		local tRememberedTargets = hCondition._tRememberedUnitList
		if not tRememberedTargets or not next(tRememberedTargets) then
			return bInverse and tTargetList or nil
		end
		for k,v in pairs(tTargetList) do
			local hResult = bInverse and v or nil
			local hActiveAbility = v:GetCurrentActiveAbility()
			if hActiveAbility ~= nil then
				local hAbilityTarget = hActiveAbility:GetCursorTarget()
				for k2,v2 in pairs(tRememberedTargets) do
					if v2 == hAbilityTarget then
						hResult = not bInverse and v or nil
						break
					end
				end
			end
			tTargetList[k] = hResult
		end
	end
	return tTargetList
end

local function TargetIsCasting(hCondition, nValue, tTargetList, bInverse)
	if nValue ~= 0 then
		for k,v in pairs(tTargetList) do
			local hActiveAbility = v:GetCurrentActiveAbility()
			if (hActiveAbility ~= nil) == bInverse then
				tTargetList[k] = nil
			end
		end
	end
	return tTargetList
end

local function TargetRelativePosition(hCondition, nValue, tTargetList, bInverse)
	if nValue ~= 0 then
		local hEntity = hCondition._hEntity
		local vEntityOrigin = hEntity:GetAbsOrigin()
		local vForwardVector = hEntity:GetForwardVector()
		local fForwardOffset = math.atan2(vForwardVector[2], vForwardVector[1])
		for k,v in pairs(tTargetList) do
			if v ~= hEntity then
				local fTargetAngle = nil
				if bInverse then
					local vTargetForward = v:GetForwardVector()
					local fTargetForwardOffset = math.atan2(vTargetForward[2], vTargetForward[1])
					local vTargetVector = v:GetAbsOrigin() - vEntityOrigin
					fTargetAngle = math.atan2(vTargetVector[2], vTargetVector[1]) - fTargetForwardOffset + 3.14159265
				else
					local vTargetVector = vEntityOrigin - v:GetAbsOrigin()
					fTargetAngle = math.atan2(vTargetVector[2], vTargetVector[1]) - fForwardOffset
				end
				if fTargetAngle > 3.14159265 then
					fTargetAngle = fTargetAngle - 6.28318531
				elseif fTargetAngle < -3.14159265 then
					fTargetAngle = fTargetAngle + 6.28318531
				end
				
				if (nValue == 1 and (math.abs(fTargetAngle) >= 0.785398163)) or
				   (nValue == 2 and (math.abs(fTargetAngle) < 2.35619449)) or
				   (nValue == 3 and (fTargetAngle < 0.785398163 or fTargetAngle >= 2.35619449)) or
				   (nValue == 4 and (fTargetAngle > -0.785398163 or fTargetAngle <= -2.35619449)) or
				   (nValue == 5 and (math.abs(fTargetAngle) >= 1.57079633)) or
				   (nValue == 6 and (math.abs(fTargetAngle) < 1.57079633)) or
				   (nValue == 7 and (math.abs(fTargetAngle) < 0.785398163 or math.abs(fTargetAngle) >= 2.35619449)) then
					tTargetList[k] = nil
				end
			else
				tTargetList[k] = nil
			end
		end
	end
	return tTargetList
end

local function TargetNearUnits(hCondition, nValue, tTargetList)
	if nValue ~= 0 then
		local hEntity = hCondition._hEntity
		local nTargetTeam = bit32.extract(nValue, 0, 2)
		local fSearchRange = stDistanceTable[bit32.extract(nValue, 2, 3)]
		local nUnitAmount = bit32.extract(nValue, 5, 3)
		for k,v in pairs(tTargetList) do
			local tUnitsList = FindUnitsInRadius(hEntity:GetTeamNumber(), v:GetAbsOrigin(), nil, fSearchRange, nTargetTeam, DOTA_UNIT_TARGET_ALL, 0, 0, false)
			local nUnitCount = 0
			for k2,v2 in pairs(tUnitsList) do
				if v2 ~= v then                --Ignore self when counting
					nUnitCount = nUnitCount + 1
				end
			end
			if (nUnitCount >= nUnitAmount) == bInverse then 
				tTargetList[k] = nil
			end
		end
	end
	return tTargetList
end

local function TargetUnitCount(hCondition, nValue, tTargetList, bInverse)
	if nValue ~= 0 then
		local nCount = 0
		for k,v in pairs(tTargetList) do
			nCount = nCount + 1
		end
		if (bInverse and nCount <= nValue) or (not bInverse and nCount >= nValue) then
			return tTargetList
		else
			return nil
		end
	end
	return tTargetList
end

local function RememberUnits(hCondition, nValue, tTargetList)
	if nValue ~= 0 then
		hCondition._tRememberedUnitList = {}
		for k,v in pairs(tTargetList) do
			hCondition._tRememberedUnitList[v] = true
		end
	end
	return tTargetList
end

local function PartyInCombat(hCondition, nValue, tTargetList, bInverse)
	if nValue ~= 0 and GameRules:IsInCombat() == bInverse then
		return nil
	end
	return tTargetList
end

local function SetPartyFocusTarget(hCondition, nValue, tTargetList)
	if nValue ~= 0 then
		CParty:SetPartyFocusTarget(unpack(tTargetList))
	end
	return tTargetList
end

local function SelectByDistance(hCondition, tTargetList, bComparison)
	local hEntity = hCondition._hEntity
    local hSelectedEntity = nil
    local fBestDistance = nil
    for k,v in pairs(tTargetList) do
        if v then
            local fDistance = (hEntity:GetAbsOrigin() - v:GetAbsOrigin()):Length2D()
            if not fBestDistance or ((bComparison and fDistance > fBestDistance) or (not bComparison and fDistance < fBestDistance)) then
                hSelectedEntity = v
                fBestDistance = fDistance
            end
        end
    end
    return hSelectedEntity
end

local function SelectByValue(tTargetList, nValueType, bComparison, bPercent)
    local hSelectedEntity = nil
    local fBestValue = nil
    for k,v in pairs(tTargetList) do
        if v then
            local fValue = nil
            if nValueType == 0 then            --Health
                fValue = bPercent and v:GetHealth()/v:GetMaxHealth() or v:GetHealth()
            elseif nValueType == 1 then        --Mana
                fValue = bPercent and v:GetMana()/v:GetMaxMana() or v:GetMana()
            elseif nValueType == 2 then        --Stamina
                fValue = bPercent and v:GetStamina()/v:GetMaxStamina() or v:GetStamina()
            end
            if fValue then
                if fValue == fBestValue and hSelectedEntity and v:entindex() < hSelectedEntity:entindex()then
                    hSelectedEntity = v
                elseif not fBestValue or (bComparison and fValue > fBestValue) or (not bComparison and fValue < fBestValue) then
                    hSelectedEntity = v
                    fBestValue = fValue
                end
            end
        end
    end
    return hSelectedEntity
end

local function SelectByRandom(tTargetList)
	return tTargetList[RandomInt(1, #tTableList)]
end

local function SelectByThreat(hCondition, tTargetList)
	local hEntity = hCondition._hEntity
	if IsValidNPCEntity(hEntity) then
		local hHighestThreatEntity = {}
		local fHighestThreatValue = -1.0
		for k,v in pairs(tTargetList) do
			local fThreat = hEntity:GetThreat(v)
			if fThreat > fHighestThreatValue then
				hHighestThreatEntity = v
				fHighestThreatValue = fThreat
			end
		end
		return hHighestThreatEntity
	end
	return next(tTargetList)
end

local stAAMConditionTargetTable =
{
    [AAM_CONDITION_TARGET_NEAREST]        = function(hCondition, tTargetList) return SelectByDistance(hCondition, tTargetList, false) end,
    [AAM_CONDITION_TARGET_FARTHEST]       = function(hCondition, tTargetList) return SelectByDistance(hCondition, tTargetList, true) end,
    [AAM_CONDITION_TARGET_HIGHEST_ABS_HP] = function(hCondition, tTargetList) return SelectByValue(tTargetList, 0, true,  false) end,
    [AAM_CONDITION_TARGET_LOWEST_ABS_HP]  = function(hCondition, tTargetList) return SelectByValue(tTargetList, 0, false, false) end,
    [AAM_CONDITION_TARGET_HIGHEST_PCT_HP] = function(hCondition, tTargetList) return SelectByValue(tTargetList, 0, true,  true)  end,
    [AAM_CONDITION_TARGET_LOWEST_PCT_HP]  = function(hCondition, tTargetList) return SelectByValue(tTargetList, 0, false, true)  end,
    [AAM_CONDITION_TARGET_HIGHEST_ABS_MP] = function(hCondition, tTargetList) return SelectByValue(tTargetList, 1, true,  false) end,
    [AAM_CONDITION_TARGET_LOWEST_ABS_MP]  = function(hCondition, tTargetList) return SelectByValue(tTargetList, 1, false, false) end,
    [AAM_CONDITION_TARGET_HIGHEST_PCT_MP] = function(hCondition, tTargetList) return SelectByValue(tTargetList, 1, true,  true)  end,
    [AAM_CONDITION_TARGET_LOWEST_PCT_MP]  = function(hCondition, tTargetList) return SelectByValue(tTargetList, 1, false, true)  end,
    [AAM_CONDITION_TARGET_HIGHEST_ABS_SP] = function(hCondition, tTargetList) return SelectByValue(tTargetList, 2, true,  false) end,
    [AAM_CONDITION_TARGET_LOWEST_ABS_SP]  = function(hCondition, tTargetList) return SelectByValue(tTargetList, 2, false, false) end,
    [AAM_CONDITION_TARGET_HIGHEST_PCT_SP] = function(hCondition, tTargetList) return SelectByValue(tTargetList, 2, true,  true)  end,
    [AAM_CONDITION_TARGET_LOWEST_PCT_SP]  = function(hCondition, tTargetList) return SelectByValue(tTargetList, 2, false, true)  end,
	[AAM_CONDITION_TARGET_RANDOM]         = function(hCondition, tTargetList) return SelectByRandom(tTargetList) end,
	[AAM_CONDITION_TARGET_HIGHEST_THREAT] = function(hCondition, tTargetList) return SelectByThreat(hCondition, tTargetList) end,
}

local function SelectTarget(hCondition, nValue, tTargetList)
	local pTargetFunction = stAAMConditionTargetTable[nValue]
	if pTargetFunction then
		return { pTargetFunction(hCondition, tTargetList) }
	else
		return {}
	end
end

local stAAMConditionFunctionTable =
{
	{TargetHPGreq,                 3},
	{TargetMPGreq,                 3},
	{TargetSPGreq,                 3},
    {TargetUnitClass,              3},
    {TargetUnitType,               2},
    {TargetUnitSubtype,            3},
    {TargetIsAlive,                1},
    {TargetIsAffected,             1},
    {TargetIsSelf,                 1},
    {TargetHasDebuff,              2},
    {TargetHasStatusEffect,        5},
    {TargetIsRemembered,           1},
    {TargetAttackingRemembered,    1},
    {TargetAttackedByRemembered,   1},
    {TargetIsAttacking,            1},
    {TargetIsBeingAttacked,        1},
	{TargetIsCastingRemembered,    1},
	{TargetIsCasting,              1},
    {TargetRelativePosition,       3},
    {TargetNearUnits,              8},
	{TargetUnitCount,              3},
    {RememberUnits,                1},
    {PartyInCombat,                1},
	{DoNothing,                    9},
	{SelectTarget,                 4},
	{SetPartyFocusTarget,          1},
}

CAutomatorCondition = setmetatable({}, { __call = 
	function(self, hEntity, szActionName, nFlags1, nFlags2, nInverseMask)
		self = setmetatable({}, {__index = CAutomatorCondition})
		
		self._bIsAAMCondition = true
		self._hEntity = hEntity
		self._szActionName = (type(szActionName) == "table") and szActionName:GetAbilityName() or szActionName
		self._nFlags1 = nFlags1 or 0
		self._nFlags2 = nFlags2 or 0
		self._nInverseMask = nInverseMask or 0
		
		self._tTargetList = {}
		
		return self
	end})

function CAutomatorCondition:GetActionName()
	return self._szActionName
end

function CAutomatorCondition:GetSaveTable()
	local tSaveTable =
	{
		ActionName = self._szActionName,
		Flags1 = self._nFlags1,
		Flags2 = self._nFlags2,
		InverseMask = self._nInverseMask,
	}
	return tSaveTable
end

function CAutomatorCondition:SelectTarget(hEntity, tRememberedUnitList)
	if hEntity then
		local nTargetTeam = bit32.extract(self._nFlags2, 24, 2) + 1
		local fMinRadius = stDistanceTable[bit32.extract(self._nFlags2, 18, 3)+1] or 0.0
		local fMaxRadius = stDistanceTable[bit32.extract(self._nFlags2, 21, 3)+1] or 0.0
		
		local bTargetDead = false
		if bit32.extract(self._nFlags1, 17, 1) == 1 and bit32.extract(self._nInverseMask, 6, 1) == 1 then
			bTargetDead = true
		end
			
		self._tRememberedUnitList = tRememberedUnitList
		local tTargetList = self._tTargetList
		for k,v in pairs(tTargetList) do
			tTargetList[k] = nil
		end
		
		--If set to friendly and 0.0 min and max radius, just select self as a shortcut
		if fMinRadius == 0.0 and fMaxRadius == 0.0 and nTargetTeam == AAM_CONDITION_TEAM_FRIENDLY then
			table.insert(tTargetList, hEntity)
		elseif nTargetTeam == AAM_CONDITION_TEAM_PARTY_FOCUS_TARGET then
			local hFocusTarget = CParty._hFocusTarget
			if IsValidExtendedEntity(hFocusTarget) then
				local fDistance = (hEntity:GetAbsOrigin() - hFocusTarget:GetAbsOrigin()):Length2D()
				if fDistance >= fMinRadius and fDistance <= fMaxRadius then
					table.insert(tTargetList, hFocusTarget)
				end
			end
		elseif nTargetTeam == AAM_CONDITION_TEAM_REMEMBERED_UNITS then
			if tRememberedUnitList then
				for k,v in pairs(tRememberedUnitList) do
					local fDistance = (hEntity:GetAbsOrigin() - k:GetAbsOrigin()):Length2D()
					if IsValidExtendedEntity(k) and fDistance >= fMinRadius and fDistance <= fMaxRadius then
						table.insert(tTargetList, k)
					end
				end
			else
				return nil	
			end
		elseif nTargetTeam >= AAM_CONDITION_TEAM_PARTY_1 and nTargetTeam <= AAM_CONDITION_TEAM_PARTY_4 then
			table.insert(tTargetList, CParty:GetMemberBySlot(nTargetTeam - 4))	
		else
			local tNearbyUnits = FindUnitsInRadius(hEntity:GetTeamNumber(), hEntity:GetAbsOrigin(), nil, fMaxRadius, nTargetTeam, DOTA_UNIT_TARGET_ALL, 0, 0, false)
			for k,v in pairs(tNearbyUnits) do
				local fDistance = (hEntity:GetAbsOrigin() - v:GetAbsOrigin()):Length2D()
				if (IsValidExtendedEntity(v) and (bTargetDead ~= v:IsAlive())) and fDistance >= fMinRadius and fDistance <= fMaxRadius then
					table.insert(tTargetList, v)
				end
			end
		end
		
		if next(tTargetList) == nil then
			return nil
		end
		
		for k,v in pairs(tTargetList) do
			if not (IsCorpseEntity(v) or IsValidExtendedEntity(v)) or (v:IsAlive() == bCanTargetDead) then
				tTargetList[k] = nil
			end
			if not hEntity:IsTargetInLOS(v) or (not hEntity:IsTargetDetected(v) and v:GetTeamNumber() ~= hEntity:GetTeamNumber()) then
				tTargetList[k] = nil
			end
		end
		
		local nBitOffset = 0
		for k,v in ipairs(stAAMConditionFunctionTable) do
			local pFunction, nSize = unpack(v)
			local nValue = (nBitOffset < 32) and bit32.extract(self._nFlags1, nBitOffset, nSize) or bit32.extract(self._nFlags2, nBitOffset - 32, nSize)
			local bInverse = (bit32.extract(self._nInverseMask, k-1, 1) == 1)
			tTargetList = pFunction(self, nValue, tTargetList, bInverse)
			if not tTargetList or next(tTargetList) == nil then
				return nil
			end
			nBitOffset = nBitOffset + nSize
		end
		return unpack(tTargetList)
	end
	return nil
end

end