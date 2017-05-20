"use strict";

var nPartySlot = 1;

var tItemPanels = {};

function OnInventoryUseFinish()
{
	var nClickBehavior = GameUI.GetClickBehaviors();
	if (nClickBehavior == 3)
	{
		$.Schedule(0.03, OnInventoryUseFinish);
	}
	else
	{
		var nEntityIndex = $("#Inventory").GetAttributeInt("entindex", -1);
		var nItemIndex = $("#Inventory").GetAttributeInt("use_itemindex", -1);
		$.Schedule(0.03, function() { GameEvents.SendCustomGameEventToServer("iw_inventory_use_finish", { entindex:nEntityIndex, itemindex:nItemIndex }); });
	}
}

function OnInventoryUseItem(args)
{
	$("#Inventory").SetAttributeInt("use_itemindex", args.itemindex);
	Abilities.ExecuteAbility(args.itemindex, $("#Inventory").GetAttributeInt("entindex", -1), false);
	$.Schedule(0.03, OnInventoryUseFinish);
}

function UpdateInventoryInfo()
{
	var nEntityIndex = $("#Inventory").GetAttributeInt("entindex", -1);
	
	var tEntityData = CustomNetTables.GetTableValue("entities", nEntityIndex);
	var tInventoryData = CustomNetTables.GetTableValue("inventory", nEntityIndex);
	if (typeof(tInventoryData) === "undefined")
		return;
	
	for (var i = 0; i < $.GetContextPanel()._tInventorySlots.length; i++)
	{
		DispatchCustomEvent($.GetContextPanel()._tInventorySlots[i], "InventorySlotUpdate", { entindex:nEntityIndex });
	}
						
	SetIconLabelText($.GetContextPanel().FindChildTraverse("GoldAttrib"), tInventoryData.gold);
	SetIconLabelText($.GetContextPanel().FindChildTraverse("WeightAttrib"), (tInventoryData.weight).toFixed(1) + " / " + (tInventoryData.weight_max).toFixed(1));
	
	var hInventoryList = $.GetContextPanel().FindChildTraverse("InventoryItemList");
	DispatchCustomEvent(hInventoryList, "ItemListUpdate");
}

function UpdateEntityInventoryInfo(szTableName, szKey, tData)
{
	var nEntityIndex = $("#Inventory").GetAttributeInt("entindex", -1);
	if (parseInt(szKey) === nEntityIndex)
	{
		$.Schedule(0.03, UpdateInventoryInfo);
	}
}

function OnInventoryDragDrop(szPanelID, hDraggedPanel)
{
	hDraggedPanel._bDragCompleted = true;
	return true;
}

function OnInventoryListDragDrop(szPanelID, hDraggedPanel)
{
	hDraggedPanel._bDragCompleted = !(hDraggedPanel._nDragType & 0x02);
	return true;
}

function OnInventoryOpen(hContextPanel, tArgs)
{
	var hRightContent = hContextPanel.FindChildTraverse("WindowRightContent");
	var hInventoryList = hRightContent.FindChild("InventoryItemList");
	DispatchCustomEvent(hInventoryList, "ItemListFocus");
	GameUI.SetPauseScreen(true);
	return true;
}

function OnInventoryClose(hContextPanel, tArgs)
{
	GameUI.SetPauseScreen(false);
	return true;
}

function OnInventoryPartyUpdate(hContextPanel, tArgs)
{
	var hInventoryList = hContextPanel.FindChildTraverse("InventoryItemList");
	hInventoryList.SetAttributeInt("entindex", tArgs.entindex);
	DispatchCustomEvent(hInventoryList, "ItemListUpdate");
	UpdateInventoryInfo();
	return true;
}

function LoadInventoryLayout()
{
	var hLeftContent = $("#Inventory").FindChildTraverse("WindowLeftContent");
	hLeftContent.BLoadLayout("file://{resources}/layout/custom_game/inventory/iw_inventory_left.xml", false, false);
	var hRightContent = $("#Inventory").FindChildTraverse("WindowRightContent");
	hRightContent.BLoadLayout("file://{resources}/layout/custom_game/inventory/iw_inventory_right.xml", false, false);
	var hInventoryList = CreateItemList(hRightContent, "InventoryItemList", 126);
}

function LoadInventorySlots()
{
	var hLeftContent = $("#Inventory").FindChildTraverse("WindowLeftContent");
	$.GetContextPanel()._tInventorySlots =
	[
		CreateInventorySlotPanel(hLeftContent, "MainHandSlot", IW_INVENTORY_SLOT_MAIN_HAND, 110, 270, 72, 208),
		CreateInventorySlotPanel(hLeftContent, "OffHandSlot", IW_INVENTORY_SLOT_OFF_HAND, 110, 270, 360, 208),
		CreateInventorySlotPanel(hLeftContent, "HeadSlot", IW_INVENTORY_SLOT_HEAD, 110, 110, 216, 128),
		CreateInventorySlotPanel(hLeftContent, "BodySlot", IW_INVENTORY_SLOT_BODY, 142, 206, 200, 304),
		CreateInventorySlotPanel(hLeftContent, "GlovesSlot", IW_INVENTORY_SLOT_GLOVES, 110, 110, 72, 488),
		CreateInventorySlotPanel(hLeftContent, "BootsSlot", IW_INVENTORY_SLOT_BOOTS, 110, 110, 360, 488),
		CreateInventorySlotPanel(hLeftContent, "BeltSlot", IW_INVENTORY_SLOT_BELT, 142, 78, 200, 520),
		CreateInventorySlotPanel(hLeftContent, "LRingSlot", IW_INVENTORY_SLOT_LRING, 46, 46, 200, 248),
		CreateInventorySlotPanel(hLeftContent, "RRingSlot", IW_INVENTORY_SLOT_RRING, 46, 46, 296, 248),
		CreateInventorySlotPanel(hLeftContent, "AmuletSlot", IW_INVENTORY_SLOT_AMULET, 46, 46, 248, 248),
		
		CreateInventorySlotPanel(hLeftContent, "QuickSlot1", IW_INVENTORY_SLOT_QUICK1, 78, 78, 112, 616),
		CreateInventorySlotPanel(hLeftContent, "QuickSlot2", IW_INVENTORY_SLOT_QUICK2, 78, 78, 192, 616),
		CreateInventorySlotPanel(hLeftContent, "QuickSlot3", IW_INVENTORY_SLOT_QUICK3, 78, 78, 272, 616),
		CreateInventorySlotPanel(hLeftContent, "QuickSlot4", IW_INVENTORY_SLOT_QUICK4, 78, 78, 352, 616),
	];
}



function LoadInventoryAttribs()
{
	/*var hParent = $.GetContextPanel().FindChildTraverse("LeftAttribs1");
	CreateIconLabel(hParent, "HealthAttrib", "inventory/icons/iw_inventory_icon_health", "", "#ff3000ff", $.Localize("#iw_ui_inventory_health"));
	CreateIconLabel(hParent, "ManaAttrib", "inventory/icons/iw_inventory_icon_mana", "", "#0080ffff", $.Localize("#iw_ui_inventory_mana"));
	CreateIconLabel(hParent, "StaminaAttrib", "inventory/icons/iw_inventory_icon_stamina", "", "#ffff00ff", $.Localize("#iw_ui_inventory_stamina"));
	CreateIconLabel(hParent, "ArmorAttrib", "inventory/icons/iw_inventory_icon_armor", "", "#008000ff", $.Localize("#iw_ui_inventory_armor"));
	
	hParent = $.GetContextPanel().FindChildTraverse("LeftAttribs2");
	$.GetContextPanel()._tResistAttribPanels =
	[
		CreateIconLabel(hParent, "FireResAttrib", "inventory/icons/iw_inventory_icon_fire", "", "#ff3000ff", $.Localize("#iw_ui_inventory_fire_res")),
		CreateIconLabel(hParent, "ColdResAttrib", "inventory/icons/iw_inventory_icon_cold", "", "#0080ffff", $.Localize("#iw_ui_inventory_cold_res")),
		CreateIconLabel(hParent, "LightningResAttrib", "inventory/icons/iw_inventory_icon_lightning", "", "#ffff00ff", $.Localize("#iw_ui_inventory_lightning_res")),
		CreateIconLabel(hParent, "DeathResAttrib", "inventory/icons/iw_inventory_icon_death", "", "#008000ff", $.Localize("#iw_ui_inventory_death_res")),
	];*/
	
	var hParent = $.GetContextPanel().FindChildTraverse("RightAttribs");
	CreateIconLabel(hParent, "GoldAttrib", "icons/iw_icon_gold", "", "#ffc000ff", $.Localize("#iw_ui_inventory_gold"));
	CreateIconLabel(hParent, "WeightAttrib", "icons/iw_icon_weight", "", "#ffffff80", $.Localize("#iw_ui_inventory_carry"), 126);
}

(function()
{
	CreateWindowPanel($.GetContextPanel(), "Inventory", "inventory", "#iw_ui_inventory", true, true);
	
	LoadInventoryLayout();
	LoadInventorySlots();
	LoadInventoryAttribs();
	//TODO: Implement the inspect popup better
	//$.GetContextPanel()._hPopup = $.CreatePanel("Panel", $.GetContextPanel(), "InspectPopup");
	//$.GetContextPanel()._hPopup.visible = false;
	//$.GetContextPanel()._hPopup.BLoadLayout("file://{resources}/layout/custom_game/ui/iw_window_popup_ok.xml", false, false);

	RegisterCustomEventHandler($.GetContextPanel(), "WindowOpen", OnInventoryOpen);
	RegisterCustomEventHandler($.GetContextPanel(), "WindowClose", OnInventoryClose);
	RegisterCustomEventHandler($.GetContextPanel(), "WindowPartyUpdate", OnInventoryPartyUpdate);
	
	var hInventoryList = $.GetContextPanel().FindChildTraverse("InventoryItemList");
	$.RegisterEventHandler("DragDrop", $.GetContextPanel(), OnInventoryDragDrop);
	$.RegisterEventHandler("DragDrop", hInventoryList.FindChildTraverse("Hitbox"), OnInventoryListDragDrop);
	
	GameEvents.Subscribe("iw_inventory_use_item", OnInventoryUseItem);
	CustomNetTables.SubscribeNetTableListener("inventory", UpdateEntityInventoryInfo);
})();