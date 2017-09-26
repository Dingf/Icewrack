require("timer")
require("mechanics/status_effects")

function ApplyWet(hVictim, hAttacker)
	hVictim:DispelModifiers(IW_STATUS_MASK_BURNING)
	local hModifier = hVictim:FindModifierByName("modifier_status_wet")
	if hModifier then
		hModifier:ForceRefresh()
	else
		local tModifierArgs = 
		{
			fire_resist = 25,
			cold_resist = -25,
			lightning_resist = -25,
		}
		AddModifier("status_wet", "modifier_status_wet", hVictim, hAttacker, tModifierArgs)
	end
end

function OnTriggerWet(hTrigger, tArgs)
	local hEntity = tArgs.activator
	CTimer(0.0, function()
		if hTrigger:IsTouching(hEntity) then
			if hEntity:GetPropertyValue(IW_PROPERTY_STATUS_WET) > -100 then
				ApplyWet(hEntity, hEntity)
			end
			return 0.1
		end
	end)
end