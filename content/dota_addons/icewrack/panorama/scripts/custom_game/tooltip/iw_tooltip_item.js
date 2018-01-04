"use strict";

function OnTooltipItemLoad()
{
	var nItemIndex = parseInt($.GetContextPanel().GetAttributeString("itemindex", ""));
	var tItemData = CustomNetTables.GetTableValue("items", nItemIndex);
	
	if (tItemData)
	{
	}
	
	$("#LoreContainer").style.width = ($("#Header").contentwidth * GameUI.GetScaleRatio()) + "px";
}