"use strict";

function UpdateStatusBarEntity(nEntityIndex)
{
	var bIsTombstoneEntity = Entities.InState(nEntityIndex, modifierstate.MODIFIER_STATE_FAKE_ALLY);
	var bIsCorpseEntity = Entities.IsCommandRestricted(nEntityIndex);
	
	$.GetContextPanel().visible = true;
	$("#Name").text = $.Localize("#" + Entities.GetUnitName(nEntityIndex));
	if (bIsCorpseEntity)
		$("#Name").text += $.Localize("#iw_ui_corpse_suffix");
	
	var fHealth = (bIsTombstoneEntity || bIsCorpseEntity) ? 0 : Entities.GetHealth(nEntityIndex);
	var fMaxHealth = Entities.GetMaxHealth(nEntityIndex);
	$("#HPFill").style.width = ((fHealth * 360)/((fMaxHealth === 0) ? 1 : fMaxHealth)) + "px";
	
	var nBuffCount = 0;
	var hContainer = $("#BuffContainer");
	var tBuffIcons = $.GetContextPanel()._tBuffIcons;
	for (var j = 0; j < Entities.GetNumBuffs(nEntityIndex); j++)
	{
		var nBuffIndex = Entities.GetBuff(nEntityIndex, j);
		if ((nBuffIndex == -1) || Buffs.IsHidden(nEntityIndex, nBuffIndex))
			continue;

		var szModifierName = Buffs.GetName(nEntityIndex, nBuffIndex);
		if (szModifierName == "modifier_elder_titan_echo_stomp")	//TODO: Remove me when we figure out a better way to do attack-move immunity
			continue;
		var nLastEntityIndex = $.GetContextPanel().GetAttributeInt("last_entindex", -1);
		if (nBuffCount >= tBuffIcons.length)
		{
			var hIcon = CreateBuffIcon(hContainer, "BuffIcon" + (nBuffCount + 1), nEntityIndex, nBuffIndex);
			hIcon.AddClass("StatusBarIcon");
			tBuffIcons.push(hIcon);
		}
		else if ((nEntityIndex !== nLastEntityIndex) || ($("#BuffIcon" + (nBuffCount + 1)).GetAttributeInt("buffindex", -1) !== nBuffIndex))
		{
			DispatchCustomEvent($("#BuffIcon" + (nBuffCount + 1)), "BuffIconSetValue", { entindex:nEntityIndex, buffindex:nBuffIndex });
		}
		$("#BuffIcon" + (nBuffCount + 1)).visible = true;
		nBuffCount++;
	}
	for (var j = nBuffCount; j < tBuffIcons.length; j++)
	{
		DispatchCustomEvent($("#BuffIcon" + (j + 1)), "BuffIconHide");
	}
	$.GetContextPanel().SetAttributeInt("last_entindex", nEntityIndex);
}

function UpdateStatusBar()
{
	var tCursorEntities = GameUI.FindScreenEntities(GameUI.GetCursorPosition());
	if (tCursorEntities.length > 0)
	{
		var nEntityIndex = -1;
		for (var i = 0; i < tCursorEntities.length; i++)
		{
			if (Entities.GetUnitName(tCursorEntities[i].entityIndex) && !Entities.IsItemPhysical(tCursorEntities[i].entityIndex))
			{
				nEntityIndex = tCursorEntities[i].entityIndex;
				break;
			}
		}
		for (var i = 0; i < tCursorEntities.length; i++)
		{
			if (nEntityIndex === -1)
			{
				if (!Entities.GetUnitName(tCursorEntities[i].entityIndex) || Entities.IsItemPhysical(tCursorEntities[i].entityIndex))
				{
					continue;
				}
				else
				{
					nEntityIndex = tCursorEntities[i].entityIndex;
				}
			}
			
			UpdateStatusBarEntity(nEntityIndex);
			break;
		}
	}
	else if (GameUI.IsAltDown() && $.GetContextPanel().visible)
	{
		UpdateStatusBarEntity($.GetContextPanel().GetAttributeInt("last_entindex", -1));
	}
	else
	{
		$.GetContextPanel().visible = false;
	}
	$.Schedule(0.03, UpdateStatusBar);
}

(function()
{
	$.GetContextPanel()._tBuffIcons = [];
	$.Schedule(0.1, UpdateStatusBar);
})();