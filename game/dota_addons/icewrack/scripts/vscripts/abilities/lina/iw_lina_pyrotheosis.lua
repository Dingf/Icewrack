iw_lina_pyrotheosis = class({})

local stPyrotheosisResponseLines =
{
	"lina_lina_spawn_05",
	"lina_lina_respawn_04",
	"lina_lina_level_01",
	"lina_lina_level_04",
	"lina_lina_level_05",
}

function iw_lina_pyrotheosis:OnSpellStart()
	local hEntity = self:GetCaster()
	local tModifierArgs =
	{
		fire_damage = self:GetSpecialValueFor("fire_damage"),
		base_attack_time = self:GetSpecialValueFor("base_attack_time"),
		duration = self:GetSpecialValueFor("duration"),
	}
	hEntity:AddNewModifier(hEntity, self, "modifier_iw_lina_pyrotheosis", tModifierArgs)
	EmitSoundOn("Hero_Lina.Pyrotheosis", hEntity)
	EmitSoundOn("Hero_Lina.Pyrotheosis.Loop", hEntity)
	
	local szResponse = stPyrotheosisResponseLines[RandomInt(1, #stPyrotheosisResponseLines)]
	EmitSoundOn(szResponse, hEntity)
end