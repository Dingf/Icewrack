require("mechanics/effect_freeze")

function ApplyChill(hVictim, hAttacker, fDamagePercentHP)
	if fDamagePercentHP > 0.1 then
		if hVictim:FindModifierByName("modifier_status_wet") then
			ApplyFreeze(hVictim, hAttacker, fDamagePercentHP)
			return
		end
	
		local fBaseDuration = 10.0 * fDamagePercentHP
		local nUnitClass = hVictim:GetUnitClass()
		local fChillFactor = 1.0
		if nUnitClass == IW_UNIT_CLASS_ELITE then
			fChillFactor = 0.4
		elseif nUnitClass == IW_UNIT_CLASS_BOSS or nUnitClass == IW_UNIT_CLASS_ACT_BOSS then
			fChillFactor = 0.2
		end
		local hModifier = hVictim:FindModifierByName("modifier_status_chill")
		if hModifier then
			local fRealDuration = fBaseDuration * hVictim:GetSelfDebuffDuration() * hAttacker:GetOtherDebuffDuration() * hVictim:GetStatusEffectDurationMultiplier(IW_STATUS_EFFECT_CHILL)
			if (hModifier:GetDuration() - hModifier:GetElapsedTime()) < fRealDuration then
				hModifier:ForceRefresh()
				hModifier:SetDuration(fBaseDuration, true)
			end
		else
			local tModifierArgs =
			{
				turn_rate = -100.0 * fChillFactor,
				cast_speed = -100.0 * fChillFactor,
				attack_speed = -100.0 * fChillFactor,
				move_speed = -50.0 * fChillFactor,
			}
			hModifier = AddModifier("status_chill", "modifier_status_chill", hVictim, hAttacker, tModifierArgs)
			if hModifier then hModifier:SetDuration(fBaseDuration, true) end
		end
	end
end