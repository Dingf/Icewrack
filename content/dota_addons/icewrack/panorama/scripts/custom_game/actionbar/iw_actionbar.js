"use strict";

function OnHotkeyActionBar(nIndex)
{
	if (!GameUI.IsHidden())
	{
		DispatchCustomEvent($("#Icon" + nIndex), "ActionBarIconActivate");
		return true;
	}
}
for (var i = 1; i <= 10; i++)
{
	Game.RegisterHotkey((i % 10).toString(), OnHotkeyActionBar.bind(this, i));
}

function OnHotkeyQuicksave()
{
	if (Game.GetLocalPlayerID() === 0)
	{
		GameEvents.SendCustomGameEventToServer("iw_quicksave", {});
		return true;
	}
}
Game.RegisterHotkey("F5", OnHotkeyQuicksave);

function OnHotkeyQuickload()
{
	if (Game.GetLocalPlayerID() === 0)
	{
		GameEvents.SendCustomGameEventToServer("iw_quickload", {});
		return true;
	}
}
Game.RegisterHotkey("F9", OnHotkeyQuickload);

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
	if (nAbilityIndex !== 0)
	{
		GameEvents.SendCustomGameEventToServer("iw_actionbar_bind", { slot:tArgs.slot, entindex:nEntityIndex, ability:nAbilityIndex });
	}
	else
	{
		GameEvents.SendCustomGameEventToServer("iw_actionbar_bind", { slot:tArgs.slot, entindex:nEntityIndex, ability:-1 });
	}
	
	DispatchCustomEvent(hContextPanel, "ActionBarBindUpdate", { entindex:nEntityIndex });
	DispatchCustomEvent(hContextPanel.FindChildTraverse("Tooltip"), "ActionBarTooltipHide");
	return true;
}

function OnActionBarRefresh(hContextPanel, tArgs)
{
	var nEntityIndex = tArgs.entindex;
	var tEntityBinds = CustomNetTables.GetTableValue("binds", nEntityIndex);
	var tEntitySpellbook = CustomNetTables.GetTableValue("spellbook", nEntityIndex);
	if (tEntitySpellbook && Entities.IsControllableByPlayer(nEntityIndex, Players.GetLocalPlayer()))
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
			var bIsAbilityBound = false;
			var nAbilityIndex = parseInt(k);
			for (var i = 0; i < 10; i++)
			{
				if (tEntityBinds[i+1] === nAbilityIndex)
				{
					bIsAbilityBound = true;
					break;
				}
			}
			
			if (bIsAbilityBound)
				continue;
			
			var hIcon = $("#TooltipIcon" + (nNumTooltipIcons + 1));
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

function OnActionBarNetTableUpdate(szTableName, szKey)
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
	var tEntityBinds = CustomNetTables.GetTableValue("binds", nEntityIndex);
	for (var i = 0; i < 10; i++)
	{
		var hIcon = $("#Icon" + (i + 1));
		var nAbilityIndex = tEntityBinds[i+1];
		if (nAbilityIndex && Entities.IsControllableByPlayer(nEntityIndex, Players.GetLocalPlayer()))
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

function UpdateActionBarBuffs(nEntityIndex)
{
	var nBuffCount = 0;
	var hContainer = $("#BuffContainer");
	
	var tBuffIcons = $.GetContextPanel()._tBuffIcons;
	var nLastEntityIndex = $.GetContextPanel().GetAttributeInt("last_entindex", -1);
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
}

function UpdateActionBar()
{
	var tSelectedEntities = Players.GetSelectedEntities(Players.GetLocalPlayer());
	if (tSelectedEntities.length > 0)
	{
		var nEntityIndex = tSelectedEntities[0];
		var nLastEntityIndex = $.GetContextPanel().GetAttributeInt("last_entindex", -1);
		UpdateActionBarBuffs(nEntityIndex);
		if (nEntityIndex !== nLastEntityIndex)
		{
			var tEntityBinds = CustomNetTables.GetTableValue("binds", nEntityIndex);
			if (tEntityBinds)
			{
				DispatchCustomEvent($("#Tooltip"), "ActionBarTooltipHide");
				DispatchCustomEvent($.GetContextPanel(), "ActionBarRefresh", { entindex:nEntityIndex });
				$.GetContextPanel().SetAttributeInt("last_entindex", nEntityIndex);
			}
			else
			{
				$.GetContextPanel().SetAttributeInt("last_entindex", nEntityIndex);
				GameEvents.SendCustomGameEventToServer("iw_actionbar_info", { entindex:nEntityIndex });
			}
			DispatchCustomEvent($("#ChannelBar"), "ActionBarChannelRefresh", { entindex:nEntityIndex });
		}
	}
	$.Schedule(0.03, UpdateActionBar);
}

(function()
{
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
		var hBindLabel = $.CreatePanel("Label", hBindContainer, "Bind" + i);
		hBindLabel.AddClass("ActionBarBindLayout");
		//Use absolute position rather than margins to minimize the rounding/floating point error from rescaling
		hBindLabel.style.position = 180 + ((i - 1) * 75) + "px 0px 0px";
		hBindLabel.SetAttributeInt("slot", i);
		hBindLabel.text = i % 10;
		hBindLabel.hittest = false;
		
		var hIcon = $.CreatePanel("Panel", hIconContainer, "Icon" + i);
		hIcon.BLoadLayout("file://{resources}/layout/custom_game/actionbar/iw_actionbar_icon.xml", false, false);
		hIcon.style.position = 156 + ((i - 1) * 75) + "px 0px 0px";
		hIcon.SetAttributeInt("slot", i);
		hIcon._hActionBar = $.GetContextPanel();
	}
	
	RegisterCustomEventHandler($.GetContextPanel(), "ActionBarBindUpdate", OnActionBarBindUpdate);
	RegisterCustomEventHandler($.GetContextPanel(), "ActionBarTooltipIconBind", OnActionBarAbilityBind);
	RegisterCustomEventHandler($.GetContextPanel(), "ActionBarRefresh", OnActionBarRefresh);
	RegisterCustomEventHandler($("#Tooltip"), "ActionBarTooltipHide", OnActionBarTooltipHide);
	
	CustomNetTables.SubscribeNetTableListener("binds", OnActionBarNetTableUpdate);
	CustomNetTables.SubscribeNetTableListener("spellbook", OnActionBarNetTableUpdate);
	
	GameUI.SetRenderBottomInsetOverride(0);
	GameUI.SetRenderTopInsetOverride(0);
	
	$.Schedule(0.1, UpdateActionBar);
})();