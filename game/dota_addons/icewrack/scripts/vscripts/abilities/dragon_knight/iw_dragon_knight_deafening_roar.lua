iw_dragon_knight_deafening_roar = class({})

function iw_dragon_knight_deafening_roar:OnAbilityPhaseStart()
	local hEntity = self:GetCaster()
	CTimer(0.03, EmitSoundOn, "Hero_DragonKnight.DeafeningRoar", hEntity)
	return true
end

function iw_dragon_knight_deafening_roar:OnAbilityPhaseInterrupted()
	local hEntity = self:GetCaster()
	StopSoundOn("Hero_DragonKnight.DeafeningRoar", hEntity)
end

function iw_dragon_knight_deafening_roar:OnSpellStart()
	local hEntity = self:GetCaster()
	local fRadius = self:GetAOERadius()
			
	local tModifierArgs =
	{
		duration = self:GetSpecialValueFor("duration"),
		move_speed = self:GetSpecialValueFor("move_speed"),
		attack_speed = self:GetSpecialValueFor("attack_speed"),
	}
	
	local hNearbyEntities = FindUnitsInRadius(hEntity:GetTeamNumber(), hEntity:GetAbsOrigin(), nil, self:GetAOERadius(), DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, 0, 0, false)
	for k,v in pairs(hNearbyEntities) do
		if v ~= hEntity then
			v:Interrupt()
			v:AddNewModifier(hEntity, self, "modifier_iw_dragon_knight_deafening_roar", tModifierArgs)
		end
	end
	
	local nParticleID = ParticleManager:CreateParticle("particles/units/heroes/hero_dragon_knight/dragon_knight_deafening_roar.vpcf", PATTACH_POINT, hEntity)
	ParticleManager:SetParticleControl(nParticleID, 1, hEntity:GetAbsOrigin())
	ParticleManager:ReleaseParticleIndex(nParticleID)
end