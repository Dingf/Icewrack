if not CIcewrackNPCEntity then

require("mechanics/difficulty")
require("ext_entity")
require("aam")

IW_NPC_DEFAULT_THREAT_RAIUS = 1800.0	--The maximum threat falloff radius
IW_NPC_DEFAULT_SHARE_RADIUS = 900.0		--The radius at which detection/threat is shared
IW_NPC_VISION_DISTANCE_MIN = 128.0		--The minimum visibility distance; distances closer than this value will not increase visibility further
IW_NPC_TOUCH_RADIUS = 8.0				--The distance at which an entity will be detected due to physical contact
IW_NPC_NOISE_TIME_MIN = 0.5				--The minimum amount of time that a noise point will remain 

local stNPCBehaviorAggressiveEnum =
{
	IW_NPC_BEHAVIOR_AGGRO_PASSIVE = 0,		--won't attack no matter what
	IW_NPC_BEHAVIOR_AGGRO_DEFENSIVE = 1,	--won't attack unless attacked first
	IW_NPC_BEHAVIOR_AGGRO_TERRITORIAL = 2,	--will attack any enemy within a certain range, will return to that range if enemy is too far away
	IW_NPC_BEHAVIOR_AGGRO_AGGRESSIVE = 3,	--will attack and pursue any enemy in sight
}

local stNPCBehaviorCooperativeEnum =
{
	IW_NPC_BEHAVIOR_COOP_SELFISH = 0,		--won't share or receive any threat/detection
	IW_NPC_BEHAVIOR_COOP_SOCIAL = 1,		--shares/receives detected units with nearby allies
	IW_NPC_BEHAVIOR_COOP_SYNERGY = 2,		--shares/receives 0.25x threat from other allies, shares detected units with nearby allies
}

local stNPCBehaviorSafetyEnum =
{
	IW_NPC_BEHAVIOR_SAFETY_RECKLESS = 0,		--won't flee or avoid damage zones
	IW_NPC_BEHAVIOR_SAFETY_PREPARED = 1,		--will flee at <10% health, damage avoidance weight 1.0x
	IW_NPC_BEHAVIOR_SAFETY_CAUTIOUS = 2,		--will flee at <25% health, damage avoidance weight 2.0x
	IW_NPC_BEHAVIOR_SAFETY_COWARDLY = 3,		--will flee at <50% health, damage avoidance weight 5.0x
	IW_NPC_BEHAVIOR_SAFETY_PACIFIST = 4,		--will flee at any health, damage avoidance weight 100.0x
}

for k,v in pairs(stNPCBehaviorAggressiveEnum) do _G[k] = v end
for k,v in pairs(stNPCBehaviorCooperativeEnum) do _G[k] = v end
for k,v in pairs(stNPCBehaviorSafetyEnum) do _G[k] = v end

local stNPCFleeThreshold =
{
	[IW_NPC_BEHAVIOR_SAFETY_RECKLESS] = 0,
	[IW_NPC_BEHAVIOR_SAFETY_PREPARED] = 0.1,
	[IW_NPC_BEHAVIOR_SAFETY_CAUTIOUS] = 0.25,
	[IW_NPC_BEHAVIOR_SAFETY_COWARDLY] = 0.5,
	[IW_NPC_BEHAVIOR_SAFETY_PACIFIST] = 1.01,
}

local stNPCAvoidanceWeight =
{
	[IW_NPC_BEHAVIOR_SAFETY_RECKLESS] = 0,
	[IW_NPC_BEHAVIOR_SAFETY_PREPARED] = 1.0,
	[IW_NPC_BEHAVIOR_SAFETY_CAUTIOUS] = 2.0,
	[IW_NPC_BEHAVIOR_SAFETY_COWARDLY] = 5.0,
	[IW_NPC_BEHAVIOR_SAFETY_PACIFIST] = 100.0,
}


local stExtEntityData = LoadKeyValues("scripts/npc/npc_units_extended.txt")
local stWaypointData = LoadKeyValues("scripts/npc/maps/waypoints_" .. GetMapName() .. ".txt")
if not stWaypointData then
	LogMessage("Waypoint list for map \"" .. GetMapName() .. "\" not found", LOG_SEVERITY_ERROR)
end

CIcewrackNPCWaypoints = {}
for k,v in pairs(stWaypointData) do
	local tWaypoint =
	{
		_fRadius = v.Radius,
		_fWaitMin = v.WaitMin or 0.0,
		_fWaitMax = v.WaitMax or 0.0,
		_vPosition = StringToVector(v.Position),
		_tDestinations = {},
		_tDestinationSums = {},
	}
	for k2,v2 in pairs(v.Destination) do
		local fDestinationSum = 0.0
		local tDestinationList = {}
		for k3,v3 in pairs(v2) do
			tDestinationList[tonumber(k3)] = v3
			fDestinationSum = fDestinationSum + v3
		end
		tWaypoint._tDestinations[tonumber(k2)] = tDestinationList
		tWaypoint._tDestinationSums[tonumber(k2)] = fDestinationSum
	end
	CIcewrackNPCWaypoints[tonumber(k)] = tWaypoint
end

local tIndexTableList = {}
CIcewrackNPCEntity = setmetatable({}, { __call = 
	function(self, hEntity)
		LogAssert(IsValidExtendedEntity(hEntity), "Type mismatch (expected \"%s\", got %s)", "CDOTA_BaseNPC", type(hEntity))
		if hEntity._bIsNPCEntity then
			return hEntity
		end
		
		if not hEntity:IsHero() then
			local tExtEntityTemplate = stExtEntityData[hEntity:GetUnitName()]
			LogAssert(tExtEntityTemplate, "Failed to load template \"%d\" - no data exists for this entry.", hEntity:GetUnitName())
			
			local tBaseIndexTable = getmetatable(hEntity).__index
			local tExtIndexTable = tIndexTableList[tBaseIndexTable]
			if not tExtIndexTable then
				tExtIndexTable = ExtendIndexTable(hEntity, CIcewrackNPCEntity)
				tIndexTableList[tBaseIndexTable] = tExtIndexTable
			end
			setmetatable(hEntity, tExtIndexTable)
			
			hEntity._bIsNPCEntity    = true
			hEntity._fNoiseDetect    = tExtEntityTemplate.NoiseDetect or 1.0
			hEntity._fNoiseThreshold = tExtEntityTemplate.NoiseThreshold or 0.25
			hEntity._fVisionDetect   = tExtEntityTemplate.VisionDetect or 1.0
			hEntity._nVisionMask     = tExtEntityTemplate.VisionMask or 0xffffffff
			hEntity._fShareRadius    = tExtEntityTemplate.ShareRadius or IW_NPC_DEFAULT_SHARE_RADIUS
			hEntity._fThreatRadius   = tExtEntityTemplate.ThreatRadius or IW_NPC_DEFAULT_THREAT_RAIUS
			
			hEntity._nLastWaypoint   = 0
			hEntity._nNextWaypoint   = 0
			hEntity._fWaypointTime   = 0
			
			hEntity._vInitialPos = hEntity:GetAbsOrigin()
			hEntity._tDetectTable = {}
			hEntity._tThreatTable = setmetatable({}, stZeroDefaultMetatable)
			hEntity._tNoiseTable = {}
			hEntity._nNoiseTableIndex = 0
			
			local hAutomator = hEntity:GetAbilityAutomator()
			if hAutomator then
				local szAutomatorName = hAutomator:GetActiveAutomatorName()
				hAutomator:InsertSpecialAction("npc_think", CIcewrackNPCEntity.OnNPCThink)
				hAutomator:InsertCondition(szAutomatorName, CAutomatorCondition(hEntity, "npc_think", 0, 0, 0))
				hAutomator:SetEnabled(true)
			end
			
			hEntity:SetThink("NPCThink", hEntity, "NPCThink", 0.1)
		end
		
		return self
	end})
	
CIcewrackNPCEntity.CallWrapper = function(self, keys) if keys.entindex then CIcewrackNPCEntity(EntIndexToHScript(keys.entindex)) end end
ListenToGameEvent("iw_ext_entity_load", Dynamic_Wrap(CIcewrackNPCEntity, "CallWrapper"), CIcewrackNPCEntity)

function CIcewrackNPCEntity:GetBehaviorAggressiveness()
	return self:GetPropertyValue(IW_PROPERTY_BEHAVIOR_AGGRO)
end

function CIcewrackNPCEntity:GetBehaviorCooperativeness()
	return self:GetPropertyValue(IW_PROPERTY_BEHAVIOR_COOP)
end

function CIcewrackNPCEntity:GetBehaviorSafety()
	return self:GetPropertyValue(IW_PROPERTY_BEHAVIOR_SAFETY)
end

function CIcewrackNPCEntity:GetHighestThreatTarget()
	local hHighestTarget = nil
	local fHighestThreat = -1
	for k,v in pairs(self._tThreatTable) do
		local hTarget = EntIndexToHScript(k)
		if hTarget:IsLowAttackPriority() then v = 0 end
		if not hTarget:IsAlive() or hTarget:GetTeamNumber() == self:GetTeamNumber() then
			self._tThreatTable[nEntityIndex] = nil
		elseif v > fHighestThreat and self:CanEntityBeSeenByMyTeam(hTarget) and not hTarget:IsInvulnerable() then
			hHighestTarget = hTarget
			fHighestThreat = v
		end
	end
	return hHighestTarget
end

function CIcewrackNPCEntity:GetThreatForTarget(hTarget)
	return self._tThreatTable[hTarget:entindex()] * self:GetBehaviorAggressiveness()
end

function CIcewrackNPCEntity:AddThreat(hEntity, fThreatAmount, bUseDistance)
	if not self:IsControllableByAnyPlayer() then
		if fThreatAmount > 0 and IsValidExtendedEntity(hEntity) and hEntity:GetTeamNumber() ~= self:GetTeamNumber() then
			local nEntityIndex = hEntity:entindex()
			local fThreatRadius = self._fThreatRadius
			local tThreatTable = self._tThreatTable
			local fDistance = math.min((self:GetAbsOrigin() - hEntity:GetOrigin()):Length2D(), fThreatRadius)
			local fDistanceMultiplier = bUseDistance and (0.5 * (1.0 - (fDistance/fThreatRadius))) + 0.5 or 1.0
			local fThreatMultiplier = 1.0 + self:GetPropertyValue(IW_PROPERTY_THREAT_MULTI)/100.0
			local fThreatValue = fThreatAmount * fDistanceMultiplier * fThreatMultiplier
			tThreatTable[nEntityIndex] = tThreatTable[nEntityIndex] + fThreatValue
			if self:GetBehaviorCooperativeness() >= IW_NPC_BEHAVIOR_COOP_SYNERGY then
				local fShareRadius = self._fShareRadius
				local hNearbyEntities = Entities:FindAllInSphere(self:GetAbsOrigin(), fShareRadius)
				for k,v in pairs(hNearbyEntities) do
					if v:GetTeamNumber() == self:GetTeamNumber() and v ~= self and IsValidNPCEntity(v) then
						if v:GetBehaviorCooperativeness() >= IW_NPC_BEHAVIOR_COOP_SYNERGY then
							v._tThreatTable[nEntityIndex] = v._tThreatTable[nEntityIndex] + fThreatValue * 0.25
						end
					end
				end
			end
		end
	end
end

function CIcewrackNPCEntity:IsTargetInVisionArea(target)
	if self:IsTargetInLOS(target) then
		local nVisionMask = self._nVisionMask
		local vForward = self:GetForwardVector():Normalized()
		local vTargetPos = (type(target) == "userdata") and target or target:GetAbsOrigin()
		local vTargetVector = (vTargetPos - self:GetAbsOrigin()):Normalized()
		local fCosTheta = math.min(1.0, math.max(-1.0, vForward:Dot(vTargetVector)))
		return bit32.btest(nVisionMask, bit32.lshift(1, math.floor(math.acos(fCosTheta)/0.1308996939)))
	end
	return false
end

function CIcewrackNPCEntity:IsTargetDetected(hEntity)
	if IsValidExtendedEntity(hEntity) then
		local nEntityIndex = hEntity:entindex()
		return self._tDetectTable[nEntityIndex] and self._tDetectTable[nEntityIndex] > GameRules:GetGameTime() or false
	end
	return false
end

function CIcewrackNPCEntity:DetectEntity(hEntity, fDetectTime)
	local nEntityIndex = hEntity:entindex()
	self._tDetectTable[nEntityIndex] = GameRules:GetGameTime() + fDetectTime
	hEntity:MakeVisibleToTeam(self:GetTeamNumber(), fDetectTime)
	if self:GetBehaviorAggressiveness() >= IW_NPC_BEHAVIOR_AGGRO_TERRITORIAL and not self._tThreatTable[nEntityIndex] then
		self._tThreatTable[nEntityIndex] = 10.0
	end
	if self:GetBehaviorCooperativeness() >= IW_NPC_BEHAVIOR_COOP_SOCIAL then
		local fShareRadius = self._fShareRadius
		local hNearbyEntities = Entities:FindAllInSphere(self:GetAbsOrigin(), fShareRadius)
		for k,v in pairs(hNearbyEntities) do
			if v:GetTeamNumber() == self:GetTeamNumber() and IsValidNPCEntity(v) then
				if v ~= self and v:GetBehaviorCooperativeness() >= IW_NPC_BEHAVIOR_C_SOCIAL then
					v._tDetectTable[nEntityIndex] = GameRules:GetGameTime() + fDetectTime
					if v:GetBehaviorAggressiveness() >= IW_NPC_BEHAVIOR_AGGRO_TERRITORIAL and not v._tThreatTable[nEntityIndex] then
						v._tThreatTable[nEntityIndex] = 10.0
					end
				end
			end
		end
	end
end

function CIcewrackNPCEntity:NPCThink()
	if self:GetMainControllingPlayer() ~= 0 and not GameRules:IsGamePaused() then
		local nVisionMask = self._nVisionMask
		local nVisionRange = self:GetCurrentVisionRange()
		local fVisionDetect = self._fVisionDetect
		local nDifficulty = GameRules:GetCustomGameDifficulty()
		
		local hNearbyEntities = Entities:FindAllInSphere(self:GetAbsOrigin(), nVisionRange * 2.0)
		for k,v in pairs(hNearbyEntities) do
			local hEntity = v
			if IsValidExtendedEntity(hEntity) and hEntity:GetTeamNumber() ~= self:GetTeamNumber() and self:IsTargetInVisionArea(hEntity) then
				local vTargetVector = hEntity:GetAbsOrigin() - self:GetAbsOrigin()
				local fVisionValue = hEntity:GetPropertyValue(IW_PROPERTY_VISIBILITY_FLAT) * nVisionRange/math.max(IW_NPC_VISION_DISTANCE_MIN, vTargetVector:Length2D())
				local fVisionMultiplier = 1.0 + hEntity:GetPropertyValue(IW_PROPERTY_VISIBILITY_PCT)
				if hEntity:IsMoving() then
					fVisionMultiplier = fVisionMultiplier * 2.0
				end
				fVisionValue = fVisionValue * fVisionMultiplier
				if fVisionValue > fVisionDetect or CalcDistanceBetweenEntityOBB(self, hEntity) < IW_NPC_TOUCH_RADIUS then
	DebugDrawSphere(hEntity:GetAbsOrigin(), Vector(0, 255, 0), 255, 48.0, true, 0.1)
					self:DetectEntity(hEntity, stNPCDetectionTime[nDifficulty])
				end
			end
		end
		
		for k,v in pairs(self._tThreatTable) do
			if v < 1 then
				self._tThreatTable[k] = 1
			else
				self._tThreatTable[k] = v * stNPCThreatDecayRate[nDifficulty]
			end
		end
	end
	return 0.1
end

local function ClearNoisePoint(self, nIndex)
	self._tNoiseTable[nIndex] = nil
end

function CIcewrackNPCEntity:AddNoiseEvent(hEntity, vNoiseOrigin, fNoiseValue, bNoDetect)
	if self:GetTeamNumber() ~= hEntity:GetTeamNumber() then
		local fNoiseThreshold = self._fNoiseThreshold
		local fNoiseDetect = self._fNoiseDetect
		local fNoiseValue = fNoiseValue/math.pow(math.max(1, (vNoiseOrigin - self:GetAbsOrigin()):Length2D()/100), 2)
		
		local tNoiseTable = self._tNoiseTable
		local fNearbyNoiseSum = 0
		local nNearbyNoiseCount = 0
		for k,v in pairs(tNoiseTable) do
			local x = (v.origin - vNoiseOrigin):Length2D()/v.speed
			local dt = math.max(IW_NPC_NOISE_TIME_MIN, GameRules:GetGameTime() - v.time)
			fNearbyNoiseSum = fNearbyNoiseSum + v.value * math.exp((-6*(x*x))/(dt*dt))/math.sqrt(1.57079632679*dt*dt)
			nNearbyNoiseCount = nNearbyNoiseCount + 1
		end
		if nNearbyNoiseCount > 0 then
			fNoiseValue = fNoiseValue + math.max(0.0, fNearbyNoiseSum * 0.1)
		end
		local fNoiseMultiplier = math.max(0, 1.0 + hEntity:GetPropertyValue(IW_PROPERTY_MOVE_NOISE_PCT)/100)
		fNoiseValue = fNoiseValue * fNoiseMultiplier
	
		local nNoiseTableIndex = self._nNoiseTableIndex
		local fEntityMoveSpeed = hEntity:GetMoveSpeedModifier(hEntity:GetBaseMoveSpeed()) * 0.25
		local fNoiseDuration = math.min(stNPCDetectionTime[GameRules:GetCustomGameDifficulty()] * 5, math.max(IW_NPC_NOISE_TIME_MIN, 0.7978845608 * fNoiseValue/fNoiseThreshold))
		tNoiseTable[nNoiseTableIndex] =
		{
			value    = fNoiseValue,
			origin   = vNoiseOrigin,
			speed    = fEntityMoveSpeed,	
			time     = GameRules:GetGameTime(),
			duration = fNoiseDuration,
		}
		self._nNoiseTableIndex = nNoiseTableIndex + 1
		CTimer(fNoiseDuration, ClearNoisePoint, self, nNoiseTableIndex)
		
		if fNoiseValue > fNoiseDetect and not bNoDetect then
			self:DetectEntity(hEntity, stNPCDetectionTime[GameRules:GetCustomGameDifficulty()])
		end
	end
end

local function EvaluateAttackTargetDesire(self)
	local hAttackTarget = nil
	local fHighestThreat = 0
	local nAggressiveness = self:GetBehaviorAggressiveness()
	local fAvoidanceWeight = stNPCAvoidanceWeight[self:GetBehaviorSafety()]
	local tAvoidanceZones = Entities:FindAllByNameWithin("npc_dota_base_additive", self:GetAbsOrigin(), self:GetCurrentVisionRange())
	for k,v in pairs(tAvoidanceZones) do
		if not self:IsTargetInLOS(v) then
			tAvoidanceZones[k] = nil
		end
	end
	if nAggressiveness >= IW_NPC_BEHAVIOR_AGGRO_DEFENSIVE then
		local fThreatRadius = self._fThreatRadius
		local fCurrentTime = GameRules:GetGameTime()
		for k,v in pairs(self._tDetectTable) do
			if v >= fCurrentTime then
				local hTarget = EntIndexToHScript(k)
				if hTarget then
					local fTargetThreat = self:GetThreatForTarget(hTarget) + 100.0
					if nAggressiveness <= IW_NPC_BEHAVIOR_AGGRO_TERRITORIAL and (hTarget:GetAbsOrigin() - self._vInitialPos):Length2D() > fThreatRadius then
						fTargetThreat = 0
					end
					for k2,v2 in pairs(tAvoidanceZones) do
						if (hTarget:GetAbsOrigin() - v2:GetAbsOrigin()):Length2D() <= v2._fAvoidanceRadius then
							fTargetThreat = fTargetThreat - (v2._fAvoidanceValue * fAvoidanceWeight)
						end
					end
					if fTargetThreat > fHighestThreat then
						fHighestThreat = fTargetThreat
						hAttackTarget = hTarget
					end
				end
			end
		end
	end
	return fHighestThreat, hAttackTarget
end

local function OnAttackTarget(self, hTarget)
	self:SetAttacking(hTarget)
	if self:IsTargetInLOS(hTarget) then
		hTarget:MakeVisibleToTeam(self:GetTeamNumber(), 0.1)
		self:IssueOrder(DOTA_UNIT_ORDER_ATTACK_TARGET, hTarget, nil, nil, false)
	else
		self:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, nil, hTarget:GetAbsOrigin(), false)
	end
end

local function EvaluateInvestigateNoiseDesire(self)
	local fMaxNoiseValue = 0
	local tMaxNoisePoint = nil
	local nAggressiveness = self:GetPropertyValue(IW_PROPERTY_BEHAVIOR_AGGRO)
	if nAggressiveness >= IW_NPC_BEHAVIOR_AGGRO_TERRITORIAL then
		local fThreatRadius = self._fThreatRadius
		local tNoiseTable = self._tNoiseTable
		for k,v in pairs(tNoiseTable) do
			local dt = math.max(IW_NPC_NOISE_TIME_MIN, GameRules:GetGameTime() - v.time)
			local fNoiseValue = v.value/math.sqrt(1.57079632679*dt*dt)
			if fNoiseValue > fMaxNoiseValue and fNoiseValue >= self._fNoiseThreshold then
				if nAggressiveness == IW_NPC_BEHAVIOR_AGGRO_AGGRESSIVE or (v.origin - self._vInitialPos):Length2D() <= fThreatRadius then
					fMaxNoiseValue = fNoiseValue
					tMaxNoisePoint = v
				end
			end
		end
	end
	return fMaxNoiseValue, tMaxNoisePoint
end

local function OnInvestigateNoise(self, tNoisePoint)
	local fInvestigateRange = self:GetCurrentVisionRange() * 0.5
	local vNoiseOrigin = tNoisePoint.origin
	local vInvestigatePos = self._vInvestigatePos
	local vLastNoiseOrigin = self._vLastNoiseOrigin
	if vNoiseOrigin ~= vLastNoiseOrigin or (self:IsTargetInVisionArea(vInvestigatePos) and (vInvestigatePos - self:GetAbsOrigin()):Length2D() <= fInvestigateRange) then
		for i=1,100 do
			local fSearchRadius = tNoisePoint.speed * (GameRules:GetGameTime() - tNoisePoint.time)
			local vTargetPos = vNoiseOrigin
			if vInvestigatePos then
				local vCurrentVector = (vInvestigatePos - vNoiseOrigin):Normalized()
				local vTargetVector = (RandomVector(1.0) + vCurrentVector):Normalized()
				vTargetPos = vTargetPos + vTargetVector * fSearchRadius
			else
				vTargetPos = vTargetPos + RandomVector(fSearchRadius)
			end
			
			if GridNav:IsTraversable(vTargetPos) then
				self:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, nil, vTargetPos, false)
				self._vInvestigatePos = vTargetPos
				self._vLastNoiseOrigin = vNoiseOrigin
				break
			end
		end
	end
end

local function EvaluateFleeFromEnemiesDesire(self)
	if self:GetHealth()/self:GetMaxHealth() < stNPCFleeThreshold[self:GetBehaviorSafety()] then
		return 100000.0
	end
	return 0
end

local function OnFleeFromEnemies(self)
	local fCurrentTime = GameRules:GetGameTime()
	local vSelfPosition = self:GetAbsOrigin()
	local vNetDirection = Vector(0, 0, 0)
	for k,v in pairs(self._tDetectTable) do
		if v >= fCurrentTime then
			local hTarget = EntIndexToHScript(k)
			if hTarget then
				local vTargetVector = vSelfPosition - hTarget:GetAbsOrigin()
				local fTargetDistance = vTargetVector:Length2D()
				vNetDirection = vNetDirection + vTargetVector/(fTargetDistance * fTargetDistance)
			end
		end
	end
	vNetDirection.z = 0
	vNetDirection = vNetDirection:Normalized()
	
	if not self._fMoveLockTime or GameRules:GetGameTime() >= self._fMoveLockTime then
		local fMoveDistance = self:GetHullRadius() + 128.0
		local fMoveSpeed = self:GetMoveSpeedModifier(self:GetBaseMoveSpeed())
		local vMovePosition = GetGroundPosition(vSelfPosition + (vNetDirection * fMoveDistance), self)
		DebugDrawSphere(vMovePosition, Vector(255, 0, 0), 128.0, 32.0, true, 0.1)
		if not GridNav:IsTraversable(vMovePosition) or not GridNav:CanFindPath(vSelfPosition, vMovePosition) then
			local x,y = vNetDirection.x, vNetDirection.y
			for i=2,21 do
				local a = math.floor(i/2) * 0.1308996939 * (((i % 2) * 2) - 1)
				local x2 = x * math.cos(a) - y * math.sin(a)
				local y2 = x * math.sin(a) + y * math.cos(a)
				local v = vSelfPosition + (Vector(x2, y2, 0) * fMoveDistance)
				if GridNav:IsTraversable(v) and GridNav:CanFindPath(vSelfPosition, v) then
					self._fMoveLockTime = GameRules:GetGameTime() + GridNav:FindPathLength(vSelfPosition, v)/fMoveSpeed
					self:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, nil, v, false)
					return
				end
			end
			
			local hNearestAttackingEntity = nil
			local fNearestDistance = nil
			for k,v in pairs(self._tAttackedByTable) do
				local hEntity = EntIndexToHScript(k)
				if hEntity and self._tDetectTable[k] and self._tDetectTable[k] >= fCurrentTime then
					local fDistance = hEntity:GetAbsOrigin() - self:GetAbsOrigin()
					if not fNearestDistance or fDistance < fNearestDistance then
						fNearestDistance = fDistance
						hNearestAttackingEntity = hEntity
					end
				end
			end
			
			if hNearestAttackingEntity then
				local vMaxPosition = nil
				local fMaxDistance = 0
				for i=-5,5 do
					for j=-5,5 do
						local v = vSelfPosition + Vector(i*128, j*128, 0)
						if GridNav:IsTraversable(v) then
							local fDistance = GridNav:FindPathLength(hNearestAttackingEntity:GetAbsOrigin(), v)
							if fDistance > fMaxDistance then
								fMaxDistance = fDistance
								vMaxPosition = v
							end
						end
					end
				end
				if vMaxPosition then
					self._fMoveLockTime = GameRules:GetGameTime() + GridNav:FindPathLength(vSelfPosition, vMaxPosition)/fMoveSpeed
					self:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, nil, vMaxPosition, false)
				end
			end
		else
			self:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, nil, vMovePosition, false)
			self._fMoveLockTime = GameRules:GetGameTime() + fMoveDistance/fMoveSpeed
		end
	end
end

local function EvaluateFleeAvoidanceZoneDesire(self)
	local fMaxAvoidanceValue = 0
	local hMaxAvoidanceZone = nil

	local tAvoidanceZones = Entities:FindAllByNameWithin("npc_dota_base_additive", self:GetAbsOrigin(), self:GetCurrentVisionRange())
	for k,v in pairs(tAvoidanceZones) do
		if self:IsTargetInLOS(v) then
			local fDistance = (self:GetAbsOrigin() - v:GetAbsOrigin()):Length2D()
			local fAvoidanceRadius = v._fAvoidanceRadius or 0.0
			local fAvoidanceValue = v._fAvoidanceValue or 0.0
			if fDistance <= fAvoidanceRadius and fAvoidanceValue > fMaxAvoidanceValue then
				fMaxAvoidanceValue = fAvoidanceValue
				hMaxAvoidanceZone = v
			elseif fDistance <= fAvoidanceRadius + 64.0 and fAvoidanceValue * 0.1 > fMaxAvoidanceValue then
				fMaxAvoidanceValue = fAvoidanceValue * 0.1
				hMaxAvoidanceZone = v
			end
		end
	end
	return fMaxAvoidanceValue * stNPCAvoidanceWeight[self:GetBehaviorSafety()], hMaxAvoidanceZone
end

local function OnFleeAvoidanceZone(self)
	local vSelfPosition = self:GetAbsOrigin()
	local vNetDirection = Vector(0, 0, 0)
	
	local tAvoidanceZones = Entities:FindAllByNameWithin("npc_dota_base_additive", self:GetAbsOrigin(), self:GetCurrentVisionRange())
	for k,v in pairs(tAvoidanceZones) do
		if not self:IsTargetInLOS(v) then
			tAvoidanceZones[k] = nil
		end
	end
	
	for k,v in pairs(tAvoidanceZones) do
		local vTargetVector = vSelfPosition - v:GetAbsOrigin()
		local fTargetDistance = vTargetVector:Length2D()
		if fTargetDistance <= v._fAvoidanceRadius then
			vNetDirection = vNetDirection + (vTargetVector:Normalized() * v._fAvoidanceValue)
		end
	end
	vNetDirection.z = 0
	vNetDirection = vNetDirection:Normalized()
	
	if not self._fMoveLockTime or GameRules:GetGameTime() >= self._fMoveLockTime then
		local fMoveDistance = self:GetHullRadius() + 128.0
		local fMoveSpeed = self:GetMoveSpeedModifier(self:GetBaseMoveSpeed())
		local vMovePosition = GetGroundPosition(vSelfPosition + (vNetDirection * fMoveDistance), self)
		DebugDrawSphere(vMovePosition, Vector(255, 0, 0), 128.0, 32.0, true, 0.1)
		if not GridNav:IsTraversable(vMovePosition) or not GridNav:CanFindPath(vSelfPosition, vMovePosition) then
			local x,y = vNetDirection.x, vNetDirection.y
			for i=2,21 do
				local a = math.floor(i/2) * 0.1308996939 * (((i % 2) * 2) - 1)
				local x2 = x * math.cos(a) - y * math.sin(a)
				local y2 = x * math.sin(a) + y * math.cos(a)
				local v = vSelfPosition + (Vector(x2, y2, 0) * fMoveDistance)
				if GridNav:IsTraversable(v) and GridNav:CanFindPath(vSelfPosition, v) then
					self._fMoveLockTime = GameRules:GetGameTime() + GridNav:FindPathLength(vSelfPosition, v)/fMoveSpeed
					self:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, nil, v, false)
					return
				end
			end
			
			local vMinPosition = nil
			local fMinDistance = 999999.9
			for i=-5,5 do
				for j=-5,5 do
					local vTargetPosition = vSelfPosition + Vector(i*128, j*128, 0)
					if GridNav:IsTraversable(vTargetPosition) then
						local bIsInAvoidanceZone = false
						for k,v in pairs(tAvoidanceZones) do
							local fTargetDistance = (vTargetPosition - v:GetAbsOrigin()):Length2D()
							if fTargetDistance <= v._fAvoidanceRadius then
								bIsInAvoidanceZone = true
								break
							end
						end
						if not bIsInAvoidanceZone then
							local fDistance = GridNav:FindPathLength(vSelfPosition, vTargetPosition)
							if GridNav:CanFindPath(vSelfPosition, vTargetPosition) and fDistance < fMinDistance then
								fMinDistance = fDistance
								vMinPosition = vTargetPosition
							end
						end
					end
				end
			end
				
			if vMinPosition then
				self._fMoveLockTime = GameRules:GetGameTime() + GridNav:FindPathLength(vSelfPosition, vMinPosition)/fMoveSpeed
				self:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, nil, vMinPosition, false)
			end
		else
			self:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, nil, vMovePosition, false)
			self._fMoveLockTime = GameRules:GetGameTime() + fMoveDistance/fMoveSpeed
		end
	end
end

local function EvaluateNPCMovementDesire(self)
	local fCurrentTime = GameRules:GetGameTime()
	--[[for k,v in pairs(self._tDetectTable) do
		if v >= fCurrentTime then
			return 0.0
		end
	end]]
	return 1.0
end

local function OnNPCMovement(self)
	local fCurrentTime = GameRules:GetGameTime()
	local fMoveLockTime = self._fMoveLockTime or 0
	if fCurrentTime >= fMoveLockTime and fCurrentTime >= self._fWaypointTime then
		local nLastWaypointID = self._nLastWaypoint
		local nNextWaypointID = self._nNextWaypoint
		local hWaypoint = CIcewrackNPCWaypoints[nNextWaypointID]
		if hWaypoint then
			if (self:GetAbsOrigin() - hWaypoint._vPosition):Length2D() < hWaypoint._fRadius then
				local fDestinationSum = hWaypoint._tDestinationSums[nLastWaypointID]
				if fDestinationSum then
					local fDestinationValue = RandomFloat(0.0, fDestinationSum)
					for k,v in pairs(hWaypoint._tDestinations[nLastWaypointID]) do
						if v >= fDestinationValue then
							self._nLastWaypoint = nNextWaypointID
							self._nNextWaypoint = k
							self._fWaypointTime = fCurrentTime + RandomFloat(hWaypoint._fWaitMin, hWaypoint._fWaitMax)
							break
						else
							fDestinationValue = fDestinationValue - v
						end
					end
				end
			else
				self:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, nil, hWaypoint._vPosition, false)
				self._fMoveLockTime = fCurrentTime + 0.1
			end
		else
			local fDistance = (self:GetAbsOrigin() - self._vInitialPos):Length2D()
			if fDistance > 64.0 then
				self:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, nil, self._vInitialPos, false)
				self._fMoveLockTime = fCurrentTime + 0.1
			end
		end
	end
end

local stNPCActionTable =
{
	[EvaluateAttackTargetDesire] = OnAttackTarget,
	[EvaluateInvestigateNoiseDesire] = OnInvestigateNoise,
	[EvaluateFleeFromEnemiesDesire] = OnFleeFromEnemies,
	[EvaluateFleeAvoidanceZoneDesire] = OnFleeAvoidanceZone,
	[EvaluateNPCMovementDesire] = OnNPCMovement,
}

function CIcewrackNPCEntity:OnNPCThink()
	if self:GetMainControllingPlayer() ~= 0 then
		local hBestAction = nil
		local hActionTarget = nil
		local fBestDesire = 0
		for k,v in pairs(stNPCActionTable) do
			local fDesireValue,hTarget = k(self)
			if fDesireValue > fBestDesire then
				fBestDesire = fDesireValue
				hActionTarget = hTarget
				hBestAction = v
			end
		end
		if hBestAction and fBestDesire > 0 then
			hBestAction(self, hActionTarget)
			return true
		end
	end
end

function IsValidNPCEntity(hEntity)
    return (IsValidExtendedEntity(hEntity) and hEntity._bIsNPCEntity == true)
end

end