function ApplyBleed(hTarget, hEntity, fDamage)
	local tModifierArgs =
	{
		bleed_damage = fDamage/8.0,
		duration = 4.0,
	}
	AddModifier("status_bleed", "modifier_status_bleed", hTarget, hEntity, tModifierArgs)
end