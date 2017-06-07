"use strict";

function OnTooltipModifierLoad()
{
	var nEntityIndex = parseInt($.GetContextPanel().GetAttributeString("entindex", ""));
	var nBuffIndex = parseInt($.GetContextPanel().GetAttributeString("buffindex", ""));
	
	var tModifierArgs = {}
	var szTextureName = Buffs.GetTexture(nEntityIndex, nBuffIndex);
	var tArgumentsList = szTextureName.split(" ");
	var szArgumentRegex = /(\w+)=([+-]*\w+\.?\w*)/;
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
	
	$("#Class").visible = (tModifierArgs["modifier_class"] !== 0);
	$("#Class").text = $.Localize("#iw_ui_modifier_class_" + tModifierArgs["modifier_class"]);
	$("#Status").visible = (tModifierArgs["status_effect"] !== 0);
	$("#Status").text = $.Localize("#iw_ui_modifier_status_" + tModifierArgs["status_effect"]);
	
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
			var tSpecialBaseValues = tSpecialSections[i].split("*", 2);
			var fSpecialValue = tModifierArgs[tSpecialBaseValues[0]];
			if (typeof(fSpecialValue) === "number")
			{
				if (tSpecialBaseValues.length > 1)
				{
					if (tSpecialBaseValues[1] === "stack_count")
					{
						fSpecialValue *= Buffs.GetStackCount(nEntityIndex, nBuffIndex);
					}
					else
					{
						var fSpecialBaseMultiplier = parseFloat(tSpecialBaseValues[1]);
						if (fSpecialBaseMultiplier)
						{
							fSpecialValue *= fSpecialBaseMultiplier;
						}
					}
				}
				szFormattedText += "<font color=\"#ffffff\">";
				szFormattedText += Math.round(fSpecialValue * 100)/100;
				szFormattedText += "</font>";
			}
		}
	}
	
	$("#Description").text = szFormattedText;
}