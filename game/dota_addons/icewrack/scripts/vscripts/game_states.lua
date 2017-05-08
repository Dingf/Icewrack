--[[
	Icewrack Game States
]]

--Game states are variables used to keep track of quests and dialogue

if not CGameState then CGameState = {} end

local function ParseGameStateKeyValues(tKeyValues, szPrefix)
	for k,v in pairs(tKeyValues) do
		local szKeyName = szPrefix and (szPrefix .. "." .. k) or k
		if type(v) == "table" then
			ParseGameStateKeyValues(v, szKeyName)
		elseif type(v) == "number" then
			CGameState._tValues[szKeyName] = v
		end
	end
end

if next(CGameState) == nil then
	local stGameStateData = LoadKeyValues("scripts/npc/iw_game_states.txt")
	CGameState._tValues = {}
	CGameState._tChangedValues = {}
	ParseGameStateKeyValues(stGameStateData)
end

function CGameState:GetGameStateValue(szName)
	return CGameState._tValues[szName]
end

function CGameState:SetGameStateValue(szName, nValue)
	if type(szName) == "string" and CGameState._tValues[szName] then
		CGameState._tValues[szName] = nValue
		CGameState._tChangedValues[szName] = nValue
		return nValue
	end
end