require("mechanics/effect_freeze")

function ApplyChill(hVictim, hAttacker, fDamagePercentHP)
	local fBaseDuration = 10.0 * fDamagePercentHP
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
			local fRealDuration = fBaseDuration * hVictim:GetSelfDebuffDuration() * hAttacker:GetOtherDebuffDuration() * hVictim:GetStatusEffectDurationMultiplier(IW_STATUS_EFFECT_CHILL)
			print(fRealDuration, hModifier:GetDuration(), hModifier:GetDuration() - hModifier:GetElapsedTime())
			if (hModifier:GetDuration() - hModifier:GetElapsedTime()) < fRealDuration then
				hModifier:ForceRefresh()
				hModifier:SetDuration(fBaseDuration, true)
			end
		else
			hModifier = AddModifier("status_chill", szModifierName, hVictim, hAttacker)
			if hModifier then hModifier:SetDuration(fBaseDuration, true) end
		end
	end
end