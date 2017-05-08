"use strict";

function OnActionBarTooltipIconPressed()
{
	var nCasterIndex = $.GetContextPanel().GetAttributeInt("caster", -1);
	var nAbilityIndex = $.GetContextPanel().GetAttributeInt("abilityindex", -1);
	if (nCasterIndex !== -1)
	{
		var hTooltip = $.GetContextPanel()._hTooltip;
		var nSlot = hTooltip.GetAttributeInt("slot", -1);
		DispatchCustomEvent($.GetContextPanel(), "ActionBarTooltipIconBind", { entindex:nCasterIndex, slot:nSlot, ability:nAbilityIndex });
		hTooltip.RemoveClass("ActionBarTooltipFadeIn");
		hTooltip.AddClass("ActionBarTooltipFadeOut");
	}
}

function OnActionBarTooltipIconMouseOver()
{
	var nEntityIndex = $.GetContextPanel().GetAttributeInt("caster", -1);
	var nAbilityIndex = $.GetContextPanel().GetAttributeInt("abilityindex", -1);
	if ((nEntityIndex !== -1) && (nAbilityIndex !== -1))
	{
		var szTooltipArgs = (nAbilityIndex !== 0)  ? "abilityindex=" + nAbilityIndex : "abilityname=internal_clear_slot";
		szTooltipArgs += "&entindex=" + nEntityIndex;
		$.DispatchEvent("UIShowCustomLayoutParametersTooltip", "AbilityTooltip", "file://{resources}/layout/custom_game/tooltip/iw_tooltip_ability.xml", szTooltipArgs);
	}
}

function OnActionBarTooltipIconMouseOut()
{
	$.DispatchEvent("UIHideCustomLayoutTooltip", "AbilityTooltip");
}