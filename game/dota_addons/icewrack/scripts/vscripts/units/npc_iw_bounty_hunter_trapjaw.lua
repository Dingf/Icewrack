function OnDestroy(self)
	local hEntity = self:GetParent()
	local hCaster = self:GetCaster()
	local hAbility = self:GetAbility()
	
	hEntity._bIsTriggered = true
	hEntity:ForceKill(false)
	hEntity:SetThink(function() hEntity:RespawnUnit() end, "TrapjawRespawn", 1.0)
	
	local hTrapTarget = hEntity._hTrapTarget
	local fLingerDuration = 1.0
	if hTrapTarget then
		local tDamageTable =
		{
			attacker = hCaster,
			target = hTrapTarget,
			source = hAbility,
			damage =
			{
				[IW_DAMAGE_TYPE_PIERCE] = 
				{
					min = hAbility:GetSpecialValueFor("damage_min") + (hCaster:GetSpellpower() * hAbility:GetSpecialValueFor("damage_min_bonus")),
					max = hAbility:GetSpecialValueFor("damage_max") + (hCaster:GetSpellpower() * hAbility:GetSpecialValueFor("damage_max_bonus")),
				}
			}
		}
		DealPrimaryDamage(hAbility, tDamageTable)
	
		local hRootModifier = hTrapTarget:AddNewModifier(hCaster, hAbility, "modifier_iw_bounty_hunter_trapjaw_root", { root_duration = hAbility:GetSpecialValueFor("root_duration") })
		if hRootModifier then
			fLingerDuration = math.max(1.0, hRootModifier:GetDuration() - 1.0)
			hEntity:SetAbsOrigin(hTrapTarget:GetAbsOrigin())
		end
	end
	hEntity:SetThink(function() hEntity:SetAbsOrigin(hEntity:GetAbsOrigin() + Vector(0,0,-8)) return 0.1 end, "TrapjawSinkThink", fLingerDuration)
	hEntity:SetThink(function() hEntity:RemoveSelf() end, "TrapjawRemoveThink", fLingerDuration + 1.0)
	EmitSoundOn("Hero_BountyHunter.Trapjaw", hEntity)
end

function OnTrapjawThink(self)
	if not self._fTriggerRadius then
		local hModifier = self:FindModifierByName("modifier_iw_bounty_hunter_trapjaw_buff")
		if hModifier then
			local hAbility = hModifier:GetAbility()
			if hAbility then
				self._fTriggerRadius = hAbility:GetAOERadius()
				self._hParentEntity = hModifier:GetCaster()
			end
		end
	end
	local fTriggerRadius = self._fTriggerRadius
	local hParentEntity = self._hParentEntity
	if fTriggerRadius and hParentEntity and not self._bIsTriggered then
		local tUnitsList = FindUnitsInRadius(hParentEntity:GetTeamNumber(), self:GetAbsOrigin(), nil, fTriggerRadius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, 0, false)
		for k,v in pairs(tUnitsList) do
			if IsValidExtendedEntity(v) and not v:IsFlying() then
				self._hTrapTarget = v
				self:RemoveModifierByName("modifier_iw_bounty_hunter_trapjaw_timer")
				return
			end
		end
		return 0.1
	end
end

function Spawn(args)
	if not thisEntity._bIsTriggered then
		thisEntity.OnTrapjawThink = OnTrapjawThink
		thisEntity:SetThink("OnTrapjawThink", thisEntity, "TrapjawThink", 3.0)
	end
end
