"use strict";

function UpdateSideBarIcon()
{
	var nHoverState = $.GetContextPanel().GetAttributeInt("hover", -1);
	if ($.GetContextPanel()._hRefPanel)
	{
		$.GetContextPanel()._bIsPanelActive = $.GetContextPanel()._hRefPanel._bRealVisible;
		if ((GameUI.IsMouseDown(0) && (nHoverState === 1)) || $.GetContextPanel()._bIsPanelActive)
		{
			$("#UpState").SetHasClass("IsActive", false);
			$("#DownState").visible = true;
			$("#UpState").visible = false;
		}
		else if (!GameUI.IsMouseDown(0))
		{
			$("#DownState").visible = false;
			$("#UpState").visible = true;
		}
		$("#IconTexture").SetHasClass("IsDown", $("#DownState").visible);
	}
	
	if ((nHoverState === 1) || $.GetContextPanel()._bIsPanelActive)
		$.Schedule(0.03, UpdateSideBarIcon);
}

function OnSidebarIconActivate()
{
	$("#DownState").visible = true;
	$("#UpState").visible = false;
	$("#IconTexture").SetHasClass("IsDown", true);
	DispatchCustomEvent($.GetContextPanel(), "SidebarIconActivate", { panel:$.GetContextPanel() });
}

function OnSidebarIconMouseOver()
{
	$.GetContextPanel().SetAttributeInt("hover", 1);
	$("#UpState").SetHasClass("IsActive", !$("#DownState").visible);
	$.Schedule(0.1, function()
	{
		if ($.GetContextPanel().GetAttributeInt("hover", -1) === 1)
		{
			$.DispatchEvent("DOTAShowTextTooltip", $.GetContextPanel().GetAttributeString("hover_text", ""));
		}
	});
	$.Schedule(0.03, UpdateSideBarIcon);
}

function OnSidebarIconMouseOut()
{
	$.GetContextPanel().SetAttributeInt("hover", 0);
	$("#UpState").SetHasClass("IsActive", false);
	if (!$.GetContextPanel()._bIsPanelActive)
	{
		$("#DownState").visible = false;
		$("#UpState").visible = true;
		$("#IconTexture").SetHasClass("IsDown", false);
	}
	$.DispatchEvent("DOTAHideTextTooltip");
}

function OnSidebarIconLoad()
{
	$("#DownState").visible = false;
	$.GetContextPanel().SetAttributeInt("hover", 0);
	
	$.Schedule(0.03, UpdateSideBarIcon);
}