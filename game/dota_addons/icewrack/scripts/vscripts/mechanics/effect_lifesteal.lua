require("timer")
require("ext_entity")

function RemoveLifesteal(hEntity, fAmount)
	hEntity:SetPropertyValue(IW_PROPERTY_HP_LIFESTEAL, hEntity:GetPropertyValue(IW_PROPERTY_HP_LIFESTEAL) - fAmount)
	hEntity:RefreshHealthRegen()
end

function ApplyLifesteal(hAttacker, hVictim, fDamageAmount)
	if IsValidExtendedEntity(hVictim) and not bit32.btest(hVictim:GetUnitFlags(), IW_UNIT_FLAG_CANNOT_DRAIN) then
		local fLifestealPercent = hAttacker:GetPropertyValue(IW_PROPERTY_LIFESTEAL_PCT)/100.0
		local fLifestealAmount = fLifestealPercent * fDamageAmount * 0.5
		if fLifestealAmount > 0 then
			hAttacker:SetPropertyValue(IW_PROPERTY_HP_LIFESTEAL, hAttacker:GetPropertyValue(IW_PROPERTY_HP_LIFESTEAL) + fLifestealAmount)
			CTimer(2.0, RemoveLifesteal, hAttacker, fLifestealAmount)
		end
	end
	return fDamageAmount
end