require("ext_entity")
require("npc")

local IW_MOVEMENT_NOISE_RADIUS = 1800.0

function OnIntervalThink(self, keys)
	local hEntity = self:GetParent()
	if hEntity:IsControllableByAnyPlayer() and hEntity:IsMoving() and not GameRules:IsGamePaused() then
		local fNoiseValue = math.max(0, hEntity:GetPropertyValue(IW_PROPERTY_MOVE_NOISE_FLAT) * (1.0 + hEntity:GetPropertyValue(IW_PROPERTY_MOVE_NOISE_PCT)/100.0))
		if fNoiseValue > 0 then
			local vNoiseOrigin = hEntity:GetAbsOrigin()
			local hNearbyEntities = Entities:FindAllInSphere(vNoiseOrigin, IW_MOVEMENT_NOISE_RADIUS)
			for k,v in pairs(hNearbyEntities) do
				if IsValidNPCEntity(v) then
					v:AddNoiseEvent(hEntity, vNoiseOrigin, fNoiseValue)
				end
			end
		end
	end
end