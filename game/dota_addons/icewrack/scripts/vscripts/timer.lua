--[[
    Timers
]]

if IsServer() then

TIMER_THINK_INTERVAL = 0.03

--Full unpack, including nil values
local function funpack(tArgs, nDepth)
	if not nDepth then nDepth = 1 end
	local nMaxDepth = 0
	for k,v in pairs(tArgs) do
		if k > nMaxDepth then nMaxDepth = k end
	end
	if nDepth <= nMaxDepth then
		return tArgs[nDepth], funpack(tArgs, nDepth + 1)
	end
end

if not CTimer then

CTimer = class({constructor = function(self, fDelay, hCallback, ...)
	if not hCallback or type(hCallback) ~= "function" then
		error("[CTimer]: <hCallback> is not a valid function")
	end
	
	self._bIsPaused = false
	self._bIsStopped = false
	
	self._fThinkTime = GameRules:GetGameTime() + fDelay
	self._fPauseTime = 0
	
	self._hCallback = hCallback
	self._tCallbackArgs = {...}

	table.insert(CTimer._tTimerList, self)
	
	return self
end},
{ _tTimerList = {},
  _shCurrentTimer = nil,
  _hTimerDummy = nil }, nil)
  
CTimer._hTimerDummy = CreateUnitByName("npc_dota_thinker", Vector(0, 0, 0), false, nil, nil, 0)
if IsValidEntity(CTimer._hTimerDummy) then
	CTimer._hTimerDummy:AddAbility("internal_dummy_buff")
	CTimer._hTimerDummy:FindAbilityByName("internal_dummy_buff"):ApplyDataDrivenModifier(CTimer._hTimerDummy, CTimer._hTimerDummy, "modifier_internal_dummy_buff", {})
	CTimer._hTimerDummy:SetThink(function()
		local fThinkTime = GameRules:GetGameTime()
		for k,v in pairs(CTimer._tTimerList) do
			if not v._bIsPaused then
				if fThinkTime >= v._fThinkTime then
					local bStatus, fValue = pcall(v._hCallback, funpack(v._tCallbackArgs))
					if not bStatus then
						error("[CTimer]: <hCallback> failed for the arguments provided. Error:\n" .. fValue)
					end
					if not fValue or type(fValue) ~= "number" or fValue <= 0 then
						v._tCallbackArgs = nil
						v._hCallback = nil
						CTimer._tTimerList[k] = nil
					else
						v._fThinkTime = v._fThinkTime + fValue
					end
				end
			end
		end
		return TIMER_THINK_INTERVAL
	end, "TimerThink", TIMER_THINK_INTERVAL)
end

function CTimer:PauseTimer()
	if not self._bIsPaused then
		self._bIsPaused = true
		self._fPauseTime = self._bUseRealTime and Time() or GameRules:GetGameTime()
	end
end

function CTimer:UnpauseTimer()
	if self._bIsPaused then
		self._bIsPaused = false
		local fCurrentTime = self._bUseRealTime and Time() or GameRules:GetGameTime()
		self._fStartTime = self._fStartTime + (fCurrentTime - fPauseTime)
	end
end

function CTimer:ResetTimer(fDelay)
	self._fStartTime = (self._bUseRealTime and Time() or GameRules:GetGameTime()) + fDelay
end

function ClearTimers()
    CTimer._tTimerList = {}
end

end

end