require("ext_entity")

npc_iw_campfire_dummy = class({})

function OnCampfireDummySpawn(self)
	local hAbility = self:AddAbility("iw_campfire_dummy_buff")
	if hAbility then
		self:AddNewModifier(self, hAbility, "modifier_iw_campfire_dummy_buff", {})
	end
end

function Spawn(args)
	thisEntity.OnSpawn = OnCampfireDummySpawn
end