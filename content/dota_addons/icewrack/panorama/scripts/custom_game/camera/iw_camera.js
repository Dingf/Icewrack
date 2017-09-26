"use strict";

function SetCameraYaw(hContextPanel)
{
	var fCurrentYaw = GameUI._fCameraYaw;
	var fYawOffset = hContextPanel._fYawOffset;
	var fYawEpsilon = hContextPanel._fYawEpsilon;
	if (Math.abs(fYawOffset) < fYawEpsilon)
	{
		fCurrentYaw += fYawOffset;
		fYawOffset = 0;
	}
	else
	{
		var fStep = fYawOffset * 0.5;
		if (Math.abs(fStep) < fYawEpsilon)
		{
			fStep = (fStep < 0) ? -fYawEpsilon : fYawEpsilon;
		}
		
		fCurrentYaw += fStep;
		fYawOffset -= fStep;
	}
	
	fCurrentYaw = fCurrentYaw % 360;
	if (fCurrentYaw < 0)
		fCurrentYaw += 360;
	
	GameUI.SetCameraYaw(fCurrentYaw);
	GameUI._fCameraYaw = fCurrentYaw;
	hContextPanel._fYawOffset = fYawOffset;
	
	if (fYawOffset !== 0)
		$.Schedule(0.03, SetCameraYaw.bind(this, hContextPanel));
}

function SetCameraZoom(hContextPanel)
{
	var fCurrentZoom = GameUI._fCameraZoom;
	var fZoomOffset = hContextPanel._fZoomOffset;
	var fZoomEpsilon = hContextPanel._fZoomEpsilon;
	
	if ((fCurrentZoom + fZoomOffset) > hContextPanel._fZoomMax)
	{
		fZoomOffset = hContextPanel._fZoomMax - fCurrentZoom;
	}
	else if ((fCurrentZoom + fZoomOffset) < hContextPanel._fZoomMin)
	{
		fZoomOffset = hContextPanel._fZoomMin - fCurrentZoom;
	}
	
	if (Math.abs(fZoomOffset) < fZoomEpsilon)
	{
		fCurrentZoom += fZoomOffset;
		fZoomOffset = 0;
	}
	else
	{
		var fStep = fZoomOffset * 0.5;
		if (Math.abs(fStep) < fZoomEpsilon)
		{
			fStep = (fStep < 0) ? -fZoomEpsilon : fZoomEpsilon;
		}
		
		fCurrentZoom += fStep;
		fZoomOffset -= fStep;
	}
	
	GameUI.SetCameraDistance(fCurrentZoom);
	GameUI._fCameraZoom = fCurrentZoom;
	hContextPanel._fZoomOffset = fZoomOffset;
	
	if (fZoomOffset !== 0)
		$.Schedule(0.03, SetCameraZoom.bind(this, hContextPanel));
}

function OnCameraMouseEvent(hContextPanel, tArgs)
{
	if (tArgs.event === "wheeled")
	{
		if (GameUI.IsShiftDown())
		{
			hContextPanel._fYawOffset += tArgs.value * 15.0;
			SetCameraYaw(hContextPanel);
		}
		else
		{
			hContextPanel._fZoomOffset -= tArgs.value * 25.0;
			SetCameraZoom(hContextPanel);
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
		var hCamera = $("#Camera");
		
		hCamera._fZoomMin = 600.0;
		hCamera._fZoomMax = 1800.0;
		
		hCamera._fZoomEpsilon = 8.0;
		hCamera._fZoomOffset = 0.0;
		
		hCamera._fYawEpsilon = 1.0;
		hCamera._fYawOffset = 0.0;
		
		GameUI._fCameraYaw = 0;
		GameUI._fCameraZoom = 1400.0;
		GameUI.SetCameraPitchMin(60);
		GameUI.SetCameraPitchMax(60);
		GameUI.SetCameraDistance(1400.0);
		
		RegisterCustomEventHandler(hCamera, "MouseEvent", OnCameraMouseEvent);
	}
})();