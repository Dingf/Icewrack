iw_bounty_hunter_ensnare = class({})

function iw_bounty_hunter_ensnare:CastFilterResultTarget(hTarget)
	if IsServer() then
		if IsValidExtendedEntity(hTarget) and hTarget:IsMassive() then
			return UF_FAIL_CUSTOM
		end
		return UF_SUCCESS
	end
end

function iw_bounty_hunter_ensnare:OnSpellStart()
	local hEntity = self:GetCaster()
	local hTarget = self:GetCursorTarget()
	local tProjectileInfo =
	{
		EffectName = "particles/units/heroes/hero_bounty_hunter/bounty_hunter_ensnare_proj.vpcf",
		Ability = self,
		iMoveSpeed = self:GetSpecialValueFor("proj_speed"),
		Source = hEntity,
		Target = hTarget,
		iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_2
	}
	ProjectileManager:CreateTrackingProjectile(tProjectileInfo)
	EmitSoundOn("Hero_BountyHunter.Ensnare", hTarget)
end

function iw_bounty_hunter_ensnare:OnProjectileHit(hTarget, vLocation)
	local hEntity = self:GetCaster()
	local tModifierArgs =
	{
		duration = self:GetSpecialValueFor("duration"),
	}
	
	hTarget:Stop()
	hTarget:AddNewModifier(hEntity, self, "modifier_iw_bounty_hunter_ensnare", tModifierArgs)
	EmitSoundOn("Hero_BountyHunter.Ensnare.Target", hTarget)
	return true
end