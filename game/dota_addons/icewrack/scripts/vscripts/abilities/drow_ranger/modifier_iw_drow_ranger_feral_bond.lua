modifier_iw_drow_ranger_feral_bond = class({})

function modifier_iw_drow_ranger_feral_bond:OnRefresh(args)
	if IsServer() then
		local hAbility = self:GetAbility()
		if self:GetParent() == self:GetCaster() and hAbility._hChildModifier then
			local hChild = hAbility._hChildModifier:GetParent()
			for k,v in pairs(stIcewrackAttributeEnum) do
				local fAttributeValue = hChild:GetBasePropertyValue(IW_PROPERTY_ATTR_STR_FLAT + v)
				self:SetPropertyValue(IW_PROPERTY_ATTR_STR_FLAT + v, fAttributeValue * self._fAttributeSharePercent)
			end
			local hModifier = hChild:AddNewModifier(hChild, self:GetAbility(), "modifier_iw_drow_ranger_feral_bond_refresh", {})
			hModifier:Destroy()
		elseif hAbility._hParentModifier then
			local hParent = hAbility._hParentModifier:GetParent()
			for k,v in pairs(stIcewrackAttributeEnum) do
				local fAttributeValue = hParent:GetBasePropertyValue(IW_PROPERTY_ATTR_STR_FLAT + v)
				self:SetPropertyValue(IW_PROPERTY_ATTR_STR_FLAT + v, fAttributeValue * self._fAttributeSharePercent)
			end
		end
	end
end

function modifier_iw_drow_ranger_feral_bond:OnCreated(args)
	if IsServer() then
		local hAbility = self:GetAbility()
		if self:GetParent() == self:GetCaster() then
			hAbility._hParentModifier = self
		else
			hAbility._hChildModifier = self
		end
		self._fAttributeSharePercent = args.attrib_percent
	else
		
	end
end