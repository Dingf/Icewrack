"use strict";

function OnAbilitySkillIconSetState(hContextPanel, tArgs)
{
	var nState = tArgs.state;
	hContextPanel.SetAttributeInt("state", nState);
	hContextPanel.FindChild("Texture").SetHasClass("AbilitySkillIconDisabled", (nState === 0));
	return true;
}

function OnAbilitySkillIconActivate()
{
	var nState = $.GetContextPanel().GetAttributeInt("state", 1);
	DispatchCustomEvent($.GetContextPanel(), "AbilitySkillIconSetState", { state:1-nState });
	DispatchCustomEvent($.GetContextPanel().GetParent(), "AbilitySkillIconActivate", { panel:$.GetContextPanel() });
}

function OnAbilitySkillIconMouseOver()
{
	var nSkillID = $.GetContextPanel().GetAttributeInt("id", -1);
	if (nSkillID !== -1)
	{
		var nState = $.GetContextPanel().GetAttributeInt("state", -1);
		//var szTooltipText = (nState === 1) ? $.Localize("iw_ui_abilities_tooltip_show") : $.Localize("iw_ui_abilities_tooltip_hide");
		//szTooltipText = szTooltipText.replace(/\{0\}/g, );
		
		var szTooltipText = $.Localize("iw_ui_character_skills_" + Math.floor(nSkillID/13) + "_" + (nSkillID % 13));
		szTooltipText = "<b>" + szTooltipText + "</b><br>";
		szTooltipText = szTooltipText + "<font color=\"#c0c0c0\">" + $.Localize("iw_ui_character_skills_" + Math.floor(nSkillID/13) + "_" + (nSkillID % 13) + "_desc") + "</font>";
		$.DispatchEvent("DOTAShowTextTooltip", $.GetContextPanel(), szTooltipText);
	}
}

function OnAbilitySkillIconMouseOut()
{
	$.DispatchEvent("DOTAHideTextTooltip", $.GetContextPanel());
}

function CreateAbilitySkillIcon(hParent, szName, nSkillID)
{
	var hPanel = $.CreatePanel("Panel", hParent, szName);
	hPanel.BLoadLayout("file://{resources}/layout/custom_game/ability/iw_ability_skill_icon.xml", false, false);
	hPanel.SetAttributeInt("id", nSkillID);
	hPanel.SetAttributeInt("state", 1);
	
	var hTexture = hPanel.FindChildrenWithClassTraverse("AbilitySkillIconTexture")[0];
	hTexture.SetImage("file://{images}/custom_game/icons/skills/iw_skill_icon_" + nSkillID + ".tga");
	
	RegisterCustomEventHandler(hPanel, "AbilitySkillIconSetState", OnAbilitySkillIconSetState);
	
	DispatchCustomEvent(hParent, "AbilitySkillIconActivate", { panel:hPanel });
	return hPanel;
}