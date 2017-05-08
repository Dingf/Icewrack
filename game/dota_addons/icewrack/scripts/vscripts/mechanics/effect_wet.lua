require("timer")
require("mechanics/status_effects")

function ApplyWet(hVictim, hAttacker)
	for k,v in pairs(hVictim._tExtModifierTable) do
		if v:GetStatusEffect() == IW_STATUS_EFFECT_BURNING then
			v:Destroy()
		end
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