--[[
    Icewrack Status Effects
	
	The descriptions below are only a rough idea of what the status effects do. Some modifiers may apply other effects in
	addition to those listed here when applying status effects.
	
	STUN
	    *Prevents all actions from the affected unit, including movement, attacking, and casting spells
	
	SLOW
	    *Reduces at least one of the following: movement speed, attack speed, and/or cast speed
		
	SILENCE
	    *Prevents the affected unit from casting spells
		
	ROOT
	    *Prevents the affected unit from moving
		
	DISARM
	    *Prevents the affected unit from attacking
		
	PACIFY
	    *Prevents the affected unit from attacking or casting spells
		
	WEAKENED
	    *Increases target's incoming damage.
		 
	SLEEP
	    *Prevents all actions from the affected unit. Can be dispelled upon taking damage.
		
	FEAR
	    *Affected unit is uncontrollable and runs away from enemies.
		
	CHARM
        *Affected unit is controlled by a different controller instead
		
	ENRAGE
        *Affected unit is uncontrollable and attacks nearby units (not necessarily enemies)

	EXHAUSTION
	    *Affected unit cannot regenerate stamina and stamina costs are increased
		
	FREEZE
	    *Prevents all actions from the affected unit, but reduces Physical and Fire damage taken. If the unit receives Physical
		 damage that is a critical strike and deals more than 10% of its max. HP, it will shatter.
		
	CHILL
	    *Reduces at least one of the following: movement speed, attack speed, and/or cast speed.
		
	WET
	    *Greatly reduces Cold and Lightning resistance, but increases Fire resistance. Immune to burning, but also causes the
		 next Chill effect received to Freeze instead (this consumes the Wet debuff). Dispels Burning when applied.
		
	BURNING
	    *Deals secondary Fire damage over time.
		
	POISON
	    *Deals secondary Death damage over time.
		
	BLEED
	    *Deals secondary Physical damage over time.
		
	BLIND
	    *Reduces line of sight to 0. Greatly reduced accuracy and dodge rating.
		
	PETRIFY
	    *Prevents all actions from the affected unit, but reduces non-Physical damage taken. If the unit receives Physical
		 damage that is a critical strike and deals more than 10% of its max. HP, it will shatter.
]]
stIcewrackStatusEffectEnum =
{
	IW_STATUS_EFFECT_NONE = 0,
	IW_STATUS_EFFECT_STUN = 1,
	IW_STATUS_EFFECT_SLOW = 2,
	IW_STATUS_EFFECT_SILENCE = 3,
	IW_STATUS_EFFECT_ROOT = 4,
	IW_STATUS_EFFECT_DISARM = 5,
	IW_STATUS_EFFECT_PACIFY = 6,
	IW_STATUS_EFFECT_WEAKEN = 7,
	IW_STATUS_EFFECT_SLEEP = 8,
	IW_STATUS_EFFECT_FEAR = 9,
	IW_STATUS_EFFECT_CHARM = 10,
	IW_STATUS_EFFECT_ENRAGE = 11,
	IW_STATUS_EFFECT_EXHAUSTION = 12,
	IW_STATUS_EFFECT_FREEZE = 13,
	IW_STATUS_EFFECT_CHILL = 14,
	IW_STATUS_EFFECT_WET = 15,
	IW_STATUS_EFFECT_BURNING = 16,
	IW_STATUS_EFFECT_POISON = 17,
	IW_STATUS_EFFECT_BLEED = 18,
	IW_STATUS_EFFECT_BLIND = 19,
	IW_STATUS_EFFECT_PETRIFY = 20,
	IW_STATUS_EFFECT_ANY = 21,
}

stIcewrackStatusMaskEnum =
{
	IW_STATUS_MASK_STUN = 1,
	IW_STATUS_MASK_SLOW = 2,
	IW_STATUS_MASK_SILENCE = 4,
	IW_STATUS_MASK_ROOT = 8,
	IW_STATUS_MASK_DISARM = 16,
	IW_STATUS_MASK_PACIFY = 32,
	IW_STATUS_MASK_WEAKEN = 64,
	IW_STATUS_MASK_SLEEP = 128,
	IW_STATUS_MASK_FEAR = 256,
	IW_STATUS_MASK_CHARM = 512,
	IW_STATUS_MASK_ENRAGE = 1024,
	IW_STATUS_MASK_EXHAUSTION = 2048,
	IW_STATUS_MASK_FREEZE = 4096,
	IW_STATUS_MASK_CHILL = 8192,
	IW_STATUS_MASK_WET = 16384,
	IW_STATUS_MASK_BURNING = 32768,
	IW_STATUS_MASK_POISON = 65536,
	IW_STATUS_MASK_BLEED = 131072,
	IW_STATUS_MASK_BLIND = 262144,
	IW_STATUS_MASK_PETRIFY = 524288,
}

for k,v in pairs(stIcewrackStatusEffectEnum) do _G[k] = v end
for k,v in pairs(stIcewrackStatusMaskEnum) do _G[k] = v end
stIcewrackStatusEffectValues =
{
	[IW_STATUS_EFFECT_STUN] = true,
	[IW_STATUS_EFFECT_SLOW] = true,
	[IW_STATUS_EFFECT_SILENCE] = true,
	[IW_STATUS_EFFECT_ROOT] = true,
	[IW_STATUS_EFFECT_DISARM] = true,
	[IW_STATUS_EFFECT_PACIFY] = true,
	[IW_STATUS_EFFECT_WEAKEN] = true,
	[IW_STATUS_EFFECT_SLEEP] = true,
	[IW_STATUS_EFFECT_FEAR] = true,
	[IW_STATUS_EFFECT_CHARM] = true,
	[IW_STATUS_EFFECT_ENRAGE] = true,
	[IW_STATUS_EFFECT_EXHAUSTION] = true,
	[IW_STATUS_EFFECT_FREEZE] = true,
	[IW_STATUS_EFFECT_CHILL] = true,
	[IW_STATUS_EFFECT_WET] = true,
	[IW_STATUS_EFFECT_BURNING] = true,
	[IW_STATUS_EFFECT_POISON] = true,
	[IW_STATUS_EFFECT_BLEED] = true,
	[IW_STATUS_EFFECT_BLIND] = true,
	[IW_STATUS_EFFECT_PETRIFY] = true,
}