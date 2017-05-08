"use strict";

function OnDialogueOptionScroll(hContextPanel, tArgs)
{
	if (tArgs.value)
	{
		if (tArgs.immediate)
		{
			hContextPanel._fCurrentOffset = tArgs.value;
			$("#TextContainer").style.position = "0px " + tArgs.value + "px 0px";
		}
		hContextPanel._fTargetOffset = tArgs.value;
	}
	return true;
}

function OnDialogueOptionActivate(hContextPanel, tArgs)
{
	var nNodeID = hContextPanel.GetAttributeInt("id", -1);
	GameEvents.SendCustomGameEventToServer("iw_dialogue_option", { value:tArgs.value, text:nNodeID + "" });
}

function OnDialogueStart(tArgs)
{
	DispatchCustomEvent(GameUI.GetRoot(), "GlobalHideUI");
	$("#Fill").visible = true;
	$("#TextContainer").RemoveAndDeleteChildren();
	$.GetContextPanel().SetAttributeInt("id", tArgs.id);
	
	var szEntityName = Entities.GetUnitName(tArgs.entindex);
	$("#Portrait").SetImage("file://{images}/portraits/" + szEntityName + ".png");
	$("#Name").text = $.Localize("#" + szEntityName);
	$("#Text").text = $.Localize("#" + tArgs.text);
}

function OnDialogueOption(tArgs)
{
	CreateDialogueOption($("#TextContainer"), "DropdownLabel", tArgs.value, $.Localize("#" + tArgs.text));
}

function OnDialogueEnd(tArgs)
{
	$("#Dialogue").visible = true;
	if (!$("#Dialogue").BHasClass("DialogueActive"))
	{
		$("#Dialogue").AddClass("DialogueActive");
		$("#Dialogue").RemoveClass("DialogueInactive");
		$("#Dialogue").style.opacity = "1.0";
	}
}

function OnDialogueNext(tArgs)
{
	DispatchCustomEvent(GameUI.GetRoot(), "GlobalShowUI");
}

function OnDialogueHide(tArgs)
{
	$("#Dialogue").AddClass("DialogueInactive");
	$("#Dialogue").RemoveClass("DialogueActive");
	$("#Dialogue").style.opacity = "0.0";
	$("#Fill").visible = false;
	
	DispatchCustomEvent(GameUI.GetRoot(), "GlobalShowUI");
}

function UpdateDialogue()
{
	var fCurrentOffset = $.GetContextPanel()._fCurrentOffset;
	var fTargetOffset = $.GetContextPanel()._fTargetOffset;
	if (fCurrentOffset !== fTargetOffset)
	{
		var fDiff = fTargetOffset - fCurrentOffset;
		if (Math.abs(fDiff) > 1.0)
			fDiff *= 0.15;
		
		$.GetContextPanel()._fCurrentOffset = fCurrentOffset + fDiff;
		$("#TextContainer").style.position = "0px " + $.GetContextPanel()._fCurrentOffset + "px 0px";
	}
	$.Schedule(0.03, UpdateDialogue);
}

(function()
{
	$.GetContextPanel()._fCurrentOffset = 0;
	$.GetContextPanel()._fTargetOffset = 0;
	RegisterCustomEventHandler($.GetContextPanel(), "DialogueOptionScroll", OnDialogueOptionScroll);
	RegisterCustomEventHandler($.GetContextPanel(), "DialogueOptionActivate", OnDialogueOptionActivate);
	
	GameEvents.Subscribe("iw_dialogue_start", OnDialogueStart);
	GameEvents.Subscribe("iw_dialogue_option", OnDialogueOption);
	GameEvents.Subscribe("iw_dialogue_end", OnDialogueEnd);
	GameEvents.Subscribe("iw_dialogue_next", OnDialogueNext);
	GameEvents.Subscribe("iw_dialogue_hide", OnDialogueHide);
	
	UpdateDialogue();
})();