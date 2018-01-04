"use strict";

function OnTooltipAbilityLoad()
{
	var nAbilityIndex = parseInt($.GetContextPanel().GetAttributeString("abilityindex", ""));
	var tAbilityData = CustomNetTables.GetTableValue("abilities", nAbilityIndex);
	if (tAbilityData)
	{
		var bNoSpecialFlag = ($.GetContextPanel().GetAttributeString("nospecial", "") === "1");
		var nEntityIndex = parseInt($.GetContextPanel().GetAttributeString("entindex", ""));
		var tEntityData = CustomNetTables.GetTableValue("entities", nEntityIndex);
		
		var szAbilityName = Abilities.GetAbilityName(nAbilityIndex);
		var nAbilityBehavior = Abilities.GetBehavior(nAbilityIndex);
		var nAbilityExtFlags = tAbilityData.extflags;
		
		var szBehaviorText = "";
		if (nAbilityBehavior & DOTA_ABILITY_BEHAVIOR.DOTA_ABILITY_BEHAVIOR_PASSIVE)
			szBehaviorText = $.Localize("iw_ui_ability_passive");
		else if (nAbilityBehavior & DOTA_ABILITY_BEHAVIOR.DOTA_ABILITY_BEHAVIOR_CHANNELLED)
		{
			szBehaviorText = $.Localize("iw_ui_ability_channeled");
			szBehaviorText += ", ";
			szBehaviorText += Abilities.GetChannelTime(nAbilityIndex).toFixed(1);
			szBehaviorText += "s";
		}
		else if (nAbilityBehavior & DOTA_ABILITY_BEHAVIOR.DOTA_ABILITY_BEHAVIOR_TOGGLE)
			szBehaviorText = $.Localize("iw_ui_ability_toggled");
		else if (nAbilityBehavior & DOTA_ABILITY_BEHAVIOR.DOTA_ABILITY_BEHAVIOR_AUTOCAST)
			szBehaviorText = $.Localize("iw_ui_ability_autocast");
		else
			szBehaviorText = $.Localize("iw_ui_ability_target");
		
		//Not passive or toggled
		if (!(nAbilityBehavior & 0x0202))
		{
			szBehaviorText += " - ";
			if (nAbilityBehavior & DOTA_ABILITY_BEHAVIOR.DOTA_ABILITY_BEHAVIOR_POINT)
			{
				szBehaviorText += $.Localize("iw_ui_ability_target_ground");
				
				var nCastRange = Abilities.GetCastRange(nAbilityIndex);
				if (nAbilityExtFlags & IW_ABILITY_FLAG_USES_ATTACK_RANGE)
				{
					szBehaviorText += ", " + $.Localize("iw_ui_ability_target_attack_range");
				}
				else if (nCastRange > 0)
				{
					szBehaviorText += ", " + (nCastRange/100.0).toFixed(2) + "m";
				}
			}
			else if (nAbilityBehavior & DOTA_ABILITY_BEHAVIOR.DOTA_ABILITY_BEHAVIOR_UNIT_TARGET)
			{
				var nTargetTeam = Abilities.GetAbilityTargetTeam(nAbilityIndex);
				switch (nTargetTeam)
				{
					case DOTA_UNIT_TARGET_TEAM.DOTA_UNIT_TARGET_TEAM_FRIENDLY:
						szBehaviorText += $.Localize("iw_ui_ability_target_ally");
						break;
					case DOTA_UNIT_TARGET_TEAM.DOTA_UNIT_TARGET_TEAM_ENEMY:
						szBehaviorText += $.Localize("iw_ui_ability_target_enemy");
						break;
					default:
						szBehaviorText += $.Localize("iw_ui_ability_target_unit");
						break;
				}
				var nCastRange = Abilities.GetCastRange(nAbilityIndex);
				if (nAbilityExtFlags & IW_ABILITY_FLAG_USES_ATTACK_RANGE)
				{
					szBehaviorText += ", " + $.Localize("iw_ui_ability_target_attack_range");
				}
				else if (nCastRange > 0)
				{
					szBehaviorText += ", " + (nCastRange/100.0).toFixed(2) + "m";
				}
			}
			else if (nAbilityExtFlags & IW_ABILITY_FLAG_KEYWORD_WEATHER)
			{
				szBehaviorText += $.Localize("iw_ui_ability_target_weather");
			}
			else if (nAbilityBehavior & DOTA_ABILITY_BEHAVIOR.DOTA_ABILITY_BEHAVIOR_NO_TARGET)
			{
				szBehaviorText += $.Localize("iw_ui_ability_target_self");
			}
		}
		else
		{
			if (nAbilityExtFlags & IW_ABILITY_FLAG_KEYWORD_ATTACK)
			{
				szBehaviorText += " - ";
				szBehaviorText += $.Localize("iw_ui_ability_target_attack");
			}
		}
		$("#Behavior").text = szBehaviorText;
			
		var nSkillMask = tAbilityData.skill;
		var hSkillContainer = $("#SkillContainer");
		hSkillContainer.RemoveAndDeleteChildren();
		for (var i = 0; i < 4; i++)
		{
			var nLevel = (nSkillMask >>> (i * 8)) & 0x07;
			var nSkill = ((nSkillMask >>> (i * 8)) & 0xF8) >> 3;
			if (nSkill !== 0)
			{
				for (var j = 0; j < nLevel; j++)
				{
					var hSkillIcon = $.CreatePanel("Image", hSkillContainer, "SkillIcon" + i + "_" + j);
					hSkillIcon.SetImage("file://{images}/custom_game/icons/skills/iw_skill_icon_" + (nSkill - 1) + ".tga");
					hSkillIcon.AddClass("TooltipAbilitySkillIcon");
				}
			}
		}
		
		$("#ManaCost").visible = false;
		$("#StaminaCost").visible = false;
		$("#CooldownCost").visible = false;
		
		var fStaminaCost = tAbilityData.stamina;
		var fStaminaUpkeep = tAbilityData.stamina_upkeep;
		var fManaCost = tAbilityData.mana;
		var fManaUpkeep = tAbilityData.mana_upkeep;
		
		$("#ManaCost").visible = (fManaCost > 0) || (fManaUpkeep > 0);
		$("#ManaLabel").text = "";
		if (fManaCost > 0)
		{
			$("#ManaLabel").text += fManaCost.toFixed(0) + ((fManaUpkeep > 0) ? " + " : "");
		}
		if (fManaUpkeep > 0)
		{
			$("#ManaLabel").text += Math.floor(fManaUpkeep * 100)/100 + "/s";
		}
		
		$("#StaminaCost").visible = (fStaminaCost > 0) || (fStaminaUpkeep > 0);
		$("#StaminaLabel").text = "";
		if (fStaminaCost > 0)
		{
			$("#StaminaLabel").text += fStaminaCost.toFixed(0) + ((fStaminaUpkeep > 0) ? " + " : "");
		}
		if (fStaminaUpkeep > 0)
		{
			$("#StaminaLabel").text += Math.floor(fStaminaUpkeep * 100)/100 + "/s";
		}
		
		var nCooldown = Abilities.GetCooldown(nAbilityIndex);
		$("#CooldownCost").visible = (nCooldown > 0);
		$("#CooldownLabel").text = Math.round(nCooldown * 100)/100 + "";
		
		var fSpellpower = 0;
		if (tEntityData)
		{
			fSpellpower = GetPropertyValue(tEntityData, Instance.IW_PROPERTY_SPELLPOWER) + (GetAttributeValue(tEntityData, Instance.IW_PROPERTY_ATTR_INT_FLAT) * 1.0);
		}
			
		var szLocalizedText = $.Localize("DOTA_Tooltip_Ability_" + szAbilityName + "_Description");
		var tSpecialSections = szLocalizedText.match(/[^{}]+(?=})/g);
		var tTextSections = szLocalizedText.replace(/\{[^}]+\}/g, "|").split("|");
		
		var szFormattedText = "";
		for (var i = 0; i < tTextSections.length; i++)
		{
			szFormattedText += tTextSections[i];
			if (tSpecialSections && tSpecialSections[i])
			{
				var tAbilitySpecials = tSpecialSections[i].split("|");
				var tAbilityBaseValues = tAbilitySpecials[0].split("*", 2);

				var fSpecialBaseValue = Abilities.GetSpecialValueFor(nAbilityIndex, tAbilityBaseValues[0]);
				var fSpecialBonusValue = 0;
				if (tAbilityBaseValues[0] === "r")
				{
					fSpecialBaseValue = (Abilities.GetAOERadius(nAbilityIndex)/100.0).toFixed(2);
				}
				else if (tAbilityBaseValues.length > 1)
				{
					var fSpecialBaseMultiplier = parseFloat(tAbilityBaseValues[1]);
					if (fSpecialBaseMultiplier)
					{
						fSpecialBaseValue *= fSpecialBaseMultiplier;
					}
				}
				var fSpecialTotal = fSpecialBaseValue;
				if (typeof(fSpecialTotal) === "number")
				{
					if (tAbilitySpecials.length > 1)
					{
						var tAbilitySpecialValues = tAbilitySpecials[1].split("*", 2);
						var fSpecialBonus = Abilities.GetSpecialValueFor(nAbilityIndex, tAbilitySpecialValues[0]);
						if (typeof(fSpecialBonus) === "number")
						{
							fSpecialBonusValue = Math.round(fSpecialBonus * 100)/100;
						}
						if (tAbilitySpecialValues.length > 1)
						{
							var fSpecialBonusMultiplier = parseFloat(tAbilitySpecialValues[1]);
							if (fSpecialBonusMultiplier)
							{
								fSpecialBonusValue *= fSpecialBonusMultiplier;
							}
						}
					}
					fSpecialTotal += fSpecialBonusValue * fSpellpower;
					fSpecialTotal = Math.round(fSpecialTotal * 100)/100;
				}
				
				szFormattedText += "<font color=\"#ffffff\">";
				if ((GameUI.IsAltDown() || bNoSpecialFlag) && (fSpecialBonusValue !== 0))
				{
					szFormattedText = szFormattedText + "(" + fSpecialBaseValue + (fSpecialBonusValue > 0 ? " + " : " - ") + Math.abs(fSpecialBonusValue) + "x)";
				}
				else
				{
					szFormattedText += fSpecialTotal;
				}
				szFormattedText += "</font>";
			}
		}
		$("#Description").text = szFormattedText;
		var szAbilityTextureName = Abilities.GetAbilityTextureName(nAbilityIndex);
		$("#Icon").SetImage("file://{images}/spellicons/" + szAbilityTextureName + ".png");
		
		$("#Title").text = $.Localize("DOTA_Tooltip_Ability_" + szAbilityName);
		$("#NotesContainer").visible = GameUI.IsAltDown();
		if (GameUI.IsAltDown())
		{
			var hNotesContainer = $("#NotesContainer");
			hNotesContainer.RemoveAndDeleteChildren();
			for (var i = 0;; i++)
			{
				var szNoteName = "DOTA_Tooltip_Ability_" + szAbilityName + "_Note" + i;
				var szLocalizedNoteText = $.Localize(szNoteName);
				if (szLocalizedNoteText !== szNoteName)
				{
					var hNoteLabel = $.CreatePanel("Label", hNotesContainer, "Note" + i);
					hNoteLabel.AddClass("TooltipAbilityNoteLabel");
					hNoteLabel.text = "• " + szLocalizedNoteText;
				}
				else
				{
					break;
				}
			}
		}
	}
}