
if IsServer() and not modifier_internal_stamina then

modifier_internal_stamina = class({})
modifier_internal_stamina._tDeclareFunctionList =
{
	MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
}

function modifier_internal_stamina:GetModifierAttackSpeedBonus_Constant(args)
	local hEntity = self:GetParent()
	local fStaminaPercent = hEntity:GetStamina()/hEntity:GetMaxStamina()
	if fStaminaPercent < 0.1 then
		self:SetPropertyValue(IW_PROPERTY_ACCURACY_PCT, -150)
		return -150
	elseif fStaminaPercent < 0.25 then
		self:SetPropertyValue(IW_PROPERTY_ACCURACY_PCT, -50)
		return -50
	else
		return 0
	end
end

function modifier_internal_stamina:OnCreated(keys)
	if IsServer() and IsValidExtendedEntity(self:GetParent()) then
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
		if not GameRules:IsGamePaused() then
			if hEntity:IsMoving() and hEntity._bRunMode then
				fStamina = fStamina - (hEntity:GetPropertyValue(IW_PROPERTY_RUN_SP_FLAT) * (hEntity:GetFatigueMultiplier() + hEntity:GetPropertyValue(IW_PROPERTY_RUN_SP_PCT)/100))/30.0
				hEntity._fStaminaRegenTime = math.max(hEntity._fStaminaRegenTime, GameRules:GetGameTime() + 3.0)
			end
		
			if fStamina ~= fMaxStamina then
				local fStaminaRegenPerSec = hEntity:GetStaminaRegen()
				if GameRules:GetGameTime() > hEntity._fStaminaRegenTime then
					fStaminaRegenPerSec = fStaminaRegenPerSec + (0.1 * fMaxStamina) * (1.0 + hEntity:GetPropertyValue(IW_PROPERTY_SP_REGEN_PCT)/100.0)
				end
				if hEntity:IsMoving() then
					fStaminaRegenPerSec = fStaminaRegenPerSec * 0.5
				end
				hEntity:SetStamina(fStamina + fStaminaRegenPerSec/30.0)
				hEntity._fLastStaminaPercent = fStamina/fMaxStamina
			end
			if hEntity._tNetTable then
				if fStamina ~= hEntity._tNetTable.stamina or fMaxStamina ~= hEntity._tNetTable.stamina_max then
					hEntity._tNetTable.stamina = fStamina
					hEntity._tNetTable.stamina_max = fMaxStamina
					hEntity._tNetTable.stamina_time = hEntity._fStaminaRegenTime
					hEntity:UpdateNetTable(true)
				end
			end
		end
	end
end

end