require("ext_entity")

function ApplyManaShield(hAttacker, hVictim, fDamageAmount)
	local fManaShieldPercent = hVictim:GetPropertyValue(IW_PROPERTY_MANASHIELD_PCT)/100.0
	if fManaShieldPercent > 0 then
		local fReductionAmount = math.min(1.0, fManaShieldPercent) * fDamageAmount
		local fReductionRatio = (fManaShieldPercent <= 1.0) and 1.0 or 1.0/fManaShieldPercent
		local fCurrentMana = hVictim:GetMana()
		fReductionAmount = math.min(fCurrentMana, fReductionAmount * fReductionRatio)
		hVictim:SetMana(fCurrentMana - fReductionAmount)
		
		--Set control point 1 orientation; values are in degrees
		--local nParticleID = ParticleManager:CreateParticle("particles/generic_gameplay/mana_shield_impact.vpcf", PATTACH_ROOTBONE_FOLLOW, hVictim)
		return fDamageAmount - fReductionAmount
	end
	return fDamageAmount
end