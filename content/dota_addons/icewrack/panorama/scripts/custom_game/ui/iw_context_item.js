"use strict";

function OnContextItemActivate()
{
	DispatchCustomEvent($.GetContextPanel(), "ContextItemActivate", { value:$.GetContextPanel()._mValue });
}

function CreateContextItem(hParent, szName, szText)
{
	var hPanel = $.CreatePanel("Panel", hParent, szName);
	hPanel.BLoadLayout("file://{resources}/layout/custom_game/ui/iw_context_item.xml", false, false);
	hPanel.FindChildTraverse("Text").text = szText;
	return hPanel;
}