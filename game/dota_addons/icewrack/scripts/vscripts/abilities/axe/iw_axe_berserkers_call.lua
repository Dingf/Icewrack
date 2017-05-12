iw_axe_berserkers_call = class({})

function iw_axe_berserkers_call:OnSpellStart()
	local hEntity = self:GetCaster()
	ParticleManager:CreateParticle("particles/units/heroes/hero_axe/axe_beserkers_call_owner.vpcf", PATTACH_POINT, hEntity)
	EmitSoundOn("Hero_Axe.BerserkersCall.Start", hEntity)
	EmitSoundOn("Hero_Axe.Berserkers_Call", hEntity)
	hEntity:StartGesture(ACT_DOTA_OVERRIDE_ABILITY_1)
	
	for k,v in pairs(hEntity._tExtModifierTable) do
		if v:IsDebuff() then
			local nStatusEffect = v:GetStatusEffect()
			local nBitshiftedEffect = bit32.lshift(1, nStatusEffect - 1)
			--Remove Stun, Slow, Root, Disarm, Pacify, Sleep, Fear, and Charm
			if bit32.btest(nBitshiftedEffect, 955) then
				v:Destroy()
			end
		end
	end
	
	local fRadius = self:GetAOERadius()
	local fThreatAmount = self:GetSpecialValueFor("threat")
	local hNearbyEntities = Entities:FindAllInSphere(hEntity:GetAbsOrigin(), self:GetAOERadius())
	for k,v in pairs(hNearbyEntities) do
		if v ~= hEntity and IsValidNPCEntity(v) then
			v:AddThreat(hEntity, fThreatAmount, false)
		end
	end
end