"use strict";

var stCharacterInfoboxIcons =
[
	["iw_icon_health", "iw_icon_armor"],
	["iw_icon_mana", "iw_icon_dmg_fire"],
	["iw_icon_stamina", "iw_icon_dmg_cold"],
	["iw_icon_sword", "iw_icon_dmg_lightning"],
	["iw_icon_wand", "iw_icon_dmg_death"],
];

var stCharacterInfoboxText =
[
	["iw_ui_character_overview_hp", "iw_ui_character_infobox_armor"],
	["iw_ui_character_overview_mp", "iw_ui_character_overview_res_fire"],
	["iw_ui_character_overview_sp", "iw_ui_character_overview_res_cold"],
	["iw_ui_character_infobox_damage", "iw_ui_character_overview_res_light"],
	["iw_ui_character_overview_spellpower", "iw_ui_character_overview_res_death"],
];

function OnInfoboxStatMouseOverThink(hContextPanel)
{
	if (hContextPanel._bMouseOver)
	{
		if (GameUI.IsAltDown() && !hContextPanel._bIsTooltipVisible)
		{
			hContextPanel._bTooltipVisible = true;
			var szTextName = hContextPanel.GetAttributeString("text", "");
			var szTooltipText = "<b>" + $.Localize(szTextName) + "</b><br>";
			szTooltipText = szTooltipText + "<font color=\"#c0c0c0\">" + $.Localize(szTextName + "_desc") + "</font>";
			$.DispatchEvent("DOTAShowTextTooltip", hContextPanel, szTooltipText);
		}
		else if (!GameUI.IsAltDown())
		{
			hContextPanel._bTooltipVisible = false;
			$.DispatchEvent("DOTAHideTextTooltip", hContextPanel);
		}
		$.Schedule(0.03, hContextPanel._hThinkerFunction);
	}
	else
	{
		hContextPanel._bTooltipVisible = false;
		$.DispatchEvent("DOTAHideTextTooltip", hContextPanel);
	}
	return 0.03
}

function OnInfoboxStatMouseOver(hContextPanel)
{
	hContextPanel._bTooltipVisible = false;
	hContextPanel._bMouseOver = true;
	if (!hContextPanel._hThinkerFunction)
	{
		hContextPanel._hThinkerFunction = OnInfoboxStatMouseOverThink.bind(this, hContextPanel);
	}
	hContextPanel._hThinkerFunction();
}

function OnInfoboxStatMouseOut(hContextPanel)
{
	hContextPanel._bMouseOver = false;
}

function OnInfoboxUpdate(hContextPanel, tArgs)
{
	var nEntityIndex = tArgs.entindex;
	var szEntityUnitName = Entities.GetUnitName(nEntityIndex);
	
	hContextPanel.SetAttributeInt("entindex", nEntityIndex);
	hContextPanel.FindChildTraverse("InfoboxTitle").text = $.Localize(szEntityUnitName) + ", " + $.Localize("title_" + szEntityUnitName);
	
	var tXPData = CustomNetTables.GetTableValue("game", "xp");
	var szLocalizedSubtitleString = $.Localize("iw_ui_character_infobox_subtitle");
	if (Entities.GetLevel(nEntityIndex) == tXPData["max_level"])
	{
		szLocalizedSubtitleString = szLocalizedSubtitleString.replace(/\{1\}/g, Entities.GetCurrentXP(nEntityIndex));
		szLocalizedSubtitleString = szLocalizedSubtitleString.replace(/\{2\}/g, Entities.GetCurrentXP(nEntityIndex));
	}
	else
	{
		var nCurrentLevelXP = tXPData[Entities.GetLevel(nEntityIndex)];
		szLocalizedSubtitleString = szLocalizedSubtitleString.replace(/\{1\}/g, (Entities.GetCurrentXP(nEntityIndex) - nCurrentLevelXP));
		szLocalizedSubtitleString = szLocalizedSubtitleString.replace(/\{2\}/g, (Entities.GetNeededXPToLevel(nEntityIndex) - nCurrentLevelXP));
	}
	hContextPanel.FindChildTraverse("InfoboxSubtitle").text = szLocalizedSubtitleString.replace(/\{0\}/g, Entities.GetLevel(nEntityIndex));
	
	var tEntityData = CustomNetTables.GetTableValue("entities", nEntityIndex);
	var tInventoryData = CustomNetTables.GetTableValue("inventory", nEntityIndex);
	
	if (tEntityData)
	{
		var hHealthLabel = hContextPanel.FindChildTraverse("Stat11").FindChild("Label");
		hHealthLabel.text = Entities.GetHealth(nEntityIndex) + " / " + Entities.GetMaxHealth(nEntityIndex);
		
		var hManaLabel = hContextPanel.FindChildTraverse("Stat21").FindChild("Label");
		hManaLabel.text = Entities.GetMana(nEntityIndex) + " / " + Entities.GetMaxMana(nEntityIndex);
		
		var hStaminaLabel = hContextPanel.FindChildTraverse("Stat31").FindChild("Label");
		hStaminaLabel.text = tEntityData.stamina.toFixed(0) + " / " + tEntityData.stamina_max.toFixed(0);
		
		var fDamageBase = 0;
		var fDamageVar = 0;
		var fStrength = GetPropertyValue(tEntityData, Instance.IW_PROPERTY_ATTR_STR_FLAT) * (1.0 + GetPropertyValue(tEntityData, Instance.IW_PROPERTY_ATTR_STR_PCT)/100.0);
		
		var nAttackSources = 0;
		var tEntityAttackSources = tEntityData.attack_source;
		for (var k in tEntityAttackSources)
		{
			//TODO: Implement non-item attack sources (like from abilities)
			var nSourceIndex = tEntityAttackSources[k];
			var tSourceData = tInventoryData.item_list[nSourceIndex];
			for (var i = 0; i < stDamageTypeNames.length; i++)
			{
				var fDamagePercent = 1.0 + GetPropertyValue(tSourceData, Instance.IW_PROPERTY_DMG_PURE_PCT + ((i > 0) ? Math.max(1, i - 2) : i))/100.0;
				
				//Apply physical damage increase from STR to physical damage
				if ((i >= DamageType.IW_DAMAGE_TYPE_CRUSH) && (i <= DamageType.IW_DAMAGE_TYPE_PIERCE))
					fDamagePercent += (fStrength * 0.01);
			
				fDamageBase += GetPropertyValue(tSourceData, Instance.IW_PROPERTY_DMG_PURE_BASE + i) * fDamagePercent;
				fDamageVar += GetPropertyValue(tSourceData, Instance.IW_PROPERTY_DMG_PURE_VAR + i) * fDamagePercent;
			}
			nAttackSources++;
		}
		if (nAttackSources > 0)
		{
			fDamageBase /= nAttackSources;
			fDamageVar /= nAttackSources;
		}
		
		for (var i = 0; i < stDamageTypeNames.length; i++)
		{
			var fDamagePercent = 1.0 + GetPropertyValue(tEntityData, Instance.IW_PROPERTY_DMG_PURE_PCT + ((i > 0) ? Math.max(1, i - 2) : i))/100.0;
			
			//Apply physical damage increase from STR to physical damage
			if ((i >= DamageType.IW_DAMAGE_TYPE_CRUSH) && (i <= DamageType.IW_DAMAGE_TYPE_PIERCE))
				fDamagePercent += (fStrength * 0.01);
			
			fDamageBase += GetPropertyValue(tEntityData, Instance.IW_PROPERTY_DMG_PURE_BASE + i) * fDamagePercent;
			fDamageVar += GetPropertyValue(tEntityData, Instance.IW_PROPERTY_DMG_PURE_VAR + i) * fDamagePercent;
		}
		
		var hAttackLabel = hContextPanel.FindChildTraverse("Stat41").FindChild("Label");
		hAttackLabel.text = Math.floor(fDamageBase) + "-" + Math.floor(fDamageBase + fDamageVar);
		
		var hSpellpowerLabel = hContextPanel.FindChildTraverse("Stat51").FindChild("Label");
		hSpellpowerLabel.text = GetPropertyValue(tEntityData, Instance.IW_PROPERTY_SPELLPOWER);
		
		var szArmorString = Math.floor(GetPropertyValue(tEntityData, Instance.IW_PROPERTY_ARMOR_CRUSH_FLAT) * (1.0 + GetPropertyValue(tEntityData, Instance.IW_PROPERTY_ARMOR_CRUSH_PCT))) + " / " + 
							Math.floor(GetPropertyValue(tEntityData, Instance.IW_PROPERTY_ARMOR_SLASH_FLAT) * (1.0 + GetPropertyValue(tEntityData, Instance.IW_PROPERTY_ARMOR_SLASH_PCT))) + " / " + 
							Math.floor(GetPropertyValue(tEntityData, Instance.IW_PROPERTY_ARMOR_PIERCE_FLAT) * (1.0 + GetPropertyValue(tEntityData, Instance.IW_PROPERTY_ARMOR_PIERCE_PCT))); 
									
		var hArmorLabel = hContextPanel.FindChildTraverse("Stat12").FindChild("Label");
		hArmorLabel.text = szArmorString;
		
		for (var i = 0; i < 4; i++)
		{
			var nResist = Math.floor(GetPropertyValue(tEntityData, Instance.IW_PROPERTY_RESIST_FIRE + i));
			var nMaxResist = Math.floor(GetPropertyValue(tEntityData, Instance.IW_PROPERTY_RESMAX_FIRE + i));
			var hResistLabel = hContextPanel.FindChildTraverse("Stat" + (i + 2) + "2").FindChild("Label");
			hResistLabel.text = ((nResist >= 100) && (nMaxResist >= 100)) ? $.Localize("#iw_ui_character_overview_immune") : (nResist + " / " + nMaxResist);
		}
		return true;
	}
}

function OnInfoboxEntityUpdate(szTableName, szKey, tData)
{
	var nEntityIndex = $.GetContextPanel().GetAttributeInt("entindex", -1);
	if (parseInt(szKey) === nEntityIndex)
	{
		//Slightly delayed so that the game registers changes to hp/mp
		$.Schedule(0.03, DispatchCustomEvent.bind(this, $.GetContextPanel(), "InfoboxUpdate", { entindex:nEntityIndex }));
	}
}

function OnInfoboxLoad()
{
	var hBackground = $.GetContextPanel().FindChildTraverse("InfoboxBackground");
	hBackground.style.width = "256px";
	hBackground.style.height = "210px";
	hBackground.BLoadLayout("file://{resources}/layout/custom_game/ui/iw_widget_stretchbox.xml", false, false);
	
	var hStatContainer = $.GetContextPanel().FindChildTraverse("StatContainer");
	for (var i = 0; i < stCharacterInfoboxIcons.length; i++)
	{
		var hStatRow = $.CreatePanel("Panel", hStatContainer, "StatRow" + (i + 1));
		hStatRow.BLoadLayoutSnippet("CharacterInfoboxStatRowSnippet");
		for (var j = 0; j < stCharacterInfoboxIcons[i].length; j++)
		{
			var hStat = $.CreatePanel("Panel", hStatRow, "Stat" + (i+1) + (j+1));
			hStat.BLoadLayoutSnippet("CharacterInfoboxStatSnippet");
			hStat.FindChildTraverse("Icon").SetImage("file://{images}/custom_game/icons/" + stCharacterInfoboxIcons[i][j] + ".tga");
			hStat.SetAttributeString("text", stCharacterInfoboxText[i][j]);
			hStat.SetPanelEvent("onmouseover", OnInfoboxStatMouseOver.bind(this, hStat));
			hStat.SetPanelEvent("onmouseout", OnInfoboxStatMouseOut.bind(this, hStat));
		}
	}
	RegisterCustomEventHandler($.GetContextPanel(), "InfoboxUpdate", OnInfoboxUpdate);
	CustomNetTables.SubscribeNetTableListener("entities", OnInfoboxEntityUpdate);
}