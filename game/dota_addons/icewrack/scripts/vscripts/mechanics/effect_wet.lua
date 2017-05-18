require("timer")
require("mechanics/status_effects")

function ApplyWet(hVictim, hAttacker)
	local tDispelledModifiers = {}
	for k,v in pairs(hVictim:FindAllModifiers()) do
		if IsValidExtendedModifier(v) and v:GetStatusEffect() == IW_STATUS_EFFECT_BURNING then
			table.insert(tDispelledModifiers, v)
		end
	end
	for k,v in pairs(tDispelledModifiers) do
		v:Destroy()
	end
	
	local hModifier = hVictim:FindModifierByName("modifier_status_wet")
	if hModifier then
		hModifier:ForceRefresh()
	else
		AddModifier("status_wet", "modifier_status_wet", hVictim, hAttacker, {})
	end
end

function OnTriggerWet(hTrigger, tArgs)
	local hEntity = tArgs.activator
	CTimer(0.0, function()
		if hTrigger:IsTouching(hEntity) then
			ApplyWet(hEntity, hEntity)
			return 0.1
		end
	end)
end