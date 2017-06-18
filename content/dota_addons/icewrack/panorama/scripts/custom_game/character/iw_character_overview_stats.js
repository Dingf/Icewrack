"use strict";

function GetOverviewRawValue(nProperty, tSourceData, nEntityIndex)
{
	return GetPropertyValue(tSourceData, nProperty);
}

function GetOverviewPercent(bOptional, nProperty, tSourceData, tEntityIndex)
{
	var fValue = GetPropertyValue(tSourceData, nProperty);
	if ((fValue !== 0) || (!bOptional))
	{
		return Math.max(0, 100.0 + fValue).toFixed(2) + "%";
	}
}

function GetOverviewZeroPercent(bOptional, nProperty, tSourceData, tEntityIndex)
{
	var fValue = GetPropertyValue(tSourceData, nProperty);
	if ((fValue !== 0) || (!bOptional))
	{
		return fValue.toFixed(2) + "%";
	}
}


function GetOverviewAttackSpeed(tSourceData, nEntityIndex)
{
	var fBaseAttackTime = GetBasePropertyValue(tSourceData, Instance.IW_PROPERTY_BASE_ATTACK_FLAT) * (1.0 + GetBasePropertyValue(tSourceData, Instance.IW_PROPERTY_BASE_ATTACK_PCT)/100.0);
	var fAttackSpeed = GetPropertyValue(tSourceData, Instance.IW_PROPERTY_ATK_SPEED_DUMMY);
	return Math.floor((100 + fAttackSpeed)/fBaseAttackTime)/100.0;
}

function GetOverviewAttackRange(tSourceData, nEntityIndex)
{
	return (GetBasePropertyValue(tSourceData, Instance.IW_PROPERTY_ATTACK_RANGE)/100.0).toFixed(2) + "m";
}

function GetOverviewAccuracy(tSourceData, nEntityIndex)
{
	var fBaseAccuracy = GetPropertyValue(tSourceData, Instance.IW_PROPERTY_ACCURACY_FLAT) + (GetAttributeValue(tSourceData, Instance.IW_PROPERTY_ATTR_AGI_FLAT) * 2.0);
	var fIncAccuracy = 1.0 + GetPropertyValue(tSourceData, Instance.IW_PROPERTY_ACCURACY_PCT)/100.0;
	return Math.max(0, Math.floor(fBaseAccuracy * fIncAccuracy));
}

function GetOverviewCritChance(tSourceData, nEntityIndex)
{
	var fBaseCritChance = GetBasePropertyValue(tSourceData, Instance.IW_PROPERTY_CRIT_CHANCE_FLAT);
	var fIncCritChance = 1.0 + (GetAttributeValue(tSourceData, Instance.IW_PROPERTY_ATTR_CUN_FLAT) * 0.05) + GetPropertyValue(tSourceData, Instance.IW_PROPERTY_CRIT_CHANCE_PCT)/100.0;
	if (fBaseCritChance > 0.0)
	{
		return (fBaseCritChance * fIncCritChance * 100.0).toFixed(2) + "%";
	}
}

function GetOverviewCritMultiplier(tSourceData, nEntityIndex)
{
	var fBaseCritMultiplier = GetBasePropertyValue(tSourceData, Instance.IW_PROPERTY_CRIT_MULTI_FLAT);
	var fIncCritMultiplier = (GetAttributeValue(tSourceData, Instance.IW_PROPERTY_ATTR_CUN_FLAT) * 0.05) + GetPropertyValue(tSourceData, Instance.IW_PROPERTY_CRIT_MULTI_PCT)/100.0;
	
	if (fBaseCritMultiplier > 0.0)
	{
		return (1.0 + fBaseCritMultiplier).toFixed(2) + "-" + (1.0 + (fBaseCritMultiplier * (1.0 + fIncCritMultiplier))).toFixed(2) + "x";
	}
}

function GetOverviewStatusChance(nStatusEffect, tSourceData, nEntityIndex)
{
	var fChance = GetPropertyValue(tSourceData, Instance.IW_PROPERTY_CHANCE_BASH + nStatusEffect);
	if (fChance > 0)
	{
		return Math.round(fChance) + "%";
	}
}

function GetOverviewArmorIgnore(tSourceData, nEntityIndex)
{
	var fBaseArmorIgnore = GetPropertyValue(tSourceData, Instance.IW_PROPERTY_IGNORE_ARMOR_FLAT);
	var fPercentArmorIgnore = GetPropertyValue(tSourceData, Instance.IW_PROPERTY_IGNORE_ARMOR_PCT);
	
	if ((fBaseArmorIgnore > 0) || (fPercentArmorIgnore > 0))
	{
		var szArmorIgnoreText = "";
		if (fPercentArmorIgnore != 0)
		{
			szArmorIgnoreText += Math.round(fPercentArmorIgnore * 100)/100.0 + "%"
			if (fBaseArmorIgnore > 0)
			{
				szArmorIgnoreText += " + ";
			}
		}
		if (fBaseArmorIgnore != 0)
		{
			szArmorIgnoreText += fBaseArmorIgnore;
		}
		return szArmorIgnoreText;
	}
}

function GetOverviewAttackStaminaCost(tSourceData, nEntityIndex)
{
	var fBaseAttackCost = GetBasePropertyValue(tSourceData, Instance.IW_PROPERTY_ATTACK_SP_FLAT);
	var fPercentAttackCost = GetPropertyValue(tSourceData, Instance.IW_PROPERTY_ATTACK_SP_PCT)/100.0;
	if (fBaseAttackCost > 0.0)
	{
		return Math.round(fBaseAttackCost * (1.0 + fPercentAttackCost) * 100)/100.0;
	}
}

function GetOverviewArmor(nArmorType, tSourceData, nEntityIndex)
{
	var fBaseArmor = GetPropertyValue(tSourceData, Instance.IW_PROPERTY_ARMOR_CRUSH_FLAT + nArmorType);
	var fPercentArmor = 1.0 + GetPropertyValue(tSourceData, Instance.IW_PROPERTY_ARMOR_CRUSH_PCT + nArmorType)/100.0;
	return Math.max(0, Math.floor(fBaseArmor * fPercentArmor));
}

function GetOverviewResistance(nDamageType, tSourceData, nEntityIndex)
{
	var fBaseResist = Math.floor(GetPropertyValue(tSourceData, Instance.IW_PROPERTY_RESIST_PHYS + nDamageType));
	var fMaxResist = Math.floor(GetPropertyValue(tSourceData, Instance.IW_PROPERTY_RESMAX_PHYS + nDamageType));
	if ((fBaseResist >= 100) && (fMaxResist >= 100))
	{
		return $.Localize("#iw_ui_character_overview_immune");
	}
	else
	{
		return fBaseResist + " / " + fMaxResist;
	}
}

function GetOverviewDodge(tSourceData, nEntityIndex)
{
	var fBaseDodge = GetPropertyValue(tSourceData, Instance.IW_PROPERTY_DODGE_FLAT) + (GetAttributeValue(tSourceData, Instance.IW_PROPERTY_ATTR_AGI_FLAT) * 1.0);
	var fIncDodge = 1.0 + GetPropertyValue(tSourceData, Instance.IW_PROPERTY_DODGE_PCT);
	return Math.max(0, Math.floor(fBaseDodge * fIncDodge));
}

function GetOverviewFatigueMultiplier(tSourceData, nEntityIndex)
{
	var fFatigueMultiplier = GetPropertyValue(tSourceData, Instance.IW_PROPERTY_FATIGUE_MULTI);
	return fFatigueMultiplier + " (" + Math.max(0, fFatigueMultiplier) + "%)"
}

function GetOverviewMovementSpeed(tSourceData, nEntityIndex)
{
	var fBaseMoveSpeed = GetPropertyValue(tSourceData, Instance.IW_PROPERTY_MOVE_SPEED_FLAT) + (GetAttributeValue(tSourceData, Instance.IW_PROPERTY_ATTR_AGI_FLAT) * 1.0);
	var fFatigueMultiplier = (GetPropertyValue(tSourceData, Instance.IW_PROPERTY_FATIGUE_MULTI) - GetAttributeValue(tSourceData, Instance.IW_PROPERTY_ATTR_STR_FLAT) * 1.0)/100.0;
	fBaseMoveSpeed *= (1.0 - Math.max(0, fFatigueMultiplier) + GetPropertyValue(tSourceData, Instance.IW_PROPERTY_MOVE_SPEED_PCT)/100)
	return Math.floor(fBaseMoveSpeed) + " (" + (Math.max(fBaseMoveSpeed, 100)/100.0).toFixed(2) + "m/s)";
}

function GetOverviewRunStaminaCost(tSourceData, nEntityIndex)
{
	var fBaseRunCost = GetPropertyValue(tSourceData, Instance.IW_PROPERTY_RUN_SP_FLAT);
	var fPercentRunCost = GetPropertyValue(tSourceData, Instance.IW_PROPERTY_RUN_SP_PCT)/100.0;
	if (fBaseRunCost > 0.0)
	{
		return Math.round(fBaseRunCost * (1.0 + fPercentRunCost) * 100)/100.0 + "/s";
	}
}

function GetOverviewSpellpower(tSourceData, nEntityIndex)
{
	return GetPropertyValue(tSourceData, Instance.IW_PROPERTY_SPELLPOWER) + (GetAttributeValue(tSourceData, Instance.IW_PROPERTY_ATTR_INT_FLAT) * 1.0)
}

function GetOverviewPhysicalDefense(tSourceData, nEntityIndex)
{
	var fDefense = Math.max(0, GetPropertyValue(tSourceData, Instance.IW_PROPERTY_DEFENSE_PHYS) + (GetAttributeValue(tSourceData, Instance.IW_PROPERTY_ATTR_END_FLAT) * 1.00));
	return fDefense + " (" + (10000/(100 + fDefense)).toFixed(2) + "%)";
}

function GetOverviewMagicalDefense(tSourceData, nEntityIndex)
{
	var fDefense = Math.max(0, GetPropertyValue(tSourceData, Instance.IW_PROPERTY_DEFENSE_MAGIC) + (GetAttributeValue(tSourceData, Instance.IW_PROPERTY_ATTR_WIS_FLAT) * 1.00));
	return fDefense + " (" + (10000/(100 + fDefense)).toFixed(2) + "%)";
}

function GetOverviewAvoidEffect(nEffectType, tSourceData, nEntityIndex)
{
	var fValue = GetPropertyValue(tSourceData, Instance.IW_PROPERTY_AVOID_BASH + nEffectType);
	if (fValue > 0)
	{
		return fValue.toFixed(2) + "%";
	}
}

function GetOverviewStatusDuration(nStatusEffect, tSourceData, nEntityIndex)
{
	var fValue = GetPropertyValue(tSourceData, Instance.IW_PROPERTY_STATUS_STUN + nStatusEffect);
	if (fValue !== 0)
	{
		if (fValue <= -100.0)
		{
			return $.Localize("#iw_ui_character_overview_immune");
		}
		else
		{
			return (fValue + 100).toFixed(2) + "%";
		}
	}
}

function GetOverviewHealth(tSourceData, nEntityIndex)
{
	return Entities.GetHealth(nEntityIndex) + " / " + Entities.GetMaxHealth(nEntityIndex);
}

function GetOverviewHealthRegeneration(tSourceData, nEntityIndex)
{
	var fRegenPerSec = GetPropertyValue(tSourceData, Instance.IW_PROPERTY_HP_REGEN_FLAT);
	fRegenPerSec += (GetPropertyValue(tSourceData, Instance.IW_PROPERTY_MAX_HP_REGEN) * Entities.GetMaxHealth(nEntityIndex));
	fRegenPerSec *= (1.0 + GetPropertyValue(tSourceData, Instance.IW_PROPERTY_HP_REGEN_PCT)/100.0);
	fRegenPerSec *= (1.0 + GetPropertyValue(tSourceData, Instance.IW_PROPERTY_HEAL_MULTI)/100.0);
	if (fRegenPerSec > 0)
	{
		return fRegenPerSec.toFixed(2) + "/s";
	}
}

function GetOverviewMana(tSourceData, nEntityIndex)
{
	return Entities.GetMana(nEntityIndex) + " / " + Entities.GetMaxMana(nEntityIndex);
}

function GetOverviewManaRegeneration(tSourceData, nEntityIndex)
{
	var fRegenPerSec = GetPropertyValue(tSourceData, Instance.IW_PROPERTY_MP_REGEN_FLAT) + (GetAttributeValue(tSourceData, Instance.IW_PROPERTY_ATTR_WIS_FLAT) * 0.025);
	fRegenPerSec += (GetPropertyValue(tSourceData, Instance.IW_PROPERTY_MAX_MP_REGEN) * Entities.GetMaxMana(nEntityIndex));
	fRegenPerSec *= (1.0 + GetPropertyValue(tSourceData, Instance.IW_PROPERTY_MP_REGEN_PCT)/100.0);
	if (fRegenPerSec > 0)
	{
		return fRegenPerSec.toFixed(2) + "/s";
	}
}

function GetOverviewStamina(tSourceData, nEntityIndex)
{
	var tEntityData = CustomNetTables.GetTableValue("entities", nEntityIndex);
	return tEntityData.stamina.toFixed(0) + " / " + tEntityData.stamina_max.toFixed(0);
}

function GetOverviewStaminaRegeneration(tSourceData, nEntityIndex)
{
	var fRegenPerSec = GetPropertyValue(tSourceData, Instance.IW_PROPERTY_SP_REGEN_FLAT);
	fRegenPerSec += (GetPropertyValue(tSourceData, Instance.IW_PROPERTY_MAX_SP_REGEN) * tSourceData.stamina_max);
	fRegenPerSec *= (1.0 + GetPropertyValue(tSourceData, Instance.IW_PROPERTY_SP_REGEN_PCT)/100.0);
	if (fRegenPerSec > 0)
	{
		return fRegenPerSec.toFixed(2) + "/s";
	}
}

function GetOverviewBuffDuration(nProperty, tSourceData, nEntityIndex)
{
	var fValue = GetPropertyValue(tSourceData, nProperty);
	if ((nProperty === Instance.IW_PROPERTY_BUFF_OTHER) || (nProperty === Instance.IW_PROPERTY_DEBUFF_OTHER))
	{
		fValue += (GetAttributeValue(tSourceData, Instance.IW_PROPERTY_ATTR_INT_FLAT) * 0.5);
	}
	
	if (fValue !== 0)
	{
		return (100.0 + fValue).toFixed(2) + "%";
	}
}

function GetOverviewLifesteal(tSourceData, nEntityIndex)
{
	var fLifestealValue = GetPropertyValue(tSourceData, Instance.IW_PROPERTY_LIFESTEAL_PCT);
	var fLifestealRate = GetPropertyValue(tSourceData, Instance.IW_PROPERTY_LIFESTEAL_RATE) * 100.0;
	if (fLifestealValue !== 0)
	{
		return fLifestealValue.toFixed(2) + "% / " + fLifestealRate.toFixed(2) + "%";
	}
}

var stOverviewAttackSourceLabelFunctions =
{
	"iw_ui_character_overview_attack_range"  : GetOverviewAttackRange,
	"iw_ui_character_overview_accuracy"      : GetOverviewAccuracy,
	"iw_ui_character_overview_crit_chance"   : GetOverviewCritChance,
	"iw_ui_character_overview_crit_multi"    : GetOverviewCritMultiplier,
	"iw_ui_character_overview_chance_bash"   : GetOverviewStatusChance.bind(this, 0),
	"iw_ui_character_overview_chance_maim"   : GetOverviewStatusChance.bind(this, 1),
	"iw_ui_character_overview_chance_bleed"  : GetOverviewStatusChance.bind(this, 2),
	"iw_ui_character_overview_chance_burn"   : GetOverviewStatusChance.bind(this, 3),
	"iw_ui_character_overview_chance_chill"  : GetOverviewStatusChance.bind(this, 4),
	"iw_ui_character_overview_chance_shock"  : GetOverviewStatusChance.bind(this, 5),
	"iw_ui_character_overview_chance_weaken" : GetOverviewStatusChance.bind(this, 6),
	"iw_ui_character_overview_armor_ignore"  : GetOverviewArmorIgnore,
	"iw_ui_character_overview_attack_cost"   : GetOverviewAttackStaminaCost
};

var stOverviewDefenseLabelFunctions =
{
	"iw_ui_character_overview_dodge"          : GetOverviewDodge,
	"iw_ui_character_overview_crush_armor"    : GetOverviewArmor.bind(this, 0),
	"iw_ui_character_overview_slash_armor"    : GetOverviewArmor.bind(this, 1),
	"iw_ui_character_overview_pierce_armor"   : GetOverviewArmor.bind(this, 2),
	"iw_ui_character_overview_res_phys"       : GetOverviewResistance.bind(this, 0),
	"iw_ui_character_overview_res_fire"       : GetOverviewResistance.bind(this, 1),
	"iw_ui_character_overview_res_cold"       : GetOverviewResistance.bind(this, 2),
	"iw_ui_character_overview_res_light"      : GetOverviewResistance.bind(this, 3),
	"iw_ui_character_overview_res_death"      : GetOverviewResistance.bind(this, 4),
	"iw_ui_character_overview_heal_multi"     : GetOverviewPercent.bind(this, true, Instance.IW_PROPERTY_HEAL_MULTI),
	"iw_ui_character_overview_damage_multi"   : GetOverviewPercent.bind(this, true, Instance.IW_PROPERTY_DAMAGE_MULTI),
	"iw_ui_character_overview_defense_phys"   : GetOverviewPhysicalDefense,
	"iw_ui_character_overview_defense_magic"  : GetOverviewMagicalDefense,
	"iw_ui_character_overview_avoid_bash"     : GetOverviewAvoidEffect.bind(this, 0),
	"iw_ui_character_overview_avoid_maim"     : GetOverviewAvoidEffect.bind(this, 1),
	"iw_ui_character_overview_avoid_bleed"    : GetOverviewAvoidEffect.bind(this, 2),
	"iw_ui_character_overview_avoid_burn"     : GetOverviewAvoidEffect.bind(this, 3),
	"iw_ui_character_overview_avoid_chill"    : GetOverviewAvoidEffect.bind(this, 4),
	"iw_ui_character_overview_avoid_shock"    : GetOverviewAvoidEffect.bind(this, 5),
	"iw_ui_character_overview_avoid_weaken"   : GetOverviewAvoidEffect.bind(this, 6),
	"iw_ui_character_overview_avoid_crit"     : GetOverviewAvoidEffect.bind(this, 7),
	"iw_ui_character_overview_status_stun"    : GetOverviewStatusDuration.bind(this, 0),
	"iw_ui_character_overview_status_slow"    : GetOverviewStatusDuration.bind(this, 1),
	"iw_ui_character_overview_status_silence" : GetOverviewStatusDuration.bind(this, 2),
	"iw_ui_character_overview_status_root"    : GetOverviewStatusDuration.bind(this, 3),
	"iw_ui_character_overview_status_disarm"  : GetOverviewStatusDuration.bind(this, 4),
	"iw_ui_character_overview_status_pacify"  : GetOverviewStatusDuration.bind(this, 5),
	"iw_ui_character_overview_status_weaken"  : GetOverviewStatusDuration.bind(this, 6),
	"iw_ui_character_overview_status_sleep"   : GetOverviewStatusDuration.bind(this, 7),
	"iw_ui_character_overview_status_fear"    : GetOverviewStatusDuration.bind(this, 8),
	"iw_ui_character_overview_status_charm"   : GetOverviewStatusDuration.bind(this, 9),
	"iw_ui_character_overview_status_enrage"  : GetOverviewStatusDuration.bind(this, 10),
	"iw_ui_character_overview_status_exhaust" : GetOverviewStatusDuration.bind(this, 11),
	"iw_ui_character_overview_status_freeze"  : GetOverviewStatusDuration.bind(this, 12),
	"iw_ui_character_overview_status_chill"   : GetOverviewStatusDuration.bind(this, 13),
	"iw_ui_character_overview_status_wet"     : GetOverviewStatusDuration.bind(this, 14),
	"iw_ui_character_overview_status_burn"    : GetOverviewStatusDuration.bind(this, 15),
	"iw_ui_character_overview_status_poison"  : GetOverviewStatusDuration.bind(this, 16),
	"iw_ui_character_overview_status_bleed"   : GetOverviewStatusDuration.bind(this, 17),
	"iw_ui_character_overview_status_blind"   : GetOverviewStatusDuration.bind(this, 18),
	"iw_ui_character_overview_status_petrify" : GetOverviewStatusDuration.bind(this, 19)
};

var stOverviewMiscLabelFunctions =
{
	"iw_ui_character_overview_hp"            : GetOverviewHealth,
	"iw_ui_character_overview_hp_regen"      : GetOverviewHealthRegeneration,
	"iw_ui_character_overview_mp"            : GetOverviewMana,
	"iw_ui_character_overview_mp_regen"      : GetOverviewManaRegeneration,
	"iw_ui_character_overview_sp"            : GetOverviewStamina,
	"iw_ui_character_overview_sp_regen"      : GetOverviewStaminaRegeneration,
	"iw_ui_character_overview_fatigue_multi" : GetOverviewFatigueMultiplier,
	"iw_ui_character_overview_move_speed"    : GetOverviewMovementSpeed,
	"iw_ui_character_overview_run_cost"      : GetOverviewRunStaminaCost,
	"iw_ui_character_overview_spellpower"    : GetOverviewSpellpower,
	"iw_ui_character_overview_cast_speed"    : GetOverviewZeroPercent.bind(this, false, Instance.IW_PROPERTY_CAST_SPEED),
	"iw_ui_character_overview_buff_self"     : GetOverviewBuffDuration.bind(this, Instance.IW_PROPERTY_BUFF_SELF),
	"iw_ui_character_overview_debuff_self"   : GetOverviewBuffDuration.bind(this, Instance.IW_PROPERTY_DEBUFF_SELF),
	"iw_ui_character_overview_buff_other"    : GetOverviewBuffDuration.bind(this, Instance.IW_PROPERTY_BUFF_OTHER),
	"iw_ui_character_overview_debuff_other"  : GetOverviewBuffDuration.bind(this, Instance.IW_PROPERTY_DEBUFF_OTHER),
	"iw_ui_character_overview_lifesteal"     : GetOverviewLifesteal,
	"iw_ui_character_overview_manashield"    : GetOverviewZeroPercent.bind(this, true, Instance.IW_PROPERTY_MANASHIELD_PCT),
	"iw_ui_character_overview_secondwind"    : GetOverviewZeroPercent.bind(this, true, Instance.IW_PROPERTY_SECONDWIND_PCT)
};
