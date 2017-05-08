"use strict";

function OnDropdownMenuMouseOut()
{
	$.GetContextPanel()._hMenuList.visible = false;
	$("#Button").RemoveClass("DropdownButtonActive");
}

function OnDropdownListMouseOver()
{
	$.GetContextPanel()._hMenuList.visible = true;
	$("#Button").AddClass("DropdownButtonActive");
}

function OnDropdownListMouseOut()
{
	$.GetContextPanel()._hMenuList.visible = false;
	$("#Button").RemoveClass("DropdownButtonActive");
}

function OnDropdownMenuUpdateValue(hContextPanel, tArgs)
{
	hContextPanel._mValue = tArgs.value;
	hContextPanel._hMenuList.visible = false;
	hContextPanel.FindChildTraverse("Label").text = hContextPanel._tMenuEntries[tArgs.value].FindChildTraverse("Text").text;
	return false;
}

function OnDropdownMenuUpdateValueQuiet(hContextPanel, tArgs)
{
	hContextPanel._mValue = tArgs.value;
	hContextPanel._hMenuList.visible = false;
	hContextPanel.FindChildTraverse("Label").text = hContextPanel._tMenuEntries[tArgs.value].FindChildTraverse("Text").text;
	return true;
}

function OnDropdownMenuClear(hContextPanel, tArgs)
{
	hContextPanel._hMenuList.RemoveAndDeleteChildren();
	hContextPanel._tMenuEntries = {};
	hContextPanel._nMenuSize = 0;
	return true;
}

function SetDropdownListWidth()
{
	var tDropdownOptions = $.GetContextPanel()._hMenuList.Children();
	for (var k in tDropdownOptions)
	{
		tDropdownOptions[k].style.width = (Math.max($("#Body").contentwidth, $.GetContextPanel()._hMenuList.contentwidth) * GameUI.GetScaleRatio()) + "px";
	}
}

function OnDropdownButtonActivate()
{
	if (($.GetContextPanel()._hMenuList.visible) && ($.GetContextPanel()._hMenuList.style.height === "fit-children"))
	{
		$.GetContextPanel()._hMenuList.visible = false;
		$("#Button").RemoveClass("DropdownButtonActive");
	}
	else
	{
		var xOffset = 0;
		var yOffset = 0;
		var hRoot = $.GetContextPanel();
		while (hRoot.GetParent())
		{
			xOffset += hRoot.actualxoffset;
			yOffset += hRoot.actualyoffset;
			hRoot = hRoot.GetParent();
		}
		xOffset = xOffset * GameUI.GetScaleRatio();
		yOffset = yOffset * GameUI.GetScaleRatio();
		$.GetContextPanel()._hMenuList.visible = true;
		$.GetContextPanel()._hMenuList.style.position = xOffset + "px " + (yOffset + 27) + "px 0px";
		$.GetContextPanel()._hMenuList.style.height = "fit-children";
		$("#Button").AddClass("DropdownButtonActive");
		SetDropdownListWidth();
	}
}

function AddDropdownMenuItem(hParent, szText, mValue)
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
		var hMenuList = hParent._hMenuList
		var hPanel = $.CreatePanel("Panel", hMenuList, "Dropdown" + mValue);
		hPanel.BLoadLayout("file://{resources}/layout/custom_game/ui/iw_dropdown_item.xml", false, false);
		hPanel.FindChildTraverse("Text").text = szText;
		hPanel._mValue = mValue;
		hPanel.SetPanelEvent("onactivate", function()
		{
			DispatchCustomEvent(hParent, "DropdownValueUpdate", { panel:hParent, value:mValue });
		});
		if (hParent._nMenuSize === 0)
		{
			hParent._mValue = mValue;
			hParent.FindChildTraverse("Label").text = hPanel.FindChildTraverse("Text").text;
		}
		hParent._tMenuEntries[mValue] = hPanel;
		hParent._nMenuSize++;
		return hPanel;
	}
	else
	{
		return hParent._tMenuEntries[mValue];
	}
}

function OnDropdownMenuLoad()
{
	$.GetContextPanel()._hMenuList.SetPanelEvent("onmouseover", OnDropdownListMouseOver);
	$.GetContextPanel()._hMenuList.SetPanelEvent("onmouseout", OnDropdownListMouseOut);
};

function CreateDropdownMenu(hParent, szName)
{
	var hPanel = $.CreatePanel("Panel", hParent, szName);
	hPanel.BLoadLayout("file://{resources}/layout/custom_game/ui/iw_dropdown_menu.xml", false, false);
	
	hPanel._hMenuList = hPanel.FindChildTraverse("DropdownList");
	hPanel._hMenuList.SetParent(GameUI.GetMenuRoot());
	
	RegisterCustomEventHandler(hPanel, "DropdownValueUpdate", OnDropdownMenuUpdateValue);
	RegisterCustomEventHandler(hPanel, "DropdownValueUpdateQuiet", OnDropdownMenuUpdateValueQuiet);
	RegisterCustomEventHandler(hPanel, "DropdownMenuClear", OnDropdownMenuClear);
	
	return hPanel;
}