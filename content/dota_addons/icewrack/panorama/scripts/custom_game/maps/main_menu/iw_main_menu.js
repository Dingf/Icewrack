"use strict";

function OnMainMenuButtonActivate(hContextPanel, tArgs)
{
	var szPanelID = tArgs.panel.id;
	if (szPanelID === "NewButton")
		GameEvents.SendCustomGameEventToServer("iw_change_level", { map:"map000" });
	else if (szPanelID === "QuitButton")
		GameEvents.SendCustomGameEventToServer("iw_quit", {});
	return true;
}

(function()
{
	var tMapInfo = CustomNetTables.GetTableValue("game", "map");
	if (tMapInfo.name == "main_menu")
	{
		$.GetContextPanel().style.opacity = 1.0;
		
		GameUI.SetCameraPitchMin(0.5);
		GameUI.SetCameraPitchMax(0.5);
		GameUI.SetCameraLookAtPositionHeightOffset(256);
		GameUI.SetCameraDistance(0.0);
		
		RegisterCustomEventHandler($.GetContextPanel(), "ButtonActivate", OnMainMenuButtonActivate);
		DispatchCustomEvent(GameUI.GetRoot(), "GlobalHideUI");
		
		var hNewButton = CreateButton($("#ButtonContainer"), "NewButton", "#iw_ui_main_menu_new_game");
		
		var tSaveData = CustomNetTables.GetTableValue("game", "saves");
		var hContinueButton = CreateButton($("#ButtonContainer"), "ContinueButton", "#iw_ui_main_menu_continue");
		DispatchCustomEvent($("#ContinueButton"), "ButtonSetEnabled", { state:(tSaveData.special.Latest !== "") });
		
		var hLoadButton = CreateButton($("#ButtonContainer"), "LoadButton", "#iw_ui_main_menu_load_game");
		DispatchCustomEvent($("#LoadButton"), "ButtonSetEnabled", { state:(tSaveData.files.length > 0) });
		
		var hOptionsButton = CreateButton($("#ButtonContainer"), "OptionsButton", "#iw_ui_main_menu_options");
		
		var hQuitButton = CreateButton($("#ButtonContainer"), "QuitButton", "#iw_ui_main_menu_quit");
		
		var tButtons = $("#ButtonContainer").Children();
		for (var k in tButtons)
		{
			tButtons[k].AddClass("MainMenuButton");
		}
	}
})();