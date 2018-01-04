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
				if (Game.GetAllPlayerIDs().length == 1)
				{
					GameEvents.SendCustomGameEventToServer("iw_pause_override", {});
				}
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
				if (Game.GetAllPlayerIDs().length == 1)
				{
					GameEvents.SendCustomGameEventToServer("iw_unpause_override", {});
				}
			}
		}
	}
}


Game.RegisterHotkey("SPACE", function()
{
	//TODO: Make this work for any player that has pause privileges
	if (Game.GetLocalPlayerID() === 0)
	{
		GameEvents.SendCustomGameEventToServer("iw_pause_hotkey", {});
		return true;
	}
});

(function()
{
	$("#ScreenFill").style.opacity = "0.0";
	GameUI.SetPauseScreen = SetPauseScreenState;
})();