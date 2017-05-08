"use strict";

function DispatchCustomEvent(hPanel, szEventName, tArgs)
{
	do
	{
		if (hPanel._tCustomEventHandlers && hPanel._tCustomEventHandlers[szEventName])
		{
			if (hPanel._tCustomEventHandlers[szEventName](hPanel, tArgs) === true)
				return true;
		}
		hPanel = hPanel.GetParent();
	}
	while (hPanel);
	return false;
}

function RegisterCustomEventHandler(hPanel, szEventName, hFunction)
{
	if (typeof hFunction === "function")
	{
		if (!hPanel._tCustomEventHandlers)
		{
			hPanel._tCustomEventHandlers = {}
		}
		
		hPanel._tCustomEventHandlers[szEventName] = hFunction;
	}
}

function UnregisterCustomEventHandler(hPanel, szEventName)
{
	if (hPanel._tCustomEventHandlers && hPanel._tCustomEventHandlers[szEventName])
	{
		delete hPanel._tCustomEventHandlers[szEventName];
	}
}