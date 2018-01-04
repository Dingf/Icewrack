if IsServer() and not modifier_internal_carry_weight then

require("container")

modifier_internal_carry_weight = class({})

function modifier_internal_carry_weight:OnRefresh()
	local hEntity = self:GetParent()
	if IsValidContainer(hEntity) then
		local fCarryWeight = hEntity:GetCarryWeight()
		local fCarryCapacity = hEntity:GetCarryCapacity()
		if fCarryWeight > fCarryCapacity then
			self:SetPropertyValue(IW_PROPERTY_FATIGUE_MULTI, (fCarryWeight - fCarryCapacity) * 5.0)
		else
			self:SetPropertyValue(IW_PROPERTY_FATIGUE_MULTI, 0)
		end
	end
end

end