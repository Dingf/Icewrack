"use strict";

function CreateDropdownText(hParent, szText, tTextArgs)
{
	var szLocalizedText = $.Localize(szText);
	var tDropdownIDs = szLocalizedText.match(/[^{}]+(?=})/g);
	var tLabels = szLocalizedText.replace(/\{[^}]\}/g, "|").split("|");
	
	var nOffset = 0;
	for (var i = 0; i < tLabels.length; i++)
	{
		var hLabel = $.CreatePanel("Label", hParent, "DropdownLabel" + i);
		hLabel.text = tLabels[i];
		if (tDropdownIDs && tDropdownIDs[i])
		{
			var hMenu = CreateDropdownMenu(hParent, "DropdownMenu" + tDropdownIDs[i]);
			hMenu.SetAttributeInt("offset", nOffset);
			if (tTextArgs[tDropdownIDs[i]])
			{
				for (var j = 0; j < tTextArgs[tDropdownIDs[i]]; j++)
				{
					AddDropdownMenuItem(hMenu, $.Localize("#" + szText + "_" + tDropdownIDs[i] + "_" + j), j);
				}
				for (var j = tTextArgs[tDropdownIDs[i]] - 1; j !== 0; j = j >> 1)
				{
					nOffset++;
				}
			}
			hMenu.SetAttributeInt("size", nOffset - hMenu.GetAttributeInt("offset", 0));
		}
	}
}