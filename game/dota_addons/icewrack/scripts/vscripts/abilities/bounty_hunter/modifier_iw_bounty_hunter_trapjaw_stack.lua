modifier_iw_bounty_hunter_trapjaw_stack = class({})

function modifier_iw_bounty_hunter_trapjaw_stack:OnCreated(args)
	if IsServer() then
		local hAbility = self:GetAbility()
		local nStackLimit = hAbility:GetSpecialValueFor("limit")
		self:SetStackCount(nStackLimit)
	end
end

