npc_iw_revive_tombstone = class({})

function npc_iw_revive_tombstone:Interact(hEntity)
	local hTarget = self._hTarget
	if hEntity and hTarget then
		local hAbility = self:FindAbilityByName("internal_revive")
		local hOwner = hAbility:GetOwner()
		if not hOwner then
			hAbility:SetOwner(hEntity)
			hEntity:IssueOrder(DOTA_UNIT_ORDER_CAST_TARGET, self, hAbility, nil, false)
		end
	end
	return true
end

function npc_iw_revive_tombstone:InteractFilter(hEntity)
	return true
end

function Spawn(args)
	local hAbility = thisEntity:AddAbility("internal_revive")
	hAbility:SetLevel(1)
	hAbility:SetOwner(nil)
end