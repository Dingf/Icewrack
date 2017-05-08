"use strict";

var nCurrentItemIndex = 0;

var tDefaultInventorySlotTextures =
[
	"iw_inventory_default_main_hand",
	"iw_inventory_default_off_hand",
	"iw_inventory_default_head",
	"iw_inventory_default_armor",
	"iw_inventory_default_gloves",
	"iw_inventory_default_boots",
	"iw_inventory_default_belt",
	"iw_inventory_default_lring",
	"iw_inventory_default_rring",
	"iw_inventory_default_amulet",
	"iw_inventory_quick_slot",
	"iw_inventory_quick_slot",
	"iw_inventory_quick_slot",
	"iw_inventory_quick_slot",
];

function OnInventorySlotUpdate(hContextPanel, tArgs)
{
	var nSlot = hContextPanel.GetAttributeInt("slot", -1);
	var nEntityIndex = tArgs.entindex ? tArgs.entindex : hContextPanel.GetAttributeInt("entindex", -1);
	var tInventoryData = CustomNetTables.GetTableValue("inventory", nEntityIndex);
	if (typeof(tInventoryData) !== "undefined")
	{
		hContextPanel.SetAttributeInt("entindex", nEntityIndex);
		var nItemIndex = tInventoryData.equipped[nSlot];
		if (typeof(nItemIndex) !== "undefined")
		{
			if (nItemIndex !== nCurrentItemIndex)
			{
				var tItemData = tInventoryData.item_list[nItemIndex];
				hContextPanel.FindChildTraverse("ItemTexture").SetImage("file://{images}/items/" + tItemData.name + ".tga");
				hContextPanel.FindChildTraverse("ItemTexture").style.opacity = "1.0";
				for (var k in tItemData)
				{
					hContextPanel._tPanelData[k] = tItemData[k];
				}
				hContextPanel._tPanelData.itemindex = nItemIndex;
				hContextPanel.SetAttributeInt("itemindex", nItemIndex);
				hContextPanel._szName = tItemData.name;
				hContextPanel.FindChildTraverse("StackCount").text = "x" + tItemData.stack;
				hContextPanel.FindChildTraverse("StackCount").visible = (tItemData.stack > 1);
			}
		}
		else if (nCurrentItemIndex !== -1)
		{
			var szDefaultTexture = hContextPanel.GetAttributeString("default_texture", "");
			hContextPanel.FindChildTraverse("ItemTexture").SetImage("file://{images}/custom_game/inventory/" + szDefaultTexture + ".tga");
			hContextPanel.FindChildTraverse("ItemTexture").style.opacity = "0.25";
			hContextPanel._tPanelData.itemindex = -1;
			hContextPanel.SetAttributeInt("itemindex", -1);
			hContextPanel._szName = "";
			hContextPanel.FindChildTraverse("StackCount").visible = false;
		}
	}
}

function OnInventorySlotMouseOver()
{
	var nItemIndex = $.GetContextPanel().GetAttributeInt("itemindex", -1);
	if (nItemIndex !== -1)
	{
		var nEntityIndex = $.GetContextPanel().GetAttributeInt("entindex", -1);
		$.DispatchEvent("DOTAShowAbilityTooltipForEntityIndex", $.GetContextPanel(), $.GetContextPanel()._szName, nEntityIndex);
	}
	else
	{
		var nSlot = $.GetContextPanel().GetAttributeInt("slot", 0);
		if (nSlot !== 0)
		{
			$.DispatchEvent("DOTAShowTextTooltip", $.GetContextPanel(), $.Localize("iw_ui_inventory_slot" + nSlot));
		}
	}
}

function OnInventorySlotMouseOut()
{
	$.DispatchEvent("DOTAHideAbilityTooltip", $.GetContextPanel());
	$.DispatchEvent("DOTAHideTextTooltip", $.GetContextPanel());
}

function OnInventorySlotDragEnter(szPanelID, hDraggedPanel)
{
	var nDragType = hDraggedPanel._nDragType;
	if (nDragType & 0x03)
	{
		var nSlotFlag = (1 << ($.GetContextPanel().GetAttributeInt("slot", 0) - 1));
		if (((hDraggedPanel._tPanelData.slots & nSlotFlag) !== 0) && (hDraggedPanel._tPanelData.itemindex !== $.GetContextPanel().GetAttributeInt("itemindex", -1)))
		{
			$("#Overlay").AddClass("PotentialEquip");
		}
	}
	return true;
}

function OnInventorySlotDragLeave(szPanelID, hDraggedPanel)
{
	$("#Overlay").RemoveClass("PotentialEquip");
	return true;
}

function OnInventorySlotDragDrop(szPanelID, hDraggedPanel)
{
	var nDragType = hDraggedPanel._nDragType;
	if ((typeof(nDragType) === "undefined") || !(nDragType & 0x03))
		return true;
		
	hDraggedPanel._bDragCompleted = true;
	var nSlot = $.GetContextPanel().GetAttributeInt("slot", 0);
	if (((hDraggedPanel._tPanelData.slots & (1 << (nSlot - 1))) !== 0) && (hDraggedPanel._tPanelData.itemindex !== $.GetContextPanel().GetAttributeInt("itemindex", -1)))
	{
		for (var k in hDraggedPanel._tPanelData)
		{
			$.GetContextPanel()._tPanelData[k] = hDraggedPanel._tPanelData[k];
		}
		$.GetContextPanel().SetAttributeInt("itemindex", hDraggedPanel._tPanelData.itemindex);
		var nEntityIndex = $.GetContextPanel().GetAttributeInt("entindex", -1);
		GameEvents.SendCustomGameEventToServer("iw_inventory_equip_item", { entindex:nEntityIndex, slot:nSlot, itemindex:hDraggedPanel._tPanelData.itemindex });
	}
	return true;
}

function OnInventorySlotDragStart(hPanel, hDraggedPanel)
{
	if ($.GetContextPanel().GetAttributeInt("itemindex", -1) === -1)
		return true;
	
	var szItemName = $.GetContextPanel()._szName;
	if (szItemName === "")
		return true;
	
	if (!GameUI.IsMouseDown(0))
		return true;
	
	$.DispatchEvent("DOTAHideAbilityTooltip", $.GetContextPanel());
	$.GetContextPanel().SetAttributeInt("tooltip_active", 0);
	
	var hDisplayPanel = $.CreatePanel("Image", $.GetContextPanel(), "ItemDrag");
	hDisplayPanel._tPanelData = {}
	hDisplayPanel.SetImage("file://{images}/items/" + szItemName + ".tga");
	for (var k in $.GetContextPanel()._tPanelData)
	{
		hDisplayPanel._tPanelData[k] = $.GetContextPanel()._tPanelData[k];
	}
	hDisplayPanel._nDragType = 0x02;
	hDisplayPanel._bDragCompleted = false;
	
	hDraggedPanel.displayPanel = hDisplayPanel;
	hDraggedPanel.offsetX = 0;
	hDraggedPanel.offsetY = 0;
	return true;
}

function OnInventorySlotDragEnd(hPanel, hDraggedPanel)
{	
	if (!hDraggedPanel._bDragCompleted)
	{
		var nSlot = $.GetContextPanel().GetAttributeInt("slot", 0);
		var nEntityIndex = $.GetContextPanel().GetAttributeInt("entindex", -1);
		GameEvents.SendCustomGameEventToServer("iw_inventory_equip_item", { entindex:nEntityIndex, slot:nSlot, itemindex:-1 });
	}
	hDraggedPanel.DeleteAsync(0);
	return true;
}

function OnInventorySlotLoad()
{
	$.RegisterEventHandler("DragEnter", $.GetContextPanel(), OnInventorySlotDragEnter);
	$.RegisterEventHandler("DragDrop", $.GetContextPanel(), OnInventorySlotDragDrop);
	$.RegisterEventHandler("DragLeave", $.GetContextPanel(), OnInventorySlotDragLeave);
	$.RegisterEventHandler("DragStart", $.GetContextPanel(), OnInventorySlotDragStart);
	$.RegisterEventHandler("DragEnd", $.GetContextPanel(), OnInventorySlotDragEnd);
}

function CreateInventorySlotPanel(hParent, szName, nSlot, nWidth, nHeight, nOffsetX, nOffsetY)
{
	var hPanel = $.CreatePanel("Panel", hParent, szName);
	hPanel.BLoadLayout("file://{resources}/layout/custom_game/inventory/iw_inventory_slot.xml", false, false);
	hPanel._tPanelData = {}
	hPanel.SetAttributeInt("slot", nSlot);
	if (nSlot <= tDefaultInventorySlotTextures.length)
	{
		hPanel.FindChild("ItemTexture").SetImage("file://{images}/custom_game/inventory/" + tDefaultInventorySlotTextures[nSlot-1] + ".tga");
		hPanel.SetAttributeString("default_texture", tDefaultInventorySlotTextures[nSlot-1]);
	}
	
	hPanel.FindChild("Overlay").style.width = (nWidth - 14) + "px";
	hPanel.FindChild("Overlay").style.height = (nHeight - 14) + "px";
	hPanel.FindChild("Background").style.width = nWidth + "px";
	hPanel.FindChild("Background").style.height = nHeight + "px";
	hPanel.FindChild("Background").BLoadLayout("file://{resources}/layout/custom_game/ui/iw_widget_stretchbox.xml", false, false);
	
	//CustomNetTables.SubscribeNetTableListener("inventory", UpdateInventorySlot);
	RegisterCustomEventHandler(hPanel, "InventorySlotUpdate", OnInventorySlotUpdate);
	
	hPanel.style.x = nOffsetX + "px";
	hPanel.style.y = nOffsetY + "px";
	return hPanel;
}