"use strict";

function ShowErrorMessage(hContextPanel, szErrorMessage, bNoLocalization)
{
	var hErrorMessage = hContextPanel.FindChild("ErrorMessage");
	hErrorMessage.RemoveClass("ErrorMessageHidden");
	hErrorMessage.RemoveClass("PopOutEffect");
	hErrorMessage.AddClass("PopOutEffect");
	hErrorMessage.FindChild("Text").text = bNoLocalization ? szErrorMessage : $.Localize(szErrorMessage);
}

function OnErrorMessageMouseEffect(hContextPanel, tArgs)
{
	if (tArgs.event !== "wheeled")
	{
		hContextPanel.RemoveClass("PopOutEffect");
		hContextPanel.AddClass("ErrorMessageHidden");
	}
	return false;
}



(function()
{
	$("#ErrorMessage").AddClass("ErrorMessageHidden");
	GameUI.ShowErrorMessage = ShowErrorMessage.bind(this, $.GetContextPanel());
	RegisterCustomEventHandler($("#ErrorMessage"), "MouseEvent", OnErrorMessageMouseEffect);
})();