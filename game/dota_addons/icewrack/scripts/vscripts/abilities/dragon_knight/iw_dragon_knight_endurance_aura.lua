iw_dragon_knight_endurance_aura = class({})

function iw_dragon_knight_endurance_aura:OnToggle()
	local hEntity = self:GetCaster()
	if self:GetToggleState() then
		local tModifierArgs =
		{
			health_regen = self:GetSpecialValueFor("health_regen"),
			stamina_regen = self:GetSpecialValueFor("stamina_regen"),
			phys_resist = self:GetSpecialValueFor("phys_resist"),
		}
		hEntity:AddNewModifier(hEntity, self, "modifier_iw_dragon_knight_endurance_aura", tModifierArgs)
	else
		local hModifier = hEntity:FindModifierByName("modifier_iw_dragon_knight_endurance_aura")
		if hModifier ~= nil then
			hModifier:Destroy()
		end
	end
end
