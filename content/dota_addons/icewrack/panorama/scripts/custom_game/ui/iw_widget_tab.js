"use strict";

function SetSelectedTab(hPanel)
{
	hPanel.SetFocus();
	hPanel.FindChild("Background").SetImage("file://{images}/custom_game/window/iw_window_tab_selected.tga");
	hPanel.FindChild("Overlay").RemoveClass("TabInactive");
	var tSiblings = hPanel.GetParent().Children();
	for (var k in tSiblings)
	{
		if ((tSiblings[k] !== hPanel) && tSiblings[k]._bIsWindowTab)
		{
			tSiblings[k].FindChild("Background").SetImage("file://{images}/custom_game/window/iw_window_tab_unselected.tga");
			tSiblings[k].FindChild("Overlay").AddClass("TabInactive");
		}
	}
	DispatchCustomEvent(hPanel, "WindowTabActivate", { panel:hPanel });
}

function OnWidgetTabActivate()
{
	SetSelectedTab($.GetContextPanel());
}

function OnWidgetTabForward()
{
	var bNextPanel = false;
	var hPanel = $.GetContextPanel();
	var tSiblings = hPanel.GetParent().Children();
	for (var k = 0; k < tSiblings.length + 1; k++)
	{
		k = k % tSiblings.length;
		if (tSiblings[k] === hPanel)
		{
			if (bNextPanel)
				return
			else
				bNextPanel = true;
		}
		else if (bNextPanel && tSiblings[k]._bIsWindowTab)
		{
			SetSelectedTab(tSiblings[k]);
			return;
		}
	}
}

function OnWidgetTabBack()
{
}

function OnWidgetTabLoad()
{
	var hPanel = $.GetContextPanel();
	var tSiblings = hPanel.GetParent().Children();
	
	hPanel.SetAttributeInt("active", 1);
	for (var k in tSiblings)
	{
		if (tSiblings[k] === hPanel)
		{
			break;
		}
		else if ((tSiblings[k] !== hPanel) && tSiblings[k]._bIsWindowTab)
		{
			hPanel.SetAttributeInt("active", 0);
			break;
		}
	}
	
	if (hPanel.GetAttributeInt("active", 0) === 1)
	{
		$("#Background").SetImage("file://{images}/custom_game/window/iw_window_tab_selected.tga");
		$("#Overlay").RemoveClass("TabInactive");
	}
	else
	{
		$("#Background").SetImage("file://{images}/custom_game/window/iw_window_tab_unselected.tga");
		$("#Overlay").AddClass("TabInactive");
	}
}

function CreateWindowTab(hParent, szName, szOverlayImage)
{
	var hPanel = $.CreatePanel("Panel", hParent, szName);
	hPanel.BLoadLayout("file://{resources}/layout/custom_game/ui/iw_widget_tab.xml", false, false);
	hPanel.FindChildTraverse("Overlay").SetImage("file://{images}/custom_game/" + szOverlayImage + ".tga");
	hPanel._bIsWindowTab = true;
	return hPanel;
}