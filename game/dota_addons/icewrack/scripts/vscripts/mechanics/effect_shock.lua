require("mechanics/damage_types")
require("mechanics/damage_secondary")

if not stShockDamageTable then
	stShockDamageTable = 
	{
		damage = {},
	}
end

function ApplyShock(hVictim, hAttacker)
	stShockDamageTable.target = hVictim
	stShockDamageTable.attacker = hAttacker
	local nUnitClass = hVictim:GetUnitClass()
	local fShockMultiplier = 0.25
	if nUnitClass == IW_UNIT_CLASS_ELITE then
		fShockMultiplier = 0.10
	elseif nUnitClass == IW_UNIT_CLASS_BOSS or nUnitClass == IW_UNIT_CLASS_ACT_BOSS then
		fShockMultiplier = 0.05
	end
	
	stShockDamageTable.damage[IW_DAMAGE_TYPE_LIGHTNING] =
	{
		min = hVictim:GetHealth() * fShockMultiplier,
		max = hVictim:GetHealth() * fShockMultiplier
	}
	DealSecondaryDamage(nil, stShockDamageTable)
	local nParticleIndex = ParticleManager:CreateParticle("particles/generic_gameplay/generic_hit_lightning.vpcf", PATTACH_ABSORIGIN_FOLLOW, hVictim)
	ParticleManager:ReleaseParticleIndex(nParticleIndex)
	EmitSoundOn("Icewrack.Shock", hVictim)
end