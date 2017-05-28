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
	local hAbility = self:GetAbility()
	if self:GetParent() == self:GetCaster() and hAbility._hChildModifier then
		local hChild = hAbility._hChildModifier:GetParent()
		if hChild:GetAttackTarget() == self:GetParent():GetAttackTarget() then
			return self._fAttackSpeedBonus
		end
	elseif hAbility._hParentModifier then
		local hParent = hAbility._hParentModifier:GetParent()
		if hParent:GetAttackTarget() == self:GetParent():GetAttackTarget() then
			return self._fAttackSpeedBonus
		end
	end
	return 0
end

--TODO: Fix the on-death and on-resurrect behavior for feral bond
function modifier_iw_drow_ranger_feral_bond:OnDeath(args)
	local hAbility = self:GetAbility()
	local hEntity = self:GetParent()
	if args.unit == hEntity then
		if hEntity == self:GetCaster() and hAbility._hChildModifier then
			local hChild = hAbility._hChildModifier:GetParent()
			hChild:ForceKill(false)
		elseif hAbility._hParentModifier then
			if GameRules:GetCustomGameDifficulty() <= IW_DIFFICULTY_NORMAL then
				local hParent = hAbility._hParentModifier:GetParent()
				local hModifier = hParent:AddNewModifier(hEntity, self:GetAbility(), "modifier_iw_drow_ranger_feral_bond_refresh", {})
				hModifier:Destroy()
			else
				hAbility._hParentModifier:Destroy()
				self:Destroy()
			end
		end
	end
end

function modifier_iw_drow_ranger_feral_bond:OnRespawn(args)
end

function modifier_iw_drow_ranger_feral_bond:OnRefresh(args)
	if IsServer() then
		local hEntity = self:GetParent()
		local hAbility = self:GetAbility()
		if hEntity == self:GetCaster() and hAbility._hChildModifier then
			local hChild = hAbility._hChildModifier:GetParent()
			local bIsChildAlive = hChild and hChild:IsAlive()
			for k,v in pairs(stIcewrackAttributeEnum) do
				if bIsChildAlive then
					local fAttributeValue = hChild:GetBasePropertyValue(IW_PROPERTY_ATTR_STR_FLAT + v)
					self:SetPropertyValue(IW_PROPERTY_ATTR_STR_FLAT + v, fAttributeValue * self._fAttributeSharePercent)
				else
					self:SetPropertyValue(IW_PROPERTY_ATTR_STR_FLAT + v, 0)
				end
			end
			if bIsChildAlive then
				local hModifier = hChild:AddNewModifier(hEntity, self:GetAbility(), "modifier_iw_drow_ranger_feral_bond_refresh", {})
				hModifier:Destroy()
			end
		elseif hAbility._hParentModifier then
			local hParent = hAbility._hParentModifier:GetParent()
			local bIsParentAlive = hParent and hParent:IsAlive()
			for k,v in pairs(stIcewrackAttributeEnum) do
				if bIsParentAlive then
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
			hAbility._hParentModifier = self
		else
			hAbility._hChildModifier = self
		end
		self._fAttributeSharePercent = args.attrib_percent/100.0
		self._fAttackSpeedBonus = args.attack_speed
	end
end