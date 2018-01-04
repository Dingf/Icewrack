require("mechanics/difficulty")

function TriggerShatter(hVictim)
	local nUnitClass = hVictim:GetUnitClass()
	if nUnitClass <= IW_UNIT_CLASS_VETERAN or (GameRules:GetCustomGameDifficulty() >= IW_DIFFICULTY_UNTHAW and nUnitClass == IW_UNIT_CLASS_HERO) then
		if hVictim:HasStatusEffect(IW_STATUS_MASK_FREEZE) then
			hVictim:ModifyHealth(0, hVictim, true, 0)
			local nParticleID = ParticleManager:CreateParticle("particles/generic_gameplay/effect_shatter_frozen.vpcf", PATTACH_WORLDORIGIN, hVictim)
			ParticleManager:SetParticleControl(nParticleID, 0, hVictim:GetAbsOrigin())
			ParticleManager:ReleaseParticleIndex(nParticleID)
			StartSoundEvent("Icewrack.ShatterFrozen", hVictim)
			hVictim:AddEffects(EF_NODRAW)
			return true
		elseif hVictim:HasStatusEffect(IW_STATUS_MASK_PETRIFY) then
			--TODO: Add shatter effect for petrified units
		end
	end
	return false
end