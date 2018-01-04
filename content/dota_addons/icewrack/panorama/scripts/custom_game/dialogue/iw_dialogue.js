"use strict";

var nScrollBufferHeight = 10000;

function OnDoNothing()
{
	//This function exists so that you can't click on anything in the background while the dialogue is happening
}

function OnDialogueOptionActivate(hContextPanel)
{
	var nOptionValue = hContextPanel.GetAttributeInt("option", -1);
	var nDialogueID = hContextPanel.GetAttributeInt("dialogue", -1);
	GameEvents.SendCustomGameEventToServer("iw_dialogue_option", { id:nDialogueID, option:nOptionValue });
}

function OnHotkeyDialogueOption(nIndex)
{
	var hDialoguePanel = GameUI.GetRoot().FindChildTraverse("Dialogue");
	if (hDialoguePanel.BHasClass("DialogueActive"))
	{
		var hOptionPanel = hDialoguePanel.FindChildTraverse("Option" + nIndex);
		if (hOptionPanel)
		{
			OnDialogueOptionActivate(hOptionPanel);
			return true;
		}
	}
}
for (var i = 1; i <= 10; i++)
{
	Game.RegisterHotkey((i % 10).toString(), OnHotkeyDialogueOption.bind(this, i));
}

function UpdateDialogueScrollOffset()
{
	var fContentHeightSum = 0.0;
	var tHistoryEntries = $("#HistoryContainer").Children();
	for (var k in tHistoryEntries)
	{
		var fContentHeight = tHistoryEntries[k].contentheight * GameUI.GetScaleRatio();
		if (fContentHeight === 0)
		{
			$.Schedule(0.03, UpdateDialogueScrollOffset);
			return;
		}
		//Add 16px to account for the margin-bottom
		fContentHeightSum += fContentHeight + 16.0;
	}
	
	//Subtract an additional 16px so that we have a bit of space from the border
	DispatchCustomEvent($("#TextGroup"), "PanelScrollOffset", { offset:(nScrollBufferHeight - fContentHeightSum - 16) });
	DispatchCustomEvent($("#TextGroup"), "PanelScroll", { value:-9999999 });
}

function OnDialogueUpdateNode(hContextPanel, tArgs)
{
	var tCurrentNode = tArgs.CurrentNode;
	var szLeftUnitName = Entities.GetUnitName(tCurrentNode.LeftID);
	var szRightUnitName = Entities.GetUnitName(tCurrentNode.RightID);
	
	hContextPanel.FindChildTraverse("LeftFramePortrait").SetImage("file://{images}/portraits/npc_dota_hero_axe.png");
	hContextPanel.FindChildTraverse("RightFramePortrait").SetImage("file://{images}/portraits/" + szRightUnitName + ".png");
	hContextPanel.FindChildTraverse("LeftFrameTitle").text = $.Localize("#" + szLeftUnitName);
	hContextPanel.FindChildTraverse("RightFrameTitle").text = $.Localize("#" + szRightUnitName);
	
	var tHistoryData = tArgs.History;
	var hHistoryContainer = hContextPanel.FindChildTraverse("HistoryContainer");
	for (var k in tHistoryData)
	{
		var hTextEntry = hHistoryContainer.FindChild("History" + k);
		if (!hTextEntry)
		{
			hTextEntry = $.CreatePanel("Panel", hHistoryContainer, "History" + k);
			hTextEntry.BLoadLayoutSnippet("DialogueTextEntrySnippet");
			hTextEntry.FindChild("Speaker").text = $.Localize("#" + Entities.GetUnitName(tHistoryData[k].Speaker));
			hTextEntry.FindChild("Text").text = $.Localize("#" + tHistoryData[k].Text);
		}
	}
	
	var tTextEntries = tCurrentNode.Text;
	var hTextContainer = hContextPanel.FindChildTraverse("TextContainer");
	hTextContainer.RemoveAndDeleteChildren();
	for (var k in tTextEntries)
	{
		var hTextEntry = $.CreatePanel("Panel", hTextContainer, "Text" + k);
		hTextEntry.BLoadLayoutSnippet("DialogueTextEntrySnippet");
		var nSpeakerEntindex = tTextEntries[k].Speaker;
		if (nSpeakerEntindex === 0)
		{
			hTextEntry.FindChild("Separator").visible = false;
			hTextEntry.AddClass("DialogueTextNarrator");
		}
		else
		{
			hTextEntry.FindChild("Speaker").text = $.Localize("#" + Entities.GetUnitName(tTextEntries[k].Speaker));
		}
		hTextEntry.FindChild("Text").text = $.Localize("#" + tTextEntries[k].Text);
	}
	
	var nOptionEntindex = tCurrentNode.OptionSpeaker;
	if (nOptionEntindex !== 0)
	{
		var hTextEntry = $.CreatePanel("Panel", hTextContainer, "OptionSpeakerText");
		hTextEntry.BLoadLayoutSnippet("DialogueTextEntrySnippet");
		hTextEntry.FindChild("Speaker").text = $.Localize("#" + Entities.GetUnitName(nOptionEntindex));
		hTextEntry.style["margin-bottom"] = "0px";
	}
	
	var nOptionIndex = 1;
	var tOptionEntries = tCurrentNode.Options;
	var hOptionsContainer = hContextPanel.FindChildTraverse("OptionsContainer");
	hOptionsContainer.RemoveAndDeleteChildren();
	for (var k in tOptionEntries)
	{
		var hOptionEntry = $.CreatePanel("Panel", hOptionsContainer, "Option" + nOptionIndex);
		hOptionEntry.BLoadLayoutSnippet("DialogueOptionEntrySnippet");
		hOptionEntry.FindChild("Number").text = (nOptionIndex++) + ".";
		hOptionEntry.FindChild("Text").text = $.Localize("#" + tOptionEntries[k]);
		hOptionEntry.SetAttributeInt("option", parseInt(k));
		hOptionEntry.SetAttributeInt("dialogue", hContextPanel.GetAttributeInt("dialogue", -1));
		if (Game.GetLocalPlayerID() === tArgs.PlayerID)
		{
			hOptionEntry.AddClass("DialogueOptionEntrySelectable");
			hOptionEntry.SetPanelEvent("onactivate", OnDialogueOptionActivate.bind(this, hOptionEntry));
		}
	}
	
	$.Schedule(0.03, UpdateDialogueScrollOffset)
	
	return true;
}

function OnDialogueShow(hContextPanel, tArgs)
{
	var hDialoguePanel = hContextPanel.FindChild("Dialogue");
	DispatchCustomEvent(GameUI.GetRoot(), "GlobalHideUI");
	hDialoguePanel.visible = true;
	hDialoguePanel.AddClass("DialogueActive");
	hDialoguePanel.RemoveClass("DialogueInactive");
	hDialoguePanel.style.opacity = "1.0";
	hDialoguePanel.FindChildTraverse("Filler").visible = true;
	return true;
}

function OnDialogueHide(hContextPanel, tArgs)
{
	var hDialoguePanel = hContextPanel.FindChild("Dialogue");
	DispatchCustomEvent(GameUI.GetRoot(), "GlobalShowUI");
	hDialoguePanel.AddClass("DialogueInactive");
	hDialoguePanel.RemoveClass("DialogueActive");
	hDialoguePanel.style.opacity = "0.0";
	hDialoguePanel.FindChildTraverse("Filler").visible = false;
	hContextPanel.FindChildTraverse("HistoryContainer").RemoveAndDeleteChildren();
	return true;
}

function OnDialogueUpdate(szTableName, szKey, tData)
{
	var nEntityIndex = $.GetContextPanel().GetAttributeInt("last_entindex", -1);
	var tListeners = tData.Listeners;
	if (tListeners && tListeners[nEntityIndex])
	{
		if (!$("#Dialogue").BHasClass("DialogueActive"))
		{
			DispatchCustomEvent($.GetContextPanel(), "DialogueShow");
		}
		$.GetContextPanel().SetAttributeInt("dialogue", parseInt(szKey));
		DispatchCustomEvent($.GetContextPanel(), "DialogueUpdateNode", tData);
	}
	else
	{
		if ($("#Dialogue").BHasClass("DialogueActive"))
		{
			DispatchCustomEvent($.GetContextPanel(), "DialogueHide");
		}
	}
}

function CheckDialogueEntity()
{
	var tSelectedEntities = Players.GetSelectedEntities(Players.GetLocalPlayer());
	if (tSelectedEntities.length > 0)
	{
		var nEntityIndex = tSelectedEntities[0];
		var nLastEntityIndex = $.GetContextPanel().GetAttributeInt("last_entindex", -1);
		if (nEntityIndex !== nLastEntityIndex)
		{
			var bIsEntityInDialogue = false;
			var tEntityDialogueData = null;
			var tDialogueList = CustomNetTables.GetAllTableValues("dialogue");
			for (var k in tDialogueList)
			{
				var tDialogueData = tDialogueList[k].value
				var tListeners = tDialogueData.Listeners;
				if (tListeners && tListeners[nEntityIndex])
				{
					bIsEntityInDialogue = true;
					tEntityDialogueData = tDialogueData;
					$.GetContextPanel().SetAttributeInt("dialogue", parseInt(tDialogueList[k].key));
					break;
				}
			}
			if (bIsEntityInDialogue)
			{
				if (!$("#Dialogue").BHasClass("DialogueActive"))
				{
					DispatchCustomEvent($.GetContextPanel(), "DialogueShow", tEntityDialogueData);
					DispatchCustomEvent($("#TextGroup"), "PanelScroll", { value:-9999999 });
				}
				DispatchCustomEvent($.GetContextPanel(), "DialogueUpdateNode", tEntityDialogueData);
			}
			else if (!bIsEntityInDialogue && $("#Dialogue").BHasClass("DialogueActive"))
			{
				DispatchCustomEvent($.GetContextPanel(), "DialogueHide");
			}
			$.GetContextPanel().SetAttributeInt("last_entindex", nEntityIndex);
		}
	}
	$.Schedule(0.1, CheckDialogueEntity);
}


(function()
{
	//GameEvents.Subscribe("iw_dialogue_start", OnDialogueStart);
	//GameEvents.Subscribe("iw_dialogue_option", OnDialogueOption);
	//GameEvents.Subscribe("iw_dialogue_end", OnDialogueEnd);
	//GameEvents.Subscribe("iw_dialogue_next", OnDialogueNext);
	//GameEvents.Subscribe("iw_dialogue_hide", OnDialogueHide);
	
	$.GetContextPanel()._hScrollbar = CreateVerticalScrollbar($("#Body"), "DialogueTextScrollbar", $("#TextGroup"));
	
	$("#ScrollBuffer").style.height = nScrollBufferHeight + "px";
	DispatchCustomEvent($("#TextGroup"), "PanelScrollOffset", { offset:nScrollBufferHeight });
	
	RegisterCustomEventHandler($.GetContextPanel(), "DialogueShow", OnDialogueShow);
	RegisterCustomEventHandler($.GetContextPanel(), "DialogueHide", OnDialogueHide);
	RegisterCustomEventHandler($.GetContextPanel(), "DialogueUpdateNode", OnDialogueUpdateNode);
	
	CustomNetTables.SubscribeNetTableListener("dialogue", OnDialogueUpdate);
	
	$.Schedule(0.1, CheckDialogueEntity);
	
})();