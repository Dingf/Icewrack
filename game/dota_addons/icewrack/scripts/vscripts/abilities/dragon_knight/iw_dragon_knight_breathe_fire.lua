iw_dragon_knight_breathe_fire = class({})

function iw_dragon_knight_breathe_fire:GetAOERadius()
	return self:GetSpecialValueFor("end_radius") + self:GetSpecialValueFor("range")
end

function iw_dragon_knight_breathe_fire:OnSpellStart()
	local hEntity = self:GetCaster()
	local vTargetPos = nil
	if self:GetCursorTarget() then
		vTargetPos = self:GetCursorTarget():GetOrigin()
	else
		vTargetPos = self:GetCursorPosition()
	end

	local vDirection = vTargetPos - self:GetCaster():GetOrigin()
	vDirection.z = 0.0
	vDirection = vDirection:Normalized()
	
	local fDistance = self:GetSpecialValueFor("range")
	local fStartRadius = self:GetSpecialValueFor("start_radius")
	local fEndRadius = self:GetSpecialValueFor("end_radius")
	local fSpeed = self:GetSpecialValueFor("speed")
	fSpeed = fSpeed * (fDistance/(fDistance - fStartRadius))

	local tProjectileInfo = 
	{
		Ability = self,
		EffectName = "particles/units/heroes/hero_dragon_knight/dragon_knight_breathe_fire.vpcf",
		vSpawnOrigin = hEntity:GetAbsOrigin(),
		fDistance = fDistance,
		fStartRadius = fStartRadius,
		fEndRadius = fEndRadius,
		Source = hEntity,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_BOTH,
		iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		vVelocity = vDirection * fSpeed,
	}
	self._vLastPosition = hEntity:GetAbsOrigin()
	self._nProjectileID = ProjectileManager:CreateLinearProjectile(tProjectileInfo)
	EmitSoundOn("Hero_DragonKnight.BreathFire", hEntity)
end

function iw_dragon_knight_breathe_fire:OnProjectileThink(vLocation)
	local hEntity = self:GetCaster()
	local vGroundPosition = GetGroundPosition(vLocation, hEntity)
	local vPositionDiff = vGroundPosition - self._vLastPosition
	if not hEntity:IsFlying() and not GridNav:IsTraversable(vLocation) and vPositionDiff.z > -64.0 then
		ProjectileManager:DestroyLinearProjectile(self._nProjectileID)
	end
	self._vLastPosition = vLocation
end

function iw_dragon_knight_breathe_fire:OnProjectileHit(hTarget, vLocation)
	local hEntity = self:GetCaster()
	if hEntity ~= hTarget and IsValidExtendedEntity(hTarget) then
		local tDamageTable =
		{
			attacker = hEntity,
			target = hTarget,
			source = self,
			damage =
			{
				[IW_DAMAGE_TYPE_FIRE] = 
				{
					min = self:GetSpecialValueFor("damage_min") + (hEntity:GetSpellpower() * self:GetSpecialValueFor("damage_min_bonus")),
					max = self:GetSpecialValueFor("damage_max") + (hEntity:GetSpellpower() * self:GetSpecialValueFor("damage_max_bonus")),
				}
			}
		}
		DealPrimaryDamage(self, tDamageTable)
	end
	return false
end