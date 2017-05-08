"use strict";

function OnTooltipAbilityLoad()
{
	var nEntityIndex = parseInt($.GetContextPanel().GetAttributeString("entindex", ""));
	var nAbilityIndex = parseInt($.GetContextPanel().GetAttributeString("abilityindex", ""));
	var szAbilityName = nAbilityIndex ? Abilities.GetAbilityName(nAbilityIndex) : $.GetContextPanel().GetAttributeString("abilityname", "");
	if (nAbilityIndex || szAbilityName)
	{
		var tAbilityTemplate = CustomNetTables.GetTableValue("abilities", szAbilityName);
		
		var szBehaviorText = "";
		var nAbilityBehavior = nAbilityIndex ? Abilities.GetBehavior(nAbilityIndex) : tAbilityTemplate.behavior;
		if (nAbilityBehavior & DOTA_ABILITY_BEHAVIOR.DOTA_ABILITY_BEHAVIOR_PASSIVE)
			szBehaviorText = $.Localize("iw_ui_ability_passive");
		else if (nAbilityBehavior & DOTA_ABILITY_BEHAVIOR.DOTA_ABILITY_BEHAVIOR_CHANNELED)
			szBehaviorText = $.Localize("iw_ui_ability_channeled");
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
				
				var nCastRange = nAbilityIndex ? Abilities.GetCastRange(nAbilityIndex) : tAbilityTemplate.castrange;
				if (nCastRange > 0)
				{
					szBehaviorText += ", " + (nCastRange/100.0).toFixed(2) + "m";
				}
			}
			else if (nAbilityBehavior & DOTA_ABILITY_BEHAVIOR.DOTA_ABILITY_BEHAVIOR_UNIT_TARGET)
			{
				var nTargetTeam = nAbilityIndex ? Abilities.GetAbilityTargetTeam(nAbilityIndex) : tAbilityTemplate.targetteam;
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
				var nCastRange = nAbilityIndex ? Abilities.GetCastRange(nAbilityIndex) : tAbilityTemplate.castrange;
				if (nCastRange > 0)
				{
					szBehaviorText += ", " + (nCastRange/100.0).toFixed(2) + "m";
				}
			}
			else if (tAbilityTemplate && (tAbilityTemplate.weather === 1))
			{
				szBehaviorText += $.Localize("iw_ui_ability_target_weather");
			}
			else if (nAbilityBehavior & DOTA_ABILITY_BEHAVIOR.DOTA_ABILITY_BEHAVIOR_NO_TARGET)
			{
				szBehaviorText += $.Localize("iw_ui_ability_target_self");
			}
		}
		$("#Behavior").text = szBehaviorText;
		
		var hSkillContainer = $("#SkillContainer");
		hSkillContainer.RemoveAndDeleteChildren();
		
		if (tAbilityTemplate)
		{
			var nSkillMask = tAbilityTemplate.skill;
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
		}
		
		var nManaCost = nAbilityIndex ? Abilities.GetManaCost(nAbilityIndex) : tAbilityTemplate.mana;
		$("#ManaCost").visible = (nManaCost > 0);
		$("#ManaLabel").text = nManaCost.toFixed(0) + "";
		
		var nStaminaCost = tAbilityTemplate ? tAbilityTemplate.stamina : 0;
		var tEntityData = CustomNetTables.GetTableValue("entities", nEntityIndex);
		nStaminaCost *= tEntityData ? tEntityData.fatigue : 1.0;
		$("#StaminaCost").visible = (nStaminaCost > 0);
		$("#StaminaLabel").text = nStaminaCost.toFixed(0) + "";
		
		var nCooldown = nAbilityIndex ? Abilities.GetCooldown(nAbilityIndex) : tAbilityTemplate.cooldown;
		$("#CooldownCost").visible = (nCooldown > 0);
		$("#CooldownLabel").text = Math.round(nCooldown * 100)/100 + "";
		
		$("#Title").text = $.Localize("DOTA_Tooltip_Ability_" + szAbilityName);
		$("#Description").text = $.Localize("DOTA_Tooltip_Ability_" + szAbilityName + "_Description");
		
		var szAbilityTextureName = nAbilityIndex ? Abilities.GetAbilityTextureName(nAbilityIndex) : tAbilityTemplate.texture;
		$("#Icon").SetImage("file://{images}/spellicons/" + szAbilityTextureName + ".png");
	}
}