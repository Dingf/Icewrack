"use strict";

var stOverviewSections =
[
	"offense", "defense", "misc"
];

var stOverviewDefenseDividers = [4, 9];
var stOverviewMiscDividers = [6, 9];

function OnOverviewStatMouseOverThink(hContextPanel)
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

function OnOverviewStatMouseOver(hContextPanel)
{
	hContextPanel._bTooltipVisible = false;
	hContextPanel._bMouseOver = true;
	if (!hContextPanel._hThinkerFunction)
	{
		hContextPanel._hThinkerFunction = OnOverviewStatMouseOverThink.bind(this, hContextPanel);
	}
	hContextPanel._hThinkerFunction();
}

function OnOverviewStatMouseOut(hContextPanel)
{
	hContextPanel._bMouseOver = false;
}

function OnOverviewUpdate(hContextPanel, tArgs)
{
	var nEntityIndex = hContextPanel.GetAttributeInt("entindex", -1);
	if (nEntityIndex !== -1)
	{
		var tEntityData = CustomNetTables.GetTableValue("entities", nEntityIndex);
		var tInventoryData = CustomNetTables.GetTableValue("inventory", nEntityIndex);
		
		var nEntityAttackSourceCount = 0;
		var tEntityAttackSources = [];
		if (Object.keys(tEntityData.attack_source).length === 0)
		{
			tEntityAttackSources.push({ name:"internal_unarmed", data:tEntityData });
			nEntityAttackSourceCount++;
		}
		else
		{
			for (var k in tEntityData.attack_source)
			{
				var nSourceIndex = tEntityData.attack_source[k];
				var tSourceData = tInventoryData.item_list[nSourceIndex];
				if (tSourceData)
				{
					tEntityAttackSources.push({ name:Abilities.GetAbilityName(nSourceIndex), data:tSourceData });
					nEntityAttackSourceCount++;
				}
			}
		}
		
		hContextPanel.FindChildTraverse("AttackSource1").visible = (nEntityAttackSourceCount !== 1);
		hContextPanel.FindChildTraverse("AttackSourceSpacer").visible = (nEntityAttackSourceCount !== 1);
		
		var fStrength = GetAttributeValue(tEntityData, Instance.IW_PROPERTY_ATTR_STR_FLAT);
		for (var k in tEntityAttackSources)
		{
			var hPanel = hContextPanel.FindChildTraverse("AttackSource" + k);
			if (hPanel)
			{
				var szSourceName = tEntityAttackSources[k].name;
				var tSourceData = tEntityAttackSources[k].data;
				
				hPanel.FindChildTraverse("Content").visible = true;
				hPanel.FindChildTraverse("Title1").text = $.Localize("DOTA_Tooltip_Ability_" + szSourceName);
				hPanel.FindChildTraverse("Image").SetImage("file://{images}/items/" + szSourceName + ".tga");
				for (var i = 0; i < stDamageTypeNames.length; i++)
				{
					var hDamagePanel = hPanel.FindChildTraverse("Damage" + (i + 1));
					if (hDamagePanel)
					{
						var fDamagePercent = 1.0 + GetPropertyValue(tSourceData, Instance.IW_PROPERTY_DMG_PURE_PCT + ((i > 0) ? Math.max(1, i - 2) : i))/100.0;
							
						//Apply physical damage increase from STR to physical damage
						if ((i >= DamageType.IW_DAMAGE_TYPE_CRUSH) && (i <= DamageType.IW_DAMAGE_TYPE_PIERCE))
							fDamagePercent += (fStrength * 0.01);
						
						var fDamageBase = GetPropertyValue(tSourceData, Instance.IW_PROPERTY_DMG_PURE_BASE + i) * fDamagePercent;
						var fDamageVar = GetPropertyValue(tSourceData, Instance.IW_PROPERTY_DMG_PURE_VAR + i) * fDamagePercent;
						
						hDamagePanel.FindChild("Label").text = Math.floor(fDamageBase) + "-" + Math.floor(fDamageBase + fDamageVar);
						hDamagePanel.visible = ((fDamageBase != 0) || (fDamageVar != 0));
					}
				}
				
				var szAttackSpeedText = $.Localize("#iw_ui_character_overview_attack_speed");
				hPanel.FindChildTraverse("AttackSpeedLabel").text = szAttackSpeedText.replace(/\{[^}]\}/g, GetOverviewAttackSpeed(tSourceData, nEntityIndex));
				
				var i = 1;
				for (var k2 in stOverviewAttackSourceLabelFunctions)
				{
					var hStatLabel = hPanel.FindChildTraverse("StatLabel" + i);
					var szResult = stOverviewAttackSourceLabelFunctions[k2](tSourceData, nEntityIndex);
					if (typeof(szResult) !== "undefined")
					{
						hStatLabel.visible = true;
						hStatLabel.FindChild("Value").text = szResult;
					}
					else
					{
						hStatLabel.visible = false;
					}
					i++;
				}
			}
		}
		
		var i = 1;
		var hDefenseSection = hContextPanel.FindChildTraverse("Section2");
		for (var k in stOverviewDefenseLabelFunctions)
		{
			var hStatLabel = hDefenseSection.FindChildTraverse("StatLabel" + i);
			var szResult = stOverviewDefenseLabelFunctions[k](tEntityData, nEntityIndex);
			if (typeof(szResult) !== "undefined")
			{
				hStatLabel.visible = true;
				hStatLabel.FindChild("Value").text = szResult;
			}
			else
			{
				hStatLabel.visible = false;
			}
			i++;
		}
		
		i = 1;
		var hMiscSection = hContextPanel.FindChildTraverse("Section3");
		for (var k in stOverviewMiscLabelFunctions)
		{
			var hStatLabel = hMiscSection.FindChildTraverse("StatLabel" + i);
			var szResult = stOverviewMiscLabelFunctions[k](tEntityData, nEntityIndex);
			if (typeof(szResult) !== "undefined")
			{
				hStatLabel.visible = true;
				hStatLabel.FindChild("Value").text = szResult;
			}
			else
			{
				hStatLabel.visible = false;
			}
			i++;
		}
	}
	return true;
}

function OnOverviewEntityUpdate(szTableName, szKey, tData)
{
	var nEntityIndex = $.GetContextPanel().GetAttributeInt("entindex", -1);
	if (parseInt(szKey) === nEntityIndex)
	{
		DispatchCustomEvent($.GetContextPanel(), "OverviewUpdate");
	}
}

function OnOverviewPartyUpdate(hContextPanel, tArgs)
{
	hContextPanel.SetAttributeInt("entindex", tArgs.entindex);
	DispatchCustomEvent(hContextPanel, "OverviewUpdate");
	return true;
}

function OnOverviewFocus(hContextPanel, tArgs)
{
	var nEntityIndex = tArgs.entindex;
	hContextPanel.visible = true;
	hContextPanel.SetAttributeInt("entindex", nEntityIndex);
	DispatchCustomEvent(hContextPanel, "OverviewUpdate");
	return true;
}

function OnOverviewHide(hContextPanel, tArgs)
{
	hContextPanel.visible = false;
	return true;
}

function CreateAttackSource(hParent, szName, szTitle)
{
	var hPanel = $.CreatePanel("Panel", hParent, szName);
	hPanel.BLoadLayoutSnippet("OvervieAttackSourceSnippet");
	
	hPanel.FindChildTraverse("Title2").text = $.Localize(szTitle);
	
	var hLeftDamageGroup = hPanel.FindChildTraverse("LeftDamageGroup");
	for (var i = 0; i < stDamageTypeNames.length; i++)
	{
		var hDamage = $.CreatePanel("Panel", hLeftDamageGroup, "Damage" + (i + 1));
		hDamage.BLoadLayoutSnippet("OverviewAttackSouceDamageSnippet");
		
		var hDamageIcon = hDamage.FindChild("Icon");
		hDamageIcon.SetImage("file://{images}/custom_game/icons/iw_icon_dmg_" + stDamageTypeNames[i] + ".tga");
		hDamageIcon.SetAttributeString("text", "iw_damage_type_" + stDamageTypeNames[i]);
		hDamageIcon.SetPanelEvent("onmouseover", OnOverviewStatMouseOver.bind(this, hDamageIcon));
		hDamageIcon.SetPanelEvent("onmouseout", OnOverviewStatMouseOut.bind(this, hDamageIcon));
	}
	
	var hRightDamageGroup = hPanel.FindChildTraverse("RightDamageGroup");
	var hAttackSpeedLabel = $.CreatePanel("Label", hRightDamageGroup, "AttackSpeedLabel");
	hAttackSpeedLabel.AddClass("OverviewAttackSourceLabel");
	
	var i = 1;
	var hLabelContainer = hPanel.FindChildTraverse("LabelContainer");
	for (var k in stOverviewAttackSourceLabelFunctions)	
	{
		var hStatLabel = $.CreatePanel("Panel", hLabelContainer, "StatLabel" + i);
		hStatLabel.BLoadLayoutSnippet("OverviewSmallLabelSnippet");
		hStatLabel.FindChild("Title").text = $.Localize(k);
		hStatLabel.SetAttributeString("text", k);
		hStatLabel.SetPanelEvent("onmouseover", OnOverviewStatMouseOver.bind(this, hStatLabel));
		hStatLabel.SetPanelEvent("onmouseout", OnOverviewStatMouseOut.bind(this, hStatLabel));
		i++;
	}
	
	return hPanel;
}

function LoadOverviewOffense()
{
	var hContent = $("#Section1").FindChild("Content");
	
	var hAttackSourceContainer = $.CreatePanel("Panel", hContent, "AttackSourceContainer");
	hAttackSourceContainer.AddClass("OverviewAttackSourceContainer");
	
	CreateAttackSource(hAttackSourceContainer, "AttackSource0", "#iw_ui_character_overview_main_hand");
	
	var hSpacer = $.CreatePanel("Panel", hAttackSourceContainer, "AttackSourceSpacer");
	hSpacer.AddClass("OverviewAttackSourceSpacer");
	
	CreateAttackSource(hAttackSourceContainer, "AttackSource1", "#iw_ui_character_overview_off_hand");
}

function LoadOverviewDefense()
{
	var hContent = $("#Section2").FindChild("Content");
	
	var i = 1;
	for (var k in stOverviewDefenseLabelFunctions)	
	{
		var hStatLabel = $.CreatePanel("Panel", hContent, "StatLabel" + i);
		hStatLabel.BLoadLayoutSnippet("OverviewLabelSnippet");
		hStatLabel.FindChild("Title").text = $.Localize(k);
		hStatLabel.SetAttributeString("text", k);
		hStatLabel.SetPanelEvent("onmouseover", OnOverviewStatMouseOver.bind(this, hStatLabel));
		hStatLabel.SetPanelEvent("onmouseout", OnOverviewStatMouseOut.bind(this, hStatLabel));
		if (i === stOverviewDefenseDividers[0])
		{
			var hDivider = $.CreatePanel("Panel", hContent, "Divider" + i);
			hDivider.AddClass("OverviewSectionSubdivider");
			stOverviewDefenseDividers.shift();
		}
		i++;
	}
}

function LoadOverviewMisc()
{
	var hContent = $("#Section3").FindChild("Content");
	
	var i = 1;
	for (var k in stOverviewMiscLabelFunctions)	
	{
		var hStatLabel = $.CreatePanel("Panel", hContent, "StatLabel" + i);
		hStatLabel.BLoadLayoutSnippet("OverviewLabelSnippet");
		hStatLabel.FindChild("Title").text = $.Localize(k);
		hStatLabel.SetAttributeString("text", k);
		hStatLabel.SetPanelEvent("onmouseover", OnOverviewStatMouseOver.bind(this, hStatLabel));
		hStatLabel.SetPanelEvent("onmouseout", OnOverviewStatMouseOut.bind(this, hStatLabel));
		if (i === stOverviewMiscDividers[0])
		{
			var hDivider = $.CreatePanel("Panel", hContent, "Divider" + i);
			hDivider.AddClass("OverviewSectionSubdivider");
			stOverviewMiscDividers.shift();
		}
		i++;
	}
}

function OnOverviewLoad()
{
	var hContainer = $("#OverviewContainer");
	
	for (var i = 0; i < stOverviewSections.length; i++)
	{
		var hSection = $.CreatePanel("Panel", hContainer, "Section" + (i + 1));
		hSection.BLoadLayoutSnippet("OverviewSectionSnippet");
		hSection.FindChildTraverse("Title").text = $.Localize("iw_ui_character_overview_" + stOverviewSections[i])
	}
	
	LoadOverviewOffense();
	LoadOverviewDefense();
	LoadOverviewMisc();
	
	CreateVerticalScrollbar($.GetContextPanel(), "OverviewScrollbar", hContainer);
	
	RegisterCustomEventHandler($.GetContextPanel(), "OverviewUpdate", OnOverviewUpdate);
	RegisterCustomEventHandler($.GetContextPanel(), "WindowPartyUpdate", OnOverviewPartyUpdate);
	RegisterCustomEventHandler($.GetContextPanel(), "CharacterContentFocus", OnOverviewFocus);
	RegisterCustomEventHandler($.GetContextPanel(), "CharacterContentHide", OnOverviewHide);
	
	CustomNetTables.SubscribeNetTableListener("entities", OnOverviewEntityUpdate);
}