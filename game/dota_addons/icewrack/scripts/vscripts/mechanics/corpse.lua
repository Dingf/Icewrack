local function OnCorpseLootableInteract(hEntity, args)
	if args.lootable == hEntity:entindex() then
		if hEntity:IsInventoryEmpty() then
			hEntity:AddNewModifier(hEntity, hEntity._hCorpseItem, "modifier_internal_corpse_unselectable", {})
			CustomGameEventManager:UnregisterListener(hEntity._nCorpseListener)
		end
	end
end

function CreateCorpse(hEntity)
	local hCorpseItem = CreateItem("item_internal_corpse", nil, nil)
	hEntity._hCorpseItem = hCorpseItem
	
	hEntity:AddNewModifier(hEntity, hCorpseItem, "modifier_internal_corpse_temp_phase", {})
	hEntity:RespawnUnit()
	hEntity:AddNewModifier(hEntity, hCorpseItem, "modifier_internal_corpse_state", {})
	
	if bit32.btest(hEntity:GetUnitSubtype(), IW_UNIT_SUBTYPE_BIOLOGICAL) then
		local nParticleID = ParticleManager:CreateParticle("particles/generic_gameplay/death_bloodpool.vpcf", PATTACH_ABSORIGIN_FOLLOW, hEntity)
		ParticleManager:ReleaseParticleIndex(nParticleID)
	end
	
	--This is a dumb hack but Valve hasn't exposed a method for making targets unattackable with attack-move
	AddModifier("elder_titan_echo_stomp", "modifier_elder_titan_echo_stomp", hEntity, hEntity, { duration=99999999 })
	
	if hEntity:IsRealHero() and CParty:IsPartyMember(hEntity) and GameRules:GetCustomGameDifficulty() < IW_DIFFICULTY_UNTHAW then
		hEntity:AddNewModifier(hEntity, hCorpseItem, "modifier_internal_corpse_unselectable", {})
	else
		if hEntity:IsInventoryEmpty() then
			hEntity:AddNewModifier(hEntity, hCorpseItem, "modifier_internal_corpse_unselectable", {})
		else
			hEntity._nCorpseListener = CustomGameEventManager:RegisterListener("iw_lootable_interact", function(_, args) OnCorpseLootableInteract(hEntity, args) end)
		end
	end
end