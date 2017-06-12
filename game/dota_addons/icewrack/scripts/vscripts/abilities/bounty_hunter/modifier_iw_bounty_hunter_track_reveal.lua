modifier_iw_bounty_hunter_track_reveal = class({})

function modifier_iw_bounty_hunter_track_reveal:OnCreated(args)
	if IsServer() then
		local hEntity = self:GetParent()
		self:StartIntervalThink(0.1)
		AddFOWViewer(self:GetCaster():GetTeamNumber(), hEntity:GetAbsOrigin(), 16.0, 0.1, true)
	end
end

function modifier_iw_bounty_hunter_track_reveal:OnIntervalThink()
	local hEntity = self:GetParent()
	local hCaster = self:GetCaster()
	if IsServer() and hEntity:IsMoving() then
		AddFOWViewer(hCaster:GetTeamNumber(), hEntity:GetAbsOrigin(), 16.0, 0.1, true)
	end
end