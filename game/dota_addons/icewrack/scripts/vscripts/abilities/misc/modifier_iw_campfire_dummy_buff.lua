modifier_iw_campfire_dummy_buff = class({})

function modifier_iw_campfire_dummy_buff:DeclareExtEvents()
	local funcs =
	{
		[IW_MODIFIER_EVENT_ON_POST_TAKE_DAMAGE] = 1,
	}
	return funcs
end

function modifier_iw_campfire_dummy_buff:OnPostTakePrimaryDamage(args)
	if args[IW_DAMAGE_TYPE_FIRE] > 0 then
		local hEntity = self:GetParent()
		local hAbility = self:GetAbility()
		hEntity:AddNewModifier(hEntity, hAbility, "modifier_iw_campfire_dummy_buff_burning", {})
	end
end