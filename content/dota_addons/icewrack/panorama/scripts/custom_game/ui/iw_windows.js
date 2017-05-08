"use strict";

(function()
{
	var hInventory = $.CreatePanel("Panel", $.GetContextPanel(), "Inventory");
	hInventory.BLoadLayout("file://{resources}/layout/custom_game/item_window/iw_inventory.xml", false, false);
	hInventory.visible = false;
	
	var hAutomator = $.CreatePanel("Panel", $.GetContextPanel(), "AAM");
	hAutomator.BLoadLayout("file://{resources}/layout/custom_game/aam/iw_aam.xml", false, false);
	hAutomator.visible = false;
	
	var hLootable = $.CreatePanel("Panel", $.GetContextPanel(), "Lootable");
	hLootable.BLoadLayout("file://{resources}/layout/custom_game/item_window/iw_lootable.xml", false, false);
	hLootable.visible = false;
	
	GameUI.GetWindowRoot = function() { return $.GetContextPanel(); };
})();