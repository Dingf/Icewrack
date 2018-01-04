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
								
	hEntity:AddNewModifier(hEntity, self, "modifier_iw_axe_berserkers_call", { duration = self:GetSpecialValueFor("duration") })
	
	local nParticleID = ParticleManager:CreateParticle("particles/units/heroes/hero_axe/axe_beserkers_call_owner.vpcf", PATTACH_POINT, hEntity)
	ParticleManager:ReleaseParticleIndex(nParticleID)
	EmitSoundOn("Hero_Axe.BerserkersCall.Start", hEntity)
	EmitSoundOn("Hero_Axe.Berserkers_Call", hEntity)
	hEntity:StartGesture(ACT_DOTA_OVERRIDE_ABILITY_1)
end