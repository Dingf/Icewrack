modifier_iw_bounty_hunter_trapjaw_stack = class({})

function modifier_iw_bounty_hunter_trapjaw_stack:OnCreated(args)
	local hAbility = self:GetAbility()
	hAbility._hStackModifier = self
	if IsServer() then
		local nStackLimit = hAbility:GetSpecialValueFor("limit")
		self:SetStackCount(nStackLimit)
	end
end

