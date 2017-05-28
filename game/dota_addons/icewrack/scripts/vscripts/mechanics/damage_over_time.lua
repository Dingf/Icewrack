require("mechanics/damage_types")
require("mechanics/damage_secondary")

function OnIntervalThink(self, keys)
	if not self._tDamageTable then
		self._fDamageRemainder = 0
		self._tDamageTable =
		{
			target = self:GetParent(),
			attacker = self:GetCaster(),
			damage = {},
		}
	end
	
	if not self._nDamageType then
		local nDamageType = stIcewrackDamageTypeEnum[keys.DamageType]
		if not nDamageType then
			LogMessage("Unknown damage type \"" .. keys.DamageType .. "\"", LOG_SEVERITY_WARNING)
			return
		end
		self._nDamageType = nDamageType
	end
	
	if not self._fBaseDamage then
		self._fBaseDamage = (type(keys.Damage) == "number") and keys.Damage or 0.0
		if keys.UsePercent and keys.UsePercent ~= 0 then
			self._fBaseDamage = self._fBaseDamage/100.0 * keys.target:GetMaxHealth()
		end
	end
	
	if not self._fDamageInterval then
		local fDamageInterval = keys.Interval
		if type(fDamageInterval) ~= "number" then
			LogMessage("Failed to parse interval \"" .. keys.Interval .. "\" for modifier \"" .. self:GetName() .. "\"", LOG_SEVERITY_WARNING)
			return
		end
		self._fDamageInterval = fDamageInterval
	end
	
	local fDamage = (self._fBaseDamage * self._fDamageInterval) + self._fDamageRemainder
	fDamage = fDamage * (1.0 + self:GetCaster():GetPropertyValue(IW_PROPERTY_DMG_DOT_PCT) / 100.0)
	self._tDamageTable.damage[self._nDamageType] =
	{
		min = math.floor(fDamage),
		max = math.floor(fDamage)
	}
	if fDamage > 0 then
		local bDamageResult = DealSecondaryDamage(nil, self._tDamageTable)
		if bDamageResult then
			self._fDamageRemainder = fDamage - math.floor(fDamage)
			local fResistance = math.min(1.0, keys.target:GetResistance(self._nDamageType), keys.target:GetMaxResistance(self._nDamageType))
			if fResistance < 1.0 then
				self._fDamageRemainder = self._fDamageRemainder / (1.0 - fResistance)
			end
			self._fDamageRemainder = self._fDamageRemainder / keys.target:GetDamageEffectiveness()
			self._fDamageRemainder = self._fDamageRemainder / self:GetCaster():GetDamageModifier(self._nDamageType)
		else
			self._fDamageRemainder = fDamage
		end
	end
end