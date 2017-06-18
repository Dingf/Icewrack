--[[
    Icewrack Modifier Triggers
]]

stIcewrackModifierTriggers = 
{
	IW_MODIFIER_NO_TRIGGER = 0,
	IW_MODIFIER_ON_ACQUIRE = 1,
	IW_MODIFIER_ON_USE = 2,
	IW_MODIFIER_ON_TOGGLE = 3,
	IW_MODIFIER_ON_CHANNEL_END = 4,
	IW_MODIFIER_ON_CHANNEL_SUCCESS = 5,
	IW_MODIFIER_ON_EQUIP = 6,
	IW_MODIFIER_ON_LEARN = 7,
	IW_MODIFIER_ON_ATTACK_SOURCE = 8,
}

for k,v in pairs(stIcewrackModifierTriggers) do _G[k] = v end