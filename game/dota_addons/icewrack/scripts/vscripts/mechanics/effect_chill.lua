require("mechanics/effect_freeze")

function ApplyChill(hVictim, hAttacker, fDamagePercentHP)
	local fRealDuration = 10.0 * fDamagePercentHP
	if fDamagePercentHP > 0.05 then
		local hWetModifier = hVictim:FindModifierByName("modifier_status_wet")
		if hWetModifier then
			ApplyFreeze(hVictim, hAttacker, fDamagePercentHP)
		end
		local nUnitClass = hVictim:GetUnitClass()
		local szModifierName = "modifier_status_chill"
		if nUnitClass == IW_UNIT_CLASS_ELITE then
			szModifierName = "modifier_status_chill_elite"
		elseif nUnitClass == IW_UNIT_CLASS_BOSS or nUnitClass == IW_UNIT_CLASS_ACT_BOSS then
			szModifierName = "modifier_status_chill_boss"
		end
		local hModifier = hVictim:FindModifierByName(szModifierName)
		if hModifier then
			if (hModifier:GetDuration() - hModifier:GetElapsedTime()) < fRealDuration then
				hModifier:SetDuration(fRealDuration + hModifier:GetElapsedTime(), true)
			end
		else
			hModifier = AddModifier("status_chill", szModifierName, hVictim, hAttacker)
			if hModifier then hModifier:SetDuration(fRealDuration, true) end
		end
	end
end