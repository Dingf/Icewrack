"use strict";

function OnDialogueOptionMouseOver()
{
	var hParent = $.GetContextPanel().GetParent();
	var fHeight = 0;
	var tSiblings = hParent.Children();
	for (var i = 0; i < tSiblings.length; i++)
	{
		if (tSiblings[i] === $.GetContextPanel())
			break;
		else
			fHeight += tSiblings[i].actuallayoutheight;
	}
	var fOffset = (68 - (fHeight + $.GetContextPanel().actuallayoutheight/2)) * GameUI.GetScaleRatio();
	DispatchCustomEvent(hParent, "DialogueOptionScroll", { value:fOffset, immediate:false });
}

function OnDialogueOptionActivate()
{
	var nValue = $.GetContextPanel().GetAttributeInt("value", -1);
	DispatchCustomEvent($.GetContextPanel().GetParent(), "DialogueOptionActivate", { value:nValue });
}

function CreateDialogueOption(hParent, szName, nValue, szText)
{
	if ((nValue < 0) || (typeof(nValue) !== "number"))
		return null;
	
	var tSiblings = hParent.Children();
	for (var i = 0; i < tSiblings.length; i++)
	{
		if (tSiblings[i].GetAttributeInt("value", -1) == nValue)
			return null;
	}
	
	var hPanel = $.CreatePanel("Panel", hParent, szName);
	hPanel.BLoadLayout("file://{resources}/layout/custom_game/dialogue/iw_dialogue_option.xml", false, false);
	hPanel.FindChild("Text").text = szText;
	hPanel.SetAttributeInt("value", nValue);
	if (hParent.GetChildCount() === 1)
	{
		$.Schedule(0.03, function()
		{
			var fOffset = (64 - (hPanel.actuallayoutheight/2)) * GameUI.GetScaleRatio();
			DispatchCustomEvent(hParent, "DialogueOptionScroll", { value:fOffset, immediate:true });
		});
	}
	
	return hPanel;
}