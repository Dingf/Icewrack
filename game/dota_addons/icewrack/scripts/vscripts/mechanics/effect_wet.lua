require("timer")
require("mechanics/status_effects")

function ApplyWet(hTarget, hEntity)
	hTarget:DispelStatusEffects(IW_STATUS_MASK_WARM + IW_STATUS_MASK_BURNING)
	local hModifier = hTarget:FindModifierByName("modifier_status_wet")
	local fBaseDuration = 30.0
	if hModifier then
		local fRealDuration = fBaseDuration * hModifier:GetRealDurationMultiplier(hTarget)
		if (hModifier:GetDuration() - hModifier:GetElapsedTime()) < fRealDuration then
			hModifier:ForceRefresh()
			hModifier:SetDuration(fBaseDuration, true)
		end
	else
		local tModifierArgs = 
		{
			fire_resist = 25,
			cold_resist = -25,
			lightning_resist = -25,
			duration = fBaseDuration,
		}
		AddModifier("status_wet", "modifier_status_wet", hTarget, hEntity, tModifierArgs)
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