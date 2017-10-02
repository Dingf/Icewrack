iw_bounty_hunter_ensnare = class({})

function iw_bounty_hunter_ensnare:OnSpellStart()
	if IsServer() then
		local hEntity = self:GetCaster()
		local tProjectileInfo =
		{
			EffectName = "particles/units/heroes/hero_bounty_hunter/bounty_hunter_ensnare_proj.vpcf",
			Ability = self,
			iMoveSpeed = self:GetSpecialValueFor("proj_speed"),
			Source = hEntity,
			Target = self:GetCursorTarget(),
			iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_2
		}
		ProjectileManager:CreateTrackingProjectile(tProjectileInfo)
	end
end

function iw_bounty_hunter_ensnare:OnProjectileHit(hTarget, vLocation)
	local hEntity = self:GetCaster()
	local tModifierArgs =
	{
		duration = self:GetSpecialValueFor("duration"),
	}
	hTarget:Stop()
	hTarget:AddNewModifier(hEntity, self, "modifier_iw_bounty_hunter_ensnare", tModifierArgs)
	return true
end