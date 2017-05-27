"use strict";

var bXPTooltipActive = false;

function UpdateXPBar()
{
	var nEntityIndex = $.GetContextPanel().GetAttributeInt("caster", -1);
	if (nEntityIndex !== -1)
	{
		var tXPData = CustomNetTables.GetTableValue("game", "xp");
		var nCurrentLevelXP = tXPData[Entities.GetLevel(nEntityIndex)];
		var nCurrentXP = Entities.GetCurrentXP(nEntityIndex) - nCurrentLevelXP;
		var nNextLevelXP = Entities.GetNeededXPToLevel(nEntityIndex) - nCurrentLevelXP;
		if (Entities.GetLevel(nEntityIndex) === tXPData["max_level"])
		{
			nCurrentXP = 1;
			nNextLevelXP = 1;
		}
		else if (nNextLevelXP == 0)
		{
			nCurrentXP = 0;
			nNextLevelXP = 1;
		}
		$("#XPBar").FindChildTraverse("XPFill").style.width = (nCurrentXP * 738)/nNextLevelXP + "px";
	}
	else
	{
		$("#XPBar").FindChildTraverse("XPFill").style.width = "0px";
	}
	$.Schedule(0.1, UpdateXPBar);
}

function OnXPMouseOver()
{
	var nEntityIndex = $.GetContextPanel().GetAttributeInt("caster", -1);
	if (nEntityIndex !== -1)
	{
		var hParent = $.GetContextPanel().GetParent();
		var fOffset = GameUI.GetCursorPosition()[0] - hParent.actualxoffset
		$.GetContextPanel().style["tooltip-arrow-position"] = fOffset + "px 0px";
		$.GetContextPanel().style["tooltip-body-position"] = (fOffset - 16) + "px 0px";
		
		bXPTooltipActive = true;
		
		var szLocalizedXPString = $.Localize("iw_ui_actionbar_xp");
		var tXPData = CustomNetTables.GetTableValue("game", "xp");
		if (Entities.GetLevel(nEntityIndex) == tXPData["max_level"])
		{
			szLocalizedXPString = szLocalizedXPString.replace(/\{[^}]\}/g, Entities.GetCurrentXP(nEntityIndex));
			$.DispatchEvent("DOTAShowTextTooltip", szLocalizedXPString);
		}
		else
		{
			var nCurrentLevelXP = tXPData[Entities.GetLevel(nEntityIndex)];
			szLocalizedXPString = szLocalizedXPString.replace(/\{0\}/g, (Entities.GetCurrentXP(nEntityIndex) - nCurrentLevelXP));
			szLocalizedXPString = szLocalizedXPString.replace(/\{1\}/g, (Entities.GetNeededXPToLevel(nEntityIndex) - nCurrentLevelXP));
			$.DispatchEvent("DOTAShowTextTooltip", szLocalizedXPString);
		}
	}
}

function OnXPMouseOut()
{
	bXPTooltipActive = false;
	$.DispatchEvent("DOTAHideTextTooltip");
}

function OnXPLoad()
{
	UpdateXPBar();
}