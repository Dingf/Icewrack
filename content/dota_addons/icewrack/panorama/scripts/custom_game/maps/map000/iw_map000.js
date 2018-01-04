"use strict";

var nDifficulty = -1;
var nLastEntityIndex = -1;
var tAbilityIcons = [];

function OnCharacterActivate()
{
	var tCursorEntities = GameUI.FindScreenEntities(GameUI.GetCursorPosition());
	if (tCursorEntities.length > 0)
	{
		$("#HeroTitle").visible = true;
		$("#HeroDetails").visible = true;
		
		var nAbilityIndex = 0;
		var nEntityIndex = tCursorEntities[tCursorEntities.length-1].entityIndex;
		
		if (nEntityIndex == nLastEntityIndex)
			return;
		
		var nAbilityIconCount = 0;
		var tEntityBinds = CustomNetTables.GetTableValue("binds", nEntityIndex);
		if (tEntityBinds)
		{
			for (var k in tEntityBinds)	
			{
				var hIcon = $("#SkillIcon" + (nAbilityIconCount + 1));
				if (nAbilityIconCount === tAbilityIcons.length)
				{
					hIcon = $.CreatePanel("Panel", $("#HeroIconContainer"), "SkillIcon" + (nAbilityIconCount + 1));
					hIcon.BLoadLayout("file://{resources}/layout/custom_game/maps/map000/iw_map000_icon.xml", false, false);
					hIcon.AddClass("CharacterSelectIcon");
					tAbilityIcons.push(hIcon);
				}
				var nAbilityIndex = tEntityBinds[k];
				if (nAbilityIndex !== -1)
				{
					hIcon.visible = true;
					hIcon.FindChildTraverse("AbilityTexture").SetImage("file://{images}/spellicons/" + Abilities.GetAbilityTextureName(nAbilityIndex) + ".png");
					hIcon.SetAttributeInt("caster", nEntityIndex);
					hIcon.SetAttributeString("abilityindex", nAbilityIndex);
					hIcon.SetHasClass("CharacterSelectIconDisabled", !Abilities.IsActivated(nAbilityIndex));
				}
				else
				{
					hIcon.visible = false;
				}
				nAbilityIconCount++;
			}
		}
		
		$("#HeroTitle").text = $.Localize("#" + Entities.GetUnitName(nEntityIndex));
		$("#HeroText").text = "\n" + $.Localize("#intro_" + Entities.GetUnitName(nEntityIndex)) + "\n";
		DispatchCustomEvent($("#NextButton"), "ButtonSetEnabled", { state:true });
		GameEvents.SendCustomGameEventToServer("iw_character_select_examine", { entindex:nEntityIndex });
		nLastEntityIndex = nEntityIndex;
	}
	else
	{
		nLastEntityIndex = -1;
		$("#HeroTitle").text = "";//$.Localize("#iw_ui_character_select_intro");
		$("#HeroDetails").visible = false;
		DispatchCustomEvent($("#NextButton"), "ButtonSetEnabled", { state:false });
		GameEvents.SendCustomGameEventToServer("iw_character_select_examine", { entindex:-1 });
	}
}

function OnDifficultyActivate()
{
	DispatchCustomEvent($("#EasyButton"), "ButtonForceDown", { state:false });
	DispatchCustomEvent($("#NormalButton"), "ButtonForceDown", { state:false });
	DispatchCustomEvent($("#HardButton"), "ButtonForceDown", { state:false });
	DispatchCustomEvent($("#UnthawButton"), "ButtonForceDown", { state:false });
	DispatchCustomEvent($("#StartButton"), "ButtonSetEnabled", { state:false });
	$("#DifficultyDetails").visible = false;
	$("#DifficultyText").text = "";
}

function DelayedOnNextButtonActivate()
{
	$("#HeroGroup").visible = false;
	$("#DifficultyGroup").style.visibility = "visible";
	$("#Blackout").RemoveClass("BlackoutActive");
	$("#Blackout").AddClass("BlackoutInactive");
	GameUI.SetCameraYaw(180.0);
	GameUI.SetCameraLookAtPositionHeightOffset(256.0);
	GameUI.SetCameraDistance(0.0);
	GameEvents.SendCustomGameEventToServer("iw_character_select_stage", { stage:2 });
}

function DelayedOnPrevButtonActivate()
{
	$("#HeroGroup").visible = true;
	$("#DifficultyGroup").style.visibility = "collapse";
	$("#Blackout").RemoveClass("BlackoutActive");
	$("#Blackout").AddClass("BlackoutInactive");
	GameUI.SetCameraYaw(0.0);
	GameUI.SetCameraLookAtPositionHeightOffset(0.0);
	GameUI.SetCameraDistance(1100.0);
	GameEvents.SendCustomGameEventToServer("iw_character_select_stage", { stage:1 });
}

function DisplayDifficultyInfo(hContextPanel, hButton)
{
	var tSiblings = hButton.GetParent().Children();
	for (var k in tSiblings)
	{
		DispatchCustomEvent(tSiblings[k], "ButtonForceDown", { state:(tSiblings[k] === hButton) });
	}
	
	DispatchCustomEvent(hContextPanel.FindChildTraverse("StartButton"), "ButtonSetEnabled", { state:true });
	hContextPanel.FindChildTraverse("DifficultyDetails").visible = true;
	hContextPanel.FindChildTraverse("DifficultyText").text = $.Localize(hButton._szDescription);
	nDifficulty = hButton._nDifficulty;
}

function OnCharacterSelectButtonActivate(hContextPanel, tArgs)
{
	var szPanelID = tArgs.panel.id;
	if (szPanelID === "BackButton")
		GameEvents.SendCustomGameEventToServer("iw_change_level", { map:"main_menu" });
	else if (szPanelID === "StartButton")
	{
		GameEvents.SendCustomGameEventToServer("iw_character_select_start", { entindex:nLastEntityIndex, difficulty:nDifficulty });
	}
	else if (szPanelID === "NextButton")
	{
		$("#Blackout").RemoveClass("BlackoutInactive");
		$("#Blackout").AddClass("BlackoutActive");
		$.Schedule(0.24, DelayedOnNextButtonActivate);
	}
	else if (szPanelID === "PrevButton")
	{
		$("#Blackout").RemoveClass("BlackoutInactive");
		$("#Blackout").AddClass("BlackoutActive");
		$.Schedule(0.24, DelayedOnPrevButtonActivate);
	}
	else
		DisplayDifficultyInfo(hContextPanel, tArgs.panel);
	return true;
}

(function()
{
	var tMapInfo = CustomNetTables.GetTableValue("game", "map");
	if (tMapInfo.name == "map000")
	{
		$.GetContextPanel().style.opacity = 1.0;
		
		GameUI.SetCameraPitchMin(10.0);
		GameUI.SetCameraPitchMax(10.0);
		GameUI.SetCameraDistance(1100.0);
		
		RegisterCustomEventHandler($.GetContextPanel(), "ButtonActivate", OnCharacterSelectButtonActivate);
		
		DispatchCustomEvent(GameUI.GetRoot(), "GlobalHideUI");
	
		$("#HeroTitle").text = "";//$.Localize("#iw_ui_character_select_intro");
		$("#DifficultyTitle").text = $.Localize("#iw_ui_character_select_difficulty");
		
		$("#HeroDetails").visible = false;
		$("#DifficultyDetails").visible = false;
		
		var hBackButton = CreateButton($("#HeroNavGroup"), "BackButton", "#iw_ui_character_select_back");
		hBackButton.AddClass("CharacterSelectLeftButton");
		
		var hNextButton = CreateButton($("#HeroNavGroup"), "NextButton", "#iw_ui_character_select_next");
		hNextButton.AddClass("CharacterSelectRightButton");
		DispatchCustomEvent(hNextButton, "ButtonSetEnabled", { state:false });
		
		var hPrevButton = CreateButton($("#DifficultyNavGroup"), "PrevButton", "#iw_ui_character_select_back");
		hPrevButton.AddClass("CharacterSelectLeftButton");
		
		
		var hStartButton = CreateButton($("#DifficultyNavGroup"), "StartButton", "#iw_ui_character_select_start");
		hStartButton.AddClass("CharacterSelectRightButton");
		DispatchCustomEvent(hStartButton, "ButtonSetEnabled", { state:false });
		
		var hEasyButton = CreateButton($("#DifficultyButtonGroup"), "EasyButton", "#iw_ui_character_select_easy");
		hEasyButton.AddClass("CharacterSelectDifficultyButton");
		hEasyButton._szDescription = "#intro_difficulty_easy";
		hEasyButton._nDifficulty = 0;
		
		var hNormalButton = CreateButton($("#DifficultyButtonGroup"), "NormalButton", "#iw_ui_character_select_normal");
		hNormalButton.AddClass("CharacterSelectDifficultyButton");
		hNormalButton._szDescription = "#intro_difficulty_normal";
		hNormalButton._nDifficulty = 1;
		
		var hHardButton = CreateButton($("#DifficultyButtonGroup"), "HardButton", "#iw_ui_character_select_hard");
		hHardButton.AddClass("CharacterSelectDifficultyButton");
		hHardButton._szDescription = "#intro_difficulty_hard";
		hHardButton._nDifficulty = 2;
		
		var hUnthawButton = CreateButton($("#DifficultyButtonGroup"), "UnthawButton", "#iw_ui_character_select_unthaw");
		hUnthawButton.AddClass("CharacterSelectDifficultyButton");
		hUnthawButton._szDescription = "#intro_difficulty_unthaw";
		hUnthawButton._nDifficulty = 3;
		
		var tHeroEntities = Entities.GetAllHeroEntities();
		for (var k in tHeroEntities)
		{
			GameEvents.SendCustomGameEventToServer("iw_actionbar_info", { entindex:tHeroEntities[k] });
		}
	}
})();