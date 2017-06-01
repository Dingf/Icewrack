modifier_iw_bounty_hunter_jinada = class({})

function modifier_iw_bounty_hunter_jinada:DeclareExtEvents()
	local funcs =
	{
		[IW_MODIFIER_EVENT_ON_PRE_ATTACK_DAMAGE] = 100,
	}
	return funcs
end

function modifier_iw_bounty_hunter_jinada:OnPreAttackDamage(args)
	local hTarget = args.target
	local hEntity = self:GetParent()
	
	if hTarget and hEntity then
		local vTargetForward = hTarget:GetForwardVector()
		local fTargetOffset = math.atan2(vTargetForward[2], vTargetForward[1])
		local vTargetEntityVector = hEntity:GetAbsOrigin() - hTarget:GetAbsOrigin()
		local fAngleOffset = math.atan2(vTargetEntityVector[2], vTargetEntityVector[1]) - fTargetOffset
	
		if fAngleOffset > 3.14159265 then
			fAngleOffset = fAngleOffset - 6.28318531
		elseif fAngleOffset < -3.14159265 then
			fAngleOffset = fAngleOffset + 6.28318531
		end
		
		if math.abs(fAngleOffset) >= 2.09439510239 then
			args.ForceCrit = true
		end
	end
end