"use strict";

var SCROLL_TYPE_VERTICAL = 1;
var SCROLL_TYPE_HORIZONTAL = 0;

var stScrollHelperPanelValues = [32, -32, 4, -4];

function OnScrollbarPositionUpdate(hContextPanel, tArgs)
{
	var fScrollOffset = hContextPanel._hRefPanel._fScrollOffset;
	var fScrollAmount = hContextPanel._hRefPanel._fScrollAmount + fScrollOffset;
	var fContentSize = hContextPanel._hRefPanel["content" + hContextPanel._szVarSize1] * GameUI.GetScaleRatio() - fScrollOffset;
	var fParentSize = hContextPanel.GetParent()["actuallayout" + hContextPanel._szVarSize1] * GameUI.GetScaleRatio();
	var fScrollSize = fParentSize - 52;
	var fScrollbarSize = Math.floor((fParentSize > fContentSize) ? fScrollSize : (fParentSize * fScrollSize)/fContentSize);
	
	var fScrollMax = Math.min(fScrollAmount, (fParentSize - fContentSize));
	var fScrollPosition = (fScrollAmount/fScrollMax) * (fScrollSize - fScrollbarSize);
	var hThumb = hContextPanel.FindChildTraverse("Thumb");
	hThumb.style[hContextPanel._szVarOffset] = Math.floor(fScrollPosition + 26) + "px";
	
	var hScrollRegion1 = hContextPanel.FindChildTraverse("ScrollRegion1");
	hScrollRegion1.style[hContextPanel._szVarSize1] = Math.floor(fScrollPosition) + "px";
	hScrollRegion1.style[hContextPanel._szVarOffset] = "31px";
	var hScrollRegion2 = hContextPanel.FindChildTraverse("ScrollRegion2");
	hScrollRegion2.style[hContextPanel._szVarSize1] = Math.floor(fScrollSize - fScrollPosition - fScrollbarSize) + "px";
	hScrollRegion2.style[hContextPanel._szVarOffset] = Math.floor(fScrollPosition + fScrollbarSize + 21) + "px";
	return true;
}

function OnScrollbarSizeUpdate(hContextPanel, tArgs)
{
	var bIsVertical = (hContextPanel._nScrollType === SCROLL_TYPE_VERTICAL);
	var fScrollOffset = hContextPanel._hRefPanel._fScrollOffset;
	var fContentSize = hContextPanel._hRefPanel["content" + hContextPanel._szVarSize1] * GameUI.GetScaleRatio() - fScrollOffset;
	var fParentSize = hContextPanel.GetParent()["actuallayout" + hContextPanel._szVarSize1] * GameUI.GetScaleRatio();
	var fScrollSize = fParentSize - 52;
	var fScrollbarSize = Math.floor((fParentSize > fContentSize) ? fScrollSize : (fParentSize * fScrollSize)/fContentSize);
	
	var hThumb = hContextPanel.FindChildTraverse("Thumb");
	hThumb.style[hContextPanel._szVarSize1] = fScrollbarSize + "px";
	hThumb.style[hContextPanel._szVarSize2] = "38px";
	DispatchCustomEvent(hThumb, "StretchBoxRefresh");
	return true;
}

function CheckScrollSize(hContextPanel)
{
	var fScrollOffset = hContextPanel._fScrollOffset;
	var fContentSize = hContextPanel._hRefPanel["content" + hContextPanel._szVarSize1] * GameUI.GetScaleRatio();
	var fParentSize = hContextPanel.GetParent()["actuallayout" + hContextPanel._szVarSize1] * GameUI.GetScaleRatio();
	if ((fContentSize !== hContextPanel._fLastContentSize) || (fParentSize !== hContextPanel._fLastParentSize))
	{
		DispatchCustomEvent(hContextPanel, "ScrollbarSizeUpdate");
		DispatchCustomEvent(hContextPanel._hRefPanel, "PanelScroll", { value:0 });
		hContextPanel._fLastContentSize = fContentSize;
		hContextPanel._fLastParentSize = fParentSize;
	}
	$.Schedule(0.1, hContextPanel._hCheckFunction);
}

function OnScrollHelperPanelThink(hPanel)
{
	if (hPanel.BHasHoverStyle())
	{
		if (GameUI.IsMouseDown(0))
		{
			if (hPanel._bFirstMouseDown)
			{
				hPanel._bFirstMouseDown = false;
				hPanel._fRepeatTime = Game.Time() + 0.5;
				DispatchCustomEvent($.GetContextPanel()._hRefPanel, "PanelScroll", { value:hPanel.GetAttributeInt("scroll_value", 0) });
			}
			else if (Game.Time() > hPanel._fRepeatTime)
			{
				DispatchCustomEvent($.GetContextPanel()._hRefPanel, "PanelScroll", { value:hPanel.GetAttributeInt("scroll_value", 0) });
			}
		}
		else
		{
			hPanel._bFirstMouseDown = true;
			hPanel._fRepeatTime = 0;
		}
		$.Schedule(0.03, hPanel._hThinkerFunction);
	}
	else
	{
		hPanel._bFirstMouseDown = true;
		hPanel._fRepeatTime = 0;
	}
}

function OnScrollFillMouseOver()
{
	var hScrollable = GameUI.GetRoot().FindChildTraverse("Scrollable");
	DispatchCustomEvent(hScrollable, "ScrollableMouseOver", { panel:$("#ScrollContainer") });
}

function OnScrollFillMouseOut()
{
	var hScrollable = GameUI.GetRoot().FindChildTraverse("Scrollable");
	DispatchCustomEvent(hScrollable, "ScrollableMouseOut", { panel:$("#ScrollContainer") });
}

function OnScrollbarPanelScroll(hContextPanel, tArgs)
{
	DispatchCustomEvent(hContextPanel._hRefPanel, "PanelScroll", tArgs);
	return true;
}

function OnScrollablePanelScroll(hContextPanel, tArgs)
{
	var hScrollbar = hContextPanel._hScrollbar;
	var fScrollAmount = hContextPanel._fScrollAmount + tArgs.value;
	var fScrollOffset = hContextPanel._fScrollOffset;
	var fContentSize = hContextPanel["content" + hScrollbar._szVarSize1] * GameUI.GetScaleRatio() - fScrollOffset;
	var fParentSize = hScrollbar.GetParent()["actuallayout" + hScrollbar._szVarSize1] * GameUI.GetScaleRatio();
	
	var fScrollMin = Math.min(0, fParentSize - fContentSize) - fScrollOffset;
	if (fScrollAmount < fScrollMin)
		fScrollAmount = fScrollMin;
	if (fScrollAmount > -0.001 - fScrollOffset)		//Small threshold value because when we set fScrollAmount to 0, it doesn't update for some reason...
		fScrollAmount = -0.001 - fScrollOffset;		//Also prevents parsing errors with values close to zero using scientific notation
	fScrollAmount = fScrollAmount;
	
	//The transitions are a hack to stop panels from scrolling to the top due to panel size/visibility changes, etc.
	hContextPanel.style.transition = "position 0.0s linear 0.0s";
	if (hContextPanel._nScrollType === SCROLL_TYPE_HORIZONTAL)
		hContextPanel.style.position = fScrollAmount + "px 0px 0px";
	else if (hContextPanel._nScrollType === SCROLL_TYPE_VERTICAL)
		hContextPanel.style.position = "0px " + fScrollAmount + "px 0px";
	
	hContextPanel.style.transition = "position 99999999.9s ease-in 99999999.9s";
	hContextPanel._fScrollAmount = fScrollAmount;
	DispatchCustomEvent(hScrollbar, "ScrollbarPositionUpdate");
}

function OnScrollbarPanelScrollOffset(hContextPanel, tArgs)
{
	hContextPanel._fScrollOffset = tArgs.offset;
	DispatchCustomEvent(hContextPanel._hScrollbar, "ScrollbarSizeUpdate");
	DispatchCustomEvent(hContextPanel, "PanelScroll", { value:0 });
	return true;
}

function OnScrollbarThumbDragMove()
{
	var hContextPanel = $.GetContextPanel();
	if (hContextPanel._bIsDragging)
	{
		var vCursorPosition = GameUI.GetCursorPosition();
		var nScrollType = hContextPanel._nScrollType;
		
		var fContentSize = hContextPanel._hRefPanel["content" + hContextPanel._szVarSize1] * GameUI.GetScaleRatio();
		var fParentSize = hContextPanel.GetParent()["actuallayout" + hContextPanel._szVarSize1] * GameUI.GetScaleRatio();
		var fScrollDiff = (hContextPanel._vLastDragPos[nScrollType] - vCursorPosition[nScrollType]) * GameUI.GetScaleRatio();
		var fScrollSize = fParentSize - 52;
		DispatchCustomEvent(hContextPanel._hRefPanel, "PanelScroll", { value:(fScrollDiff/fScrollSize * fContentSize) });
		
		$.GetContextPanel()._vLastDragPos = vCursorPosition;
		$.Schedule(0.03, OnScrollbarThumbDragMove);
	}
}

function OnScrollbarThumbDragStart(szPanelName, hDraggedPanel)
{
	var hDummyPanel = $.CreatePanel("Panel", $.GetContextPanel(), "DummyPanel");
	hDraggedPanel.displayPanel = hDummyPanel;
	
	$.GetContextPanel()._vLastDragPos = GameUI.GetCursorPosition();
	$.GetContextPanel()._bIsDragging = true;
	$.Schedule(0.03, OnScrollbarThumbDragMove);
	return true;
}

function OnScrollbarThumbDragEnd(hPanel, hDraggedPanel)
{
	hDraggedPanel.DeleteAsync(0);
	$.GetContextPanel()._bIsDragging = false;
	return true;
}

function OnScrollbarLoad()
{
	$("#Background1").style.width = "38px";
	$("#Background1").style.height = "38px";
	$("#Background1").BLoadLayout("file://{resources}/layout/custom_game/ui/iw_widget_stretchbox.xml", false, false);
	
	$("#Background2").style.width = "38px";
	$("#Background2").style.height = "38px";
	$("#Background2").BLoadLayout("file://{resources}/layout/custom_game/ui/iw_widget_stretchbox.xml", false, false);
	
	var hThumb = $("#Thumb");
	var bIsVertical = ($.GetContextPanel()._nScrollType === SCROLL_TYPE_VERTICAL);
	hThumb.BLoadLayout("file://{resources}/layout/custom_game/ui/iw_widget_stretchbox.xml", false, false);
	hThumb.style[$.GetContextPanel()._szVarOffset] = "26px";
	$.RegisterEventHandler("DragStart", hThumb, OnScrollbarThumbDragStart);
	$.RegisterEventHandler("DragEnd", hThumb, OnScrollbarThumbDragEnd);
	
	var tScrollHelperPanels = [$("#ScrollRegion1"), $("#ScrollRegion2"), $("#Overlay1"), $("#Overlay2")];
	for (var i = 0; i < tScrollHelperPanels.length; i++)
	{
		tScrollHelperPanels[i]._fRepeatTime = 0;
		tScrollHelperPanels[i].SetAttributeInt("scroll_value", stScrollHelperPanelValues[i]);
		tScrollHelperPanels[i]._hThinkerFunction = OnScrollHelperPanelThink.bind(this, tScrollHelperPanels[i]);
		tScrollHelperPanels[i].SetPanelEvent("onmouseover", tScrollHelperPanels[i]._hThinkerFunction);
	}
}

function RegisterScrollablePanel(hPanel, hScrollbar, nScrollType)
{
	var hScrollable = GameUI.GetRoot().FindChildTraverse("Scrollable");
	
	hPanel.hittest = true;
	hPanel._nScrollType = nScrollType;
	hPanel._hScrollbar = hScrollbar;
	hPanel._fScrollAmount = 0;
	hPanel._fScrollOffset = 0;
	
	hPanel.ClearPanelEvent("onmouseover");
	hPanel.SetPanelEvent("onmouseover", DispatchCustomEvent.bind(this, hScrollable, "ScrollableMouseOver", { panel:hPanel }));
	hPanel.ClearPanelEvent("onmouseout");
	hPanel.SetPanelEvent("onmouseout", DispatchCustomEvent.bind(this, hScrollable, "ScrollableMouseOut", { panel:hPanel }));
	
	RegisterCustomEventHandler(hPanel, "PanelScroll", OnScrollablePanelScroll);
	RegisterCustomEventHandler(hPanel, "PanelScrollOffset", OnScrollbarPanelScrollOffset);
}

function InitScrollbarPanel(hPanel)
{
	hPanel.BLoadLayout("file://{resources}/layout/custom_game/ui/iw_widget_scrollbar.xml", false, false);
	hPanel._fLastContentSize = 0;
	hPanel._fLastParentSize = 0;
	
	RegisterCustomEventHandler(hPanel, "PanelScroll", OnScrollbarPanelScroll);
	RegisterCustomEventHandler(hPanel, "ScrollbarSizeUpdate", OnScrollbarSizeUpdate);
	RegisterCustomEventHandler(hPanel, "ScrollbarPositionUpdate", OnScrollbarPositionUpdate);
	
	hPanel._hCheckFunction = CheckScrollSize.bind(this, hPanel);
	$.Schedule(0.1, hPanel._hCheckFunction);
}

function CreateHorizontalScrollbar(hParent, szName, hRefPanel)
{
	if (!hRefPanel._hScrollbar)
	{
		var hPanel = $.CreatePanel("Panel", hParent, szName);
		InitScrollbarPanel(hPanel);
		hPanel._hRefPanel = hRefPanel;
		hPanel._nScrollType = SCROLL_TYPE_HORIZONTAL;
		hPanel._szVarSize1 = "width";
		hPanel._szVarSize2 = "height";
		hPanel._szVarOffset = "x";
		hPanel.AddClass("ScrollbarHorizontalStyle");
		RegisterScrollablePanel(hRefPanel, hPanel, SCROLL_TYPE_HORIZONTAL);
		return hPanel;
	}
}

function CreateVerticalScrollbar(hParent, szName, hRefPanel)
{
	if (!hRefPanel._hScrollbar)
	{
		var hPanel = $.CreatePanel("Panel", hParent, szName);
		InitScrollbarPanel(hPanel);
		hPanel._hRefPanel = hRefPanel;
		hPanel._nScrollType = SCROLL_TYPE_VERTICAL;
		hPanel._szVarSize1 = "height";
		hPanel._szVarSize2 = "width";
		hPanel._szVarOffset = "y";
		hPanel.AddClass("ScrollbarVerticalStyle");
		hPanel.BLoadLayout("file://{resources}/layout/custom_game/ui/iw_widget_scrollbar.xml", false, false);
		RegisterScrollablePanel(hRefPanel, hPanel, SCROLL_TYPE_VERTICAL);
		return hPanel;
	}
}