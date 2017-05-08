"use strict";

var SIDEBAR_SCROLL_SPEED = 12.0;

var bSideBarForceActive = false;
var bSideBarActive = false;
var fSideBarXOffset = 64.0;

function OnMouseOver()
{
	bSideBarActive = true;
}

function OnMouseOut()
{
	bSideBarActive = false;
}

function UpdateSideBar()
{
	if (!$.GetContextPanel().visible)
	{
		$.Schedule(0.03, UpdateSideBar);
		return false;
	}
	
	bSideBarForceActive = false;
	var tChildren = $("#IconContainer").Children();
	for (var k in tChildren)
	{
		if (tChildren[k]._bIsPanelActive)
		{
			bSideBarForceActive = true;
			break;
		}
	}
	
	if ((bSideBarActive || bSideBarForceActive) && (fSideBarXOffset >= 0.0))
	{
		if (fSideBarXOffset > 0.0)
		{
			fSideBarXOffset = Math.max(fSideBarXOffset - SIDEBAR_SCROLL_SPEED, 0.0);
			$("#SideBar").style.position = fSideBarXOffset + "px 0px 0px";
		}
	}
	else if (fSideBarXOffset < 64.0)
	{
		fSideBarXOffset = Math.min(fSideBarXOffset + SIDEBAR_SCROLL_SPEED, 64.0);
		$("#SideBar").style.position = fSideBarXOffset + "px 0px 0px";
	}
	
	$.Schedule(0.03, UpdateSideBar);
}

function OnSidebarIconActivate(hContextPanel, tArgs)
{
	var hRefPanel = tArgs.panel._hRefPanel;
	if (hRefPanel)
	{
		DispatchCustomEvent(hRefPanel, "WindowToggle");
	}
};

(function()
{
	RegisterCustomEventHandler($.GetContextPanel(), "SidebarIconActivate", OnSidebarIconActivate);
	
	$("#SideBar").style.position = fSideBarXOffset + "px 0px 0px";
	var hIconContainer = $("#IconContainer");
	for (var i = 0; i < 6; i++)
	{
		var hIcon = $.CreatePanel("Panel", hIconContainer, "Icon" + (i + 1));
		hIcon.BLoadLayout("file://{resources}/layout/custom_game/sidebar/iw_sidebar_icon.xml", false, false);
		hIcon.style.position = "0px " + (i * 44) + "px 0px";
	}
	
	var hCharacter = GameUI.GetWindowRoot().FindChildTraverse("Character");
	var hCharacterIcon = $("#Icon1");
	hCharacterIcon.FindChildTraverse("IconTexture").SetImage("file://{images}/custom_game/sidebar/iw_sidebar_icon_character.tga");
	hCharacterIcon.SetAttributeString("hover_text", $.Localize("#iw_ui_character"));
	hCharacterIcon._hRefPanel = hCharacter;
	hCharacter.visible = false;
	
	var hInventory = GameUI.GetWindowRoot().FindChildTraverse("Inventory");
	var hInventoryIcon = $("#Icon2");
	hInventoryIcon.FindChildTraverse("IconTexture").SetImage("file://{images}/custom_game/sidebar/iw_sidebar_icon_inventory.tga");
	hInventoryIcon.SetAttributeString("hover_text", $.Localize("#iw_ui_inventory"));
	hInventoryIcon._hRefPanel = hInventory;
	hInventory.visible = false;
	
	var hAbilities = GameUI.GetWindowRoot().FindChildTraverse("Abilities");
	var hAbilitiesIcon = $("#Icon3");
	hAbilitiesIcon.FindChildTraverse("IconTexture").SetImage("file://{images}/custom_game/sidebar/iw_sidebar_icon_abilities.tga");
	hAbilitiesIcon.SetAttributeString("hover_text", $.Localize("#iw_ui_abilities"));
	hAbilitiesIcon._hRefPanel = hAbilities;
	hAbilities.visible = false;
	
	var hJournalIcon = $("#Icon4");
	hJournalIcon.FindChildTraverse("IconTexture").SetImage("file://{images}/custom_game/sidebar/iw_sidebar_icon_journal.tga");
	hJournalIcon.SetAttributeString("hover_text", $.Localize("#iw_ui_journal"));
	
	var hMapIcon = $("#Icon5");
	hMapIcon.FindChildTraverse("IconTexture").SetImage("file://{images}/custom_game/sidebar/iw_sidebar_icon_map.tga");
	hMapIcon.SetAttributeString("hover_text", $.Localize("#iw_ui_map"));
	
	var hAutomator = GameUI.GetWindowRoot().FindChildTraverse("AAM");
	var hAutomatorIcon = $("#Icon6");
	hAutomatorIcon.FindChildTraverse("IconTexture").SetImage("file://{images}/custom_game/sidebar/iw_sidebar_icon_aam.tga");
	hAutomatorIcon.SetAttributeString("hover_text", "Tactics");
	hAutomatorIcon._hRefPanel = hAutomator;
	hAutomator.visible = false;
	
	$.Schedule(0.03, UpdateSideBar);
})();