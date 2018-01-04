--[[
    Automator Special Actions
]]

function GetAllUnits(hSearcher, nTargetTeam, fMinRadius, fMaxRadius, nTargetFlags)
    if hSearcher and nTargetTeam then
        fMaxRadius = fMaxRadius or 1800.0
        fMinRadius = fMinRadius or 0.0
        nTargetFlags = nTargetFlags or 0
        
        local tUnitsList = FindUnitsInRadius(hSearcher:GetTeamNumber(), hSearcher:GetAbsOrigin(), nil, fMaxRadius, nTargetTeam, DOTA_UNIT_TARGET_ALL, nTargetFlags, 0, false)
        local tSelectedUnitsList = {}
        
        for k,v in pairs(tUnitsList) do
            local hEntity = v
            local fDistance = (hSearcher:GetAbsOrigin() - hEntity:GetAbsOrigin()):Length2D()
            if fDistance >= fMinRadius then
                table.insert(tSelectedUnitsList, hEntity)
            end
        end
        return tSelectedUnitsList
    else
        return nil
    end
end

local function MoveAwayFrom(hEntity, vTargetPosition, hDistanceFunction)
	local vEntityPosition = hEntity:GetAbsOrigin()
	local vDirection = vEntityPosition - vTargetPosition
	vDirection.z = 0
	vDirection = vDirection:Normalized()
	
	if not hEntity._fMoveLockTime or GameRules:GetGameTime() >= hEntity._fMoveLockTime then
		local fDistance = hEntity:GetHullRadius() + 128.0
		local vMovePosition = GetGroundPosition(vEntityPosition + (vDirection * fDistance), hEntity)
		if not GridNav:IsTraversable(vMovePosition) or not GridNav:CanFindPath(vEntityPosition, vMovePosition) then
			local x,y = vDirection.x, vDirection.y
			for i=2,21 do
				local a = math.floor(i/2) * 0.1308996939 * (((i % 2) * 2) - 1)
				local x2 = x * math.cos(a) - y * math.sin(a)
				local y2 = x * math.sin(a) + y * math.cos(a)
				local v = vEntityPosition + (Vector(x2, y2, 0) * fDistance)
				if GridNav:IsTraversable(v) and GridNav:CanFindPath(vEntityPosition, v) then
					local fEntityMoveSpeed = hEntity:GetMoveSpeedModifier(hEntity:GetBaseMoveSpeed())
					hEntity._fMoveLockTime = GameRules:GetGameTime() + GridNav:FindPathLength(vEntityPosition, v)/fEntityMoveSpeed
					hEntity:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, nil, v, false)
					return true
				end
			end
			
			local vMaxPosition = nil
			local fMaxDistance = nil
			for i=-5,5 do
				for j=-5,5 do
					local v = vEntityPosition + Vector(i*128, j*128, 0)
					if GridNav:IsTraversable(v) and GridNav:CanFindPath(vEntityPosition, v) then
						local fDistance = hDistanceFunction(vTargetPosition, v)
						if fDistance and (not fMaxDistance or fDistance > fMaxDistance) then
							fMaxDistance = fDistance
							vMaxPosition = v
						end
					end
				end
			end
			if vMaxPosition then
				local fEntityMoveSpeed = hEntity:GetMoveSpeedModifier(hEntity:GetBaseMoveSpeed())
				hEntity._fMoveLockTime = GameRules:GetGameTime() + GridNav:FindPathLength(vEntityPosition, vMaxPosition)/fEntityMoveSpeed
				hEntity:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, nil, vMaxPosition, false)
				return true
			end
			return false
		else
			hEntity:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, nil, vMovePosition, false)
			return true
		end
	end
	return true
end

--Skips the current action; useful for things like saving targets without performing actions
local function AAMDoNothing(hEntity, hAutomator, hTarget)
	return false
end

local function AAMSkipToCondition(hEntity, hAutomator, nValue)
	if nValue > hAutomator._nCurrentStep then
		hAutomator._nCurrentStep = nValue - 1
	end
	return false
end

local function AAMSkipRemaining(hEntity, hAutomator, nValue)
	hAutomator._nCurrentStep = #hAutomator
	return false
end

local function AAMAttackTarget(hEntity, hAutomator, hTarget)
    if IsInstanceOf(hEntity, CEntityBase) and hAutomator and hTarget then
		if hEntity:IsHoldingPosition() then
			local fDistance = (hTarget:GetAbsOrigin() - hEntity:GetAbsOrigin()):Length2D()
			if fDistance > hEntity:GetAttackRange() then
				return false
			end
		end
		
		if hEntity:IsAttackingEntity(hTarget) then
			return true
        else
            if hTarget:IsInvulnerable() or hTarget:IsAttackImmune() or not hEntity:CanEntityBeSeenByMyTeam(hTarget) then 
                return false
            else
				hEntity:IssueOrder(DOTA_UNIT_ORDER_ATTACK_TARGET, hTarget, nil, nil, false)
                return true
            end
        end
    end
    return false
end

local function AAMHoldPosition(hEntity, hAutomator, hTarget)
	--TODO: Implement me
	return false
end

local function AAMMoveAwayFromTarget(hEntity, hAutomator, hTarget)
    if IsInstanceOf(hEntity, CEntityBase) and hAutomator and hTarget then
		if hEntity:IsHoldingPosition() then
			return false
		end
		return MoveAwayFrom(hEntity, hTarget:GetAbsOrigin(), function(v1, v2) return GridNav:FindPathLength(v1, v2) end)
    end
    return false
end

local function AAMMoveTowardsTarget(hEntity, hAutomator, hTarget)
    if IsInstanceOf(hEntity, CEntityBase) and hAutomator and hTarget then
		if hEntity:IsHoldingPosition() then
			return false
		end
		
        local vDirection = hTarget:GetAbsOrigin() - hEntity:GetAbsOrigin()
        local vPosition = hEntity:GetAbsOrigin() + (vDirection:Normalized() * 100.0)
		local fDistance = CalcDistanceBetweenEntityOBB(hTarget, hEntity)
        if GridNav:IsTraversable(vPosition) and fDistance > 128.0 then
            hEntity:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, nil, GetGroundPosition(vPosition, hEntity), hEntity:IsAttacking())
            return true
        else
            return false
        end
    end
end

local function AAMMoveInFrontOf(hEntity, hAutomator, hTarget)
	--TODO: Implement me
	return false
end

local function AAMMoveBehind(hEntity, hAutomator, hTarget)
	--TODO: Implement me
	return false
end

local function AAMUseQuickItem(hEntity, hAutomator, hTarget, nValue)
	--TODO: Implement me
	return false
end

local function AAMNPCInvestigateNoise(hEntity, hAutomator, hTarget, nValue)
	if IsValidExtendedEntity(hEntity) and not hEntity:IsControllableByAnyPlayer() then
		local tNoiseTable = hEntity._tNoiseTable
		local fBestNoiseValue = 0.0
		local nBestNoiseIndex = nil
		for k,v in pairs(tNoiseTable) do
			if v > fBestNoiseValue then
				nBestNoiseIndex = k
				fBestNoiseValue = v
			end
			--[[local x = math.floor(k/1024)
			if x >= 512 then x = x - 1024 end
			local y = k % 1024
			if y >= 512 then y = y - 1024 end
			local vTargetPos = GetGroundPosition(Vector(GridNav:GridPosToWorldCenterX(x), GridNav:GridPosToWorldCenterY(y), 0), hEntity)
			DebugDrawSphere(vTargetPos, Vector(v * 16.0, 0, 0), 128.0, 32.0, true, 0.1)]]
		end
		
		if nBestNoiseIndex then
			local x = math.floor(nBestNoiseIndex/1024)
			if x >= 512 then x = x - 1024 end
			local y = nBestNoiseIndex % 1024
			if y >= 512 then y = y - 1024 end
			local vTargetPos = Vector(GridNav:GridPosToWorldCenterX(x), GridNav:GridPosToWorldCenterY(y), 0)
			hEntity:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, nil, vTargetPos, false)
			return true
		end
	end
	return false
end

local function DistanceAvoidDangerZone(v1, v2)
	local bIsInAvoidanceZone = false
	local tAvoidanceZones = CAvoidanceZone:GetAvoidanceZones()
	for k,v in pairs(tAvoidanceZones) do
		if v:IsTargetInZone(v2) then
			bIsInAvoidanceZone = true
			break
		end
	end
	
	if not bIsInAvoidanceZone then
		return -1.0 * GridNav:FindPathLength(v1, v2)
	end
end

local function AAMNPCAvoidDangerZone(hEntity, hAutomator, hTarget, nValue)
    if IsInstanceOf(hEntity, CEntityBase) and hAutomator and hTarget then
		local vEntityPosition = hEntity:GetAbsOrigin()
		local vNetDirection = Vector(0, 0, 0)
		local nAvoidanceZoneCount = 0
		
		local tAvoidanceZones = CAvoidanceZone:GetAvoidanceZones()
		for k,v in pairs(tAvoidanceZones) do
			local vTargetVector = vEntityPosition - v:GetOrigin()
			local fTargetDistance = vTargetVector:Length2D()
			if v:GetAvoidanceValue() >= nValue and (hEntity:IsTargetInLOS(v) or fTargetDistance <= v:GetRadius()) then
				vNetDirection = vNetDirection + (vTargetVector:Normalized() * v:GetAvoidanceValue())
				nAvoidanceZoneCount = nAvoidanceZoneCount + 1
			end
		end
		if nAvoidanceZoneCount > 0 then
			vNetDirection.z = 0
			vNetDirection = vNetDirection:Normalized()
			return MoveAwayFrom(hEntity, vEntityPosition - vNetDirection, DistanceAvoidDangerZone)
		end
	end
	return false
end

stAAMSpecialActionTable = 
{
	["aam_do_nothing"]        = AAMDoNothing,
	["aam_skip_to_condition"] = AAMSkipToCondition,
	["aam_skip_remaining"]    = AAMSkipRemaining,
    ["aam_attack"]            = AAMAttackTarget,
    ["aam_hold_position"]     = AAMHoldPosition,
    ["aam_move_away_from"]    = AAMMoveAwayFromTarget,
    ["aam_move_towards"]      = AAMMoveTowardsTarget,
    ["aam_move_in_front_of"]  = AAMMoveInFrontOf,
	["aam_move_behind"]       = AAMMoveBehind,
	["aam_use_quick_item"]    = AAMUseQuickItem,
	["aam_npc_investigate"]   = AAMNPCInvestigateNoise,
	["aam_npc_avoid_danger"]  = AAMNPCAvoidDangerZone,
}
