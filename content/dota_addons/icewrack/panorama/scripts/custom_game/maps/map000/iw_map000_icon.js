"use strict";

function OnMouseOverThink()
{
	if ($.GetContextPanel()._bMouseOver)
	{
		var nEntityIndex = $.GetContextPanel().GetAttributeInt("caster", -1);
		var nAbilityIndex = $.GetContextPanel().GetAttributeInt("abilityindex", -1);
		if (nAbilityIndex !== -1)
		{
			var szTooltipArgs = "abilityindex=" + nAbilityIndex + "&entindex=" + nEntityIndex;
			$.DispatchEvent("UIShowCustomLayoutParametersTooltip", "AbilityTooltip", "file://{resources}/layout/custom_game/tooltip/iw_tooltip_ability.xml", szTooltipArgs );
		}
		$.Schedule(0.03, OnMouseOverThink);
	}
	else
	{
		$.GetContextPanel()._bTooltipVisible = false;
		$.DispatchEvent("UIHideCustomLayoutTooltip", "AbilityTooltip");
	}
	return 0.03
}

function OnMouseOver()
{
	
	$.GetContextPanel()._bTooltipVisible = false;
	$.GetContextPanel()._bMouseOver = true;
	OnMouseOverThink();
}

function OnMouseOut()
{
	$.GetContextPanel()._bMouseOver = false;
}


	