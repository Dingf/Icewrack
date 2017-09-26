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
	IW_PROPERTY_ATTR_STR_FLAT = 1,       IW_PROPERTY_ATTR_END_FLAT = 2,       IW_PROPERTY_ATTR_AGI_FLAT = 3,       IW_PROPERTY_ATTR_CUN_FLAT = 4,
	IW_PROPERTY_ATTR_INT_FLAT = 5,       IW_PROPERTY_ATTR_WIS_FLAT = 6,       IW_PROPERTY_ATTR_STR_PCT = 7,        IW_PROPERTY_ATTR_END_PCT = 8,
	IW_PROPERTY_ATTR_AGI_PCT = 9,        IW_PROPERTY_ATTR_CUN_PCT = 10,       IW_PROPERTY_ATTR_INT_PCT = 11,       IW_PROPERTY_ATTR_WIS_PCT = 12,
	IW_PROPERTY_MAX_SP_FLAT = 13,        IW_PROPERTY_SP_REGEN_FLAT = 14,      IW_PROPERTY_SP_REGEN_PCT = 15,       IW_PROPERTY_MAX_SP_REGEN = 16,
	IW_PROPERTY_HP_REGEN_FLAT = 17,      IW_PROPERTY_HP_REGEN_PCT = 18,       IW_PROPERTY_MAX_HP_REGEN = 19,       IW_PROPERTY_MP_REGEN_FLAT = 20,
	IW_PROPERTY_MP_REGEN_PCT = 21,       IW_PROPERTY_MAX_MP_REGEN = 22,       IW_PROPERTY_VISION_RANGE_FLAT = 23,  IW_PROPERTY_VISION_RANGE_PCT = 24,
	IW_PROPERTY_EFFECTIVE_HP = 25,       IW_PROPERTY_ATTACK_RANGE = 26,       IW_PROPERTY_BASE_ATTACK_FLAT = 27,   IW_PROPERTY_BASE_ATTACK_PCT = 28,
	IW_PROPERTY_ATTACK_HP_FLAT = 29,     IW_PROPERTY_ATTACK_HP_PCT = 30,      IW_PROPERTY_ATTACK_MP_FLAT = 31,     IW_PROPERTY_ATTACK_MP_PCT = 32,
	IW_PROPERTY_ATTACK_SP_FLAT = 33,     IW_PROPERTY_ATTACK_SP_PCT = 34,      IW_PROPERTY_RUN_SP_FLAT = 35,        IW_PROPERTY_RUN_SP_PCT = 36,         
	IW_PROPERTY_MOVE_SPEED_FLAT = 37,    IW_PROPERTY_MOVE_SPEED_PCT = 38,     IW_PROPERTY_CAST_SPEED = 39,         IW_PROPERTY_SPELLPOWER = 40,
	IW_PROPERTY_CRIT_CHANCE_FLAT = 41,   IW_PROPERTY_CRIT_MULTI_FLAT = 42,    IW_PROPERTY_CRIT_CHANCE_PCT = 43,    IW_PROPERTY_CRIT_MULTI_PCT = 44,
	IW_PROPERTY_ARMOR_CRUSH_FLAT = 45,   IW_PROPERTY_ARMOR_SLASH_FLAT = 46,   IW_PROPERTY_ARMOR_PIERCE_FLAT = 47,  IW_PROPERTY_ARMOR_CRUSH_PCT = 48,
    IW_PROPERTY_ARMOR_SLASH_PCT = 49,    IW_PROPERTY_ARMOR_PIERCE_PCT = 50,   IW_PROPERTY_IGNORE_ARMOR_FLAT = 51,  IW_PROPERTY_IGNORE_ARMOR_PCT = 52,
	IW_PROPERTY_RESIST_PHYS = 53,        IW_PROPERTY_RESIST_FIRE = 54,        IW_PROPERTY_RESIST_COLD = 55,        IW_PROPERTY_RESIST_LIGHT = 56,
	IW_PROPERTY_RESIST_DEATH = 57,       IW_PROPERTY_RESMAX_PHYS = 58,        IW_PROPERTY_RESMAX_FIRE = 59,        IW_PROPERTY_RESMAX_COLD = 60,
	IW_PROPERTY_RESMAX_LIGHT = 61,       IW_PROPERTY_RESMAX_DEATH = 62,       IW_PROPERTY_ACCURACY_FLAT = 63,      IW_PROPERTY_ACCURACY_PCT = 64,
	IW_PROPERTY_DODGE_FLAT = 65,         IW_PROPERTY_DODGE_PCT = 66, 	      IW_PROPERTY_BUFF_SELF = 67,          IW_PROPERTY_DEBUFF_SELF = 68,
	IW_PROPERTY_BUFF_OTHER = 69,         IW_PROPERTY_DEBUFF_OTHER = 70,       IW_PROPERTY_EXPERIENCE_MULTI = 71,   IW_PROPERTY_THREAT_MULTI = 72,
	IW_PROPERTY_HEAL_MULTI = 73,         IW_PROPERTY_DAMAGE_MULTI = 74,       IW_PROPERTY_FATIGUE_MULTI = 75,      IW_PROPERTY_DRAIN_MULTI = 76,
	IW_PROPERTY_STATUS_STUN = 77,        IW_PROPERTY_STATUS_SLOW = 78,        IW_PROPERTY_STATUS_SILENCE = 79,     IW_PROPERTY_STATUS_ROOT = 80,
	IW_PROPERTY_STATUS_DISARM = 81,      IW_PROPERTY_STATUS_MAIM = 82,        IW_PROPERTY_STATUS_PACIFY = 83,      IW_PROPERTY_STATUS_DECAY = 84,
	IW_PROPERTY_STATUS_DISEASE = 85,     IW_PROPERTY_STATUS_SLEEP = 86,       IW_PROPERTY_STATUS_FEAR = 87,        IW_PROPERTY_STATUS_CHARM = 88,
	IW_PROPERTY_STATUS_ENRAGE = 89,      IW_PROPERTY_STATUS_EXHAUST = 90,     IW_PROPERTY_STATUS_FREEZE = 91,      IW_PROPERTY_STATUS_CHILL = 92,
	IW_PROPERTY_STATUS_WET = 93,         IW_PROPERTY_STATUS_WARM = 94,        IW_PROPERTY_STATUS_BURNING = 95,     IW_PROPERTY_STATUS_POISON = 96,
	IW_PROPERTY_STATUS_BLEED = 97,       IW_PROPERTY_STATUS_BLIND = 98,       IW_PROPERTY_STATUS_DEAF = 99,        IW_PROPERTY_STATUS_PETRIFY = 100,
	IW_PROPERTY_DEFENSE_PHYS = 101,      IW_PROPERTY_DEFENSE_MAGIC = 102,     IW_PROPERTY_AVOID_BASH = 103,        IW_PROPERTY_AVOID_MAIM = 104,
	IW_PROPERTY_AVOID_BLEED = 105,       IW_PROPERTY_AVOID_BURN = 106,        IW_PROPERTY_AVOID_CHILL = 107,       IW_PROPERTY_AVOID_SHOCK = 108,
	IW_PROPERTY_AVOID_DECAY = 109,       IW_PROPERTY_AVOID_CRIT = 110,        IW_PROPERTY_CHANCE_BASH = 111,       IW_PROPERTY_CHANCE_MAIM = 112,
	IW_PROPERTY_CHANCE_BLEED = 113,      IW_PROPERTY_CHANCE_BURN = 114,       IW_PROPERTY_CHANCE_CHILL = 115,      IW_PROPERTY_CHANCE_SHOCK = 116,
	IW_PROPERTY_CHANCE_DECAY = 117,      IW_PROPERTY_DMG_PURE_BASE = 118,     IW_PROPERTY_DMG_CRUSH_BASE = 119,    IW_PROPERTY_DMG_SLASH_BASE = 120,
	IW_PROPERTY_DMG_PIERCE_BASE = 121,   IW_PROPERTY_DMG_FIRE_BASE = 122,     IW_PROPERTY_DMG_COLD_BASE = 123,     IW_PROPERTY_DMG_LIGHT_BASE = 124,
	IW_PROPERTY_DMG_DEATH_BASE = 125,    IW_PROPERTY_DMG_PURE_VAR = 126,      IW_PROPERTY_DMG_CRUSH_VAR = 127,     IW_PROPERTY_DMG_SLASH_VAR = 128,
	IW_PROPERTY_DMG_PIERCE_VAR = 129,    IW_PROPERTY_DMG_FIRE_VAR = 130,      IW_PROPERTY_DMG_COLD_VAR = 131,      IW_PROPERTY_DMG_LIGHT_VAR = 132,
	IW_PROPERTY_DMG_DEATH_VAR = 133,     IW_PROPERTY_DMG_PURE_PCT = 134,      IW_PROPERTY_DMG_PHYS_PCT = 135,      IW_PROPERTY_DMG_FIRE_PCT = 136,
	IW_PROPERTY_DMG_COLD_PCT = 137,      IW_PROPERTY_DMG_LIGHT_PCT = 138,     IW_PROPERTY_DMG_DEATH_PCT = 139,     IW_PROPERTY_DMG_DOT_PCT = 140,
	IW_PROPERTY_LIFESTEAL_PCT = 141,     IW_PROPERTY_LIFESTEAL_RATE = 142,    IW_PROPERTY_MANASHIELD_PCT = 143,    IW_PROPERTY_SECONDWIND_PCT = 144,
	IW_PROPERTY_SKILL_FIRE = 145,        IW_PROPERTY_SKILL_EARTH = 146,       IW_PROPERTY_SKILL_WATER = 147,       IW_PROPERTY_SKILL_AIR = 148,
	IW_PROPERTY_SKILL_LIGHT = 149,       IW_PROPERTY_SKILL_SHADOW = 150,      IW_PROPERTY_SKILL_BODY = 151,        IW_PROPERTY_SKILL_MIND = 152,      
	IW_PROPERTY_SKILL_NATURE = 153,      IW_PROPERTY_SKILL_DEATH = 154,       IW_PROPERTY_SKILL_DIVINE = 155,      IW_PROPERTY_SKILL_SHAPE = 156,
	IW_PROPERTY_SKILL_META = 157,        IW_PROPERTY_SKILL_TWOHAND = 158,     IW_PROPERTY_SKILL_ONEHAND = 159,     IW_PROPERTY_SKILL_MARKSMAN = 160,
	IW_PROPERTY_SKILL_UNARMED = 161,     IW_PROPERTY_SKILL_ARMOR = 162,       IW_PROPERTY_SKILL_COMBAT = 163,      IW_PROPERTY_SKILL_ATHLETICS = 164,
	IW_PROPERTY_SKILL_SURVIVAL = 165,    IW_PROPERTY_SKILL_PERCEPTION = 166,  IW_PROPERTY_SKILL_LORE = 167,        IW_PROPERTY_SKILL_SPEECH = 168,
	IW_PROPERTY_SKILL_STEALTH = 169,     IW_PROPERTY_SKILL_THIEVERY = 170,    IW_PROPERTY_ATTRIBUTE_POINTS = 171,  IW_PROPERTY_SKILL_POINTS = 172,
	IW_PROPERTY_MOVE_NOISE_FLAT = 173,   IW_PROPERTY_MOVE_NOISE_PCT = 174,    IW_PROPERTY_CAST_NOISE_FLAT = 175,   IW_PROPERTY_CAST_NOISE_PCT = 176,
	IW_PROPERTY_DARK_SIGHT_PCT = 177,    IW_PROPERTY_VISIBILITY_FLAT = 178,   IW_PROPERTY_VISIBILITY_PCT = 179,    IW_PROPERTY_BEHAVIOR_AGGRO = 180,
	IW_PROPERTY_BEHAVIOR_COOP = 181,     IW_PROPERTY_BEHAVIOR_SAFETY = 182,   IW_PROPERTY_CORPSE_TIME = 183,       IW_PROPERTY_ATK_SPEED_DUMMY = 184,
	IW_PROPERTY_SP_REGEN_TIME_PCT = 185,
}

for k,v in pairs(stInstanceTypeEnum) do _G[k] = v end
for k,v in pairs(stIcewrackPropertyEnum) do _G[k] = v end

stIcewrackPropertiesName = 
{
	StrengthFlat = 1,                  EnduranceFlat = 2,                 AgilityFlat = 3,                   CunningFlat = 4,
	IntelligenceFlat = 5,              WisdomFlat = 6,                    StrengthPercent = 7,               EndurancePercent = 8,
	AgilityPercent = 9,                CunningPercent = 10,               IntelligencePercent = 11,          WisdomPercent = 12,
	MaxStaminaFlat = 13,               StaminaRegenFlat = 14,             StaminaRegenPercent = 15,          MaxStaminaPercentRegen = 16,
	HealthRegenFlat = 17,              HealthRegenPercent = 18,           MaxHealthPercentRegen = 19,        ManaRegenFlat = 20,
	ManaRegenPercent = 21,             MaxManaPercentRegen = 22,          VisionRangeFlat = 23,              VisionRangePercent = 24,
	EffectiveHealth = 25,              AttackRange = 26,                  BaseAttackTimeFlat = 27,           BaseAttackTimePercent = 28,
	AttackCostHealthFlat = 29,         AttackCostHealthPercent = 30,      AttackCostManaPercent = 31,        AttackCostManaPercent = 32,
	AttackCostStaminaFlat = 33,        AttackCostStaminaPercent = 34,     RunCostStaminaFlat = 35,           RunCostStaminaPercent = 36,
	MovementSpeedFlat = 37,            MovementSpeedPercent = 38,         CastSpeed = 39,                    Spellpower = 40,
	BaseCritChance = 41,               BaseCritMultiplier = 42,           CritChance = 43,                   CritMultiplier = 44,
	ArmorCrushFlat = 45,               ArmorSlashFlat = 46,               ArmorPierceFlat = 47,              ArmorCrushPercent = 48,
	ArmorSlashPercent = 49,            ArmorPiercePercent = 50,           IgnoreArmorFlat = 51,              IgnoreArmorPercent = 52,
	ResistPhysical = 53,               ResistFire = 54,                   ResistCold = 55,                   ResistLightning = 56,
	ResistDeath = 57,                  MaxResistPhysical = 58,            MaxResistFire = 59,                MaxResistCold = 60,
	MaxResistLightning = 61,           MaxResistDeath = 62,               AccuracyFlat = 63,                 AccuracyPercent = 64,
	DodgeFlat = 65,                    DodgePercent = 66,                 BuffDurationSelf = 67,             DebuffDurationSelf = 68,
	BuffDurationOther = 69,            DebuffDurationOther = 70,          ExperienceMultiplier = 71,         ThreatMultiplier = 72,         
	HealMultiplier = 73,               DamageMultiplier = 74,             FatigueMultiplier = 75,            DrainMultiplier = 76,
	EffectDurationStun = 77,           EffectDurationSlow = 78,           EffectDurationSilence = 79,        EffectDurationRoot = 80,
	EffectDurationDisarm = 81,         EffectDurationMaim = 82,           EffectDurationPacify = 83,         EffectDurationDecay = 84,
	EffectDurationDisease = 85,        EffectDurationSleep = 86,          EffectDurationFear = 87,           EffectDurationCharm = 88,
	EffectDurationEnrage = 89,         EffectDurationExhaustion = 90,     EffectDurationFreeze = 91,         EffectDurationChill = 92,
	EffectDurationWet = 93,            EffectDurationWarm = 94,           EffectDurationBurning = 95,        EffectDurationPoison = 96,
	EffectDurationBleed = 97,          EffectDurationBlind = 98,          EffectDurationDeaf = 99,           EffectDurationPetrify = 100,
	EffectDefensePhysical = 101,       EffectDefenseMagic = 102,          EffectAvoidBash = 103,             EffectAvoidMaim = 104,
	EffectAvoidBleed = 105,            EffectAvoidBurn = 106,             EffectAvoidChill = 107,            EffectAvoidShock = 108,
	EffectAvoidDecay = 109,            EffectAvoidCrit = 110,             EffectChanceBash = 111,            EffectChanceMaim = 112,
	EffectChanceBleed = 113,           EffectChanceBurn = 114,            EffectChanceChill = 115,           EffectChanceShock = 116,
	EffectChanceDecay = 117,           DamagePureBase = 118,              DamageCrushBase = 119,             DamageSlashBase = 120,
	DamagePierceBase = 121,            DamageFireBase = 122,              DamageColdBase = 123,              DamageLightningBase = 124,
	DamageDeathBase = 125,             DamagePureVar = 126,               DamageCrushVar = 127,              DamageSlashVar = 128,
	DamagePierceVar = 129,             DamageFireVar = 130,               DamageColdVar = 131,               DamageLightningVar = 132,
	DamageDeathVar = 133,              DamagePurePercent = 134,           DamagePhysicalPercent = 135,       DamageFirePercent = 136,
	DamageColdPercent = 137,           DamageLightningPercent = 138,      DamageDeathPercent = 139,          DamageOverTimePercent = 140,
	LifestealPercent = 141,            LifestealRate = 142,               ManaShieldPercent = 143,           SecondWindPercent = 144,
	SkillFire = 145,                   SkillEarth = 146,                  SkillWater = 147,                  SkillAir = 148,
	SkillLight = 149,                  SkillShadow = 150,                 SkillBody = 151,                   SkillMind = 152,
	SkillNature = 153,                 SkillDeath = 154,                  SkillDivine = 155,                 SkillShape = 156,
	SkillMetamagic = 157,              SkillTwoHanded = 158,              SkillOneHanded = 159,              SkillMarksmanship = 160,
	SkillUnarmed = 161,                SkillArmor = 162,                  SkillCombat = 163,                 SkillAthletics = 164,
	SkillSurvival = 165,               SkillPerception = 166,             SkillLore = 167,                   SkillSpeech = 168,
	SkillStealth = 169,                SkillThievery = 170,               AttributePoints = 171,             SkillPoints = 172,
	MovementNoiseFlat = 173,           MovementNoisePercent = 174,        CastNoiseFlat = 175,               CastNoisePercent = 176,
	DarkSightPercent = 177,            VisibilityFlat = 178,              VisibilityPercent = 179,           BehaviorAggressiveness = 180,
	BehaviorCooperativeness = 181,     BehaviorSafety = 182,              CorpseTime = 183,                  AttackSpeedDummy = 184,
	StaminaRegenTimePercent = 185,  
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
			LogAssert(type(nInstanceID) == "number", LOG_MESSAGE_ASSERT_TYPE, "number", type(nInstanceID))
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

function CInstance:GetChildren()
	return self._tChildrenInstances
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
    return (self:GetPropertyValue(IW_PROPERTY_MAX_SP_FLAT) + (self:GetAttributeValue(IW_ATTRIBUTE_ENDURANCE) * 1.0))
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
	return self:GetPropertyValue(IW_PROPERTY_SPELLPOWER) + (self:GetAttributeValue(IW_ATTRIBUTE_INTELLIGENCE) * 1.0)
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

function CInstance:GetDamageEffectiveness()
	return math.max(0, 1.0 + self:GetPropertyValue(IW_PROPERTY_DAMAGE_MULTI)/100.0)
end

function CInstance:GetFatigueMultiplier()
	return 1.0 + math.max(0, self:GetPropertyValue(IW_PROPERTY_FATIGUE_MULTI)/100.0)
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

function CInstance:GetAttackHealthCost()
	return math.max(0, self:GetBasePropertyValue(IW_PROPERTY_ATTACK_HP_FLAT) * (self:GetFatigueMultiplier() + self:GetPropertyValue(IW_PROPERTY_ATTACK_HP_PCT)/100.0))
end

function CInstance:GetAttackManaCost()
	return math.max(0, self:GetBasePropertyValue(IW_PROPERTY_ATTACK_MP_FLAT) * (self:GetFatigueMultiplier() + self:GetPropertyValue(IW_PROPERTY_ATTACK_MP_PCT)/100.0))
end

function CInstance:GetAttackStaminaCost()
	return math.max(0, self:GetBasePropertyValue(IW_PROPERTY_ATTACK_SP_FLAT) * (self:GetFatigueMultiplier() + self:GetPropertyValue(IW_PROPERTY_ATTACK_SP_PCT)/100.0))
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