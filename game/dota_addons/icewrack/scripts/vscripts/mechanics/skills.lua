--[[
    Icewrack Skills
    
    Values listed are per point of that skill
	
	
	FIRE
	    *5% increased Fire resistance
		*10% increased Fire damage
	
	EARTH
	    *5% increased Physical resistance
		*10% increased Physical damage
	
	WATER
	    *5% increased Cold resistance
		*10% increased Cold damage
	
	AIR
	    *5% increased Lightning resistance
		*10% increased Lightning damage
	
	LIGHT
	    *20% increased line of sight radius
		
	SHADOW
	    *15% reduced visibility
		
	BODY
		*+1 SP/s regeneration
		
	MIND
		*+1 MP/s regeneration
		
	LIFE
		*+1 HP/s regeneration
		
	DEATH
	    *5% increased Death resistance
		*10% increased Death damage
		
	SHAPE
	    *+3 to all attributes
		
	METAMAGIC
	    *+10 spellpower
			
	
	TWO-HANDED:
	    *20% increased accuracy with two-handed weapons
		*10% reduced BAT with two-handed weapons
	
	ONE-HANDED:
	    *20% increased accuracy with one-handed weapons while not dual wielding
		*10% reduced BAT with one-handed weapons while not dual wielding
	
	MARKSMANSHIP:
	    *20% increased accuracy with ranged weapons
		*10% reduced BAT with ranged weapons
	
	DUAL WIELDING
	    *20% increased accuracy with one-handed weapons while dual wielding
		*10% reduced BAT with one-handed weapons while dual wielding
		
	HEAVY ARMOR
	    *20% increased armor
	    *10% reduced weight of equipped armor
		
	COMBAT
		*-0.5s stamina recharge time
		*10% reduced movement stamina cost
		*10% reduced attack stamina cost

	LEADERSHIP:
	    *Nearby allies deal 10% increased damage per point of Leadership (only the highest level applies)
		*Nearby allies take 5% reduced damage per point of Leadership
		
	SURVIVAL:
	    *20% increased dodge score
	    *+10 physical debuff defense
		*+10 magical debuff defense
		
	LORE:
	    *+20 to WIS
	    *Increases ability to identify/examine items and creatures
		
	SPEECHCRAFT:
		*10% better shop prices (TODO)
		*Increased attitude gains among party members/factions
		*Persuasion dialogue options check against speech (TODO)
		
	STEALTH:
		*10% reduced movement noise
		*10% reduced cast noise
		*10% reduced threat generated
		
	THIEVERY:
		*Required to pick locks and disarm traps (TODO)
		*Increases ability to find extra loot in objects/corpses
]]

stIcewrackSkillEnum =
{
	IW_SKILL_FIRE = 1,       IW_SKILL_TWOHAND = 13,
	IW_SKILL_EARTH = 2,	     IW_SKILL_ONEHAND = 14,
	IW_SKILL_WATER = 3,      IW_SKILL_MARKSMAN = 15,
	IW_SKILL_AIR = 4,        IW_SKILL_DUALWIELD = 16,
	IW_SKILL_LIGHT = 5,      IW_SKILL_ARMOR = 17,
	IW_SKILL_SHADOW = 6,     IW_SKILL_COMBAT = 18,
	IW_SKILL_BODY = 7,       IW_SKILL_LEADERSHIP = 19,
	IW_SKILL_MIND = 8,       IW_SKILL_SURVIVAL = 20,
	IW_SKILL_NATURE = 9,     IW_SKILL_LORE = 21,
	IW_SKILL_DEATH = 10,     IW_SKILL_SPEECH = 22,
	IW_SKILL_SHAPE = 11,     IW_SKILL_STEALTH = 23,
	IW_SKILL_METAMAGIC = 12, IW_SKILL_THIEVERY = 24,
}
for k,v in pairs(stIcewrackSkillEnum) do _G[k] = v end
stIcewrackSkillValues =
{
	[IW_SKILL_FIRE] = true,      [IW_SKILL_TWOHAND] = true,
	[IW_SKILL_EARTH] = true,     [IW_SKILL_ONEHAND] = true,
	[IW_SKILL_WATER] = true,     [IW_SKILL_MARKSMAN] = true,
	[IW_SKILL_AIR] = true,       [IW_SKILL_DUALWIELD] = true,
	[IW_SKILL_LIGHT] = true,     [IW_SKILL_ARMOR] = true,
	[IW_SKILL_SHADOW] = true,    [IW_SKILL_COMBAT] = true,
	[IW_SKILL_BODY] = true,      [IW_SKILL_LEADERSHIP] = true,
	[IW_SKILL_MIND] = true,      [IW_SKILL_SURVIVAL] = true,
	[IW_SKILL_NATURE] = true,    [IW_SKILL_LORE] = true,
	[IW_SKILL_DEATH] = true,     [IW_SKILL_SPEECH] = true,
	[IW_SKILL_SHAPE] = true,     [IW_SKILL_STEALTH] = true,
	[IW_SKILL_METAMAGIC] = true, [IW_SKILL_THIEVERY] = true,
}

IW_MAX_ASSIGNABLE_SKILL = 5

modifier_internal_skill_bonus = class({})
modifier_internal_skill_bonus_leadership_aura = class({})

function modifier_internal_skill_bonus:IsAura()
	return self:GetStackCount() > 0 and GameRules:State_Get() >= DOTA_GAMERULES_STATE_GAME_IN_PROGRESS
end

function modifier_internal_skill_bonus:GetModifierAura()
	return "modifier_internal_skill_bonus_leadership_aura"
end

function modifier_internal_skill_bonus:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_internal_skill_bonus:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_internal_skill_bonus:GetAuraRadius()
	return 900.0
end

function modifier_internal_skill_bonus:GetAuraEntityReject(hEntity)
	local hCaster = self:GetCaster()
	if not hCaster:IsAlive() then
		return true
	elseif hCaster ~= hEntity and hEntity:IsAlive() then
		local tModifierTable = hEntity:FindAllModifiersByName("modifier_internal_skill_bonus_leadership_aura")
		if #tModifierTable > 0 then
			for k,v in pairs(tModifierTable) do
				if v:GetCaster() ~= hCaster and v:GetStackCount() >= hCaster:GetPropertyValue(IW_PROPERTY_SKILL_LEADERSHIP) then
					return true
				end
			end
			--If this is the highest level leadership aura, remove all of the others (ignoring aura stickiness)
			for k,v in pairs(tModifierTable) do
				if v:GetCaster() ~= hCaster then
					v:Destroy()
				end
			end
		else
			if hEntity:GetPropertyValue(IW_PROPERTY_SKILL_LEADERSHIP) >= hCaster:GetPropertyValue(IW_PROPERTY_SKILL_LEADERSHIP) then
				return true
			end
		end
		return false
	else
		return true
	end
end

function modifier_internal_skill_bonus:IsAuraActiveOnDeath()
	return false
end

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
		elseif bit32.btest(nItemType, bit32.lshift(1, IW_ITEM_TYPE_WEAPON_1H - 1)) and not hEntity:IsDualWielding() then
			self:SetPropertyValue(IW_PROPERTY_ACCURACY_PCT, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_ONEHAND) * 20)
			self:SetPropertyValue(IW_PROPERTY_BASE_ATTACK_PCT, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_ONEHAND) * -10)
		elseif bit32.btest(nItemType, bit32.lshift(1, IW_ITEM_TYPE_WEAPON_1H - 1)) and hEntity:IsDualWielding() then
			self:SetPropertyValue(IW_PROPERTY_ACCURACY_PCT, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_DUALWIELD) * 20)
			self:SetPropertyValue(IW_PROPERTY_BASE_ATTACK_PCT, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_DUALWIELD) * -10)
		else
			self:SetPropertyValue(IW_PROPERTY_ACCURACY_PCT, 0)
			self:SetPropertyValue(IW_PROPERTY_BASE_ATTACK_PCT, 0)
		end
	else
		self:SetPropertyValue(IW_PROPERTY_ACCURACY_PCT, 0)
		self:SetPropertyValue(IW_PROPERTY_BASE_ATTACK_PCT, 0)
	end
	
	
	self:SetPropertyValue(IW_PROPERTY_DMG_FIRE_PCT, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_FIRE) * 10)
	self:SetPropertyValue(IW_PROPERTY_RESIST_FIRE, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_FIRE) * 5)
	
	self:SetPropertyValue(IW_PROPERTY_DMG_PHYS_PCT, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_EARTH) * 10)
	self:SetPropertyValue(IW_PROPERTY_RESIST_PHYS, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_EARTH) * 5)
	
	self:SetPropertyValue(IW_PROPERTY_DMG_COLD_PCT, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_WATER) * 10)
	self:SetPropertyValue(IW_PROPERTY_RESIST_COLD, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_WATER) * 5)
	
	self:SetPropertyValue(IW_PROPERTY_DMG_LIGHT_PCT, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_AIR) * 10)
	self:SetPropertyValue(IW_PROPERTY_RESIST_LIGHT, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_AIR) * 5)
	
	self:SetPropertyValue(IW_PROPERTY_VISION_RANGE_PCT, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_LIGHT) * 20)
	
	self:SetPropertyValue(IW_PROPERTY_VISIBILITY_PCT, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_SHADOW) * -15)
	
	self:SetPropertyValue(IW_PROPERTY_SP_REGEN_FLAT, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_BODY) * 1)
	
	self:SetPropertyValue(IW_PROPERTY_MP_REGEN_FLAT, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_MIND) * 1)
	
	self:SetPropertyValue(IW_PROPERTY_HP_REGEN_FLAT, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_LIFE) * 1)
	
	self:SetPropertyValue(IW_PROPERTY_DMG_DEATH_PCT, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_DEATH) * 10)
	self:SetPropertyValue(IW_PROPERTY_RESIST_DEATH, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_DEATH) * 5)
	
	self:SetPropertyValue(IW_PROPERTY_ATTR_STR_FLAT, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_SHAPE) * 3)
	self:SetPropertyValue(IW_PROPERTY_ATTR_CON_FLAT, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_SHAPE) * 3)
	self:SetPropertyValue(IW_PROPERTY_ATTR_AGI_FLAT, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_SHAPE) * 3)
	self:SetPropertyValue(IW_PROPERTY_ATTR_PER_FLAT, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_SHAPE) * 3)
	self:SetPropertyValue(IW_PROPERTY_ATTR_INT_FLAT, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_SHAPE) * 3)
	self:SetPropertyValue(IW_PROPERTY_ATTR_WIS_FLAT, (hEntity:GetPropertyValue(IW_PROPERTY_SKILL_SHAPE) * 3) + (hEntity:GetPropertyValue(IW_PROPERTY_SKILL_LORE) * 20))
	
	self:SetPropertyValue(IW_PROPERTY_SPELLPOWER, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_METAMAGIC) * 10.0)
	
	self:SetPropertyValue(IW_PROPERTY_ARMOR_CRUSH_PCT, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_ARMOR) * 20)
	self:SetPropertyValue(IW_PROPERTY_ARMOR_SLASH_PCT, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_ARMOR) * 20)
	self:SetPropertyValue(IW_PROPERTY_ARMOR_PIERCE_PCT, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_ARMOR) * 20)
	self:SetPropertyValue(IW_PROPERTY_EQUIP_WEIGHT_PCT, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_ARMOR) * -10)
	
	self:SetPropertyValue(IW_PROPERTY_SP_RECHARGE_PCT, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_COMBAT) * 5)
	self:SetPropertyValue(IW_PROPERTY_SP_RECHARGE_TIME, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_COMBAT) * -0.5)
	self:SetPropertyValue(IW_PROPERTY_RUN_SP_PCT, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_COMBAT) * -10)
	self:SetPropertyValue(IW_PROPERTY_SP_COST_PCT, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_COMBAT) * -10)
	
	self:SetPropertyValue(IW_PROPERTY_DODGE_PCT, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_SURVIVAL) * 20)
	self:SetPropertyValue(IW_PROPERTY_DEFENSE_PHYS, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_SURVIVAL) * 10)
	self:SetPropertyValue(IW_PROPERTY_DEFENSE_MAGIC, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_SURVIVAL) * 10)
	
	self:SetPropertyValue(IW_PROPERTY_PRICE_MULTI, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_SPEECH) * 10)
	
	self:SetPropertyValue(IW_PROPERTY_MOVE_NOISE_PCT, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_STEALTH) * -10)
	self:SetPropertyValue(IW_PROPERTY_CAST_NOISE_PCT, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_STEALTH) * -10)
	self:SetPropertyValue(IW_PROPERTY_THREAT_MULTI, hEntity:GetPropertyValue(IW_PROPERTY_SKILL_STEALTH) * -10)
	
	self:SetStackCount(hEntity:GetPropertyValue(IW_PROPERTY_SKILL_LEADERSHIP))
end

function modifier_internal_skill_bonus_leadership_aura:OnCreated(args)
	if IsServer() then
		local nLeadershipLevel = self:GetCaster():GetPropertyValue(IW_PROPERTY_SKILL_LEADERSHIP)
		self:SetPropertyValue(IW_PROPERTY_DMG_PURE_PCT, nLeadershipLevel * 10.0)
		self:SetPropertyValue(IW_PROPERTY_DMG_PHYS_PCT, nLeadershipLevel * 10.0)
		self:SetPropertyValue(IW_PROPERTY_DMG_FIRE_PCT, nLeadershipLevel * 10.0)
		self:SetPropertyValue(IW_PROPERTY_DMG_COLD_PCT, nLeadershipLevel * 10.0)
		self:SetPropertyValue(IW_PROPERTY_DMG_LIGHT_PCT, nLeadershipLevel * 10.0)
		self:SetPropertyValue(IW_PROPERTY_DMG_DEATH_PCT, nLeadershipLevel * 10.0)
		self:SetPropertyValue(IW_PROPERTY_DAMAGE_MULTI, nLeadershipLevel * -5.0)
		self:SetStackCount(nLeadershipLevel)
		--TODO: Add some visual effects for the leadership aura?
	else
		self._tModifierArgs["damage_out"] = self:GetStackCount() * 10.0
		self._tModifierArgs["damage_in"] = self:GetStackCount() * -5.0
		self:BuildTextureArgsString()
	end
end