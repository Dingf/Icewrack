require("mechanics/damage_types")

local stDamageVisualTable = 
{
	[IW_DAMAGE_TYPE_PURE]      = {6, Vector(255, 64, 255)},
	[IW_DAMAGE_TYPE_CRUSH]     = {3, Vector(255, 255, 255)},
	[IW_DAMAGE_TYPE_SLASH]     = {8, Vector(255, 255, 255)},
	[IW_DAMAGE_TYPE_PIERCE]    = {9, Vector(255, 255, 255)},
	[IW_DAMAGE_TYPE_FIRE]      = {1, Vector(255, 48, 0)},
	[IW_DAMAGE_TYPE_COLD]      = {2, Vector(0, 128, 255)},
	[IW_DAMAGE_TYPE_LIGHTNING] = {4, Vector(255, 255, 0)},
	[IW_DAMAGE_TYPE_DEATH]     = {5, Vector(0, 64, 0)},
}

function ShowResistMessage(hEntity)
	local nParticleID = ParticleManager:CreateParticle("particles/msg_fx/msg_miss.vpcf", PATTACH_ROOTBONE_FOLLOW, hEntity)
	ParticleManager:SetParticleControl(nParticleID, 1, Vector(4, nil, nil))
	ParticleManager:SetParticleControl(nParticleID, 2, Vector(1.0, 1, 0))
	ParticleManager:SetParticleControl(nParticleID, 3, Vector(255, 255, 255))
end

function ShowMissMessage(hEntity)
	local nParticleID = ParticleManager:CreateParticle("particles/msg_fx/msg_miss.vpcf", PATTACH_ROOTBONE_FOLLOW, hEntity)
	ParticleManager:SetParticleControl(nParticleID, 1, Vector(5, nil, nil))
	ParticleManager:SetParticleControl(nParticleID, 2, Vector(1.0, 1, 0))
	ParticleManager:SetParticleControl(nParticleID, 3, Vector(222, 55, 55))
end

function ShowDamageMessage(hEntity, nDamageType, fDamageAmount)
	local tDamageVisual = stDamageVisualTable[nDamageType]
	local nParticleIndex = ParticleManager:CreateParticle("particles/msg_fx/msg_crit.vpcf", PATTACH_ABSORIGIN_FOLLOW, hEntity)
	ParticleManager:SetParticleControl(nParticleIndex, 1, Vector(nil, tonumber(math.floor(fDamageAmount)), tDamageVisual[1]))
	ParticleManager:SetParticleControl(nParticleIndex, 2, Vector(math.log10(fDamageAmount), #tostring(math.floor(fDamageAmount)) + 1, 0))
	ParticleManager:SetParticleControl(nParticleIndex, 3, tDamageVisual[2])
	ParticleManager:ReleaseParticleIndex(nParticleIndex)
end

function ShowBlockMessage(hEntity, nDamageType, fBlockAmount)
	local nParticleID = ParticleManager:CreateParticle("particles/msg_fx/msg_block.vpcf", PATTACH_ROOTBONE_FOLLOW, hEntity)
	ParticleManager:SetParticleControl(nParticleID, 1, Vector(1, tonumber(math.floor(fBlockAmount)), 7))
	ParticleManager:SetParticleControl(nParticleID, 2, Vector(1.0, #tostring(math.floor(fBlockAmount)) + 2, 0))
	ParticleManager:SetParticleControl(nParticleID, 3, tDamageVisual[2])
end