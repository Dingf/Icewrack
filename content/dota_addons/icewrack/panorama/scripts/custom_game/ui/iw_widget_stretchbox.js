"use strict";

function OnStretchBoxRefresh(hContextPanel, tArgs)
{
	var nPanelWidth = 21;
	if (hContextPanel.style.width)
		nPanelWidth = Math.max(Number(hContextPanel.style.width.split("px")[0]), 21);
	hContextPanel.FindChildTraverse("TopMid").style.width = (nPanelWidth - 20) + "px";
	hContextPanel.FindChildTraverse("Center").style.width = (nPanelWidth - 20) + "px";
	hContextPanel.FindChildTraverse("BottomMid").style.width = (nPanelWidth - 20) + "px";

	var nPanelHeight = 21;
	if (hContextPanel.style.height)
		nPanelHeight = Math.max(Number(hContextPanel.style.height.split("px")[0]), 21);
	hContextPanel.FindChildTraverse("MidLeft").style.height = (nPanelHeight - 20) + "px";
	hContextPanel.FindChildTraverse("Center").style.height = (nPanelHeight - 20) + "px";
	hContextPanel.FindChildTraverse("MidRight").style.height = (nPanelHeight - 20) + "px";
	return true;
}

function OnStretchBoxLoad()
{
	RegisterCustomEventHandler($.GetContextPanel(), "StretchBoxRefresh", OnStretchBoxRefresh);
	OnStretchBoxRefresh($.GetContextPanel(), null);
}