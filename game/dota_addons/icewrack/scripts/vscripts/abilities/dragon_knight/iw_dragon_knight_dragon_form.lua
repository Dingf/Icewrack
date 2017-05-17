iw_dragon_knight_dragon_form = class({})

local stDragonFormResponseLines =
{
	"dragon_knight_drag_cast_01",
	"dragon_knight_drag_cast_02",
	"dragon_knight_drag_ability_eldrag_03",
	"dragon_knight_drag_ability_eldrag_04",
}

function iw_dragon_knight_dragon_form:OnAbilityPhaseStart()
	local hEntity = self:GetCaster()
	EmitSoundOn("Hero_DragonKnight.DragonForm.PreCast", hEntity)
	CTimer(0.5, function()
		if hEntity:GetCurrentActiveAbility() == self then
			self._szResponse = stDragonFormResponseLines[RandomInt(1, #stDragonFormResponseLines)]
			EmitSoundOn(self._szResponse, hEntity)
		end
	end)
	return true
end

function iw_dragon_knight_dragon_form:OnAbilityPhaseInterrupted()
	local hEntity = self:GetCaster()
	StopSoundOn("Hero_DragonKnight.DragonForm.PreCast", hEntity)
	if self._szResponse then
		StopSoundOn(self._szResponse, hEntity)
		self._szResponse = nil
	end
end

function iw_dragon_knight_dragon_form:OnSpellStart()
	local hEntity = self:GetCaster()
	
	if not self._hAttackSource then
		self._hAttackSource = CExtItem(CreateItem("iw_dragon_knight_dragon_form_source", nil, nil))
	end
	
	local tModifierArgs =
	{
		health_bonus = self:GetSpecialValueFor("health_bonus"),
		stamina_bonus = self:GetSpecialValueFor("stamina_bonus"),
		speed_bonus = self:GetSpecialValueFor("speed_bonus"),
		duration = self:GetSpecialValueFor("duration"),
		modelname = hEntity:GetModelName(),
	}
	
	StopSoundOn("Hero_DragonKnight.DragonForm.PreCast", hEntity)
	if self._szResponse then
		StopSoundOn(self._szResponse, hEntity)
		self._szResponse = nil
	end
	
	local nParticleID = ParticleManager:CreateParticle("particles/units/heroes/hero_dragon_knight/dragon_knight_transform_green.vpcf", PATTACH_WORLDORIGIN, self)
	ParticleManager:SetParticleControl(nParticleID, 0, hEntity:GetAbsOrigin())
	ParticleManager:ReleaseParticleIndex(nParticleID)
	
	EmitSoundOn("Hero_DragonKnight.ElderDragonForm", hEntity)
	hEntity:AddNewModifier(hEntity, self, "modifier_iw_dragon_knight_dragon_form", tModifierArgs)
end