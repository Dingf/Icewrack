iw_axe_battle_hunger = class({})

function iw_axe_battle_hunger:OnToggle()
	if self:GetToggleState() then
		local tModifierArgs =
		{
			lifesteal = self:GetSpecialValueFor("lifesteal"),
			second_wind = self:GetSpecialValueFor("second_wind"),
			attack_speed = self:GetSpecialValueFor("attack_speed"),
		}
		self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_iw_axe_battle_hunger", tModifierArgs)
	else
		local hModifier = self:GetCaster():FindModifierByName("modifier_iw_axe_battle_hunger")
		if hModifier ~= nil then
			hModifier:Destroy()
		end
	end
end
