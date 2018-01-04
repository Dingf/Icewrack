"use strict";

function OnBuffIconMouseOver()
{
	var nEntityIndex = $.GetContextPanel().GetAttributeInt("entindex", -1);
	var nBuffIndex = $.GetContextPanel().GetAttributeInt("buffindex", -1);
	if ((nEntityIndex !== -1) && (nBuffIndex !== -1))
	{
		var szTooltipArgs = "buffindex=" + nBuffIndex + "&entindex=" + nEntityIndex;
		$.DispatchEvent("UIShowCustomLayoutParametersTooltip", "ModifierTooltip", "file://{resources}/layout/custom_game/tooltip/iw_tooltip_modifier.xml", szTooltipArgs);
	}
}

function OnBuffIconMouseOut()
{
	$.DispatchEvent("UIHideCustomLayoutTooltip", "ModifierTooltip");
}

function OnBuffIconUpdate(hContextPanel, tArgs)
{
	var nEntityIndex = hContextPanel.GetAttributeInt("entindex", -1);
	var nBuffIndex = hContextPanel.GetAttributeInt("buffindex", -1);
	var fBuffTimeRemaining = Buffs.GetRemainingTime(nEntityIndex, nBuffIndex);
	var fBuffDuration = Buffs.GetDuration(nEntityIndex, nBuffIndex);
	fBuffTimeRemaining = (fBuffTimeRemaining < -0.5) ? fBuffDuration : fBuffTimeRemaining;
	var fBuffTimePercent = (fBuffDuration <= 0) ? 1.0 : fBuffTimeRemaining/fBuffDuration;
	
	var nBuffStackCount = Buffs.GetStackCount(nEntityIndex, nBuffIndex);
	if (nBuffStackCount > 0)
	{
		hContextPanel.FindChildTraverse("StackLabel").text = nBuffStackCount + "";
		hContextPanel.FindChildTraverse("StackLabel").visible = true;
	}
	else
	{
		hContextPanel.FindChildTraverse("StackLabel").visible = false;
	}
	
	var hLeftDurationFill = hContextPanel.FindChildTraverse("LeftDurationFill");
	var hRightDurationFill = hContextPanel.FindChildTraverse("RightDurationFill");
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
		hContextPanel.visible = false;
	}
	return true;
}

function UpdateBuffIcon(hPanel)
{
	if (hPanel.visible === true)
	{
		DispatchCustomEvent(hPanel, "BuffIconUpdate");
	}
	$.Schedule(0.03, hPanel._hUpdateFunction);
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
	DispatchCustomEvent(hContextPanel, "BuffIconUpdate");
	return true;
}

function OnBuffIconHide(hContextPanel, tArgs)
{
	hContextPanel.SetAttributeInt("entindex", -1);
	hContextPanel.SetAttributeInt("buffindex", -1);
	hContextPanel.visible = false;
	return true;
}

function OnBuffIconLoad()
{
	RegisterCustomEventHandler($.GetContextPanel(), "BuffIconUpdate", OnBuffIconUpdate);
	RegisterCustomEventHandler($.GetContextPanel(), "BuffIconSetValue", OnBuffIconSetValue);
	RegisterCustomEventHandler($.GetContextPanel(), "BuffIconHide", OnBuffIconHide);
}

function CreateBuffIcon(hParent, szName, nEntityIndex, nBuffIndex)
{
	var hPanel = $.CreatePanel("Panel", hParent, szName);
	hPanel.BLoadLayout("file://{resources}/layout/custom_game/ui/iw_widget_buff_icon.xml", false, false);
	OnBuffIconSetValue(hPanel, { entindex:nEntityIndex, buffindex:nBuffIndex });
	
	hPanel._hUpdateFunction = UpdateBuffIcon.bind(this, hPanel);
	hPanel._hUpdateFunction();
	return hPanel;
}