modifier_iw_bounty_hunter_track_target = class({})

local function TrackDummyThink(self)
	local hModifier = self._hModifier
	local hParent = hModifier:GetParent()
	self:SetAbsOrigin(hParent:GetAbsOrigin())
	return 0.03
end

function modifier_iw_bounty_hunter_track_target:OnCreated(args)
	if IsServer() and not self._hTrackDummy then
		local hParent = self:GetParent()
		local hTrackDummy = CreateUnitByName("npc_dota_hero_base", hParent:GetAbsOrigin(), false, nil, nil, hParent:GetTeamNumber())
		
		self._hTrackDummy = hTrackDummy
		hTrackDummy._hModifier = self
		hTrackDummy.OnThink = TrackDummyThink
		hTrackDummy:AddNewModifier(hTrackDummy, self:GetAbility(), "modifier_iw_bounty_hunter_track_reveal", {})
		hTrackDummy:SetThink("OnThink", hTrackDummy, "TrackDummyThink", 0.03)
	end
end

function modifier_iw_bounty_hunter_track_target:OnDestroy(args)
	if IsServer() then
		local hTrackDummy = self._hTrackDummy
		if hTrackDummy and not hTrackDummy:IsNull() then
			self._hTrackDummy = nil
			hTrackDummy:RemoveSelf()
		end
	end
end