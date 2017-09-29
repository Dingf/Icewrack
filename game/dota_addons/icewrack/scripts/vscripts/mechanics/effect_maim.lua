if not modifier_status_maim then

modifier_status_maim = class({})

function modifier_status_maim:OnCreated(args)
	if IsServer() then
		local hEntity = self:GetParent()
		self._fMoveDamage = args.move_damage
		self._fDamageRemainder = 0.0
		self._vLastPosition = hEntity:GetAbsOrigin()
		self._tDamageTable =
		{
			target = self:GetParent(),
			attacker = self:GetCaster(),
			damage =
			{
				[IW_DAMAGE_TYPE_SLASH] = {}
			},
		}
		self:StartIntervalThink(0.1)
	end
end

function modifier_status_maim:OnIntervalThink()
	if IsServer() then
		local hCaster = self:GetCaster()
		local hTarget = self:GetParent()
		local vPosition = hTarget:GetAbsOrigin()
		local fDistance = (vPosition - self._vLastPosition):Length2D()
		
		local fDamage = (fDistance * self._fMoveDamage/100.0) + self._fDamageRemainder
		fDamage = fDamage * (1.0 + self:GetCaster():GetPropertyValue(IW_PROPERTY_DMG_DOT_PCT) / 100.0)
		if fDamage > 0 then
			self._tDamageTable.damage[IW_DAMAGE_TYPE_SLASH].min = math.floor(fDamage)
			self._tDamageTable.damage[IW_DAMAGE_TYPE_SLASH].max = math.floor(fDamage)
			local bDamageResult = DealSecondaryDamage(nil, self._tDamageTable)
			if bDamageResult then
				self._fDamageRemainder = fDamage - math.floor(fDamage)
				local fResistance = math.min(1.0, hTarget:GetResistance(IW_DAMAGE_TYPE_SLASH), hTarget:GetMaxResistance(IW_DAMAGE_TYPE_SLASH))
				if fResistance < 1.0 then
					self._fDamageRemainder = self._fDamageRemainder / (1.0 - fResistance)
				end
				self._fDamageRemainder = self._fDamageRemainder / hTarget:GetDamageEffectiveness()
				self._fDamageRemainder = self._fDamageRemainder / hCaster:GetDamageModifier(IW_DAMAGE_TYPE_SLASH)
			else
				self._fDamageRemainder = fDamage
			end
		end
		self._vLastPosition = vPosition
	end
end

else

function ApplyMaim(hTarget, hEntity, fDamagePercentHP)
	if fDamagePercentHP > 0.1 then
		local fBaseDuration = 10.0 * fDamagePercentHP
		local nUnitClass = hTarget:GetUnitClass()
		local fMovementSpeed = -50.0
		local fMoveDamagePercent = 10.0
		if nUnitClass == IW_UNIT_CLASS_ELITE then
			fMovementSpeed = -20.0
		elseif nUnitClass == IW_UNIT_CLASS_BOSS or nUnitClass == IW_UNIT_CLASS_ACT_BOSS then
			fMovementSpeed = -10.0
		end
	
		local hModifier = hTarget:FindModifierByName("modifier_status_maim")
		if hModifier then
			local fRealDuration = fBaseDuration * hModifier:GetRealDurationMultiplier(hTarget)
			if (hModifier:GetDuration() - hModifier:GetElapsedTime()) < fRealDuration then
				hModifier:ForceRefresh()
				hModifier:SetDuration(fBaseDuration, true)
			end
		else
			local tModifierArgs =
			{
				move_speed = fMovementSpeed,
				move_damage = fMoveDamagePercent,
				duration = fBaseDuration,
			}
			AddModifier("status_maim", "modifier_status_maim", hTarget, hEntity, tModifierArgs)
		end
	end
end

end