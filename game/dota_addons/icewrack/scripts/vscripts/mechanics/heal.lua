require("ext_entity")

function HealTarget(self, keys)
	local hTarget = keys.target
	if IsValidExtendedEntity(hTarget) then
		local fAmount = keys.Amount
		if fAmount and type(fAmount) == "number" and fAmount > 0 then
			hTarget:ModifyHealth(hTarget:GetHealth() + (fAmount * hTarget:GetHealEffectiveness()), hTarget, true, 0)
		end
	end
end