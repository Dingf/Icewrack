iw_axe_berserkers_call = class({})

function iw_axe_berserkers_call:OnSpellStart()
	local hEntity = self:GetCaster()
	local nParticleID = ParticleManager:CreateParticle("particles/units/heroes/hero_axe/axe_beserkers_call_owner.vpcf", PATTACH_POINT, hEntity)
	ParticleManager:ReleaseParticleIndex(nParticleID)
	EmitSoundOn("Hero_Axe.BerserkersCall.Start", hEntity)
	EmitSoundOn("Hero_Axe.Berserkers_Call", hEntity)
	hEntity:StartGesture(ACT_DOTA_OVERRIDE_ABILITY_1)
	
	local tDispelledModifiers = {}
	for k,v in pairs(hEntity:FindAllModifiers()) do
		if IsValidExtendedEntity(v) and v:IsDebuff() then
			local nStatusEffect = v:GetStatusEffect()
			local nBitshiftedEffect = bit32.lshift(1, nStatusEffect - 1)
			--Remove Stun, Slow, Root, Disarm, Pacify, Sleep, Fear, and Charm
			if bit32.btest(nBitshiftedEffect, 955) then
				table.insert(tDispelledModifiers, v)
			end
		end
	end
	for k,v in pairs(tDispelledModifiers) do
		v:Destroy()
	end
	
	local fRadius = self:GetAOERadius()
	local fThreatAmount = self:GetSpecialValueFor("threat") + self:GetSpecialValueFor("threat_bonus") * hEntity:GetSpellpower()
	local hNearbyEntities = Entities:FindAllInSphere(hEntity:GetAbsOrigin(), self:GetAOERadius())
	for k,v in pairs(hNearbyEntities) do
		if v ~= hEntity and IsValidNPCEntity(v) and v:GetTeamNumber() ~= hEntity:GetTeamNumber() then
			v:AddThreat(hEntity, fThreatAmount, false)
		end
	end
end