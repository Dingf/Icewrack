"use strict";

var Instance =
{
	IW_PROPERTY_ATTR_STR_FLAT : 1,       IW_PROPERTY_ATTR_END_FLAT : 2,       IW_PROPERTY_ATTR_AGI_FLAT : 3,       IW_PROPERTY_ATTR_CUN_FLAT : 4,
	IW_PROPERTY_ATTR_INT_FLAT : 5,       IW_PROPERTY_ATTR_WIS_FLAT : 6,       IW_PROPERTY_ATTR_STR_PCT : 7,        IW_PROPERTY_ATTR_END_PCT : 8,
	IW_PROPERTY_ATTR_AGI_PCT : 9,        IW_PROPERTY_ATTR_CUN_PCT : 10,       IW_PROPERTY_ATTR_INT_PCT : 11,       IW_PROPERTY_ATTR_WIS_PCT : 12,
	IW_PROPERTY_MAX_SP_FLAT : 13,        IW_PROPERTY_SP_REGEN_FLAT : 14,      IW_PROPERTY_SP_REGEN_PCT : 15,       IW_PROPERTY_MAX_SP_REGEN : 16,
	IW_PROPERTY_HP_REGEN_FLAT : 17,      IW_PROPERTY_HP_REGEN_PCT : 18,       IW_PROPERTY_MAX_HP_REGEN : 19,       IW_PROPERTY_MP_REGEN_FLAT : 20,
	IW_PROPERTY_MP_REGEN_PCT : 21,       IW_PROPERTY_MAX_MP_REGEN : 22,       IW_PROPERTY_VISION_RANGE_FLAT : 23,  IW_PROPERTY_VISION_RANGE_PCT : 24,
	IW_PROPERTY_EFFECTIVE_HP : 25,       IW_PROPERTY_ATTACK_RANGE : 26,       IW_PROPERTY_BASE_ATTACK_FLAT : 27,   IW_PROPERTY_BASE_ATTACK_PCT : 28,
	IW_PROPERTY_ATTACK_HP_FLAT : 29,     IW_PROPERTY_ATTACK_HP_PCT : 30,      IW_PROPERTY_ATTACK_MP_FLAT : 31,     IW_PROPERTY_ATTACK_MP_PCT : 32,
	IW_PROPERTY_ATTACK_SP_FLAT : 33,     IW_PROPERTY_ATTACK_SP_PCT : 34,      IW_PROPERTY_RUN_SP_FLAT : 35,        IW_PROPERTY_RUN_SP_PCT : 36,         
	IW_PROPERTY_MOVE_SPEED_FLAT : 37,    IW_PROPERTY_MOVE_SPEED_PCT : 38,     IW_PROPERTY_CAST_SPEED : 39,         IW_PROPERTY_SPELLPOWER : 40,
	IW_PROPERTY_CRIT_CHANCE_FLAT : 41,   IW_PROPERTY_CRIT_MULTI_FLAT : 42,    IW_PROPERTY_CRIT_CHANCE_PCT : 43,    IW_PROPERTY_CRIT_MULTI_PCT : 44,
	IW_PROPERTY_ARMOR_CRUSH_FLAT : 45,   IW_PROPERTY_ARMOR_SLASH_FLAT : 46,   IW_PROPERTY_ARMOR_PIERCE_FLAT : 47,  IW_PROPERTY_ARMOR_CRUSH_PCT : 48,
    IW_PROPERTY_ARMOR_SLASH_PCT : 49,    IW_PROPERTY_ARMOR_PIERCE_PCT : 50,   IW_PROPERTY_IGNORE_ARMOR_FLAT : 51,  IW_PROPERTY_IGNORE_ARMOR_PCT : 52,
	IW_PROPERTY_RESIST_PHYS : 55,        IW_PROPERTY_RESIST_FIRE : 56,        IW_PROPERTY_RESIST_COLD : 57,        IW_PROPERTY_RESIST_LIGHT : 58,
	IW_PROPERTY_RESIST_DEATH : 59,       IW_PROPERTY_RESMAX_PHYS : 60,        IW_PROPERTY_RESMAX_FIRE : 61,        IW_PROPERTY_RESMAX_COLD : 62,
	IW_PROPERTY_RESMAX_LIGHT : 63,       IW_PROPERTY_RESMAX_DEATH : 64,       IW_PROPERTY_ACCURACY_FLAT : 65,      IW_PROPERTY_ACCURACY_PCT : 66,
	IW_PROPERTY_DODGE_FLAT : 67,         IW_PROPERTY_DODGE_PCT : 68, 	      IW_PROPERTY_BUFF_SELF : 69,          IW_PROPERTY_DEBUFF_SELF : 70,
	IW_PROPERTY_BUFF_OTHER : 71,         IW_PROPERTY_DEBUFF_OTHER : 72,       IW_PROPERTY_EXPERIENCE_MULTI : 53,   IW_PROPERTY_THREAT_MULTI : 54,
	IW_PROPERTY_HEAL_MULTI : 73,         IW_PROPERTY_DAMAGE_MULTI : 74,       IW_PROPERTY_FATIGUE_MULTI : 75,      IW_PROPERTY_DRAIN_MULTI : 76,
	IW_PROPERTY_STATUS_STUN : 77,        IW_PROPERTY_STATUS_SLOW : 78,        IW_PROPERTY_STATUS_SILENCE : 79,     IW_PROPERTY_STATUS_ROOT : 80,
	IW_PROPERTY_STATUS_DISARM : 81,      IW_PROPERTY_STATUS_MAIM : 82,        IW_PROPERTY_STATUS_PACIFY : 83,      IW_PROPERTY_STATUS_DECAY : 84,
	IW_PROPERTY_STATUS_DISEASE : 85,     IW_PROPERTY_STATUS_SLEEP : 86,       IW_PROPERTY_STATUS_FEAR : 87,        IW_PROPERTY_STATUS_CHARM : 88,
	IW_PROPERTY_STATUS_ENRAGE : 89,      IW_PROPERTY_STATUS_EXHAUST : 90,     IW_PROPERTY_STATUS_FREEZE : 91,      IW_PROPERTY_STATUS_CHILL : 92,
	IW_PROPERTY_STATUS_WET : 93,         IW_PROPERTY_STATUS_WARM : 94,        IW_PROPERTY_STATUS_BURNING : 95,     IW_PROPERTY_STATUS_POISON : 96,
	IW_PROPERTY_STATUS_BLEED : 97,       IW_PROPERTY_STATUS_BLIND : 98,       IW_PROPERTY_STATUS_DEAF : 99,        IW_PROPERTY_STATUS_PETRIFY : 100,
	IW_PROPERTY_DEFENSE_PHYS : 101,      IW_PROPERTY_DEFENSE_MAGIC : 102,     IW_PROPERTY_AVOID_BASH : 103,        IW_PROPERTY_AVOID_MAIM : 104,
	IW_PROPERTY_AVOID_BLEED : 105,       IW_PROPERTY_AVOID_BURN : 106,        IW_PROPERTY_AVOID_CHILL : 107,       IW_PROPERTY_AVOID_SHOCK : 108,
	IW_PROPERTY_AVOID_DECAY : 109,       IW_PROPERTY_AVOID_CRIT : 110,        IW_PROPERTY_CHANCE_BASH : 111,       IW_PROPERTY_CHANCE_MAIM : 112,
	IW_PROPERTY_CHANCE_BLEED : 113,      IW_PROPERTY_CHANCE_BURN : 114,       IW_PROPERTY_CHANCE_CHILL : 115,      IW_PROPERTY_CHANCE_SHOCK : 116,
	IW_PROPERTY_CHANCE_DECAY : 117,      IW_PROPERTY_DMG_PURE_BASE : 118,     IW_PROPERTY_DMG_CRUSH_BASE : 119,    IW_PROPERTY_DMG_SLASH_BASE : 120,
	IW_PROPERTY_DMG_PIERCE_BASE : 121,   IW_PROPERTY_DMG_FIRE_BASE : 122,     IW_PROPERTY_DMG_COLD_BASE : 123,     IW_PROPERTY_DMG_LIGHT_BASE : 124,
	IW_PROPERTY_DMG_DEATH_BASE : 125,    IW_PROPERTY_DMG_PURE_VAR : 126,      IW_PROPERTY_DMG_CRUSH_VAR : 127,     IW_PROPERTY_DMG_SLASH_VAR : 128,
	IW_PROPERTY_DMG_PIERCE_VAR : 129,    IW_PROPERTY_DMG_FIRE_VAR : 130,      IW_PROPERTY_DMG_COLD_VAR : 131,      IW_PROPERTY_DMG_LIGHT_VAR : 132,
	IW_PROPERTY_DMG_DEATH_VAR : 133,     IW_PROPERTY_DMG_PURE_PCT : 134,      IW_PROPERTY_DMG_PHYS_PCT : 135,      IW_PROPERTY_DMG_FIRE_PCT : 136,
	IW_PROPERTY_DMG_COLD_PCT : 137,      IW_PROPERTY_DMG_LIGHT_PCT : 138,     IW_PROPERTY_DMG_DEATH_PCT : 139,     IW_PROPERTY_DMG_DOT_PCT : 140,
	IW_PROPERTY_LIFESTEAL_PCT : 141,     IW_PROPERTY_LIFESTEAL_RATE : 142,    IW_PROPERTY_MANASHIELD_PCT : 143,    IW_PROPERTY_SECONDWIND_PCT : 144,
	IW_PROPERTY_SKILL_FIRE : 145,        IW_PROPERTY_SKILL_EARTH : 146,       IW_PROPERTY_SKILL_WATER : 147,       IW_PROPERTY_SKILL_AIR : 148,
	IW_PROPERTY_SKILL_LIGHT : 149,       IW_PROPERTY_SKILL_SHADOW : 150,      IW_PROPERTY_SKILL_BODY : 151,        IW_PROPERTY_SKILL_MIND : 152,      
	IW_PROPERTY_SKILL_NATURE : 153,      IW_PROPERTY_SKILL_DEATH : 154,       IW_PROPERTY_SKILL_DIVINE : 155,      IW_PROPERTY_SKILL_SHAPE : 156,
	IW_PROPERTY_SKILL_META : 157,        IW_PROPERTY_SKILL_TWOHAND : 158,     IW_PROPERTY_SKILL_ONEHAND : 159,     IW_PROPERTY_SKILL_MARKSMAN : 160,
	IW_PROPERTY_SKILL_UNARMED : 161,     IW_PROPERTY_SKILL_ARMOR : 162,       IW_PROPERTY_SKILL_COMBAT : 163,      IW_PROPERTY_SKILL_ATHLETICS : 164,
	IW_PROPERTY_SKILL_SURVIVAL : 165,    IW_PROPERTY_SKILL_PERCEPTION : 166,  IW_PROPERTY_SKILL_LORE : 167,        IW_PROPERTY_SKILL_SPEECH : 168,
	IW_PROPERTY_SKILL_STEALTH : 169,     IW_PROPERTY_SKILL_THIEVERY : 170,    IW_PROPERTY_ATTRIBUTE_POINTS : 171,  IW_PROPERTY_SKILL_POINTS : 172,
	IW_PROPERTY_MOVE_NOISE_FLAT : 173,   IW_PROPERTY_MOVE_NOISE_PCT : 174,    IW_PROPERTY_CAST_NOISE_FLAT : 175,   IW_PROPERTY_CAST_NOISE_PCT : 176,
	IW_PROPERTY_DARK_SIGHT_PCT : 177,    IW_PROPERTY_VISIBILITY_FLAT : 178,   IW_PROPERTY_VISIBILITY_PCT : 179,    IW_PROPERTY_BEHAVIOR_AGGRO : 180,
	IW_PROPERTY_BEHAVIOR_COOP : 181,     IW_PROPERTY_BEHAVIOR_SAFETY : 182,   IW_PROPERTY_CORPSE_TIME : 183,       IW_PROPERTY_ATK_SPEED_DUMMY : 184,
	IW_PROPERTY_SP_REGEN_TIME_PCT : 185, 
};

function GetBasePropertyValue(hInstance, nProperty)
{
	return hInstance.properties_base[String(nProperty)]
}

function GetBonusPropertyValue(hInstance, nProperty)
{
	return hInstance.properties_bonus[String(nProperty)]
}

function GetPropertyValue(hInstance, nProperty)
{
	return hInstance.properties_base[String(nProperty)] + hInstance.properties_bonus[String(nProperty)];
}

function GetAttributeValue(hInstance, nAttribute)
{
	return GetPropertyValue(hInstance, nAttribute) * (1.0 + GetPropertyValue(hInstance, nAttribute + 6)/100.0);
}