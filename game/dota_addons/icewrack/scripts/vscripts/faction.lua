--[[
    Icewrack Factions
]]


if not CFactionEntity then

local stFactionData = LoadKeyValues("scripts/npc/iw_faction_list.txt")

CFactionEntity = setmetatable(ext_class({}), { __call = 
	function(self, hEntity, nFactionMask)
		LogAssert(IsInstanceOf(hEntity, CDOTA_BaseNPC), LOG_MESSAGE_ASSERT_TYPE, "CDOTA_BaseNPC", type(hEntity))
		LogAssert(type(nFactionMask) ~= "number", LOG_MESSAGE_ASSERT_TYPE, "number", type(nFactionMask))
		if hEntity._bIsFactionEntity then
			return hEntity
		end
		
		ExtendIndexTable(hEntity, CFactionEntity)
		
		hEntity._nFactionMask = nFactionMask
		
		return hEntity
	end})
	
function CFactionEntity:IsEnemy(hTarget)
	if IsValidFactionEntity(hTarget) then
	
	end
end
	
function CFactionEntity:GetFactionWeight(nFactionMask)

end
	
	
end