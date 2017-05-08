--[[
    Icewrack Attributes
    
    Values listed are per point of that attribute
    
    STRENGTH (STR):
	    *Increases HP by 2
        *Increases Physical damage dealt with attacks by 1%
        *Increases carry capacity by 1
		*Reduces encumbrance by 1%
        
    ENDURANCE (END):
        *Increases HP by 5
        *Increases SP by 1
		*Increases resistance to physical debuffs by 1
        
    AGILITY (AGI):
        *Increases accuracy score by 1
        *Increases dodge score by 1
        *Increases attack speed by 1
		*Increases movement speed by 1
        
    CUNNING (CUN):
        *Increases critical strike chance by 5%
        *Increases critical strike multiplier by 5%
        *Requirement for some persuasion checks (TODO)
        
    INTELLIGENCE (INT):
		*Increases spellpower by 1
        *Increases MP by 2
        
    WISDOM (WIS):
		*Increases MP regeneration by 0.025/s
		*Increases other buff duration by 0.5%
		*Increases other debuff duration by 0.5%
		*Increases resistance to magical debuffs by 1
]]

if IsServer() and not modifier_internal_attribute_bonus then

stIcewrackAttributeEnum =
{
	IW_ATTRIBUTE_STRENGTH = 0,
	IW_ATTRIBUTE_ENDURANCE = 1,
	IW_ATTRIBUTE_AGILITY = 2,
	IW_ATTRIBUTE_CUNNING = 3,
	IW_ATTRIBUTE_INTELLIGENCE = 4,
	IW_ATTRIBUTE_WISDOM = 5,
}

for k,v in pairs(stIcewrackAttributeEnum) do _G[k] = v end
stIcewrackAttributeValues =
{
	[IW_ATTRIBUTE_STRENGTH] = true,
	[IW_ATTRIBUTE_ENDURANCE] = true,
	[IW_ATTRIBUTE_AGILITY] = true,
	[IW_ATTRIBUTE_CUNNING] = true,
	[IW_ATTRIBUTE_INTELLIGENCE] = true,
	[IW_ATTRIBUTE_WISDOM] = true,
}

modifier_internal_attribute_bonus = class({})
modifier_internal_attribute_bonus._tDeclareFunctionList =
{
	MODIFIER_PROPERTY_HEALTH_BONUS,
	MODIFIER_PROPERTY_MANA_BONUS,
	MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
}

function modifier_internal_attribute_bonus:GetModifierHealthBonus(args)
	local hEntity = self:GetParent()
	return (hEntity:GetAttributeValue(IW_ATTRIBUTE_ENDURANCE) * 5.0) + (hEntity:GetAttributeValue(IW_ATTRIBUTE_STRENGTH) * 2.0)
end

function modifier_internal_attribute_bonus:GetModifierManaBonus(args)
	local hEntity = self:GetParent()
	return (hEntity:GetAttributeValue(IW_ATTRIBUTE_INTELLIGENCE) * 2)
end

function modifier_internal_attribute_bonus:GetModifierAttackSpeedBonus_Constant(args)
	local hEntity = self:GetParent()
	return hEntity:GetAttributeValue(IW_ATTRIBUTE_AGILITY) * 1.0
end

function modifier_internal_attribute_bonus:OnRefresh()
	local hEntity = self:GetParent()
	self:SetPropertyValue(IW_PROPERTY_SPELLPOWER, (hEntity:GetAttributeValue(IW_ATTRIBUTE_INTELLIGENCE) * 1.0))
end

end