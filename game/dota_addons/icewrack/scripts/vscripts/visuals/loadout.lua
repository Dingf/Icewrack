--[[
    Icewrack Loadout
]]

if not tLoadoutData then tLoadoutData = {} end

function Precache(context)
	local szUnitName = thisEntity:GetUnitName()
	if not tLoadoutData[szUnitName] then
		tLoadoutData[szUnitName] = LoadKeyValues("scripts/npc/loadouts/loadout_" .. szUnitName:sub(15) .. ".txt")
	end
	for k,v in pairs(tLoadoutData[szUnitName]) do
		if v.Model then PrecacheModel(v.Model, context) end
	end
end

local function BuildLoadoutTable(hEntity)
	local hWearable = Entities:First()
	while hWearable do
		if hWearable:GetClassname() == "dota_item_wearable" and hWearable:GetOwner() == hEntity then
			if not hEntity._tLoadoutTable then
				hEntity._tLoadoutTable = {}
			end
			table.insert(hEntity._tLoadoutTable, 1, hWearable)
		end
		hWearable = Entities:Next(hWearable)
	end
end

function RefreshLoadout(hEntity)
	local hInventory = hEntity:GetInventory()
	local tLoadoutTemplate = tLoadoutData[hEntity:GetUnitName()]
	if hInventory and tLoadoutTemplate then
		if not hEntity._tLoadoutTable or not next(hEntity._tLoadoutTable) then
			BuildLoadoutTable(hEntity)
		end
		if hEntity._tLoadoutTable then
			for k,v in pairs(hEntity._tLoadoutTable) do
				local tDefaultLoadout = tLoadoutTemplate["default" .. k]
				if tDefaultLoadout then
					local nLoadoutSlot = tDefaultLoadout.Slot
					local szModelName = tDefaultLoadout.Model
					if nLoadoutSlot and szModelName and nLoadoutSlot == k then
						v:SetModel(szModelName)
					end
				end
			end
			for k,v in pairs(hInventory._tEquippedItems) do
				local tLoadout = tLoadoutTemplate[v:GetName()]
				if tLoadout then
					local nLoadoutSlot = tLoadout.Slot
					local szModelName = tLoadout.Model
					if nLoadoutSlot and szModelName then
						hEntity._tLoadoutTable[nLoadoutSlot]:SetModel(szModelName)
					end
				end
			end
		end
	end
end

function Spawn(keys)
	thisEntity.RefreshLoadout = RefreshLoadout
end