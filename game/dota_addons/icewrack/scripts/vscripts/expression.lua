--[[
    Icewrack Expressions
]]

if not CExpression then

require("instance")
require("game_states")

local function GetWordValue(nIndex, bUseLiteral)
	local hLastExpression = CExpression._hCallStack[#CExpression._hCallStack]
	if hLastExpression then
		local value = hLastExpression[nIndex]
		if IsInstanceOf(value, CExpression) then
			return value:EvaluateExpression()
		elseif type(value) == "string" and not bUseLiteral then
			return CGameState:GetGameStateValue(value)
		else
			return value
		end
	end
end

local stOperatorListTier1 = 
{
	["!"]  = function(nIndex1) return not GetWordValue(nIndex1) end,
	["-"]  = function(nIndex1, nIndex2) if type(GetWordValue(nIndex2)) ~= "number" then return -GetWordValue(nIndex1) else return nil end end,
	["->"] = function(nIndex1, nIndex2, hInstance) if hInstance then return hInstance:GetPropertyValue(nIndex1) or false else return false end end
}

local stOperatorListTier2 =
{
	["*"]  = function(nIndex1, nIndex2) return GetWordValue(nIndex2) * GetWordValue(nIndex1) end,
	["/"]  = function(nIndex1, nIndex2) return GetWordValue(nIndex2) / GetWordValue(nIndex1) end,
}

local stOperatorListTier3 = 
{
	["+"]  = function(nIndex1, nIndex2) return GetWordValue(nIndex2) + GetWordValue(nIndex1) end,
	["-"]  = function(nIndex1, nIndex2) return GetWordValue(nIndex2) - GetWordValue(nIndex1) end,
}

local stOperatorListTier4 =
{
	[">"]  = function(nIndex1, nIndex2) return GetWordValue(nIndex2) > GetWordValue(nIndex1) end,
	[">="] = function(nIndex1, nIndex2) return GetWordValue(nIndex2) >= GetWordValue(nIndex1) end,
	["<"]  = function(nIndex1, nIndex2) return GetWordValue(nIndex2) < GetWordValue(nIndex1) end,
	["<="] = function(nIndex1, nIndex2) return GetWordValue(nIndex2) <= GetWordValue(nIndex1) end,
}

local stOperatorListTier5 =
{
	["=="] = function(nIndex1, nIndex2) return GetWordValue(nIndex2) == GetWordValue(nIndex1) end,
	["!="] = function(nIndex1, nIndex2) return GetWordValue(nIndex2) ~= GetWordValue(nIndex1) end,
}

local stOperatorListTier6 =
{
	["&&"] = function(nIndex1, nIndex2) if (not GetWordValue(nIndex2)) then return false else return not (not GetWordValue(nIndex1)) end end,
	["||"] = function(nIndex1, nIndex2) if not (not GetWordValue(nIndex2)) then return true else return not (not GetWordValue(nIndex1)) end end,
	["^^"] = function(nIndex1, nIndex2) return not (not GetWordValue(nIndex2)) ~= not (not GetWordValue(nIndex1)) end,
}

local stOperatorListTier7 =
{
	["="]  = function(nIndex1, nIndex2) return CGameState:SetGameStateValue(GetWordValue(nIndex2, true), GetWordValue(nIndex1)) end,
}

local stOperatorTierList =
{
	stOperatorListTier1,
	stOperatorListTier2,
	stOperatorListTier3,
	stOperatorListTier4,
	stOperatorListTier5,
	stOperatorListTier6,
	stOperatorListTier7,
}

local stOperatorList = {}
for k,v in pairs(stOperatorTierList) do
	for k2,v2 in pairs(v) do
		stOperatorList[k2] = true
	end
end

CExpression = setmetatable({}, { __call = 
	function(self, szExpression)
		LogAssert(type(szExpression) == "string", "Type mismatch (expected \"%s\", got %s)", "string", type(szExpression))
		self = setmetatable({}, {__index = CExpression})
		
		local tGroupList = {}
		local tOperatorList = {}
		local szSubbedExpression = string.gsub(szExpression, " _+ ", " ")
		for k in string.gmatch(szExpression, "%b()") do table.insert(tGroupList, 1, k) end
		szSubbedExpression = string.gsub(szSubbedExpression, "%b()", " _ ")
		
		for k in string.gmatch(szSubbedExpression, "[!=%-%+%*/><%^&|]+") do table.insert(tOperatorList, 1, k) end
		szSubbedExpression = string.gsub(szSubbedExpression, "[!=%-%+%*/><%^&|]+", " __ ")
		
		for k in string.gmatch(szSubbedExpression, "[%w_.]+") do
			table.insert(self, tonumber(k) or k)
		end
	
		for k,v in pairs(self) do
			if v == "_" then
				self[k] = CExpression(tGroupList[#tGroupList]:sub(2, -2))
				tGroupList[#tGroupList] = nil
			elseif v == "__" then
				self[k] = tOperatorList[#tOperatorList]
				tOperatorList[#tOperatorList] = nil
			end
		end
		
		return self
	end})
	
CExpression._hCallStack = {}

function CExpression:EvaluateExpression(hInstance)
	local tWordList = {}
	for k,v in pairs(self) do tWordList[k] = v end
	table.insert(CExpression._hCallStack, tWordList)
	
	for k,v in pairs(stOperatorTierList) do
		local bHasOperator = true
		while bHasOperator do
			bHasOperator = false
			local nPrevIndex = nil
			for k2,v2 in pairs(tWordList) do
				local hOperatorFunction = v[v2]
				if hOperatorFunction then
					local nNextIndex = next(tWordList, k2)
					if not stOperatorList[tWordList[nNextIndex]] then
						local bStatus, result = pcall(hOperatorFunction, nNextIndex, nPrevIndex, hInstance)
						if not bStatus then
							LogMessage("Failed to evaluate expression: " .. result, LOG_SEVERITY_ERROR)
							return false
						end
						if result ~= nil then
    						tWordList[k2] = result
							--Don't clear the previous word if it's a unary operator (tier 1)
    						if k ~= 1 then tWordList[nPrevIndex] = nil end
    						tWordList[nNextIndex] = nil
    						bHasOperator = true
    					end
						break
					end
				end
				nPrevIndex = k2
			end
		end
	end
	local nIndex, _ = next(tWordList)
	local mResult = GetWordValue(nIndex, false)
	table.remove(CExpression._hCallStack)
	return (mResult == nil) and true or mResult
end

end