--[[
    Icewrack Avoidance Zones
]]

require("timer")

CAvoidanceZone = setmetatable({ _stZoneList = {}, _snLastIndex = 1 },  { __call = 
	function(self, vPosition, fRadius, fValue, fDuration)
		LogAssert(type(vPosition) == "userdata", LOG_MESSAGE_ASSERT_TYPE, "vector")
		LogAssert(type(fRadius) == "number", LOG_MESSAGE_ASSERT_TYPE, "number")
		LogAssert(type(fValue) == "number", LOG_MESSAGE_ASSERT_TYPE, "number")
		
		self = setmetatable({}, {__index = CAvoidanceZone})
		
		local nIndex = CAvoidanceZone._snLastIndex
		self._nIndex = nIndex
		self._vPosition = vPosition
		self._fRadius = fRadius
		self._fValue = fValue
		
		if type(fDuration) == "number" then
			CTimer(fDuration, CAvoidanceZone.RemoveSelf, self)
		end
		
		CAvoidanceZone._stZoneList[nIndex] = self
		CAvoidanceZone._snLastIndex = nIndex + 1
		
		return self
	end})
	
function CAvoidanceZone:GetAvoidanceZones()
	return CAvoidanceZone._stZoneList
end

function CAvoidanceZone:GetOrigin()
	return self._vPosition
end

function CAvoidanceZone:GetRadius()
	return self._fRadius
end

function CAvoidanceZone:GetAvoidanceValue()
	return self._fValue
end

function CAvoidanceZone:IsTargetInZone(vTargetPosition)
	local fTargetDistance = (vTargetPosition - self:GetOrigin()):Length2D()
	return fTargetDistance <= self:GetRadius()
end

function CAvoidanceZone:RemoveSelf()
	CAvoidanceZone._stZoneList[self._nIndex] = nil
end
