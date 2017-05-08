var stDropdownTableParams =
{
	1:  {"0":8},
	2:  {"0":8},
	3:  {"0":8},
	4:  {"0":8},
	5:  {"0":4},
	6:  {"0":7},
	10: {"0":4},
	11: {"0":22},
	19: {"0":8},
	20: {"0":8, "1":3, "2":8},
	21: {"0":8}
};

function OnAAMConditionItemUpdateValue(hContextPanel, tArgs)
{
	var nOffset = tArgs.panel.GetAttributeInt("offset", -1);
	var nSize = tArgs.panel.GetAttributeInt("size", -1);
	var nValue = hContextPanel.GetAttributeInt("value", -1);
	
	if (typeof tArgs.value === "number")
	{
		nValue = nValue & ((0xFFFFFFFF << (nSize + nOffset)) | ((0xFFFFFFFF >>> (31 - nOffset)) >>> 1));
		nValue = nValue | (tArgs.value << nOffset);
	}
	hContextPanel.SetAttributeInt("value", nValue);
	return false;
}

function OnAAMConditionItemSetValue(hContextPanel, tArgs)
{
	var nID = hContextPanel.GetAttributeInt("id", -1);
	var nInverse = hContextPanel.GetAttributeInt("inverse", 0);
	var hBodyPanel = hContextPanel.FindChild("Body");
	var nValue = tArgs.value;
	
	if (nInverse !== tArgs.inverse)
	{
		hBodyPanel.RemoveAndDeleteChildren();
		CreateDropdownText(hBodyPanel, "iw_ui_aam_condition" + nID + ((tArgs.inverse === 1) ? "n" : ""), stDropdownTableParams[nID]);
	}
	
	var tChildren = hBodyPanel.Children();
	for (var k in tChildren)
	{
		if (tChildren[k].paneltype === "Panel")
		{
			var nOffset = tChildren[k].GetAttributeInt("offset", -1);
			var nSize = tChildren[k].GetAttributeInt("size", -1);
			var nValue = (tArgs.value >>> nOffset) & ~(0xFFFFFFFF << nSize);
			DispatchCustomEvent(tChildren[k], "DropdownValueUpdateQuiet", { panel:tChildren[k], value:nValue });
		}
	}
	
	hContextPanel.SetAttributeInt("value", tArgs.value);
	hContextPanel.SetAttributeInt("inverse", tArgs.inverse);
	hContextPanel.FindChildTraverse("InvertButton").SetHasClass("AAMConditionItemInverted", (tArgs.inverse === 1));
	return true
}

function OnAAMConditionItemClear(hContextPanel, tArgs)
{
	var tChildren = hContextPanel.FindChildTraverse("Body").Children();
	for (var k in tChildren)
	{
		if (tChildren[k]._hMenuList)
		{
			tChildren[k]._hMenuList.DeleteAsync(0.0);
		}
	}
	hContextPanel.FindChildTraverse("Body").RemoveAndDeleteChildren();
	return true
}

function OnAAMConditionItemDeleteActivate()
{
	$.GetContextPanel().SetAttributeInt("value", 0);
	DispatchCustomEvent($.GetContextPanel(), "AAMConditionItemClear", { panel:$.GetContextPanel() });
	DispatchCustomEvent($.GetContextPanel(), "AAMConditionItemDelete", { panel:$.GetContextPanel(), id:$.GetContextPanel().GetAttributeInt("id", -1) });
	$.GetContextPanel().DeleteAsync(0.0);
}

function OnAAMConditionItemInvertActivate()
{
	var tDropdownValues = {};
	var hBodyPanel = $.GetContextPanel().FindChild("Body");
	var tChildren = hBodyPanel.Children();
	for (var k in tChildren)
	{
		if (tChildren[k].paneltype === "Panel")
		{
			tDropdownValues[tChildren[k].id] = tChildren[k]._mValue;
		}
	}
	
	var nID = $.GetContextPanel().GetAttributeInt("id", -1);
	var nInverse = 1 - $.GetContextPanel().GetAttributeInt("inverse", 0);
	
	DispatchCustomEvent($.GetContextPanel(), "AAMConditionItemClear", { panel:$.GetContextPanel() });
	CreateDropdownText(hBodyPanel, "iw_ui_aam_condition" + nID + ((nInverse === 1) ? "n" : ""), stDropdownTableParams[nID]);
	for (var k in tDropdownValues)
	{
		var hPanel = hBodyPanel.FindChildTraverse(k);
		if (hPanel)
		{
			DispatchCustomEvent(hPanel, "DropdownValueUpdate", { panel:hPanel, value:tDropdownValues[k] });
		}
	}
	
	OnAAMConditionItemLoad();
	$.GetContextPanel().SetAttributeInt("inverse", nInverse);
	$("#InvertButton").SetHasClass("AAMConditionItemInverted", (nInverse === 1));
	DispatchCustomEvent($.GetContextPanel(), "AAMConditionItemInvert", { panel:$.GetContextPanel() });
}

function OnAAMConditionItemLoad()
{
	var nValue = 0;
	var nValueCount = 0;
	var tChildren = $("#Body").Children();
	for (var k in tChildren)
	{
		var nOffset = tChildren[k].GetAttributeInt("offset", -1);
		var nSize = tChildren[k].GetAttributeInt("size", -1);
		if (tChildren[k]._mValue)
		{
			if (typeof tChildren[k]._mValue === "number")
			{
				nValue = nValue | (tChildren[k]._mValue << nOffset);
			}
			nValueCount++;
		}
	}
	$.GetContextPanel().SetAttributeInt("value", (nValueCount === 0) ? 1 : nValue);
	DispatchCustomEvent($.GetContextPanel().GetParent(), "DropdownValueUpdate", { panel:$.GetContextPanel() });
}

function CreateAAMConditionItem(hParent, szName, nID)
{
	var hPanel = $.CreatePanel("Panel", hParent, szName);
	hPanel.BLoadLayout("file://{resources}/layout/custom_game/aam/iw_aam_condition_item.xml", false, false);
	hPanel.SetAttributeInt("id", nID);
	hPanel.SetAttributeInt("inverse", 0);
	CreateDropdownText(hPanel.FindChild("Body"), "iw_ui_aam_condition" + nID, stDropdownTableParams[nID]);
	
	RegisterCustomEventHandler(hPanel, "DropdownValueUpdate", OnAAMConditionItemUpdateValue);
	RegisterCustomEventHandler(hPanel, "AAMConditionItemClear", OnAAMConditionItemClear);
	RegisterCustomEventHandler(hPanel, "AAMConditionItemSetValue", OnAAMConditionItemSetValue);
	
	var nNextID = null;
	var hNextPanel = null;
	var tConditionItems = hParent.Children();
	for (var k in tConditionItems)
	{
		var nSiblingID = tConditionItems[k].GetAttributeInt("id", -1);
		if ((nSiblingID > nID) && (!nNextID || (nSiblingID < nNextID)))
		{
			nNextID = nSiblingID;
			hNextPanel = tConditionItems[k];
		}
	}
	
	if (hNextPanel)
	{
		hParent.MoveChildBefore(hPanel, hNextPanel);
	}
	
	return hPanel;
}