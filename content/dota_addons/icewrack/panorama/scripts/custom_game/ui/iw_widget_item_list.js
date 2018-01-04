"use strict";

var tComparatorList =
[
	function(hPanel1, hPanel2) { return hPanel1._tPanelData.type <= hPanel2._tPanelData.type; },
	function(hPanel1, hPanel2) { return hPanel1._tPanelData.type >= hPanel2._tPanelData.type; },
	function(hPanel1, hPanel2) { return $.Localize("DOTA_Tooltip_Ability_" + hPanel1._tPanelData.name) <= $.Localize("DOTA_Tooltip_Ability_" + hPanel2._tPanelData.name); },
	function(hPanel1, hPanel2) { return $.Localize("DOTA_Tooltip_Ability_" + hPanel1._tPanelData.name) >= $.Localize("DOTA_Tooltip_Ability_" + hPanel2._tPanelData.name); },
	function(hPanel1, hPanel2) { return hPanel1._tPanelData.value <= hPanel2._tPanelData.value; },
	function(hPanel1, hPanel2) { return hPanel1._tPanelData.value >= hPanel2._tPanelData.value; },
	function(hPanel1, hPanel2) { return hPanel1._tPanelData.weight <= hPanel2._tPanelData.weight; },
	function(hPanel1, hPanel2) { return hPanel1._tPanelData.weight >= hPanel2._tPanelData.weight; }
];


function ItemListMergeSort(tBuffer, nStartIndex, nEndIndex, hComparator, tChildren)
{
	if (nEndIndex - nStartIndex <= 1)
		return;
	
	var nMidIndex = Math.floor((nStartIndex + nEndIndex)/2);
	ItemListMergeSort(tChildren, nStartIndex, nMidIndex, hComparator, tBuffer);
	ItemListMergeSort(tChildren, nMidIndex, nEndIndex, hComparator, tBuffer);
	
	var nLeftOffset = nStartIndex;
	var nRightOffset = nMidIndex;
	for (var i = nStartIndex; i < nEndIndex; i++)
	{
		if ((nLeftOffset < nMidIndex) && ((nRightOffset >= nEndIndex) || hComparator(tBuffer[nLeftOffset], tBuffer[nRightOffset])))
		{
			tChildren[i] = tBuffer[nLeftOffset];
			nLeftOffset++;
		}
		else
		{
			tChildren[i] = tBuffer[nRightOffset];
			nRightOffset++;
		}
	}
}

function ItemListSort(hContextPanel, hComparator)
{
	var hBodyPanel = hContextPanel.FindChildTraverse("ListBody");
	var tChildren = hBodyPanel.Children();
	var tBuffer = tChildren.slice();
	ItemListMergeSort(tBuffer, 0, tChildren.length, hComparator, tChildren);
	for (var i = 1; i < tChildren.length; i++)
	{
		hBodyPanel.MoveChildAfter(tChildren[i], tChildren[i-1]);
	}
}

function OnItemListSort(hContextPanel, tArgs)
{
	var hCategoryPanel = (tArgs && tArgs.panel) ? tArgs.panel : hContextPanel._hCurrentSortCategory;
	var nCategoryID = hCategoryPanel.GetAttributeInt("category", 0);
	var nSortState = hCategoryPanel.GetAttributeInt("sort_state", 0);
	ItemListSort(hContextPanel, tComparatorList[(nCategoryID * 2) + nSortState]);
	
	var tSortCategories = hContextPanel._tSortCategories;
	for (var i = 0; i < tSortCategories.length; i++)
	{
		var szCategoryLabel = $.Localize(tSortCategories[i].GetAttributeString("label", ""));
		if (tSortCategories[i] == hCategoryPanel)
		{
			tSortCategories[i].SetAttributeInt("sort_state", nSortState);
			tSortCategories[i].FindChild("SortDirection").visible = true;
			tSortCategories[i].FindChild("SortDirection").SetHasClass("DirectionIconSortAscending", (nSortState === 0));
			hContextPanel._hCurrentSortCategory = tSortCategories[i];
		}
		else
		{
			tSortCategories[i].SetAttributeInt("sort_state", 1);
			tSortCategories[i].FindChild("SortDirection").visible = false;
		}
	}
	return true;
}

function OnItemListFocus(hContextPanel, tArgs)
{
	hContextPanel.SetFocus();
	SetSelectedTab(hContextPanel.FindChildTraverse("TabAll"));
	return true;
}

function OnItemListUpdate(hContextPanel, tArgs)
{
	var nEntityIndex = hContextPanel.GetAttributeInt("entindex", -1);
	var tInventoryData = CustomNetTables.GetTableValue("inventory", nEntityIndex);
	
	if (typeof(tInventoryData) === "undefined")
		return;
	
	var nContextFilter = hContextPanel.GetAttributeInt("context_filter", 0);
	var nItemFilter = hContextPanel.GetAttributeInt("item_filter", 0);
	var tItemList = tInventoryData.item_list;
	for (var k in hContextPanel._tItemPanels)
	{
		if (!tItemList[k])
		{
			hContextPanel._tItemPanels[k].visible = false;
		}
	}
	var hBodyPanel = hContextPanel.FindChildTraverse("ListBody");
	for (var k in tItemList)
	{
		var tItemData = CustomNetTables.GetTableValue("items", k);
		if (tItemData.flags & IW_ITEM_FLAG_HIDDEN)
		{
			continue;
		}
		
		if (!hContextPanel._tItemPanels[k])
		{
			hContextPanel._tItemPanels[k] = CreateItemEntry(hBodyPanel, "Item" + k, nEntityIndex, Number(k), tItemData, nContextFilter);
		}
		else
		{
			hContextPanel._tItemPanels[k].visible = true;
			DispatchCustomEvent(hContextPanel._tItemPanels[k], "ItemEntryUpdate", { item:tItemData });
		}
		
		DispatchCustomEvent(hContextPanel._tItemPanels[k], "ItemEntryEquip", { state:false });
		if ((nItemFilter !== 0) && (tItemData.type > 0))
		{
			if ((nItemFilter & tItemData.type) === 0)
			{
				hContextPanel._tItemPanels[k].visible = false;
			}
		}
	}
	var tEquippedItems = tInventoryData.equipped;
	for (var k in tEquippedItems)
	{
		var nItemIndex = tEquippedItems[k];
		DispatchCustomEvent(hContextPanel._tItemPanels[nItemIndex], "ItemEntryEquip", { state:true });
	}
	
	DispatchCustomEvent(hContextPanel, "ItemListSort");
	return true;
}

function UpdateEntityItemList(szTableName, szKey, tData)
{
	var nEntityIndex = $.GetContextPanel().GetAttributeInt("entindex", -1);
	if (parseInt(szKey) === nEntityIndex)
	{
		$.Schedule(0.03, DispatchCustomEvent.bind(this, $.GetContextPanel(), "ItemListUpdate"));
	}
}

function OnWindowTabActivate(hContextPanel, tArgs)
{
	var hPanel = tArgs.panel;
	if (hPanel.id === "TabAll")
	{
		hContextPanel.FindChildTraverse("TabLabel").text = $.Localize("#iw_ui_item_list_all_items");
		hContextPanel.SetAttributeInt("item_filter", 0);
	}
	else if (hPanel.id === "TabWeapons")
	{
		hContextPanel.FindChildTraverse("TabLabel").text = $.Localize("#iw_ui_item_list_weapons");
		hContextPanel.SetAttributeInt("item_filter", 504);
	}
	else if (hPanel.id === "TabArmor")
	{
		hContextPanel.FindChildTraverse("TabLabel").text = $.Localize("#iw_ui_item_list_armor_jewelry");
		hContextPanel.SetAttributeInt("item_filter", 1044480);
	}
	else if (hPanel.id == "TabConsumables")
	{
		hContextPanel.FindChildTraverse("TabLabel").text = $.Localize("#iw_ui_item_list_consumables");
		hContextPanel.SetAttributeInt("item_filter", 32505856);
	}
	else if (hPanel.id === "TabReagents")
	{
		hContextPanel.FindChildTraverse("TabLabel").text = $.Localize("#iw_ui_item_list_crafting");
		hContextPanel.SetAttributeInt("item_filter", 2113929216);
	}
	else if (hPanel.id == "TabMisc")
	{
		hContextPanel.FindChildTraverse("TabLabel").text = $.Localize("#iw_ui_item_list_misc");
		hContextPanel.SetAttributeInt("item_filter", 2147483649);
	}
	DispatchCustomEvent(hContextPanel, "ItemListUpdate");
	return true;
}

function OnItemListTypeSort()
{
	$("#TypeCategory").SetAttributeInt("sort_state", 1 - $("#TypeCategory").GetAttributeInt("sort_state", 0));
	DispatchCustomEvent($.GetContextPanel(), "ItemListSort", { panel:$("#TypeCategory") });
}

function OnItemListNameSort()
{
	$("#NameCategory").SetAttributeInt("sort_state", 1 - $("#NameCategory").GetAttributeInt("sort_state", 0));
	DispatchCustomEvent($.GetContextPanel(), "ItemListSort", { panel:$("#NameCategory") });
}

function OnItemListValueSort()
{
	$("#ValueCategory").SetAttributeInt("sort_state", 1 - $("#ValueCategory").GetAttributeInt("sort_state", 0));
	DispatchCustomEvent($.GetContextPanel(), "ItemListSort", { panel:$("#ValueCategory") });
}

function OnItemListWeightSort()
{
	$("#WeightCategory").SetAttributeInt("sort_state", 1 - $("#WeightCategory").GetAttributeInt("sort_state", 0));
	DispatchCustomEvent($.GetContextPanel(), "ItemListSort", { panel:$("#WeightCategory") });
}

function OnItemListLoad()
{
	var hTabContainer = $("#TabContainer");
	var hFrontSpacer = $.CreatePanel("Image", hTabContainer, "TabSpacer1");
	hFrontSpacer.SetImage("file://{images}/custom_game/window/iw_window_tab_spacer.tga");
	
	CreateWindowTab(hTabContainer, "TabAll", "inventory/iw_inventory_tab_all");
	CreateWindowTab(hTabContainer, "TabWeapons", "inventory/iw_inventory_tab_weapons");
	CreateWindowTab(hTabContainer, "TabArmor", "inventory/iw_inventory_tab_armor");
	CreateWindowTab(hTabContainer, "TabConsumables", "inventory/iw_inventory_tab_consumables");
	CreateWindowTab(hTabContainer, "TabReagents", "inventory/iw_inventory_tab_reagents");
	CreateWindowTab(hTabContainer, "TabMisc", "inventory/iw_inventory_tab_misc");
	
	var hBackSpacer = $.CreatePanel("Image", hTabContainer, "TabSpacer2");
	hBackSpacer.SetImage("file://{images}/custom_game/window/iw_window_tab_spacer.tga");
	
	var hTabLabel = $.CreatePanel("Label", $.GetContextPanel(), "TabLabel");
	hTabLabel.AddClass("ItemListTabLabel");
	$("#TabLabel").text = $.Localize("#iw_ui_item_list_all_items");
	$.GetContextPanel().SetAttributeInt("item_filter", 0);
	
	CreateVerticalScrollbar($("#ListContainer"), "ItemListScrollbar", $("#ListBody"));
	
	$.GetContextPanel()._tSortCategories = [ $("#TypeCategory"), $("#NameCategory"), $("#ValueCategory"), $("#WeightCategory") ];
	for (var i = 0; i < $.GetContextPanel()._tSortCategories.length; i++)
	{
		$.GetContextPanel()._tSortCategories[i].SetAttributeInt("category", i);
		$.GetContextPanel()._tSortCategories[i].SetAttributeInt("sort_state", 0);
	}
	$("#NameCategory").SetAttributeString("label", "iw_ui_item_list_name");
	$("#ValueCategory").SetAttributeString("label", "iw_ui_item_list_value");
	$("#WeightCategory").SetAttributeString("label", "iw_ui_item_list_weight");
	DispatchCustomEvent($.GetContextPanel(), "ItemListSort", { panel:$("#NameCategory") });
}

function CreateItemList(hParent, szName, nContextFilter)
{
	var hPanel = $.CreatePanel("Panel", hParent, szName);
	hPanel.BLoadLayout("file://{resources}/layout/custom_game/ui/iw_widget_item_list.xml", false, false);
	hPanel.SetAttributeInt("context_filter", nContextFilter);
	hPanel._tItemPanels = {};
	
	RegisterCustomEventHandler(hPanel, "ItemListFocus", OnItemListFocus);
	RegisterCustomEventHandler(hPanel, "ItemListUpdate", OnItemListUpdate);
	RegisterCustomEventHandler(hPanel, "ItemListSort", OnItemListSort);
	RegisterCustomEventHandler(hPanel, "WindowTabActivate", OnWindowTabActivate);
	
	CustomNetTables.SubscribeNetTableListener("inventory", UpdateEntityItemList);
	
	return hPanel
}