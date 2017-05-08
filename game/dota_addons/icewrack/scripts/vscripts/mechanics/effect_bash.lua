require("mechanics/effect_shatter")

function ApplyBash(hVictim, hAttacker, fDamagePercentHP)
	local fRealDuration = 5.0 * fDamagePercentHP
	if fDamagePercentHP > 0.05 then
		local hModifier = hVictim:FindModifierByName("modifier_status_bash")
		if hModifier then
			if (hModifier:GetDuration() - hModifier:GetElapsedTime()) < fRealDuration then
				hModifier:SetDuration(fRealDuration, true)
			end
		else
			hModifier = AddModifier("status_bash", "modifier_status_bash", hVictim, hAttacker)
			if hModifier then hModifier:SetDuration(fRealDuration, true) end
		end
		TriggerShatter(hVictim)
	end
end