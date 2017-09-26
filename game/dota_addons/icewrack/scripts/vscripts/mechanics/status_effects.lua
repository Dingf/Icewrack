--[[
    Icewrack Status Effects
	
	The descriptions below are only a rough idea of what the status effects do. Some modifiers may apply other effects in
	addition to those listed here when applying status effects.
	
	STUN
	    *Prevents all actions from the affected unit, including movement, attacking, and casting spells. Stunned units have a
		 dodge score of 0.
	
	SLOW
	    *Reduces at least one of the following: movement speed, attack speed, and/or cast speed
		
	SILENCE
	    *Prevents the affected unit from casting spells
		
	ROOT
	    *Prevents the affected unit from moving or dodging.
		
	DISARM
	    *Prevents the affected unit from attacking
		
	MAIM
		*Affected unit is slowed and deals additional secondary Slash damage over time while moving.
		
	PACIFY
	    *Prevents the affected unit from attacking or casting spells
		
	DECAY
	    *Affected unit has reduced maximum health and cannot regain health. All healing received is dealt as secondary Death damage instead.
		 
	DISEASE
		*Affected unit has reduced attributes (different diseases may reduce different attributes). 
		 
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
		 damage that is a critical strike and deals more than 10% of its max. HP, it will shatter. Frozen units have a dodge
		 score of 0.
		
	CHILL
	    *Reduces at least one of the following: movement speed, attack speed, and/or cast speed.
		
	WET
	    *Reduces Cold and Lightning resistance, but increases Fire resistance. Immune to burning, but also causes the next
		 Chill effect received to Freeze instead (this consumes the Wet effect). Dispels Burning and Warm when applied.
		 
	WARM
		*Increases Cold resistance, stamina regeneration, and mana regeneration. The next instance of Chilled or Frozen has no
		 effect (this consumes the Warm effect). Dispels Frozen, Wet, and Chilled when applied.
		
	BURNING
	    *Deals secondary Fire damage over time.
		
	POISON
	    *Deals secondary Death damage over time.
		
	BLEED
	    *Deals secondary Physical damage over time.
		
	BLIND
	    *Reduces line of sight to 0. Greatly reduced accuracy rating. Immune to abilities which require vision.
		
	DEAF
		*Affected unit cannot detect sounds and has greatly reduced dodge rating. Immune to abilities which require sound.
		
	PETRIFY
	    *Prevents all actions from the affected unit, but reduces non-Physical damage taken. If the unit receives Physical
		 damage that is a critical strike and deals more than 10% of its max. HP, it will shatter. Petrified units have a
		 dodge score of 0.
]]
stIcewrackStatusEffectEnum =
{
	IW_STATUS_EFFECT_NONE = 0,
	IW_STATUS_EFFECT_STUN = 1,
	IW_STATUS_EFFECT_SLOW = 2,
	IW_STATUS_EFFECT_SILENCE = 3,
	IW_STATUS_EFFECT_ROOT = 4,
	IW_STATUS_EFFECT_DISARM = 5,
	IW_STATUS_EFFECT_MAIM = 6,
	IW_STATUS_EFFECT_PACIFY = 7,
	IW_STATUS_EFFECT_DECAY = 8,
	IW_STATUS_EFFECT_DISEASE = 9,
	IW_STATUS_EFFECT_SLEEP = 10,
	IW_STATUS_EFFECT_FEAR = 11,
	IW_STATUS_EFFECT_CHARM = 12,
	IW_STATUS_EFFECT_ENRAGE = 13,
	IW_STATUS_EFFECT_EXHAUSTION = 14,
	IW_STATUS_EFFECT_FREEZE = 15,
	IW_STATUS_EFFECT_CHILL = 16,
	IW_STATUS_EFFECT_WET = 17,
	IW_STATUS_EFFECT_WARM = 18,
	IW_STATUS_EFFECT_BURNING = 19,
	IW_STATUS_EFFECT_POISON = 20,
	IW_STATUS_EFFECT_BLEED = 21,
	IW_STATUS_EFFECT_BLIND = 22,
	IW_STATUS_EFFECT_DEAF = 23,
	IW_STATUS_EFFECT_PETRIFY = 24,
	IW_STATUS_EFFECT_ANY = 25,
}

stIcewrackStatusMaskEnum =
{
	IW_STATUS_MASK_STUN = 1,
	IW_STATUS_MASK_SLOW = 2,
	IW_STATUS_MASK_SILENCE = 4,
	IW_STATUS_MASK_ROOT = 8,
	IW_STATUS_MASK_DISARM = 16,
	IW_STATUS_MASK_MAIM = 32,
	IW_STATUS_MASK_PACIFY = 64,
	IW_STATUS_MASK_DECAY = 128,
	IW_STATUS_MASK_DISEASE = 256,
	IW_STATUS_MASK_SLEEP = 512,
	IW_STATUS_MASK_FEAR = 1024,
	IW_STATUS_MASK_CHARM = 2048,
	IW_STATUS_MASK_ENRAGE = 4096,
	IW_STATUS_MASK_EXHAUSTION = 8192,
	IW_STATUS_MASK_FREEZE = 16384,
	IW_STATUS_MASK_CHILL = 32768,
	IW_STATUS_MASK_WET = 65536,
	IW_STATUS_MASK_WARM = 131072,
	IW_STATUS_MASK_BURNING = 262144,
	IW_STATUS_MASK_POISON = 524288,
	IW_STATUS_MASK_BLEED = 1048576,
	IW_STATUS_MASK_BLIND = 2097152,
	IW_STATUS_MASK_DEAF = 4194304,
	IW_STATUS_MASK_PETRIFY = 8388608,
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
	[IW_STATUS_EFFECT_MAIM] = true,
	[IW_STATUS_EFFECT_PACIFY] = true,
	[IW_STATUS_EFFECT_DISEASE] = true,
	[IW_STATUS_EFFECT_DECAY] = true,
	[IW_STATUS_EFFECT_SLEEP] = true,
	[IW_STATUS_EFFECT_FEAR] = true,
	[IW_STATUS_EFFECT_CHARM] = true,
	[IW_STATUS_EFFECT_ENRAGE] = true,
	[IW_STATUS_EFFECT_EXHAUSTION] = true,
	[IW_STATUS_EFFECT_FREEZE] = true,
	[IW_STATUS_EFFECT_CHILL] = true,
	[IW_STATUS_EFFECT_WET] = true,
	[IW_STATUS_EFFECT_WARM] = true,
	[IW_STATUS_EFFECT_BURNING] = true,
	[IW_STATUS_EFFECT_POISON] = true,
	[IW_STATUS_EFFECT_BLEED] = true,
	[IW_STATUS_EFFECT_BLIND] = true,
	[IW_STATUS_EFFECT_DEAF] = true,
	[IW_STATUS_EFFECT_PETRIFY] = true,
}