if not GameRules.CombatState then

require("timer")
require("ext_entity")

IW_COMBAT_LINGER_TIME = 5.0

GameRules.CombatState = false
GameRules.IsInCombat = function() return GameRules.CombatState end

local stCombatNetTable = {}
local nCombatParticleID = nil

shCombatTimer = CTimer(0.03, function()
	GameRules.CombatState = false
	local hEntity = Entities:First()
	while hEntity do
		if IsValidExtendedEntity(hEntity) and hEntity:GetMainControllingPlayer() == 0 then
			if next(hEntity._tAttackingTable) or next(hEntity._tAttackedByTable) then
				GameRules.CombatState = true
				break
			end
		end
		hEntity = Entities:Next(hEntity)
	end
	
	if nCombatParticleID and not GameRules.CombatState then
		ParticleManager:DestroyParticle(nCombatParticleID, true)
		nCombatParticleID = nil
	elseif not nCombatParticleID and GameRules.CombatState then
		nCombatParticleID = ParticleManager:CreateParticle("particles/generic_gameplay/screen_combat.vpcf", PATTACH_EYES_FOLLOW, GameRules:GetPlayerHero())
	end
	
	stCombatNetTable.State = GameRules.CombatState
	CustomNetTables:SetTableValue("game", "Combat", stCombatNetTable)
	return 0.1
end)

end
