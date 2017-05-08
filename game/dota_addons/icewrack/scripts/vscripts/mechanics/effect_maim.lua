function ApplyMaim(hVictim, hAttacker, fDamagePercentHP)
	local fRealDuration = 10.0 * fDamagePercentHP
	if fDamagePercentHP > 0.05 then
		local hModifier = hVictim:FindModifierByName("modifier_status_maim")
		if hModifier then
			if (hModifier:GetDuration() - hModifier:GetElapsedTime()) < fRealDuration then
				hModifier:SetDuration(fRealDuration, true)
			end
		else
			hModifier = AddModifier("status_maim", "modifier_status_maim", hVictim, hAttacker)
			if hModifier then hModifier:SetDuration(fRealDuration, true) end
		end
	end
end