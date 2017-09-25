function ApplyBurning(hVictim, hAttacker, fDamagePercentHP)
	local hModifier = hVictim:FindModifierByName("modifier_status_wet")
	if not hModifier and fDamagePercentHP > 0.1 then
		local fBaseDuration = 5.0 * fDamagePercentHP
		local nUnitClass = hVictim:GetUnitClass()
		local fBurnPercent = 5.0
		if nUnitClass == IW_UNIT_CLASS_ELITE then
			fBurnPercent = 2.0
		elseif nUnitClass == IW_UNIT_CLASS_BOSS or nUnitClass == IW_UNIT_CLASS_ACT_BOSS then
			fBurnPercent = 1.0
		end
		local hModifier = hVictim:FindModifierByName("modifier_status_burning")
		if hModifier then
			local fRealDuration = fBaseDuration * hVictim:GetSelfDebuffDuration() * hAttacker:GetOtherDebuffDuration() * hVictim:GetStatusEffectDurationMultiplier(IW_STATUS_EFFECT_BURNING)
			if (hModifier:GetDuration() - hModifier:GetElapsedTime()) < fRealDuration then
				hModifier:ForceRefresh()
				hModifier:SetDuration(fBaseDuration, true)
			end
		else
			hModifier = AddModifier("status_burning", "modifier_status_burning", hVictim, hAttacker, { burn_damage=fBurnPercent })
			if hModifier then hModifier:SetDuration(fBaseDuration, true) end
		end
	end
end