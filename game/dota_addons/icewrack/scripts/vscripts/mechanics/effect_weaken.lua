function ApplyWeaken(hVictim, hAttacker, fDamagePercentHP)
	local fRealDuration = 20.0 * fDamagePercentHP
	if fBaseDuration > 0.05 then
		local nUnitClass = hVictim:GetUnitClass()
		local szModifierName = "modifier_status_weaken"
		if nUnitClass == IW_UNIT_CLASS_ELITE then
			szModifierName = "modifier_status_weaken_elite"
		elseif nUnitClass == IW_UNIT_CLASS_BOSS or nUnitClass == IW_UNIT_CLASS_ACT_BOSS then
			szModifierName = "modifier_status_weaken_boss"
		end
		local hModifier = hVictim:FindModifierByName(szModifierName)
		if hModifier then
			local fRealDuration = fBaseDuration * hModifier:GetRealDurationMultiplier(hVictim)
			if (hModifier:GetDuration() - hModifier:GetElapsedTime()) < fRealDuration then
				hModifier:ForceRefresh()
				hModifier:SetDuration(fBaseDuration, true)
			end
		else
			hModifier = AddModifier("status_weaken", szModifierName, hVictim, hAttacker)
			if hModifier then hModifier:SetDuration(fBaseDuration, true) end
		end
	end
end