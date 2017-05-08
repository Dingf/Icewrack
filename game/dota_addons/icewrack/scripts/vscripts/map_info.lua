if not CMapInfo then

local stMapTypeFlags = 
{
	IW_MAP_TYPE_OUTSIDE = 0,
	IW_MAP_TYPE_INSIDE = 1,
	IW_MAP_TYPE_TOWN = 2,
}

for k,v in pairs(stMapTypeFlags) do _G[k] = v end

local tMapInfoTable = LoadKeyValues("scripts/npc/iw_map_list.txt")
CMapInfo = tMapInfoTable[GetMapName()]
if not CMapInfo or not CMapInfo.ID then
	LogMessage("Failed to load map information for the current map \"" .. GetMapName() .. "\"", LOG_SEVERITY_ERROR)
end

CMapInfo.name = GetMapName()
CMapInfo.flags = GetFlagValue(CMapInfo.type or "", stMapTypeFlags)
CMapInfo.type = nil
GameRules.GetMapInfo = function() return CMapInfo end

if IsServer() then
	CustomNetTables:SetTableValue("game", "map", GameRules:GetMapInfo())
end

function CMapInfo:GetName()
	return CMapInfo.name
end

function CMapInfo:GetType()
	return CMapInfo.type
end

function CMapInfo:GetID()
	return CMapInfo.ID
end

function CMapInfo:GetBounds()
	return CMapInfo.left, CMapInfo.top, CMapInfo.right, CMapInfo.bottom
end

function CMapInfo:GetMapVisionMultiplier()
	return CMapInfo.vision or 1.0
end

function CMapInfo:IsOutside()
	return bit32.band(CMapInfo.flags, IW_MAP_TYPE_INSIDE) == 0
end

function CMapInfo:IsInside()
	return bit32.band(CMapInfo.flags, IW_MAP_TYPE_INSIDE) == 1
end

function CMapInfo:IsTown()
	return bit32.band(CMapInfo.flags, IW_MAP_TYPE_TOWN) ~= 0
end

function CMapInfo:IsRevealed()
	return CMapInfo.revealed == 1
end

function CMapInfo:IsOverride()
	return CMapInfo.override == 1
end

end