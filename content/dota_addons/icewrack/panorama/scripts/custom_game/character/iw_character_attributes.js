"use strict";

var stAttributesShortNames =
[
	"str", "end", "agi", "cun", "int", "wis"
];

var stAttributesDetailParams =
[
	[2, 1, 1, 1],
	[5, 1, 1],
	[1, 1, 1, 1],
	[5, 5],
	[1, 2],
	[0.025, 0.5, 0.5, 1]
];

function ConfirmAttributeSelection(hContextPanel)
{
	if (hContextPanel._nAllocatedCount > 0)
	{
		var nEntityIndex = hContextPanel.GetAttributeInt("entindex", -1);
		var tAttributesData = { entindex:nEntityIndex };
		hContextPanel._nAllocatedCount = 0;
		for (var i = 0; i < hContextPanel._tAllocatedPoints.length; i++)
		{
			tAttributesData[i+1] = hContextPanel._tAllocatedPoints[i];
			hContextPanel._tAllocatedPoints[i] = 0;
		}
		GameEvents.SendCustomGameEventToServer("iw_character_attributes_confirm", tAttributesData);
	}
}

function OnAttributeIconMouseOver(hContextPanel)
{
	var nID = hContextPanel.GetAttributeInt("id", -1);
	var nAttributeBase = $.GetContextPanel().GetAttributeInt("attrib_base" + nID, -1);
	var nAttributeBonus = $.GetContextPanel().GetAttributeInt("attrib_bonus" + nID, -1);
	var szTooltipText = "<b>" + $.Localize("iw_ui_character_attributes_" + stAttributesShortNames[nID]) + ": " + nAttributeBase;
	if (nAttributeBonus > 0)
		szTooltipText = szTooltipText + "<font color=\"#00ff00\"> +" + nAttributeBonus + "</font>";
	else if (nAttributeBonus < 0)
		szTooltipText = szTooltipText + "<font color=\"#ff0000\"> -" + nAttributeBonus + "</font>";
	szTooltipText = szTooltipText + "</b><br><font color=\"#c0c0c0\">" + $.Localize("iw_ui_character_attributes_" + stAttributesShortNames[nID] + "_desc") + "</font>";
	$.DispatchEvent("DOTAShowTextTooltip", hContextPanel, szTooltipText);
}

function OnAttributeIconMouseOut(hContextPanel)
{
	$.DispatchEvent("DOTAHideTextTooltip", hContextPanel);
}

function OnAttributeIconActivate(hContextPanel)
{
	var nID = hContextPanel.GetAttributeInt("id", -1);
	if ($.GetContextPanel().GetAttributeInt("attrib_points", 0) > 0)
	{
		$.GetContextPanel()._tAllocatedPoints[nID]++;
		$.GetContextPanel()._nAllocatedCount++;
	}
	DispatchCustomEvent($.GetContextPanel(), "AttributesUpdate");
}

function OnAttributeIconContextMenu(hContextPanel)
{
	var nID = hContextPanel.GetAttributeInt("id", -1);
	if ($.GetContextPanel()._tAllocatedPoints[nID] > 0)
	{
		$.GetContextPanel()._tAllocatedPoints[nID]--;
		$.GetContextPanel()._nAllocatedCount--;
	}
	DispatchCustomEvent($.GetContextPanel(), "AttributesUpdate");
}

function OnAttributesUpdate(hContextPanel, tArgs)
{
	var nEntityIndex = hContextPanel.GetAttributeInt("entindex", -1);
	if (nEntityIndex !== -1)
	{
		var tPropertiesData = CustomNetTables.GetTableValue("entities", nEntityIndex);
		var nAttributePoints = GetBasePropertyValue(tPropertiesData, Instance.IW_PROPERTY_ATTRIBUTE_POINTS) - hContextPanel._nAllocatedCount;
		hContextPanel.SetAttributeInt("attrib_points", nAttributePoints);
		DispatchCustomEvent(hContextPanel.GetParent(), "CharacterAttribPointsUpdate", { value:nAttributePoints });
		
		if (hContextPanel.visible)
		{
			var nAttributeSum = 0;
			var tAttributeValues = [];
			var nAttributesCount = stAttributesShortNames.length;
			for (var i = 0; i < nAttributesCount; i++)
			{
				var nAttributeBase = Math.floor(GetBasePropertyValue(tPropertiesData, Instance.IW_PROPERTY_ATTR_STR_FLAT + i));
				var nAllocatedPoints = hContextPanel._tAllocatedPoints[i];
				hContextPanel._tAttribValues[i].text = (nAttributeBase + nAllocatedPoints);
				hContextPanel._tAttribValues[i].SetHasClass("AttributeValueLabelAllocated", (nAllocatedPoints > 0));
				
				var fAttributePercent = 1.0 + GetPropertyValue(tPropertiesData, Instance.IW_PROPERTY_ATTR_STR_PCT + i)/100.0;
				var nAttributeTotal = Math.floor(GetPropertyValue(tPropertiesData, Instance.IW_PROPERTY_ATTR_STR_FLAT + i) * fAttributePercent);
				
				if (nAttributeTotal > nAttributeBase)
				{
					hContextPanel._tAttribBonuses[i].text = "+" + (nAttributeTotal - nAttributeBase);
					hContextPanel._tAttribBonuses[i].SetHasClass("AttributeBonusLabelNegative", false);
				}
				else if (nAttributeTotal < nAttributeBase)
				{
					hContextPanel._tAttribBonuses[i].text = "-" + (nAttributeBase - nAttributeTotal);
					hContextPanel._tAttribBonuses[i].SetHasClass("AttributeBonusLabelNegative", true);
				}
				else
				{
					hContextPanel._tAttribBonuses[i].text = "";
				}
				
				var tDetails = hContextPanel._tAttribDetails[i].Children();
				for (var k in tDetails)
				{
					var szLocalizedText = $.Localize("iw_ui_character_attributes_" + stAttributesShortNames[i] + "_" + k);
					var fDetailValue = Math.floor(stAttributesDetailParams[i][parseInt(k)] * (nAttributeTotal + nAllocatedPoints) * 1000)/1000.0;		//Round to 3 decimal places, but don't show trailing zeros
					tDetails[k].text = szLocalizedText.replace(/\{[^}]\}/g, fDetailValue);
					tDetails[k].SetHasClass("AttributeDetailLabelAllocated", (nAllocatedPoints > 0));
				}
				hContextPanel.SetAttributeInt("attrib_base" + i, nAttributeBase);
				hContextPanel.SetAttributeInt("attrib_bonus" + i, nAttributeTotal - nAttributeBase);
				tAttributeValues.push(nAttributeTotal + nAllocatedPoints);
				nAttributeSum += (nAttributeTotal + nAllocatedPoints);
			}
			
			for (var i = 0; i < nAttributesCount; i++)
			{
				var f1 = Math.min((2.0 * tAttributeValues[i])/nAttributeSum, 1.0);
				var f2 = Math.min((2.0 * tAttributeValues[(i+1)%6])/nAttributeSum, 1.0);
				
				var dy = (Math.cos((i+1)%6 * 1.0471975512) * f2) - (Math.cos(i * 1.0471975512) * f1);
				var dx = (Math.sin((i+1)%6 * 1.0471975512) * f2) - (Math.sin(i * 1.0471975512) * f1);
				var t = -Math.atan2(dy, dx);
				
				var fRotation = (t * 57.2957795131).toFixed(8);
				var fTranslateX = 0.0;
				var fTranslateY = 0.0;
				var hSectionFill = hContextPanel._tAttribSections[i].FindChildTraverse("Fill");
				switch(i)
				{
					case 0:
						fTranslateY = 160 * (1.0 - f1);
						break;
					case 1:
						fTranslateX = 138.564064605 * f1;
						fTranslateY = 80 * (1.0 - f1);
						break;
					case 2:
						fTranslateX = 138.564064606 * f1;
						fTranslateY = 80 * f1;
						break;
					case 3:
						fTranslateX = 138.564064606;
						fTranslateY = 160 * f1;
						break;
					case 4:
						fTranslateX = 138.564064606 * (1.0 - f1);
						fTranslateY = 80 * (1.0 + f1);
						break;
					case 5:
						fTranslateX = 138.564064606 * (1.0 - f1);
						fTranslateY = 160 - (80 * f1);
						break;
				}
				hSectionFill.style.transform = "rotatez(" + fRotation + "deg) translatex(" + fTranslateX + "px) translatey(" + fTranslateY + "px)";	
			}
		}
	}
	return true;
}

function OnAttributesPartyUpdate(hContextPanel, tArgs)
{
	ConfirmAttributeSelection(hContextPanel);
	hContextPanel._nAllocatedCount = 0;
	for (var i = 0; i < hContextPanel._tAllocatedPoints.length; i++)
	{
		hContextPanel._tAllocatedPoints[i] = 0;
	}
	hContextPanel.SetAttributeInt("entindex", tArgs.entindex);
	DispatchCustomEvent(hContextPanel, "AttributesUpdate");
	return true;
}

function OnAttributesEntityUpdate(szTableName, szKey, tData)
{
	var nEntityIndex = $.GetContextPanel().GetAttributeInt("entindex", -1);
	if (parseInt(szKey) === nEntityIndex)
	{
		DispatchCustomEvent($.GetContextPanel(), "AttributesUpdate");
	}
}

function OnAttributesFocus(hContextPanel, tArgs)
{
	var nEntityIndex = tArgs.entindex;
	hContextPanel.visible = true;
	hContextPanel.SetAttributeInt("entindex", nEntityIndex);
	DispatchCustomEvent(hContextPanel, "AttributesUpdate");
	return true;
}

function OnAttributesHide(hContextPanel, tArgs)
{
	hContextPanel.visible = false;
	ConfirmAttributeSelection(hContextPanel);
	return true;
}

function OnAttributesLoad()
{
	$.GetContextPanel()._tAttribValues = [];
	$.GetContextPanel()._tAttribBonuses = [];
	$.GetContextPanel()._tAttribDetails = [];
	$.GetContextPanel()._tAttribSections = [];
	
	$.GetContextPanel()._nAllocatedCount = 0;
	$.GetContextPanel()._tAllocatedPoints = [];
	
	var hAttributesGraph = $("#AttributesGraph");
	var szAttribPointsText = "<b>" + $.Localize("iw_ui_character_attributes_points") + "</b><br>";
	szAttribPointsText = szAttribPointsText + "<font color=\"#c0c0c0\">" + $.Localize("iw_ui_character_attributes_points_left") + "<br>";
	szAttribPointsText = szAttribPointsText + $.Localize("iw_ui_character_attributes_points_right") + "</font>";
	
	var hAttributeList = $("#AttributeList");
	var hIconContainer = $("#IconContainer");
	var hSectionContainer = $("#SectionContainer");
	for (var i = 0; i < stAttributesShortNames.length; i++)
	{
		var hListEntry = $.CreatePanel("Panel", hAttributeList, "ListEntry" + (i + 1));
		hListEntry.BLoadLayoutSnippet("AttributeListEntrySnippet");
		var hTitleText = hListEntry.FindChildTraverse("Title");
		hTitleText.text = $.Localize("#iw_ui_character_attributes_" + stAttributesShortNames[i]);
		$.GetContextPanel()._tAttribValues.push(hListEntry.FindChildTraverse("Value"));
		$.GetContextPanel()._tAttribBonuses.push(hListEntry.FindChildTraverse("Bonus"));
		var hDetails = hListEntry.FindChildTraverse("Details");
		for (var j = 0; j < stAttributesDetailParams[i].length; j++)
		{
			var hDetailsText = $.CreatePanel("Label", hDetails, "Detail" + j);
			hDetailsText.AddClass("AttributeDetailLabel");
			hDetailsText.text = $.Localize("iw_ui_character_attributes_" + stAttributesShortNames[i] + "_" + j);
		}
		$.GetContextPanel()._tAttribDetails.push(hDetails);
		
		var hIcon = $.CreatePanel("Panel", hIconContainer, "Icon" + (i + 1));
		hIcon.SetAttributeInt("id", i);
		hIcon.BLoadLayoutSnippet("AttributeIconSnippet");
		hIcon.AddClass("AttributesIcon" + (i + 1));
		var hIconTexture = hIcon.FindChildrenWithClassTraverse("AttributeIconTexture")[0];
		hIconTexture.SetImage("file://{images}/custom_game/character/attributes/iw_attribute_" + stAttributesShortNames[i] + ".tga");
		hIcon.SetPanelEvent("onmouseover", OnAttributeIconMouseOver.bind(this, hIcon));
		hIcon.SetPanelEvent("onmouseout", OnAttributeIconMouseOut.bind(this, hIcon));
		hIcon.SetPanelEvent("onactivate", OnAttributeIconActivate.bind(this, hIcon));
		hIcon.SetPanelEvent("oncontextmenu", OnAttributeIconContextMenu.bind(this, hIcon));
		
		var hSection = $.CreatePanel("Panel", hSectionContainer, "Section" + (i + 1));
		hSection.BLoadLayoutSnippet("AttributeSectionSnippet" + ((i % 2) + 1));
		hSection.AddClass("AttributeSection" + (i + 1));
		$.GetContextPanel()._tAttribSections.push(hSection);
		$.GetContextPanel()._tAllocatedPoints.push(0);
	}
	CreateVerticalScrollbar($.GetContextPanel(), "AttribListScrollbar", hAttributeList);
	
	RegisterCustomEventHandler($.GetContextPanel(), "AttributesUpdate", OnAttributesUpdate);
	RegisterCustomEventHandler($.GetContextPanel(), "WindowPartyUpdate", OnAttributesPartyUpdate);
	RegisterCustomEventHandler($.GetContextPanel(), "CharacterContentFocus", OnAttributesFocus);
	RegisterCustomEventHandler($.GetContextPanel(), "CharacterContentHide", OnAttributesHide);
	
	CustomNetTables.SubscribeNetTableListener("entities", OnAttributesEntityUpdate);
}