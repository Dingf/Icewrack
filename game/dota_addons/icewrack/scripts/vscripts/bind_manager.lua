if not CBindManager then

if _VERSION < "Lua 5.2" then
    bit = require("lib/numberlua")
    bit32 = bit.bit32
end

--TODO: Change the bind system to not use the "bind" command when Valve fixes keybinds for panorama

stValidBindKeys =
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

stDefaultBinds =
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
end

end