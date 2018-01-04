function Spawn(args)
	local hAbility = thisEntity:AddAbility("iw_campfire_dummy_buff")
	if hAbility then
		thisEntity:AddNewModifier(thisEntity, hAbility, "modifier_iw_campfire_dummy_buff", {})
	end
end