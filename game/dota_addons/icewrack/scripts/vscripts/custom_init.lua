ICEWRACK_GAME_MODE_ID = 538255698
for k in string.gmatch(package.path, "[%w/\\.: _?()]+") do
	if string.find(k, "common\\dota 2 beta\\game\\bin\\win64\\lua\\%?.lua") ~= nil then
		ICEWRACK_GAME_DIR = string.gsub(k, "common\\dota 2 beta\\game\\bin\\win64\\lua\\%?.lua", "workshop\\content\\570\\" .. ICEWRACK_GAME_MODE_ID .. "\\")
		break
	end
end
if not ICEWRACK_GAME_DIR then
	error("Unable to find Icewrack game directory")
end

for k,v in pairs(dofile("log_manager")) do _G[k] = v end
require("constants")

stZeroDefaultMetatable = { __index = function(self, k) return 0 end }

function GetFlagValue(szFlagString, tEnumTable)
	local nFlagValue = 0
	for k in string.gmatch(szFlagString or "", "[%w_]+") do
		if tEnumTable[k] then
			nFlagValue = nFlagValue + tEnumTable[k]
		end
	end
	return nFlagValue
end

function GetBitshiftedFlagValue(szFlagString, tEnumTable)
	local nFlagValue = 0
	for k in string.gmatch(szFlagString or "", "[%w_]+") do
		if tEnumTable[k] then
			nFlagValue = nFlagValue + bit32.lshift(1, tEnumTable[k] - 1)
		end
	end
	return nFlagValue
end

function StringToVector(szString)
	if szString then
		local _,_,x,y,z = string.find(szString, "([^%s]+) ([^%s]+) ([^%s]+)")
		x = tonumber(x)
		y = tonumber(y)
		z = tonumber(z)
		if x and y and z then
			return Vector(x,y,z)
		end
	end
	return nil
end

local tExtClassList = {}
function ext_class(class)
	if type(class) == "table" and not tExtClassList[class] then
		tExtClassList[class] = {}
		return class
	end
end

local function BuildIndexTable(tObject, ...)
	local tObjectMetatable = getmetatable(tObject)
	local tBaseIndexTable = setmetatable({}, { __index = tObjectMetatable and tObjectMetatable.__index or {} } )
	local tExtendedClasses = {...}
	for k,v in pairs(tExtendedClasses) do
		if type(v) == "table" then
			for k2,v2 in pairs(v) do
				if type(v2) == "function" then
					tBaseIndexTable[k2] = v2
				end
			end
		end
	end
	return { __index = tBaseIndexTable }
end

function ExtendIndexTable(tObject, class, ...)
	local tClassIndexTableList = tExtClassList[class]
	if tClassIndexTableList then
		local tBaseIndexTable = getmetatable(tObject).__index
		local tExtIndexTable = tClassIndexTableList[tBaseIndexTable]
		if not tExtIndexTable then
			tExtIndexTable = BuildIndexTable(tObject, ..., class)
			tClassIndexTableList[tBaseIndexTable] = tExtIndexTable
		end
		setmetatable(tObject, tExtIndexTable)
		return tExtIndexTable
	end
end

function IsInstanceOf(tObject, class)
	local tObjectMetatable = getmetatable(tObject)
	if type(tObjectMetatable) == "table" and class then
		local tTargetMetatable = getmetatable(tObject).__index
		while tTargetMetatable do
			local tClassIndexTableList = tExtClassList[class]
			if tClassIndexTableList then
				for k,v in pairs(tClassIndexTableList) do
					if tTargetMetatable == v.__index then
						return true
					end
				end
			elseif tTargetMetatable == class then
				return true
			end
			tObjectMetatable = getmetatable(tTargetMetatable)
			tTargetMetatable = tObjectMetatable and tObjectMetatable.__index
		end
	end
	return false
end

function CreateDummyUnit(vPosition, hOwner, nTeamNumber)
	local hDummy = CreateUnitByName("npc_iw_generic_dummy", vPosition, false, hOwner, hOwner, nTeamNumber)
	hDummy:AddAbility("internal_dummy_buff")
	hDummy:FindAbilityByName("internal_dummy_buff"):ApplyDataDrivenModifier(hDummy, hDummy, "modifier_internal_dummy_buff", {})
	hDummy:RemoveAbility("internal_dummy_buff")
	return hDummy
end

function CreateAvoidanceZone(vPosition, fRadius, fValue, fDuration)
	local hDummy = CreateUnitByName("npc_iw_avoidance_zone", vPosition, false, nil, nil, DOTA_TEAM_GOODGUYS)
	hDummy:AddAbility("internal_dummy_buff")
	hDummy:FindAbilityByName("internal_dummy_buff"):ApplyDataDrivenModifier(hDummy, hDummy, "modifier_internal_dummy_buff", {})
	hDummy:RemoveAbility("internal_dummy_buff")
	hDummy._fAvoidanceRadius = fRadius
	hDummy._fAvoidanceValue = fValue
	hDummy:SetThink(function() if not hDummy:IsNull() then hDummy:RemoveSelf() end end, "RemoveAvoidanceZone", fDuration)
	return hDummy

end

return getfenv()