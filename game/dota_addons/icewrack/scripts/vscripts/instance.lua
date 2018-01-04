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
	IW_INSTANCE_WORLD_OBJECT = 6,
}

stIcewrackPropertyEnum =
{
	IW_PROPERTY_ATTR_STR_FLAT = 1,       IW_PROPERTY_ATTR_CON_FLAT = 2,       IW_PROPERTY_ATTR_AGI_FLAT = 3,       IW_PROPERTY_ATTR_PER_FLAT = 4,
	IW_PROPERTY_ATTR_INT_FLAT = 5,       IW_PROPERTY_ATTR_WIS_FLAT = 6,       IW_PROPERTY_ATTR_STR_PCT = 7,        IW_PROPERTY_ATTR_CON_PCT = 8,
	IW_PROPERTY_ATTR_AGI_PCT = 9,        IW_PROPERTY_ATTR_PER_PCT = 10,       IW_PROPERTY_ATTR_INT_PCT = 11,       IW_PROPERTY_ATTR_WIS_PCT = 12,
	IW_PROPERTY_MAX_SP_FLAT = 13,        IW_PROPERTY_MAX_SP_PCT = 14,         IW_PROPERTY_SP_RECHARGE_TIME = 15,   IW_PROPERTY_SP_RECHARGE_PCT = 16,
	IW_PROPERTY_SP_REGEN_FLAT = 17,      IW_PROPERTY_SP_REGEN_PCT = 18,       IW_PROPERTY_MAX_SP_REGEN = 19,       IW_PROPERTY_HP_LIFESTEAL = 20,
	IW_PROPERTY_HP_REGEN_FLAT = 21,      IW_PROPERTY_HP_REGEN_PCT = 22,       IW_PROPERTY_MAX_HP_REGEN = 23,       IW_PROPERTY_MP_REGEN_FLAT = 24,
	IW_PROPERTY_MP_REGEN_PCT = 25,       IW_PROPERTY_MAX_MP_REGEN = 26,       IW_PROPERTY_VISION_RANGE_FLAT = 27,  IW_PROPERTY_VISION_RANGE_PCT = 28,
	IW_PROPERTY_EFFECTIVE_HP = 29,       IW_PROPERTY_ATTACK_RANGE = 30,       IW_PROPERTY_BASE_ATTACK_FLAT = 31,   IW_PROPERTY_BASE_ATTACK_PCT = 32,
	IW_PROPERTY_ATTACK_HP_FLAT = 33,     IW_PROPERTY_ATTACK_MP_FLAT = 34,     IW_PROPERTY_ATTACK_SP_FLAT = 35,     IW_PROPERTY_HP_COST_PCT = 36,
	IW_PROPERTY_MP_COST_PCT = 37,        IW_PROPERTY_SP_COST_PCT = 38,        IW_PROPERTY_RUN_SP_FLAT = 39,        IW_PROPERTY_RUN_SP_PCT = 40,         
	IW_PROPERTY_MOVE_SPEED_FLAT = 41,    IW_PROPERTY_MOVE_SPEED_PCT = 42,     IW_PROPERTY_CAST_SPEED = 43,         IW_PROPERTY_SPELLPOWER = 44,
	IW_PROPERTY_CRIT_CHANCE_FLAT = 45,   IW_PROPERTY_CRIT_MULTI_FLAT = 46,    IW_PROPERTY_CRIT_CHANCE_PCT = 47,    IW_PROPERTY_CRIT_MULTI_PCT = 48,
	IW_PROPERTY_ARMOR_CRUSH_FLAT = 49,   IW_PROPERTY_ARMOR_SLASH_FLAT = 50,   IW_PROPERTY_ARMOR_PIERCE_FLAT = 51,  IW_PROPERTY_ARMOR_CRUSH_PCT = 52,
    IW_PROPERTY_ARMOR_SLASH_PCT = 53,    IW_PROPERTY_ARMOR_PIERCE_PCT = 54,   IW_PROPERTY_IGNORE_ARMOR_FLAT = 55,  IW_PROPERTY_IGNORE_ARMOR_PCT = 56,
	IW_PROPERTY_RESIST_PHYS = 57,        IW_PROPERTY_RESIST_FIRE = 58,        IW_PROPERTY_RESIST_COLD = 59,        IW_PROPERTY_RESIST_LIGHT = 60,
	IW_PROPERTY_RESIST_DEATH = 61,       IW_PROPERTY_RESMAX_PHYS = 62,        IW_PROPERTY_RESMAX_FIRE = 63,        IW_PROPERTY_RESMAX_COLD = 64,
	IW_PROPERTY_RESMAX_LIGHT = 65,       IW_PROPERTY_RESMAX_DEATH = 66,       IW_PROPERTY_ACCURACY_FLAT = 67,      IW_PROPERTY_ACCURACY_PCT = 68,
	IW_PROPERTY_DODGE_FLAT = 69,         IW_PROPERTY_DODGE_PCT = 70, 	      IW_PROPERTY_BUFF_SELF = 71,          IW_PROPERTY_DEBUFF_SELF = 72,
	IW_PROPERTY_BUFF_OTHER = 73,         IW_PROPERTY_DEBUFF_OTHER = 74,       IW_PROPERTY_HEAL_MULTI = 75,         IW_PROPERTY_DAMAGE_MULTI = 76,
	IW_PROPERTY_THREAT_MULTI = 77,       IW_PROPERTY_FATIGUE_MULTI = 78,      IW_PROPERTY_PRICE_MULTI = 79,        IW_PROPERTY_EXP_MULTI = 80,
	IW_PROPERTY_STATUS_STUN = 81,        IW_PROPERTY_STATUS_SLOW = 82,        IW_PROPERTY_STATUS_SILENCE = 83,     IW_PROPERTY_STATUS_ROOT = 84,
	IW_PROPERTY_STATUS_DISARM = 85,      IW_PROPERTY_STATUS_MAIM = 86,        IW_PROPERTY_STATUS_PACIFY = 87,      IW_PROPERTY_STATUS_DECAY = 88,
	IW_PROPERTY_STATUS_DISEASE = 89,     IW_PROPERTY_STATUS_SLEEP = 90,       IW_PROPERTY_STATUS_FEAR = 91,        IW_PROPERTY_STATUS_CHARM = 92,
	IW_PROPERTY_STATUS_ENRAGE = 93,      IW_PROPERTY_STATUS_EXHAUST = 94,     IW_PROPERTY_STATUS_FREEZE = 95,      IW_PROPERTY_STATUS_CHILL = 96,
	IW_PROPERTY_STATUS_WET = 97,         IW_PROPERTY_STATUS_WARM = 98,        IW_PROPERTY_STATUS_BURNING = 99,     IW_PROPERTY_STATUS_POISON = 100,
	IW_PROPERTY_STATUS_BLEED = 101,      IW_PROPERTY_STATUS_BLIND = 102,      IW_PROPERTY_STATUS_DEAF = 103,       IW_PROPERTY_STATUS_PETRIFY = 104,
	IW_PROPERTY_DEFENSE_PHYS = 105,      IW_PROPERTY_DEFENSE_MAGIC = 106,     IW_PROPERTY_AVOID_BASH = 107,        IW_PROPERTY_AVOID_MAIM = 108,
	IW_PROPERTY_AVOID_BLEED = 109,       IW_PROPERTY_AVOID_BURN = 110,        IW_PROPERTY_AVOID_CHILL = 111,       IW_PROPERTY_AVOID_SHOCK = 112,
	IW_PROPERTY_AVOID_DECAY = 113,       IW_PROPERTY_AVOID_CRIT = 114,        IW_PROPERTY_CHANCE_BASH = 115,       IW_PROPERTY_CHANCE_MAIM = 116,
	IW_PROPERTY_CHANCE_BLEED = 117,      IW_PROPERTY_CHANCE_BURN = 118,       IW_PROPERTY_CHANCE_CHILL = 119,      IW_PROPERTY_CHANCE_SHOCK = 120,
	IW_PROPERTY_CHANCE_DECAY = 121,      IW_PROPERTY_DMG_PURE_BASE = 122,     IW_PROPERTY_DMG_CRUSH_BASE = 123,    IW_PROPERTY_DMG_SLASH_BASE = 124,
	IW_PROPERTY_DMG_PIERCE_BASE = 125,   IW_PROPERTY_DMG_FIRE_BASE = 126,     IW_PROPERTY_DMG_COLD_BASE = 127,     IW_PROPERTY_DMG_LIGHT_BASE = 128,
	IW_PROPERTY_DMG_DEATH_BASE = 129,    IW_PROPERTY_DMG_PURE_VAR = 130,      IW_PROPERTY_DMG_CRUSH_VAR = 131,     IW_PROPERTY_DMG_SLASH_VAR = 132,
	IW_PROPERTY_DMG_PIERCE_VAR = 133,    IW_PROPERTY_DMG_FIRE_VAR = 134,      IW_PROPERTY_DMG_COLD_VAR = 135,      IW_PROPERTY_DMG_LIGHT_VAR = 136,
	IW_PROPERTY_DMG_DEATH_VAR = 137,     IW_PROPERTY_DMG_PURE_PCT = 138,      IW_PROPERTY_DMG_PHYS_PCT = 139,      IW_PROPERTY_DMG_FIRE_PCT = 140,
	IW_PROPERTY_DMG_COLD_PCT = 141,      IW_PROPERTY_DMG_LIGHT_PCT = 142,     IW_PROPERTY_DMG_DEATH_PCT = 143,     IW_PROPERTY_DMG_DOT_PCT = 144,
	IW_PROPERTY_LIFESTEAL_PCT = 145,     IW_PROPERTY_LIFESTEAL_RATE = 146,    IW_PROPERTY_MANASHIELD_PCT = 147,    IW_PROPERTY_SECONDWIND_PCT = 148,
	IW_PROPERTY_SKILL_FIRE = 149,        IW_PROPERTY_SKILL_EARTH = 150,       IW_PROPERTY_SKILL_WATER = 151,       IW_PROPERTY_SKILL_AIR = 152,
	IW_PROPERTY_SKILL_LIGHT = 153,       IW_PROPERTY_SKILL_SHADOW = 154,      IW_PROPERTY_SKILL_BODY = 155,        IW_PROPERTY_SKILL_MIND = 156,      
	IW_PROPERTY_SKILL_LIFE = 157,        IW_PROPERTY_SKILL_DEATH = 158,       IW_PROPERTY_SKILL_SHAPE = 159,       IW_PROPERTY_SKILL_METAMAGIC = 160,
	IW_PROPERTY_SKILL_TWOHAND = 161,     IW_PROPERTY_SKILL_ONEHAND = 162,     IW_PROPERTY_SKILL_MARKSMAN = 163,    IW_PROPERTY_SKILL_DUALWIELD = 164,
	IW_PROPERTY_SKILL_ARMOR = 165,       IW_PROPERTY_SKILL_COMBAT = 166,      IW_PROPERTY_SKILL_LEADERSHIP = 167,  IW_PROPERTY_SKILL_SURVIVAL = 168,
	IW_PROPERTY_SKILL_LORE = 169,        IW_PROPERTY_SKILL_SPEECH = 170,      IW_PROPERTY_SKILL_STEALTH = 171,     IW_PROPERTY_SKILL_THIEVERY = 172,
	IW_PROPERTY_ATTRIBUTE_POINTS = 173,  IW_PROPERTY_SKILL_POINTS = 174,      IW_PROPERTY_CARRY_CAPACITY = 175,    IW_PROPERTY_EQUIP_WEIGHT_PCT = 176,
	IW_PROPERTY_MOVE_NOISE_FLAT = 177,   IW_PROPERTY_MOVE_NOISE_PCT = 178,    IW_PROPERTY_CAST_NOISE_FLAT = 179,   IW_PROPERTY_CAST_NOISE_PCT = 180,
	IW_PROPERTY_DARK_SIGHT_PCT = 181,    IW_PROPERTY_VISIBILITY_FLAT = 182,   IW_PROPERTY_VISIBILITY_PCT = 183,    IW_PROPERTY_NOISE_THRESHOLD = 184,
	IW_PROPERTY_VISION_THRESHOLD = 185,  IW_PROPERTY_VISION_MASK = 186,       IW_PROPERTY_THREAT_RADIUS = 187,     IW_PROPERTY_SHARE_RADIUS = 188,
	IW_PROPERTY_THREAT_SHARE_PCT = 189,  IW_PROPERTY_CORPSE_TIME = 190,       IW_PROPERTY_ATK_SPEED_DUMMY = 191,
}

for k,v in pairs(stInstanceTypeEnum) do _G[k] = v end
for k,v in pairs(stIcewrackPropertyEnum) do _G[k] = v end

stIcewrackPropertiesName = 
{
	StrengthFlat = 1,                  ConstitutionFlat = 2,              AgilityFlat = 3,                   PerceptionFlat = 4,
	IntelligenceFlat = 5,              WisdomFlat = 6,                    StrengthPercent = 7,               ConstitutionPercent = 8,
	AgilityPercent = 9,                PerceptionPercent = 10,            IntelligencePercent = 11,          WisdomPercent = 12,
	MaxStaminaFlat = 13,               MaxStaminaPercent = 14,            StaminaRechargeTime = 15,          StaminaRechargePercent = 16,
	StaminaRegenFlat = 17,             StaminaRegenPercent = 18,          MaxStaminaPercentRegen = 19,       HealthRegenLifesteal = 20,
	HealthRegenFlat = 21,              HealthRegenPercent = 22,           MaxHealthPercentRegen = 23,        ManaRegenFlat = 24,
	ManaRegenPercent = 25,             MaxManaPercentRegen = 26,          VisionRangeFlat = 27,              VisionRangePercent = 28,
	EffectiveHealth = 29,              AttackRange = 30,                  BaseAttackTimeFlat = 31,           BaseAttackTimePercent = 32,
	AttackCostHealthFlat = 33,         AttackCostManaFlat = 34,           AttackCostStaminaFlat = 35,        HealthUseCostPercent = 36,
	ManaUseCostPercent = 37,           StaminaUseCostPercent = 38,        RunCostStaminaFlat = 39,           RunCostStaminaPercent = 40,
	MovementSpeedFlat = 41,            MovementSpeedPercent = 42,         CastSpeed = 43,                    Spellpower = 44,
	BaseCritChance = 45,               BaseCritMultiplier = 46,           CritChance = 47,                   CritMultiplier = 48,
	ArmorCrushFlat = 49,               ArmorSlashFlat = 50,               ArmorPierceFlat = 51,              ArmorCrushPercent = 52,
	ArmorSlashPercent = 53,            ArmorPiercePercent = 54,           IgnoreArmorFlat = 55,              IgnoreArmorPercent = 56,
	ResistPhysical = 57,               ResistFire = 58,                   ResistCold = 59,                   ResistLightning = 60,
	ResistDeath = 61,                  MaxResistPhysical = 62,            MaxResistFire = 63,                MaxResistCold = 64,
	MaxResistLightning = 65,           MaxResistDeath = 66,               AccuracyFlat = 67,                 AccuracyPercent = 68,
	DodgeFlat = 69,                    DodgePercent = 70,                 BuffDurationSelf = 71,             DebuffDurationSelf = 72,
	BuffDurationOther = 73,            DebuffDurationOther = 74,          HealMultiplier = 78,               DamageMultiplier = 76,
	ThreatMultiplier = 77,             FatigueMultiplier = 78,            PriceMultiplier = 79,              ExperienceMultiplier = 80,         
	EffectDurationStun = 81,           EffectDurationSlow = 82,           EffectDurationSilence = 83,        EffectDurationRoot = 84,
	EffectDurationDisarm = 85,         EffectDurationMaim = 86,           EffectDurationPacify = 87,         EffectDurationDecay = 88,
	EffectDurationDisease = 89,        EffectDurationSleep = 90,          EffectDurationFear = 91,           EffectDurationCharm = 92,
	EffectDurationEnrage = 93,         EffectDurationExhaustion = 94,     EffectDurationFreeze = 95,         EffectDurationChill = 96,
	EffectDurationWet = 97,            EffectDurationWarm = 98,           EffectDurationBurning = 99,        EffectDurationPoison = 100,
	EffectDurationBleed = 101,         EffectDurationBlind = 102,         EffectDurationDeaf = 103,          EffectDurationPetrify = 104,
	EffectDefensePhysical = 105,       EffectDefenseMagic = 106,          EffectAvoidBash = 107,             EffectAvoidMaim = 108,
	EffectAvoidBleed = 109,            EffectAvoidBurn = 110,             EffectAvoidChill = 111,            EffectAvoidShock = 112,
	EffectAvoidDecay = 113,            EffectAvoidCrit = 114,             EffectChanceBash = 115,            EffectChanceMaim = 116,
	EffectChanceBleed = 117,           EffectChanceBurn = 118,            EffectChanceChill = 119,           EffectChanceShock = 120,
	EffectChanceDecay = 121,           DamagePureBase = 122,              DamageCrushBase = 123,             DamageSlashBase = 124,
	DamagePierceBase = 125,            DamageFireBase = 126,              DamageColdBase = 127,              DamageLightningBase = 128,
	DamageDeathBase = 129,             DamagePureVar = 130,               DamageCrushVar = 131,              DamageSlashVar = 132,
	DamagePierceVar = 133,             DamageFireVar = 134,               DamageColdVar = 135,               DamageLightningVar = 136,
	DamageDeathVar = 137,              DamagePurePercent = 138,           DamagePhysicalPercent = 139,       DamageFirePercent = 140,
	DamageColdPercent = 141,           DamageLightningPercent = 142,      DamageDeathPercent = 143,          DamageOverTimePercent = 144,
	LifestealPercent = 145,            LifestealRate = 146,               ManaShieldPercent = 147,           SecondWindPercent = 148,
	SkillFire = 149,                   SkillEarth = 150,                  SkillWater = 151,                  SkillAir = 152,
	SkillLight = 153,                  SkillShadow = 154,                 SkillBody = 155,                   SkillMind = 156,
	SkillLife = 157,                   SkillDeath = 158,                  SkillShape = 159,                  SkillMetamagic = 160,
	SkillTwoHanded = 161,              SkillOneHanded = 162,              SkillMarksmanship = 163,           SkillDualWield = 164,
	SkillHeavyArmor = 165,             SkillCombat = 166,                 SkillLeadership = 167,             SkillSurvival = 168,
	SkillLore = 169,                   SkillSpeech = 170,                 SkillStealth = 171,                SkillThievery = 172,
	AttributePoints = 173,             SkillPoints = 174,                 CarryCapacity = 175,               EquippedWeightPercent = 176,
	MovementNoiseFlat = 177,           MovementNoisePercent = 178,        CastNoiseFlat = 179,               CastNoisePercent = 180,
	DarkSightPercent = 181,            VisibilityFlat = 182,              VisibilityPercent = 183,           NoiseDetectThreshold = 184,
	VisionDetectThreshold = 185,       VisionDetectMask = 186,            ThreatFalloffRadius = 187,         ThreatShareRadius = 188,
	ThreatSharePercent = 189,          CorpseTime = 190,                  AttackSpeedDummy = 191,
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

CInstance = ext_class({
	--_bAllowDynamicInstances = true,
	_nNextDynamicID = IW_INSTANCE_DYNAMIC_BASE,
	_tInstanceList = {},
})

CInstance = setmetatable(CInstance, { __call = 
	function(self, hInstance, nInstanceID)
		if nInstanceID then
			LogAssert(type(nInstanceID) == "number", LOG_MESSAGE_ASSERT_TYPE, "number")
		end
		if IsInstanceOf(hInstance, CInstance) then
			LogMessage(LOG_MESSAGE_WARN_EXISTS, LOG_SEVERITY_WARNING, "CInstance", hInstance:GetName())
			return hInstance
		--elseif not CInstance._bAllowDynamicInstances and not nInstanceID then
		--	LogMessage("Failed to create instance - dynamic instances are currently disabled", LOG_SEVERITY_ERROR)
		elseif nInstanceID and CInstance._tInstanceList[nInstanceID] then
			LogMessage("Failed to create instance \"" .. nInstanceID .. "\" - another instance with this ID already exists", LOG_SEVERITY_ERROR)
		end
		
		ExtendIndexTable(hInstance, CInstance)

		hInstance._tPropertyValues = setmetatable({}, stPropertyMetatable)
		hInstance._tChildrenInstances = {}
		
		hInstance._bInstanceState = true
		
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

--[[function CInstance:SetAllowDynamicInstances(bState)
	if type(bState) == "boolean" then
		CInstance._bAllowDynamicInstances = bState
	end
end	]]

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

function CInstance:GetChildren()
	return self._tChildrenInstances
end

function CInstance:GetInstanceState()
	return self._bInstanceState
end

function CInstance:SetInstanceState(bState)
	if type(bState) == "boolean" then
		self._bInstanceState = bState
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

function CInstance:GetBaseAttackTime()
	return self:GetBasePropertyValue(IW_PROPERTY_BASE_ATTACK_FLAT) * math.max(0.25, (1.0 + self:GetPropertyValue(IW_PROPERTY_BASE_ATTACK_PCT)/100))
end

function CInstance:GetMaxStamina()
    return (self:GetPropertyValue(IW_PROPERTY_MAX_SP_FLAT) + (self:GetAttributeValue(IW_ATTRIBUTE_CONSTITUTION) * 1.0))
end

function CInstance:GetStaminaRegen()
	return (self:GetPropertyValue(IW_PROPERTY_SP_REGEN_FLAT) + (self:GetPropertyValue(IW_PROPERTY_MAX_SP_REGEN)/100.0 * self:GetMaxStamina())) * (1.0 + self:GetPropertyValue(IW_PROPERTY_SP_REGEN_PCT)/100.0)
end

function CInstance:GetCastSpeed()
	return self:GetPropertyValue(IW_PROPERTY_CAST_SPEED)
end

function CInstance:GetSpellpower()
	return self:GetPropertyValue(IW_PROPERTY_SPELLPOWER) + (self:GetAttributeValue(IW_ATTRIBUTE_INTELLIGENCE) * 1.0)
end

function CInstance:GetCriticalStrikeChance()
	return self:GetBasePropertyValue(IW_PROPERTY_CRIT_CHANCE_FLAT) * (1.00 + (self:GetAttributeValue(IW_ATTRIBUTE_PERCEPTION) * 0.05) + self:GetPropertyValue(IW_PROPERTY_CRIT_CHANCE_PCT)/100.0)
end

function CInstance:GetCriticalStrikeMultiplierMin()
	return self:GetPropertyValue(IW_PROPERTY_CRIT_MULTI_FLAT)
end

function CInstance:GetCriticalStrikeMultiplierMax()
	return self:GetBasePropertyValue(IW_PROPERTY_CRIT_MULTI_FLAT) * (1.00 + (self:GetAttributeValue(IW_ATTRIBUTE_PERCEPTION) * 0.05) + self:GetPropertyValue(IW_PROPERTY_CRIT_MULTI_PCT)/100.0)
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
	return math.max(0, 1.0 + self:GetPropertyValue(IW_PROPERTY_BUFF_OTHER)/100.0 + (self:GetAttributeValue(IW_ATTRIBUTE_INTELLIGENCE) * 0.005))
end

function CInstance:GetSelfDebuffDuration()
	return math.max(0, 1.0 + self:GetPropertyValue(IW_PROPERTY_DEBUFF_SELF)/100.0)
end

function CInstance:GetOtherDebuffDuration()
	return math.max(0, 1.0 + self:GetPropertyValue(IW_PROPERTY_DEBUFF_OTHER)/100.0 + (self:GetAttributeValue(IW_ATTRIBUTE_INTELLIGENCE) * 0.005))
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

function CInstance:GetDamageTakenMultiplier()
	return math.max(0, 1.0 + self:GetPropertyValue(IW_PROPERTY_DAMAGE_MULTI)/100.0)
end

function CInstance:GetFatigueMultiplier()
	return 1.0 + math.max(0, self:GetPropertyValue(IW_PROPERTY_FATIGUE_MULTI)/100.0)
end

function CInstance:GetStatusEffectDurationMultiplier(nStatusEffect)
	if stIcewrackStatusEffectValues[nStatusEffect] then
	    return 1.0 + (self:GetPropertyValue(IW_PROPERTY_STATUS_STUN + nStatusEffect - 1)/100.0)
	end
	return nil
end

function CInstance:GetPhysicalDebuffDefense()
	return math.max(0, self:GetPropertyValue(IW_PROPERTY_DEFENSE_PHYS) + (self:GetAttributeValue(IW_ATTRIBUTE_CONSTITUTION) * 1.00))
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
    return (hInstance ~= nil and type(hInstance) == "table" and not (hInstance.IsNull and hInstance:IsNull()) and IsInstanceOf(hInstance, CInstance))
end

end