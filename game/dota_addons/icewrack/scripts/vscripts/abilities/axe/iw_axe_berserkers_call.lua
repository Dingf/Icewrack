iw_axe_berserkers_call = class({})

function iw_axe_berserkers_call:OnSpellStart()
	local hEntity = self:GetCaster()
	
	hEntity:DispelStatusEffects(IW_STATUS_MASK_STUN +
	                            IW_STATUS_MASK_SLOW +
							    IW_STATUS_MASK_ROOT +
							    IW_STATUS_MASK_DISARM +
								IW_STATUS_MASK_MAIM +
							    IW_STATUS_MASK_PACIFY +
							    IW_STATUS_MASK_SLEEP +
							    IW_STATUS_MASK_FEAR + 
							    IW_STATUS_MASK_CHARM +
								IW_STATUS_MASK_EXHAUSTION)
	
	local fRadius = self:GetAOERadius()
	local fThreatAmount = self:GetSpecialValueFor("threat") + self:GetSpecialValueFor("threat_bonus") * hEntity:GetSpellpower()
	local hNearbyEntities = FindUnitsInRadius(hEntity:GetTeamNumber(), hEntity:GetAbsOrigin(), nil, self:GetAOERadius(), DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, 0, 0, false)

	for k,v in pairs(hNearbyEntities) do
		if v ~= hEntity and IsValidNPCEntity(v) and v:IsEnemy(hEntity) then
			v:AddThreat(hEntity, fThreatAmount, false)
		end
	end
	
	local nParticleID = ParticleManager:CreateParticle("particles/units/heroes/hero_axe/axe_beserkers_call_owner.vpcf", PATTACH_POINT, hEntity)
	ParticleManager:ReleaseParticleIndex(nParticleID)
	EmitSoundOn("Hero_Axe.BerserkersCall.Start", hEntity)
	EmitSoundOn("Hero_Axe.Berserkers_Call", hEntity)
	hEntity:StartGesture(ACT_DOTA_OVERRIDE_ABILITY_1)
end