"use strict";

function OnBuffIconMouseOver()
{
	var nEntityIndex = $.GetContextPanel().GetAttributeInt("entindex", -1);
	var nBuffIndex = $.GetContextPanel().GetAttributeInt("buffindex", -1);
	if ((nEntityIndex !== -1) && (nBuffIndex !== -1))
	{
		var szTooltipArgs = "buffindex=" + nBuffIndex + "&entindex=" + nEntityIndex;
		$.DispatchEvent("UIShowCustomLayoutParametersTooltip", "ModifierTooltip", "file://{resources}/layout/custom_game/tooltip/iw_tooltip_modifier.xml", szTooltipArgs);
		
		
		//$.DispatchEvent("DOTAShowBuffTooltip", $.GetContextPanel(), nEntityIndex, nBuffIndex, Entities.IsEnemy(nEntityIndex));
	}
}

function OnBuffIconMouseOut()
{
	$.DispatchEvent("UIHideCustomLayoutTooltip", "ModifierTooltip");
	//$.DispatchEvent("DOTAHideBuffTooltip");
}

function UpdateBuffIcon(hPanel)
{
	if (hPanel.visible === true)
	{
		var nEntityIndex = hPanel.GetAttributeInt("entindex", -1);
		var nBuffIndex = hPanel.GetAttributeInt("buffindex", -1);
		var fBuffTimeRemaining = Buffs.GetRemainingTime(nEntityIndex, nBuffIndex);
		var fBuffDuration = Buffs.GetDuration(nEntityIndex, nBuffIndex);
		fBuffTimeRemaining = (fBuffTimeRemaining < -0.5) ? fBuffDuration : fBuffTimeRemaining;
		var fBuffTimePercent = (fBuffDuration <= 0) ? 1.0 : fBuffTimeRemaining/fBuffDuration;
		
		var hLeftDurationFill = hPanel.FindChildTraverse("LeftDurationFill");
		var hRightDurationFill = hPanel.FindChildTraverse("RightDurationFill");
		hLeftDurationFill.visible = (fBuffTimePercent >= 0.0);
		hRightDurationFill.visible = (fBuffTimePercent >= 0.5);
		if (fBuffTimePercent >= 0.5)
		{
			hLeftDurationFill.style.transform = "rotateZ(0deg)";
			hRightDurationFill.style.transform = "rotateZ(" + ((1.0 - fBuffTimePercent) * 360.0) + "deg)";
		}
		else if (fBuffTimePercent >= 0.0)
		{
			hLeftDurationFill.style.transform = "rotateZ(" + ((0.5 - fBuffTimePercent) * 360.0) + "deg)";
		}
		else
		{
			hPanel.visible = false;
		}
		
		var nBuffStackCount = Buffs.GetStackCount(nEntityIndex, nBuffIndex);
		if (nBuffStackCount > 0)
		{
			hPanel.FindChildTraverse("StackLabel").text = nBuffStackCount + "";
			hPanel.FindChildTraverse("StackLabel").visible = true;
		}
		else
		{
			hPanel.FindChildTraverse("StackLabel").visible = false;
		}
		$.Schedule(0.03, hPanel._hUpdateFunction);
	}
}

function OnBuffIconLoad()
{
	RegisterCustomEventHandler($.GetContextPanel(), "BuffIconSetValue", OnBuffIconSetValue);
}

function OnBuffIconSetValue(hContextPanel, tArgs)
{
	var nEntityIndex = tArgs.entindex;
	var nBuffIndex = tArgs.buffindex;
	var szModifierName = Buffs.GetName(nEntityIndex, nBuffIndex);
	var szTextureName = Buffs.GetTexture(nEntityIndex, nBuffIndex);
	
    var szTextureRegex = /texture=(\w+)/g;
	var tResults = szTextureRegex.exec(szTextureName);
	if (tResults)
	{
		szTextureName = tResults[1];
	}
	
	hContextPanel.FindChildTraverse("ModifierTexture").SetImage("file://{images}/spellicons/" + szTextureName + ".png");
	hContextPanel.SetAttributeString("modifier_name", szModifierName);
	hContextPanel.SetAttributeInt("entindex", nEntityIndex);
	hContextPanel.SetAttributeInt("buffindex", nBuffIndex);
	hContextPanel.FindChildTraverse("Duration").SetHasClass("IsBuff", !Buffs.IsDebuff(nEntityIndex, nBuffIndex));
	$.Schedule(0.03, hContextPanel._hUpdateFunction);
	return true;
}

function CreateBuffIcon(hParent, szName, nEntityIndex, nBuffIndex)
{
	var hPanel = $.CreatePanel("Panel", hParent, szName);
	hPanel._hUpdateFunction = UpdateBuffIcon.bind(this, hPanel);
	hPanel.BLoadLayout("file://{resources}/layout/custom_game/ui/iw_widget_buff_icon.xml", false, false);
	OnBuffIconSetValue(hPanel, { entindex:nEntityIndex, buffindex:nBuffIndex });
	return hPanel;
}