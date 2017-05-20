modifier_iw_drow_ranger_frost_arrows = class({})

function modifier_iw_drow_ranger_frost_arrows:DeclareFunctions()
	local funcs =
	{
		MODIFIER_EVENT_ON_ATTACK_START,
		MODIFIER_EVENT_ON_ATTACK,
	}
	return funcs
end

function modifier_iw_drow_ranger_frost_arrows:OnAttackStart()
	local hEntity = self:GetCaster()
	local hAbility = self:GetAbility()
	local hAttackSource = hEntity:GetCurrentAttackSource()
	if self._bIsBowEquipped and hEntity:GetMana() >= hAbility:GetManaCost() then
		self._bIsFrostArrowAttack = true
		hEntity:SetRangedProjectileName("particles/units/heroes/hero_drow/drow_frost_arrow.vpcf")
		if self._hLastAttackSource ~= hAttackSource then
			if self._hLastAttackSource then
				self._hLastAttackSource:RemoveChild(self)
			end
			hAttackSource:AddChild(self)
			self._hLastAttackSource = hAttackSource
		end
	else
		self._bIsFrostArrowAttack = false
		hEntity:SetRangedProjectileName(self._szBaseProjectile)
		if self._hLastAttackSource then
			self._hLastAttackSource:RemoveChild(self)
			self._hLastAttackSource = nil
		end
	end
end

function modifier_iw_drow_ranger_frost_arrows:OnAttack()
	local hEntity = self:GetCaster()
	local hAbility = self:GetAbility()
	if self._bIsFrostArrowAttack then
		hEntity:SpendMana(hAbility:GetManaCost(), hAbility)
	end
end

function modifier_iw_drow_ranger_frost_arrows:OnRefresh()
	local hEntity = self:GetCaster()
	local hAbility = self:GetAbility()
	local hAttackSource = hEntity:GetCurrentAttackSource()
	local nItemType = hAttackSource and hAttackSource:GetItemType() or 0
	
	self._bIsBowEquipped = bit32.btest(nItemType, bit32.lshift(1, IW_ITEM_TYPE_WEAPON_BOW - 1))
	if self._bIsBowEquipped then
		local fDamagePercent = self:GetAbility():GetSpecialValueFor("damage")/5.0
		local fChillChance = self:GetAbility():GetSpecialValueFor("chill_chance")
		self._fDamageSumMin = 0
		self._fDamageSumMax = 0
		for i=IW_DAMAGE_TYPE_CRUSH,IW_DAMAGE_TYPE_PIERCE do
			self._fDamageSumMin = self._fDamageSumMin + (hAttackSource:GetDamageMin(i) * fDamagePercent)
			self._fDamageSumMax = self._fDamageSumMax + (hAttackSource:GetDamageMax(i) * fDamagePercent)
		end
		self:SetPropertyValue(IW_PROPERTY_DMG_COLD_BASE, self._fDamageSumMin)
		self:SetPropertyValue(IW_PROPERTY_DMG_COLD_VAR, self._fDamageSumMax - self._fDamageSumMin)
		self:SetPropertyValue(IW_PROPERTY_CHANCE_CHILL, fChillChance)
	else
		self:SetPropertyValue(IW_PROPERTY_DMG_COLD_BASE, 0)
		self:SetPropertyValue(IW_PROPERTY_DMG_COLD_VAR, 0)
		self:SetPropertyValue(IW_PROPERTY_CHANCE_CHILL, 0)
	end
end

function modifier_iw_drow_ranger_frost_arrows:OnCreated(args)
	if IsServer() then
		local hEntity = self:GetCaster()
		hEntity:RemoveChild(self)
		self._szBaseProjectile = hEntity:GetRangedProjectileName()
	end
end

function modifier_iw_drow_ranger_frost_arrows:OnDestroy(args)
	if IsServer() then
		local hEntity = self:GetCaster()
		hEntity:SetRangedProjectileName(self._szBaseProjectile)
		if self._hLastAttackSource then
			self._hLastAttackSource:RemoveChild(self)
		end
	end
end