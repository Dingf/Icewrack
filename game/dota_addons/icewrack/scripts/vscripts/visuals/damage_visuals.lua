function CreateDamageVisuals(hTarget, nDamageType, bIsCrit)
	if nDamageType >= IW_DAMAGE_TYPE_CRUSH and nDamageType <= IW_DAMAGE_TYPE_PIERCE and IsValidExtendedEntity(hTarget) then
		local nUnitSubtype = hTarget:GetUnitSubtype()
		if bit32.btest(nUnitSubtype, IW_UNIT_SUBTYPE_BIOLOGICAL) then
			ParticleManager:CreateParticle("particles/generic_gameplay/generic_hit_physical_b.vpcf", PATTACH_POINT, hTarget)
		elseif bit32.btest(nUnitSubtype, IW_UNIT_SUBTYPE_MECHANICAL) then
			ParticleManager:CreateParticle("particles/generic_gameplay/generic_hit_physical_m.vpcf", PATTACH_POINT, hTarget)
		end
	elseif nDamageType == IW_DAMAGE_TYPE_FIRE then
		ParticleManager:CreateParticle("particles/generic_gameplay/generic_hit_fire.vpcf", PATTACH_POINT, hTarget)
	elseif nDamageType == IW_DAMAGE_TYPE_COLD then
		ParticleManager:CreateParticle("particles/generic_gameplay/generic_hit_frost.vpcf", PATTACH_POINT, hTarget)
	elseif nDamageType == IW_DAMAGE_TYPE_LIGHTNING then
		ParticleManager:CreateParticle("particles/generic_gameplay/generic_hit_lightning.vpcf", PATTACH_POINT, hTarget)
	elseif nDamageType == IW_DAMAGE_TYPE_DEATH then
		ParticleManager:CreateParticle("particles/generic_gameplay/generic_hit_death.vpcf", PATTACH_POINT, hTarget)
	end
end