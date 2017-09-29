if not modifier_status_decay then

modifier_status_decay = class({})

function modifier_status_decay:DeclareExtEvents()
	local funcs =
	{
		[IW_MODIFIER_EVENT_ON_HEAL] = 1,
	}
	return funcs
end

function modifier_status_decay:OnHealingReceived(args)
	local fAmount = args.amount
	if fAmount > 0 then
		local tDamageTable =
		{
			target = args.target,
			attacker = args.healer,
			damage =
			{
				[IW_DAMAGE_TYPE_DEATH] =
				{
					min = fAmount,
					max = fAmount,
				}
			}
		}
		DealSecondaryDamage(nil, tDamageTable)
		args.amount = 0
	end
end

else

function ApplyDecay(hTarget, hEntity, fDamagePercentHP)
	if fDamagePercentHP > 0.1 then
		local fBaseDuration = 10.0 * fDamagePercentHP
		local nUnitClass = hTarget:GetUnitClass()
		local fHealthPercent = -25.0
		local fHealEffectiveness = -100.0
		if nUnitClass == IW_UNIT_CLASS_ELITE then
			fHealthPercent = -10.0
		elseif nUnitClass == IW_UNIT_CLASS_BOSS or nUnitClass == IW_UNIT_CLASS_ACT_BOSS then
			fHealthPercent = -5.0
		end
		local hModifier = hTarget:FindModifierByName("modifier_status_decay")
		if hModifier then
			local fRealDuration = fBaseDuration * hModifier:GetRealDurationMultiplier(hTarget)
			if (hModifier:GetDuration() - hModifier:GetElapsedTime()) < fRealDuration then
				hModifier:ForceRefresh()
				hModifier:SetDuration(fBaseDuration, true)
			end
		else
			local tModifierArgs =
			{
				health_percent = fHealthPercent/100.0,
				heal_effectiveness = fHealEffectiveness,
				duration = fBaseDuration,
			}
			AddModifier("status_decay", "modifier_status_decay", hTarget, hEntity, tModifierArgs)
		end
	end
end

end