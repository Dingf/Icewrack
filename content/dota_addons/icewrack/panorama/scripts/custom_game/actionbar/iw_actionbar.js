"use strict";

function OnTooltipMouseOver()
{
	$("#Tooltip").AddClass("ActionBarTooltipVisible");
	$("#Tooltip").RemoveClass("ActionBarTooltipFadeOut");
}

function OnTooltipMouseOut()
{
	$("#Tooltip").RemoveClass("ActionBarTooltipVisible");
	$("#Tooltip").AddClass("ActionBarTooltipFadeOut");
}

function OnActionBarAbilityBind(hContextPanel, tArgs)
{
	var nEntityIndex = tArgs.entindex;
	var nAbilityIndex = tArgs.ability;
	var tActionBarBinds = hContextPanel._tActionBarBinds;
	if (nAbilityIndex !== 0)
	{
		if (!tActionBarBinds[tArgs.entindex])
		{
			tActionBarBinds[tArgs.entindex] = []
		}
		tActionBarBinds[tArgs.entindex][tArgs.slot-1] = nAbilityIndex;
		GameEvents.SendCustomGameEventToServer("iw_actionbar_bind", { slot:tArgs.slot, entindex:nEntityIndex, ability:nAbilityIndex });
	}
	else
	{
		delete tActionBarBinds[tArgs.entindex][tArgs.slot-1];
		GameEvents.SendCustomGameEventToServer("iw_actionbar_bind", { slot:tArgs.slot, entindex:nEntityIndex, ability:-1 });
	}
	
	DispatchCustomEvent(hContextPanel, "ActionBarBindUpdate", { entindex:nEntityIndex });
	DispatchCustomEvent(hContextPanel.FindChildTraverse("Tooltip"), "ActionBarTooltipHide");
	return true;
}

function OnActionBarRefresh(hContextPanel, tArgs)
{
	var nEntityIndex = tArgs.entindex;
	var tEntitySpellbook = CustomNetTables.GetTableValue("spellbook", nEntityIndex);
	if (tEntitySpellbook && !Entities.IsEnemy(nEntityIndex))
	{
		var tEntitySpellList = tEntitySpellbook.Spells;
		var nEntitySpellCount = 0;
		for (var k in tEntitySpellList)
			nEntitySpellCount++;
		
		var hTooltip = $("#Tooltip");
		var hTooltipIconContainer = $("#Tooltip").FindChildTraverse("TooltipContainer");
		var tTooltipIcons = hContextPanel._tTooltipIcons;
		if (nEntitySpellCount >= tTooltipIcons.length)
		{
			for (var i = tTooltipIcons.length; i <= nEntitySpellCount; i++)
			{
				var hIcon = $.CreatePanel("Panel", hTooltipIconContainer, "TooltipIcon" + (i + 1));
				hIcon.BLoadLayout("file://{resources}/layout/custom_game/actionbar/iw_actionbar_tooltip_icon.xml", false, false);
				hIcon.style.position = (8 + ((i % 4) * 68)) + "px " + (8 + (Math.floor(i/4) * 68)) + "px 0px";
				hIcon._hTooltip = hTooltip;
				tTooltipIcons.push(hIcon);
			}
		}
		
		var nNumTooltipIcons = 0;
		for (var k in tEntitySpellList)
		{
			var hIcon = $("#TooltipIcon" + (nNumTooltipIcons + 1));
			var nAbilityIndex = parseInt(k);
			var szAbilityTextureName = Abilities.GetAbilityTextureName(nAbilityIndex);
			hIcon.SetAttributeInt("abilityindex", nAbilityIndex);
			hIcon.SetAttributeInt("caster", nEntityIndex);
			hIcon.FindChildTraverse("AbilityTexture").SetImage("file://{images}/spellicons/" + szAbilityTextureName + ".png");
			hIcon.visible = true;
			nNumTooltipIcons++;
		}
		
		var hIcon = $("#TooltipIcon" + (nNumTooltipIcons + 1));
		hIcon.FindChildTraverse("AbilityTexture").SetImage("file://{images}/spellicons/internal_clear_slot.png");
		hIcon.SetAttributeInt("caster", nEntityIndex);
		hIcon.SetAttributeInt("abilityindex", 0);
		hIcon.visible = true;
		nNumTooltipIcons++;
					
		for (var j = nNumTooltipIcons + 1; j <= tTooltipIcons.length; j++)
			$("#TooltipIcon" + j).visible = false;
				
		hTooltip.SetAttributeInt("num_icons", nNumTooltipIcons);
		hTooltip.style["width"] = Math.min(8 + (nNumTooltipIcons * 68), 280) + "px";
		hTooltip.style["height"] = (28 + (68 * Math.ceil(nNumTooltipIcons/4))) + "px";
	}
	
	var hXPBar = hContextPanel.FindChildTraverse("XPBar");
	hXPBar.SetAttributeInt("caster", Entities.IsEnemy(nEntityIndex) ? -1 : nEntityIndex);
	
	DispatchCustomEvent(hContextPanel, "ActionBarBindUpdate", { entindex:nEntityIndex });
	return true;
}

function OnActionBarTooltipHide(hContextPanel, tArgs)
{
	hContextPanel.RemoveClass("ActionBarTooltipFadeIn");
	hContextPanel.RemoveClass("ActionBarTooltipFadeOut");
	hContextPanel.RemoveClass("ActionBarTooltipVisible");
	return true;
}

function OnActionBarHotkey(tArgs)
{
	DispatchCustomEvent($("#Icon" + tArgs.value), "ActionBarIconActivate");
}

function OnSpellbookUpdate(szTableName, szKey)
{
	var nLastEntityIndex = $.GetContextPanel().GetAttributeInt("last_entindex", -1);
	if (parseInt(szKey) === nLastEntityIndex)
	{
		DispatchCustomEvent($.GetContextPanel(), "ActionBarRefresh", { entindex:nLastEntityIndex });
	}
}

function OnActionBarBindUpdate(hContextPanel, tArgs)
{
	var nEntityIndex = tArgs.entindex;
	var tActionBarBinds = hContextPanel._tActionBarBinds;
	if (!(nEntityIndex in tActionBarBinds))
	{
		tActionBarBinds[nEntityIndex] = [];
		
		var tEntitySpellbook = CustomNetTables.GetTableValue("spellbook", nEntityIndex);
		if (tEntitySpellbook)
		{
			for (var k in tEntitySpellbook.Binds)
			{
				var nSlot = parseInt(k) - 1;
				tActionBarBinds[nEntityIndex][nSlot] = tEntitySpellbook.Binds[k];
			}
		}
	}
	
	var bIsEnemy = Entities.IsEnemy(nEntityIndex);
	for (var i = 0; i < 10; i++)
	{
		var hIcon = $("#Icon" + (i + 1));
		var nAbilityIndex = tActionBarBinds[nEntityIndex][i];
		if (nAbilityIndex && !bIsEnemy)
		{
			var szAbilityName = Abilities.GetAbilityName(nAbilityIndex);
			var szAbilityTextureName = Abilities.GetAbilityTextureName(nAbilityIndex);
			hIcon.SetAttributeInt("abilityindex", nAbilityIndex);
		}
		else
		{
			hIcon.SetAttributeInt("abilityindex", -1);
		}
		hIcon.SetAttributeInt("caster", nEntityIndex);
		DispatchCustomEvent(hIcon, "ActionBarIconRefresh");
	}
	return true;
}

function OnActionBarKeyUpdate(hContextPanel, tArgs)
{
	var tBindInfo = CustomNetTables.GetTableValue("game", "binds");
	for (var i = 1; i <= 10; i++)
	{
		var hBindLabel = hContextPanel.FindChildTraverse("Bind" + i);
		hBindLabel.text = tBindInfo["iw_actionbar_" + i];
	}
	return true;
}

function OnBindUpdate(szTableName, szKey)
{
	if (szKey === "binds")
	{
		DispatchCustomEvent($.GetContextPanel(), "ActionBarBindKeyUpdate");
	}
}

function UpdateActionBarBuffs(nEntityIndex)
{
	var nBuffCount = 0;
	var hContainer = $("#BuffContainer");
	
	var tBuffIcons = $.GetContextPanel()._tBuffIcons;
	for (var j = 0; j < tBuffIcons.length; j++)
		$("#BuffIcon" + (j + 1)).visible = false;
	
	for (var i = 0; i < Entities.GetNumBuffs(nEntityIndex); i++)
	{
		var nBuffIndex = Entities.GetBuff(nEntityIndex, i);
		if ((nBuffIndex == -1) || Buffs.IsHidden(nEntityIndex, nBuffIndex))
			continue;
		
		var szModifierName = Buffs.GetName(nEntityIndex, nBuffIndex);
		if (szModifierName == "modifier_elder_titan_echo_stomp")	//TODO: Remove me when we figure out a better way to do attack-move immunity
			continue;
			
		if (nBuffCount >= tBuffIcons.length)
		{
			var hIcon = CreateBuffIcon(hContainer, "BuffIcon" + (nBuffCount + 1), nEntityIndex, nBuffIndex);
			hIcon.AddClass("ActionBarBuffIcon");
			tBuffIcons.push(hIcon);
		}
		else if ($("#BuffIcon" + (nBuffCount + 1)).GetAttributeInt("buffindex", -1) !== nBuffIndex)
		{
			DispatchCustomEvent($("#BuffIcon" + (nBuffCount + 1)), "BuffIconSetValue", { entindex:nEntityIndex, buffindex:nBuffIndex });
		}
		$("#BuffIcon" + (nBuffCount + 1)).visible = true;
		nBuffCount++;
	}
}

function UpdateActionBar()
{
	var tSelectedEntities = Players.GetSelectedEntities(Players.GetLocalPlayer());
	if (tSelectedEntities)
	{
		var nEntityIndex = tSelectedEntities[0];
		var nLastEntityIndex = $.GetContextPanel().GetAttributeInt("last_entindex", -1);
		if (nEntityIndex !== nLastEntityIndex)
		{
			DispatchCustomEvent($("#Tooltip"), "ActionBarTooltipHide");
			DispatchCustomEvent($.GetContextPanel(), "ActionBarRefresh", { entindex:nEntityIndex });
			DispatchCustomEvent($("#ChannelBar"), "ActionBarChannelRefresh", { entindex:nEntityIndex });
			$.GetContextPanel().SetAttributeInt("last_entindex", nEntityIndex);
		}
		UpdateActionBarBuffs(nEntityIndex);
	}
	$.Schedule(0.1, UpdateActionBar);
}

(function()
{
	$.GetContextPanel()._tActionBarBinds = {};
	$.GetContextPanel()._tTooltipIcons = [];
	$.GetContextPanel()._tBuffIcons = [];
	$.GetContextPanel().SetAttributeInt("last_entindex", -1);
	
	var hXPContainer = $("#XPContainer");
	var hXPBar = $.CreatePanel("Panel", hXPContainer, "XPBar");
	hXPBar.BLoadLayout("file://{resources}/layout/custom_game/actionbar/iw_actionbar_xp.xml", false, false);
	
	var hChannelContainer = $("#ChannelContainer");
	var hChannelBar = $.CreatePanel("Panel", hChannelContainer, "ChannelBar");
	hChannelBar.BLoadLayout("file://{resources}/layout/custom_game/actionbar/iw_actionbar_channel.xml", false, false);
	
	var hBindContainer = $("#BindContainer");
	var hIconContainer = $("#IconContainer");
	for (var i = 1; i <= 10; i++)
	{
		var hBind = $.CreatePanel("Label", hBindContainer, "Bind" + i);
		hBind.AddClass("ActionBarBindLayout");
		//Use absolute position rather than margins to minimize the rounding/floating point error from rescaling
		hBind.style.position = 180 + ((i - 1) * 75) + "px 0px 0px";
		hBind.SetAttributeInt("slot", i);
		hBind.hittest = false;
		
		var hIcon = $.CreatePanel("Panel", hIconContainer, "Icon" + i);
		hIcon.BLoadLayout("file://{resources}/layout/custom_game/actionbar/iw_actionbar_icon.xml", false, false);
		hIcon.style.position = 156 + ((i - 1) * 75) + "px 0px 0px";
		hIcon.SetAttributeInt("slot", i);
		hIcon._hActionBar = $.GetContextPanel();
	}
	
	GameEvents.Subscribe("iw_actionbar_ability", OnActionBarHotkey);
	
	RegisterCustomEventHandler($.GetContextPanel(), "ActionBarKeyUpdate", OnActionBarKeyUpdate);
	RegisterCustomEventHandler($.GetContextPanel(), "ActionBarBindUpdate", OnActionBarBindUpdate);
	RegisterCustomEventHandler($.GetContextPanel(), "ActionBarTooltipIconBind", OnActionBarAbilityBind);
	RegisterCustomEventHandler($.GetContextPanel(), "ActionBarRefresh", OnActionBarRefresh);
	RegisterCustomEventHandler($("#Tooltip"), "ActionBarTooltipHide", OnActionBarTooltipHide);
	
	CustomNetTables.SubscribeNetTableListener("game", OnBindUpdate);
	CustomNetTables.SubscribeNetTableListener("spellbook", OnSpellbookUpdate);
	
	GameUI.SetRenderBottomInsetOverride(0);
	GameUI.SetRenderTopInsetOverride(0);
	
	DispatchCustomEvent($.GetContextPanel(), "ActionBarKeyUpdate");
	
	$.Schedule(0.1, UpdateActionBar);
})();