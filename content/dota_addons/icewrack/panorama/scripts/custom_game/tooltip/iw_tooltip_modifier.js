"use strict";

function OnTooltipModifierLoad()
{
	var nEntityIndex = parseInt($.GetContextPanel().GetAttributeString("entindex", ""));
	var nBuffIndex = parseInt($.GetContextPanel().GetAttributeString("buffindex", ""));
	
	var tModifierArgs = {}
	var szTextureName = Buffs.GetTexture(nEntityIndex, nBuffIndex);
	var tArgumentsList = szTextureName.split(" ");
	var szArgumentRegex = /(\w+)=([+-]*[\w\.]+)/;
	for (var k in tArgumentsList)
	{
		var tResults = szArgumentRegex.exec(tArgumentsList[k]);
		if (tResults)
		{
			var szKey = tResults[1];
			if (szKey !== "texture")
			{
				var nNumberValue = Number(tResults[2])
				tModifierArgs[szKey] = (isNaN(nNumberValue)) ? tResults[2] : nNumberValue;
			}
		}
	}
	
	var szModifierName = Buffs.GetName(nEntityIndex, nBuffIndex);
	$("#Title").text = $.Localize("DOTA_Tooltip_" + szModifierName);
	
	var szLocalizedText = $.Localize("DOTA_Tooltip_" + szModifierName + "_Description");
	szLocalizedText = szLocalizedText.replace(/\n/g, "<br>");
	var tSpecialSections = szLocalizedText.match(/[^{}]+(?=})/g);
	var tTextSections = szLocalizedText.replace(/\{[^}]+\}/g, "|").split("|");
	var tTextSections = szLocalizedText.replace(/\{[^}]+\}/g, "|").split("|");
	
	var szFormattedText = "";
	for (var i = 0; i < tTextSections.length; i++)
	{
		szFormattedText += tTextSections[i];
		if (tSpecialSections && tSpecialSections[i])
		{
			var fSpecialValue = tModifierArgs[tSpecialSections[i]];
			if (typeof(fSpecialValue) === "number")
			{
				szFormattedText += "<font color=\"#ffffff\">";
				szFormattedText += Math.round(fSpecialValue * 100)/100;
				szFormattedText += "</font>";
			}
		}
	}
	
	$("#Description").text = szFormattedText;
}