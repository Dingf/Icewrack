iw_bounty_hunter_trapjaw = class({})

function iw_bounty_hunter_trapjaw:OnSpellStart()
	if IsServer() then
		local hEntity = self:GetCaster()
		local vTargetPos = self:GetCursorPosition()
		local hTrapEntity = CreateUnitByName("npc_iw_bounty_hunter_trapjaw", vTargetPos, true, hEntity, hEntity, hEntity:GetTeamNumber())
		hTrapEntity:AddNewModifier(hEntity, self, "modifier_iw_bounty_hunter_trapjaw_buff", {})
		hTrapEntity:AddNewModifier(hEntity, self, "modifier_iw_bounty_hunter_trapjaw_timer", { duration = self:GetSpecialValueFor("duration") })
	end
end