require("mechanics/effect_shatter")

function ApplyBash(hTarget, hEntity, fDamagePercentHP)
	local fBaseDuration = 5.0 * fDamagePercentHP
	if fDamagePercentHP > 0.1 then
		local hModifier = hTarget:FindModifierByName("modifier_status_bash")
		if hModifier then
			local fRealDuration = fBaseDuration * hModifier:GetRealDurationMultiplier(hTarget)
			if (hModifier:GetDuration() - hModifier:GetElapsedTime()) < fRealDuration then
				hModifier:ForceRefresh()
				hModifier:SetDuration(fBaseDuration, true)
			end
		else
			local tModifierArgs =
			{
				duration = fBaseDuration,
			}
			AddModifier("status_bash", "modifier_status_bash", hTarget, hEntity, tModifierArgs)
		end
		TriggerShatter(hTarget)
	end
end