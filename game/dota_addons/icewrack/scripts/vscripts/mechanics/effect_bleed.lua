function ApplyBleed(hVictim, hAttacker, fDamage)
	AddModifier("status_bleed", "modifier_status_bleed", hVictim, hAttacker, { bleed_damage=fDamage/4.0 })
end