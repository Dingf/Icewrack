"use strict";

function OnItemActionEquip(hContextPanel, tArgs)
{
	if (!DispatchCustomEvent(hContextPanel.GetParent(), "ItemActionEquip", tArgs))
	{
		var nSlots = tArgs.slots;
		var nItemIndex = tArgs.itemindex;
		var nEntityIndex = tArgs.entindex;
		var tEquippedItems = CustomNetTables.GetTableValue("inventory", String(nEntityIndex)).equipped;
			
		for (var i = 0; i < 32; i++)
		{
			if (((nSlots & (1 << i)) !== 0) && (!tEquippedItems[String(i+1)]))
			{
				GameEvents.SendCustomGameEventToServer("iw_inventory_equip_item", { entindex:nEntityIndex, slot:Number(i+1), itemindex:nItemIndex });
				return;
			}
		}
		for (var i = 0; i < 32; i++)
		{
			if ((nSlots & (1 << i)) !== 0)
			{
				GameEvents.SendCustomGameEventToServer("iw_inventory_equip_item", { entindex:nEntityIndex, slot:Number(i+1), itemindex:nItemIndex });
				return;
			}
		}
	}
	return true;
}

function OnItemActionUnequip(hContextPanel, tArgs)
{
	if (!DispatchCustomEvent(hContextPanel.GetParent(), "ItemActionUnequip", tArgs))
	{
		var nItemIndex = tArgs.itemindex;
		var nEntityIndex = tArgs.entindex;
		var tEquippedItems = CustomNetTables.GetTableValue("inventory", String(nEntityIndex)).equipped;
		for (var k in tEquippedItems)
		{
			if (tEquippedItems[k] === nItemIndex)
			{
				GameEvents.SendCustomGameEventToServer("iw_inventory_equip_item", { entindex:nEntityIndex, slot:Number(k), itemindex:-1 }); 
				break;
			}
		}
	}
	return true;
}

function OnItemActionUse(hContextPanel, tArgs)
{
	if (!DispatchCustomEvent(hContextPanel.GetParent(), "ItemActionUse", tArgs))
	{
		var nItemIndex = tArgs.itemindex;
		var nEntityIndex = tArgs.entindex;
		GameEvents.SendCustomGameEventToServer("iw_inventory_use_item", { entindex:nEntityIndex, itemindex:nItemIndex });
	}
	return true;
}

function OnItemActionDrop(hContextPanel, tArgs)
{
	if (!DispatchCustomEvent(hContextPanel.GetParent(), "ItemActionDrop", tArgs))
	{
		var nItemIndex = tArgs.itemindex;
		var nEntityIndex = tArgs.entindex;
		GameEvents.SendCustomGameEventToServer("iw_inventory_drop_item", { entindex:nEntityIndex, itemindex:nItemIndex });
	}
	return true;
}

function OnItemActionInspect(hContextPanel, tArgs)
{
	if (!DispatchCustomEvent(hContextPanel.GetParent(), "ItemActionInspect", tArgs))
	{
		//TODO: Implement this properly
		$.DispatchEvent("DismissAllContextMenus");
	}
	/*var hPanel = $.GetContextPanel()._hInventory._hPopup;
	if (hPanel)
	{
		hPanel.visible = true;
		hPanel.SetFocus();
		hPanel.FindChildTraverse("PopupText").text = $.Localize("#inspect_" + $.GetContextPanel()._tPanelData.name);
	}*/
	return true;
}

function OnItemActionTake(hContextPanel, tArgs)
{
	if (!DispatchCustomEvent(hContextPanel.GetParent(), "ItemActionTake", tArgs))
	{
		//Don't do anything; we handle taking/storing in lootable
	}
	return true;
}

function OnItemActionStore(hContextPanel, tArgs)
{
	if (!DispatchCustomEvent(hContextPanel.GetParent(), "ItemActionStore", tArgs))
	{
		//Don't do anything; we handle taking/storing in lootable
	}
	return true;
}