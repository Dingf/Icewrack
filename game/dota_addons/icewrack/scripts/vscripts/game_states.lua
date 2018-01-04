--[[
	Icewrack Game States
]]

--Game states are variables used to keep track of quests and dialogue

if not GameRules.GetGameState then

local stGameStateData = LoadKeyValues("scripts/npc/iw_game_states.txt")
local stGameStateValues = {}
local stModifiedGameStateValues = {}	--This records the game states that have been changed so that we don't need to save all of them

local function ParseGameStateKeyValues(tKeyValues, szPrefix)
	for k,v in pairs(tKeyValues) do
		local szKeyName = szPrefix and (szPrefix .. "." .. k) or k
		if type(v) == "table" then
			ParseGameStateKeyValues(v, szKeyName)
		elseif type(v) == "number" then
			stGameStateValues[szKeyName] = v
		end
	end
end

function GameRules:GetGameState(szName)
	return stGameStateValues[szName]
end

function GameRules:SetGameState(szName, nValue)
	if stGameStateValues[szName] and type(nValue) == "number" then
		stGameStateValues[szName] = nValue
		stModifiedGameStateValues[szName] = nValue
	end
end

function GameRules:GetModifiedGameStates()
	return stModifiedGameStateValues
end

ParseGameStateKeyValues(stGameStateData)

end