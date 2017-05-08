--TODO: Make this only work when all party members are present/when the last party member enters
function OnMapTransitionTrigger(hTrigger, tArgs)
	if not GameRules:IsInCombat() then
		local nIndex,nLength = string.find(hTrigger:GetName(), "transition_")
		if nIndex == 1 then
			local szMapName = string.sub(hTrigger:GetName(), nLength + 1)
			FireGameEventLocal("iw_map_transition", { map = szMapName })
		end
	else
		GameRules:SendCustomMessage("#iw_error_transition_combat", 0, 0)
	end
end