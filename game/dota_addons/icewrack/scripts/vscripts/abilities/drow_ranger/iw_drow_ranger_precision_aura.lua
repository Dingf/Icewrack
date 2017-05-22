iw_drow_ranger_precision_aura = class({})

function iw_drow_ranger_precision_aura:OnToggle()
	local hEntity = self:GetCaster()
	if self:GetToggleState() then
		local tModifierArgs =
		{
			accuracy = self:GetSpecialValueFor("accuracy"),
			crit_chance = self:GetSpecialValueFor("crit_chance"),
		}
		hEntity:AddNewModifier(hEntity, self, "modifier_iw_drow_ranger_precision_aura", tModifierArgs)
	else
		local hModifier = hEntity:FindModifierByName("modifier_iw_drow_ranger_precision_aura")
		if hModifier ~= nil then
			hModifier:Destroy()
		end
	end
end
