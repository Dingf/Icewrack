"use strict";

var fEpsilon = 1.0;
var fCurrentYaw = 0;
var fYawOffset = 0;
var bInstantYaw = false;

function SetCameraYaw()
{
	if ((Math.abs(fYawOffset) < fEpsilon) || bInstantYaw)
	{
		fCurrentYaw += fYawOffset;
		fYawOffset = 0;
	}
	else
	{
		var fStep = fYawOffset * 0.5;
		if (Math.abs(fStep) < fEpsilon)
		{
			fStep = (fStep < 0) ? -fEpsilon : fEpsilon;
		}
		
		fCurrentYaw += fStep;
		fYawOffset -= fStep;
	}
	
	fCurrentYaw = fCurrentYaw % 360;
	if (fCurrentYaw < 0)
		fCurrentYaw += 360;
	
	GameUI.SetCameraYaw(fCurrentYaw);
	GameUI._fCameraYaw = fCurrentYaw;
	
	if (fYawOffset !== 0)
		$.Schedule(0.03, SetCameraYaw);
}

function OnCameraMouseEvent(hContextPanel, tArgs)
{
	if (tArgs.event === "wheeled")
	{
		if (GameUI.IsShiftDown())
		{
			fYawOffset = tArgs.value * 45.0;
			fYawOffset -= fCurrentYaw % 45;
			bInstantYaw = true;
			SetCameraYaw();
		}
		else
		{
			fYawOffset += tArgs.value * 10.0;
			bInstantYaw = false;
			SetCameraYaw();
		}
		return true;
	}
	return false;
}

(function()
{
	var tMapInfo = CustomNetTables.GetTableValue("game", "map");
	if (tMapInfo.override !== 1)
	{
		GameUI._fCameraYaw = 0;
		GameUI.SetCameraPitchMin(60.0);
		GameUI.SetCameraPitchMax(60.0);
		
		RegisterCustomEventHandler($("#Camera"), "MouseEvent", OnCameraMouseEvent);
	}
})();