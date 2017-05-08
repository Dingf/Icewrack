require("mechanics/difficulty")

function TriggerShatter(hVictim)
	local nUnitClass = hVictim:GetUnitClass()
	if nUnitClass <= IW_UNIT_CLASS_VETERAN or (GameRules:GetCustomGameDifficulty() >= IW_DIFFICULTY_UNTHAW and nUnitClass == IW_UNIT_CLASS_HERO) then
		for k,v in pairs(hVictim._tExtModifierTable) do
			local nStatusEffect = v:GetStatusEffect()
			if nStatusEffect == IW_STATUS_EFFECT_FREEZE then
				hVictim:ModifyHealth(0, hVictim, true, 0)
				local hDummy = CreateDummyUnit(hVictim:GetAbsOrigin(), nil, hVictim:GetTeamNumber())
				ParticleManager:CreateParticle("particles/econ/items/effigies/status_fx_effigies/frosty_base_statue_destruction_radiant.vpcf", PATTACH_ABSORIGIN_FOLLOW, hDummy)
				StartSoundEvent("Icewrack.ShatterFrozen", hVictim)
				hVictim:AddEffects(EF_NODRAW)
				hDummy:SetThink(function() hDummy:RemoveSelf() end, "ShatterDummyThink", 0.1)
				return true
			elseif nStatusEffect == IW_STATUS_EFFECT_PETRIFY then
				
				--TODO: Add shatter effect for petrified units
			end
		end
	end
	return false
end