"use strict";

function OnAbilityEntryActivate()
{
	DispatchCustomEvent($.GetContextPanel(), "AbilityEntrySelect", { panel:$.GetContextPanel() });
}

function OnAbilityEntryContextMenu()
{
	DispatchCustomEvent($.GetContextPanel(), "AbilityEntryDeselect", { panel:$.GetContextPanel() });
}

function OnAbilityEntryMouseOver()
{
	if (!$.GetContextPanel().BHasClass("AbilityEntrySelected"))
	{
		$.GetContextPanel().AddClass("AbilityEntryHover");
	}
}

function OnAbilityEntryMouseOut()
{
	$.GetContextPanel().RemoveClass("AbilityEntryHover");
}

function OnAbilityEntryIconMouseOver()
{
	var nAbilityIndex = $.GetContextPanel().GetAttributeInt("abilityindex", -1);
	var nEntityIndex = $.GetContextPanel().GetAttributeInt("entindex", -1);
	var szAbilityName = $.GetContextPanel().GetAttributeString("name", "");
	var szTooltipArgs = (nAbilityIndex !== -1) ? "abilityindex=" + nAbilityIndex : "abilityname=" + szAbilityName;
	if (nEntityIndex !== -1)
		szTooltipArgs += "&entindex=" + nEntityIndex;
	$.DispatchEvent("UIShowCustomLayoutParametersTooltip", $("#Icon"), "AbilityTooltip", "file://{resources}/layout/custom_game/tooltip/iw_tooltip_ability.xml", szTooltipArgs);
	
}

function OnAbilityEntryIconMouseOut()
{
	$.DispatchEvent("UIHideCustomLayoutTooltip", $("#Icon"), "AbilityTooltip");
}

function OnAbilityEntrySelect(hContextPanel, tArgs)
{
	hContextPanel.AddClass("AbilityEntrySelected");
}

function OnAbilityEntryDeselect(hContextPanel, tArgs)
{
	hContextPanel.RemoveClass("AbilityEntrySelected");
}

function OnAbilityEntryDragStart(szPanelID, hDraggedPanel)
{
	var tPartyCombatTable = CustomNetTables.GetTableValue("game", "Combat");
	if (tPartyCombatTable.State === 1)
	{
		Game.EmitSound("UI.Invalid");
		return true;
	}
	
	var nEntityIndex = $.GetContextPanel().GetAttributeInt("entindex", -1);
	var nAbilityIndex = $.GetContextPanel().GetAttributeInt("abilityindex", -1);
	var szAbilityName = $.GetContextPanel().GetAttributeString("name", "");
	if ((nEntityIndex === -1) || (nAbilityIndex === -1) || (szAbilityName === ""))
		return true;
	
	if (!GameUI.IsMouseDown(0))
		return true;
	
	var hDisplayPanel = $.CreatePanel("Image", $.GetContextPanel(), "AbilityDrag");
	
	var szAbilityTextureName = Abilities.GetAbilityTextureName(nAbilityIndex);
	hDisplayPanel.SetImage("file://{images}/spellicons/" + szAbilityTextureName + ".png");
	hDisplayPanel.SetAttributeInt("abilityindex", nAbilityIndex);
	hDisplayPanel.SetAttributeInt("entindex", nEntityIndex);
	hDisplayPanel.AddClass("AbilityEntryDragIcon");
	
	hDisplayPanel._nDragType = 0x08;
	hDisplayPanel._bDragCompleted = false;
	
	hDraggedPanel.displayPanel = hDisplayPanel;
	hDraggedPanel.offsetX = 0;
	hDraggedPanel.offsetY = 0;
	return true;
}

function OnAbilityEntryDragEnd(szPanelID, hDraggedPanel)
{
	hDraggedPanel.DeleteAsync(0);
	return true;
}

function OnAbilityEntryLoad()
{
	$.RegisterEventHandler("DragStart", $.GetContextPanel(), OnAbilityEntryDragStart);
	$.RegisterEventHandler("DragEnd", $.GetContextPanel(), OnAbilityEntryDragEnd);
}

function CreateAbilityEntry(hParent, szName, nEntityIndex, nAbilityIndex)
{
	var hPanel = $.CreatePanel("Panel", hParent, szName);
	hPanel.BLoadLayout("file://{resources}/layout/custom_game/ability/iw_ability_entry.xml", false, false);
	
	var szAbilityName = Abilities.GetAbilityName(nAbilityIndex);
	var szAbilityTextureName = Abilities.GetAbilityTextureName(nAbilityIndex);
	hPanel.FindChild("Icon").SetImage("file://{images}/spellicons/" + szAbilityTextureName + ".png");
	hPanel.FindChild("Label").text = $.Localize("DOTA_Tooltip_Ability_" + szAbilityName);
	
	hPanel.SetAttributeString("name", szAbilityName);
	hPanel.SetAttributeInt("is_combo", 0);
	hPanel.SetAttributeInt("entindex", nEntityIndex);
	hPanel.SetAttributeInt("abilityindex", nAbilityIndex);
	
	var nAbilitySkillMask = 0;
	var tAbilityTemplate = CustomNetTables.GetTableValue("abilities", szAbilityName);
	if (tAbilityTemplate)
	{
		var nSkillMask = tAbilityTemplate.skill;
		var tAbilitySkillValues = [];
		for (var i = 0; i < 4; i++)
		{
			var nLevel = (nSkillMask >>> (i * 8)) & 0x07;
			var nSkill = ((nSkillMask >>> (i * 8)) & 0xF8) >> 3;
			if (nSkill !== 0)
			{
				for (var j = 0; j < nLevel; j++)
				{
					tAbilitySkillValues.push(nSkill-1);
				}
				nAbilitySkillMask = nAbilitySkillMask | (1 << (nSkill - 1));
			}
		}
		
		var hSkillsContainer1 = hPanel.FindChildTraverse("SkillsContainer1");
		for (var i = 0; i < tAbilitySkillValues.length && i < 9; i++)
		{
			var hIcon = $.CreatePanel("Image", hSkillsContainer1, "Skill" + i);
			hIcon.SetImage("file://{images}/custom_game/icons/skills/iw_skill_icon_" + tAbilitySkillValues[i] + ".tga");
			hIcon.AddClass("AbilityEntrySkillIcon");
		}
		var hSkillsContainer2 = hPanel.FindChildTraverse("SkillsContainer2");
		for (var i = 9; i < tAbilitySkillValues.length && i < 18; i++)
		{
			var hIcon = $.CreatePanel("Image", hSkillsContainer2, "Skill" + i);
			hIcon.SetImage("file://{images}/custom_game/icons/skills/iw_skill_icon_" + tAbilitySkillValues[i] + ".tga");
			hIcon.AddClass("AbilityEntrySkillIcon");
		}
	}
	hPanel.SetAttributeInt("skillmask", nAbilitySkillMask);
	
	RegisterCustomEventHandler(hPanel, "AbilityEntrySelect", OnAbilityEntrySelect);
	RegisterCustomEventHandler(hPanel, "AbilityEntryDeselect", OnAbilityEntryDeselect);
			
	return hPanel;
}

function CreateAbilityComboEntry(hParent, szName, szAbilityName)
{
	var hPanel = $.CreatePanel("Panel", hParent, szName);
	hPanel.BLoadLayout("file://{resources}/layout/custom_game/ability/iw_ability_entry.xml", false, false);
	
	hPanel.FindChild("Icon").SetImage("file://{images}/spellicons/" + szAbilityName + ".png");
	hPanel.FindChild("Label").text = $.Localize("DOTA_Tooltip_Ability_" + szAbilityName);
	hPanel.SetAttributeInt("is_combo", 1);
	hPanel.SetAttributeString("name", szAbilityName);
	
	hPanel._tComboTemplate = [];
	var tComboTemplate = CustomNetTables.GetTableValue("spellbook", "combos")[szAbilityName];
	if (tComboTemplate)
	{
		for (var k in tComboTemplate)
		{
			var tComboGroup = [];
			for (var k2 in tComboTemplate[k])
			{
				tComboGroup.push(tComboTemplate[k][k2]);
			}
			hPanel._tComboTemplate.push(tComboGroup);
		}
	}
	
	RegisterCustomEventHandler(hPanel, "AbilityEntrySelect", OnAbilityEntrySelect);
	RegisterCustomEventHandler(hPanel, "AbilityEntryDeselect", OnAbilityEntryDeselect);
	
	return hPanel;
}