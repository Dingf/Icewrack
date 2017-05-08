"use strict";

function OnCharacterUpdate(hContextPanel, tArgs)
{
	var nEntityIndex = hContextPanel.GetAttributeInt("entindex", -1);
	DispatchCustomEvent(hContextPanel.FindChildTraverse("Infobox"), "InfoboxUpdate", { entindex:nEntityIndex });
	return true;		
}

function OnCharacterOpen(hContextPanel, tArgs)
{
	var hTabContainer = hContextPanel.FindChildTraverse("TabContainer");
	SetSelectedTab(hTabContainer.FindChildTraverse("TabOverview"));
	GameUI.SetPauseScreen(true);
	return true;
}

function OnCharacterClose(hContextPanel, tArgs)
{
	var tContentPanels = hContextPanel.FindChildTraverse("Content").Children();
	for (var k in tContentPanels)
	{
		DispatchCustomEvent(tContentPanels[k], "CharacterContentHide");
	}
	GameUI.SetPauseScreen(false);
	return true;
}

function OnCharacterPartyUpdate(hContextPanel, tArgs)
{
	hContextPanel.SetAttributeInt("entindex", tArgs.entindex);
	var hCharacterContent = hContextPanel.FindChildTraverse("Content");
	var tChildren = hCharacterContent.Children();
	for (var k in tChildren)
	{
		if ((tChildren[k].id === "AttributePanel") || (tChildren[k].id === "SkillsPanel") || (tChildren[k].id === "OverviewPanel"))	//TODO: Fix me to work for all children panels (need to register the handler on them)
		DispatchCustomEvent(tChildren[k], "WindowPartyUpdate", tArgs);
	}
	DispatchCustomEvent(hContextPanel, "CharacterUpdate");
	return true;
}

function OnCharacterTabActivate(hContextPanel, tArgs)
{
	var hPanel = tArgs.panel;
	var nEntityIndex = hContextPanel.FindChild("Character").GetAttributeInt("entindex", -1);
	var hCharacterContent = hContextPanel.FindChildTraverse("Content");
	var hCharacterTabLabel = hContextPanel.FindChildTraverse("TabLabel");
	
	var hOverviewPanel = hCharacterContent.FindChild("OverviewPanel");
	var hAttributesPanel = hCharacterContent.FindChild("AttributePanel");
	var hSkillsPanel = hCharacterContent.FindChild("SkillsPanel");
	var hStatsPanel = hCharacterContent.FindChild("StatsPanel");
	
	//TODO: Remove this when you've implemented all of the character content hide event handlers
	hStatsPanel.visible = false;
	if (hPanel.id === "TabOverview")
	{
		hCharacterTabLabel.text = $.Localize("#iw_ui_character_overview");
		DispatchCustomEvent(hOverviewPanel, "CharacterContentFocus", { entindex:nEntityIndex });
		DispatchCustomEvent(hAttributesPanel, "CharacterContentHide");
		DispatchCustomEvent(hSkillsPanel, "CharacterContentHide");
		DispatchCustomEvent(hStatsPanel, "CharacterContentHide");
	}
	else if (hPanel.id === "TabAttributes")
	{
		hCharacterTabLabel.text = $.Localize("#iw_ui_character_attributes");
		DispatchCustomEvent(hAttributesPanel, "CharacterContentFocus", { entindex:nEntityIndex });
		DispatchCustomEvent(hOverviewPanel, "CharacterContentHide");
		DispatchCustomEvent(hSkillsPanel, "CharacterContentHide");
		DispatchCustomEvent(hStatsPanel, "CharacterContentHide");
	}
	else if (hPanel.id === "TabSkills")
	{
		hCharacterTabLabel.text = $.Localize("#iw_ui_character_skills");
		DispatchCustomEvent(hSkillsPanel, "CharacterContentFocus", { entindex:nEntityIndex });
		DispatchCustomEvent(hOverviewPanel, "CharacterContentHide");
		DispatchCustomEvent(hAttributesPanel, "CharacterContentHide");
		DispatchCustomEvent(hStatsPanel, "CharacterContentHide");
	}
	else if (hPanel.id === "TabStats")
	{
		hCharacterTabLabel.text = $.Localize("#iw_ui_character_stats");
		DispatchCustomEvent(hStatsPanel, "CharacterContentFocus", { entindex:nEntityIndex });
		DispatchCustomEvent(hOverviewPanel, "CharacterContentHide");
		DispatchCustomEvent(hAttributesPanel, "CharacterContentHide");
		DispatchCustomEvent(hSkillsPanel, "CharacterContentHide");
	}
	return true;
}

function OnCharacterAttribPointsUpdate(hContextPanel, tArgs)
{
	SetIconLabelText(hContextPanel.FindChildTraverse("AttribPointsLabel"), tArgs.value);
	return true;
}

function OnCharacterSkillPointsUpdate(hContextPanel, tArgs)
{
	SetIconLabelText(hContextPanel.FindChildTraverse("SkillPointsLabel"), tArgs.value);
	return true;
}

function LoadCharacterLayout()
{
	var hContent = $("#Character").FindChildTraverse("WindowMainContent");
	hContent.BLoadLayout("file://{resources}/layout/custom_game/character/iw_character_main.xml", false, false);
	
	var hInfobox = $("#Character").FindChildTraverse("Infobox");
	hInfobox.LoadLayoutAsync("file://{resources}/layout/custom_game/character/iw_character_infobox.xml", false, false);
	
	var szAttribPointsText = "<b>" + $.Localize("iw_ui_character_attribute_points") + "</b><br>";
	szAttribPointsText = szAttribPointsText + "<font color=\"#c0c0c0\">" + $.Localize("iw_ui_character_attribute_points_desc") + "</font>";
	var hAttribPointsLabel = CreateIconLabel(hContent, "AttribPointsLabel", "icons/iw_icon_attributes", "", "#ffffff", szAttribPointsText);
	hAttribPointsLabel.AddClass("CharacterAttributePointsIconLabel");
	
	var szSkillPointsText = "<b>" + $.Localize("iw_ui_character_skill_points") + "</b><br>";
	szSkillPointsText = szSkillPointsText + "<font color=\"#c0c0c0\">" + $.Localize("iw_ui_character_skill_points_desc") + "</font>";
	var hSkillPointsLabel = CreateIconLabel(hContent, "SkillPointsLabel", "icons/iw_icon_skills", "", "#ffffff", szSkillPointsText);
	hSkillPointsLabel.AddClass("CharacterSkillPointsIconLabel");
}

function LoadCharacterTabs()
{	
	var hTabContainer = $("#Character").FindChildTraverse("TabContainer");
	CreateWindowTab(hTabContainer, "TabOverview", "character/iw_character_tab_overview");
	CreateWindowTab(hTabContainer, "TabAttributes", "character/iw_character_tab_attributes");
	CreateWindowTab(hTabContainer, "TabSkills", "character/iw_character_tab_skills");
	CreateWindowTab(hTabContainer, "TabStats", "inventory/iw_inventory_tab_reagents");
	
	var hContentBackground = $("#Character").FindChildTraverse("ContentBackground");
	hContentBackground.style.width = "672px";
	hContentBackground.style.height = "480px";
	hContentBackground.BLoadLayout("file://{resources}/layout/custom_game/ui/iw_widget_stretchbox.xml", false, false);
	
	var hCharacterTabLabel = $("#Character").FindChildTraverse("TabLabel");
	hCharacterTabLabel.text = $.Localize("#iw_ui_character_overview");
}

function LoadCharacterContent()
{
	var hCharacterContent = $("#Character").FindChildTraverse("Content");
	var hOverviewPanel = $.CreatePanel("Panel", hCharacterContent, "OverviewPanel");
	hOverviewPanel.LoadLayoutAsync("file://{resources}/layout/custom_game/character/iw_character_overview.xml", false, false);
	
	var hAttribPanel = $.CreatePanel("Panel", hCharacterContent, "AttributePanel");
	hAttribPanel.LoadLayoutAsync("file://{resources}/layout/custom_game/character/iw_character_attributes.xml", false, false);
	hAttribPanel.visible = false;
	
	var hSkillsPanel = $.CreatePanel("Panel", hCharacterContent, "SkillsPanel");
	hSkillsPanel.LoadLayoutAsync("file://{resources}/layout/custom_game/character/iw_character_skills.xml", false, false);
	hSkillsPanel.visible = false;
	
	var hStatsPanel = $.CreatePanel("Panel", hCharacterContent, "StatsPanel");
	hStatsPanel.LoadLayoutAsync("file://{resources}/layout/custom_game/character/iw_character_stats.xml", false, false);
	hStatsPanel.visible = false;
}

(function()
{
	CreateWindowPanel($.GetContextPanel(), "Character", "character", "#iw_ui_character", false, true);
	
	LoadCharacterLayout();
	LoadCharacterTabs();
	LoadCharacterContent();
	
	RegisterCustomEventHandler($.GetContextPanel(), "WindowOpen", OnCharacterOpen);
	RegisterCustomEventHandler($.GetContextPanel(), "WindowClose", OnCharacterClose);
	RegisterCustomEventHandler($.GetContextPanel(), "WindowPartyUpdate", OnCharacterPartyUpdate);
	RegisterCustomEventHandler($.GetContextPanel(), "WindowTabActivate", OnCharacterTabActivate);
	RegisterCustomEventHandler($.GetContextPanel(), "CharacterUpdate", OnCharacterUpdate);
	RegisterCustomEventHandler($.GetContextPanel(), "CharacterAttribPointsUpdate", OnCharacterAttribPointsUpdate);
	RegisterCustomEventHandler($.GetContextPanel(), "CharacterSkillPointsUpdate", OnCharacterSkillPointsUpdate);
})();