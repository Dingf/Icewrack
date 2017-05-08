"use strict";

function AAMLoaderSort(v1, v2)
{
	v1 = v1.toLowerCase();
    v2 = v2.toLowerCase();
	if (v1 > v2)
		return 1;
	else if (v1 < v2)
		return -1;
	else
		return 0;
}

function OnAAMLoaderRefresh(hContextPanel, tArgs)
{
	var nEntityIndex = hContextPanel.GetAttributeInt("entindex", -1);
	var szAutomatorName = null;
	if (hContextPanel._hSelectedEntry)
	{
		szAutomatorName = hContextPanel._hSelectedEntry.FindChild("EntryText").text;
		hContextPanel._hSelectedEntry = null;
	}
	
	var hEntryListContainer = hContextPanel.FindChildTraverse("EntryListContainer");
	hEntryListContainer.RemoveAndDeleteChildren();
	
	var tAutomatorEntries = [];
	var tAutomatorList = CustomNetTables.GetTableValue("aam", nEntityIndex).AutomatorList;
	for (var k in tAutomatorList)
	{
		tAutomatorEntries.push(k);
	}
	tAutomatorEntries.sort(AAMLoaderSort);
	
	var bHasSelectedEntry = false;
	for (var i = 0; i < tAutomatorEntries.length; i++)
	{
		var hEntry = $.CreatePanel("Panel", hEntryListContainer, "Entry" + i);
		hEntry.BLoadLayoutSnippet("AAMLoaderEntrySnippet");
		hEntry.FindChild("EntryText").text = tAutomatorEntries[i];
		hEntry.SetPanelEvent("onactivate", OnAAMEntryActivate.bind(this, hEntry));
		if (tAutomatorEntries[i] === szAutomatorName)
		{
			bHasSelectedEntry = true;
			hContextPanel._hSelectedEntry = hEntry;
		}
	}
	
	DispatchCustomEvent(hContextPanel.FindChildTraverse("LoadButton"), "ButtonSetEnabled", { state:bHasSelectedEntry });
	DispatchCustomEvent(hContextPanel.FindChildTraverse("DeleteButton"), "ButtonSetEnabled", { state:bHasSelectedEntry });
	return true;
}

function OnAAMLoaderNetTableUpdate(szTableName, szKey, tData)
{
	var nEntityIndex = $.GetContextPanel().GetAttributeInt("entindex", -1);
	if ((nEntityIndex === parseInt(szKey)) && ($.GetContextPanel()._hPopup.visible))
	{
		DispatchCustomEvent($.GetContextPanel(), "AAMLoaderRefresh");
	}
}

function OnAAMLoaderLoadButton()
{
	var nEntityIndex = $.GetContextPanel().GetAttributeInt("entindex", -1);
	var szAutomatorName = $.GetContextPanel()._hSelectedEntry.FindChild("EntryText").text;
	GameEvents.SendCustomGameEventToServer("iw_aam_load", { entindex:nEntityIndex, name:szAutomatorName });
	DispatchCustomEvent($.GetContextPanel().FindChildTraverse("PopupMain"), "WindowClose");
}

function OnAAMLoaderCancelButton()
{
	DispatchCustomEvent($.GetContextPanel().FindChildTraverse("PopupMain"), "WindowClose");
}

function OnAAMLoaderDeleteButton()
{
	var nEntityIndex = $.GetContextPanel().GetAttributeInt("entindex", -1);
	var szAutomatorName = $.GetContextPanel()._hSelectedEntry.FindChild("EntryText").text;
	GameEvents.SendCustomGameEventToServer("iw_aam_delete_automator", { entindex:nEntityIndex, name:szAutomatorName });
}

function OnAAMLoaderButtonActivate(hContextPanel, tArgs)
{
	var szPanelID = tArgs.panel.id;
	if (szPanelID === "LoadButton")
		OnAAMLoaderLoadButton();
	else if (szPanelID === "CancelButton")
		OnAAMLoaderCancelButton();
	else if (szPanelID === "DeleteButton")
		OnAAMLoaderDeleteButton();
	return true;
}

function OnAAMEntryActivate(hPanel)
{
	var hContextPanel = $.GetContextPanel();
	var hPrevEntry = hContextPanel._hSelectedEntry
	if (hPrevEntry)
	{
		hPrevEntry.RemoveClass("AAMLoaderSelectedEntry");
	}
	hContextPanel._hSelectedEntry = hPanel;
	hPanel.AddClass("AAMLoaderSelectedEntry");
	DispatchCustomEvent(hContextPanel.FindChildTraverse("LoadButton"), "ButtonSetEnabled", { state:true });
	DispatchCustomEvent(hContextPanel.FindChildTraverse("DeleteButton"), "ButtonSetEnabled", { state:true });
}

function OnAAMLoaderOpen(hContextPanel, tArgs)
{
	hContextPanel.SetAttributeInt("entindex", tArgs.entindex);
		
	DispatchCustomEvent(hContextPanel, "AAMLoaderRefresh");
		
	hContextPanel._hSelectedEntry = null;
	DispatchCustomEvent(hContextPanel.FindChildTraverse("LoadButton"), "ButtonSetEnabled", { state:false });
	DispatchCustomEvent(hContextPanel.FindChildTraverse("DeleteButton"), "ButtonSetEnabled", { state:false });
		
	DispatchCustomEvent(hContextPanel._hPopup, "WindowOpen");
	return true;
}

function OnAAMLoaderLoad()
{
	var hPopup = CreateWindowPopupPanel($.GetContextPanel(), "AAMLoader");
	$.GetContextPanel()._hPopup = hPopup;
	var hContent = hPopup.FindChild("PopupContent");
	hContent.BLoadLayout("file://{resources}/layout/custom_game/aam/iw_aam_loader_main.xml", false, false);
	
	var hBackground = hContent.FindChild("Background");
	hBackground.style.width = "256px";
	hBackground.style.height = "160px";
	hBackground.BLoadLayout("file://{resources}/layout/custom_game/ui/iw_widget_stretchbox.xml", false, false);
	
	var hEntryList = hContent.FindChild("EntryList");
	var hEntryListContainer = hEntryList.FindChild("EntryListContainer");
	CreateVerticalScrollbar(hEntryList, "AAMLoaderScrollbar", hEntryListContainer);
	
	var hLoadButton = CreateButton(hContent, "LoadButton", "#iw_ui_aam_load");
	hLoadButton.AddClass("AAMLoaderButton");
	var hCancelButton = CreateButton(hContent, "CancelButton", "#iw_ui_aam_cancel");
	hCancelButton.AddClass("AAMLoaderButton");
	var hDeleteButton = CreateButton(hContent, "DeleteButton", "#iw_ui_aam_delete");
	hDeleteButton.AddClass("AAMLoaderButton");
	
	CustomNetTables.SubscribeNetTableListener("aam", OnAAMLoaderNetTableUpdate);
	
	RegisterCustomEventHandler($.GetContextPanel(), "AAMLoaderOpen", OnAAMLoaderOpen);
	RegisterCustomEventHandler($.GetContextPanel(), "AAMLoaderRefresh", OnAAMLoaderRefresh);
	RegisterCustomEventHandler($.GetContextPanel(), "ButtonActivate", OnAAMLoaderButtonActivate);
	
	DispatchCustomEvent(hPopup.GetParent(), "WindowClose");
	DispatchCustomEvent(hPopup, "WindowClose");
	hPopup.visible = false;
}