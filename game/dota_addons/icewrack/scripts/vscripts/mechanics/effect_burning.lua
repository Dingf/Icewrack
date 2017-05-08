function ApplyBurning(hVictim, hAttacker)
	local hModifier = hVictim:FindModifierByName("modifier_status_wet")
	if not hModifier then
		local nUnitClass = hVictim:GetUnitClass()
		local szModifierName = "modifier_status_burning"
		if nUnitClass == IW_UNIT_CLASS_ELITE then
			szModifierName = "modifier_status_burning_elite"
		elseif nUnitClass == IW_UNIT_CLASS_BOSS or nUnitClass == IW_UNIT_CLASS_ACT_BOSS then
			szModifierName = "modifier_status_burning_boss"
		end
		local hModifier = hVictim:FindModifierByName(szModifierName)
		if hModifier then
			hModifier:ForceRefresh()
		else
			AddModifier("status_burning", szModifierName, hVictim, hAttacker)
		end
	end
end