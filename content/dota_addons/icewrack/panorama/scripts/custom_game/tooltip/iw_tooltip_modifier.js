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
	
	var nModifierClass = tModifierArgs["modifier_class"];
	if ((typeof(nModifierClass) !== "undefined") && (nModifierClass !== 0))
	{
		$("#Class").visible = true;
		$("#Class").text = $.Localize("#iw_ui_modifier_class_" + nModifierClass);
	}
	else
	{
		$("#Class").visible = false;
	}
	
	var nStatusEffect = tModifierArgs["status_effect"];
	if ((typeof(nStatusEffect) !== "undefined") && (nStatusEffect !== 0))
	{
		$("#Status").visible = true;
		$("#Status").text = $.Localize("#iw_ui_modifier_status_" + nStatusEffect);
	}
	else
	{
		$("#Status").visible = false;
	}
	
	var szLocalizedText = $.Localize("DOTA_Tooltip_" + szModifierName + "_Description");
	szLocalizedText = szLocalizedText.replace(/\n/g, "<br>");
	var tSpecialSections = szLocalizedText.match(/[^{}]+(?=})/g);
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