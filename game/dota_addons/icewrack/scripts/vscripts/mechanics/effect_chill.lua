require("mechanics/effect_freeze")

function ApplyChill(hTarget, hEntity, fDamagePercentHP)
	if fDamagePercentHP > 0.1 then
		if hTarget:HasStatusEffect(IW_STATUS_MASK_WET) then
			ApplyFreeze(hTarget, hEntity, fDamagePercentHP)
			return
		end
		
		hTarget:DispelStatusEffects(IW_STATUS_MASK_WARM)
	
		local fBaseDuration = 10.0 * fDamagePercentHP
		local nUnitClass = IsValidExtendedEntity(hTarget) and hTarget:GetUnitClass() or IW_UNIT_CLASS_NORMAL
		local fChillFactor = 1.0
		if nUnitClass == IW_UNIT_CLASS_ELITE then
			fChillFactor = 0.4
		elseif nUnitClass == IW_UNIT_CLASS_BOSS or nUnitClass == IW_UNIT_CLASS_ACT_BOSS then
			fChillFactor = 0.2
		end
		local hModifier = hTarget:FindModifierByName("modifier_status_chill")
		if hModifier then
			local fRealDuration = fBaseDuration * hModifier:GetRealDurationMultiplier(hTarget)
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
				duration = fBaseDuration,
			}
			AddModifier("status_chill", "modifier_status_chill", hTarget, hEntity, tModifierArgs)
		end
	end
end