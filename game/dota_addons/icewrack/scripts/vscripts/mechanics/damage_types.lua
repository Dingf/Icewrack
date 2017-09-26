--[[
    Icewrack Damage Types
    
    PURE:
        *Cannot be resisted or blocked (but is affected by incoming/outgoing damage modifiers)
        *Used by holy/arcane spells (think SWM Arcane Bolt, Chen's Test of Faith, etc.)
        *This is the default damage type if none is specified
		
    PHYSICAL:
        *Armor is treated as physical damage block (not percent resistance)
		*Status effect depends on the Physical sub-type used (see below)
	
		CRUSH:
			*Physical damage sub-type
			*Critical strikes apply Bash, which stuns the target for up to 5 seconds, based on the percentage of max. HP dealt as damage
			*Bash shatters Frozen and Petrified enemies when applied
			
		SLASH:
			*Physical damage sub-type
			*Critical strikes apply Maim, which slows the target's movement speed for up to 10 seconds, based on the percentage of max.
			HP dealt as damage. Moving while Maimed causes the target to suffer additional secondary Slash damage.
			 
		PIERCE:
			*Physical damage sub-type
			*Critical strikes apply Bleed, dealing 100% of the original damage dealt as secondary Pierce damage over 4 seconds.
 
    FIRE:
		*High damage, medium variance
        *Critical strikes apply Burning, dealing 5/2/1% of target's maximum HP as secondary Fire damage per second for up to 5 seconds, based on
		 the percentage of max. HP dealt as damage. Only one instance of Burning can be applied to the target at a time.
		*Indiscriminate area damage and burning ground effects - lots of friendly fire possible
        
    COLD:
		*Low to medium damage, little to no variance
        *Critical strikes apply Chill, which slows the target's move speed, attack speed, and turn rate for up to 10 seconds, based on the percentage
		 of max. HP dealt as damage.
		*If a Chilled target is Wet, the target is dispelled of Wet and is Frozen instead
		*Disabling area abilities and strong single target damage/effects
        
    LIGHTNING:
		*High damage, high variance
		*Critical strikes apply Shock, dealing 25/10/5% of the target's current HP as secondary Lightning damage
        *Intelligent damage - Lightning damage chains or autotargets, preventing friendly fire
    
    DEATH:
		*Medium damage, as well as damage over time
        *Critical strikes apply Decay, temporarily reducing maximum health and causing all healing effects to deal secondary Death damage instead.
		*Poison abilities deal secondary Death damage
]]

IW_DAMAGE_TYPE_PHYSICAL = 1

stIcewrackDamageTypeEnum =
{
	IW_DAMAGE_TYPE_PURE = 0,
	IW_DAMAGE_TYPE_CRUSH = 1,
	IW_DAMAGE_TYPE_SLASH = 2,
	IW_DAMAGE_TYPE_PIERCE = 3,
	IW_DAMAGE_TYPE_FIRE = 4,
	IW_DAMAGE_TYPE_COLD = 5,
	IW_DAMAGE_TYPE_LIGHTNING = 6,
	IW_DAMAGE_TYPE_DEATH = 7,
}
	
stIcewrackDamageEffectEnum = 
{
	IW_DAMAGE_EFFECT_BASH = 1,
	IW_DAMAGE_EFFECT_MAIM = 2,
	IW_DAMAGE_EFFECT_BLEED = 3,
	IW_DAMAGE_EFFECT_BURN = 4,
	IW_DAMAGE_EFFECT_CHILL = 5,
	IW_DAMAGE_EFFECT_SHOCK = 6,
	IW_DAMAGE_EFFECT_DECAY = 7,
}

for k,v in pairs(stIcewrackDamageTypeEnum) do _G[k] = v end
for k,v in pairs(stIcewrackDamageEffectEnum) do _G[k] = v end
stIcewrackDamageTypeValues =
{
	[IW_DAMAGE_TYPE_PURE] = true,
	[IW_DAMAGE_TYPE_CRUSH] = true,
	[IW_DAMAGE_TYPE_SLASH] = true,
	[IW_DAMAGE_TYPE_PIERCE] = true,
	[IW_DAMAGE_TYPE_FIRE] = true,
	[IW_DAMAGE_TYPE_COLD] = true,
	[IW_DAMAGE_TYPE_LIGHTNING] = true,
	[IW_DAMAGE_TYPE_DEATH] = true,
}

stIcewrackDamageEffectValues =
{
	[IW_DAMAGE_EFFECT_BASH] = true,
	[IW_DAMAGE_EFFECT_MAIM] = true,
	[IW_DAMAGE_EFFECT_BLEED] = true,
	[IW_DAMAGE_EFFECT_BURN] = true,
	[IW_DAMAGE_EFFECT_CHILL] = true,
	[IW_DAMAGE_EFFECT_SHOCK] = true,
	[IW_DAMAGE_EFFECT_DECAY] = true,
}