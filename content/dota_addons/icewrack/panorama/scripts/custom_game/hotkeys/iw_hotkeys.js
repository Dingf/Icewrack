"use strict";

Game.HotkeyFunctions = {};
Game.RegisterHotkey = function(szKeyName, hFunction)
{
	if ((typeof(szKeyName) === "string") && (typeof(hFunction) === "function"))
	{
		var tHotkeyFunctions = Game.HotkeyFunctions[szKeyName];
		if (!tHotkeyFunctions)
		{
			Game.HotkeyFunctions[szKeyName] = [];
			tHotkeyFunctions = Game.HotkeyFunctions[szKeyName];
		}
		tHotkeyFunctions.push(hFunction);
	}
}

function DispatchHotkeyEvent(szKeyName)
{
	return function()
	{
		var tHotkeyFunctions = Game.HotkeyFunctions[szKeyName];
		if (tHotkeyFunctions)
		{
			for (var k in tHotkeyFunctions)
			{
				var hFunction = tHotkeyFunctions[k];
				if (hFunction() === true)
					break;
			}
		}
	}
}

Game.AddCommand("IcewrackHotkeyF1", DispatchHotkeyEvent("F1"), "", 0);
Game.AddCommand("IcewrackHotkeyF2", DispatchHotkeyEvent("F2"), "", 0);
Game.AddCommand("IcewrackHotkeyF3", DispatchHotkeyEvent("F3"), "", 0);
Game.AddCommand("IcewrackHotkeyF4", DispatchHotkeyEvent("F4"), "", 0);
Game.AddCommand("IcewrackHotkeyF5", DispatchHotkeyEvent("F5"), "", 0);
Game.AddCommand("IcewrackHotkeyF6", DispatchHotkeyEvent("F6"), "", 0);
Game.AddCommand("IcewrackHotkeyF7", DispatchHotkeyEvent("F7"), "", 0);
Game.AddCommand("IcewrackHotkeyF8", DispatchHotkeyEvent("F8"), "", 0);
Game.AddCommand("IcewrackHotkeyF9", DispatchHotkeyEvent("F9"), "", 0);
Game.AddCommand("IcewrackHotkeyF10", DispatchHotkeyEvent("F10"), "", 0);
Game.AddCommand("IcewrackHotkeyF11", DispatchHotkeyEvent("F11"), "", 0);
Game.AddCommand("IcewrackHotkeyF12", DispatchHotkeyEvent("F12"), "", 0);

Game.AddCommand("IcewrackHotkeySpace", DispatchHotkeyEvent("SPACE"), "", 0);

Game.AddCommand("IcewrackHotkey1", DispatchHotkeyEvent("1"), "", 0);
Game.AddCommand("IcewrackHotkey2", DispatchHotkeyEvent("2"), "", 0);
Game.AddCommand("IcewrackHotkey3", DispatchHotkeyEvent("3"), "", 0);
Game.AddCommand("IcewrackHotkey4", DispatchHotkeyEvent("4"), "", 0);
Game.AddCommand("IcewrackHotkey5", DispatchHotkeyEvent("5"), "", 0);
Game.AddCommand("IcewrackHotkey6", DispatchHotkeyEvent("6"), "", 0);
Game.AddCommand("IcewrackHotkey7", DispatchHotkeyEvent("7"), "", 0);
Game.AddCommand("IcewrackHotkey8", DispatchHotkeyEvent("8"), "", 0);
Game.AddCommand("IcewrackHotkey9", DispatchHotkeyEvent("9"), "", 0);
Game.AddCommand("IcewrackHotkey0", DispatchHotkeyEvent("0"), "", 0);

Game.AddCommand("IcewrackHotkeyTidle", DispatchHotkeyEvent("`"), "", 0);

/*Game.AddCommand("IcewrackSelectParty1", WrapHotkeyFunction("OnPartyMemberSelectHotkey", 1), "", 0);
Game.AddCommand("IcewrackSelectParty2", WrapHotkeyFunction("OnPartyMemberSelectHotkey", 2), "", 0);
Game.AddCommand("IcewrackSelectParty3", WrapHotkeyFunction("OnPartyMemberSelectHotkey", 4), "", 0);
Game.AddCommand("IcewrackSelectParty4", WrapHotkeyFunction("OnPartyMemberSelectHotkey", 8), "", 0);
Game.AddCommand("IcewrackSelectAll",    WrapHotkeyFunction("OnPartyMemberSelectHotkey", 15), "", 0);

Game.AddCommand("IcewrackPauseGame", WrapHotkeyFunction("OnPauseHotkey"), "", 0);

Game.AddCommand("IcewrackActionBar1", WrapHotkeyFunction("OnActionBarHotkey", 1), "", 0);
Game.AddCommand("IcewrackActionBar2", WrapHotkeyFunction("OnActionBarHotkey", 2), "", 0);
Game.AddCommand("IcewrackActionBar3", WrapHotkeyFunction("OnActionBarHotkey", 3), "", 0);
Game.AddCommand("IcewrackActionBar4", WrapHotkeyFunction("OnActionBarHotkey", 4), "", 0);
Game.AddCommand("IcewrackActionBar5", WrapHotkeyFunction("OnActionBarHotkey", 5), "", 0);
Game.AddCommand("IcewrackActionBar6", WrapHotkeyFunction("OnActionBarHotkey", 6), "", 0);
Game.AddCommand("IcewrackActionBar7", WrapHotkeyFunction("OnActionBarHotkey", 7), "", 0);
Game.AddCommand("IcewrackActionBar8", WrapHotkeyFunction("OnActionBarHotkey", 8), "", 0);
Game.AddCommand("IcewrackActionBar9", WrapHotkeyFunction("OnActionBarHotkey", 9), "", 0);
Game.AddCommand("IcewrackActionBar0", WrapHotkeyFunction("OnActionBarHotkey", 10), "", 0);

Game.AddCommand("IcewrackQuicksave", WrapHotkeyFunction("OnQuicksaveHotkey"), "", 0);
Game.AddCommand("IcewrackQuickload", WrapHotkeyFunction("OnQuickloadHotkey"), "", 0);*/