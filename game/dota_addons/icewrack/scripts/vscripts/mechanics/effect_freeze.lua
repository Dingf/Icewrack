function ApplyFreeze(hVictim, hAttacker, fDamagePercentHP)
	local fRealDuration = 10.0 * fDamagePercentHP
	if fDamagePercentHP > 0.05 then
		hVictim:RemoveModifierByName("modifier_status_wet")
		local hModifier = hVictim:FindModifierByName("modifier_status_frozen")
		if hModifier then
			if (hModifier:GetDuration() - hModifier:GetElapsedTime()) < fRealDuration then
				hModifier:SetDuration(fRealDuration + hModifier:GetElapsedTime(), true)
			end
		else
			hModifier = AddModifier("status_frozen", "modifier_status_frozen", hVictim, hAttacker)
			if hModifier then hModifier:SetDuration(fRealDuration, true) end
		end
	end
end