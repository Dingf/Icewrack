"use strict";

function ShowErrorMessage(hContextPanel, szErrorMessage, bNoLocalization)
{
	var hErrorMessage = hContextPanel.FindChild("ErrorMessage");
	hErrorMessage.RemoveClass("PopOutEffect");
	hErrorMessage.AddClass("PopOutEffect");
	hErrorMessage.FindChild("Text").text = bNoLocalization ? szErrorMessage : $.Localize(szErrorMessage);
}

function OnErrorMessageMouseEffect(hContextPanel, tArgs)
{
	hContextPanel.RemoveClass("PopOutEffect");
	return false;
}

(function()
{
	GameUI.ShowErrorMessage = ShowErrorMessage.bind(this, $.GetContextPanel());
	RegisterCustomEventHandler($("#ErrorMessage"), "MouseEvent", OnErrorMessageMouseEffect);
})();