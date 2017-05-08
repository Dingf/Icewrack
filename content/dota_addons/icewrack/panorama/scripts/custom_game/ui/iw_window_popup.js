"use strict";

function OnWindowPopupOpen(hContextPanel, tArgs)
{
	hContextPanel.FindChild("PopupSpace").visible = true;
}

function OnWindowPopupClose(hContextPanel, tArgs)
{
	hContextPanel.FindChild("PopupSpace").visible = false;
	var hWindowRoot = GameUI.GetWindowRoot();
	var tSiblings = hWindowRoot.Children();
	for (var i = tSiblings.length-1; i >= 0; i--)
	{
		var hWindow = tSiblings[i]._hWindowPanel;
		if ((hWindow) && (hWindow._bRealVisible) && (hWindow !== hContextPanel))
		{
			DispatchCustomEvent(hWindow, "WindowFocus");
			hWindowRoot.MoveChildBefore(tSiblings[i], hContextPanel.GetParent());
			break;
		}
		else if (i === 0)
		{
			//Return focus to the main game
			var hDummyPanel = $.CreatePanel("Panel", hWindowRoot, "DummyFocusPanel");
			hDummyPanel.SetAcceptsFocus(true);
			hDummyPanel.SetFocus();
			hDummyPanel.DeleteAsync(0.03);
		}
	}
}

function OnWindowPopupFocus(hContextPanel, tArgs)
{
	var hWindowRoot = GameUI.GetWindowRoot();
	var tSiblings = hWindowRoot.Children();
	for (var k in tSiblings)
	{
		if (tSiblings[k] !== hContextPanel.GetParent())
		{
			hWindowRoot.MoveChildBefore(tSiblings[k], hContextPanel.GetParent());
		}
	}
}

function OnWindowPopupLoad()
{
	$.RegisterEventHandler("DragStart", $.GetContextPanel().FindChild("PopupMain"), OnWindowDragStart);
	$.RegisterEventHandler("DragEnd", $.GetContextPanel().FindChild("PopupMain"), OnWindowDragEnd);
}

function OnWindowPopupSpaceActivate()
{
	var hPopupMain = $.GetContextPanel().FindChild("PopupMain");
	DispatchCustomEvent(hPopupMain, "WindowClose");
}

function CreateWindowPopupPanel(hParent, szName)
{
	hParent.SetParent(GameUI.GetWindowRoot());
	var hPanel = $.CreatePanel("Panel", hParent, szName);
	hPanel.BLoadLayout("file://{resources}/layout/custom_game/ui/iw_window_popup.xml", false, false);
	
	var hPopupMain = hPanel.FindChild("PopupMain");
	hPopupMain._bInputLock = false;
	RegisterCustomEventHandler(hPanel, "WindowOpen", OnWindowPopupOpen);
	RegisterCustomEventHandler(hPanel, "WindowClose", OnWindowPopupClose);
	RegisterCustomEventHandler(hPanel, "WindowFocus", OnWindowPopupFocus);
	RegisterCustomEventHandler(hPopupMain, "WindowOpen", OnWindowOpen);
	RegisterCustomEventHandler(hPopupMain, "WindowClose", OnWindowClose);
	RegisterCustomEventHandler(hPopupMain, "WindowFocus", OnWindowFocus);
	RegisterCustomEventHandler(hPopupMain, "ButtonActivate", OnWindowButtonActivate);
	
	hPopupMain.SetPanelEvent("onfocus", DispatchCustomEvent.bind(this, hPopupMain, "WindowFocus"));
	hPopupMain.SetPanelEvent("oncancel", DispatchCustomEvent.bind(this, hPopupMain, "WindowClose"));
	hPopupMain.SetPanelEvent("onactivate", DispatchCustomEvent.bind(this, hPopupMain, "WindowFocus"));
	
	return hPopupMain;
}