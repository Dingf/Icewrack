modifier_iw_axe_counter_helix = class({})

function modifier_iw_axe_counter_helix:DeclareExtEvents()
	local funcs =
	{
		[IW_MODIFIER_EVENT_ON_EXECUTE_ORDER] = 1,
	}
	return funcs
end

function modifier_iw_axe_counter_helix:OnCreated(args)
	if IsServer() then
		local hEntity = self:GetParent()
		local hCaster = self:GetCaster()
		local hAbility = self:GetAbility()
		local hDummy = CreateDummyUnit(hEntity:GetAbsOrigin(), hCaster:GetOwner(), hCaster:GetTeamNumber())
		hDummy:RemoveModifierByName("modifier_internal_dummy_buff")
		hDummy:AddNewModifier(hDummy, hAbility, "modifier_iw_axe_counter_helix_dummy_buff", {})
		hDummy:SetMoveCapability(DOTA_UNIT_CAP_MOVE_GROUND)
		hDummy:SetBaseMoveSpeed(hEntity:GetMoveSpeedModifier(hEntity:GetBaseMoveSpeed()))
		hDummy:SetHullRadius(hEntity:GetHullRadius())
		hDummy:SetThink(function()
			local target = hDummy._target
			if type(target) == "userdata" then
				hDummy:MoveToPosition(target)
			elseif IsInstanceOf(target, CDOTA_BaseNPC) then
				hDummy:MoveToNPC(target)
			end
			DebugDrawSphere(hDummy:GetAbsOrigin(), Vector(255, 0, 0), 128.0, 32.0, true, 0.1)
			CreateAvoidanceZone(hDummy:GetAbsOrigin(), hAbility:GetAOERadius() + 64.0, args.avoidance, 0.1)
			hEntity:SetAbsOrigin(hDummy:GetAbsOrigin())
			hEntity:SetForwardVector(hDummy:GetForwardVector())
			return 0.1
		end)
		self._hMoveDummy = hDummy
	end
end

function modifier_iw_axe_counter_helix:OnDestroy()
	if IsServer() then
		local hEntity = self:GetParent()
		hEntity:Stop()
		self._hMoveDummy:RemoveSelf()
	end
end

function modifier_iw_axe_counter_helix:OnExecuteOrder(args)
	local hDummy = self._hMoveDummy
	if args.OrderType == DOTA_UNIT_ORDER_MOVE_TO_POSITION or args.OrderType == DOTA_UNIT_ORDER_ATTACK_MOVE then
		hDummy._target = args.Position
		return false
	elseif args.OrderType == DOTA_UNIT_ORDER_MOVE_TO_TARGET or args.OrderType == DOTA_UNIT_ORDER_ATTACK_TARGET then
		hDummy._target = EntIndexToHScript(args.TargetIndex)
		return false
	end
end
