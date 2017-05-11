"use strict";

function OnMouseOver()
{
	var nAbilityIndex = $.GetContextPanel().GetAttributeInt("abilityindex", -1);
	if (nAbilityIndex !== -1)
	{
		var nEntityIndex = $.GetContextPanel().GetAttributeInt("caster", -1);
		var szTooltipArgs = "abilityindex=" + nAbilityIndex + "&entindex=" + nEntityIndex;
		$.DispatchEvent("UIShowCustomLayoutParametersTooltip", "AbilityTooltip", "file://{resources}/layout/custom_game/tooltip/iw_tooltip_ability.xml", szTooltipArgs );
	}
}

function OnMouseOut()
{
	$.DispatchEvent("UIHideCustomLayoutTooltip", "AbilityTooltip");
}