modifier_iw_dragon_knight_razorscales = class({})

function modifier_iw_dragon_knight_razorscales:DeclareExtEvents()
	local funcs =
	{
		[IW_MODIFIER_EVENT_ON_TAKE_ATTACK_DAMAGE] = 1,
	}
	return funcs
end

function modifier_iw_dragon_knight_razorscales:RecalculateArmorValue()
	local hEntity = self:GetParent()
	local hAbility = self:GetAbility() or self._hAbility
	local fTotalArmor = hEntity:GetArmor(IW_DAMAGE_TYPE_CRUSH)
	local fBaseDamage = hAbility:GetSpecialValueFor("damage")
	local fDamagePercent = hAbility:GetSpecialValueFor("percent")/100.0
	fTotalArmor = fTotalArmor + hEntity:GetArmor(IW_DAMAGE_TYPE_SLASH)
	fTotalArmor = fTotalArmor + hEntity:GetArmor(IW_DAMAGE_TYPE_PIERCE)
	self._fDamageAmount = fBaseDamage + (fTotalArmor * fDamagePercent)
end

function modifier_iw_dragon_knight_razorscales:OnCreated(args)
	if IsServer() then
		self._hAbility = self:GetAbility()
		self:RecalculateArmorValue()
	end
end

function modifier_iw_dragon_knight_razorscales:OnRefresh(args)
	if IsServer() then
		self:RecalculateArmorValue()
	end
end

function modifier_iw_dragon_knight_razorscales:OnTakeAttackDamage(args)
	local hEntity = self:GetParent()
	local hTarget = args.attacker
	if args.target == hEntity and not hTarget:IsRangedAttacker() then
		local tDamageTable =
		{
			attacker = hEntity,
			target = hTarget,
			source = self,
			damage =
			{
				[IW_DAMAGE_TYPE_SLASH] = 
				{
					min = self._fDamageAmount,
					max = self._fDamageAmount,
				}
			}
		}
		
		local nParticleID = ParticleManager:CreateParticle("particles/units/heroes/hero_dragon_knight/iw_dragon_knight_razorscales.vpcf", PATTACH_CUSTOMORIGIN, hEntity)
		ParticleManager:SetParticleControlEnt(nParticleID, 0, hEntity, PATTACH_POINT_FOLLOW, "attach_hitloc", hEntity:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(nParticleID, 1, hTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", hTarget:GetAbsOrigin(), true)
		ParticleManager:ReleaseParticleIndex(nParticleID)
		
		DealPrimaryDamage(self, tDamageTable)
	end
end