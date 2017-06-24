"use strict";

function OnIndicatorMouseOverThink()
{
	if ($.GetContextPanel()._bMouseOver)
	{
		var nState = $.GetContextPanel().GetAttributeInt("state", -1);
		var szTooltipName = $.GetContextPanel().GetAttributeString("tooltip_name", "");
		$.DispatchEvent("DOTAShowTextTooltip", $("#Hitbox"), $.Localize("#" + szTooltipName + nState));
		$.Schedule(0.03, OnIndicatorMouseOverThink);
	}
	else
	{
		$.GetContextPanel()._bTooltipVisible = false;
		$.DispatchEvent("DOTAHideTextTooltip", $("#Hitbox"));
	}
	return 0.03
}

function OnIndicatorMouseOver()
{
	$.GetContextPanel()._bTooltipVisible = false;
	$.GetContextPanel()._bMouseOver = true;
	OnIndicatorMouseOverThink();
}

function OnIndicatorMouseOut()
{
	$.GetContextPanel()._bMouseOver = false;
}

function OnIndicatorActivate()
{
	var hParent = $.GetContextPanel().GetParent();
	DispatchCustomEvent(hParent, "PartybarIndicatorActivate", { panel:$.GetContextPanel() });
}

function OnPartybarIndicatorRefresh(hContextPanel, tArgs)
{
	var nState = hContextPanel.GetAttributeInt("state", -1);
	var szTextureName = hContextPanel.GetAttributeString("texture_name", "");
	var tTextures = hContextPanel.FindChild("TextureContainer").Children();
	for (var k in tTextures)
	{
		var nTextureState = tTextures[k].GetAttributeInt("state", -1);
		tTextures[k].visible = (nTextureState === nState);
	}
	return true;
}

function CreatePartybarIndicator(hParent, szName, szTextureName, szTooltipName, nStateCount)
{
	var hPanel = $.CreatePanel("Panel", hParent, szName);
	hPanel.BLoadLayout("file://{resources}/layout/custom_game/partybar/iw_partybar_indicator.xml", false, false);
	hPanel.SetAttributeString("texture_name", szTextureName);
	hPanel.SetAttributeString("tooltip_name", szTooltipName);
	hPanel.SetAttributeInt("state", 0);
	
	var hTextureContainer = hPanel.FindChild("TextureContainer");
	for (var i = 0; i < nStateCount; i++)
	{
		var hTexture = $.CreatePanel("Image", hTextureContainer, "Texture" + i);
		
		hTexture.SetImage("file://{images}/custom_game/partybar/indicators/" + szTextureName + i + ".tga");
		hTexture.AddClass("PartybarIndicatorTexture");
		hTexture.SetAttributeInt("state", i);
	}
	
	RegisterCustomEventHandler(hPanel, "PartybarIndicatorRefresh", OnPartybarIndicatorRefresh);
	DispatchCustomEvent(hPanel, "PartybarIndicatorRefresh");
	
	return hPanel;
}