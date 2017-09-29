function ApplyWarm(hTarget, hEntity)
	hTarget:DispelStatusEffects(IW_STATUS_MASK_WET + IW_STATUS_MASK_CHILLED + IW_STATUS_MASK_FROZEN)
	local hModifier = hTarget:FindModifierByName("modifier_status_warm")
	local fBaseDuration = 30.0
	if hModifier then
		local fRealDuration = fBaseDuration * hModifier:GetRealDurationMultiplier(hTarget)
		if (hModifier:GetDuration() - hModifier:GetElapsedTime()) < fRealDuration then
			hModifier:ForceRefresh()
			hModifier:SetDuration(fBaseDuration, true)
		end
	else
		local tModifierArgs = 
		{
			cold_resist = 25,
			mana_regen = 50,
			stamina_regen = 50,
			duration = fBaseDuration,
		}
		AddModifier("status_warm", "modifier_status_warm", hTarget, hEntity, tModifierArgs)
	end
end