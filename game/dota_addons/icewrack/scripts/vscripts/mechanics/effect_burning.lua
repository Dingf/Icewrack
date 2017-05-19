function ApplyBurning(hVictim, hAttacker)
	local hModifier = hVictim:FindModifierByName("modifier_status_wet")
	if not hModifier then
		local nUnitClass = hVictim:GetUnitClass()
		local fBurnPercent = 5.0
		if nUnitClass == IW_UNIT_CLASS_ELITE then
			fBurnPercent = 2.0
		elseif nUnitClass == IW_UNIT_CLASS_BOSS or nUnitClass == IW_UNIT_CLASS_ACT_BOSS then
			fBurnPercent = 1.0
		end
		local hModifier = hVictim:FindModifierByName("modifier_status_burning")
		if hModifier then
			hModifier:ForceRefresh()
		else
			AddModifier("status_burning", "modifier_status_burning", hVictim, hAttacker, { burn_damage=fBurnPercent })
		end
	end
end