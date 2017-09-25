function ApplyFreeze(hVictim, hAttacker, fDamagePercentHP)
	local fBaseDuration = 10.0 * fDamagePercentHP
	if fDamagePercentHP > 0.1 then
		hVictim:RemoveModifierByName("modifier_status_wet")
		local hModifier = hVictim:FindModifierByName("modifier_status_frozen")
		if hModifier then
			local fRealDuration = fBaseDuration * hModifier:GetRealDurationMultiplier(hVictim)
			if (hModifier:GetDuration() - hModifier:GetElapsedTime()) < fRealDuration then
				hModifier:ForceRefresh()
				hModifier:SetDuration(fBaseDuration, true)
			end
		else
			hModifier = AddModifier("status_frozen", "modifier_status_frozen", hVictim, hAttacker)
			if hModifier then hModifier:SetDuration(fBaseDuration, true) end
		end
	end
end