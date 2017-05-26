--[[
    Icewrack Skills
    
    Values listed are per point of that skill; magical skills do not provide any inherent benefits
	
	TWO-HANDED:
	    *20% increased accuracy with two-handed weapons
		*10% reduced BAT with two-handed weapons
	
	ONE-HANDED:
	    *20% increased accuracy with one-handed weapons
		*10% reduced BAT with two-handed weapons
	
	MARKSMANSHIP:
	    *20% increased accuracy with ranged weapons
		*10% reduced BAT with ranged weapons
	
	MARTIAL ARTS
	    *+15-20 Unarmed Crush Damage
	
	ARMOR:
	    *20% increased armor
	    *20% reduced encumbrance
	
	COMBAT:
	    *+1 Stamina/s regeneration
		*15% reduced stamina recharge time
		*15% reduced attack stamina cost
		
	ATHLETICS:
		*15% increased movement speed
		*15% reduced movement stamina cost
		
	SURVIVAL:
	    *+10% all resistances
		
	PERCEPTION:
	    *Hidden objects have a detection threshold which is checked against perception to become visible
	    *Some dialogue checks against perception to provide additional information
		
	LORE:
		*+10% XP gain
		*Increases your ability to identify objects
		
	SPEECH:
		*10% better shop prices
		*Persuasion dialogue options check against speech
		
	STEALTH:
		*15% reduced movement noise
		*15% reduced visibility
		
	THIEVERY:
		*Required to pick locks, disarm traps, and steal from enemies
]]

IW_MAX_ASSIGNABLE_SKILL = 5

if IsServer() and not modifier_internal_skill_bonus then

modifier_internal_skill_bonus = class({})

function modifier_internal_skill_bonus:OnRefresh()
	local hEntity = self:GetParent()
	local hAttackSource = hEntity:GetCurrentAttackSource()
	if hAttackSource then
		local nItemType = hAttackSource:GetItemType()
		if bit32.btest(nItemType, bit32.lshift(1, IW_ITEM_TYPE_WEAPON_BOW - 1)) then
			self:SetPropertyValue(IW_PROPERTY_ACCURACY_PCT, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_MARKSMAN) * 20)
			self:SetPropertyValue(IW_PROPERTY_BASE_ATTACK_PCT, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_MARKSMAN) * -10)
		elseif bit32.btest(nItemType, bit32.lshift(1, IW_ITEM_TYPE_WEAPON_2H - 1)) then
			self:SetPropertyValue(IW_PROPERTY_ACCURACY_PCT, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_TWOHAND) * 20)
			self:SetPropertyValue(IW_PROPERTY_BASE_ATTACK_PCT, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_TWOHAND) * -10)
		elseif bit32.btest(nItemType, bit32.lshift(1, IW_ITEM_TYPE_WEAPON_1H - 1)) then
			self:SetPropertyValue(IW_PROPERTY_ACCURACY_PCT, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_ONEHAND) * 20)
			self:SetPropertyValue(IW_PROPERTY_BASE_ATTACK_PCT, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_ONEHAND) * -10)
		else
			self:SetPropertyValue(IW_PROPERTY_ACCURACY_PCT, 0)
			self:SetPropertyValue(IW_PROPERTY_BASE_ATTACK_PCT, 0)
		end
		self:SetPropertyValue(IW_PROPERTY_DMG_CRUSH_BASE, 0)
		self:SetPropertyValue(IW_PROPERTY_DMG_CRUSH_VAR, 0)
	else
		--TODO: Add base unarmed damage
		self:SetPropertyValue(IW_PROPERTY_ACCURACY_PCT, 0)
		self:SetPropertyValue(IW_PROPERTY_BASE_ATTACK_PCT, 0)
		self:SetPropertyValue(IW_PROPERTY_DMG_CRUSH_BASE, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_UNARMED) * 15)
		self:SetPropertyValue(IW_PROPERTY_DMG_CRUSH_VAR, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_UNARMED) * 5)
	end
	
	self:SetPropertyValue(IW_PROPERTY_ARMOR_CRUSH_PCT, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_ARMOR) * 20)
	self:SetPropertyValue(IW_PROPERTY_ARMOR_SLASH_PCT, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_ARMOR) * 20)
	self:SetPropertyValue(IW_PROPERTY_ARMOR_PIERCE_PCT, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_ARMOR) * 20)
	self:SetPropertyValue(IW_PROPERTY_FATIGUE_MULTI, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_ARMOR) * -20)
	
	self:SetPropertyValue(IW_PROPERTY_SP_REGEN_FLAT, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_COMBAT) * 1.0)
	self:SetPropertyValue(IW_PROPERTY_ATTACK_SP_PCT, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_COMBAT) * -15.0)
	self:SetPropertyValue(IW_PROPERTY_SP_REGEN_TIME_PCT, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_COMBAT) * -15.0)
	
	self:SetPropertyValue(IW_PROPERTY_MOVE_SPEED_FLAT, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_ATHLETICS) * 15)
	self:SetPropertyValue(IW_PROPERTY_RUN_SP_PCT, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_ATHLETICS) * -15)
	
	self:SetPropertyValue(IW_PROPERTY_RESIST_FIRE, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_SURVIVAL) * 10)
	self:SetPropertyValue(IW_PROPERTY_RESIST_COLD, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_SURVIVAL) * 10)
	self:SetPropertyValue(IW_PROPERTY_RESIST_LIGHT, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_SURVIVAL) * 10)
	self:SetPropertyValue(IW_PROPERTY_RESIST_DEATH, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_SURVIVAL) * 10)
	
	self:SetPropertyValue(IW_PROPERTY_EXPERIENCE_MULTI, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_LORE) * 10)
	
	self:SetPropertyValue(IW_PROPERTY_SHOP_PRICE_PCT, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_SPEECH) * -10)
	
	self:SetPropertyValue(IW_PROPERTY_MOVE_NOISE_PCT, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_STEALTH) * -15)
	self:SetPropertyValue(IW_PROPERTY_VISIBILITY_PCT, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_STEALTH) * -15)
end

end