function ApplyMaim(hVictim, hAttacker, fDamagePercentHP)
	local fBaseDuration = 10.0 * fDamagePercentHP
	if fDamagePercentHP > 0.1 then
		local hModifier = hVictim:FindModifierByName("modifier_status_maim")
		if hModifier then
			local fRealDuration = fBaseDuration * hModifier:GetRealDurationMultiplier(hVictim)
			if (hModifier:GetDuration() - hModifier:GetElapsedTime()) < fRealDuration then
				hModifier:ForceRefresh()
				hModifier:SetDuration(fBaseDuration, true)
			end
		else
			hModifier = AddModifier("status_maim", "modifier_status_maim", hVictim, hAttacker)
			if hModifier then hModifier:SetDuration(fBaseDuration, true) end
		end
	end
end