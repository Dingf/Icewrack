"use strict";

function AddContextMenuItem(hParent, szText, mValue)
{
	if (szText === "")
		return;
	
	if (!hParent._tMenuEntries)
	{
		hParent._nMenuSize = 0;
		hParent._tMenuEntries = {};
	}
	if (!hParent._tMenuEntries[mValue])
	{
		var hPanel = CreateContextItem(hParent, "Context" + mValue, szText);
		hPanel._mValue = mValue;
		hParent._tMenuEntries[mValue] = hPanel;
		hParent._nMenuSize++;
	}
}

function OnContextItemVisible(hContextPanel, tArgs)
{
	var hContextItem = hContextPanel._tMenuEntries[tArgs.value];
	if (hContextItem && (typeof(tArgs.state) === "boolean"))
	{
		hContextItem.visible = tArgs.state;
	}
	return true;
}

function OnContextItemActivate(hContextPanel, tArgs)
{
	hContextPanel.visible = false;
	DispatchCustomEvent(hContextPanel._hOriginalParent, "ContextItemActivate", tArgs);
	return true;
}

function OnContextMenuActivate(hContextPanel, tArgs)
{
	var vCursorPosition = GameUI.GetCursorPosition();
	hContextPanel.style.position = ((vCursorPosition[0] * GameUI.GetScaleRatio()) - 1) + "px " + ((vCursorPosition[1] * GameUI.GetScaleRatio()) - 1) + "px 0px";
	hContextPanel.visible = true;
	return true;
}

function CreateContextMenu(hParent, szName)
{
	var hPanel = $.CreatePanel("Panel", hParent, szName);
	hPanel.BLoadLayout("file://{resources}/layout/custom_game/ui/iw_context_menu.xml", false, false);
	hPanel.visible = false;
	hPanel.SetPanelEvent("onmouseout", function() { hPanel.visible = false; });
	hPanel._hOriginalParent = hParent;
	hPanel.SetParent(GameUI.GetMenuRoot());
	
	RegisterCustomEventHandler(hPanel, "ContextItemVisible", OnContextItemVisible);
	RegisterCustomEventHandler(hPanel, "ContextItemActivate", OnContextItemActivate);
	RegisterCustomEventHandler(hPanel, "ContextMenuActivate", OnContextMenuActivate);
	
	return hPanel
}