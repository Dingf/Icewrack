function ApplyWeaken(hVictim, hAttacker, fDamagePercentHP)
	local fRealDuration = 20.0 * fDamagePercentHP
	if fDamagePercentHP > 0.05 then
		local nUnitClass = hVictim:GetUnitClass()
		local szModifierName = "modifier_status_weaken"
		if nUnitClass == IW_UNIT_CLASS_ELITE then
			szModifierName = "modifier_status_weaken_elite"
		elseif nUnitClass == IW_UNIT_CLASS_BOSS or nUnitClass == IW_UNIT_CLASS_ACT_BOSS then
			szModifierName = "modifier_status_weaken_boss"
		end
		local hModifier = hVictim:FindModifierByName(szModifierName)
		if hModifier then
			if (hModifier:GetDuration() - hModifier:GetElapsedTime()) < fRealDuration then
				hModifier:SetDuration(fRealDuration + hModifier:GetElapsedTime(), true)
			end
		else
			hModifier = AddModifier("status_weaken", szModifierName, hVictim, hAttacker)
			if hModifier then hModifier:SetDuration(fRealDuration, true) end
		end
	end
end