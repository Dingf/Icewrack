modifier_status_maim = class({})

function ApplyMaim(hTarget, hEntity, fDamagePercentHP)
	if fDamagePercentHP > 0.1 then
		local fBaseDuration = 10.0 * fDamagePercentHP
		local nUnitClass = IsValidExtendedEntity(hTarget) and hTarget:GetUnitClass() or IW_UNIT_CLASS_NORMAL
		local fSlowFactor = 1.0
		if nUnitClass == IW_UNIT_CLASS_ELITE then
			fSlowFactor = 0.4
		elseif nUnitClass == IW_UNIT_CLASS_BOSS or nUnitClass == IW_UNIT_CLASS_ACT_BOSS then
			fMovementSpeed = 0.2
		end
	
		local hModifier = hTarget:FindModifierByName("modifier_status_maim")
		if hModifier then
			local fRealDuration = fBaseDuration * hModifier:GetRealDurationMultiplier(hTarget)
			if (hModifier:GetDuration() - hModifier:GetElapsedTime()) < fRealDuration then
				hModifier:ForceRefresh()
				hModifier:SetDuration(fBaseDuration, true)
			end
		else
			local tModifierArgs =
			{
				move_speed = -50.0 * fSlowFactor,
				attack_speed = -100.0 * fSlowFactor,
				duration = fBaseDuration,
			}
			AddModifier("status_maim", "modifier_status_maim", hTarget, hEntity, tModifierArgs)
		end
	end
end