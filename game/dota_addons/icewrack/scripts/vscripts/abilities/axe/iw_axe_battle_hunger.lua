iw_axe_battle_hunger = class({})

function iw_axe_battle_hunger:OnToggle()
	local hEntity = self:GetCaster()
	if self:GetToggleState() then
		local tModifierArgs =
		{
			lifesteal = self:GetSpecialValueFor("lifesteal"),
			second_wind = self:GetSpecialValueFor("second_wind"),
			attack_speed = self:GetSpecialValueFor("attack_speed"),
			health_loss = self:GetSpecialValueFor("health_loss"),
		}
		hEntity:AddNewModifier(hEntity, self, "modifier_iw_axe_battle_hunger", tModifierArgs)
	else
		local hModifier = hEntity:FindModifierByName("modifier_iw_axe_battle_hunger")
		if hModifier ~= nil then
			hModifier:Destroy()
		end
	end
end
