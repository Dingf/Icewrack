"use strict";

var AAM_STATE_DISABLED = 0;
var AAM_STATE_ENABLED = 1;
var AAM_STATE_ENABLED_WHILE_NOT_SELECTED = 2;

function InsertAAMCondition(bIsLocal)
{
	var nEntityIndex = $("#AAM").GetAttributeInt("entindex", -1);
	var hCondition = CreateAAMCondition($("#AAM").FindChildTraverse("Conditions"), "", nEntityIndex, bIsLocal);
		
	var nPriority = 1;
	var tConditionList = $.GetContextPanel()._tConditionList;
	for (var k in tConditionList)
	{
		if (tConditionList[k].visible)
		{
			nPriority++;
		}
	}
	DispatchCustomEvent(hCondition, "AAMConditionSetPriority", { priority:nPriority });
	
	var tEntityConditionPanels = $.GetContextPanel()._tEntityConditionPanels;
	if (!tEntityConditionPanels[nEntityIndex])
	{
		tEntityConditionPanels[nEntityIndex] = [];
	}
	tEntityConditionPanels[nEntityIndex].push(hCondition);
	$.GetContextPanel()._tConditionList.push(hCondition);
	return hCondition;
}

function DeleteAAMConditionList(bIsLocal)
{
	var nEntityIndex = $("#AAM").GetAttributeInt("entindex", -1);
	var tConditionList = $.GetContextPanel()._tConditionList;
	for (var i = tConditionList.length - 1; i >= 0; i--)
	{
		var hCondition = tConditionList[i];
		if (hCondition.visible)
		{
			if (!bIsLocal)
			{
				var nPriority = hCondition.GetAttributeInt("priority", -1);
				GameEvents.SendCustomGameEventToServer("iw_aam_delete_condition", { entindex:nEntityIndex, priority:nPriority });
			}
			
			var tChildren = hCondition.FindChildTraverse("ConditionBody").Children();
			for (var k in tChildren)
			{
				if (tChildren[k]._hMenuList)
				{
					tChildren[k]._hMenuList.DeleteAsync(0.0);
				}
			}
			
			tChildren = hCondition.FindChildTraverse("ConditionItemList").Children();
			for (var k in tChildren)
			{
				DispatchCustomEvent(tChildren[k], "AAMConditionItemClear");
			}
			hCondition.DeleteAsync(0.0);
		}
		$.GetContextPanel()._tConditionList.splice(i, 1);
	}
	$.GetContextPanel()._tEntityConditionPanels[nEntityIndex] = [];
}

function SaveAAMCondition()
{
	var nEntityIndex = $("#AAM").GetAttributeInt("entindex", -1);
	var szText = $("#AAM").FindChildTraverse("TitleText").text;
	GameEvents.SendCustomGameEventToServer("iw_aam_save", { entindex:nEntityIndex, name:szText });
}

function OpenAAMLoader()
{
	var nEntityIndex = $("#AAM").GetAttributeInt("entindex", -1);
	var hLoader = $.GetContextPanel()._hLoaderWindow.FindChildTraverse("PopupMain");
	DispatchCustomEvent(hLoader, "AAMLoaderOpen", { entindex:nEntityIndex });
}

function LoadAAMConditions()
{
	for (var i = 0; i < $.GetContextPanel()._tConditionList.length; i++)
	{
		$.GetContextPanel()._tConditionList[i].visible = false;
	}
	
	var nEntityIndex = $("#AAM").GetAttributeInt("entindex", -1);
	if (nEntityIndex === -1)
		return;
	
	var tEntityConditionPanels = $.GetContextPanel()._tEntityConditionPanels;
	if ((!tEntityConditionPanels[nEntityIndex]) || (tEntityConditionPanels[nEntityIndex].length == 0))
	{
		var tEntityAAMInfo = CustomNetTables.GetTableValue("aam", String(nEntityIndex));
		var szActiveAutomatorName = tEntityAAMInfo.ActiveAutomator;
		if (!szActiveAutomatorName)
			szActiveAutomatorName = $.Localize("#iw_ui_aam_default_name");
		
		$.GetContextPanel()._szActiveAutomator = szActiveAutomatorName;
		$("#AAM").FindChildTraverse("TitleText").text = szActiveAutomatorName;
		tEntityConditionPanels[nEntityIndex] = [];
		var tConditionList = tEntityAAMInfo.AutomatorList[szActiveAutomatorName];
		if (tConditionList)
		{
			for (var k in tConditionList)
			{
				var hCondition = InsertAAMCondition(true);
				var nFlags1 = tConditionList[k].Flags1;
				var nFlags2 = tConditionList[k].Flags2;
				var nInverseMask = tConditionList[k].InverseMask;
				var szAbilityName = tConditionList[k].Ability;
				DispatchCustomEvent(hCondition, "AAMConditionSetValue", { ability:szAbilityName, flags1:nFlags1, flags2:nFlags2, invmask:nInverseMask });
			}
		}
	}
	else
	{
		for (var i = 0; i < tEntityConditionPanels[nEntityIndex].length; i++)
		{
			tEntityConditionPanels[nEntityIndex][i].visible = true;
		}
	}
}

function UpdateAAMSelection()
{
	var tPartyMembers = CustomNetTables.GetTableValue("party", "Members");
	for (var k in tPartyMembers)
	{
		var nEntityIndex = parseInt(tPartyMembers[k]);
		var tAutomatorData = CustomNetTables.GetTableValue("aam", nEntityIndex);
		if (tAutomatorData.State === AAM_STATE_ENABLED_WHILE_NOT_SELECTED)
		{
			var nPlayerID = Players.GetLocalPlayer();
			var tSelectedEntities = Players.GetSelectedEntities(nPlayerID);
			var nEntitySelectedIndex = tSelectedEntities.indexOf(nEntityIndex);
			GameEvents.SendCustomGameEventToServer("iw_aam_change_state", { entindex:nEntityIndex, state:(nEntitySelectedIndex>=0)?0:1, hidden:true });
		}
	}
	$.Schedule(0.03, UpdateAAMSelection);
}

function OnAAMTitleTextUpdate()
{
	var szText = $("#AAM").FindChildTraverse("TitleText").text.replace(/[^\w\s]/g, "");
	if (!$.GetContextPanel()._bTitleTextLock)
	{
		$.GetContextPanel()._bTitleTextLock = true;
		$("#AAM").FindChildTraverse("TitleText").text = szText;
		$.GetContextPanel()._bTitleTextLock = false;
	}
	else
	{
		return;
	}
	
	var hSaveButton = $("#AAM").FindChildTraverse("SaveButton");
	if ((hSaveButton._bState) && (szText.length === 0))
	{
		hSaveButton._bState = false;
		DispatchCustomEvent(hSaveButton, "ButtonSetEnabled", { state:false });
	}
	else if ((!hSaveButton._bState) && (szText.length !== 0))
	{
		hSaveButton._bState = true;
		DispatchCustomEvent(hSaveButton, "ButtonSetEnabled", { state:true });
	}
}

function UpdateAAMInfo()
{
	var nEntityIndex = $("#AAM").GetAttributeInt("entindex", -1);
	var tEntityAAMInfo = CustomNetTables.GetTableValue("aam", String(nEntityIndex));
	DispatchCustomEvent($.GetContextPanel(), "AAMStateUpdate", { value:tEntityAAMInfo.State });
	DispatchCustomEvent($.GetContextPanel(), "AAMLoadUpdate");
}

function OnAAMOpen(hContextPanel, tArgs)
{
	GameUI.SetPauseScreen(true);
	return true;
}

function OnAAMClose(hContextPanel, tArgs)
{
	GameUI.SetPauseScreen(false);
	return true;
}

function OnAAMPartyUpdate(hContextPanel, tArgs)
{
	hContextPanel.SetAttributeInt("entindex", tArgs.entindex);
	LoadAAMConditions();
	UpdateAAMInfo();
	return true;
}

function OnAAMStateMouseOver()
{
	$("#AAM").AddClass("AAMStateMouseOver");
	var hTooltipHitbox = $("#AAM").FindChildTraverse("TooltipHitbox");
	var nState = $.GetContextPanel().GetAttributeInt("state", -1);
	if (nState !== -1)
	{
		$.DispatchEvent("DOTAShowTextTooltip", hTooltipHitbox, $.Localize("#iw_ui_aam_state_" + nState));
	}
}

function OnAAMStateMouseOut()
{
	$("#AAM").RemoveClass("AAMStateMouseOver");
	var hTooltipHitbox = $("#AAM").FindChildTraverse("TooltipHitbox");
	$.DispatchEvent("DOTAHideTextTooltip", hTooltipHitbox);
}

function OnAAMStateActivate()
{
	var nState = $.GetContextPanel().GetAttributeInt("state", -1);
	DispatchCustomEvent($.GetContextPanel(), "AAMStateUpdate", { value:(nState+1)%3 });
}

function OnAAMStateUpdate(hContextPanel, tArgs)
{
	var hStateButton = hContextPanel.FindChildTraverse("StateButton");
	var hTooltipHitbox = hContextPanel.FindChildTraverse("TooltipHitbox");
	if (hStateButton)
	{
		if (hContextPanel.FindChild("AAM").BHasClass("AAMStateMouseOver") && (tArgs.value !== -1))
		{
			$.DispatchEvent("DOTAShowTextTooltip", hTooltipHitbox, $.Localize("#iw_ui_aam_state_" + tArgs.value));
		}
		hStateButton.FindChildTraverse("TextureOff").visible = (tArgs.value === 0);
		hStateButton.FindChildTraverse("TextureOn").visible = (tArgs.value === 1);
		hStateButton.FindChildTraverse("TextureNS").visible = (tArgs.value === 2);
	}
	
	var nEntityIndex = hContextPanel.FindChild("AAM").GetAttributeInt("entindex", -1);
	var tAutomatorList = CustomNetTables.GetTableValue("aam", nEntityIndex).AutomatorList;
	if (Object.keys(tAutomatorList).length === 0)
	{
		var hTitleText = hContextPanel.FindChildTraverse("TitleText");
		GameEvents.SendCustomGameEventToServer("iw_aam_save", { entindex:nEntityIndex, name:hTitleText.text });
	}
	GameEvents.SendCustomGameEventToServer("iw_aam_change_state", { entindex:nEntityIndex, state:tArgs.value, hidden:false });
	hContextPanel.SetAttributeInt("state", tArgs.value);
	return true;
}

function OnAAMLoadUpdate(hContextPanel, tArgs)
{
	var nEntityIndex = hContextPanel.FindChild("AAM").GetAttributeInt("entindex", -1);
	var tAutomatorList = CustomNetTables.GetTableValue("aam", nEntityIndex).AutomatorList;
	if (tAutomatorList)
	{
		var hLoadButton = hContextPanel.FindChildTraverse("LoadButton");
		DispatchCustomEvent(hLoadButton, "ButtonSetEnabled", { state:(Object.keys(tAutomatorList).length > 1) });
	}
	return true;
}

function OnAAMLoadConditions(hContextPanel, tArgs)
{
	return true;
}

function OnAAMNetTableUpdate(szTableName, szKey, tData)
{
	var nEntityIndex = parseInt(szKey)
	var nState = $.GetContextPanel().GetAttributeInt("state", -1);
	if (nEntityIndex === $("#AAM").GetAttributeInt("entindex", -1))
	{
		if (tData.State !== nState)
		{
			DispatchCustomEvent($.GetContextPanel(), "AAMStateUpdate", { value:tData.State });
		}
		if (tData.ActiveAutomator !== $.GetContextPanel()._szActiveAutomator)
		{
			$.GetContextPanel()._szActiveAutomator = tData.ActiveAutomator;
			DeleteAAMConditionList(true);
			LoadAAMConditions();
		}
		DispatchCustomEvent($.GetContextPanel(), "AAMLoadUpdate");
	}
}

function OnAAMConditionMoveUp(hContextPanel, tArgs)
{
	var hCondition = tArgs.panel;
	var nPriority = hCondition.GetAttributeInt("priority", -1);
	var tConditionList = hContextPanel._tConditionList;
	for (var i = 0; i < tConditionList.length; i++)
	{
		if (tConditionList[i].visible)
		{
			var nConditionPriority = tConditionList[i].GetAttributeInt("priority", -1);
			if (nConditionPriority === nPriority - 1)
			{
				tConditionList[i].SetAttributeInt("priority", nPriority);
				tConditionList[i].FindChildTraverse("PriorityLabel").text = nPriority + "";
				hCondition.SetAttributeInt("priority", nConditionPriority);
				hCondition.FindChildTraverse("PriorityLabel").text = nConditionPriority + "";
				hContextPanel.FindChildTraverse("Conditions").MoveChildBefore(hCondition, tConditionList[i]);
				return true;
			}
		}
	}
	return false;
}

function OnAAMConditionMoveDown(hContextPanel, tArgs)
{
	var hCondition = tArgs.panel;
	var nPriority = hCondition.GetAttributeInt("priority", -1);
	var tConditionList = hContextPanel._tConditionList;
	for (var i = 0; i < tConditionList.length; i++)
	{
		if (tConditionList[i].visible)
		{
			var nConditionPriority = tConditionList[i].GetAttributeInt("priority", -1);
			if (nConditionPriority === nPriority + 1)
			{
				tConditionList[i].SetAttributeInt("priority", nPriority);
				tConditionList[i].FindChildTraverse("PriorityLabel").text = nPriority + "";
				hCondition.SetAttributeInt("priority", nConditionPriority);
				hCondition.FindChildTraverse("PriorityLabel").text = nConditionPriority + "";
				hContextPanel.FindChildTraverse("Conditions").MoveChildBefore(tConditionList[i], hCondition);
				return true;
			}
		}
	}
	return false;
}

function OnAAMConditionDelete(hContextPanel, tArgs)
{
	var hCondition = tArgs.panel;
	var nPriority = hCondition.GetAttributeInt("priority", -1);
	var nEntityIndex = hContextPanel.FindChild("AAM").GetAttributeInt("entindex", -1);
	var tConditionList = hContextPanel._tConditionList;
	for (var i = 0; i < tConditionList.length; i++)
	{
		if (tConditionList[i].visible)
		{
			var nConditionPriority = tConditionList[i].GetAttributeInt("priority", -1);
			if (tConditionList[i] === hCondition)
			{
				tConditionList.splice(i, 1);
				i--;
				continue;
			}
			else if (nConditionPriority > nPriority)
			{
				var nPanelPriority = tConditionList[i].GetAttributeInt("priority", -1);
				tConditionList[i].FindChildTraverse("PriorityLabel").text = (nPanelPriority - 1) + "";
				tConditionList[i].SetAttributeInt("priority", nPanelPriority - 1);
			}
		}
	}
	var tEntityConditionPanels = hContextPanel._tEntityConditionPanels[nEntityIndex];
	for (var i = 0; i < tEntityConditionPanels.length; i++)
	{
		if (tEntityConditionPanels[i] === hCondition)
		{
			tEntityConditionPanels.splice(i, 1);
			break;
		}
	}
	hCondition.DeleteAsync(0.0);
	return true;
}

function OnAAMButtonActivate(hContextPanel, tArgs)
{
	var szPanelID = tArgs.panel.id;
	if (szPanelID === "InsertButton")
		InsertAAMCondition(false);
	else if (szPanelID === "ClearButton")
		DeleteAAMConditionList(false);
	else if (szPanelID === "SaveButton")
		SaveAAMCondition();
	else if (szPanelID === "LoadButton")
		OpenAAMLoader();
	return true;
}

function LoadAAMLayout()
{
	var hContent = $("#AAM").FindChildTraverse("WindowMainContent");
	hContent.BLoadLayout("file://{resources}/layout/custom_game/aam/iw_aam_main.xml", false, false);
	var hTooltipHitbox = hContent.FindChildTraverse("TooltipHitbox");
	hTooltipHitbox.SetPanelEvent("onactivate", OnAAMStateActivate);
	hTooltipHitbox.SetPanelEvent("onmouseover", OnAAMStateMouseOver);
	hTooltipHitbox.SetPanelEvent("onmouseout", OnAAMStateMouseOut);
}

function LoadAAMTop()
{
	var hTitleBar = $("#AAM").FindChildTraverse("TitleBar");
	hTitleBar.style.width = "400px";
	hTitleBar.style.height = "46px";
	hTitleBar.BLoadLayout("file://{resources}/layout/custom_game/ui/iw_widget_stretchbox.xml", false, false);
	
	var hTitleText = $("#AAM").FindChildTraverse("TitleText");
	hTitleText.SetPanelEvent("ontextentrychange", OnAAMTitleTextUpdate);
	
	//TODO: Put this stuff in CSS
	var hInsertButton = CreateButton($("#AAM"), "InsertButton", "#iw_ui_aam_insert");
	hInsertButton.style.position = "54px 80px 0px";
	hInsertButton.style["pre-transform-scale2d"] = "0.75";
	
	var hClearButton = CreateButton($("#AAM"), "ClearButton", "#iw_ui_aam_clear");
	hClearButton.style.position = "54px 144px 0px";
	hClearButton.style["pre-transform-scale2d"] = "0.75";
	
	var hSaveButton = CreateButton($("#AAM"), "SaveButton", "#iw_ui_aam_save");
	hSaveButton.style.position = "706px 80px 0px";
	hSaveButton.style["pre-transform-scale2d"] = "0.75";
	
	var hLoadButton = CreateButton($("#AAM"), "LoadButton", "#iw_ui_aam_load");
	hLoadButton.style.position = "706px 144px 0px";
	hLoadButton.style["pre-transform-scale2d"] = "0.75";
}

function LoadAAMList()
{
	var hConditionBackground = $("#AAM").FindChildTraverse("Background");
	hConditionBackground.style.width = "974px";
	hConditionBackground.style.height = "494px";
	hConditionBackground.BLoadLayout("file://{resources}/layout/custom_game/ui/iw_widget_stretchbox.xml", false, false);
	
	var hConditionList = $("#AAM").FindChildTraverse("Conditions");
	CreateVerticalScrollbar($("#AAM").FindChildTraverse("ConditionContainer"), "AAMConditionsScrollbar", hConditionList);
}

function LoadAAMLoader()
{
	var hLoaderWindow = $.CreatePanel("Panel", GameUI.GetWindowRoot(), "AAMLoaderRoot");
	hLoaderWindow.BLoadLayout("file://{resources}/layout/custom_game/aam/iw_aam_loader.xml", false, false);
	$.GetContextPanel()._hLoaderWindow = hLoaderWindow;
}

(function()
{
	CreateWindowPanel($.GetContextPanel(), "AAM", "tactics", "#iw_ui_aam", false, true);
	
	LoadAAMLayout();
	LoadAAMTop();
	LoadAAMList();
	LoadAAMLoader();
	
	$.GetContextPanel()._tConditionList = [];
	$.GetContextPanel()._tEntityConditionPanels = {};
	
	CustomNetTables.SubscribeNetTableListener("aam", OnAAMNetTableUpdate);
	
	RegisterCustomEventHandler($.GetContextPanel(), "WindowOpen", OnAAMOpen);
	RegisterCustomEventHandler($.GetContextPanel(), "WindowClose", OnAAMClose);
	RegisterCustomEventHandler($.GetContextPanel(), "WindowPartyUpdate", OnAAMPartyUpdate);
	RegisterCustomEventHandler($.GetContextPanel(), "AAMStateUpdate", OnAAMStateUpdate);
	RegisterCustomEventHandler($.GetContextPanel(), "AAMLoadUpdate", OnAAMLoadUpdate);
	RegisterCustomEventHandler($.GetContextPanel(), "AAMLoadConditions", OnAAMLoadConditions);
	RegisterCustomEventHandler($.GetContextPanel(), "AAMConditionMoveUp", OnAAMConditionMoveUp);
	RegisterCustomEventHandler($.GetContextPanel(), "AAMConditionMoveDown", OnAAMConditionMoveDown);
	RegisterCustomEventHandler($.GetContextPanel(), "AAMConditionDelete", OnAAMConditionDelete);
	RegisterCustomEventHandler($.GetContextPanel(), "ButtonActivate", OnAAMButtonActivate);
	
	$.Schedule(0.03, UpdateAAMSelection);
})();