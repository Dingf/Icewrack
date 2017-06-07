iw_bounty_hunter_trapjaw = class({})

function iw_bounty_hunter_trapjaw:CastFilterResultLocation(vLocation)
	local hStackModifier = self._hStackModifier
	if hStackModifier and hStackModifier:GetStackCount() > 0 then
		return UF_SUCCESS
	end
	return UF_FAIL_CUSTOM
end

function iw_bounty_hunter_trapjaw:GetCustomCastErrorLocation(vLocation)
	return "#iw_error_cast_no_trapjaws"
end

function iw_bounty_hunter_trapjaw:OnSpellStart()
	if IsServer() then
		local hEntity = self:GetCaster()
		local vTargetPos = self:GetCursorPosition()
		local hTrapEntity = CWorldObject(CreateUnitByName("npc_iw_bounty_hunter_trapjaw", vTargetPos, false, hEntity, hEntity, hEntity:GetTeamNumber()))
		
		local hStackModifier = self._hStackModifier
		hStackModifier:SetStackCount(hStackModifier:GetStackCount() - 1)
	end
end