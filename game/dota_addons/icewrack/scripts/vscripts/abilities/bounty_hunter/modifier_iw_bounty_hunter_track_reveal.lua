modifier_iw_bounty_hunter_track_reveal = class({})

function modifier_iw_bounty_hunter_track_reveal:OnCreated(args)
	if IsServer() then
		local hEntity = self:GetParent()
		self:StartIntervalThink(0.1)
		AddFOWViewer(self:GetCaster():GetTeamNumber(), hEntity:GetAbsOrigin(), 16.0, 0.0, true)
	end
end

function modifier_iw_bounty_hunter_track_reveal:OnIntervalThink()
	local hEntity = self:GetParent()
	if IsServer() and hEntity:IsMoving() then
		AddFOWViewer(self:GetCaster():GetTeamNumber(), hEntity:GetAbsOrigin(), 16.0, 0.0, true)
	end
end