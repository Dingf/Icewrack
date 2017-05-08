if not CLootList then

require("expression")
require("ext_item")

local stLootTableData = LoadKeyValues("scripts/npc/iw_loot_tables.txt")
local stLootListData = LoadKeyValues("scripts/npc/iw_loot_lists.txt")

CLootList = setmetatable({}, { __call =
	function(self, szLootTableName)
		return stLootListData[szLootTableName]
	end})

for k,v in pairs(stLootListData) do
	setmetatable(v, {__index = CLootList})
	for k2,v2 in pairs(v) do
		v2.Chance = tonumber(v2.Chance) and tonumber(v2.Chance)/100.0 or 0.0
		v2.Precondition = CExpression(v2.Precondition)
		v2.LootList = stLootTableData[v2.LootList] or {}
	end
end

function CLootList:GenerateLootList()
	local tLootList = {}
	for k,v in pairs(self) do
		if RandomFloat(0.0, 1.0) < v.Chance and v.Precondition:EvaluateExpression() then
			local nWeightSum = 0
			for k2,v2 in pairs(v.LootList) do
				nWeightSum = nWeightSum + v2.Weight
			end
			local fRoll = RandomFloat(0.0, nWeightSum)
			for k2,v2 in pairs(v.LootList) do
				fRoll = fRoll - v2.Weight
				if fRoll <= 0 then
					local hItem = CExtItem(CreateItem(k2, nil, nil))
					hItem:SetStackCount(RandomInt(v2.Min, v2.Max))
					table.insert(tLootList, hItem)
					break
				end
			end
		end
	end
	return tLootList
end

end