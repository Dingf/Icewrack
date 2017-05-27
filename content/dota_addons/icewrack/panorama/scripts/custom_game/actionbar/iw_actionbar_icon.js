"use strict";

function OnActionBarIconActivateEvent(hContextPanel, tArgs)
{
	var nEntityIndex = hContextPanel.GetAttributeInt("caster", -1);
	var nAbilityIndex = hContextPanel.GetAttributeInt("abilityindex", -1);
	if ((nEntityIndex !== -1) && (nAbilityIndex !== -1))
	{
		var nSkillMask = hContextPanel.GetAttributeInt("skill_mask", 0);
		if (nSkillMask !== 0)
		{
			var szErrorMessage = $.Localize("#iw_error_insufficient_skill") + " - ";
			var bIsFirstSkill = true;
			for (var i = 0; i < 4; i++)
			{
				var nSkill = (nSkillMask >>> (i << 3)) & 0xFF;
				if ((nSkill !== 0) && (nSkill <= 26))
				{
					if (bIsFirstSkill)
						bIsFirstSkill = false;
					else
						szErrorMessage += ", ";
					
					var szSkillName = $.Localize("#iw_ui_character_skills_" + Math.floor((nSkill - 1)/13) + "_" + (nSkill - 1) % 13);
					szErrorMessage += szSkillName;
				}
			}
			Game.EmitSound("UI.Invalid");
			GameUI.ShowErrorMessage(szErrorMessage, true);
		}
		else
		{
			Abilities.ExecuteAbility(nAbilityIndex, nEntityIndex, false);
		}
	}
	return true;
}

function OnActionBarIconActivate()
{
	DispatchCustomEvent($.GetContextPanel(), "ActionBarIconActivate");
}

function OnActionBarIconDoubleClickEvent(hContextPanel, tArgs)
{
	var nEntityIndex = hContextPanel.GetAttributeInt("caster", -1);
	var nAbilityIndex = hContextPanel.GetAttributeInt("abilityindex", -1);
	if ((nEntityIndex !== -1) && (nAbilityIndex !== -1))
	{
		var nSkillMask = hContextPanel.GetAttributeInt("skill_mask", 0);
		if (nSkillMask !== 0)
		{
			var szErrorMessage = $.Localize("#iw_error_insufficient_skill") + " - ";
			var bIsFirstSkill = true;
			for (var i = 0; i < 4; i++)
			{
				var nSkill = (nSkillMask >>> (i << 3)) & 0xFF;
				if ((nSkill !== 0) && (nSkill <= 26))
				{
					if (bIsFirstSkill)
						bIsFirstSkill = false;
					else
						szErrorMessage += ", ";
					
					var szSkillName = $.Localize("#iw_ui_character_skills_" + Math.floor((nSkill - 1)/13) + "_" + (nSkill - 1) % 13);
					szErrorMessage += szSkillName;
				}
			}
			Game.EmitSound("UI.Invalid");
			GameUI.ShowErrorMessage(szErrorMessage, true);
		}
		else
		{
			if (Abilities.IsToggle(nAbilityIndex))
			{
				Abilities.ExecuteAbility(nAbilityIndex, nEntityIndex, false);
			}
			else if (Abilities.IsAutocast(nAbilityIndex))
			{
				Game.PrepareUnitOrders({ OrderType:dotaunitorder_t.DOTA_UNIT_ORDER_CAST_TOGGLE_AUTO, AbilityIndex:nAbilityIndex });
			}
			else
			{
				Abilities.CreateDoubleTapCastOrder(nAbilityIndex, nEntityIndex);
			}
		}
	}
	return true;
}

function OnActionBarIconDoubleClick()
{
	DispatchCustomEvent($.GetContextPanel(), "ActionBarIconDoubleClick");
}

function OnActionBarIconContextMenu()
{
	var tPartyCombatTable = CustomNetTables.GetTableValue("game", "Combat");
	var nEntityIndex = $.GetContextPanel().GetAttributeInt("caster", -1);
	if (tPartyCombatTable.State === 1)
	{
		Game.EmitSound("UI.Invalid");
		GameUI.ShowErrorMessage("#iw_error_cant_memorize_in_combat");
	}
	else if (!Entities.IsEnemy(nEntityIndex))
	{
		var hTooltip = $.GetContextPanel().GetParent().GetParent().GetParent().FindChild("Tooltip");
		if (hTooltip.BHasClass("ActionBarTooltipFadeIn"))
		{
			hTooltip.RemoveClass("ActionBarTooltipFadeIn");
			hTooltip.AddClass("ActionBarTooltipFadeOut");
			var nAbilityIndex = $.GetContextPanel().GetAttributeInt("abilityindex", -1);
			if ((nEntityIndex !== -1) && (nAbilityIndex !== -1))
			{
				var szTooltipArgs = "abilityindex=" + nAbilityIndex + "&entindex=" + nEntityIndex;
				$.DispatchEvent("UIShowCustomLayoutParametersTooltip", "AbilityTooltip", "file://{resources}/layout/custom_game/tooltip/iw_tooltip_ability.xml", szTooltipArgs);
			}
		}
		else
		{
			$.DispatchEvent("UIHideCustomLayoutTooltip", "AbilityTooltip");
			hTooltip.RemoveClass("ActionBarTooltipFadeOut");
			hTooltip.AddClass("ActionBarTooltipFadeIn");
			hTooltip.SetAttributeInt("slot", $.GetContextPanel().GetAttributeInt("slot", -1));
			
			var nNumIcons = hTooltip.GetAttributeInt("num_icons", 0);
			var nTooltipXOffset = parseInt($.GetContextPanel().style["position"].split("px")[0]) - (140 - Math.min(4 + (nNumIcons * 34), 140));
			var nTooltipYOffset = -68 * Math.ceil(nNumIcons/4);
			hTooltip.style["position"] = (-394 + nTooltipXOffset) + "px " + (984 + nTooltipYOffset) + "px 0px";
		}
	}
}

function OnActionBarIconMouseOverThink()
{
	if ($.GetContextPanel()._bMouseOver)
	{
		var nEntityIndex = $.GetContextPanel().GetAttributeInt("caster", -1);
		var nAbilityIndex = $.GetContextPanel().GetAttributeInt("abilityindex", -1);
		if ((nEntityIndex != -1) && (nAbilityIndex !== -1))
		{
			var szTooltipArgs = "abilityindex=" + nAbilityIndex + "&entindex=" + nEntityIndex;
			$.DispatchEvent("UIShowCustomLayoutParametersTooltip", "AbilityTooltip", "file://{resources}/layout/custom_game/tooltip/iw_tooltip_ability.xml", szTooltipArgs);
		}
		$.Schedule(0.03, OnActionBarIconMouseOverThink);
	}
	else
	{
		$.GetContextPanel()._bTooltipVisible = false;
		$.DispatchEvent("UIHideCustomLayoutTooltip", "AbilityTooltip");
	}
	return 0.03
}

function OnActionBarIconMouseOver()
{
	$.GetContextPanel()._bTooltipVisible = false;
	$.GetContextPanel()._bMouseOver = true;
	OnActionBarIconMouseOverThink();
}

function OnActionBarIconMouseOut()
{
	$.GetContextPanel()._bMouseOver = false;
	var hTooltip = $.GetContextPanel().GetParent().GetParent().GetParent().FindChild("Tooltip");
	if (hTooltip.BHasClass("ActionBarTooltipFadeIn"))
	{
		hTooltip.RemoveClass("ActionBarTooltipFadeIn");
		hTooltip.AddClass("ActionBarTooltipFadeOut");
	}
}
	
function OnActionBarIconDragStart(szPanelID, hDraggedPanel)
{
	var tPartyCombatTable = CustomNetTables.GetTableValue("game", "Combat");
	if (tPartyCombatTable.State === 1)
	{
		Game.EmitSound("UI.Invalid");
		return true;
	}
	
	var nEntityIndex = $.GetContextPanel().GetAttributeInt("caster", -1);
	var nAbilityIndex = $.GetContextPanel().GetAttributeInt("abilityindex", -1);
	var szAbilityName = Abilities.GetAbilityName(nAbilityIndex);
	if ((nEntityIndex === -1) || (nAbilityIndex === -1) || (szAbilityName === ""))
		return true;
	
	if (!GameUI.IsMouseDown(0))
		return true;
	
	var hDisplayPanel = $.CreatePanel("Image", $.GetContextPanel(), "AbilityDrag");
	
	var szAbilityTextureName = Abilities.GetAbilityTextureName(nAbilityIndex);
	hDisplayPanel.SetImage("file://{images}/spellicons/" + szAbilityTextureName + ".png");
	hDisplayPanel.SetAttributeInt("abilityindex", nAbilityIndex);
	hDisplayPanel.SetAttributeInt("entindex", nEntityIndex);
	hDisplayPanel.AddClass("ActionBarDragIcon");
	
	hDisplayPanel._nDragType = 0x04;
	hDisplayPanel._bDragCompleted = false;
	hDisplayPanel._hRefPanel = $.GetContextPanel();
	
	hDraggedPanel.displayPanel = hDisplayPanel;
	hDraggedPanel.offsetX = 0;
	hDraggedPanel.offsetY = 0;
	return true;
}	

function OnActionBarIconDragEnd(szPanelID, hDraggedPanel)
{	
	if (!hDraggedPanel._bDragCompleted)
	{
		var hRefPanel = hDraggedPanel._hRefPanel;
		var nRefSlot = hRefPanel.GetAttributeInt("slot", -1);
		var nEntityIndex = hDraggedPanel.GetAttributeInt("entindex", -1);
		DispatchCustomEvent(hRefPanel, "ActionBarTooltipIconBind", { entindex:nEntityIndex, slot:nRefSlot, ability:0 });
	}
	hDraggedPanel.DeleteAsync(0);
	return true;
}

function OnActionBarIconDragEnter(szPanelID, hDraggedPanel)
{
	var nDragType = hDraggedPanel._nDragType;
	var nCasterIndex = $.GetContextPanel().GetAttributeInt("caster", -2);
	var nEntityIndex = hDraggedPanel.GetAttributeInt("entindex", -1);
	var nAbilityIndex = hDraggedPanel.GetAttributeInt("abilityindex", -1);
	if ((nDragType & 0x0c) && (nAbilityIndex !== -1) && (nEntityIndex === nCasterIndex))
	{
		if (nDragType & 0x04)
		{
			var hRefPanel = hDraggedPanel._hRefPanel;
			if ($.GetContextPanel() === hRefPanel)
			{
				return true;
			}
		}
		var szAbilityTextureName = Abilities.GetAbilityTextureName(nAbilityIndex);
		$("#DragContainer").visible = true;
		$("#DragImage").SetImage("file://{images}/spellicons/" + szAbilityTextureName + ".png");
	}
	return true;
}

function OnActionBarIconDragDrop(szPanelID, hDraggedPanel)
{
	var nDragType = hDraggedPanel._nDragType;
	var nCasterIndex = $.GetContextPanel().GetAttributeInt("caster", -2);
	var nEntityIndex = hDraggedPanel.GetAttributeInt("entindex", -1);
	var nAbilityIndex = hDraggedPanel.GetAttributeInt("abilityindex", -1);
	if ((nDragType & 0x0c) && (nAbilityIndex !== -1) && (nEntityIndex === nCasterIndex))
	{
		var nSlot = $.GetContextPanel().GetAttributeInt("slot", -1);
		DispatchCustomEvent($.GetContextPanel(), "ActionBarTooltipIconBind", { entindex:nEntityIndex, slot:nSlot, ability:nAbilityIndex });
		if (nDragType & 0x04)
		{
			var hRefPanel = hDraggedPanel._hRefPanel;
			if (hRefPanel)
			{
				var nRefSlot = hRefPanel.GetAttributeInt("slot", -1);
				DispatchCustomEvent(hRefPanel, "ActionBarTooltipIconBind", { entindex:nEntityIndex, slot:nRefSlot, ability:0 });
			}
		}
		hDraggedPanel._bDragCompleted = true;
	}
	return true;
}

function OnActionBarIconDragLeave(szPanelID, hDraggedPanel)
{
	$("#DragContainer").visible = false;
	return true;
}

function UpdateActionBarIconCooldown(hContextPanel)
{
	var hLeftFill = hContextPanel.FindChildTraverse("LeftCDFill");
	var hRightFill = hContextPanel.FindChildTraverse("RightCDFill");
	var hLeftContainer = hContextPanel.FindChildTraverse("LeftCDContainer");
	var hRightContainer = hContextPanel.FindChildTraverse("RightCDContainer");
	
	var nAbilityIndex = hContextPanel.GetAttributeInt("abilityindex", -1);
	var nLastAbilityIndex = hContextPanel.GetAttributeInt("last_abilityindex", -1);
	var fCooldownTimeRemaining = Abilities.GetCooldownTimeRemaining(nAbilityIndex);
	if (fCooldownTimeRemaining > 0.0)
	{
		hContextPanel.FindChildTraverse("RefreshOverlay").RemoveClass("RefreshOverlayAnim");
		hContextPanel.FindChildTraverse("CooldownLabel").visible = true;
		hContextPanel.FindChildTraverse("CooldownLabel").text = "" + Math.ceil(fCooldownTimeRemaining);
		hContextPanel.FindChildTraverse("Cooldown").visible = true;
		var fCooldownPercent = fCooldownTimeRemaining/Abilities.GetCooldownLength(nAbilityIndex);
		if (fCooldownPercent >= 0.5)
		{
			hLeftFill.visible = true;
			hLeftContainer.style.transform = "rotateZ(0deg)";
			hLeftFill.RemoveClass("CooldownAnimation");
			hRightFill.visible = true;
			if (!hRightFill.BHasClass("CooldownAnimation") || Game.IsGamePaused() || (nLastAbilityIndex !== nAbilityIndex))
			{
				hRightContainer.style.transform = "rotateZ(" + ((1.0 - fCooldownPercent) * 360.0) + "deg)"
				if (!Game.IsGamePaused())
				{
					hRightFill.AddClass("CooldownAnimation");
					hRightFill.style["animation-duration"] = (Abilities.GetCooldownLength(nAbilityIndex)/2.0) + "s";
				}
				else
				{
					hRightFill.RemoveClass("CooldownAnimation");
				}
			}
		}
		else
		{
			hLeftFill.visible = true;
			hRightContainer.style.transform = "rotateZ(0deg)";
			hRightFill.RemoveClass("CooldownAnimation");
			hRightFill.visible = false;
			if (!hLeftFill.BHasClass("CooldownAnimation") || Game.IsGamePaused() || (nLastAbilityIndex !== nAbilityIndex))
			{
				hLeftContainer.style.transform = "rotateZ(" + ((0.5 - fCooldownPercent) * 360.0) + "deg)";
				if (!Game.IsGamePaused())
				{
					hLeftFill.AddClass("CooldownAnimation");
					hLeftFill.style["animation-duration"] = (Abilities.GetCooldownLength(nAbilityIndex)/2.0) + "s";
				}
				else
				{
					hLeftFill.RemoveClass("CooldownAnimation");
				}
			}
		}
		hContextPanel.SetAttributeInt("last_cooldown", 1);
	}
	else
	{
		if (hContextPanel.GetAttributeInt("last_cooldown", -1) === 1)
		{
			hLeftFill.RemoveClass("CooldownAnimation");
			hRightFill.RemoveClass("CooldownAnimation");
			if (hContextPanel.GetAttributeInt("last_abilityindex", -1) === nAbilityIndex)
			{
				hContextPanel.FindChildTraverse("RefreshOverlay").AddClass("RefreshOverlayAnim");
			}
		}
		hContextPanel.SetAttributeInt("last_cooldown", 0);
		hContextPanel.FindChildTraverse("CooldownLabel").visible = false;
		hContextPanel.FindChildTraverse("Cooldown").visible = false;
	}
}

function OnActionBarIconRefresh(hContextPanel, tArgs)
{
	var nEntityIndex = hContextPanel.GetAttributeInt("caster", -1);
	var nAbilityIndex = hContextPanel.GetAttributeInt("abilityindex", -1);
	
	hContextPanel.FindChildTraverse("ManaIndicator").visible = false;
	hContextPanel.FindChildTraverse("ManaLabel").visible = false;
	hContextPanel.FindChildTraverse("StaminaIndicator").visible = false;
	hContextPanel.FindChildTraverse("StaminaLabel").visible = false;
	
	if ((nAbilityIndex !== -1) && (nEntityIndex !== -1))
	{
		var tEntityData = CustomNetTables.GetTableValue("entities", nEntityIndex);
		var tEntitySpellbook = CustomNetTables.GetTableValue("spellbook", nEntityIndex);
		var tSpellData = tEntitySpellbook.Spells[nAbilityIndex];
				
		var szAbilityTextureName = Abilities.GetAbilityTextureName(nAbilityIndex);
		hContextPanel.FindChildTraverse("AbilityTexture").SetImage("file://{images}/spellicons/" + szAbilityTextureName + ".png");
		
		var bIsSkillRequirementMet = true;
		var nSkillMask = tSpellData ? tSpellData.skill : 0;
		var nMissingMask = 0;
		for (var i = 0; i < 4; i++)
		{
			var nLevel = (nSkillMask >>> (i << 3)) & 0x07;
			var nSkill = ((nSkillMask >>> (i << 3)) & 0xF8) >>> 3;
			if ((nSkill !== 0) && (nSkill <= 26))
			{
				var nEntitySkill = GetPropertyValue(tEntityData, Instance.IW_PROPERTY_SKILL_FIRE + nSkill - 1)
				if (nEntitySkill < nLevel)
				{
					nMissingMask |= (nSkill << (i << 3));
					bIsSkillRequirementMet = false;
				}
			}
		}
		hContextPanel.SetAttributeInt("skill_mask", nMissingMask);
		
		var nCurrentLevel = Abilities.GetLevel(nAbilityIndex);
		var bIsAbilityActivated = Abilities.IsActivated(nAbilityIndex);
		if ((nCurrentLevel > 0) && bIsSkillRequirementMet && bIsAbilityActivated)
		{
			var nManaCost = Abilities.GetManaCost(nAbilityIndex);
			if (nManaCost > 0)
			{
				hContextPanel.FindChildTraverse("ManaIndicator").visible = true;
				hContextPanel.FindChildTraverse("ManaLabel").visible = true;
				hContextPanel.FindChildTraverse("ManaLabel").text = "" + nManaCost;
			}
			
			var nStaminaCost = tSpellData.stamina;
			if (nStaminaCost > 0)
			{
				hContextPanel.FindChildTraverse("StaminaIndicator").visible = true;
				hContextPanel.FindChildTraverse("StaminaLabel").visible = true;
				hContextPanel.FindChildTraverse("StaminaLabel").text = "" + nStaminaCost.toFixed(0);
				hContextPanel.SetAttributeInt("stamina_cost", nStaminaCost);
			}
			
			UpdateActionBarIconCooldown(hContextPanel);
		}
	}
	else
	{
		hContextPanel.FindChildTraverse("ActiveStateOverlay").visible = false;
		hContextPanel.FindChildTraverse("ToggleStateOverlay").visible = false;
		hContextPanel.FindChildTraverse("AutocastStateOverlay").visible = false;
		hContextPanel.FindChildTraverse("CooldownLabel").visible = false;
		hContextPanel.FindChildTraverse("Cooldown").visible = false;
		hContextPanel.FindChildTraverse("AbilityTexture").SetImage("file://{images}/spellicons/default.png");
	}
}

function UpdateActionBarIcon()
{
	var nCasterIndex = $.GetContextPanel().GetAttributeInt("caster", -1);
	var nAbilityIndex = $.GetContextPanel().GetAttributeInt("abilityindex", -1);

	if (nAbilityIndex !== -1)
	{
		var nLevel = Abilities.GetLevel(nAbilityIndex);
		var nCurrentLevel = $.GetContextPanel().GetAttributeInt("current_level", -1);
		if (nLevel !== nCurrentLevel)
		{
			$.GetContextPanel().SetAttributeInt("current_level", nLevel);
			DispatchCustomEvent($.GetContextPanel(), "ActionBarIconRefresh");
		}
		
		var szAbilityName = Abilities.GetAbilityName(nAbilityIndex);
		var tEntityData = CustomNetTables.GetTableValue("entities", nCasterIndex);
		
		var nStaminaCost = $.GetContextPanel().GetAttributeInt("stamina_cost", 0);
		var nStamina = tEntityData ? tEntityData.stamina : 0;

		var bLevelFlag = ((nLevel === 0) || !Abilities.IsActivated(nAbilityIndex));
		var bSkillFlag = (!bLevelFlag && ($.GetContextPanel().GetAttributeInt("skill_mask", 0) !== 0));
		var bManaFlag = (!bLevelFlag && !bSkillFlag && (Entities.GetMana(nCasterIndex) < Abilities.GetManaCost(nAbilityIndex)));
		var bStaminaFlag = (!bLevelFlag && !bSkillFlag && !bManaFlag && (nStamina < nStaminaCost) && (nStaminaCost > 0));
		var bActiveFlag = (nAbilityIndex === Abilities.GetLocalPlayerActiveAbility());
		var bToggleFlag = Abilities.GetToggleState(nAbilityIndex);
		
		$("#AbilityTexture").SetHasClass("NoLevel", bLevelFlag);
		$("#AbilityTexture").SetHasClass("NoSkill", bSkillFlag);
		$("#AbilityTexture").SetHasClass("NoMana", bManaFlag);
		$("#AbilityTexture").SetHasClass("NoStamina", bStaminaFlag);
		$("#AbilityTexture").SetHasClass("IsActive", bActiveFlag || bToggleFlag);
		$("#ActiveStateOverlay").visible = bActiveFlag;
		$("#ToggleStateOverlay").visible = bToggleFlag;
		$("#AutocastStateOverlay").visible = Abilities.GetAutoCastState(nAbilityIndex);
		if (!bLevelFlag)
		{
			UpdateActionBarIconCooldown($.GetContextPanel());
		}
		$.GetContextPanel().SetAttributeInt("last_abilityindex", nAbilityIndex);
	}
	$.Schedule(0.03, UpdateActionBarIcon);
}

function OnActionBarIconUpdate(szTableName, szKey, tData)
{
	var nEntityIndex = $.GetContextPanel().GetAttributeInt("caster", -1);
	if (parseInt(szKey) === nEntityIndex)
	{
		DispatchCustomEvent($.GetContextPanel(), "ActionBarIconRefresh");
	}
}

function OnActionBarIconLoad()
{
	$("#DragContainer").visible = false;
	
	$.RegisterEventHandler("DragStart", $.GetContextPanel(), OnActionBarIconDragStart);
	$.RegisterEventHandler("DragEnd", $.GetContextPanel(), OnActionBarIconDragEnd);
	$.RegisterEventHandler("DragEnter", $.GetContextPanel(), OnActionBarIconDragEnter);
	$.RegisterEventHandler("DragDrop", $.GetContextPanel(), OnActionBarIconDragDrop);
	$.RegisterEventHandler("DragLeave", $.GetContextPanel(), OnActionBarIconDragLeave);
	
	RegisterCustomEventHandler($.GetContextPanel(), "ActionBarIconRefresh", OnActionBarIconRefresh);
	RegisterCustomEventHandler($.GetContextPanel(), "ActionBarIconActivate", OnActionBarIconActivateEvent);
	RegisterCustomEventHandler($.GetContextPanel(), "ActionBarIconDoubleClick", OnActionBarIconDoubleClickEvent);
	
	DispatchCustomEvent($.GetContextPanel(), "ActionBarIconRefresh");
	CustomNetTables.SubscribeNetTableListener("entities", OnActionBarIconUpdate);
	CustomNetTables.SubscribeNetTableListener("spellbook", OnActionBarIconUpdate);
	UpdateActionBarIcon();
};