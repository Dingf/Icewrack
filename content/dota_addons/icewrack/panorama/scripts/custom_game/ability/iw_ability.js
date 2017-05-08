"use strict";

function OnAbilityListClear(hContextPanel, tArgs)
{
	var tAbilityComboPanels = hContextPanel._tAbilityComboPanels;
	for (var k in tAbilityComboPanels)
	{
		tAbilityComboPanels[k].visible = false;
	}
	
	var tAbilityEntryPanels = hContextPanel._tAbilityEntryPanels;
	for (var i = 0; i < tAbilityEntryPanels.length; i++)
	{
		tAbilityEntryPanels[i].visible = false;
	}
	return true;
}

function OnAbilityListLoad(hContextPanel, tArgs)
{
	DispatchCustomEvent(hContextPanel, "AbilityListClear");
	var nEntityIndex = hContextPanel.GetAttributeInt("entindex", -1);
	if (nEntityIndex === -1)
		return;
	
	var hAbilityList = hContextPanel.FindChildTraverse("List");
	var tEntityAbilityEntries = hContextPanel._tEntityAbilityEntries;
	if (!tEntityAbilityEntries[nEntityIndex])
	{
		tEntityAbilityEntries[nEntityIndex] = [];
		var tEntitySpellbook = CustomNetTables.GetTableValue("spellbook", nEntityIndex);
		var tEntitySpellList = tEntitySpellbook.Spells;
		for (var k in tEntitySpellList)
		{
			var nAbilityIndex = tEntitySpellList[k].entindex;
			var szLocalizedAbilityName = $.Localize("DOTA_Tooltip_Ability_" + Abilities.GetAbilityName(nAbilityIndex));
			var hEntry = CreateAbilityEntry(hAbilityList, "Ability" + nAbilityIndex, nEntityIndex, nAbilityIndex);
			
			var tSiblings = hAbilityList.Children();
			for (var i = 0; i < tSiblings.length; i++)
			{
				if (tSiblings[i] !== hEntry)
				{
					var szSiblingName = $.Localize("DOTA_Tooltip_Ability_" + tSiblings[i].GetAttributeString("name", ""));
					if (szLocalizedAbilityName < szSiblingName)
					{
						hAbilityList.MoveChildBefore(hEntry, tSiblings[i]);
						break;
					}
				}
			}
			
			hContextPanel._tAbilityEntryPanels.push(hEntry);
			tEntityAbilityEntries[nEntityIndex].push(hEntry);
		}
	}
	else
	{
		for (var i = 0; i < tEntityAbilityEntries[nEntityIndex].length; i++)
		{
			tEntityAbilityEntries[nEntityIndex][i].visible = true;
		}
	}
	DispatchCustomEvent(hContextPanel, "AbilitySkillFilter");
	return true;
}

function OnAbilityListLoadCombos(hContextPanel, tArgs)
{
	DispatchCustomEvent(hContextPanel, "AbilityListClear");
	var hAbilityList = hContextPanel.FindChildTraverse("List");
	var tAbilityComboPanels = hContextPanel._tAbilityComboPanels;
	var tSpellbookComboList = CustomNetTables.GetTableValue("spellbook", "combos");
	for (var k in tSpellbookComboList)
	{
		if (tAbilityComboPanels[k])
		{
			tAbilityComboPanels[k].visible = true;
		}
		else
		{
			var hEntry = CreateAbilityComboEntry(hAbilityList, "Combo" + k, k);
			tAbilityComboPanels[k] = hEntry;
		}
	}
	return true;
}

function OnAbilitySkillIconActivate(hContextPanel, tArgs)
{
	var hPanel = tArgs.panel;
	if (hPanel)
	{
		var nSkillID = hPanel.GetAttributeInt("id", -1);
		var nValue = hPanel.GetAttributeInt("state", -1);
		
		var nSkillMask = hContextPanel.GetAttributeInt("skillmask", -1);
		nSkillMask = nSkillMask & ~(1 << nSkillID);
		nSkillMask = nSkillMask | (nValue << nSkillID);
		hContextPanel.SetAttributeInt("skillmask", nSkillMask);
		
		DispatchCustomEvent(hContextPanel, "AbilitySkillFilter");
	}
	return true;
}

function OnAbilityEntrySelectParent(hContextPanel, tArgs)
{
	var hPanel = tArgs.panel;
	var hSelectedEntry = hContextPanel._hSelectedEntry;
	if (hPanel && (hPanel !== hSelectedEntry))
	{
		if (hSelectedEntry)
		{
			DispatchCustomEvent(hSelectedEntry, "AbilityEntryDeselect", { quiet:true });
		}
		if (hPanel.GetAttributeInt("is_combo", 0))
		{
			var szAbilityName = hPanel.GetAttributeString("name", "");
			var tComboTemplate = hPanel._tComboTemplate;
			DispatchCustomEvent(hContextPanel._hDetailsPanel, "AbilityDetailsUpdateCombo", { name:szAbilityName, template:tComboTemplate });
		}
		else
		{
			var nAbilityIndex = hPanel.GetAttributeInt("abilityindex", -1);
			DispatchCustomEvent(hContextPanel._hDetailsPanel, "AbilityDetailsUpdate", { abilityindex:nAbilityIndex });
		}
		hContextPanel._hSelectedEntry = hPanel;
	}
	return true;
}

function OnAbilityEntryDeselectParent(hContextPanel, tArgs)
{
	var hPanel = (!tArgs || !tArgs.hPanel) ? hContextPanel._hSelectedEntry : tArgs.panel;
	if ((hPanel === hContextPanel._hSelectedEntry) && (!tArgs || !tArgs.quiet))
	{
		hContextPanel._hSelectedEntry = null;
		DispatchCustomEvent(hContextPanel._hDetailsPanel, "AbilityDetailsSetVisible", { visible:false });
	}
	return true;
}

function OnAbilitySkillMask(hContextPanel, tArgs)
{
	var nSkillMask = tArgs.mask;
	for (var i = 0; i < 26; i++)
	{
		var nState = (nSkillMask & (1 << i)) >>> i;
		DispatchCustomEvent(hContextPanel.FindChildTraverse("SkillIcon" + i), "AbilitySkillIconSetState", { state:nState });
	}
	hContextPanel.SetAttributeInt("skillmask", nSkillMask);
	return true;
}

function OnAbilitySkillFilter(hContextPanel, tArgs)
{
	var nSkillMask = hContextPanel.GetAttributeInt("skillmask", -1);
	var nEntityIndex = hContextPanel.GetAttributeInt("entindex", -1);
	var szSearchTextFilter = hContextPanel.GetAttributeString("searchtext", "");
	if (!hContextPanel._bIsComboMode)
	{
		var tEntityAbilityEntries = hContextPanel._tEntityAbilityEntries;
		for (var i = 0; i < tEntityAbilityEntries[nEntityIndex].length; i++)
		{
			var nEntryEntindex = tEntityAbilityEntries[nEntityIndex][i].GetAttributeInt("entindex", -1);
			var nEntrySkillMask = tEntityAbilityEntries[nEntityIndex][i].GetAttributeInt("skillmask", -1);
			tEntityAbilityEntries[nEntityIndex][i].visible = ((nEntrySkillMask & nSkillMask) !== 0);
			if (szSearchTextFilter !== "")
			{
				var nAbilityIndex = tEntityAbilityEntries[nEntityIndex][i].GetAttributeInt("abilityindex", -1);
				var szAbilityName = $.Localize("DOTA_Tooltip_Ability_" + Abilities.GetAbilityName(nAbilityIndex)).toLowerCase();
				if (szAbilityName.indexOf(szSearchTextFilter) === -1)
				{
					tEntityAbilityEntries[nEntityIndex][i].visible = false;
				}
			}
		}
	}
	else
	{
		var tComboPanels = hContextPanel._tAbilityComboPanels;
		for (var k in tComboPanels)
		{
			var szAbilityName = tComboPanels[k].GetAttributeString("name", "");
			tComboPanels[k].visible = (szAbilityName.indexOf(szSearchTextFilter) !== -1);
		}
	}
	return true;
}

function OnAbilitySearchTextUpdate()
{
	var szText = $("#Abilities").FindChildTraverse("SearchText").text.toLowerCase();
	$.GetContextPanel().SetAttributeString("searchtext", szText);
	
	DispatchCustomEvent($.GetContextPanel(), "AbilitySkillFilter");
}

function OnAbilityOpen(hContextPanel, tArgs)
{
	DispatchCustomEvent(hContextPanel, "AbilitySkillMask", { mask:0x7fffffff });
	DispatchCustomEvent(hContextPanel, "AbilitySkillFilter");
	if (hContextPanel._hSelectedEntry)
	{
		DispatchCustomEvent(hContextPanel._hSelectedEntry, "AbilityEntryDeselect");
	}
	
	GameUI.SetPauseScreen(true);
	return true;
}

function OnAbilityClose(hContextPanel, tArgs)
{
	GameUI.SetPauseScreen(false);
	return true;
}

function OnAbilityPartyUpdate(hContextPanel, tArgs)
{
	hContextPanel.SetAttributeInt("entindex", tArgs.entindex);
	DispatchCustomEvent(hContextPanel, "AbilitySkillMask", { mask:0x7fffffff });
	if (hContextPanel._bIsComboMode)
	{
		DispatchCustomEvent(hContextPanel, "AbilityListLoadCombos");
	}
	else
	{
		DispatchCustomEvent(hContextPanel, "AbilityListLoad");
		DispatchCustomEvent(hContextPanel, "AbilitySkillFilter");
		DispatchCustomEvent(hContextPanel._hDetailsPanel, "AbilityDetailsPartyUpdate", tArgs);
		if (hContextPanel._hSelectedEntry)
		{
			DispatchCustomEvent(hContextPanel._hSelectedEntry, "AbilityEntryDeselect");
		}
	}
	return true;
}


function OnAbilityTabActivate(hContextPanel, tArgs)
{
	var hPanel = tArgs.panel;
	var hAbilityTabLabel = hContextPanel.FindChildTraverse("TabLabel");
	if (hPanel.id === "TabAbilities")
	{
		hContextPanel._bIsComboMode = false;
		hAbilityTabLabel.text = $.Localize("#iw_ui_ability_list");
		DispatchCustomEvent(hContextPanel, "AbilityListLoad");
	}
	else if (hPanel.id === "TabCombinations")
	{
		hContextPanel._bIsComboMode = true;
		hAbilityTabLabel.text = $.Localize("#iw_ui_ability_list_combos");
		DispatchCustomEvent(hContextPanel, "AbilityListLoadCombos");
	}
	return true;
}

function LoadAbilityLayout()
{
	var hContent = $("#Abilities").FindChildTraverse("WindowMainContent");
	hContent.BLoadLayout("file://{resources}/layout/custom_game/ability/iw_ability_main.xml", false, false);
	
	var hSearchBackground = $("#Abilities").FindChildTraverse("SearchBackground");
	hSearchBackground.style.width = "270px";
	hSearchBackground.style.height = "46px";
	hSearchBackground.BLoadLayout("file://{resources}/layout/custom_game/ui/iw_widget_stretchbox.xml", false, false);
	
	var hSearchText = $("#Abilities").FindChildTraverse("SearchText");
	hSearchText.SetPanelEvent("ontextentrychange", OnAbilitySearchTextUpdate);
}

function LoadAbilityIcons()
{
	var hIconContainer = $("#Abilities").FindChildTraverse("IconContainer1");
	for (var i = 0; i < 13; i++)
	{
		var hIcon = CreateAbilitySkillIcon(hIconContainer, "SkillIcon" + i, i);
		hIcon.style.position = (64 + (i * 40)) + "px 16px 0px";
	}
	
	hIconContainer = $("#Abilities").FindChildTraverse("IconContainer2");
	for (var i = 0; i < 13; i++)
	{
		var hIcon = CreateAbilitySkillIcon(hIconContainer, "SkillIcon" + (i + 13), (i + 13));
		hIcon.style.position = (64 + (i * 40)) + "px 16px 0px";
	}
}

function LoadAbilityList()
{
	var hListBackground = $("#Abilities").FindChildTraverse("ListBackground");
	hListBackground.style.width = "270px";
	hListBackground.style.height = "550px";
	hListBackground.BLoadLayout("file://{resources}/layout/custom_game/ui/iw_widget_stretchbox.xml", false, false);
	
	var hListContainer = $("#Abilities").FindChildTraverse("ListContainer");
	var hList = $("#Abilities").FindChildTraverse("List");
	CreateVerticalScrollbar(hListContainer, "OverviewScrollbar", hList);
	
	var hTabContainer = $("#Abilities").FindChildTraverse("TabContainer");
	CreateWindowTab(hTabContainer, "TabAbilities", "inventory/iw_inventory_tab_weapons");
	CreateWindowTab(hTabContainer, "TabCombinations", "character/iw_character_tab_attributes");
	
	var hAbilityTabLabel = $("#Abilities").FindChildTraverse("TabLabel");
	hAbilityTabLabel.text = $.Localize("#iw_ui_ability_list");
}

function LoadAbilityDetails()
{
	var hDetailsBackground = $("#Abilities").FindChildTraverse("DetailsBackground");
	hDetailsBackground.style.width = "656px";
	hDetailsBackground.style.height = "414px";
	hDetailsBackground.BLoadLayout("file://{resources}/layout/custom_game/ui/iw_widget_stretchbox.xml", false, false);
	
	var hDetailsContainer = $("#Abilities").FindChildTraverse("DetailsContainer");
	var hDetails = CreateAbilityDetails(hDetailsContainer, "Details");
	CreateVerticalScrollbar(hDetailsContainer, "OverviewScrollbar", hDetails);
	$.GetContextPanel()._hDetailsPanel = hDetails;
}

(function()
{
	CreateWindowPanel($.GetContextPanel(), "Abilities", "abilities", "#iw_ui_abilities", false, true);
	
	LoadAbilityLayout();
	LoadAbilityIcons();
	LoadAbilityList();
	LoadAbilityDetails();
	
	$.GetContextPanel()._tAbilityEntryPanels = [];
	$.GetContextPanel()._tAbilityComboPanels = {};
	$.GetContextPanel()._tEntityAbilityEntries = {};
	
	RegisterCustomEventHandler($.GetContextPanel(), "WindowOpen", OnAbilityOpen);
	RegisterCustomEventHandler($.GetContextPanel(), "WindowClose", OnAbilityClose);
	RegisterCustomEventHandler($.GetContextPanel(), "WindowPartyUpdate", OnAbilityPartyUpdate);
	RegisterCustomEventHandler($.GetContextPanel(), "WindowTabActivate", OnAbilityTabActivate);
	RegisterCustomEventHandler($.GetContextPanel(), "AbilityListClear", OnAbilityListClear);
	RegisterCustomEventHandler($.GetContextPanel(), "AbilityListLoad", OnAbilityListLoad);
	RegisterCustomEventHandler($.GetContextPanel(), "AbilityListLoadCombos", OnAbilityListLoadCombos);
	RegisterCustomEventHandler($.GetContextPanel(), "AbilitySkillMask", OnAbilitySkillMask);
	RegisterCustomEventHandler($.GetContextPanel(), "AbilitySkillFilter", OnAbilitySkillFilter);
	RegisterCustomEventHandler($.GetContextPanel(), "AbilitySkillIconActivate", OnAbilitySkillIconActivate);
	RegisterCustomEventHandler($.GetContextPanel(), "AbilityEntrySelect", OnAbilityEntrySelectParent);
	RegisterCustomEventHandler($.GetContextPanel(), "AbilityEntryDeselect", OnAbilityEntryDeselectParent);
})();