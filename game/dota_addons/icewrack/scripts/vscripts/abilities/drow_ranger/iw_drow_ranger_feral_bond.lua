iw_drow_ranger_feral_bond = class({})

function iw_drow_ranger_feral_bond:CastFilterResultTarget(hTarget)
	if IsServer() then
		self._bSubtypeFailed = false
		self._bClassFailed = false
		if hTarget:GetUnitSubtype() ~= IW_UNIT_SUBTYPE_BEAST then
			self._bTargetFailed = true
			return UF_FAIL_CUSTOM
		elseif hTarget:GetUnitClass() > IW_UNIT_CLASS_VETERAN then
			self._bClassFailed = true
			return UF_FAIL_CUSTOM
		end
	end
	return UF_SUCCESS
end

function iw_drow_ranger_feral_bond:GetCustomCastErrorTarget(hTarget)
	if self._bTargetFailed then return "#iw_error_cast_beast" end
	if self._bClassFailed then return "#iw_error_cast_veteran_or_lower" end
end

function iw_drow_ranger_feral_bond:OnSpellStart()
	if IsServer() then
		local hTarget = self:GetCursorTarget()
		
		--TODO: Make it so that this ability cannot be cast again
		
		hTarget:SetTeam(DOTA_TEAM_GOODGUYS)
		hTarget:SetControllableByPlayer(0, true)
		hTarget:Stop()
	end
end