"use strict";

function DoNothing()
{
	
}

function ClosePopup()
{
	$.GetContextPanel().visible = false;
	$.GetContextPanel().GetParent().SetFocus();
}

function OnWindowPopupOKLoad()
{
	//var hOKButton = CreateButton($("#PopupOK"), "OKButton", "#iw_ui_popup_ok", ClosePopup);
	//hOKButton.AddClass("OKButton");
}