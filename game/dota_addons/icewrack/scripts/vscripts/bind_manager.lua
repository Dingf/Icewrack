if not CBindManager then

if _VERSION < "Lua 5.2" then
    bit = require("lib/numberlua")
    bit32 = bit.bit32
end

require("ext_entity")
require("ext_ability")
require("ext_item")

--TODO: Change the bind system to not use the "bind" command when Valve fixes keybinds for panorama

local stValidHotkeys =
{
	--A, S, and H are not valid because they are used for in-game commands (attack, stop, and hold position)
	b = "B", c = "C", d = "D", e = "E", f = "F", g = "G", i = "I", j = "J", k = "K", l = "L", m = "M",
	n = "N", o = "O", p = "P", q = "Q", r = "R", t = "T", u = "U", v = "V", w = "W", x = "X", y = "Y", z = "Z",
	["1"] = "1", ["2"] = "2", ["3"] = "3", ["4"] = "4", ["5"] = "5", ["6"] = "6", ["7"] = "7", ["8"] = "8", ["9"] = "9", ["0"] = "0",
	["["] = "[", ["]"] = "]", ["'"] = "'", [","] = ",", ["."] = ".", ["/"] = "/", ["-"] = "-", ["="] = "=", ["`"] = "`",
	f1 = "F1", f2 = "F2", f3 = "F3", f4 = "F4", f5 = "F5", f6 = "F6", f7 = "F7", f8 = "F8", f9 = "F9", f10 = "F10", f11 = "F11", f12 = "F12",
	kp_1 = "KP1", kp_2 = "KP2", kp_3 = "KP3", kp_4 = "KP4", kp_5 = "KP5", kp_6 = "KP6", kp_7 = "KP7", kp_8 = "KP8", kp_9 = "KP9", kp_0 = "KP0",
	tab = "TAB", enter = "ENTER", escape = "ESC", space = "SPACE", uparrow = "UP", downarrow = "DOWN", leftarrow = "LEFT", rightarrow = "RIGHT",
	ins = "INS", del = "DEL", pgdn = "PGDN", pgup = "PGUP", home = "HOME", ["end"] = "END",
}

local stValidActionBindSlots = {}
for i=1,10 do stValidActionBindSlots[i] = true end
local function ActionBindIndexFunction(self, k)
	return stValidActionBindSlots[k] and -1 or nil
end

CBindManager = 
{
	_stDefaultActionBinds = {},
	_tHotkeyBinds = {},
	_tActionBinds = {},
	_tNetTable =
	{
		Hotkeys = {},
		Actions = {},
	}
}

function CBindManager:CreateFromDefaultActionBinds(hEntity)
	local tEntityBindTable = setmetatable({}, { __index = ActionBindIndexFunction })
	local szUnitName = hEntity:GetUnitName()
	local tDefaultActionBinds = CBindManager._stDefaultActionBinds[szUnitName]
	if tDefaultActionBinds then
		for k,v in pairs(tDefaultActionBinds) do
			local hAbility = hEntity:FindAbilityByName(v)
			if hAbility then
				tEntityBindTable[k] = hAbility:entindex()
				hAbility:OnAbilityBind(hEntity, k)
			end
		end
	end
	return tEntityBindTable
end
	
function CBindManager:SetActionBind(hEntity, nSlot, hAbility)
	if IsValidExtendedEntity(hEntity) then
		if hAbility then
			LogAssert(IsValidExtendedAbility(hAbility) or IsValidExtendedItem(hAbility), LOG_MESSAGE_ASSERT_TYPE, "CExtAbility\" or \"CExtItem")
			if hAbility:GetOwner() ~= hEntity then
				LogMessage("Tried to bind item or ability \"" .. hAbility:GetAbilityName() .. "\" that does not belong to entity .. \"" .. hEntity:GetUnitName() .. "\"", LOG_SEVERITY_WARNING)
				return
			end
		end
	
		local nEntityIndex = hEntity:entindex()
		local tEntityBindTable = CBindManager._tActionBinds[nEntityIndex]
		local tEntityBindNetTable = CBindManager._tNetTable.Actions[nEntityIndex]
		if not tEntityBindTable then
			tEntityBindTable = CBindManager:CreateFromDefaultActionBinds(hEntity)
			tEntityBindNetTable = {}
			for k,v in pairs(stValidActionBindSlots) do
				tEntityBindNetTable[k] = tEntityBindTable[k]
			end
			CBindManager._tActionBinds[nEntityIndex] = tEntityBindTable
			CBindManager._tNetTable.Actions[nEntityIndex] = tEntityBindNetTable
			CustomNetTables:SetTableValue("binds", tostring(nEntityIndex), tEntityBindNetTable)
		end
		
		if not tEntityBindTable[nSlot] then
			LogMessage("Tried to bind to nonexistant actionbar slot \"" .. nSlot .. "\"", LOG_SEVERITY_WARNING)
		else
			if not hAbility then
				local nOldAbilityIndex = tEntityBindTable[nSlot]
				if nOldAbilityIndex ~= -1 then 
					local hOldAbility = EntIndexToHScript(nOldAbilityIndex)
					hOldAbility:OnAbilityUnbind(hEntity)
				end
				tEntityBindTable[nSlot] = -1
				tEntityBindNetTable[nSlot] = -1
				CustomNetTables:SetTableValue("binds", tostring(nEntityIndex), tEntityBindNetTable)
			else
				local nAbilityIndex = hAbility:entindex()
				local nOldAbilityIndex = tEntityBindTable[nSlot]
				if nOldAbilityIndex ~= nAbilityIndex then
					for k,v in pairs(tEntityBindTable) do
						if v == nAbilityIndex then
							tEntityBindTable[k] = nil
							tEntityBindNetTable[k] = nil
							hAbility:OnAbilityUnbind(hEntity)
						end
					end
					if nOldAbilityIndex ~= -1 then 
						local hOldAbility = EntIndexToHScript(nOldAbilityIndex)
						hOldAbility:OnAbilityUnbind(hEntity)
					end
					tEntityBindTable[nSlot] = nAbilityIndex
					tEntityBindNetTable[nSlot] = nAbilityIndex
					hAbility:OnAbilityBind(hEntity, nSlot)
					CustomNetTables:SetTableValue("binds", tostring(nEntityIndex), tEntityBindNetTable)
				end
			end
		end
	end
end

function CBindManager:OnClientActionBarBind(args)
	local hEntity = EntIndexToHScript(args.entindex)
	local hAbility = EntIndexToHScript(args.ability)
	if hEntity then
		CBindManager:SetActionBind(hEntity, args.slot, hAbility)
	end
end

function CBindManager:OnClientActionBarInfoRequest(args)
	local nEntityIndex = args.entindex
	local tEntityBindTable = CBindManager._tActionBinds[nEntityIndex]
	if not tEntityBindTable then
		local hEntity = EntIndexToHScript(nEntityIndex)
		tEntityBindTable = CBindManager:CreateFromDefaultActionBinds(hEntity)
		CBindManager._tActionBinds[nEntityIndex] = tEntityBindTable
	end
	
	local tEntityBindNetTable = {}
	for k,v in pairs(stValidActionBindSlots) do
		tEntityBindNetTable[k] = tEntityBindTable[k]	--This also gets the -1 values for the empty slots
	end
	CBindManager._tNetTable.Actions[nEntityIndex] = tEntityBindNetTable
	CustomNetTables:SetTableValue("binds", tostring(nEntityIndex), tEntityBindNetTable)
end

CustomGameEventManager:RegisterListener("iw_actionbar_bind", Dynamic_Wrap(CBindManager, "OnClientActionBarBind"))
CustomGameEventManager:RegisterListener("iw_actionbar_info", Dynamic_Wrap(CBindManager, "OnClientActionBarInfoRequest"))

local stExtEntityData = LoadKeyValues("scripts/npc/npc_units_extended.txt")
for k,v in pairs(stExtEntityData) do
	local tAbilitiesList = v.Abilities
	if tAbilitiesList then
		local tDefaultActionBinds = CBindManager._stDefaultActionBinds[k]
		if not tDefaultActionBinds then
			tDefaultActionBinds = setmetatable({}, { __index = ActionBindIndexFunction })
			CBindManager._stDefaultActionBinds[k] = tDefaultActionBinds
		end
		for k2,v2 in pairs(tAbilitiesList) do
			local nSlot = tonumber(k2)
			if nSlot then
				tDefaultActionBinds[nSlot] = v2
			end
		end
	end
end
stExtEntityData = nil
	

--[[	stDefaultBinds =
{
	iw_pause = "space",
	iw_select_party_1 = "F1",
	iw_select_party_2 = "F2",
	iw_select_party_3 = "F3",
	iw_select_party_4 = "F4",
	iw_select_all = "`",
	iw_quicksave = "F5",
	iw_quickload = "F9",
	iw_menu_characters = "C",
	iw_menu_party = "V",
	iw_menu_inventory = "E",
	iw_menu_skills = "D",
	iw_menu_quests = "Q",
	iw_menu_map = "W",
	iw_menu_tactics = "T",
	iw_menu_options = "ESC",
	iw_toggle_run = "/",
	iw_actionbar_1 = "1",
	iw_actionbar_2 = "2",
	iw_actionbar_3 = "3",
	iw_actionbar_4 = "4",
	iw_actionbar_5 = "5",
	iw_actionbar_6 = "6",
	iw_actionbar_7 = "7",
	iw_actionbar_8 = "8",
	iw_actionbar_9 = "9",
	iw_actionbar_10 = "0",
}

SendToServerConsole("unbindall")
CBindManager = 
{
	_tBindTable = {},
	_tReverseBindTable = {},
	_tNetTable = {},
}

function CBindManager:RegisterBind(szKey, szCommand, hBindFunction)
	szKey = string.lower(szKey)
	if stValidBindKeys[string.lower(szKey)] then
		if hBindFunction then
			Convars:RegisterCommand(szCommand, hBindFunction, "", 0)
		end
		local szOldKey = CBindManager._tReverseBindTable[szCommand]
		if szOldKey then
			CBindManager._tBindTable[szOldKey] = nil
		end
		CBindManager._tBindTable[szKey] = szCommand
		CBindManager._tReverseBindTable[szCommand] = szKey
		CBindManager._tNetTable[szCommand] = stValidBindKeys[szKey]
		SendToServerConsole("bind ".. szKey .. " " .. szCommand)
		CustomNetTables:SetTableValue("game", "binds", CBindManager._tNetTable)
	end
end

function CBindManager:RegisterDefaultBinds(tBindData)
	--TODO: Delete me
	Convars:RegisterCommand("iw_override_unpause", function()
		PauseGame(false)
	end, "", 0)


	Convars:RegisterCommand("iw_pause", function()
		if not GameRules:GetMapInfo():IsOverride() then
			GameRules.PauseState = (not GameRules.PauseState)
			PauseGame(GameRules.PauseState or (GameRules.OverridePauseLevel > 0))
		end
	end, "", 0)
	
	for i = 1,4 do
		Convars:RegisterCommand("iw_select_party_" .. i, function()
			if not GameRules:GetMapInfo():IsOverride() then
				CustomGameEventManager:Send_ServerToAllClients("iw_party_select", { value = bit32.lshift(1, i-1) })
			end
		end, "", 0)
	end
	
	Convars:RegisterCommand("iw_select_all", function()
		if not GameRules:GetMapInfo():IsOverride() then
			CustomGameEventManager:Send_ServerToAllClients("iw_party_select", { value = 0x0F })
		end
	end, "", 0)
	
	Convars:RegisterCommand("iw_quicksave", function()
		if not GameRules:GetMapInfo():IsOverride() then
			FireGameEventLocal("iw_save_game", { mode = IW_SAVE_MODE_QUICKSAVE })
		end
	end, "", 0)
	
	Convars:RegisterCommand("iw_quickload", function()
		if not GameRules:GetMapInfo():IsOverride() and not GameRules:IsGamePaused() then
			CSaveManager:LoadSave(CSaveManager._tSaveSpecial.Quicksave)
		end
	end, "", 0)
	
	local tMenuList = 
	{
		"character", "party", "inventory", "skills",
		"quests",    "map",   "tactics",   "options",
	}
	
	for _,v in pairs(tMenuList) do
		Convars:RegisterCommand("iw_menu_" .. v, function()
			CustomGameEventManager:Send_ServerToAllClients("iw_menu_option", { name = v })
		end, "", 0)
	end
	
	Convars:RegisterCommand("iw_toggle_run", function()
		CustomGameEventManager:Send_ServerToAllClients("iw_toggle_run", {})
	end, "", 0)
	
	for i = 1,10 do
		Convars:RegisterCommand("iw_actionbar_" .. i, function()
			CustomGameEventManager:Send_ServerToAllClients("iw_actionbar_ability", { value = i })
		end, "", 0)
	end
	
	
	for k,v in pairs(tBindData or stDefaultBinds) do
		CBindManager:RegisterBind(v,k)
	end
	for k,v in pairs(stDefaultBinds) do
		if not CBindManager._tBindTable[k] then
			CBindManager:RegisterBind(v,k)
		end
	end
end]]
end