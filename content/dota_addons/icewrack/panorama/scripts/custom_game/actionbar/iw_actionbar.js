"use strict";


var NUM_ACTIONBAR_ICONS = 10;

var bUpdateFlag = false;

var tActionBarBinds = {};
var tTooltipIcons = [];
var tBuffIcons = [];

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

function OnAbilityBind(hContextPanel, tArgs)
{
	var nEntityIndex = tArgs.entindex;
	var nAbilityIndex = tArgs.ability;
	if (nAbilityIndex !== 0)
	{
		if (!tActionBarBinds[tArgs.entindex])
		{
			tActionBarBinds[tArgs.entindex] = []
		}
		tActionBarBinds[tArgs.entindex][tArgs.slot-1] = nAbilityIndex;
		SetEntityBinds(tArgs.entindex);
		GameEvents.SendCustomGameEventToServer("iw_actionbar_bind", { slot:tArgs.slot, entindex:nEntityIndex, ability:nAbilityIndex });
	}
	else
	{
		delete tActionBarBinds[tArgs.entindex][tArgs.slot-1];
		GameEvents.SendCustomGameEventToServer("iw_actionbar_bind", { slot:tArgs.slot, entindex:nEntityIndex, ability:-1 });
	}
	bUpdateFlag = true;
	return true;
}

function OnActionBarHotkey(tArgs)
{
	DispatchCustomEvent($("#Icon" + tArgs.value), "ActionBarIconActivate");
}

function OnActionBarTooltipUpdate(hContext, tArgs)
{
	var nEntityIndex = tArgs.entindex;
	var tEntitySpellbook = CustomNetTables.GetTableValue("spellbook", nEntityIndex);
	if (tEntitySpellbook)
	{
		var tEntitySpellList = tEntitySpellbook.Spells;
		var nEntitySpellCount = 0;
		for (var k in tEntitySpellList)
			nEntitySpellCount++;
		
		var hTooltip = $("#Tooltip");
		var hTooltipIconContainer = $("#Tooltip").FindChildTraverse("TooltipContainer");
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
			var nAbilityIndex = tEntitySpellList[k].entindex;
			hIcon.SetAttributeInt("abilityindex", nAbilityIndex);
			hIcon.SetAttributeInt("caster", nEntityIndex);
			DispatchCustomEvent(hIcon, "ActionBarIconRefresh");
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
	return true;
}

function OnSpellbookUpdate(szTableName, szKey)
{
	var nLastEntityIndex = $.GetContextPanel().GetAttributeInt("last_entindex", -1);
	if (parseInt(szKey) === nLastEntityIndex)
	{
		DispatchCustomEvent($.GetContextPanel(), "ActionBarTooltipUpdate", { entindex:nLastEntityIndex });
		bUpdateFlag = true;
	}
}

function SetEntityBinds(nEntityIndex)
{
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
	for (var i = 0; i < NUM_ACTIONBAR_ICONS; i++)
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
}

function OnActionBarBindUpdate(hContextPanel, tArgs)
{
	var tBindInfo = CustomNetTables.GetTableValue("game", "binds");
	for (var i = 1; i <= 10; i++)
	{
		$("#Bind" + i).text = tBindInfo["iw_actionbar_" + i];
	}
	return true;
}

function OnBindUpdate(szTableName, szKey)
{
	if (szKey === "binds")
	{
		DispatchCustomEvent($.GetContextPanel(), "ActionBarBindUpdate");
	}
}

function UpdateActionBarBuffs(nEntityIndex)
{
	var nBuffCount = 0;
	var hContainer = $("#BuffContainer");
	for (var i = 0; i < Entities.GetNumBuffs(nEntityIndex); i++)
	{
		var nBuffIndex = Entities.GetBuff(nEntityIndex, i);
		if ((nBuffIndex == -1) || Buffs.IsHidden(nEntityIndex, nBuffIndex))
			continue;
		
		var szModifierName = Buffs.GetName(nEntityIndex, nBuffIndex);
		var szTextureName = Buffs.GetTexture(nEntityIndex, nBuffIndex);
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
	if (typeof tSelectedEntities === "undefined")
	{
		$.Schedule(0.1, UpdateActionBar);
		return;
	}
	
	var nEntityIndex = tSelectedEntities[0];
	if ((typeof nEntityIndex === "undefined") || !Entities.IsAlive(nEntityIndex))
		nEntityIndex = -1;
	
	var nLastEntityIndex = $.GetContextPanel().GetAttributeInt("last_entindex", -1);
	if ((nEntityIndex !== nLastEntityIndex) || (bUpdateFlag))
	{
		$("#XPBar").SetAttributeInt("caster", -1);
		if (!bUpdateFlag)
		{
			$("#Tooltip").RemoveClass("ActionBarTooltipFadeIn");
			$("#Tooltip").RemoveClass("ActionBarTooltipFadeOut");
			$("#Tooltip").RemoveClass("ActionBarTooltipVisible");
			DispatchCustomEvent($.GetContextPanel(), "ActionBarTooltipUpdate", { entindex:nEntityIndex });
		}

		SetEntityBinds(nEntityIndex);
		if (!Entities.IsEnemy(nEntityIndex))
		{
			$("#XPBar").SetAttributeInt("caster", nEntityIndex);			
		}
		$.GetContextPanel().SetAttributeInt("last_entindex", nEntityIndex);
		bUpdateFlag = false;
	}
	
	for (var j = 0; j < tBuffIcons.length; j++)
		$("#BuffIcon" + (j + 1)).visible = false;
	
	if ((nEntityIndex === -1) || (Entities.IsEnemy(nEntityIndex)))
	{
		$.Schedule(0.1, UpdateActionBar);
		return;
	}
	
	UpdateActionBarBuffs(nEntityIndex);
	$.Schedule(0.1, UpdateActionBar);
}

(function()
{
	var hXPContainer = $("#XPContainer");
	var hXPBar = $.CreatePanel("Panel", hXPContainer, "XPBar");
	hXPBar.BLoadLayout("file://{resources}/layout/custom_game/actionbar/iw_actionbar_xp.xml", false, false);
	
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
	
	$.GetContextPanel().SetAttributeInt("last_entindex", -1);
	
	GameEvents.Subscribe("iw_actionbar_ability", OnActionBarHotkey);
	
	RegisterCustomEventHandler($.GetContextPanel(), "ActionBarBindUpdate", OnActionBarBindUpdate);
	RegisterCustomEventHandler($.GetContextPanel(), "ActionBarTooltipUpdate", OnActionBarTooltipUpdate);
	RegisterCustomEventHandler($.GetContextPanel(), "ActionBarTooltipIconBind", OnAbilityBind);
	
	CustomNetTables.SubscribeNetTableListener("game", OnBindUpdate);
	CustomNetTables.SubscribeNetTableListener("spellbook", OnSpellbookUpdate);
	
	GameUI.SetRenderBottomInsetOverride(0);
	GameUI.SetRenderTopInsetOverride(0);
	
	$.Schedule(0.1, UpdateActionBar);
	$.Schedule(0.1, DispatchCustomEvent.bind(this, $.GetContextPanel(), "ActionBarBindUpdate"));
})();