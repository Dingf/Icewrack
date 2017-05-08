"use strict";

function OnIconLabelMouseOver()
{
	$.DispatchEvent("DOTAShowTextTooltip", $("#Icon"), $.GetContextPanel().GetAttributeString("hover_text", ""));
}

function OnIconLabelMouseOut()
{
	$.DispatchEvent("DOTAHideTextTooltip", $("#Icon"));
}

function OnIconLabelLoad()
{
	$("#IconBackground").style.width = "30px";
	$("#IconBackground").style.height = "30px";
	$("#IconBackground").BLoadLayout("file://{resources}/layout/custom_game/ui/iw_widget_stretchbox.xml", false, false);
	
	var nLabelWidth = $.GetContextPanel().GetAttributeInt("label_width", 86);
	$("#LabelBackground").style.width = (nLabelWidth + "px");
	$("#LabelBackground").style.height = "30px";
	$("#LabelBackground").BLoadLayout("file://{resources}/layout/custom_game/ui/iw_widget_stretchbox.xml", false, false);
	$("#LabelContainer").style.position = "23px 0px 0px";
}

function SetIconLabelText(hPanel, szLabelText)
{
	hPanel.FindChildTraverse("Label").text = szLabelText;
}

function CreateIconLabel(hParent, szName, szIconImage, szLabelText, szColor, szHoverText, nLabelWidth)
{
	var hPanel = $.CreatePanel("Panel", hParent, szName);
	hPanel.BLoadLayout("file://{resources}/layout/custom_game/ui/iw_widget_icon_label.xml", false, false);
	hPanel.SetAttributeString("hover_text", szHoverText);
	if (typeof(nLabelWidth) !== "undefined")
		hPanel.SetAttributeInt("label_width", nLabelWidth);
	hPanel.FindChildTraverse("Icon").SetImage("file://{images}/custom_game/" + szIconImage + ".tga");
	hPanel.FindChildTraverse("Icon").style["wash-color"] = szColor;
	hPanel.FindChildTraverse("Label").text = $.Localize(szLabelText);
	hPanel.FindChildTraverse("Label").style.color = szColor;
	return hPanel;
}