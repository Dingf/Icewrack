function ApplyFreeze(hTarget, hEntity, fDamagePercentHP)
	local fBaseDuration = 10.0 * fDamagePercentHP
	if fDamagePercentHP > 0.1 then
		hTarget:DispelStatusEffects(IW_STATUS_MASK_WET + IW_STATUS_MASK_WARM + IW_STATUS_MASK_BURNING)
		local hModifier = hTarget:FindModifierByName("modifier_status_frozen")
		if hModifier then
			local fRealDuration = fBaseDuration * hModifier:GetRealDurationMultiplier(hTarget)
			if (hModifier:GetDuration() - hModifier:GetElapsedTime()) < fRealDuration then
				hModifier:ForceRefresh()
				hModifier:SetDuration(fBaseDuration, true)
			end
		else
			local tModifierArgs =
			{
				duration = fBaseDuration,
			}
			AddModifier("status_frozen", "modifier_status_frozen", hTarget, hEntity, tModifierArgs)
		end
	end
end