if not GameRules.CombatState then

require("timer")

IW_COMBAT_LINGER_TIME = 5.0

GameRules.CombatState = false
GameRules.IsInCombat = function() return GameRules.CombatState end

local nCombatEventID = 0
local stCombatEventTable = {}
local stCombatNetTable = { State = false }
local nCombatParticleID = nil

local function ClearCombatEvent(nEventID)
	stCombatEventTable[nEventID] = nil
	GameRules.CombatState = (next(stCombatEventTable) ~= nil)
	if not GameRules.CombatState then
		stCombatNetTable.State = GameRules.CombatState
		CustomNetTables:SetTableValue("game", "Combat", stCombatNetTable)
	end
end

function TriggerCombatEvent(fDuration)
	if not fDuration then fDuration = IW_COMBAT_LINGER_TIME end
	if not GameRules.CombatState then
		GameRules.CombatState = true
		stCombatNetTable.State = GameRules.CombatState
		CustomNetTables:SetTableValue("game", "Combat", stCombatNetTable)
	end
	stCombatEventTable[nCombatEventID] = true
	CTimer(fDuration, ClearCombatEvent, nCombatEventID)
	nCombatEventID = nCombatEventID + 1
end

CustomNetTables:SetTableValue("game", "Combat", stCombatNetTable)

end
