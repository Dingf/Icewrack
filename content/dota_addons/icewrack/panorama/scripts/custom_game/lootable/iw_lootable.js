"use strict";

function UpdateLootableInfo()
{
	var nEntityIndex = $.GetContextPanel().GetAttributeInt("entindex", -1);
	var nLootableIndex = $.GetContextPanel().GetAttributeInt("lootable", -1);
	var tEntityInventory = CustomNetTables.GetTableValue("inventory", nEntityIndex);
	var tLootableInventory = CustomNetTables.GetTableValue("inventory", nLootableIndex);
	if ((typeof(tEntityInventory) === "undefined") || (typeof(tLootableInventory) === "undefined"))
		return;
	
	var szLeftWeightString = (tLootableInventory.weight).toFixed(1);
	if (tLootableInventory.weight_max > 0)
		szLeftWeightString += (" / " + (tLootableInventory.weight_max).toFixed(1));
	
	var szRightWeightString = (tEntityInventory.weight).toFixed(1);
	if (tEntityInventory.weight_max > 0)
		szRightWeightString += (" / " + (tEntityInventory.weight_max).toFixed(1));

	SetIconLabelText($.GetContextPanel().FindChildTraverse("LeftGoldAttrib"), tLootableInventory.gold);
	SetIconLabelText($.GetContextPanel().FindChildTraverse("LeftWeightAttrib"), szLeftWeightString);
	SetIconLabelText($.GetContextPanel().FindChildTraverse("RightGoldAttrib"), tEntityInventory.gold);
	SetIconLabelText($.GetContextPanel().FindChildTraverse("RightWeightAttrib"), szRightWeightString);
	
	DispatchCustomEvent($.GetContextPanel().FindChildTraverse("LootableLeftList"), "ItemListUpdate");
	DispatchCustomEvent($.GetContextPanel().FindChildTraverse("LootableRightList"), "ItemListUpdate");
}

function OnLootableTakeAllMouseOver()
{
	var hHeaderCenter = $("#Lootable").FindChildTraverse("TradeHeaderCenter");
	$.DispatchEvent("DOTAShowTextTooltip", hHeaderCenter, $.Localize("#iw_ui_lootable_take_all"));
}

function OnLootableTakeAllMouseOut()
{
	var hHeaderCenter = $("#Lootable").FindChildTraverse("TradeHeaderCenter");
	$.DispatchEvent("DOTAHideTextTooltip", hHeaderCenter);
}

function OnLootableInventoryUpdate(szTableName, szKey, tData)
{
	var nTargetIndex = parseInt(szKey);
	var nEntityIndex = $.GetContextPanel().GetAttributeInt("entindex", -1);
	var nLootableIndex = $.GetContextPanel().GetAttributeInt("lootable", -1);
	if ((nTargetIndex === nEntityIndex) || (nTargetIndex === nLootableIndex))
	{
		UpdateLootableInfo();
	}
}

function OnLootableInteract(args)
{
	DispatchCustomEvent($("#Lootable"), "WindowOpen");
	
	var hLeftList = $.GetContextPanel().FindChildTraverse("LootableLeftList");
	$.GetContextPanel().SetAttributeInt("lootable", args.lootable);
	hLeftList.SetAttributeInt("entindex", args.lootable);
	var hLeftTitle = $.GetContextPanel().FindChildTraverse("LeftNameTitle");
	hLeftTitle.text = $.Localize("#" + Entities.GetUnitName(args.lootable));
	
	var hRightList = $.GetContextPanel().FindChildTraverse("LootableRightList");
	$.GetContextPanel().SetAttributeInt("entindex", args.entindex);
	$("#Lootable").SetAttributeInt("entindex", args.entindex);
	hRightList.SetAttributeInt("entindex", args.entindex);
	var hRightTitle = $.GetContextPanel().FindChildTraverse("RightNameTitle");
	hRightTitle.text = $.Localize("#" + Entities.GetUnitName(args.entindex));
	DispatchCustomEvent($("#Lootable"), "WindowPartyUpdate", { entindex:args.entindex });
	
	UpdateLootableInfo();
}

function OnLootableLeftDragDrop(szPanelID, hDraggedPanel)
{
	if (hDraggedPanel._nDragType == 0x01)
	{
		var nItemIndex = hDraggedPanel._tPanelData.itemindex;
		var nEntityIndex = $.GetContextPanel().GetAttributeInt("entindex", -1);
		var nLootableIndex = $.GetContextPanel().GetAttributeInt("lootable", -1);
		GameEvents.SendCustomGameEventToServer("iw_lootable_store_item", { entindex:nEntityIndex, lootable:nLootableIndex, itemindex:nItemIndex });
		hDraggedPanel._bDragCompleted = true;
	}
}

function OnLootableRightDragDrop(szPanelID, hDraggedPanel)
{
	if (hDraggedPanel._nDragType == 0x01)
	{
		var nItemIndex = hDraggedPanel._tPanelData.itemindex;
		var nEntityIndex = $.GetContextPanel().GetAttributeInt("entindex", -1);
		var nLootableIndex = $.GetContextPanel().GetAttributeInt("lootable", -1);
		GameEvents.SendCustomGameEventToServer("iw_lootable_take_item", { entindex:nEntityIndex, lootable:nLootableIndex, itemindex:nItemIndex });
		hDraggedPanel._bDragCompleted = true;
	}
}

function OnLootableTakeItem(hContextPanel, tArgs)
{
	var nItemIndex = tArgs.itemindex;
	var nLootableIndex = hContextPanel.GetAttributeInt("lootable", -1);
	var nEntityIndex = hContextPanel.GetAttributeInt("entindex", -1);
	GameEvents.SendCustomGameEventToServer("iw_lootable_take_item", { entindex:nEntityIndex, lootable:nLootableIndex, itemindex:nItemIndex });
	return true;
}

function OnLootableStoreItem(hContextPanel, tArgs)
{
	var nItemIndex = tArgs.itemindex;
	var nEntityIndex = hContextPanel.GetAttributeInt("entindex", -1);
	var nLootableIndex = hContextPanel.GetAttributeInt("lootable", -1);
	GameEvents.SendCustomGameEventToServer("iw_lootable_store_item", { entindex:nEntityIndex, lootable:nLootableIndex, itemindex:nItemIndex });
	return true;
}

function OnLootableOpen(hContextPanel, tArgs)
{
	GameUI.SetPauseScreen(true);
	return true;
}

function OnLootableClose(hContextPanel, tArgs)
{
	var nEntityIndex = hContextPanel.GetAttributeInt("entindex", -1);
	var nLootableIndex = hContextPanel.GetAttributeInt("lootable", -1);
	GameEvents.SendCustomGameEventToServer("iw_lootable_interact", { entindex:nEntityIndex, lootable:nLootableIndex });
	GameUI.SetPauseScreen(false);
	return true;
}

function OnLootableFocus(hContextPanel, tArgs)
{
	var hLeftContent = hContextPanel.FindChildTraverse("WindowLeftContent");
	var hLeftList = hLeftContent.FindChild("LootableLeftList");
	DispatchCustomEvent(hLeftList, "ItemListFocus");
	var hRightContent = hContextPanel.FindChildTraverse("WindowRightContent");
	var hRightList = hRightContent.FindChild("LootableRightList");
	DispatchCustomEvent(hRightList, "ItemListFocus");
	return true;
}

function OnLootablePartyUpdate(hContextPanel, tArgs)
{
	var hRightList = hContextPanel.FindChildTraverse("LootableRightList");
	hRightList.SetAttributeInt("entindex", tArgs.entindex);
	hContextPanel.SetAttributeInt("entindex", tArgs.entindex);
	UpdateLootableInfo();
	return true;
}

function OnLootableButtonActivate(hContextPanel, tArgs)
{
	var szPanelID = tArgs.panel.id;
	if (szPanelID === "TakeAllButton")
	{
		var nLootableIndex = hContextPanel.GetAttributeInt("lootable", -1);
		var nEntityIndex = hContextPanel.GetAttributeInt("entindex", -1);
		GameEvents.SendCustomGameEventToServer("iw_lootable_take_all", { lootable:nLootableIndex, entindex:nEntityIndex });
	}
	return true;
}

function LoadLootableLayout()
{
	var hLeftContent = $("#Lootable").FindChildTraverse("WindowLeftContent");
	hLeftContent.style.position = "26px 0px 0px";
	hLeftContent.BLoadLayout("file://{resources}/layout/custom_game/lootable/iw_lootable_left.xml", false, false);
	CreateItemList(hLeftContent, "LootableLeftList", 192);
	var hRightContent = $("#Lootable").FindChildTraverse("WindowRightContent");
	hRightContent.BLoadLayout("file://{resources}/layout/custom_game/lootable/iw_lootable_right.xml", false, false);
	CreateItemList(hRightContent, "LootableRightList", 320);
	
	var hHeaderCenter = $("#Lootable").FindChildTraverse("TradeHeaderCenter");
	var hTakeAllButton = CreateButton(hHeaderCenter, "TakeAllButton", null, "ui/window/iw_window_take_all_button");
	hTakeAllButton.SetPanelEvent("onmouseover", OnLootableTakeAllMouseOver);
	hTakeAllButton.SetPanelEvent("onmouseout", OnLootableTakeAllMouseOut);
}

function LoadLootableAttribs()
{
	var hLeftAttribs = $("#Lootable").FindChildTraverse("LeftAttribs");
	CreateIconLabel(hLeftAttribs, "LeftGoldAttrib", "icons/iw_icon_gold", "", "#ffc000ff", $.Localize("#iw_ui_inventory_gold"), 128);
	CreateIconLabel(hLeftAttribs, "LeftWeightAttrib", "icons/iw_icon_weight", "", "#ffffff80", $.Localize("#iw_ui_inventory_carry"), 128);
	
	var hRightAttribs = $("#Lootable").FindChildTraverse("RightAttribs");
	CreateIconLabel(hRightAttribs, "RightGoldAttrib", "icons/iw_icon_gold", "", "#ffc000ff", $.Localize("#iw_ui_inventory_gold"), 128);
	CreateIconLabel(hRightAttribs, "RightWeightAttrib", "icons/iw_icon_weight", "", "#ffffff80", $.Localize("#iw_ui_inventory_carry"), 128);
}

(function()
{
	CreateWindowPanel($.GetContextPanel(), "Lootable", "", "#iw_ui_lootable", WINDOW_OPTION_SPLIT | WINDOW_OPTION_TRADE);
	$("#Lootable").visible = false;
	
	LoadLootableLayout();
	LoadLootableAttribs();

	RegisterCustomEventHandler($.GetContextPanel(), "WindowOpen", OnLootableOpen);
	RegisterCustomEventHandler($.GetContextPanel(), "WindowClose", OnLootableClose);
	RegisterCustomEventHandler($.GetContextPanel(), "WindowFocus", OnLootableFocus);
	RegisterCustomEventHandler($.GetContextPanel(), "WindowPartyUpdate", OnLootablePartyUpdate);
	RegisterCustomEventHandler($.GetContextPanel(), "ButtonActivate", OnLootableButtonActivate);
	
	RegisterCustomEventHandler($.GetContextPanel(), "ItemActionTake", OnLootableTakeItem);
	RegisterCustomEventHandler($.GetContextPanel(), "ItemActionStore", OnLootableStoreItem);
	
	var hLeftList = $.GetContextPanel().FindChildTraverse("LootableLeftList");
	var hRightList = $.GetContextPanel().FindChildTraverse("LootableRightList");
	$.RegisterEventHandler("DragDrop", hLeftList.FindChildTraverse("Hitbox"), OnLootableLeftDragDrop);
	$.RegisterEventHandler("DragDrop", hRightList.FindChildTraverse("Hitbox"), OnLootableRightDragDrop);
	
	GameEvents.Subscribe("iw_lootable_interact", OnLootableInteract);
	CustomNetTables.SubscribeNetTableListener("inventory", OnLootableInventoryUpdate);
})();