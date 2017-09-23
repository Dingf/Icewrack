
if IsServer() and not modifier_internal_stamina then

modifier_internal_stamina = class({})
modifier_internal_stamina._tDeclareFunctionList =
{
	MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
}

function modifier_internal_stamina:GetModifierAttackSpeedBonus_Constant(args)
	local hEntity = self:GetParent()
	local fStaminaPercent = hEntity:GetStamina()/hEntity:GetMaxStamina()
	if fStaminaPercent < 0.1 then
		if IsServer() and self._nLastStaminaLevel ~= 3 then
			self:SetPropertyValue(IW_PROPERTY_ACCURACY_PCT, -150)
			self:SetPropertyValue(IW_PROPERTY_MOVE_SPEED_PCT, -50)
			hEntity:RefreshEntity()
			self._nLastStaminaLevel = 3
		end
		return -150
	elseif fStaminaPercent < 0.25 then
		if IsServer() and self._nLastStaminaLevel ~= 2 then
			self:SetPropertyValue(IW_PROPERTY_ACCURACY_PCT, -50)
			self:SetPropertyValue(IW_PROPERTY_MOVE_SPEED_PCT, -25)
			hEntity:RefreshEntity()
			self._nLastStaminaLevel = 2
		end
		return -50
	else
		if IsServer() and self._nLastStaminaLevel ~= 1 then
			self:SetPropertyValue(IW_PROPERTY_ACCURACY_PCT, 0)
			self:SetPropertyValue(IW_PROPERTY_MOVE_SPEED_PCT, 0)
			hEntity:RefreshEntity()
			self._nLastStaminaLevel = 1
		end
		return 0
	end
end

function modifier_internal_stamina:OnCreated(keys)
	if IsServer() and IsValidExtendedEntity(self:GetParent()) then
		self._nLastStaminaLevel = 1
		self:StartIntervalThink(0.03)
		self:OnIntervalThink()
	else
		self:Destroy()
	end
end

--TODO: Fix the stamina percentage not being maintained when equipping items that provide extra stamina or endurance
function modifier_internal_stamina:OnIntervalThink()
	if IsServer() then
		local hEntity = self:GetParent()
		local fStamina = hEntity:GetStamina()
		local fMaxStamina = hEntity:GetMaxStamina()
		if fMaxStamina ~= hEntity._fLastMaxStamina then
			fStamina = math.max(0, math.min(fMaxStamina, hEntity._fLastStaminaPercent * fMaxStamina))
			hEntity._fLastMaxStamina = fMaxStamina
		end
		if not GameRules:IsGamePaused() and hEntity:IsAlive() then
			if hEntity:IsMoving() and hEntity._bRunMode then
				local fStaminaDrain = hEntity:GetPropertyValue(IW_PROPERTY_RUN_SP_FLAT) * (hEntity:GetFatigueMultiplier() + hEntity:GetPropertyValue(IW_PROPERTY_RUN_SP_PCT)/100)
				fStaminaDrain = fStaminaDrain/30.0
				hEntity:SpendStamina(fStaminaDrain)
				fStamina = hEntity:GetStamina()
			elseif hEntity:IsAttacking() then
				hEntity:SpendStamina(0)
			end
		
			local fStaminaRegenTime = hEntity:GetStaminaRegenTime()
			if fStamina ~= fMaxStamina then
				local fStaminaRegenPerSec = hEntity:GetPropertyValue(IW_PROPERTY_SP_REGEN_FLAT) + (hEntity:GetPropertyValue(IW_PROPERTY_MAX_SP_REGEN)/100.0 * hEntity:GetMaxStamina())
				if GameRules:GetGameTime() > fStaminaRegenTime then
					fStaminaRegenPerSec = fStaminaRegenPerSec + (0.1 * fMaxStamina)
				end
				fStaminaRegenPerSec = fStaminaRegenPerSec * (1.0 + self:GetPropertyValue(IW_PROPERTY_SP_REGEN_PCT)/100.0)
				if hEntity:IsMoving() then
					fStaminaRegenPerSec = fStaminaRegenPerSec * 0.5
				end
				hEntity:SetStamina(fStamina + fStaminaRegenPerSec/30.0)
				hEntity._fLastStaminaPercent = fStamina/fMaxStamina
			end
			local tNetTable = hEntity._tNetTable
			if tNetTable then
				if fStamina ~= tNetTable.stamina or fMaxStamina ~= tNetTable.stamina_max or fStaminaRegenTime ~= tNetTable.stamina_time then
					tNetTable.stamina = fStamina
					tNetTable.stamina_max = fMaxStamina
					tNetTable.stamina_time = fStaminaRegenTime
					hEntity:UpdateNetTable(true)
				end
			end
		end
	end
end

end