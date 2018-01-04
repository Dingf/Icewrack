--[[
    Icewrack LOS Blocker Zones
]]

require("timer")

CLOSBlockerZone = setmetatable({ _stZoneList = {}, _snLastIndex = 1 },  { __call = 
	function(self, vPosition, fRadius, fDuration)
		LogAssert(type(vPosition) == "userdata", LOG_MESSAGE_ASSERT_TYPE, "vector")
		LogAssert(type(fRadius) == "number", LOG_MESSAGE_ASSERT_TYPE, "number")
		
		self = setmetatable({}, {__index = CLOSBlockerZone})
		
		local nIndex = CLOSBlockerZone._snLastIndex
		self._nIndex = nIndex
		self._vPosition = vPosition
		self._fRadius = fRadius
		self._fValue = fValue
		
		if type(fDuration) == "number" then
			CTimer(fDuration, CLOSBlockerZone.RemoveSelf, self)
		end
		
		CLOSBlockerZone._stZoneList[nIndex] = self
		CLOSBlockerZone._snLastIndex = nIndex + 1
		
		return self
	end})
	
function CLOSBlockerZone:GetLOSBlockerZones()
	return CLOSBlockerZone._stZoneList
end

function CLOSBlockerZone:GetOrigin()
	return self._vPosition
end

function CLOSBlockerZone:GetRadius()
	return self._fRadius
end

function CLOSBlockerZone:IsTargetInZone(vTargetPosition)
	local fTargetDistance = (vTargetPosition - self:GetOrigin()):Length2D()
	return fTargetDistance <= self:GetRadius()
end

function CLOSBlockerZone:RemoveSelf()
	CLOSBlockerZone._stZoneList[self._nIndex] = nil
end