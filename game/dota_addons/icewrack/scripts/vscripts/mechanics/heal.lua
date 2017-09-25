require("ext_entity")

function HealTarget(hEntity, hTarget, fHealAmount)
	if IsValidExtendedEntity(hEntity) and IsValidExtendedEntity(hTarget) and type(fHealAmount) == "number" then
		fHealAmount = math.max(fHealAmount, 0)
		local tHealTable = 
		{
			healer = hEntity,
			target = hTarget,
			amount = fHealAmount,
		}
		hTarget:TriggerExtendedEvent(IW_MODIFIER_EVENT_ON_HEAL, tHealTable)
		if tHealTable.amount > 0 then
			hTarget:ModifyHealth(hTarget:GetHealth() + (tHealTable.amount * hTarget:GetHealEffectiveness()), hTarget, true, 0)
		end
	end
end