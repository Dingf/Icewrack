local TICK_RATE = 0.1

modifier_iw_axe_battle_hunger = class({})
	
function modifier_iw_axe_battle_hunger:OnCreated(keys)
	if IsServer() then
		self:StartIntervalThink(TICK_RATE)
		self:OnIntervalThink()
	end
end

function modifier_iw_axe_battle_hunger:OnIntervalThink()
	if IsServer() then
		local hEntity = self:GetParent()
		local fHealthLossPercent = self:GetAbility():GetSpecialValueFor("health_loss")/100.0
		local fHealthLoss = fHealthLossPercent * hEntity:GetMaxHealth() * TICK_RATE
		hEntity:ModifyHealth(math.max(0, hEntity:GetHealth() - fHealthLoss), hEntity, true, 0)
	end
end