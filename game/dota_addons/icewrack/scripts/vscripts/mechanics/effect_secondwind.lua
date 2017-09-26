require("ext_entity")

function ApplySecondWind(hAttacker, hVictim, fDamageAmount)
	local fSecondWindPercent = hVictim:GetPropertyValue(IW_PROPERTY_SECONDWIND_PCT)/100.0 * (1.0 + hVictim:GetPropertyValue(IW_PROPERTY_SP_REGEN_PCT)/100.0)
	if fSecondWindPercent > 0 then
		local fStaminaAmount = fSecondWindPercent * fDamageAmount
		local fCurrentStamina = hVictim:GetStamina()
		hVictim:SetStamina(fCurrentStamina + fStaminaAmount)
	end
	return fDamageAmount
end