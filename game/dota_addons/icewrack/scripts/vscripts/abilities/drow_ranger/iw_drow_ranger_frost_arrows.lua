iw_drow_ranger_frost_arrows = class({})

function iw_drow_ranger_frost_arrows:OnToggle()
	local hEntity = self:GetCaster()
	if self:GetToggleState() then
		local tModifierArgs =
		{
			damage = self:GetSpecialValueFor("damage"),
			chill_chance = self:GetSpecialValueFor("chill_chance"),
		}
		hEntity:AddNewModifier(hEntity, self, "modifier_iw_drow_ranger_frost_arrows", tModifierArgs)
		hEntity:SetMana(hEntity:GetMana() + self:GetManaCost())	--The initial toggle shouldn't cost any mana, but we need the mana cost for display purposes
	else
		local hModifier = hEntity:FindModifierByName("modifier_iw_drow_ranger_frost_arrows")
		if hModifier ~= nil then
			hModifier:Destroy()
		end
	end
end
