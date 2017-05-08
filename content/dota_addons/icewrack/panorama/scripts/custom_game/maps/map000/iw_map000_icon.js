"use strict";

function OnMouseOver()
{
	var nAbilityIndex = $.GetContextPanel().GetAttributeInt("abilityindex", 0);
	if (nAbilityIndex)
	{
		$.DispatchEvent("UIShowCustomLayoutParametersTooltip", "AbilityTooltip", "file://{resources}/layout/custom_game/tooltip/iw_tooltip_ability.xml", "abilityindex=" + nAbilityIndex );
	}
}

function OnMouseOut()
{
	$.DispatchEvent("UIHideCustomLayoutTooltip", "AbilityTooltip");
}