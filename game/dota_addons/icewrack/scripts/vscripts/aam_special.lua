--[[
    Automator Special Actions
]]

require("timer")
--require("ext_entity")

local tPathingNodes = {}
local tPositionTracker = {}

--TODO: Add use quick item, move in front of, move behind

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

--Skips the current action; useful for things like saving targets without performing actions
function DoNothing(hEntity, hAutomator, hTarget)
	return false
end

function MoveAwayFromTarget(hEntity, hAutomator, hTarget)
    if IsValidExtendedEntity(hEntity) and hAutomator and hTarget then
		if hEntity:IsHoldPosition() then
			return false
		end
	
		local vEntityPosition = hEntity:GetAbsOrigin()
		local vTargetPosition = hTarget:GetAbsOrigin()
        local vTargetVector = vEntityPosition - vTargetPosition
		vTargetVector.z = 0
		vTargetVector = vTargetVector:Normalized()
		
		if not hEntity._fMoveLockTime or GameRules:GetGameTime() >= hEntity._fMoveLockTime then
			local fDistance = hEntity:GetHullRadius() + 128.0
			local vMovePosition = GetGroundPosition(vEntityPosition + (vTargetVector * fDistance), hEntity)
			DebugDrawSphere(vMovePosition, Vector(255, 0, 0), 128.0, 32.0, true, 0.1)
			if not GridNav:IsTraversable(vMovePosition) or not GridNav:CanFindPath(vEntityPosition, vMovePosition) then
				local x,y = vTargetVector.x, vTargetVector.y
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
				local fMaxDistance = 0
				for i=-5,5 do
					for j=-5,5 do
						local v = vEntityPosition + Vector(i*128, j*128, 0)
						if GridNav:IsTraversable(v) then
							local fDistance = GridNav:FindPathLength(vTargetPosition, v)
							if fDistance > fMaxDistance then
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
    end
    return false
end

function MoveTowardsTarget(hEntity, hAutomator, hTarget)
    if IsValidExtendedEntity(hEntity) and hAutomator and hTarget then
		if hEntity:IsHoldPosition() then
			return false
		end
		
        local vDirection = hTarget:GetAbsOrigin() - hEntity:GetAbsOrigin()
        local vPosition = hEntity:GetAbsOrigin() + (vDirection:Normalized() * 100.0)
		local fDistance = CalcDistanceBetweenEntityOBB(hTarget, hEntity)
        if GridNav:IsTraversable(vPosition) and fDistance > 128.0 then
            hEntity:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, nil, GetGroundPosition(vPosition, hEntity._hBaseEntity), hEntity:IsAttacking())
            return true
        else
            return false
        end
    end
end

function AttackTarget(hEntity, hAutomator, hTarget)
    if IsValidExtendedEntity(hEntity) and hAutomator and hTarget then
		if hEntity:IsHoldPosition() then
			local fDistance = (hTarget:GetAbsOrigin() - hEntity:GetAbsOrigin()):Length2D()
			if fDistance > hEntity:GetAttackRange() then
				return false
			end
		end
		
		if hEntity:IsAttackingEntity(hTarget) then
			return true
        else
            if hTarget:IsInvulnerable() or hTarget:IsAttackImmune() then 
                return false
            else
				hEntity:IssueOrder(DOTA_UNIT_ORDER_ATTACK_TARGET, hTarget, nil, nil, false)
                return true
            end
        end
    end
    return false
end

function SkipToCondition(hEntity, hAutomator, nValue)
	if nValue > hAutomator._nCurrentStep then
		hAutomator._nCurrentStep = nValue - 1
	end
	return false
end

stAAMSpecialActionTable = 
{
	["aam_do_nothing"]        = DoNothing,
    ["aam_move_away_from"]    = MoveAwayFromTarget,
    ["aam_move_towards"]      = MoveTowardsTarget,
    ["aam_attack"]            = AttackTarget,
	["aam_skip_to_condition"] = SkipToCondition,
}
