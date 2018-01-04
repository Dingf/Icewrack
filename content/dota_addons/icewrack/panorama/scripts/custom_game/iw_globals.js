"use strict";

var nHiddenLevel = 0;

function OnGlobalHideUI(hContextPanel, tArgs)
{
	if (nHiddenLevel === 0)
	{
		hContextPanel.FindChildTraverse("ActionBar").visible = false;
		hContextPanel.FindChildTraverse("SideBar").visible = false;
		hContextPanel.FindChildTraverse("StatusBar").visible = false;
		hContextPanel.FindChildTraverse("PartyBar").visible = false;
		hContextPanel.FindChildTraverse("Dialogue").visible = false;
		hContextPanel.FindChildTraverse("Minimap").visible = false;
	}
	nHiddenLevel++;
	return true;
}

function OnGlobalShowUI(hContextPanel, tArgs)
{
	nHiddenLevel--;
	if (nHiddenLevel === 0)
	{
		hContextPanel.FindChildTraverse("ActionBar").visible = true;
		hContextPanel.FindChildTraverse("SideBar").visible = true;
		hContextPanel.FindChildTraverse("StatusBar").visible = true;
		hContextPanel.FindChildTraverse("PartyBar").visible = true;
		hContextPanel.FindChildTraverse("Dialogue").visible = true;
		hContextPanel.FindChildTraverse("Minimap").visible = true;
	}
	return true;
}

function RegisterMouseCallback()
{
	var hRoot = GameUI.GetRoot();
	hRoot._tMouseCallbackList =
	[ 
		hRoot.FindChildTraverse("Scrollable"),
		hRoot.FindChildTraverse("Camera"),
		hRoot.FindChildTraverse("ErrorMessage"),
	];
	GameUI.SetMouseCallback(GlobalMouseCallback);
}

function GlobalMouseCallback(szEventName, nValue)
{
	var tMouseCallbackList = GameUI.GetRoot()._tMouseCallbackList;
	for (var i = 0; i < tMouseCallbackList.length; i++)
	{
		if (DispatchCustomEvent(tMouseCallbackList[i], "MouseEvent", { event:szEventName, value:nValue }))
			return true;
	}
	return false;
}

(function()
{
	var hRoot = $.GetContextPanel();
	while (hRoot.GetParent())
	{
		hRoot = hRoot.GetParent();
	}
	
	var hWindowRoot = $.GetContextPanel().FindChildTraverse("WindowSpace");
	var hMenuRoot = $.GetContextPanel().FindChildTraverse("MenuSpace");
	GameUI.GetRoot = function() { return hRoot; };
	GameUI.GetWindowRoot = function() { return $("#WindowSpace"); };
	GameUI.GetMenuRoot = function() { return $("#MenuSpace"); };
	GameUI.GetScaleRatio = function() { return 1920.0/Game.GetScreenWidth(); };
	GameUI.IsHidden = function() { return (nHiddenLevel !== 0); };
	
	//Hack to get constantly updated stamina stuff without spamming nettables
	Entities.GetStamina = Entities.GetPhysicalArmorValue;
	Entities.GetStaminaRechargeTime = function(nEntityIndex) { return Entities.GetMagicalArmorValue(nEntityIndex) * 100.0 };
	
	//Hide some of the new UI stuff
	hRoot.FindChildTraverse("shop_launcher_block").visible = false;
	hRoot.FindChildTraverse("scoreboard").visible = false;
	hRoot.FindChildTraverse("NetGraph").visible = false;
	hRoot.FindChildTraverse("topbar").visible = false;
	hRoot.FindChildTraverse("quickstats").visible = false;
	
	RegisterCustomEventHandler(hRoot, "GlobalHideUI", OnGlobalHideUI);
	RegisterCustomEventHandler(hRoot, "GlobalShowUI", OnGlobalShowUI);
	
	$.Schedule(0.03, RegisterMouseCallback);
})();