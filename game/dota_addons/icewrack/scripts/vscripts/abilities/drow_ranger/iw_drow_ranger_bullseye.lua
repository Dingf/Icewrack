iw_drow_ranger_bullseye = class({})

function iw_drow_ranger_bullseye:OnAbilityPhaseStart()
	local hEntity = self:GetCaster()
	hEntity:AddNewModifier(hEntity, self, "modifier_iw_drow_ranger_bullseye", {})
	hEntity:TriggerExtendedEvent(IW_MODIFIER_EVENT_ON_PRE_ATTACK)
	return true
end

function iw_drow_ranger_bullseye:CastFilterResult()
	if IsServer() then
		local hEntity = self:GetCaster()
		local hAttackSource = hEntity:GetCurrentAttackSource()
		local nItemType = hAttackSource and hAttackSource:GetItemType() or 0
		
		self._bEquipFailed = false
		if bit32.btest(nItemType, bit32.lshift(1, IW_ITEM_TYPE_WEAPON_BOW - 1)) then
			return UF_SUCCESS
		end
		self._bEquipFailed = true
		return UF_FAIL_CUSTOM
	end
end

function iw_drow_ranger_bullseye:GetCustomCastError()
	if self._bEquipFailed then return "#iw_error_cast_bow" end
end

function iw_drow_ranger_bullseye:OnSpellStart()
	local hEntity = self:GetCaster()
	if IsServer() then
		local tProjectileInfo =
		{
			EffectName = "particles/units/heroes/hero_drow/drow_bullseye.vpcf",
			Ability = self,
			iMoveSpeed = hEntity:GetProjectileSpeed() * 1.5,
			Source = hEntity,
			Target = self:GetCursorTarget(),
			iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1
		}
		
		ProjectileManager:CreateTrackingProjectile(tProjectileInfo)
		hEntity:TriggerExtendedEvent(IW_MODIFIER_EVENT_ON_ATTACK_START)
		EmitSoundOn("Hero_DrowRanger.Bullseye.Launch", hEntity)
	end
end

function iw_drow_ranger_bullseye:OnProjectileHit(hTarget, vLocation)
	local hEntity = self:GetCaster()
	local tDamageTable =
	{
		attacker = hEntity,
		target = hTarget,
		Percent = self:GetSpecialValueFor("damage"),
		ForceCrit = true,
	}
	
	self:SetPropertyValue(IW_PROPERTY_IGNORE_ARMOR_PCT, self:GetSpecialValueFor("armor_penetration"))
	hEntity:AddChild(self)
	DealAttackDamage(hEntity, tDamageTable)
	hEntity:RemoveChild(self)
	EmitSoundOn("Hero_DrowRanger.Bullseye.Impact", hTarget)
	return true
end