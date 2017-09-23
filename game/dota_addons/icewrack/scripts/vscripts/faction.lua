--[[
    Icewrack Factions
]]


--TODO: Add save/load functionality for factions so that their relationships can change throughout the course of the game

if not CFaction then

CFaction =
{
	_tFactionList = {}
}

local stFactionData = LoadKeyValues("scripts/npc/iw_faction_list.txt")

for k,v in pairs(stFactionData) do
	local nFactionID = tonumber(k)
	if nFactionID then
		local fDefaultWeight = tonumber(v.WeightDefault)
		CFaction._tFactionList[nFactionID] =
		{
			_szName = v.Name,
			_tFactionWeights = setmetatable({}, { __index = function(self, k) return fDefaultWeight end})
		}
	end
end

--Load the override weights after we load all of the factions to ensure that the data is valid
for k,v in pairs(stFactionData) do
	local nFactionID = tonumber(k)
	if nFactionID then
		local tFactionData = CFaction._tFactionList[nFactionID]
		for k2,v2 in pairs(v.WeightOverride or {}) do
			local nTargetFactionID = tonumber(k2)
			if CFaction._tFactionList[nTargetFactionID] and type(v2) == "number" then
				tFactionData._tFactionWeights[nTargetFactionID] = v2
			end
		end
	end
end

function CFaction:GetFactionWeight(nFactionID1, nFactionID2)
	local tFaction1 = CFaction._tFactionList[nFactionID1]
	local tFaction2 = CFaction._tFactionList[nFactionID2]
	if tFaction1 and tFaction2 then
		if nFactionID1 == nFactionID2 then
			return 100.0
		end
		return math.min(tFaction1._tFactionWeights[nFactionID2], tFaction2._tFactionWeights[nFactionID1])
	end
end

end