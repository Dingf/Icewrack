iw_bounty_hunter_smoke_bomb = class({})

function iw_bounty_hunter_smoke_bomb:OnSpellStart()
	if IsServer() then
		local hEntity = self:GetCaster()
		local vTargetPos = self:GetCursorPosition()
		local hCastDummy = CInstance(CreateDummyUnit(vTargetPos, hEntity:GetOwner(), 0))
	
		local tProjectileInfo =
		{
			EffectName = "particles/units/heroes/hero_bounty_hunter/bounty_hunter_smoke_bomb_projectile.vpcf",
			Ability = self,
			iMoveSpeed = self:GetSpecialValueFor("proj_speed"),
			Source = hEntity,
			Target = hCastDummy,
			iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1
		}
		
		ProjectileManager:CreateTrackingProjectile(tProjectileInfo)
		EmitSoundOn("Hero_BountyHunter.SmokeBomb.Launch", hEntity)
	else
	
	end
end

function iw_bounty_hunter_smoke_bomb:OnProjectileHit(hTarget, vPosition)
	local hEntity = self:GetCaster()
	local fDuration = self:GetSpecialValueFor("duration") * hEntity:GetOtherDebuffDuration()
	local tModifierArgs =
	{
		accuracy = self:GetSpecialValueFor("accuracy") + self:GetSpecialValueFor("accuracy_bonus") * hEntity:GetSpellpower(),
		duration = fDuration,
	}
	hTarget:AddNewModifier(hTarget, self, "modifier_iw_bounty_hunter_smoke_bomb", tModifierArgs)
	hTarget:AddNewModifier(hTarget, self, "modifier_iw_bounty_hunter_smoke_bomb_visibility", { visibility = self:GetSpecialValueFor("visibility") })
	StopSoundOn("Hero_BountyHunter.SmokeBomb.Launch", hEntity)
	EmitSoundOn("Hero_BountyHunter.SmokeBomb", hTarget)
	
	local fAvoidanceValue = self:GetSpecialValueFor("avoidance")
	CreateAvoidanceZone(vPosition, self:GetAOERadius() + 64.0, fAvoidanceValue, fDuration)
end