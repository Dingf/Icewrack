modifier_iw_drow_ranger_feral_bond = class({})

function modifier_iw_drow_ranger_feral_bond:DeclareFunctions()
	local funcs =
	{
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_EVENT_ON_DEATH,
		MODIFIER_EVENT_ON_RESPAWN,
	}
	return funcs
end

function modifier_iw_drow_ranger_feral_bond:GetModifierAttackSpeedBonus_Constant(args)
	if IsServer() then
		local hAbility = self:GetAbility()
		if self:GetParent() == self:GetCaster() and IsValidExtendedEntity(hAbility._hChildEntity) then
			local hChild = hAbility._hChildEntity
			if hChild:GetAttackTarget() == self:GetParent():GetAttackTarget() then
				return self._fAttackSpeedBonus
			end
		elseif IsValidExtendedEntity(hAbility._hParentEntity) then
			local hParent = hAbility._hParentEntity
			if hParent:GetAttackTarget() == self:GetParent():GetAttackTarget() then
				return self._fAttackSpeedBonus
			end
		end
	end
	return 0
end

--TODO: Fix the on-death and on-resurrect behavior for feral bond
function modifier_iw_drow_ranger_feral_bond:OnDeath(args)
	local hAbility = self:GetAbility()
	local hEntity = self:GetParent()
	if args.unit == hEntity then
		if hEntity == self:GetCaster() and IsValidExtendedEntity(hAbility._hChildEntity) then
			local hChild = hAbility._hChildEntity
			
			--hAbility._hChildEntity:ForceKill(false)
			local hModifier = hChild:AddNewModifier(hEntity, self:GetAbility(), "modifier_iw_drow_ranger_feral_bond_refresh", {})
			if hModifier then
				hModifier:Destroy()
			end
		elseif IsValidExtendedEntity(hAbility._hParentEntity) then
			local hParent = hAbility._hParentEntity
			if GameRules:GetCustomGameDifficulty() > IW_DIFFICULTY_NORMAL then
				local hParentModifier = hParent:FindModifierByName("modifier_iw_drow_ranger_feral_bond")
				hParentModifier:Destroy()
				self:Destroy()
			end
			local hModifier = hParent:AddNewModifier(hEntity, self:GetAbility(), "modifier_iw_drow_ranger_feral_bond_refresh", {})
			if hModifier then
				hModifier:Destroy()
			end
		end
			CTimer(15.0, function() hEntity:RespawnUnit() end)
	end
end

function modifier_iw_drow_ranger_feral_bond:OnRespawn(args)
	local hAbility = self:GetAbility()
	local hEntity = self:GetParent()
	if args.unit == hEntity then
		if hEntity == self:GetCaster() and IsValidExtendedEntity(hAbility._hChildEntity) then
			local hChild = hAbility._hChildEntity
			local hModifier = hChild:AddNewModifier(hEntity, self:GetAbility(), "modifier_iw_drow_ranger_feral_bond_refresh", {})
			if hModifier then
				hModifier:Destroy()
			end
		elseif IsValidExtendedEntity(hAbility._hParentEntity) then
			local hParent = hAbility._hParentEntity
			local hModifier = hParent:AddNewModifier(hEntity, self:GetAbility(), "modifier_iw_drow_ranger_feral_bond_refresh", {})
			if hModifier then
				hModifier:Destroy()
			end
		end
	end
end

function modifier_iw_drow_ranger_feral_bond:OnRefresh(args)
	if IsServer() then
		local hEntity = self:GetParent()
		local hAbility = self:GetAbility()
		if hEntity == self:GetCaster() and IsValidExtendedEntity(hAbility._hChildEntity) then
			local hChild = hAbility._hChildEntity
			for k,v in pairs(stIcewrackAttributeEnum) do
				if hChild:IsAlive() then
					local fAttributeValue = hChild:GetBasePropertyValue(IW_PROPERTY_ATTR_STR_FLAT + v)
					self:SetPropertyValue(IW_PROPERTY_ATTR_STR_FLAT + v, fAttributeValue * self._fAttributeSharePercent)
				else
					self:SetPropertyValue(IW_PROPERTY_ATTR_STR_FLAT + v, 0)
				end
			end
			if hChild:IsAlive() then
				local hModifier = hChild:AddNewModifier(hEntity, self:GetAbility(), "modifier_iw_drow_ranger_feral_bond_refresh", {})
				hModifier:Destroy()
			end
		elseif IsValidExtendedEntity(hAbility._hParentEntity) then
			local hParent = hAbility._hParentEntity
			for k,v in pairs(stIcewrackAttributeEnum) do
				if hParent:IsAlive() then
					local fAttributeValue = hParent:GetBasePropertyValue(IW_PROPERTY_ATTR_STR_FLAT + v)
					self:SetPropertyValue(IW_PROPERTY_ATTR_STR_FLAT + v, fAttributeValue * self._fAttributeSharePercent)
				else
					self:SetPropertyValue(IW_PROPERTY_ATTR_STR_FLAT + v, 0)
				end
			end
		end
	end
end

function modifier_iw_drow_ranger_feral_bond:OnCreated(args)
	if IsServer() then
		local hAbility = self:GetAbility()
		if self:GetParent() == self:GetCaster() then
			hAbility._hParentEntity = self:GetParent()
		else
			hAbility._hChildEntity = self:GetParent()
		end
		self._fAttributeSharePercent = args.attrib_percent/100.0
		self._fAttackSpeedBonus = args.attack_speed
	end
end