"use strict";

var stItemEntryIcons =
[
	null,
	null,
	"iw_icon_sword",
	"iw_icon_mace",
	"iw_icon_axe",
	"iw_icon_dagger",
	"iw_icon_staff",
	"iw_icon_bow",
	"iw_icon_ammo",		//TODO: Add me
	
	null,
	null,
	null,
	"iw_icon_helmet",
	"iw_icon_body",
	"iw_icon_gloves",
	"iw_icon_boots",
	"iw_icon_belt",
	"iw_icon_shield",
	"iw_icon_amulet",
	"iw_icon_ring",
	
	"iw_icon_potion",
	"iw_icon_flask",
	"iw_icon_wand",
	"iw_icon_scroll",
	"iw_icon_book",
	"iw_icon_food",		//TODO: Add me
	
	"iw_icon_herb",
	"iw_icon_metal",
	"iw_icon_leather",
	"iw_icon_cloth",
	"iw_icon_wood",
	"iw_icon_jewel",
];

function OnItemEntryUpdate(hContextPanel, tArgs)
{
	var tItemData = tArgs.item;
	if (tItemData)
	{
		hContextPanel.FindChildTraverse("ItemName").text = $.Localize("DOTA_Tooltip_Ability_" + tItemData.name);
		if (tItemData.stack > 1)
			hContextPanel.FindChildTraverse("ItemName").text += (" x" + tItemData.stack);
		hContextPanel.FindChild("ItemValue").text = tItemData.value;
		hContextPanel.FindChild("ItemWeight").text = tItemData.weight.toFixed(1);
	}
	return true;
}

function OnItemEntryEquip(hContextPanel, tArgs)
{
	if (tArgs.state)
	{
		hContextPanel.FindChildTraverse("ItemEquipped").visible = true;
		hContextPanel.SetAttributeInt("equipped", 1);
	}
	else
	{
		hContextPanel.FindChildTraverse("ItemEquipped").visible = false;
		hContextPanel.SetAttributeInt("equipped", 0);
	}
	return true;
}

function OnItemEntryDragStart(hPanel, hDraggedPanel)
{
	if ($.GetContextPanel().GetAttributeInt("itemindex", -1) === -1)
		return true;
	
	var szItemName = $.GetContextPanel()._tPanelData.name;
	if (szItemName === "")
		return true;
	
	if (!GameUI.IsMouseDown(0))
		return true;
	
	$.DispatchEvent("DOTAHideAbilityTooltip", $.GetContextPanel());
	
	var hDisplayPanel = $.CreatePanel("Image", $.GetContextPanel(), "ItemDrag");
	hDisplayPanel.SetImage("file://{images}/items/" + szItemName + ".tga");
	hDisplayPanel._tPanelData = {}
	for (var k in $.GetContextPanel()._tPanelData)
	{
		hDisplayPanel._tPanelData[k] = $.GetContextPanel()._tPanelData[k];
	}
	hDisplayPanel._nDragType = 0x01;
	hDisplayPanel._bDragCompleted = false;
	
	hDraggedPanel.displayPanel = hDisplayPanel;
	hDraggedPanel.offsetX = 0;
	hDraggedPanel.offsetY = 0;
	return true;
}

function OnItemEntryDragEnd(hPanel, hDraggedPanel)
{
	hDraggedPanel.DeleteAsync(0);
	return true;
}

function OnItemEntryMouseOverThink()
{
	if ($.GetContextPanel()._bMouseOver)
	{
		var nItemIndex = $.GetContextPanel().GetAttributeInt("itemindex", -1);
		if (nItemIndex !== -1)
		{
			var szTooltipArgs = "itemindex=" + nItemIndex;
			$.DispatchEvent("UIShowCustomLayoutParametersTooltip", "ItemTooltip", "file://{resources}/layout/custom_game/tooltip/iw_tooltip_item.xml", szTooltipArgs);
		}
		$.Schedule(0.03, OnItemEntryMouseOverThink);
	}
	else
	{
		$.DispatchEvent("UIHideCustomLayoutTooltip", "ItemTooltip");
	}
	return 0.03
}

function OnItemEntryMouseOver()
{
	$.GetContextPanel()._bMouseOver = true;
	OnItemEntryMouseOverThink();
}

function OnItemEntryMouseOut()
{
	$.GetContextPanel()._bMouseOver = false;
}

function OnItemEntryActivate()
{
	var nItemIndex = $.GetContextPanel().GetAttributeInt("itemindex", -1);
	var nEntityIndex = $.GetContextPanel().GetAttributeInt("entindex", -1);
	var nContextFilter = $.GetContextPanel().GetAttributeInt("filter", 0);
	var nItemType = $.GetContextPanel()._tPanelData.type;
	
	if (((nContextFilter & ((1 << (IW_ITEM_ACTION_EQUIP)) | (1 << IW_ITEM_ACTION_UNEQUIP))) !== 0) && ((nItemType & 1044984) !== 0))
	{
		if ($.GetContextPanel().GetAttributeInt("equipped", 0) == 1)
			DispatchCustomEvent($.GetContextPanel(), "ItemActionUnequip", { entindex:nEntityIndex, itemindex:nItemIndex });
		else
			DispatchCustomEvent($.GetContextPanel(), "ItemActionEquip", { entindex:nEntityIndex, itemindex:nItemIndex, slots:$.GetContextPanel()._tPanelData.slots });
	}
	else if (((nContextFilter & (1 << IW_ITEM_ACTION_USE)) !== 0) && ((nItemType & 32505856) !== 0))
	{
		DispatchCustomEvent($.GetContextPanel(), "ItemActionUse", { entindex:nEntityIndex, itemindex:nItemIndex });
	}
	else if ((nContextFilter & (1 << IW_ITEM_ACTION_TAKE)) !== 0)
	{
		DispatchCustomEvent($.GetContextPanel(), "ItemActionTake", { entindex:nEntityIndex, itemindex:nItemIndex });
	}
	else if ((nContextFilter & (1 << IW_ITEM_ACTION_STORE)) !== 0)
	{
		DispatchCustomEvent($.GetContextPanel(), "ItemActionStore", { entindex:nEntityIndex, itemindex:nItemIndex });
	}
	else
	{
		DispatchCustomEvent($.GetContextPanel(), "ItemActionInspect", { entindex:nEntityIndex, itemindex:nItemIndex });
	}
}

function OnItemEntryContextItemActivate(hContextPanel, tArgs)
{
	var nItemIndex = hContextPanel.GetAttributeInt("itemindex", -1);
	var nEntityIndex = hContextPanel.GetAttributeInt("entindex", -1);
	switch (tArgs.value)
	{
		case IW_ITEM_ACTION_EQUIP:
			DispatchCustomEvent(hContextPanel, "ItemActionEquip", { itemindex:nItemIndex, entindex:nEntityIndex, slots:hContextPanel._tPanelData.slots });
			break;
		case IW_ITEM_ACTION_UNEQUIP:
			DispatchCustomEvent(hContextPanel, "ItemActionUnequip", { itemindex:nItemIndex, entindex:nEntityIndex });
			break;
		case IW_ITEM_ACTION_USE:
			DispatchCustomEvent(hContextPanel, "ItemActionUse", { itemindex:nItemIndex, entindex:nEntityIndex });
			break;
		case IW_ITEM_ACTION_DROP:
			DispatchCustomEvent(hContextPanel, "ItemActionDrop", { itemindex:nItemIndex, entindex:nEntityIndex });
			break;
		case IW_ITEM_ACTION_INSPECT:
			DispatchCustomEvent(hContextPanel, "ItemActionInspect", { itemindex:nItemIndex, entindex:nEntityIndex });
			break;
		case IW_ITEM_ACTION_TAKE:
			DispatchCustomEvent(hContextPanel, "ItemActionTake", { itemindex:nItemIndex, entindex:nEntityIndex });
			break;
		case IW_ITEM_ACTION_STORE:
			DispatchCustomEvent(hContextPanel, "ItemActionStore", { itemindex:nItemIndex, entindex:nEntityIndex });
			break;
		default:
			break;
	}
	return true;
}

function OnItemEntryContextMenu()
{
	$.DispatchEvent("DOTAHideAbilityTooltip", $.GetContextPanel());

	var nItemFlags = $.GetContextPanel()._tPanelData.flags;
	var nItemSlots = $.GetContextPanel()._tPanelData.slots;
	var bEquipped = ($.GetContextPanel().GetAttributeInt("equipped", 0) === 1);
	var hContextMenu = $.GetContextPanel()._hContextMenu;
	
	DispatchCustomEvent(hContextMenu, "ContextItemVisible", { value:IW_ITEM_ACTION_EQUIP, state:((nItemSlots !== 0) && (!bEquipped)) });
	DispatchCustomEvent(hContextMenu, "ContextItemVisible", { value:IW_ITEM_ACTION_UNEQUIP, state:(((nItemFlags & IW_ITEM_FLAG_CANNOT_UNEQUIP) === 0) && (bEquipped)) });
	DispatchCustomEvent(hContextMenu, "ContextItemVisible", { value:IW_ITEM_ACTION_USE, state:((nItemFlags & IW_ITEM_FLAG_CAN_ACTIVATE) !== 0) });
	DispatchCustomEvent(hContextMenu, "ContextItemVisible", { value:IW_ITEM_ACTION_READ, state:((nItemFlags & IW_ITEM_FLAG_CAN_READ) !== 0) });
	
	var nContextFilter = $.GetContextPanel().GetAttributeInt("filter", 0);
	for (var i = 1; i < IW_ITEM_ACTION_MAX; i++)
	{
		if ((nContextFilter & (1 << i)) === 0)
		{
			DispatchCustomEvent(hContextMenu, "ContextItemVisible", { value:i, state:false });
		}
	}

	/*
	hContextMenu._tMenuEntries[IW_ITEM_ACTION_EQUIP].visible = false;
	hContextMenu._tMenuEntries[IW_ITEM_ACTION_UNEQUIP].visible = false;
	hContextMenu._tMenuEntries[IW_ITEM_ACTION_USE].visible = false;
	
	if ((nItemType & 1044984) !== 0)
	{
		if ($.GetContextPanel().GetAttributeInt("equipped", 0) == 1)
			hContextMenu._tMenuEntries[IW_ITEM_ACTION_UNEQUIP].visible = true;
		else
			hContextMenu._tMenuEntries[IW_ITEM_ACTION_EQUIP].visible = true;
	}
	else if ((nItemType & 32505856) !== 0)
	{
		hContextMenu._tMenuEntries[IW_ITEM_ACTION_USE].visible = true;
	}*/
	
	DispatchCustomEvent(hContextMenu, "ContextMenuActivate");
}

function LoadItemEntryContextMenu(hPanel)
{
	var hContextMenu = CreateContextMenu(hPanel, "ContextMenu");
	hPanel._hContextMenu = hContextMenu;
	
	AddContextMenuItem(hContextMenu, $.Localize("iw_ui_item_entry_equip"), IW_ITEM_ACTION_EQUIP);
	AddContextMenuItem(hContextMenu, $.Localize("iw_ui_item_entry_unequip"), IW_ITEM_ACTION_UNEQUIP);
	AddContextMenuItem(hContextMenu, $.Localize("iw_ui_item_entry_use"), IW_ITEM_ACTION_USE);
	AddContextMenuItem(hContextMenu, $.Localize("iw_ui_item_entry_drop"), IW_ITEM_ACTION_DROP);
	AddContextMenuItem(hContextMenu, $.Localize("iw_ui_item_entry_read"), IW_ITEM_ACTION_READ);
	AddContextMenuItem(hContextMenu, $.Localize("iw_ui_item_entry_inspect"), IW_ITEM_ACTION_INSPECT);
	AddContextMenuItem(hContextMenu, $.Localize("iw_ui_item_entry_take"), IW_ITEM_ACTION_TAKE);
	AddContextMenuItem(hContextMenu, $.Localize("iw_ui_item_entry_store"), IW_ITEM_ACTION_STORE);
}

function OnItemEntryLoad()
{
	$.RegisterEventHandler("DragStart", $.GetContextPanel(), OnItemEntryDragStart);
	$.RegisterEventHandler("DragEnd", $.GetContextPanel(), OnItemEntryDragEnd);
}

function CreateItemEntry(hParent, szName, nEntityIndex, nItemIndex, tItemData, nContextFilter)
{
	var hPanel = $.CreatePanel("Panel", hParent, szName);
	hPanel.BLoadLayout("file://{resources}/layout/custom_game/ui/iw_widget_item_entry.xml", false, false);
	hPanel.SetAttributeInt("equipped", 0);
	hPanel.SetAttributeInt("entindex", nEntityIndex);
	hPanel.SetAttributeInt("itemindex", nItemIndex);
	hPanel.SetAttributeInt("filter", nContextFilter);
	hPanel._tPanelData = {};
	hPanel._tPanelData.itemindex = nItemIndex;
	for (var k in tItemData)
	{
		hPanel._tPanelData[k] = tItemData[k];
	}
	
	hPanel.FindChild("ItemIcon").SetImage("file://{images}/custom_game/icons/iw_icon_other.tga");
	for (var i = 0; i < 32; i++)
	{
		if ((stItemEntryIcons[i] != null) && ((tItemData.type & (1 << i)) !== 0))
		{
			hPanel.FindChild("ItemIcon").SetImage("file://{images}/custom_game/icons/" + stItemEntryIcons[i] + ".tga");
			break;
		}
	}
	
	RegisterCustomEventHandler(hPanel, "ItemActionEquip", OnItemActionEquip);
	RegisterCustomEventHandler(hPanel, "ItemActionUnequip", OnItemActionUnequip);
	RegisterCustomEventHandler(hPanel, "ItemActionUse", OnItemActionUse);
	RegisterCustomEventHandler(hPanel, "ItemActionDrop", OnItemActionDrop);
	RegisterCustomEventHandler(hPanel, "ItemActionInspect", OnItemActionInspect);
	RegisterCustomEventHandler(hPanel, "ItemActionTake", OnItemActionTake);
	RegisterCustomEventHandler(hPanel, "ItemActionStore", OnItemActionStore);
	RegisterCustomEventHandler(hPanel, "ItemEntryUpdate", OnItemEntryUpdate);
	RegisterCustomEventHandler(hPanel, "ItemEntryEquip", OnItemEntryEquip);
	RegisterCustomEventHandler(hPanel, "ContextItemActivate", OnItemEntryContextItemActivate);
	
	LoadItemEntryContextMenu(hPanel);
	DispatchCustomEvent(hPanel, "ItemEntryUpdate", { item:tItemData });
	
	return hPanel;
}