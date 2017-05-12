--[[
    Icewrack Instances
]]

if not CInstance then 

require("mechanics/attributes")
require("mechanics/damage_types")
require("mechanics/status_effects")

--TODO: Implement reduced armor when attacking from rear (flanking)
--TODO: Implement shop price percent 

IW_INSTANCE_DYNAMIC_BASE = 0x80000000	--The base ID used for dynamic (non-spawn) instances created throughout the game

stInstanceTypeEnum =
{
	IW_INSTANCE_EXT_ENTITY = 1,
	IW_INSTANCE_EXT_ITEM = 2,
	IW_INSTANCE_EXT_ABILITY = 3,
	IW_INSTANCE_EXT_MODIFIER = 4,
	IW_INSTANCE_CONTAINER = 5,
	IW_INSTANCE_PROP = 6
}

stIcewrackPropertyEnum =
{
	IW_PROPERTY_ATTR_STR_FLAT = 1,       IW_PROPERTY_ATTR_END_FLAT = 2,       IW_PROPERTY_ATTR_AGI_FLAT = 3,       IW_PROPERTY_ATTR_CUN_FLAT = 4,
	IW_PROPERTY_ATTR_INT_FLAT = 5,       IW_PROPERTY_ATTR_WIS_FLAT = 6,       IW_PROPERTY_ATTR_STR_PCT = 7,        IW_PROPERTY_ATTR_END_PCT = 8,
	IW_PROPERTY_ATTR_AGI_PCT = 9,        IW_PROPERTY_ATTR_CUN_PCT = 10,       IW_PROPERTY_ATTR_INT_PCT = 11,       IW_PROPERTY_ATTR_WIS_PCT = 12,
	IW_PROPERTY_MAX_HP_PCT = 13,         IW_PROPERTY_MAX_MP_PCT = 14,         IW_PROPERTY_MAX_SP_FLAT = 15,        IW_PROPERTY_MAX_SP_PCT = 16,
	IW_PROPERTY_SP_REGEN_FLAT = 17,      IW_PROPERTY_SP_REGEN_PCT = 18,       IW_PROPERTY_MAX_SP_REGEN = 19,       IW_PROPERTY_HP_REGEN_FLAT = 20,
	IW_PROPERTY_HP_REGEN_PCT = 21,       IW_PROPERTY_MAX_HP_REGEN = 22,       IW_PROPERTY_MP_REGEN_FLAT = 23,      IW_PROPERTY_MP_REGEN_PCT = 24,
	IW_PROPERTY_MAX_MP_REGEN = 25,       IW_PROPERTY_ATTACK_SP_FLAT = 26,     IW_PROPERTY_ATTACK_SP_PCT = 27,      IW_PROPERTY_RUN_SP_FLAT = 28,
	IW_PROPERTY_RUN_SP_PCT = 29,         IW_PROPERTY_THREAT_MULTI = 30,       IW_PROPERTY_ATTACK_RANGE = 31,       IW_PROPERTY_BASE_ATTACK_TIME = 32,
	IW_PROPERTY_MOVE_SPEED_FLAT = 33,    IW_PROPERTY_MOVE_SPEED_PCT = 34,     IW_PROPERTY_CAST_SPEED = 35,         IW_PROPERTY_SPELLPOWER = 36,
	IW_PROPERTY_CRIT_CHANCE_FLAT = 37,   IW_PROPERTY_CRIT_MULTI_FLAT = 38,    IW_PROPERTY_CRIT_CHANCE_PCT = 39,    IW_PROPERTY_CRIT_MULTI_PCT = 40,
	IW_PROPERTY_ARMOR_CRUSH_FLAT = 41,   IW_PROPERTY_ARMOR_SLASH_FLAT = 42,   IW_PROPERTY_ARMOR_PIERCE_FLAT = 43,  IW_PROPERTY_ARMOR_CRUSH_PCT = 44,
    IW_PROPERTY_ARMOR_SLASH_PCT = 45,    IW_PROPERTY_ARMOR_PIERCE_PCT = 46,   IW_PROPERTY_IGNORE_ARMOR_FLAT = 47,  IW_PROPERTY_IGNORE_ARMOR_PCT = 48,
	IW_PROPERTY_EXPERIENCE_MULTI = 49,   IW_PROPERTY_PRICE_MULTI = 50,        IW_PROPERTY_RESIST_PHYS = 51,        IW_PROPERTY_RESIST_FIRE = 52,
	IW_PROPERTY_RESIST_COLD = 53,        IW_PROPERTY_RESIST_LIGHT = 54,       IW_PROPERTY_RESIST_DEATH = 55,       IW_PROPERTY_RESMAX_PHYS = 56,
	IW_PROPERTY_RESMAX_FIRE = 57,        IW_PROPERTY_RESMAX_COLD = 58,        IW_PROPERTY_RESMAX_LIGHT = 59,       IW_PROPERTY_RESMAX_DEATH = 60,
	IW_PROPERTY_ACCURACY_FLAT = 61,      IW_PROPERTY_ACCURACY_PCT = 62,       IW_PROPERTY_DODGE_FLAT = 63,         IW_PROPERTY_DODGE_PCT = 64, 	
	IW_PROPERTY_BUFF_SELF = 65,          IW_PROPERTY_DEBUFF_SELF = 66,        IW_PROPERTY_BUFF_OTHER = 67,         IW_PROPERTY_DEBUFF_OTHER = 68,
	IW_PROPERTY_HEAL_MULTI = 69,         IW_PROPERTY_DAMAGE_MULTI = 70,       IW_PROPERTY_FATIGUE_MULTI = 71,      IW_PROPERTY_DRAIN_MULTI = 72,
	IW_PROPERTY_STATUS_STUN = 73,        IW_PROPERTY_STATUS_SLOW = 74,        IW_PROPERTY_STATUS_SILENCE = 75,     IW_PROPERTY_STATUS_ROOT = 76,
	IW_PROPERTY_STATUS_DISARM = 77,      IW_PROPERTY_STATUS_PACIFY = 78,      IW_PROPERTY_STATUS_WEAKEN = 79,      IW_PROPERTY_STATUS_SLEEP = 80,
	IW_PROPERTY_STATUS_FEAR = 81,        IW_PROPERTY_STATUS_CHARM = 82,       IW_PROPERTY_STATUS_ENRAGE = 83,      IW_PROPERTY_STATUS_EXHAUST = 84,
	IW_PROPERTY_STATUS_FREEZE = 85,      IW_PROPERTY_STATUS_CHILL = 86,       IW_PROPERTY_STATUS_WET = 87,         IW_PROPERTY_STATUS_BURNING = 88,
	IW_PROPERTY_STATUS_POISON = 89,      IW_PROPERTY_STATUS_BLEED = 90,       IW_PROPERTY_STATUS_BLIND = 91,       IW_PROPERTY_STATUS_PETRIFY = 92,
	IW_PROPERTY_DEFENSE_PHYS = 93,       IW_PROPERTY_DEFENSE_MAGIC = 94,      IW_PROPERTY_AVOID_BASH = 95,         IW_PROPERTY_AVOID_MAIM = 96,
	IW_PROPERTY_AVOID_BLEED = 97,        IW_PROPERTY_AVOID_BURN = 98,         IW_PROPERTY_AVOID_CHILL = 99,        IW_PROPERTY_AVOID_SHOCK = 100,
	IW_PROPERTY_AVOID_WEAKEN = 101,      IW_PROPERTY_AVOID_CRIT = 102,        IW_PROPERTY_CHANCE_BASH = 103,       IW_PROPERTY_CHANCE_MAIM = 104,
	IW_PROPERTY_CHANCE_BLEED = 105,      IW_PROPERTY_CHANCE_BURN = 106,       IW_PROPERTY_CHANCE_CHILL = 107,      IW_PROPERTY_CHANCE_SHOCK = 108,
	IW_PROPERTY_CHANCE_WEAKEN = 109,     IW_PROPERTY_DMG_PURE_BASE = 110,     IW_PROPERTY_DMG_CRUSH_BASE = 111,    IW_PROPERTY_DMG_SLASH_BASE = 112,
	IW_PROPERTY_DMG_PIERCE_BASE = 113,   IW_PROPERTY_DMG_FIRE_BASE = 114,     IW_PROPERTY_DMG_COLD_BASE = 115,     IW_PROPERTY_DMG_LIGHT_BASE = 116,
	IW_PROPERTY_DMG_DEATH_BASE = 117,    IW_PROPERTY_DMG_PURE_VAR = 118,      IW_PROPERTY_DMG_CRUSH_VAR = 119,     IW_PROPERTY_DMG_SLASH_VAR = 120,
	IW_PROPERTY_DMG_PIERCE_VAR = 121,    IW_PROPERTY_DMG_FIRE_VAR = 122,      IW_PROPERTY_DMG_COLD_VAR = 123,      IW_PROPERTY_DMG_LIGHT_VAR = 124,
	IW_PROPERTY_DMG_DEATH_VAR = 125,     IW_PROPERTY_DMG_PURE_PCT = 126,      IW_PROPERTY_DMG_PHYS_PCT = 127,      IW_PROPERTY_DMG_FIRE_PCT = 128,
	IW_PROPERTY_DMG_COLD_PCT = 129,      IW_PROPERTY_DMG_LIGHT_PCT = 130,     IW_PROPERTY_DMG_DEATH_PCT = 131,     IW_PROPERTY_DMG_DOT_PCT = 132,
	IW_PROPERTY_LIFESTEAL_PCT = 133,     IW_PROPERTY_LIFESTEAL_RATE = 134,    IW_PROPERTY_MANASHIELD_PCT = 135,    IW_PROPERTY_SECONDWIND_PCT = 136,
	IW_PROPERTY_SKILL_FIRE = 137,        IW_PROPERTY_SKILL_EARTH = 138,       IW_PROPERTY_SKILL_WATER = 139,       IW_PROPERTY_SKILL_AIR = 140,
	IW_PROPERTY_SKILL_LIGHT = 141,       IW_PROPERTY_SKILL_SHADOW = 142,      IW_PROPERTY_SKILL_BODY = 143,        IW_PROPERTY_SKILL_MIND = 144,      
	IW_PROPERTY_SKILL_NATURE = 145,      IW_PROPERTY_SKILL_DEATH = 146,       IW_PROPERTY_SKILL_DIVINE = 147,      IW_PROPERTY_SKILL_SHAPE = 148,
	IW_PROPERTY_SKILL_META = 149,        IW_PROPERTY_SKILL_TWOHAND = 150,     IW_PROPERTY_SKILL_ONEHAND = 151,     IW_PROPERTY_SKILL_MARKSMAN = 152,
	IW_PROPERTY_SKILL_UNARMED = 153,     IW_PROPERTY_SKILL_ARMOR = 154,       IW_PROPERTY_SKILL_COMBAT = 155,      IW_PROPERTY_SKILL_ATHLETICS = 156,
	IW_PROPERTY_SKILL_SURVIVAL = 157,    IW_PROPERTY_SKILL_PERCEPTION = 158,  IW_PROPERTY_SKILL_LORE = 159,        IW_PROPERTY_SKILL_SPEECH = 160,
	IW_PROPERTY_SKILL_STEALTH = 161,     IW_PROPERTY_SKILL_THIEVERY = 162,    IW_PROPERTY_ATTRIBUTE_POINTS = 163,  IW_PROPERTY_SKILL_POINTS = 164,
	IW_PROPERTY_MOVE_NOISE_FLAT = 165,   IW_PROPERTY_MOVE_NOISE_PCT = 166,    IW_PROPERTY_CAST_NOISE_FLAT = 167,   IW_PROPERTY_CAST_NOISE_PCT = 168,
	IW_PROPERTY_NIGHT_VISION = 169,      IW_PROPERTY_VISIBILITY_FLAT = 170,   IW_PROPERTY_VISIBILITY_PCT = 171,    IW_PROPERTY_BEHAVIOR_AGGRO = 172,
	IW_PROPERTY_BEHAVIOR_COOP = 173,     IW_PROPERTY_BEHAVIOR_SAFETY = 174,   IW_PROPERTY_CORPSE_TIME = 175,       IW_PROPERTY_ATK_SPEED_DUMMY = 176,
}

for k,v in pairs(stInstanceTypeEnum) do _G[k] = v end
for k,v in pairs(stIcewrackPropertyEnum) do _G[k] = v end

stIcewrackPropertiesName = 
{
	StrengthFlat = 1,                  EnduranceFlat = 2,                 AgilityFlat = 3,                   CunningFlat = 4,
	IntelligenceFlat = 5,              WisdomFlat = 6,                    StrengthPercent = 7,               EndurancePercent = 8,
	AgilityPercent = 9,                CunningPercent = 10,               IntelligencePercent = 11,          WisdomPercent = 12,
	MaxHealthPercent = 13,             MaxManaPercent = 14,               MaxStaminaFlat = 15,               MaxStaminaPercent = 16,
	StaminaRegenFlat = 17,             StaminaRegenPercent = 18,          MaxStaminaPercentRegen = 19,       HealthRegenFlat = 20,
	HealthRegenPercent = 21,           MaxHealthPercentRegen = 22,        ManaRegenFlat = 23,                ManaRegenPercent = 24,
	MaxManaPercentRegen = 25,          StaminaUsageAttackFlat = 26,       StaminaUsageAttackPercent = 27,    StaminaUsageRunFlat = 28,
	StaminaUsageRunPercent = 29,       ThreatMultiplier = 30,             AttackRange = 31,                  BaseAttackTime = 32,
	MovementSpeedFlat = 33,            MovementSpeedPercent = 34,         CastSpeed = 35,                    Spellpower = 36,
	BaseCritChance = 37,               BaseCritMultiplier = 38,           CritChance = 39,                   CritMultiplier = 40,
	ArmorCrushFlat = 41,               ArmorSlashFlat = 42,               ArmorPierceFlat = 43,              ArmorCrushPercent = 44,
	ArmorSlashPercent = 45,            ArmorPiercePercent = 46,           IgnoreArmorFlat = 47,              IgnoreArmorPercent = 48,
	ExperienceMultiplier = 49,         ShopPriceMultiplier = 50,          ResistPhysical = 51,               ResistFire = 52,
	ResistCold = 53,                   ResistLightning = 54,              ResistDeath = 55,                  MaxResistPhysical = 56,
	MaxResistFire = 57,                MaxResistCold = 58,                MaxResistLightning = 59,           MaxResistDeath = 60,
	AccuracyFlat = 61,                 AccuracyPercent = 62,              DodgeFlat = 63,                    DodgePercent = 64,
	BuffDurationSelf = 65,             DebuffDurationSelf = 66,           BuffDurationOther = 67,            DebuffDurationOther = 68,
	HealMultiplier = 69,               DamageMultiplier = 70,             FatigueMultiplier = 71,            DrainMultiplier = 72,
	EffectDurationStun = 73,           EffectDurationSlow = 74,           EffectDurationSilence = 75,        EffectDurationRoot = 76,
	EffectDurationDisarm = 77,         EffectDurationPacify = 78,         EffectDurationWeaken = 79,         EffectDurationSleep = 80,
	EffectDurationFear = 81,           EffectDurationCharm = 82,          EffectDurationEnrage = 83,         EffectDurationExhaustion = 84,
	EffectDurationFreeze = 85,         EffectDurationChill = 86,          EffectDurationWet = 87,            EffectDurationBurning = 88,
	EffectDurationPoison = 89,         EffectDurationBleed = 90,          EffectDurationBlind = 91,          EffectDurationPetrify = 92,
	EffectDefensePhysical = 93,        EffectDefenseMagic = 94,           EffectAvoidBash = 95,              EffectAvoidMaim = 96,
	EffectAvoidBleed = 97,             EffectAvoidBurn = 98,              EffectAvoidChill = 99,             EffectAvoidShock = 100,
	EffectAvoidWeaken = 101,           EffectAvoidCrit = 102,             EffectChanceBash = 103,            EffectChanceMaim = 104,
	EffectChanceBleed = 105,           EffectChanceBurn = 106,            EffectChanceChill = 107,           EffectChanceShock = 108,
	EffectChanceWeaken = 109,          DamagePureBase = 110,              DamageCrushBase = 111,             DamageSlashBase = 112,
	DamagePierceBase = 113,            DamageFireBase = 114,              DamageColdBase = 115,              DamageLightningBase = 116,
	DamageDeathBase = 117,             DamagePureVar = 118,               DamageCrushVar = 119,              DamageSlashVar = 120,
	DamagePierceVar = 121,             DamageFireVar = 122,               DamageColdVar = 123,               DamageLightningVar = 124,
	DamageDeathVar = 125,              DamagePurePercent = 126,           DamagePhysicalPercent = 127,       DamageFirePercent = 128,
	DamageColdPercent = 129,           DamageLightningPercent = 130,      DamageDeathPercent = 131,          DamageOverTimePercent = 132,
	LifestealPercent = 133,            LifestealRate = 134,               ManaShieldPercent = 135,           SecondWindPercent = 136,
	SkillFire = 137,                   SkillEarth = 138,                  SkillWater = 139,                  SkillAir = 140,
	SkillLight = 141,                  SkillShadow = 142,                 SkillBody = 143,                   SkillMind = 144,
	SkillNature = 145,                 SkillDeath = 146,                  SkillDivine = 147,                 SkillShape = 148,
	SkillMetamagic = 149,              SkillTwoHanded = 150,              SkillOneHanded = 151,              SkillMarksmanship = 152,
	SkillUnarmed = 153,                SkillArmor = 154,                  SkillCombat = 155,                 SkillAthletics = 156,
	SkillSurvival = 157,               SkillPerception = 158,             SkillLore = 159,                   SkillSpeech = 160,
	SkillStealth = 161,                SkillThievery = 162,               AttributePoints = 163,             SkillPoints = 164,
	MovementNoiseFlat = 165,           MovementNoisePercent = 166,        CastNoiseFlat = 167,               CastNoisePercent = 168,
	NightVision = 169,                 VisibilityFlat = 170,              VisibilityPercent = 171,           BehaviorAggressiveness = 172,
	BehaviorCooperativeness = 173,     BehaviorSafety = 174,              CorpseTime = 175,                  AttackSpeedDummy = 176,
}

stIcewrackPropertyValues = {}
for k,v in pairs(stIcewrackPropertyEnum) do stIcewrackPropertyValues[v] = true end

local stPropertyMetatable = {__index =
	function(self, k)
		if stIcewrackPropertyValues[k] then
			return 0
		end
		return nil
	end}
	
local function GetInstanceID(hInstance)
	return hInstance._nInstanceID
end

local tIndexTableList = {}
CInstance = 
{
	_bAllowDynamicInstances = true,
	_nNextDynamicID = IW_INSTANCE_DYNAMIC_BASE,
	_tInstanceList = {},
}
CInstance = setmetatable(CInstance, { __call = 
	function(self, hInstance, nInstanceID)
		if nInstanceID then
			LogAssert(type(nInstanceID) == "number", "Type mismatch (expected \"%s\", got %s)", "number", type(nInstanceID))
		end
		if hInstance._bIsInstance or (not CInstance._bAllowDynamicInstances and not hInstance) then
			LogMessage("Failed to create instance \"" .. nInstanceID .. "\" - dynamic instances are currently disabled", LOG_SEVERITY_WARNING)
			return hInstance
		elseif nInstanceID and CInstance._tInstanceList[nInstanceID] then
			LogMessage("Failed to create instance \"" .. nInstanceID .. "\" - another instance with this ID already exists", LOG_SEVERITY_WARNING)
		end
		
		local tBaseIndexTable = getmetatable(hInstance) and getmetatable(hInstance).__index or {}
		local tExtIndexTable = tIndexTableList[tBaseIndexTable]
		if not tExtIndexTable then
			tExtIndexTable = ExtendIndexTable(hInstance, CInstance)
			tIndexTableList[tBaseIndexTable] = tExtIndexTable
		end
		setmetatable(hInstance, tExtIndexTable)

		hInstance._bIsInstance = true
		hInstance._tPropertyValues = setmetatable({}, stPropertyMetatable)
		hInstance._tChildrenInstances = {}
		
		if not nInstanceID then
			hInstance._nInstanceID = CInstance._nNextDynamicID
			hInstance.GetInstanceID = GetInstanceID
			CInstance._nNextDynamicID = CInstance._nNextDynamicID + 1
		else
			hInstance._nInstanceID = nInstanceID
			hInstance.GetInstanceID = GetInstanceID
		end
		
		CInstance._tInstanceList[hInstance._nInstanceID] = hInstance
		return hInstance
	end})

function CInstance:SetAllowDynamicInstances(bState)
	if type(bState) == "boolean" then
		CInstance._bAllowDynamicInstances = bState
	end
end	

function CInstance:AddChild(hNode)
	if IsValidInstance(hNode) and hNode ~= self then
		self._tChildrenInstances[hNode] = true
	end
end

function CInstance:RemoveChild(hNode)
	if IsValidInstance(hNode) and self._tChildrenInstances[hNode] then
		self._tChildrenInstances[hNode] = nil
	end
end

function CInstance:GetBasePropertyValue(nProperty)
	return self._tPropertyValues[nProperty]
end

function CInstance:GetPropertyValue(nProperty)
	local fPropertyValue = self._tPropertyValues[nProperty]
	for k,v in pairs(self._tChildrenInstances) do
		fPropertyValue = fPropertyValue + k:GetPropertyValue(nProperty)
	end
	return fPropertyValue
end

function CInstance:GetPropertyValueClamped(nProperty, fMin, fMax)
	return math.min(fMax, math.max(fMin, self:GetPropertyValue(nProperty)))
end

function CInstance:SetPropertyValue(nProperty, fValue)
	if type(nProperty) == "string" then
		nProperty = stIcewrackPropertyEnum[k] or stIcewrackPropertiesName[k]
		if not nProperty then return end
	end
	if stIcewrackPropertyValues[nProperty] then
		if type(fValue) == "table" then
			for k,v in pairs(fValue) do
				if type(k) == "number" and type(v) == "number" then
					self._tPropertyValues[nProperty] = k + (RandomInt(0, 2147483647) % v)
					return
				end
			end
		elseif type(fValue) == "number" then
			self._tPropertyValues[nProperty] = fValue
		end
	end
end

function CInstance:GetAttributeValue(nAttribute)
	if stIcewrackAttributeValues[nAttribute] then
		local fAttributeBase = self:GetPropertyValue(IW_PROPERTY_ATTR_STR_FLAT  + nAttribute)
		local fAttributePercent = 1.0 + self:GetPropertyValue(IW_PROPERTY_ATTR_STR_PCT + nAttribute)/100.0
	    return math.floor(fAttributeBase * fAttributePercent)
	end
end

function CInstance:GetArmor(nDamageType)
	if stIcewrackDamageTypeValues[nDamageType] and nDamageType >= IW_DAMAGE_TYPE_CRUSH and nDamageType <= IW_DAMAGE_TYPE_PIERCE then
		return math.max(0, self:GetPropertyValue(IW_PROPERTY_ARMOR_CRUSH_FLAT + nDamageType - 1) * (1.0 + self:GetPropertyValue(IW_PROPERTY_ARMOR_CRUSH_PCT + nDamageType - 1)/100.0))
	end
end

function CInstance:GetResistance(nDamageType)
	if stIcewrackDamageTypeValues[nDamageType] and nDamageType ~= IW_DAMAGE_TYPE_PURE then
		nDamageType = math.max(0, nDamageType - 3)
		return self:GetPropertyValue(IW_PROPERTY_RESIST_PHYS + nDamageType)/100.0
	end
end

function CInstance:GetMaxResistance(nDamageType)
	if stIcewrackDamageTypeValues[nDamageType] and nDamageType ~= IW_DAMAGE_TYPE_PURE then
		nDamageType = math.max(0, nDamageType - 3)
	    return self:GetPropertyValue(IW_PROPERTY_RESMAX_PHYS + nDamageType)/100.0
	end
end

function CInstance:GetBaseDamageMin(nDamageType)
	if stIcewrackDamageTypeValues[nDamageType] then
	    return self:GetBasePropertyValue(IW_PROPERTY_DMG_PURE_BASE + nDamageType)
	end
end

function CInstance:GetDamageMin(nDamageType)
	if stIcewrackDamageTypeValues[nDamageType] then
	    return self:GetPropertyValue(IW_PROPERTY_DMG_PURE_BASE + nDamageType)
	end
end

function CInstance:GetBaseDamageMax(nDamageType)
	if stIcewrackDamageTypeValues[nDamageType] then
	    return self:GetBasePropertyValue(IW_PROPERTY_DMG_PURE_BASE + nDamageType) + math.max(0, self:GetPropertyValue(IW_PROPERTY_DMG_PURE_VAR + nDamageType))
	end
end

function CInstance:GetDamageMax(nDamageType)
	if stIcewrackDamageTypeValues[nDamageType] then
	    return self:GetPropertyValue(IW_PROPERTY_DMG_PURE_BASE + nDamageType) + math.max(0, self:GetPropertyValue(IW_PROPERTY_DMG_PURE_VAR + nDamageType))
	end
end

function CInstance:GetAttackDamage(nDamageType)
	if stIcewrackDamageTypeValues[nDamageType] then
		return RandomFloat(self:GetAttackDamageMin(nPropertyType), self:GetAttackDamageMax(nPropertyType))
	end
end

function CInstance:GetMaxStamina()
    return (self:GetPropertyValue(IW_PROPERTY_MAX_SP_FLAT) + (self:GetAttributeValue(IW_ATTRIBUTE_ENDURANCE) * 1.0)) * (1.0 + self:GetPropertyValue(IW_PROPERTY_MAX_SP_PCT)/100.0)
end

function CInstance:GetStaminaRegen()
	return (self:GetPropertyValue(IW_PROPERTY_SP_REGEN_FLAT) + (self:GetPropertyValue(IW_PROPERTY_MAX_SP_REGEN)/100.0 * self:GetMaxStamina())) * (1.0 + self:GetPropertyValue(IW_PROPERTY_SP_REGEN_PCT)/100.0)
end

function CInstance:GetCarryCapacity()
	return (self:GetAttributeValue(IW_ATTRIBUTE_STRENGTH) * 2.0)
end

function CInstance:GetCastSpeed()
	return self:GetPropertyValue(IW_PROPERTY_CAST_SPEED)
end

function CInstance:GetSpellpower()
	return self:GetPropertyValue(IW_PROPERTY_SPELLPOWER)
end

function CInstance:GetCriticalStrikeChance()
	return self:GetBasePropertyValue(IW_PROPERTY_CRIT_CHANCE_FLAT) * (1.00 + (self:GetAttributeValue(IW_ATTRIBUTE_CUNNING) * 0.05) + self:GetPropertyValue(IW_PROPERTY_CRIT_CHANCE_PCT)/100.0)
end

function CInstance:GetCriticalStrikeMultiplierMin()
	return self:GetPropertyValue(IW_PROPERTY_CRIT_MULTI_FLAT)
end

function CInstance:GetCriticalStrikeMultiplierMax()
	return self:GetBasePropertyValue(IW_PROPERTY_CRIT_MULTI_FLAT) * (1.00 + (self:GetAttributeValue(IW_ATTRIBUTE_CUNNING) * 0.05) + self:GetPropertyValue(IW_PROPERTY_CRIT_MULTI_PCT)/100.0)
end

function CInstance:GetCriticalStrikeMultiplier()
	return RandomFloat(self:GetCriticalStrikeMultiplierMin(), self:GetCriticalStrikeMultiplierMax())
end

function CInstance:GetCriticalStrikeAvoidance()
	return self:GetPropertyValue(IW_PROPERTY_AVOID_CRIT)/100.0
end

function CInstance:GetSelfBuffDuration()
	return math.max(0, 1.0 + self:GetPropertyValue(IW_PROPERTY_BUFF_SELF)/100.0)
end

function CInstance:GetOtherBuffDuration()
	return math.max(0, 1.0 + self:GetPropertyValue(IW_PROPERTY_BUFF_OTHER)/100.0 + (self:GetAttributeValue(IW_ATTRIBUTE_WISDOM) * 0.005))
end

function CInstance:GetSelfDebuffDuration()
	return math.max(0, 1.0 + self:GetPropertyValue(IW_PROPERTY_DEBUFF_SELF)/100.0)
end

function CInstance:GetOtherDebuffDuration()
	return math.max(0, 1.0 + self:GetPropertyValue(IW_PROPERTY_DEBUFF_OTHER)/100.0 + (self:GetAttributeValue(IW_ATTRIBUTE_WISDOM) * 0.005))
end

function CInstance:GetAccuracyScore()
    local fAccuracyScore = self:GetPropertyValue(IW_PROPERTY_ACCURACY_FLAT) + (self:GetAttributeValue(IW_ATTRIBUTE_AGILITY) * 1.00)
	return math.max(0, fAccuracyScore * (1.0 + self:GetPropertyValue(IW_PROPERTY_ACCURACY_PCT)/100.0))
end

function CInstance:GetDodgeScore()
    local fDodgeScore = self:GetPropertyValue(IW_PROPERTY_DODGE_FLAT) + (self:GetAttributeValue(IW_ATTRIBUTE_AGILITY) * 1.00)
	return math.max(0, fDodgeScore * (1.0 + self:GetPropertyValue(IW_PROPERTY_DODGE_PCT)/100.0))
end

function CInstance:GetHealEffectiveness()
	return math.max(0, 1.0 + self:GetPropertyValue(IW_PROPERTY_HEAL_MULTI)/100.0)
end

function CInstance:GetDamageEffectiveness()
	return math.max(0, 1.0 + self:GetPropertyValue(IW_PROPERTY_DAMAGE_MULTI)/100.0)
end

function CInstance:GetFatigueMultiplier()
	return 1.0 + math.max(0, (self:GetPropertyValue(IW_PROPERTY_FATIGUE_MULTI) - (self:GetAttributeValue(IW_ATTRIBUTE_STRENGTH) * 1.00))/100.0)
end

function CInstance:GetDrainMultiplier()
	return math.max(0, 1.0 + self:GetPropertyValue(IW_PROPERTY_DRAIN_MULTI)/100.0)
end

function CInstance:GetStatusEffectDurationMultiplier(nStatusEffect)
	if stIcewrackStatusEffectValues[nStatusEffect] then
	    return 1.0 + (self:GetPropertyValue(IW_PROPERTY_STATUS_STUN + nStatusEffect - 1)/100.0)
	end
	return nil
end

function CInstance:GetPhysicalDebuffDefense()
	return math.max(0, self:GetPropertyValue(IW_PROPERTY_DEFENSE_PHYS) + (self:GetAttributeValue(IW_ATTRIBUTE_ENDURANCE) * 1.00))
end

function CInstance:GetMagicalDebuffDefense()
	return math.max(0, self:GetPropertyValue(IW_PROPERTY_DEFENSE_MAGIC) + (self:GetAttributeValue(IW_ATTRIBUTE_WISDOM) * 1.00))
end

function CInstance:GetDamageEffectAvoidance(nDamageType)
	if stIcewrackDamageEffectValues[nDamageType] then
	    return self:GetPropertyValue(IW_PROPERTY_AVOID_BASH + nDamageType - 1)/100.0
	end
	return 0.0
end

function CInstance:GetDamageEffectChance(nDamageType)
	if stIcewrackDamageEffectValues[nDamageType] then
	    return self:GetPropertyValue(IW_PROPERTY_CHANCE_BASH + nDamageType - 1)/100.0
	end
	return 0.0
end

function CInstance:GetDamageModifier(nDamageType)
	if stIcewrackDamageTypeValues[nDamageType] then
		if nDamageType ~= IW_DAMAGE_TYPE_PURE then
			nDamageType = math.max(1, nDamageType - 2)
		end
		return 1.0 + self:GetPropertyValue(IW_PROPERTY_DMG_PURE_PCT + nDamageType)/100.0
	end
end

function CInstance:GetInstanceList()
	return CInstance._tInstanceList
end

function GetInstanceByID(nInstanceID)
	return CInstance._tInstanceList[nInstanceID]
end

function IsValidInstance(hInstance)
    return (hInstance ~= nil and type(hInstance) == "table" and not (hInstance.IsNull and hInstance:IsNull()) and hInstance._bIsInstance == true)
end

end