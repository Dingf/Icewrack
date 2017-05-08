"use strict";

var tAAMConditionOffsets = [0, 0, 3, 6, 9, 12, 14, 17, 18, 19, 20, 22, 27, 28, 29, 30, 31, 32, 33, 34, 37, 45, 48, 49, 50, 63, 64];

var tAAMConditionSpecialActions = 
[
	"aam_do_nothing",
	"aam_skip_to_condition",
	"aam_skip_remaining",
	"aam_attack",
	"aam_hold_position",
	"aam_move_away_from",
	"aam_move_towards",
	"aam_move_in_front_of",
	"aam_move_behind",
];

function UpdateAAMConditionState(hContextPanel)
{
	var nEntityIndex = hContextPanel.GetAttributeInt("entindex", -1);
	var hConditionMenu = hContextPanel.FindChildTraverse("ConditionMenu");
	var tEntityBindList = CustomNetTables.GetTableValue("spellbook", nEntityIndex).Binds;
	var szActionName = hConditionMenu._mValue;
	DispatchCustomEvent(hConditionMenu, "DropdownMenuClear");
	for (var i = 0; i < tAAMConditionSpecialActions.length; i++)
	{
		AddDropdownMenuItem(hConditionMenu, $.Localize("DOTA_Tooltip_Ability_" + tAAMConditionSpecialActions[i]), tAAMConditionSpecialActions[i]);
	}
	for (var k in tEntityBindList)
	{
		var nAbilityIndex = parseInt(tEntityBindList[k]);
		var szAbilityName = Abilities.GetAbilityName(nAbilityIndex);
		if (!Abilities.IsPassive(nAbilityIndex))
		{
			AddDropdownMenuItem(hConditionMenu, $.Localize("DOTA_Tooltip_Ability_" + szAbilityName), szAbilityName);
		}
	}
	if (typeof(szActionName) !== "undefined")
	{
		if (!hConditionMenu._tMenuEntries[szActionName])
		{
			var hDropdownItem = AddDropdownMenuItem(hConditionMenu, $.Localize("DOTA_Tooltip_Ability_" + szActionName), szActionName);
			DispatchCustomEvent(hConditionMenu, "DropdownValueUpdateQuiet", { panel:hConditionMenu, value:szActionName });
			hContextPanel.SetHasClass("AAMConditionInvalid", true);
			hContextPanel.SetAttributeString("ability", szActionName);
			hDropdownItem.visible = false;
		}
		else
		{
			DispatchCustomEvent(hConditionMenu, "DropdownValueUpdateQuiet", { panel:hConditionMenu, value:szActionName });
			hContextPanel.SetHasClass("AAMConditionInvalid", false);
			hContextPanel.SetAttributeString("ability", szActionName);
		}
	}
}

function OnSpellbookUpdate(szTableName, szKey)
{
	var nEntityIndex = $.GetContextPanel().GetAttributeInt("entindex", -1);
	if (parseInt(szKey) == nEntityIndex)
	{
		UpdateAAMConditionState($.GetContextPanel());
	}
}

function OnAAMConditionUpdateValue(hContextPanel, tArgs)
{
	var nFlags1 = 0;
	var nFlags2 = 0;
	var nInverseMask = 0;
	var tChildren = hContextPanel.FindChildTraverse("ConditionItemList").Children();
	for (var k in tChildren)
	{
		var nID = tChildren[k].GetAttributeInt("id", -1);
		var nValue = tChildren[k].GetAttributeInt("value", 0);
		var nOffset = tAAMConditionOffsets[nID];
		
		if (nOffset < 32)
		{
			nFlags1 = nFlags1 | (nValue << nOffset);
		}
		else
		{
			nFlags2 = nFlags2 | (nValue << (nOffset - 32));
		}
		if (tChildren[k].GetAttributeInt("inverse", 0) === 1)
		{
			nInverseMask = nInverseMask | (1 << (nID - 1));
		}
	}
	
	var hConditionBody = hContextPanel.FindChildTraverse("ConditionBody");
	nFlags2 = nFlags2 | (hConditionBody.FindChild("DropdownMenu0")._mValue << 26);
	nFlags2 = nFlags2 | (hConditionBody.FindChild("DropdownMenu1")._mValue << 24);
	nFlags2 = nFlags2 | (hConditionBody.FindChild("DropdownMenu2")._mValue << 18);
	nFlags2 = nFlags2 | (hConditionBody.FindChild("DropdownMenu3")._mValue << 21);
	
	hContextPanel.SetAttributeInt("flags1", nFlags1);
	hContextPanel.SetAttributeInt("flags2", nFlags2);
	hContextPanel.SetAttributeInt("inverse_mask", nInverseMask);
	var szAbilityName = hContextPanel.GetAttributeString("ability", "");
	
	var hConditionExtra1 = hContextPanel.FindChildTraverse("ConditionMenuExtra1");
	var hConditionExtra2 = hContextPanel.FindChildTraverse("ConditionMenuExtra2");
	if (hConditionExtra1.visible && hConditionExtra2.visible)
	{
		szAbilityName += hConditionExtra1._mValue;
		szAbilityName += hConditionExtra2._mValue;
	}

	if (!tArgs.local)
	{
		GameEvents.SendCustomGameEventToServer("iw_aam_update_condition",
		{
			entindex : hContextPanel.GetAttributeInt("entindex", -1),
			priority : hContextPanel.GetAttributeInt("priority", -1),
			ability  : szAbilityName,
			flags1   : nFlags1,
			flags2   : nFlags2,
			invmask  : nInverseMask,
		});
	}
}

function OnAAMConditionValueUpdate(hContextPanel, tArgs)
{
	if (tArgs.panel.id === "AddDropdownMenu")
	{
		var hAddDropdownMenu = hContextPanel.FindChildTraverse("AddDropdownMenu");
		var hConditionItemList = hContextPanel.FindChildTraverse("ConditionItemList");
		var hPanel = CreateAAMConditionItem(hConditionItemList, "AAMCondition" + tArgs.value, tArgs.value);
		hAddDropdownMenu.FindChildTraverse("Label").text = $.Localize("iw_ui_aam_add_subcondition");
		hAddDropdownMenu._hMenuList.FindChildTraverse("Dropdown" + tArgs.value).visible = false;
		//DispatchCustomEvent(hContextPanel, "AAMConditionUpdateValue", { local:false });
		//$.Schedule(0.03, UpdateAAMConditionValue.bind(this, hContextPanel));
	}
	else if (tArgs.panel.id === "ConditionMenu")
	{
		var hConditionIcon = hContextPanel.FindChildTraverse("ConditionIcon");
		hConditionIcon.SetImage("file://{images}/spellicons/" + tArgs.value + ".png");
		hContextPanel.SetAttributeString("ability", tArgs.value);
		if (tArgs.value === "aam_skip_to_condition")
		{
			hContextPanel.FindChildTraverse("ConditionMenuExtra1").visible = true;
			hContextPanel.FindChildTraverse("ConditionMenuExtra2").visible = true;
		}
		else
		{
			hContextPanel.FindChildTraverse("ConditionMenuExtra1").visible = false;
			hContextPanel.FindChildTraverse("ConditionMenuExtra2").visible = false;
		}
		
		hContextPanel.SetHasClass("AAMConditionInvalid", false);
		DispatchCustomEvent(hContextPanel, "AAMConditionUpdateValue", { quiet:false });
	}
	else
	{
		DispatchCustomEvent(hContextPanel, "AAMConditionUpdateValue", { quiet:false });
	}
	return true;
}

function OnAAMConditionItemDelete(hContextPanel, tArgs)
{
	var hAddDropdownMenu = hContextPanel.FindChildTraverse("AddDropdownMenu");
	hAddDropdownMenu._hMenuList.FindChildTraverse("Dropdown" + tArgs.id).visible = true;
	DispatchCustomEvent(hContextPanel, "AAMConditionUpdateValue", { local:false });
	//$.Schedule(0.03, UpdateAAMConditionValue.bind(this, hContextPanel));
	return true;
}

function OnAAMConditionSetValue(hContextPanel, tArgs)
{
	var nFlags1 = tArgs.flags1;
	var nFlags2 = tArgs.flags2;
	var nInverseMask = tArgs.invmask;
	var szActionName = tArgs.ability;
	
	var hConditionIcon = hContextPanel.FindChildTraverse("ConditionIcon");
	hConditionIcon.SetImage("file://{images}/spellicons/" + szActionName + ".png");
	
	var hConditionMenu = hContextPanel.FindChildTraverse("ConditionMenu");
	hConditionMenu._mValue = tArgs.ability;
	UpdateAAMConditionState(hContextPanel);
	
	var hConditionItemList = hContextPanel.FindChildTraverse("ConditionItemList");
	var hAddDropdownMenu = hContextPanel.FindChildTraverse("AddDropdownMenu");
	for (var i = 1; i < tAAMConditionOffsets.length - 1; i++)
	{
		var nOffset = tAAMConditionOffsets[i];
		var nSize = tAAMConditionOffsets[i+1] - nOffset;
		var nInverse = (nInverseMask >>> (i - 1)) & 0x01;
		
		var nValue = (nOffset < 32) ? ((nFlags1 >>> nOffset) & ~(0xFFFFFFFF << nSize)) : ((nFlags2 >>> (nOffset - 32)) & ~(0xFFFFFFFF << nSize));
		if (i === 24)
		{
			var hConditionBody = hContextPanel.FindChildTraverse("ConditionBody");
			var hDropdown0 = hConditionBody.FindChild("DropdownMenu0");
			DispatchCustomEvent(hDropdown0, "DropdownValueUpdateQuiet", { panel:hDropdown0, value:((nValue & 0x300) >>> 8) });
			var hDropdown1 = hConditionBody.FindChild("DropdownMenu1");
			DispatchCustomEvent(hDropdown1, "DropdownValueUpdateQuiet", { panel:hDropdown1, value:((nValue & 0xC0) >>> 6) });
			var hDropdown2 = hConditionBody.FindChild("DropdownMenu2");
			DispatchCustomEvent(hDropdown2, "DropdownValueUpdateQuiet", { panel:hDropdown2, value:(nValue & 0x07) });
			var hDropdown3 = hConditionBody.FindChild("DropdownMenu3");
			DispatchCustomEvent(hDropdown3, "DropdownValueUpdateQuiet", { panel:hDropdown3, value:((nValue & 0x38) >>> 3) });
		}
		else if (nValue !== 0)
		{
			var hPanel = CreateAAMConditionItem(hConditionItemList, "AAMCondition" + i, i);
			hAddDropdownMenu._hMenuList.FindChildTraverse("Dropdown" + i).visible = false;
			DispatchCustomEvent(hPanel, "AAMConditionItemSetValue", { value:nValue, inverse:nInverse });
		}
	}
	//$.Schedule(0.03, DispatchCustomEvent.bind(this, hConditionMenu, "DropdownValueUpdate", { panel:hConditionMenu, value:tArgs.ability }));
	return true;
}

function OnAAMConditionSetPriority(hContextPanel, tArgs)
{
	hContextPanel.SetAttributeInt("priority", tArgs.priority);
	hContextPanel.FindChildTraverse("PriorityLabel").text = tArgs.priority + "";
	return true;
}

function OnAAMConditionMoveUp()
{
	var nEntityIndex = $.GetContextPanel().GetAttributeInt("entindex", -1);
	var nPriority = $.GetContextPanel().GetAttributeInt("priority", -1);
	GameEvents.SendCustomGameEventToServer("iw_aam_move_condition", { entindex:nEntityIndex, old_priority:nPriority, new_priority:nPriority - 1 });
	DispatchCustomEvent($.GetContextPanel(), "AAMConditionMoveUp", { panel:$.GetContextPanel() });
}

function OnAAMConditionMoveDown()
{
	var nEntityIndex = $.GetContextPanel().GetAttributeInt("entindex", -1);
	var nPriority = $.GetContextPanel().GetAttributeInt("priority", -1);
	GameEvents.SendCustomGameEventToServer("iw_aam_move_condition", { entindex:nEntityIndex, old_priority:nPriority, new_priority:nPriority + 1 });
	DispatchCustomEvent($.GetContextPanel(), "AAMConditionMoveDown", { panel:$.GetContextPanel() });
}

function OnAAMConditionDelete()
{
	var nEntityIndex = $.GetContextPanel().GetAttributeInt("entindex", -1);
	var nPriority = $.GetContextPanel().GetAttributeInt("priority", -1);
	GameEvents.SendCustomGameEventToServer("iw_aam_delete_condition", { entindex:nEntityIndex, priority:nPriority });
	
	var tChildren = $.GetContextPanel().FindChildTraverse("ConditionBody").Children();
	for (var k in tChildren)
	{
		if (tChildren[k]._hMenuList)
		{
			tChildren[k]._hMenuList.DeleteAsync(0.0);
		}
	}
	
	tChildren = $.GetContextPanel().FindChildTraverse("ConditionItemList").Children();
	for (var k in tChildren)
	{
		DispatchCustomEvent(tChildren[k], "AAMConditionItemClear");
	}
	DispatchCustomEvent($.GetContextPanel(), "AAMConditionDelete", { panel:$.GetContextPanel() });
}

function OnAAMConditionIconMouseOver()
{
	var hConditionIcon = $("#ConditionIcon");
	var szAbilityName = $.GetContextPanel().GetAttributeString("ability", "");
	if (szAbilityName !== "")
	{
		var nEntityIndex = $.GetContextPanel().GetAttributeInt("entindex", -1);
		var szTooltipArgs = "abilityname=" + szAbilityName + "&entindex=" + nEntityIndex;
		$.DispatchEvent("UIShowCustomLayoutParametersTooltip", hConditionIcon, "AbilityTooltip", "file://{resources}/layout/custom_game/tooltip/iw_tooltip_ability.xml", szTooltipArgs);
	}
}

function OnAAMConditionIconMouseOut()
{
	$.DispatchEvent("UIHideCustomLayoutTooltip", $("#ConditionIcon"), "AbilityTooltip");
}

function OnAAMConditionLoad()
{
	var szAbilityName = $.GetContextPanel().GetAttributeString("ability", "")
	if (!szAbilityName)
	{
		$.GetContextPanel().SetAttributeString("ability", "aam_do_nothing");
	}
	DispatchCustomEvent($.GetContextPanel(), "AAMConditionUpdateValue", { quiet:false });
	$("#ConditionIcon").SetPanelEvent("onmouseover", OnAAMConditionIconMouseOver);
	$("#ConditionIcon").SetPanelEvent("onmouseout", OnAAMConditionIconMouseOut);
	CustomNetTables.SubscribeNetTableListener("spellbook", OnSpellbookUpdate);
}

function CreateAAMCondition(hParent, szName, nEntityIndex, bIsLocal)
{
	var hPanel = $.CreatePanel("Panel", hParent, szName);
	hPanel.BLoadLayout("file://{resources}/layout/custom_game/aam/iw_aam_condition.xml", false, false);
	hPanel.SetAttributeInt("entindex", nEntityIndex);
	
	var hAddDropdownMenu = CreateDropdownMenu(hPanel.FindChildTraverse("AddCondition"), "AddDropdownMenu");
	for (var i = 1; i < tAAMConditionOffsets.length - 1; i++)
	{
		//Offset 24 is the targeting params in the main condition body; don't create a dropdown for it
		if (i !== 24)
		{
			var szLocalizedText = $.Localize("#iw_ui_aam_condition" + i);
			szLocalizedText = szLocalizedText.replace(/\{[^}]\}/g, "");
			szLocalizedText = szLocalizedText.replace("  ", " ");
			AddDropdownMenuItem(hAddDropdownMenu, szLocalizedText, i);
		}
	}
	hAddDropdownMenu.FindChildTraverse("Label").text = $.Localize("iw_ui_aam_add_subcondition");
	
	var hConditionMenu = CreateDropdownMenu(hPanel.FindChildTraverse("ConditionBody"), "ConditionMenu");
	UpdateAAMConditionState(hPanel);
	
	var hConditionBody = hPanel.FindChildTraverse("ConditionBody");
	var hConditionMenuExtra1 = CreateDropdownMenu(hConditionBody, "ConditionMenuExtra1");
	var hConditionMenuExtra2 = CreateDropdownMenu(hConditionBody, "ConditionMenuExtra2");
	CreateDropdownText(hConditionBody, "iw_ui_aam_condition_main", { "0":15, "1":4, "2":7, "3":7 });
	for (var i = 0; i < 10; i++)
	{
		AddDropdownMenuItem(hConditionMenuExtra1, String(i), i);
		AddDropdownMenuItem(hConditionMenuExtra2, String(i), i);
	}
	hConditionMenuExtra1.visible = false;
	hConditionMenuExtra2.visible = false;
	
	RegisterCustomEventHandler(hPanel, "DropdownValueUpdate", OnAAMConditionValueUpdate);
	RegisterCustomEventHandler(hPanel, "AAMConditionItemInvert", OnAAMConditionValueUpdate);
	RegisterCustomEventHandler(hPanel, "AAMConditionItemDelete", OnAAMConditionItemDelete);
	RegisterCustomEventHandler(hPanel, "AAMConditionSetValue", OnAAMConditionSetValue);
	RegisterCustomEventHandler(hPanel, "AAMConditionUpdateValue", OnAAMConditionUpdateValue);
	RegisterCustomEventHandler(hPanel, "AAMConditionSetPriority", OnAAMConditionSetPriority);
	
	DispatchCustomEvent(hPanel, "AAMConditionUpdateValue", { local:bIsLocal });
	return hPanel;
}