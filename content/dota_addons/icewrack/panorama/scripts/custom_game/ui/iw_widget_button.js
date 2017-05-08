"use strict";

var BUTTON_STATE_UP = 0;
var BUTTON_STATE_OVER = 1;
var BUTTON_STATE_DOWN = 2;

function CanActivateButton(hPanel)
{
	return (hPanel.GetAttributeInt("enabled", -1) === 1) && (hPanel.GetAttributeInt("force_down", -1) !== 1);
}

function OnButtonActivate()
{
	if (CanActivateButton($.GetContextPanel()))
	{
		DispatchCustomEvent($.GetContextPanel().GetParent(), "ButtonActivate", { panel:$.GetContextPanel() });
	}
}

function OnButtonMouseOver()
{
	$.GetContextPanel().SetAttributeInt("hover", BUTTON_STATE_OVER);
	if (CanActivateButton($.GetContextPanel()))
	{
		for (var i = 0; i < $.GetContextPanel()._hTextures.length; i++)
			$.GetContextPanel()._hTextures[i].visible = (i === BUTTON_STATE_OVER);
		$.Schedule(0.03, UpdateButton);
	}
}

function OnButtonMouseOut()
{
	$.GetContextPanel().SetAttributeInt("hover", BUTTON_STATE_UP);
	if ($.GetContextPanel().GetAttributeInt("force_down", -1) !== 1)
	{
		$("#Text").RemoveClass("ButtonTextDown");
		for (var i = 0; i < $.GetContextPanel()._hTextures.length; i++)
			$.GetContextPanel()._hTextures[i].visible = (i === BUTTON_STATE_UP);
	}
}

function UpdateButton()
{
	var nHoverState = $.GetContextPanel().GetAttributeInt("hover", -1);
	if (CanActivateButton($.GetContextPanel()) && (nHoverState === BUTTON_STATE_OVER))
	{
		if (GameUI.IsMouseDown(0))
		{
			$("#Text").AddClass("ButtonTextDown");
			for (var i = 0; i < $.GetContextPanel()._hTextures.length; i++)
				$.GetContextPanel()._hTextures[i].visible = (i === BUTTON_STATE_DOWN);
		}
		else
		{
			$("#Text").RemoveClass("ButtonTextDown");
			for (var i = 0; i < $.GetContextPanel()._hTextures.length; i++)
				$.GetContextPanel()._hTextures[i].visible = (i === BUTTON_STATE_OVER);
		}
		$.Schedule(0.03, UpdateButton);
	}
}

function OnButtonSetEnabled(hContextPanel, tArgs)
{
	hContextPanel.SetAttributeInt("enabled", tArgs.state ? 1 : 0);
	hContextPanel.FindChildTraverse("Text").SetHasClass("ButtonTextActive", tArgs.state);
	hContextPanel.FindChildTraverse("TextureDisabled").visible = !tArgs.state;
	return true;
}

function OnButtonForceDown(hContextPanel, tArgs)
{
	hContextPanel.SetAttributeInt("force_down", tArgs.state ? 1 : 0);
	if (tArgs.state)
	{
		hContextPanel.FindChildTraverse("Text").AddClass("ButtonTextDown");
		for (var i = 0; i < hContextPanel._hTextures.length; i++)
			hContextPanel._hTextures[i].visible = (i === BUTTON_STATE_DOWN);
	}
	else if (!GameUI.IsMouseDown(0))
	{
		hContextPanel.FindChildTraverse("Text").RemoveClass("ButtonTextDown");
		for (var i = 0; i < hContextPanel._hTextures.length; i++)
			hContextPanel._hTextures[i].visible = (i === hContextPanel.GetAttributeInt("hover", -1));
	}
	return true;
}

function OnButtonLoad()
{
	for (var i = 0; i < $.GetContextPanel()._hTextures.length; i++)
		$.GetContextPanel()._hTextures[i].visible = (i === BUTTON_STATE_UP);
}

function CreateButton(hParent, szName, szText, szTextureName)
{
	var hPanel = $.CreatePanel("Panel", hParent, szName);
	hPanel.BLoadLayout("file://{resources}/layout/custom_game/ui/iw_widget_button.xml", false, false);
	hPanel.SetAttributeInt("force_down", 0);
	hPanel.SetAttributeInt("enabled", 1);
	hPanel.SetAttributeInt("hover", 0);
	
	if (szText && !szTextureName)
	{
		hPanel.FindChildTraverse("Text").text = $.Localize(szText);
		hPanel.FindChildTraverse("Text").SetHasClass("ButtonTextActive", true);
	}
	
	if (!szTextureName)
		szTextureName = "ui/iw_button_default";
	hPanel.FindChildTraverse("Texture").SetImage("file://{images}/custom_game/" + szTextureName + ".tga");
	hPanel.FindChildTraverse("TextureOver").SetImage("file://{images}/custom_game/" + szTextureName + "_over.tga");
	hPanel.FindChildTraverse("TextureOver").visible = false;
	hPanel.FindChildTraverse("TextureDown").SetImage("file://{images}/custom_game/" + szTextureName + "_down.tga");
	hPanel.FindChildTraverse("TextureDown").visible = false;
	hPanel.FindChildTraverse("TextureDisabled").SetImage("file://{images}/custom_game/" + szTextureName + "_disabled.tga");
	hPanel.FindChildTraverse("TextureDisabled").visible = false;
	hPanel._hTextures = [hPanel.FindChildTraverse("Texture"), hPanel.FindChildTraverse("TextureOver"), hPanel.FindChildTraverse("TextureDown")];
	
	RegisterCustomEventHandler(hPanel, "ButtonSetEnabled", OnButtonSetEnabled);
	RegisterCustomEventHandler(hPanel, "ButtonForceDown", OnButtonForceDown);
	return hPanel;
}
