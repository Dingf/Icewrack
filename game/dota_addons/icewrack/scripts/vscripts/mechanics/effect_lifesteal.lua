require("timer")
require("ext_entity")

function RemoveLifesteal(hEntity, fAmount)
	hEntity._fLifestealRegen = hEntity._fLifestealRegen - fAmount
	hEntity:RefreshHealthRegen()
end

function ApplyLifesteal(hAttacker, hVictim, fDamageAmount)
	local fLifestealPercent = hAttacker:GetPropertyValue(IW_PROPERTY_LIFESTEAL_PCT)/100.0
	if fLifestealPercent > 0 then
		local fLifestealAmount = fLifestealPercent * fDamageAmount * 0.5 * hVictim:GetDrainMultiplier()
		hAttacker._fLifestealRegen = hAttacker._fLifestealRegen + fLifestealAmount
		CTimer(2.0, RemoveLifesteal, hAttacker, fLifestealAmount)
	end
	return fDamageAmount
end