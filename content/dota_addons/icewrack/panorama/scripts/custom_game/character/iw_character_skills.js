"use strict";

var MAX_SKILL_ENTRIES = 12;
var MAX_SKILL_LEVEL = 5;

function ConfirmSkillSelection(hContextPanel)
{
	if (hContextPanel._nAllocatedCount > 0)
	{
		var nEntityIndex = hContextPanel.GetAttributeInt("entindex", -1);
		var tSkillsData = { entindex:nEntityIndex };
		var szSkillsString = "";
		hContextPanel._nAllocatedCount = 0;
		for (var i = 0; i < hContextPanel._tAllocatedPoints.length; i++)
		{
			szSkillsString += hContextPanel._tAllocatedPoints[i];
			hContextPanel._tAllocatedPoints[i] = 0;
		}
		tSkillsData.value = szSkillsString;
		GameEvents.SendCustomGameEventToServer("iw_character_skills_confirm", tSkillsData);
	}
}

function OnSkillEntryMouseOverThink(hContextPanel)
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
	return 0.03;
}

function OnSkillEntryMouseOver(hContextPanel)
{
	hContextPanel._bTooltipVisible = false;
	hContextPanel._bMouseOver = true;
	if (!hContextPanel._hThinkerFunction)
	{
		hContextPanel._hThinkerFunction = OnSkillEntryMouseOverThink.bind(this, hContextPanel);
	}
	hContextPanel._hThinkerFunction();
}

function OnSkillEntryMouseOut(hContextPanel)
{
	hContextPanel._bMouseOver = false;
}

function OnSkillsAddButtonActivate(hContextPanel)
{
	var nID = hContextPanel.GetAttributeInt("id", -1);
	var nLevel = hContextPanel.GetAttributeInt("value", -1);
	if (($.GetContextPanel().GetAttributeInt("skill_points", 0) >= (nLevel + 1)) && (nLevel < MAX_SKILL_LEVEL))
	{
		$.GetContextPanel()._tAllocatedPoints[nID]++;
		$.GetContextPanel()._nAllocatedCount += (nLevel + 1);
	}
	DispatchCustomEvent($.GetContextPanel(), "SkillsUpdate");
}

function OnSkillsAddButtonContextMenu(hContextPanel)
{
	var nID = hContextPanel.GetAttributeInt("id", -1);
	var nLevel = hContextPanel.GetAttributeInt("value", -1);
	if ($.GetContextPanel()._tAllocatedPoints[nID] > 0)
	{
		$.GetContextPanel()._tAllocatedPoints[nID]--;
		$.GetContextPanel()._nAllocatedCount -= nLevel;
	}
	DispatchCustomEvent($.GetContextPanel(), "SkillsUpdate");
}

function OnSkillsUpdate(hContextPanel, tArgs)
{
	var nEntityIndex = hContextPanel.GetAttributeInt("entindex", -1);
	if (nEntityIndex !== -1)
	{
		var tEntityData = CustomNetTables.GetTableValue("entities", nEntityIndex);
		var nSkillPoints = GetBasePropertyValue(tEntityData, Instance.IW_PROPERTY_SKILL_POINTS) - hContextPanel._nAllocatedCount;
		hContextPanel.SetAttributeInt("skill_points", nSkillPoints);
		DispatchCustomEvent(hContextPanel.GetParent(), "CharacterSkillPointsUpdate", { value:nSkillPoints });
		
		if (hContextPanel.visible)
		{
			for (var i = 0; i < MAX_SKILL_ENTRIES * 2; i++)
			{
				var hSkillEntry = hContextPanel.FindChildTraverse("SkillEntry" + (i + 1));
				
				var nSkillBaseValue = GetBasePropertyValue(tEntityData, Instance.IW_PROPERTY_SKILL_FIRE + i) + hContextPanel._tAllocatedPoints[i];
				var nSkillBonusValue = GetBonusPropertyValue(tEntityData, Instance.IW_PROPERTY_SKILL_FIRE + i);
				var nSkillCost = nSkillBaseValue + 1;
				var bHasAllocatedPoints = (hContextPanel._tAllocatedPoints[i] > 0);
				
				var hLevelLabel = hSkillEntry.FindChildTraverse("Level");
				if (nSkillBaseValue > 0)
					hLevelLabel.text = nSkillBaseValue;
				else
					hLevelLabel.text = "-";
				hLevelLabel.SetHasClass("SkillEntryBonusLabel", bHasAllocatedPoints);
				
				hSkillEntry.FindChildTraverse("Bonus").text = (nSkillBonusValue > 0) ? ("+" + nSkillBonusValue) : "";
				
				var hCostLabel = hSkillEntry.FindChild("Cost");
				hCostLabel.SetHasClass("SkillEntryCostLabelAllocated", bHasAllocatedPoints);
				if (nSkillBaseValue < MAX_SKILL_LEVEL)
					hCostLabel.text = nSkillCost;
				else
					hCostLabel.text = "-";
				
				var hAddButton = hSkillEntry.FindChild("AddButton");
				hAddButton._bIsEnabled = (nSkillPoints >= nSkillCost);
				hAddButton.SetAttributeInt("value", nSkillBaseValue);
				hAddButton.SetHasClass("SkillEntryAddButtonAllocated", bHasAllocatedPoints);
				hAddButton.SetHasClass("SkillEntryAddButtonEnabled", hAddButton._bIsEnabled && !bHasAllocatedPoints);
			}
		}
	}
	return true;
}

function OnSkillsPartyUpdate(hContextPanel, tArgs)
{
	ConfirmSkillSelection(hContextPanel);
	hContextPanel.SetAttributeInt("entindex", tArgs.entindex);
	DispatchCustomEvent(hContextPanel, "SkillsUpdate");
	return true;
}

function OnSkillsEntityUpdate(szTableName, szKey, tData)
{
	var nEntityIndex = $.GetContextPanel().GetAttributeInt("entindex", -1);
	if (parseInt(szKey) === nEntityIndex)
	{
		DispatchCustomEvent($.GetContextPanel(), "SkillsUpdate");
	}
}

function OnSkillsFocus(hContextPanel, tArgs)
{
	hContextPanel.visible = true;
	hContextPanel.SetAttributeInt("entindex", tArgs.entindex);
	DispatchCustomEvent(hContextPanel, "SkillsUpdate");
	return true;
}

function OnSkillsHide(hContextPanel, tArgs)
{
	hContextPanel.visible = false;
	ConfirmSkillSelection(hContextPanel);
	return true;
}

function OnSkillsLoad()
{
	$.GetContextPanel()._nAllocatedCount = 0;
	$.GetContextPanel()._tAllocatedPoints = [];
	
	var tEntryContainers = [ $("#LeftContainer"), $("#RightContainer") ];
	for (var i = 0; i < tEntryContainers.length; i++)
	{
		for (var j = 0; j < MAX_SKILL_ENTRIES; j++)
		{
			var szSkillEntryText = "iw_ui_character_skills_" + i + "_" + j;
			var hSkillEntry = $.CreatePanel("Panel", tEntryContainers[i], "SkillEntry" + ((i * MAX_SKILL_ENTRIES) + j + 1));
			hSkillEntry.BLoadLayoutSnippet("SkillEntrySnippet");
			hSkillEntry.FindChildTraverse("Title").text = $.Localize(szSkillEntryText);
			hSkillEntry.SetAttributeString("text", szSkillEntryText);
			hSkillEntry.SetPanelEvent("onmouseover", OnSkillEntryMouseOver.bind(this, hSkillEntry));
			hSkillEntry.SetPanelEvent("onmouseout", OnSkillEntryMouseOut.bind(this, hSkillEntry));
			var hAddButton = hSkillEntry.FindChildTraverse("AddButton");
			hAddButton.SetAttributeInt("id", (i * MAX_SKILL_ENTRIES) + j);
			hAddButton.SetPanelEvent("onactivate", OnSkillsAddButtonActivate.bind(this, hAddButton));
			hAddButton.SetPanelEvent("oncontextmenu", OnSkillsAddButtonContextMenu.bind(this, hAddButton));
			$.GetContextPanel()._tAllocatedPoints.push(0);
		}
	}
	
	RegisterCustomEventHandler($.GetContextPanel(), "SkillsUpdate", OnSkillsUpdate);
	RegisterCustomEventHandler($.GetContextPanel(), "WindowPartyUpdate", OnSkillsPartyUpdate);
	RegisterCustomEventHandler($.GetContextPanel(), "CharacterContentFocus", OnSkillsFocus);
	RegisterCustomEventHandler($.GetContextPanel(), "CharacterContentHide", OnSkillsHide);
	
	CustomNetTables.SubscribeNetTableListener("entities", OnSkillsEntityUpdate);
}