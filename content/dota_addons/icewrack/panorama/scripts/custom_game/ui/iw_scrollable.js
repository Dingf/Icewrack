"use strict";

function UpdateScrollable()
{
	for (var i = $("#Scrollable")._tMouseOverStack.length; i > 0; i--)
	{
		$("#Scrollable")._tScrollableStack.push($("#Scrollable")._tMouseOverStack[i-1]);
	}
	$("#Scrollable")._tMouseOverStack = [];
	$.GetContextPanel()._nUpdateCallbackID = 0;
}

function OnScrollableMouseOver(hContextPanel, tArgs)
{
	hContextPanel._tMouseOverStack.push(tArgs.panel);
	if (hContextPanel._nUpdateCallbackID !== 0)
		hContextPanel._nUpdateCallbackID = $.Schedule(0.03, UpdateScrollable);
	return true;
}

function OnScrollableMouseOut(hContextPanel, tArgs)
{
	var tScrollableStack = $("#Scrollable")._tScrollableStack;
	for (var i = 0; i < tScrollableStack.length; i++)
	{
		if (tScrollableStack[i] === tArgs.panel)
		{
			$("#Scrollable")._tScrollableStack.splice(i, tScrollableStack.length);
			break;
		}
	}
	return true;
}

function OnScrollableMouseEvent(hContextPanel, tArgs)
{
	var tScrollableStack = $("#Scrollable")._tScrollableStack;
	if ((tScrollableStack.length > 0) && (tArgs.event === "wheeled"))
	{
		var hScrollablePanel = tScrollableStack[tScrollableStack.length-1];
		if (hScrollablePanel.visible)
		{
			DispatchCustomEvent(hScrollablePanel, "PanelScroll", { value:(tArgs.value * 32.0) });
			return true;
		}
	}
	return false;
}

(function()
{
	var hScrollable = $("#Scrollable");
	hScrollable._tScrollableStack = [];
	hScrollable._tMouseOverStack = [];
	
	RegisterCustomEventHandler(hScrollable, "ScrollableMouseOver", OnScrollableMouseOver);
	RegisterCustomEventHandler(hScrollable, "ScrollableMouseOut", OnScrollableMouseOut);
	RegisterCustomEventHandler(hScrollable, "MouseEvent", OnScrollableMouseEvent);
})();