modifier_iw_axe_culling_blade = class({})

function modifier_iw_axe_culling_blade:DeclareExtEvents()
	local funcs =
	{
		[IW_MODIFIER_EVENT_ON_PRE_ATTACK_DAMAGE] = 10,
	}
	return funcs
end

function modifier_iw_axe_culling_blade:OnPreAttackDamage(args)
	local hTarget = args.target
	local hEntity = self:GetParent()
	
	if hTarget and hEntity then
		local hAbility = self:GetAbility()
		local fTargetHealth = hTarget:GetHealth()/hTarget:GetMaxHealth()
		local fThreshold = hAbility:GetSpecialValueFor("threshold")/100.0
		local fDamageBonus = hAbility:GetSpecialValueFor("damage") * (1.0 - fTargetHealth)
		if fTargetHealth < fThreshold then
			fDamageBonus = fDamageBonus * 2.0
		end
		for k,v in pairs(args.damage) do
			if k >= IW_DAMAGE_TYPE_CRUSH and k <= IW_DAMAGE_TYPE_PIERCE then
				args.damage[k].min = v.min * (1.0 + fDamageBonus)
				args.damage[k].max = v.max * (1.0 + fDamageBonus)
			end
		end
	end
end
