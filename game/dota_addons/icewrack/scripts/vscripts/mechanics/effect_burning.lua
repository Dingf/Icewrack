function ApplyBurning(hTarget, hEntity, fDamagePercentHP)
	if fDamagePercentHP > 0.1 then
		local fBaseDuration = 5.0 * fDamagePercentHP
		local nUnitClass = IsValidExtendedEntity(hTarget) and hTarget:GetUnitClass() or IW_UNIT_CLASS_NORMAL
		local fBurnPercent = 2.5
		if nUnitClass == IW_UNIT_CLASS_ELITE then
			fBurnPercent = 1.0
		elseif nUnitClass == IW_UNIT_CLASS_BOSS or nUnitClass == IW_UNIT_CLASS_ACT_BOSS then
			fBurnPercent = 0.5
		end
		local hModifier = hTarget:FindModifierByName("modifier_status_burning")
		if hModifier then
			local fRealDuration = fBaseDuration * hModifier:GetRealDurationMultiplier(hTarget)
			if (hModifier:GetDuration() - hModifier:GetElapsedTime()) < fRealDuration then
				hModifier:ForceRefresh()
				hModifier:SetDuration(fBaseDuration, true)
			end
		else
			local tModifierArgs =
			{
				burn_damage = fBurnPercent,
				duration = fBaseDuration,
			}
			AddModifier("status_burning", "modifier_status_burning", hTarget, hEntity, tModifierArgs)
		end
	end
end