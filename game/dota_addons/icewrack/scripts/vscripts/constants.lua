AbilityLearnResult_t =
{
	ABILITY_CAN_BE_UPGRADED = 0,
	ABILITY_CANNOT_BE_UPGRADED_NOT_UPGRADABLE = 1,
	ABILITY_CANNOT_BE_UPGRADED_AT_MAX = 2,
	ABILITY_CANNOT_BE_UPGRADED_REQUIRES_LEVEL = 3,
	ABILITY_NOT_LEARNABLE = 4,
}

Attributes =
{
	DOTA_ATTRIBUTE_INVALID = -1,
	DOTA_ATTRIBUTE_STRENGTH = 0,
	DOTA_ATTRIBUTE_AGILITY = 1,
	DOTA_ATTRIBUTE_INTELLECT = 2,
	DOTA_ATTRIBUTE_MAX = 3,
}

DOTAAbilitySpeakTrigger_t =
{
	DOTA_ABILITY_SPEAK_CAST = 1,
	DOTA_ABILITY_SPEAK_START_ACTION_PHASE = 0,
}

DOTALimits_t =
{
	DOTA_DEFAULT_MAX_TEAM = 5, -- Default number of players per team.
	DOTA_DEFAULT_MAX_TEAM_PLAYERS = 10, -- Default number of non-spectator players supported.
	DOTA_MAX_PLAYERS = 64, -- Max number of players connected to the server including spectators.
	DOTA_MAX_PLAYER_TEAMS = 10, -- Max number of player teams supported.
	DOTA_MAX_SPECTATOR_LOBBY_SIZE = 15, -- Max number of viewers in a spectator lobby.
	DOTA_MAX_SPECTATOR_TEAM_SIZE = 40, -- How many spectators can watch.
	DOTA_MAX_TEAM = 24, -- Max number of players per team.
	DOTA_MAX_TEAM_PLAYERS = 24, -- Max number of non-spectator players supported.
}

DOTAModifierAttribute_t =
{
	MODIFIER_ATTRIBUTE_NONE = 0,
	MODIFIER_ATTRIBUTE_PERMANENT = 1,
	MODIFIER_ATTRIBUTE_MULTIPLE = 2,
	MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE = 4,
	MODIFIER_ATTRIBUTE_AURA_PRIORITY = 8,
}

DOTASpeechType_t =
{
	DOTA_SPEECH_USER_INVALID = 0,
	DOTA_SPEECH_USER_SINGLE = 1,
	DOTA_SPEECH_USER_TEAM = 2,
	DOTA_SPEECH_USER_TEAM_NEARBY = 3,
	DOTA_SPEECH_USER_NEARBY = 4,
	DOTA_SPEECH_USER_ALL = 5,
	DOTA_SPEECH_GOOD_TEAM = 6,
	DOTA_SPEECH_BAD_TEAM = 7,
	DOTA_SPEECH_SPECTATOR = 8,
	DOTA_SPEECH_RECIPIENT_TYPE_MAX = 9,
}

DOTATeam_t =
{
	DOTA_TEAM_FIRST = 2,
	DOTA_TEAM_GOODGUYS = 2,
	DOTA_TEAM_BADGUYS = 3,
	DOTA_TEAM_NEUTRALS = 4,
	DOTA_TEAM_NOTEAM = 5,
	DOTA_TEAM_CUSTOM_MIN = 6,
	DOTA_TEAM_CUSTOM_1 = 6,
	DOTA_TEAM_CUSTOM_2 = 7,
	DOTA_TEAM_CUSTOM_3 = 8,
	DOTA_TEAM_CUSTOM_4 = 9,
	DOTA_TEAM_CUSTOM_5 = 10,
	DOTA_TEAM_CUSTOM_6 = 11,
	DOTA_TEAM_CUSTOM_7 = 12,
	DOTA_TEAM_CUSTOM_8 = 13,
	DOTA_TEAM_CUSTOM_MAX = 13,
	DOTA_TEAM_CUSTOM_COUNT = 8,
	DOTA_TEAM_COUNT = 14,
}

DOTA_ABILITY_BEHAVIOR =
{
	DOTA_ABILITY_BEHAVIOR_NONE = 0,
	DOTA_ABILITY_BEHAVIOR_HIDDEN = 1,
	DOTA_ABILITY_BEHAVIOR_PASSIVE = 2,
	DOTA_ABILITY_BEHAVIOR_NO_TARGET = 4,
	DOTA_ABILITY_BEHAVIOR_UNIT_TARGET = 8,
	DOTA_ABILITY_BEHAVIOR_POINT = 16,
	DOTA_ABILITY_BEHAVIOR_AOE = 32,
	DOTA_ABILITY_BEHAVIOR_NOT_LEARNABLE = 64,
	DOTA_ABILITY_BEHAVIOR_CHANNELLED = 128,
	DOTA_ABILITY_BEHAVIOR_ITEM = 256,
	DOTA_ABILITY_BEHAVIOR_TOGGLE = 512,
	DOTA_ABILITY_BEHAVIOR_DIRECTIONAL = 1024,
	DOTA_ABILITY_BEHAVIOR_IMMEDIATE = 2048,
	DOTA_ABILITY_BEHAVIOR_AUTOCAST = 4096,
	DOTA_ABILITY_BEHAVIOR_OPTIONAL_UNIT_TARGET = 8192,
	DOTA_ABILITY_BEHAVIOR_OPTIONAL_POINT = 16384,
	DOTA_ABILITY_BEHAVIOR_OPTIONAL_NO_TARGET = 32768,
	DOTA_ABILITY_BEHAVIOR_AURA = 65536,
	DOTA_ABILITY_BEHAVIOR_ATTACK = 131072,
	DOTA_ABILITY_BEHAVIOR_DONT_RESUME_MOVEMENT = 262144,
	DOTA_ABILITY_BEHAVIOR_ROOT_DISABLES = 524288,
	DOTA_ABILITY_BEHAVIOR_UNRESTRICTED = 1048576,
	DOTA_ABILITY_BEHAVIOR_IGNORE_PSEUDO_QUEUE = 2097152,
	DOTA_ABILITY_BEHAVIOR_IGNORE_CHANNEL = 4194304,
	DOTA_ABILITY_BEHAVIOR_DONT_CANCEL_MOVEMENT = 8388608,
	DOTA_ABILITY_BEHAVIOR_DONT_ALERT_TARGET = 16777216,
	DOTA_ABILITY_BEHAVIOR_DONT_RESUME_ATTACK = 33554432,
	DOTA_ABILITY_BEHAVIOR_NORMAL_WHEN_STOLEN = 67108864,
	DOTA_ABILITY_BEHAVIOR_IGNORE_BACKSWING = 134217728,
	DOTA_ABILITY_BEHAVIOR_RUNE_TARGET = 268435456,
	DOTA_ABILITY_BEHAVIOR_DONT_CANCEL_CHANNEL = 536870912,
	DOTA_ABILITY_BEHAVIOR_VECTOR_TARGETING = 1073741824,
	DOTA_ABILITY_BEHAVIOR_LAST_RESORT_POINT = -2147483648,
	DOTA_ABILITY_LAST_BEHAVIOR = -2147483648,
}

DOTA_HeroPickState =
{
	DOTA_HEROPICK_STATE_ALL_DRAFT_SELECT = 53,
	DOTA_HEROPICK_STATE_AP_SELECT = 1,
	DOTA_HEROPICK_STATE_AR_SELECT = 28,
	DOTA_HEROPICK_STATE_BD_SELECT = 50,
	DOTA_HEROPICK_STATE_CD_BAN1 = 33,
	DOTA_HEROPICK_STATE_CD_BAN2 = 34,
	DOTA_HEROPICK_STATE_CD_BAN3 = 35,
	DOTA_HEROPICK_STATE_CD_BAN4 = 36,
	DOTA_HEROPICK_STATE_CD_BAN5 = 37,
	DOTA_HEROPICK_STATE_CD_BAN6 = 38,
	DOTA_HEROPICK_STATE_CD_CAPTAINPICK = 32,
	DOTA_HEROPICK_STATE_CD_INTRO = 31,
	DOTA_HEROPICK_STATE_CD_PICK = 49,
	DOTA_HEROPICK_STATE_CD_SELECT1 = 39,
	DOTA_HEROPICK_STATE_CD_SELECT10 = 48,
	DOTA_HEROPICK_STATE_CD_SELECT2 = 40,
	DOTA_HEROPICK_STATE_CD_SELECT3 = 41,
	DOTA_HEROPICK_STATE_CD_SELECT4 = 42,
	DOTA_HEROPICK_STATE_CD_SELECT5 = 43,
	DOTA_HEROPICK_STATE_CD_SELECT6 = 44,
	DOTA_HEROPICK_STATE_CD_SELECT7 = 45,
	DOTA_HEROPICK_STATE_CD_SELECT8 = 46,
	DOTA_HEROPICK_STATE_CD_SELECT9 = 47,
	DOTA_HEROPICK_STATE_CM_BAN1 = 7,
	DOTA_HEROPICK_STATE_CM_BAN10 = 16,
	DOTA_HEROPICK_STATE_CM_BAN2 = 8,
	DOTA_HEROPICK_STATE_CM_BAN3 = 9,
	DOTA_HEROPICK_STATE_CM_BAN4 = 10,
	DOTA_HEROPICK_STATE_CM_BAN5 = 11,
	DOTA_HEROPICK_STATE_CM_BAN6 = 12,
	DOTA_HEROPICK_STATE_CM_BAN7 = 13,
	DOTA_HEROPICK_STATE_CM_BAN8 = 14,
	DOTA_HEROPICK_STATE_CM_BAN9 = 15,
	DOTA_HEROPICK_STATE_CM_CAPTAINPICK = 6,
	DOTA_HEROPICK_STATE_CM_INTRO = 5,
	DOTA_HEROPICK_STATE_CM_PICK = 27,
	DOTA_HEROPICK_STATE_CM_SELECT1 = 17,
	DOTA_HEROPICK_STATE_CM_SELECT10 = 26,
	DOTA_HEROPICK_STATE_CM_SELECT2 = 18,
	DOTA_HEROPICK_STATE_CM_SELECT3 = 19,
	DOTA_HEROPICK_STATE_CM_SELECT4 = 20,
	DOTA_HEROPICK_STATE_CM_SELECT5 = 21,
	DOTA_HEROPICK_STATE_CM_SELECT6 = 22,
	DOTA_HEROPICK_STATE_CM_SELECT7 = 23,
	DOTA_HEROPICK_STATE_CM_SELECT8 = 24,
	DOTA_HEROPICK_STATE_CM_SELECT9 = 25,
	DOTA_HEROPICK_STATE_COUNT = 56,
	DOTA_HEROPICK_STATE_FH_SELECT = 30,
	DOTA_HEROPICK_STATE_INTRO_SELECT_UNUSED = 3,
	DOTA_HEROPICK_STATE_MO_SELECT = 29,
	DOTA_HEROPICK_STATE_NONE = 0,
	DOTA_HEROPICK_STATE_RD_SELECT_UNUSED = 4,
	DOTA_HEROPICK_STATE_SD_SELECT = 2,
	DOTA_HEROPICK_STATE_SELECT_PENALTY = 55,
	DOTA_HERO_PICK_STATE_ABILITY_DRAFT_SELECT = 51,
	DOTA_HERO_PICK_STATE_ARDM_SELECT = 52,
	DOTA_HERO_PICK_STATE_CUSTOMGAME_SELECT = 54,
}

DOTA_MOTION_CONTROLLER_PRIORITY =
{
	DOTA_MOTION_CONTROLLER_PRIORITY_HIGH = 3,
	DOTA_MOTION_CONTROLLER_PRIORITY_HIGHEST = 4,
	DOTA_MOTION_CONTROLLER_PRIORITY_LOW = 1,
	DOTA_MOTION_CONTROLLER_PRIORITY_LOWEST = 0,
	DOTA_MOTION_CONTROLLER_PRIORITY_MEDIUM = 2,
}

DOTA_RUNES =
{
	DOTA_RUNE_ARCANE = 6,
	DOTA_RUNE_BOUNTY = 5,
	DOTA_RUNE_COUNT = 7,
	DOTA_RUNE_DOUBLEDAMAGE = 0,
	DOTA_RUNE_HASTE = 1,
	DOTA_RUNE_ILLUSION = 2,
	DOTA_RUNE_INVALID = -1,
	DOTA_RUNE_INVISIBILITY = 3,
	DOTA_RUNE_REGENERATION = 4,
}

DOTA_UNIT_TARGET_FLAGS =
{
	DOTA_UNIT_TARGET_FLAG_CHECK_DISABLE_HELP = 65536,
	DOTA_UNIT_TARGET_FLAG_DEAD = 8,
	DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE = 128,
	DOTA_UNIT_TARGET_FLAG_INVULNERABLE = 64,
	DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES = 16,
	DOTA_UNIT_TARGET_FLAG_MANA_ONLY = 32768,
	DOTA_UNIT_TARGET_FLAG_MELEE_ONLY = 4,
	DOTA_UNIT_TARGET_FLAG_NONE = 0,
	DOTA_UNIT_TARGET_FLAG_NOT_ANCIENTS = 512,
	DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE = 16384,
	DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO = 131072,
	DOTA_UNIT_TARGET_FLAG_NOT_DOMINATED = 2048,
	DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS = 8192,
	DOTA_UNIT_TARGET_FLAG_NOT_MAGIC_IMMUNE_ALLIES = 32,
	DOTA_UNIT_TARGET_FLAG_NOT_NIGHTMARED = 524288,
	DOTA_UNIT_TARGET_FLAG_NOT_SUMMONED = 4096,
	DOTA_UNIT_TARGET_FLAG_NO_INVIS = 256,
	DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD = 262144,
	DOTA_UNIT_TARGET_FLAG_PLAYER_CONTROLLED = 1024,
	DOTA_UNIT_TARGET_FLAG_PREFER_ENEMIES = 1048576,
	DOTA_UNIT_TARGET_FLAG_RANGED_ONLY = 2,
}

DOTA_UNIT_TARGET_TEAM =
{
	DOTA_UNIT_TARGET_TEAM_NONE = 0,
	DOTA_UNIT_TARGET_TEAM_FRIENDLY = 1,
	DOTA_UNIT_TARGET_TEAM_ENEMY = 2,
	DOTA_UNIT_TARGET_TEAM_BOTH = 3,
	DOTA_UNIT_TARGET_TEAM_CUSTOM = 4,
}

DOTA_UNIT_TARGET_TYPE =
{
	DOTA_UNIT_TARGET_ALL = 55,
	DOTA_UNIT_TARGET_BASIC = 18,
	DOTA_UNIT_TARGET_BUILDING = 4,
	DOTA_UNIT_TARGET_COURIER = 16,
	DOTA_UNIT_TARGET_CREEP = 2,
	DOTA_UNIT_TARGET_CUSTOM = 128,
	DOTA_UNIT_TARGET_HERO = 1,
	DOTA_UNIT_TARGET_NONE = 0,
	DOTA_UNIT_TARGET_OTHER = 32,
	DOTA_UNIT_TARGET_TREE = 64,
}

LuaModifierType =
{
	LUA_MODIFIER_MOTION_NONE = 0,
	LUA_MODIFIER_MOTION_HORIZONTAL = 1,
	LUA_MODIFIER_MOTION_VERTICAL = 2,
	LUA_MODIFIER_MOTION_BOTH = 3,
	LUA_MODIFIER_INVALID = 4,
}

ParticleAttachment_t =
{
	PATTACH_INVALID = -1,
	PATTACH_ABSORIGIN = 0,
	PATTACH_ABSORIGIN_FOLLOW = 1,
	PATTACH_CUSTOMORIGIN = 2,
	PATTACH_CUSTOMORIGIN_FOLLOW = 3,
	PATTACH_POINT = 4,
	PATTACH_POINT_FOLLOW = 5,
	PATTACH_EYES_FOLLOW = 6,
	PATTACH_OVERHEAD_FOLLOW = 7,
	PATTACH_WORLDORIGIN = 8,
	PATTACH_ROOTBONE_FOLLOW = 9,
	PATTACH_RENDERORIGIN_FOLLOW = 10,
	PATTACH_MAIN_VIEW = 11,
	PATTACH_WATERWAKE = 12,
	PATTACH_CENTER_FOLLOW = 13,
	MAX_PATTACH_TYPES = 14,
}

UnitFilterResult =
{
	UF_SUCCESS = 0,
	UF_FAIL_FRIENDLY = 1,
	UF_FAIL_ENEMY = 2,
	UF_FAIL_HERO = 3,
	UF_FAIL_CONSIDERED_HERO = 4,
	UF_FAIL_CREEP = 5,
	UF_FAIL_BUILDING = 6,
	UF_FAIL_COURIER = 7,
	UF_FAIL_OTHER = 8,
	UF_FAIL_ANCIENT = 9,
	UF_FAIL_ILLUSION = 10,
	UF_FAIL_SUMMONED = 11,
	UF_FAIL_DOMINATED = 12,
	UF_FAIL_MELEE = 13,
	UF_FAIL_RANGED = 14,
	UF_FAIL_DEAD = 15,
	UF_FAIL_MAGIC_IMMUNE_ALLY = 16,
	UF_FAIL_MAGIC_IMMUNE_ENEMY = 17,
	UF_FAIL_INVULNERABLE = 18,
	UF_FAIL_IN_FOW = 19,
	UF_FAIL_INVISIBLE = 20,
	UF_FAIL_NOT_PLAYER_CONTROLLED = 21,
	UF_FAIL_ATTACK_IMMUNE = 22,
	UF_FAIL_CUSTOM = 23,
	UF_FAIL_INVALID_LOCATION = 24,
	UF_FAIL_DISABLE_HELP = 25,
	UF_FAIL_OUT_OF_WORLD = 26,
	UF_FAIL_NIGHTMARED = 27,
}

modifierevent = {}
modifierproperty = {}
for k,v in pairs(_G) do
	if type(v) == "number" then
		if string.find(k, "MODIFIER_EVENT_ON_") == 1 then
			modifierevent[k] = v
		elseif string.find(k, "MODIFIER_PROPERTY_") == 1 then
			modifierproperty[k] = v
		end
	end
end

stLuaModifierPropertyAliases =
{
	MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE = "GetModifierPreAttack_BonusDamage",
	MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE_PROC = "GetModifierPreAttack_BonusDamage_Proc",
	MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE_POST_CRIT = "GetModifierPreAttack_BonusDamagePostCrit",
	MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE = "GetModifierBaseAttack_BonusDamage",
	MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PHYSICAL = "GetModifierProcAttack_BonusDamage_Physical",
	MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_MAGICAL = "GetModifierProcAttack_BonusDamage_Magical",
	MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PURE = "GetModifierProcAttack_BonusDamage_Pure",
	MODIFIER_PROPERTY_PROCATTACK_FEEDBACK = "GetModifierProcAttack_Feedback",
	MODIFIER_PROPERTY_PRE_ATTACK = "GetModifierPreAttack",
	MODIFIER_PROPERTY_INVISIBILITY_LEVEL = "GetModifierInvisibilityLevel",
	MODIFIER_PROPERTY_PERSISTENT_INVISIBILITY = "GetModifierPersistentInvisibility",
	MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT = "GetModifierMoveSpeedBonus_Constant",
	MODIFIER_PROPERTY_MOVESPEED_BASE_OVERRIDE = "GetModifierMoveSpeedOverride",
	MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE = "GetModifierMoveSpeedBonus_Percentage",
	MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE_UNIQUE = "GetModifierMoveSpeedBonus_Percentage_Unique",
	MODIFIER_PROPERTY_MOVESPEED_BONUS_UNIQUE = "GetModifierMoveSpeedBonus_Special_Boots",
	MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE = "GetModifierMoveSpeed_Absolute",
	MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE_MIN = "GetModifierMoveSpeed_AbsoluteMin",
	MODIFIER_PROPERTY_MOVESPEED_LIMIT = "GetModifierMoveSpeed_Limit",
	MODIFIER_PROPERTY_MOVESPEED_MAX = "GetModifierMoveSpeed_Max",
	MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT = "GetModifierAttackSpeedBonus_Constant",
	MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT_POWER_TREADS = "GetModifierAttackSpeedBonus_Constant_PowerTreads",
	MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT_SECONDARY = "GetModifierAttackSpeedBonus_Constant_Secondary",
	MODIFIER_PROPERTY_COOLDOWN_REDUCTION_CONSTANT = "GetModifierCooldownReduction_Constant",
	MODIFIER_PROPERTY_BASE_ATTACK_TIME_CONSTANT = "GetModifierBaseAttackTimeConstant",
	MODIFIER_PROPERTY_ATTACK_POINT_CONSTANT = "GetModifierAttackPointConstant",
	MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE = "GetModifierDamageOutgoing_Percentage",
	MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE_ILLUSION = "GetModifierDamageOutgoing_Percentage_Illusion",
	MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE = "GetModifierTotalDamageOutgoing_Percentage",
	MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE = "GetModifierBaseDamageOutgoing_Percentage",
	MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE_UNIQUE = "GetModifierBaseDamageOutgoing_PercentageUnique",
	MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE = "GetModifierIncomingDamage_Percentage",
	MODIFIER_PROPERTY_INCOMING_PHYSICAL_DAMAGE_PERCENTAGE = "GetModifierIncomingPhysicalDamage_Percentage",
	MODIFIER_PROPERTY_INCOMING_SPELL_DAMAGE_CONSTANT = "GetModifierIncomingSpellDamageConstant",
	MODIFIER_PROPERTY_EVASION_CONSTANT = "GetModifierEvasion_Constant",
	MODIFIER_PROPERTY_AVOID_DAMAGE = "GetModifierAvoidDamage",
	MODIFIER_PROPERTY_AVOID_SPELL = "GetModifierAvoidSpell",
	MODIFIER_PROPERTY_MISS_PERCENTAGE = "GetModifierMiss_Percentage",
	MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS = "GetModifierPhysicalArmorBonus",
	MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS_ILLUSIONS = "GetModifierPhysicalArmorBonusIllusions",
	MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS_UNIQUE = "GetModifierPhysicalArmorBonusUnique",
	MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS_UNIQUE_ACTIVE = "GetModifierPhysicalArmorBonusUniqueActive",
	MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS = "GetModifierMagicalResistanceBonus",
	MODIFIER_PROPERTY_MAGICAL_RESISTANCE_ITEM_UNIQUE = "GetModifierMagicalResistanceItemUnique",
	MODIFIER_PROPERTY_MAGICAL_RESISTANCE_DECREPIFY_UNIQUE = "GetModifierMagicalResistanceDecrepifyUnique",
	MODIFIER_PROPERTY_BASE_MANA_REGEN = "GetModifierBaseRegen",
	MODIFIER_PROPERTY_MANA_REGEN_CONSTANT = "GetModifierConstantManaRegen",
	MODIFIER_PROPERTY_MANA_REGEN_CONSTANT_UNIQUE = "GetModifierConstantManaRegenUnique",
	MODIFIER_PROPERTY_MANA_REGEN_PERCENTAGE = "GetModifierPercentageManaRegen",
	MODIFIER_PROPERTY_MANA_REGEN_TOTAL_PERCENTAGE = "GetModifierTotalPercentageManaRegen",
	MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT = "GetModifierConstantHealthRegen",
	MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE = "GetModifierHealthRegenPercentage",
	MODIFIER_PROPERTY_HEALTH_BONUS = "GetModifierHealthBonus",
	MODIFIER_PROPERTY_MANA_BONUS = "GetModifierManaBonus",
	MODIFIER_PROPERTY_EXTRA_STRENGTH_BONUS = "GetModifierExtraStrengthBonus",
	MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS = "GetModifierExtraHealthBonus",
	MODIFIER_PROPERTY_EXTRA_MANA_BONUS = "GetModifierExtraManaBonus",
	MODIFIER_PROPERTY_EXTRA_HEALTH_PERCENTAGE = "GetModifierExtraHealthPercentage",
	MODIFIER_PROPERTY_STATS_STRENGTH_BONUS = "GetModifierBonusStats_Strength",
	MODIFIER_PROPERTY_STATS_AGILITY_BONUS = "GetModifierBonusStats_Agility",
	MODIFIER_PROPERTY_STATS_INTELLECT_BONUS = "GetModifierBonusStats_Intellect",
	MODIFIER_PROPERTY_ATTACK_RANGE_BONUS = "GetModifierAttackRangeBonus",
	MODIFIER_PROPERTY_PROJECTILE_SPEED_BONUS = "GetModifierProjectileSpeedBonus",
	MODIFIER_PROPERTY_REINCARNATION = "ReincarnateTime",
	MODIFIER_PROPERTY_RESPAWNTIME = "GetModifierConstantRespawnTime",
	MODIFIER_PROPERTY_RESPAWNTIME_PERCENTAGE = "GetModifierPercentageRespawnTime",
	MODIFIER_PROPERTY_RESPAWNTIME_STACKING = "GetModifierStackingRespawnTime",
	MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE = "GetModifierPercentageCooldown",
	MODIFIER_PROPERTY_CASTTIME_PERCENTAGE = "GetModifierPercentageCasttime",
	MODIFIER_PROPERTY_MANACOST_PERCENTAGE = "GetModifierPercentageManacost",
	MODIFIER_PROPERTY_DEATHGOLDCOST = "GetModifierConstantDeathGoldCost",
	MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE = "GetModifierPreAttack_CriticalStrike",
	MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK = "GetModifierPhysical_ConstantBlock",
	MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK_UNAVOIDABLE_PRE_ARMOR = "GetModifierPhysical_ConstantBlockUnavoidablePreArmor",
	MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK = "GetModifierTotal_ConstantBlock",
	MODIFIER_PROPERTY_OVERRIDE_ANIMATION = "GetOverrideAnimation",
	MODIFIER_PROPERTY_OVERRIDE_ANIMATION_WEIGHT = "GetOverrideAnimationWeight",
	MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE = "GetOverrideAnimationRate",
	MODIFIER_PROPERTY_ABSORB_SPELL = "GetAbsorbSpell",
	MODIFIER_PROPERTY_REFLECT_SPELL = "GetReflectSpell",
	MODIFIER_PROPERTY_DISABLE_AUTOATTACK = "GetDisableAutoAttack",
	MODIFIER_PROPERTY_BONUS_DAY_VISION = "GetBonusDayVision",
	MODIFIER_PROPERTY_BONUS_NIGHT_VISION = "GetBonusNightVision",
	MODIFIER_PROPERTY_BONUS_NIGHT_VISION_UNIQUE = "GetBonusNightVisionUnique",
	MODIFIER_PROPERTY_BONUS_VISION_PERCENTAGE = "GetBonusVisionPercentage",
	MODIFIER_PROPERTY_FIXED_DAY_VISION = "GetFixedDayVision",
	MODIFIER_PROPERTY_FIXED_NIGHT_VISION = "GetFixedNightVision",
	MODIFIER_PROPERTY_MIN_HEALTH = "GetMinHealth",
	MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL = "GetAbsoluteNoDamagePhysical",
	MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL = "GetAbsoluteNoDamageMagical",
	MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE = "GetAbsoluteNoDamagePure",
	MODIFIER_PROPERTY_IS_ILLUSION = "GetIsIllusion",
	MODIFIER_PROPERTY_ILLUSION_LABEL = "GetModifierIllusionLabel",
	MODIFIER_PROPERTY_SUPER_ILLUSION = "GetModifierSuperIllusion",
	MODIFIER_PROPERTY_TURN_RATE_PERCENTAGE = "GetModifierTurnRate_Percentage",
	MODIFIER_PROPERTY_DISABLE_HEALING = "GetDisableHealing",
	MODIFIER_PROPERTY_OVERRIDE_ATTACK_MAGICAL = "GetOverrideAttackMagical",
	MODIFIER_PROPERTY_UNIT_STATS_NEEDS_REFRESH = "GetModifierUnitStatsNeedsRefresh",
	MODIFIER_PROPERTY_BOUNTY_CREEP_MULTIPLIER = "GetModifierBountyCreepMultiplier",
	MODIFIER_PROPERTY_BOUNTY_OTHER_MULTIPLIER = "GetModifierBountyOtherMultiplier",
	MODIFIER_PROPERTY_TOOLTIP = "OnTooltip",
	MODIFIER_PROPERTY_MODEL_CHANGE = "GetModifierModelChange",
	MODIFIER_PROPERTY_MODEL_SCALE = "GetModifierModelScale",
	MODIFIER_PROPERTY_IS_SCEPTER = "GetModifierScepter",
	MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS = "GetActivityTranslationModifiers",
	MODIFIER_PROPERTY_TRANSLATE_ATTACK_SOUND = "GetAttackSound",
	MODIFIER_PROPERTY_LIFETIME_FRACTION = "GetUnitLifetimeFraction",
	MODIFIER_PROPERTY_PROVIDES_FOW_POSITION = "GetModifierProvidesFOWVision",
	MODIFIER_PROPERTY_SPELLS_REQUIRE_HP = "GetModifierSpellsRequireHP",
	MODIFIER_PROPERTY_FORCE_DRAW_MINIMAP = "GetForceDrawOnMinimap",
	MODIFIER_PROPERTY_DISABLE_TURNING = "GetModifierDisableTurning",
	MODIFIER_PROPERTY_IGNORE_CAST_ANGLE = "GetModifierIgnoreCastAngle",
	MODIFIER_PROPERTY_CHANGE_ABILITY_VALUE = "GetModifierChangeAbilityValue",
	MODIFIER_PROPERTY_ABILITY_LAYOUT = "GetModifierAbilityLayout",
}

stLuaModifierEventAliases = 
{
	MODIFIER_EVENT_ON_ATTACK_RECORD = "OnAttackRecord",
	MODIFIER_EVENT_ON_ATTACK_START = "OnAttackStart",
	MODIFIER_EVENT_ON_ATTACK = "OnAttack",
	MODIFIER_EVENT_ON_ATTACK_LANDED = "OnAttackLanded",
	MODIFIER_EVENT_ON_ATTACK_FAIL = "OnAttackFail",
	MODIFIER_EVENT_ON_ATTACK_ALLIED = "OnAttackAllied",
	MODIFIER_EVENT_ON_ATTACK_FINISHED = "OnAttackFinished",
	MODIFIER_EVENT_ON_PROJECTILE_DODGE = "OnProjectileDodge",
	MODIFIER_EVENT_ON_ORDER = "OnOrder",
	MODIFIER_EVENT_ON_UNIT_MOVED = "OnUnitMoved",
	MODIFIER_EVENT_ON_ABILITY_START = "OnAbilityStart",
	MODIFIER_EVENT_ON_ABILITY_EXECUTED = "OnAbilityExecuted",
	MODIFIER_EVENT_ON_ABILITY_FULLY_CAST = "OnAbilityFullyCast",
	MODIFIER_EVENT_ON_BREAK_INVISIBILITY = "OnBreakInvisibility",
	MODIFIER_EVENT_ON_ABILITY_END_CHANNEL = "OnAbilityEndChannel",
	MODIFIER_EVENT_ON_TAKEDAMAGE = "OnTakeDamage",
	MODIFIER_EVENT_ON_STATE_CHANGED = "OnStateChanged",
	MODIFIER_EVENT_ON_ATTACKED = "OnAttacked",
	MODIFIER_EVENT_ON_DEATH = "OnDeath",
	MODIFIER_EVENT_ON_RESPAWN = "OnRespawn",
	MODIFIER_EVENT_ON_SPENT_MANA = "OnSpentMana",
	MODIFIER_EVENT_ON_TELEPORTING = "OnTeleporting",
	MODIFIER_EVENT_ON_TELEPORTED = "OnTeleported",
	MODIFIER_EVENT_ON_SET_LOCATION = "OnSetLocation",
	MODIFIER_EVENT_ON_HEALTH_GAINED = "OnHealthGained",
	MODIFIER_EVENT_ON_MANA_GAINED = "OnManaGained",
	MODIFIER_EVENT_ON_TAKEDAMAGE_KILLCREDIT = "OnTakeDamageKillCredit",
	MODIFIER_EVENT_ON_HERO_KILLED = "OnHeroKilled",
	MODIFIER_EVENT_ON_HEAL_RECEIVED = "OnHealReceived",
	MODIFIER_EVENT_ON_BUILDING_KILLED = "OnBuildingKilled",
	MODIFIER_EVENT_ON_MODEL_CHANGED = "OnModelChanged",
	MODIFIER_EVENT_ON_CREATED = "OnModifierCreated",
	MODIFIER_EVENT_ON_DESTROY = "OnModifierDestroy",
	MODIFIER_EVENT_ON_REFRESH = "OnModifierRefresh",
	MODIFIER_EVENT_ON_INTERVAL_THINK = "OnIntervalThink",
}

modifierpriority =
{
	MODIFIER_PRIORITY_LOW = 0,
	MODIFIER_PRIORITY_NORMAL = 1,
	MODIFIER_PRIORITY_HIGH = 2,
	MODIFIER_PRIORITY_ULTRA = 3,
	MODIFIER_PRIORITY_SUPER_ULTRA = 4,
}

modifierremove =
{
	DOTA_BUFF_REMOVE_ALL = 0,
	DOTA_BUFF_REMOVE_ENEMY = 1,
	DOTA_BUFF_REMOVE_ALLY = 2,
}

modifierstate =
{
	MODIFIER_STATE_ROOTED = 0,
	MODIFIER_STATE_DISARMED = 1,
	MODIFIER_STATE_ATTACK_IMMUNE = 2,
	MODIFIER_STATE_SILENCED = 3,
	MODIFIER_STATE_MUTED = 4,
	MODIFIER_STATE_STUNNED = 5,
	MODIFIER_STATE_HEXED = 6,
	MODIFIER_STATE_INVISIBLE = 7,
	MODIFIER_STATE_INVULNERABLE = 8,
	MODIFIER_STATE_MAGIC_IMMUNE = 9,
	MODIFIER_STATE_PROVIDES_VISION = 10,
	MODIFIER_STATE_NIGHTMARED = 11,
	MODIFIER_STATE_BLOCK_DISABLED = 12,
	MODIFIER_STATE_EVADE_DISABLED = 13,
	MODIFIER_STATE_UNSELECTABLE = 14,
	MODIFIER_STATE_CANNOT_TARGET_ENEMIES = 15,
	MODIFIER_STATE_CANNOT_MISS = 16,
	MODIFIER_STATE_SPECIALLY_DENIABLE = 17,
	MODIFIER_STATE_FROZEN = 18,
	MODIFIER_STATE_COMMAND_RESTRICTED = 19,
	MODIFIER_STATE_NOT_ON_MINIMAP = 20,
	MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES = 21,
	MODIFIER_STATE_LOW_ATTACK_PRIORITY = 22,
	MODIFIER_STATE_NO_HEALTH_BAR = 23,
	MODIFIER_STATE_FLYING = 24,
	MODIFIER_STATE_NO_UNIT_COLLISION = 25,
	MODIFIER_STATE_NO_TEAM_MOVE_TO = 26,
	MODIFIER_STATE_NO_TEAM_SELECT = 27,
	MODIFIER_STATE_PASSIVES_DISABLED = 28,
	MODIFIER_STATE_DOMINATED = 29,
	MODIFIER_STATE_BLIND = 30,
	MODIFIER_STATE_OUT_OF_GAME = 31,
	MODIFIER_STATE_FAKE_ALLY = 32,
	MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY = 33,
	MODIFIER_STATE_TRUESIGHT_IMMUNE = 34,
	MODIFIER_STATE_LAST = 35,
}

GameActivity_t =
{
	ACT_DOTA_IDLE = 1500,
	ACT_DOTA_IDLE_RARE = 1501,
	ACT_DOTA_RUN = 1502,
	ACT_DOTA_ATTACK = 1503,
	ACT_DOTA_ATTACK2 = 1504,
	ACT_DOTA_ATTACK_EVENT = 1505,
	ACT_DOTA_DIE = 1506,
	ACT_DOTA_FLINCH = 1507,
	ACT_DOTA_FLAIL = 1508,
	ACT_DOTA_DISABLED = 1509,
	ACT_DOTA_CAST_ABILITY_1 = 1510,
	ACT_DOTA_CAST_ABILITY_2 = 1511,
	ACT_DOTA_CAST_ABILITY_3 = 1512,
	ACT_DOTA_CAST_ABILITY_4 = 1513,
	ACT_DOTA_CAST_ABILITY_5 = 1514,
	ACT_DOTA_CAST_ABILITY_6 = 1515,
	ACT_DOTA_OVERRIDE_ABILITY_1 = 1516,
	ACT_DOTA_OVERRIDE_ABILITY_2 = 1517,
	ACT_DOTA_OVERRIDE_ABILITY_3 = 1518,
	ACT_DOTA_OVERRIDE_ABILITY_4 = 1519,
	ACT_DOTA_CHANNEL_ABILITY_1 = 1520,
	ACT_DOTA_CHANNEL_ABILITY_2 = 1521,
	ACT_DOTA_CHANNEL_ABILITY_3 = 1522,
	ACT_DOTA_CHANNEL_ABILITY_4 = 1523,
	ACT_DOTA_CHANNEL_ABILITY_5 = 1524,
	ACT_DOTA_CHANNEL_ABILITY_6 = 1525,
	ACT_DOTA_CHANNEL_END_ABILITY_1 = 1526,
	ACT_DOTA_CHANNEL_END_ABILITY_2 = 1527,
	ACT_DOTA_CHANNEL_END_ABILITY_3 = 1528,
	ACT_DOTA_CHANNEL_END_ABILITY_4 = 1529,
	ACT_DOTA_CHANNEL_END_ABILITY_5 = 1530,
	ACT_DOTA_CHANNEL_END_ABILITY_6 = 1531,
	ACT_DOTA_CONSTANT_LAYER = 1532,
	ACT_DOTA_CAPTURE = 1533,
	ACT_DOTA_SPAWN = 1534,
	ACT_DOTA_KILLTAUNT = 1535,
	ACT_DOTA_TAUNT = 1536,
	ACT_DOTA_THIRST = 1537,
	ACT_DOTA_CAST_DRAGONBREATH = 1538,
	ACT_DOTA_ECHO_SLAM = 1539,
	ACT_DOTA_CAST_ABILITY_1_END = 1540,
	ACT_DOTA_CAST_ABILITY_2_END = 1541,
	ACT_DOTA_CAST_ABILITY_3_END = 1542,
	ACT_DOTA_CAST_ABILITY_4_END = 1543,
	ACT_MIRANA_LEAP_END = 1544,
	ACT_WAVEFORM_START = 1545,
	ACT_WAVEFORM_END = 1546,
	ACT_DOTA_CAST_ABILITY_ROT = 1547,
	ACT_DOTA_DIE_SPECIAL = 1548,
	ACT_DOTA_RATTLETRAP_BATTERYASSAULT = 1549,
	ACT_DOTA_RATTLETRAP_POWERCOGS = 1550,
	ACT_DOTA_RATTLETRAP_HOOKSHOT_START = 1551,
	ACT_DOTA_RATTLETRAP_HOOKSHOT_LOOP = 1552,
	ACT_DOTA_RATTLETRAP_HOOKSHOT_END = 1553,
	ACT_STORM_SPIRIT_OVERLOAD_RUN_OVERRIDE = 1554,
	ACT_DOTA_TINKER_REARM1 = 1555,
	ACT_DOTA_TINKER_REARM2 = 1556,
	ACT_DOTA_TINKER_REARM3 = 1557,
	ACT_TINY_AVALANCHE = 1558,
	ACT_TINY_TOSS = 1559,
	ACT_TINY_GROWL = 1560,
	ACT_DOTA_WEAVERBUG_ATTACH = 1561,
	ACT_DOTA_CAST_WILD_AXES_END = 1562,
	ACT_DOTA_CAST_LIFE_BREAK_START = 1563,
	ACT_DOTA_CAST_LIFE_BREAK_END = 1564,
	ACT_DOTA_NIGHTSTALKER_TRANSITION = 1565,
	ACT_DOTA_LIFESTEALER_RAGE = 1566,
	ACT_DOTA_LIFESTEALER_OPEN_WOUNDS = 1567,
	ACT_DOTA_SAND_KING_BURROW_IN = 1568,
	ACT_DOTA_SAND_KING_BURROW_OUT = 1569,
	ACT_DOTA_EARTHSHAKER_TOTEM_ATTACK = 1570,
	ACT_DOTA_WHEEL_LAYER = 1571,
	ACT_DOTA_ALCHEMIST_CHEMICAL_RAGE_START = 1572,
	ACT_DOTA_ALCHEMIST_CONCOCTION = 1573,
	ACT_DOTA_JAKIRO_LIQUIDFIRE_START = 1574,
	ACT_DOTA_JAKIRO_LIQUIDFIRE_LOOP = 1575,
	ACT_DOTA_LIFESTEALER_INFEST = 1576,
	ACT_DOTA_LIFESTEALER_INFEST_END = 1577,
	ACT_DOTA_LASSO_LOOP = 1578,
	ACT_DOTA_ALCHEMIST_CONCOCTION_THROW = 1579,
	ACT_DOTA_ALCHEMIST_CHEMICAL_RAGE_END = 1580,
	ACT_DOTA_CAST_COLD_SNAP = 1581,
	ACT_DOTA_CAST_GHOST_WALK = 1582,
	ACT_DOTA_CAST_TORNADO = 1583,
	ACT_DOTA_CAST_EMP = 1584,
	ACT_DOTA_CAST_ALACRITY = 1585,
	ACT_DOTA_CAST_CHAOS_METEOR = 1586,
	ACT_DOTA_CAST_SUN_STRIKE = 1587,
	ACT_DOTA_CAST_FORGE_SPIRIT = 1588,
	ACT_DOTA_CAST_ICE_WALL = 1589,
	ACT_DOTA_CAST_DEAFENING_BLAST = 1590,
	ACT_DOTA_VICTORY = 1591,
	ACT_DOTA_DEFEAT = 1592,
	ACT_DOTA_SPIRIT_BREAKER_CHARGE_POSE = 1593,
	ACT_DOTA_SPIRIT_BREAKER_CHARGE_END = 1594,
	ACT_DOTA_TELEPORT = 1595,
	ACT_DOTA_TELEPORT_END = 1596,
	ACT_DOTA_CAST_REFRACTION = 1597,
	ACT_DOTA_CAST_ABILITY_7 = 1598,
	ACT_DOTA_CANCEL_SIREN_SONG = 1599,
	ACT_DOTA_CHANNEL_ABILITY_7 = 1600,
	ACT_DOTA_LOADOUT = 1601,
	ACT_DOTA_FORCESTAFF_END = 1602,
	ACT_DOTA_POOF_END = 1603,
	ACT_DOTA_SLARK_POUNCE = 1604,
	ACT_DOTA_MAGNUS_SKEWER_START = 1605,
	ACT_DOTA_MAGNUS_SKEWER_END = 1606,
	ACT_DOTA_MEDUSA_STONE_GAZE = 1607,
	ACT_DOTA_RELAX_START = 1608,
	ACT_DOTA_RELAX_LOOP = 1609,
	ACT_DOTA_RELAX_END = 1610,
	ACT_DOTA_CENTAUR_STAMPEDE = 1611,
	ACT_DOTA_BELLYACHE_START = 1612,
	ACT_DOTA_BELLYACHE_LOOP = 1613,
	ACT_DOTA_BELLYACHE_END = 1614,
	ACT_DOTA_ROQUELAIRE_LAND = 1615,
	ACT_DOTA_ROQUELAIRE_LAND_IDLE = 1616,
	ACT_DOTA_GREEVIL_CAST = 1617,
	ACT_DOTA_GREEVIL_OVERRIDE_ABILITY = 1618,
	ACT_DOTA_GREEVIL_HOOK_START = 1619,
	ACT_DOTA_GREEVIL_HOOK_END = 1620,
	ACT_DOTA_GREEVIL_BLINK_BONE = 1621,
	ACT_DOTA_IDLE_SLEEPING = 1622,
	ACT_DOTA_INTRO = 1623,
	ACT_DOTA_GESTURE_POINT = 1624,
	ACT_DOTA_GESTURE_ACCENT = 1625,
	ACT_DOTA_SLEEPING_END = 1626,
	ACT_DOTA_AMBUSH = 1627,
	ACT_DOTA_ITEM_LOOK = 1628,
	ACT_DOTA_STARTLE = 1629,
	ACT_DOTA_FRUSTRATION = 1630,
	ACT_DOTA_TELEPORT_REACT = 1631,
	ACT_DOTA_TELEPORT_END_REACT = 1632,
	ACT_DOTA_SHRUG = 1633,
	ACT_DOTA_RELAX_LOOP_END = 1634,
	ACT_DOTA_PRESENT_ITEM = 1635,
	ACT_DOTA_IDLE_IMPATIENT = 1636,
	ACT_DOTA_SHARPEN_WEAPON = 1637,
	ACT_DOTA_SHARPEN_WEAPON_OUT = 1638,
	ACT_DOTA_IDLE_SLEEPING_END = 1639,
	ACT_DOTA_BRIDGE_DESTROY = 1640,
	ACT_DOTA_TAUNT_SNIPER = 1641,
	ACT_DOTA_DEATH_BY_SNIPER = 1642,
	ACT_DOTA_LOOK_AROUND = 1643,
	ACT_DOTA_CAGED_CREEP_RAGE = 1644,
	ACT_DOTA_CAGED_CREEP_RAGE_OUT = 1645,
	ACT_DOTA_CAGED_CREEP_SMASH = 1646,
	ACT_DOTA_CAGED_CREEP_SMASH_OUT = 1647,
	ACT_DOTA_IDLE_IMPATIENT_SWORD_TAP = 1648,
	ACT_DOTA_INTRO_LOOP = 1649,
	ACT_DOTA_BRIDGE_THREAT = 1650,
	ACT_DOTA_DAGON = 1651,
	ACT_DOTA_CAST_ABILITY_2_ES_ROLL_START = 1652,
	ACT_DOTA_CAST_ABILITY_2_ES_ROLL = 1653,
	ACT_DOTA_CAST_ABILITY_2_ES_ROLL_END = 1654,
	ACT_DOTA_NIAN_PIN_START = 1655,
	ACT_DOTA_NIAN_PIN_LOOP = 1656,
	ACT_DOTA_NIAN_PIN_END = 1657,
	ACT_DOTA_LEAP_STUN = 1658,
	ACT_DOTA_LEAP_SWIPE = 1659,
	ACT_DOTA_NIAN_INTRO_LEAP = 1660,
	ACT_DOTA_AREA_DENY = 1661,
	ACT_DOTA_NIAN_PIN_TO_STUN = 1662,
	ACT_DOTA_RAZE_1 = 1663,
	ACT_DOTA_RAZE_2 = 1664,
	ACT_DOTA_RAZE_3 = 1665,
	ACT_DOTA_UNDYING_DECAY = 1666,
	ACT_DOTA_UNDYING_SOUL_RIP = 1667,
	ACT_DOTA_UNDYING_TOMBSTONE = 1668,
	ACT_DOTA_WHIRLING_AXES_RANGED = 1669,
	ACT_DOTA_SHALLOW_GRAVE = 1670,
	ACT_DOTA_COLD_FEET = 1671,
	ACT_DOTA_ICE_VORTEX = 1672,
	ACT_DOTA_CHILLING_TOUCH = 1673,
	ACT_DOTA_ENFEEBLE = 1674,
	ACT_DOTA_FATAL_BONDS = 1675,
	ACT_DOTA_MIDNIGHT_PULSE = 1676,
	ACT_DOTA_ANCESTRAL_SPIRIT = 1677,
	ACT_DOTA_THUNDER_STRIKE = 1678,
	ACT_DOTA_KINETIC_FIELD = 1679,
	ACT_DOTA_STATIC_STORM = 1680,
	ACT_DOTA_MINI_TAUNT = 1681,
	ACT_DOTA_ARCTIC_BURN_END = 1682,
	ACT_DOTA_LOADOUT_RARE = 1683,
	ACT_DOTA_SWIM = 1684,
	ACT_DOTA_FLEE = 1685,
	ACT_DOTA_TROT = 1686,
	ACT_DOTA_SHAKE = 1687,
	ACT_DOTA_SWIM_IDLE = 1688,
	ACT_DOTA_WAIT_IDLE = 1689,
	ACT_DOTA_GREET = 1690,
	ACT_DOTA_TELEPORT_COOP_START = 1691,
	ACT_DOTA_TELEPORT_COOP_WAIT = 1692,
	ACT_DOTA_TELEPORT_COOP_END = 1693,
	ACT_DOTA_TELEPORT_COOP_EXIT = 1694,
	ACT_DOTA_SHOPKEEPER_PET_INTERACT = 1695,
	ACT_DOTA_ITEM_PICKUP = 1696,
	ACT_DOTA_ITEM_DROP = 1697,
	ACT_DOTA_CAPTURE_PET = 1698,
	ACT_DOTA_PET_WARD_OBSERVER = 1699,
	ACT_DOTA_PET_WARD_SENTRY = 1700,
	ACT_DOTA_PET_LEVEL = 1701,
	ACT_DOTA_CAST_BURROW_END = 1702,
	ACT_DOTA_LIFESTEALER_ASSIMILATE = 1703,
	ACT_DOTA_LIFESTEALER_EJECT = 1704,
	ACT_DOTA_ATTACK_EVENT_BASH = 1705,
	ACT_DOTA_CAPTURE_RARE = 1706,
	ACT_DOTA_AW_MAGNETIC_FIELD = 1707,
	ACT_DOTA_CAST_GHOST_SHIP = 1708,
}

TraceContents_t =
{
	CONTENTS_EMPTY = 0x00000000,
	CONTENTS_SOLID = 0x00000001,
	CONTENTS_WINDOW = 0x00000002,
	CONTENTS_AUX = 0x00000004,
	CONTENTS_GRATE = 0x00000008,
	CONTENTS_SLIME = 0x00000010,
	CONTENTS_WATER = 0x000000020,
	CONTENTS_BLOCKLOS = 0x00000040,
	CONTENTS_OPAQUE = 0x00000080,
	CONTENTS_TESTFOGVOLUME = 0x00000100,
	CONTENTS_TEAM4 = 0x00000200,
	CONTENTS_TEAM3 = 0x00000400,
	CONTENTS_TEAM1 = 0x00000800,
	CONTENTS_TEAM2 = 0x00001000,
	CONTENTS_IGNORE_NODRAW_OPAQUE = 0x00002000,
	CONTENTS_MOVEABLE = 0x00004000,
	CONTENTS_AREAPORTAL = 0x00008000,
	CONTENTS_PLAYERCLIP = 0x00010000,
	CONTENTS_MONSTERCLIP = 0x00020000,
	CONTENTS_CURRENT_0 = 0x00040000,
	CONTENTS_CURRENT_90 = 0x00080000,
	CONTENTS_CURRENT_180 = 0x00100000,
	CONTENTS_CURRENT_270 = 0x00200000,
	CONTENTS_CURRENT_UP = 0x00400000,
	CONTENTS_CURRENT_DOWN = 0x00800000,
	CONTENTS_ORIGIN = 0x01000000,
	CONTENTS_MONSTER = 0x02000000,
	CONTENTS_DEBRIS = 0x04000000,
	CONTENTS_DETAIL = 0x08000000,
	CONTENTS_TRANSLUCENT = 0x10000000,
	CONTENTS_LADDER = 0x20000000,
	CONTENTS_HITBOX = 0x40000000,
}

TraceMasks_t =
{
	MASK_SPLITAREAPORTAL = 0x00000030,
	MASK_SOLID_BRUSHONLY = 0x0000400B,
	MASK_WATER = 0x00004030,
	MASK_BLOCKLOS = 0x00004041,
	MASK_OPAQUE = 0x00004081,
	MASK_VISIBLE = 0x00006081,
	MASK_DEADSOLID = 0x0001000b,
	MASK_PLAYERSOLID_BRUSHONLY = 0x0001400b,
	MASK_NPCWORLDSTATIC = 0x0002000b,
	MASK_NPCSOLID_BRUSHONLY = 0x0002400b,
	MASK_CURRENT = 0x00fc0000,
	MASK_SHOT_PORTAL = 0x02004003,
	MASK_SOLID = 0x0200400B,
	MASK_BLOCKLOS_AND_NPCS = 0x02004041,
	MASK_OPAQUE_AND_NPCS = 0x02004081,
	MASK_VISIBLE_AND_NPCS = 0x02006081,
	MASK_PLAYERSOLID = 0x0201400B,
	MASK_NPCSOLID = 0x0202400B,
	MASK_SHOT_HULL = 0x0600400B,
	MASK_SHOT = 0x46004003,
	MASK_ALL = 0xffffffff,
}

stExtModifierEventValues =
{
	IW_MODIFIER_EVENT_ON_CAST_FILTER = 1,
	IW_MODIFIER_EVENT_ON_CAST_ERROR = 2,
	IW_MODIFIER_EVENT_ON_PRE_DEAL_DAMAGE = 3,
	IW_MODIFIER_EVENT_ON_PRE_TAKE_DAMAGE = 4,
	IW_MODIFIER_EVENT_ON_POST_DEAL_DAMAGE = 5,
	IW_MODIFIER_EVENT_ON_POST_TAKE_DAMAGE = 6,
	IW_MODIFIER_EVENT_ON_PRE_ATTACK_DAMAGE = 7,
	IW_MODIFIER_EVENT_ON_POST_ATTACK_DAMAGE = 8,
	IW_MODIFIER_EVENT_ON_TAKE_ATTACK_DAMAGE = 9,
	IW_MODIFIER_EVENT_ON_DODGE_ATTACK_DAMAGE = 10,
	IW_MODIFIER_EVENT_ON_ATTACK_EVENT_START = 11,
	IW_MODIFIER_EVENT_ON_PRE_ATTACK_EVENT = 12,
}

for k,v in pairs(stExtModifierEventValues) do _G[k] = v end

stExtModifierEventAliases =
{
	[IW_MODIFIER_EVENT_ON_CAST_FILTER] = "OnCastFilterResult",
	[IW_MODIFIER_EVENT_ON_CAST_ERROR] = "OnGetCustomCastError",
	[IW_MODIFIER_EVENT_ON_PRE_DEAL_DAMAGE] = "OnPreDealPrimaryDamage",
	[IW_MODIFIER_EVENT_ON_PRE_TAKE_DAMAGE] = "OnPreTakePrimaryDamage",
	[IW_MODIFIER_EVENT_ON_POST_DEAL_DAMAGE] = "OnPostDealPrimaryDamage",
	[IW_MODIFIER_EVENT_ON_POST_TAKE_DAMAGE] = "OnPostTakePrimaryDamage",
	[IW_MODIFIER_EVENT_ON_PRE_ATTACK_DAMAGE] = "OnPreAttackDamage",
	[IW_MODIFIER_EVENT_ON_POST_ATTACK_DAMAGE] = "OnPostAttackDamage",
	[IW_MODIFIER_EVENT_ON_TAKE_ATTACK_DAMAGE] = "OnTakeAttackDamage",
	[IW_MODIFIER_EVENT_ON_DODGE_ATTACK_DAMAGE] = "OnDodgeAttackDamage",
	[IW_MODIFIER_EVENT_ON_ATTACK_EVENT_START] = "OnAttackEventStart",
	[IW_MODIFIER_EVENT_ON_PRE_ATTACK_EVENT] = "OnPreAttackEvent",
}

for k,v in pairs(TraceContents_t) do _G[k] = v end
for k,v in pairs(TraceMasks_t) do _G[k] = v end