modifier_iw_dragon_knight_dragon_form = class({})

function modifier_iw_dragon_knight_dragon_form:DeclareFunctions()
	local funcs =
	{
		MODIFIER_EVENT_ON_ATTACK,
	}
	return funcs
end

function modifier_iw_dragon_knight_dragon_form:DeclareExtEvents()
	local funcs =
	{
		[IW_MODIFIER_EVENT_ON_CAST_FILTER] = 1,
		[IW_MODIFIER_EVENT_ON_CAST_ERROR] = 1,
	}
	return funcs
end

function modifier_iw_dragon_knight_dragon_form:OnCastFilterResult(args)
	return UF_FAIL_CUSTOM
end

function modifier_iw_dragon_knight_dragon_form:OnGetCustomCastError(args)
	return "#iw_error_cast_transform"
end

function modifier_iw_dragon_knight_dragon_form:OnCreated(args)
	local hEntity = self:GetParent()
	if IsServer() and IsValidExtendedEntity(hEntity) then
		self._szBaseAttackCap = hEntity:GetAttackCapability()
		self._szBaseProjectile = hEntity:GetRangedProjectileName()
		self._tWearables = {}
		local hChild = hEntity:FirstMoveChild()
		while hChild do
			if hChild:GetClassname() == "dota_item_wearable" then
				hChild:AddEffects(EF_NODRAW)
				table.insert(self._tWearables, hChild)
			end
			hChild = hChild:NextMovePeer()
		end
		
		local hAttackSource = self:GetAbility()._hAttackSource
		hAttackSource:AddChild(hEntity)
		hEntity:AddAttackSource(hAttackSource, 2)
		hEntity:GetInventory():AddItemToInventory(hAttackSource)
		
		hEntity:SetAttackCapability(DOTA_UNIT_CAP_RANGED_ATTACK)
		hEntity:SetRangedProjectileName("particles/units/heroes/hero_dragon_knight/iw_dragon_knight_dragon_form_attack.vpcf")
		
		hEntity:StartGesture(ACT_DOTA_CAST_ABILITY_4)
		self:StartIntervalThink(0.8)
	end
end

function modifier_iw_dragon_knight_dragon_form:OnIntervalThink()
	EmitSoundOn("Hero_DragonKnight.DragonForm.Wings", self:GetCaster())
end

function modifier_iw_dragon_knight_dragon_form:OnDestroy(args)
	local hEntity = self:GetParent()
	if IsServer() and IsValidExtendedEntity(hEntity) then
		
		for k,v in pairs(self._tWearables) do
			v:RemoveEffects(EF_NODRAW)
		end
		
		local hAttackSource = self:GetAbility()._hAttackSource
		hAttackSource:RemoveChild(hEntity)
		hEntity:RemoveAttackSource(hAttackSource, 2)
		hEntity:GetInventory():RemoveItem(hAttackSource)
		
		hEntity:SetAttackCapability(self._szBaseAttackCap)
		hEntity:SetRangedProjectileName(self._szBaseProjectile)
		EmitSoundOn("Hero_DragonKnight.ElderDragonForm.Revert", hEntity)
		
		local nParticleID = ParticleManager:CreateParticle("particles/units/heroes/hero_dragon_knight/dragon_knight_transform_green.vpcf", PATTACH_WORLDORIGIN, self)
		ParticleManager:SetParticleControl(nParticleID, 0, hEntity:GetAbsOrigin())
		ParticleManager:ReleaseParticleIndex(nParticleID)
	end
end

function modifier_iw_dragon_knight_dragon_form:OnAttack(args)
	local hEntity = self:GetParent()
	if args.attacker == hEntity then
		local hTarget = args.target
		local hSpellbook = hEntity:GetSpellbook()
		local hBreatheFireAbility = hSpellbook:GetAbility("iw_dragon_knight_breathe_fire")
		if hBreatheFireAbility then
			local vDirection = hTarget:GetAbsOrigin() - hEntity:GetOrigin()
			vDirection.z = 0.0
			vDirection = vDirection:Normalized()
			
			local fDistance = hBreatheFireAbility:GetSpecialValueFor("range")
			local fStartRadius = hBreatheFireAbility:GetSpecialValueFor("start_radius")
			local fEndRadius = hBreatheFireAbility:GetSpecialValueFor("end_radius")
			local fSpeed = hBreatheFireAbility:GetSpecialValueFor("speed")
			fSpeed = fSpeed * (fDistance/(fDistance - fStartRadius))
			local tProjectileInfo = 
			{
				Ability = hBreatheFireAbility,
				EffectName = "particles/units/heroes/hero_dragon_knight/iw_dragon_knight_breathe_fire_dragon.vpcf",
				vSpawnOrigin = hEntity:GetAbsOrigin(),
				fDistance = fDistance,
				fStartRadius = fStartRadius,
				fEndRadius = fEndRadius,
				Source = hEntity,
				iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_BOTH,
				iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
				vVelocity = vDirection * fSpeed,
			}
			hBreatheFireAbility._vLastPosition = hEntity:GetAbsOrigin()
			hBreatheFireAbility._nProjectileID = ProjectileManager:CreateLinearProjectile(tProjectileInfo)
			EmitSoundOn("Hero_DragonKnight.BreathFire", hEntity)
		end
	end
end