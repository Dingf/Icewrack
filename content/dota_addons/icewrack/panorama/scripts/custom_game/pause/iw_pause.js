"use strict";

var nPauseLevel = 0;
function SetPauseScreenState(bState)
{
	if (typeof(bState) === "boolean")
	{
		if (bState)
		{
			nPauseLevel = nPauseLevel + 1;
			if (nPauseLevel === 1)
			{
				$("#ScreenFill").AddClass("FillActive");
				$("#ScreenFill").RemoveClass("FillInactive");
				$("#ScreenFill").style.opacity = "1.0";
				GameEvents.SendCustomGameEventToServer("iw_pause", {});
			}
		}
		else
		{
			nPauseLevel = nPauseLevel - 1;
			if (nPauseLevel === 0)
			{
				$("#ScreenFill").AddClass("FillInactive");
				$("#ScreenFill").RemoveClass("FillActive");
				$("#ScreenFill").style.opacity = "0.0";
				GameEvents.SendCustomGameEventToServer("iw_unpause", {});
			}
		}
	}
}

(function()
{
	$("#ScreenFill").style.opacity = "0.0";
	GameUI.SetPauseScreen = SetPauseScreenState;
})();