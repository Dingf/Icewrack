require("world_object")

local CIcewrack_BountyTrapjaw = class({})

function CIcewrack_BountyTrapjaw:OnTrapjawTrigger(hTarget)
	local hModifier = self:FindModifierByName("modifier_iw_bounty_hunter_trapjaw_buff")
	local hAbility = hModifier:GetAbility()
	local hCaster = hModifier:GetCaster()
	if hTarget and hAbility and hCaster then
		self:SetObjectState(1)
		self:ForceKill(false)
		self:SetThink(function() self:RespawnUnit() end, "TrapjawRespawn", 1.0)
	
		local tDamageTable =
		{
			attacker = hCaster,
			target = hTarget,
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
		hTarget:RemoveModifierByName("modifier_iw_bounty_hunter_trapjaw_root")
		local hRootModifier = hTarget:AddNewModifier(hCaster, hAbility, "modifier_iw_bounty_hunter_trapjaw_root", { root_duration = hAbility:GetSpecialValueFor("root_duration") })
		if hRootModifier then
			self:SetAbsOrigin(hTarget:GetAbsOrigin())
		end
		EmitSoundOn("Hero_BountyHunter.Trapjaw", self)
	end
end

function CIcewrack_BountyTrapjaw:OnTrapjawThink()
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
	if fTriggerRadius and hParentEntity and self:GetObjectState() == 0 then
		local tUnitsList = FindUnitsInRadius(hParentEntity:GetTeamNumber(), self:GetAbsOrigin(), nil, fTriggerRadius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, 0, false)
		for k,v in pairs(tUnitsList) do
			if IsValidExtendedEntity(v) and not v:IsFlying() and not v:IsCorpse() then
				self:OnTrapjawTrigger(v)
				return
			end
		end
		return 0.1
	end
end

function OnInteract(self, hEntity)
	--TODO: Actually implement me
	return true
end

function OnInteractFilterInclude(self, hEntity)
	return hEntity:GetUnitName() == "npc_dota_hero_bounty_hunter"
end

function Spawn(args)
	if not IsValidWorldObject(thisEntity) then
		thisEntity = CWorldObject(thisEntity)
		setmetatable(thisEntity, ExtendIndexTable(thisEntity, CIcewrack_BountyTrapjaw))
		thisEntity:SetThink("OnTrapjawThink", thisEntity, "TrapjawThink", 3.0)
	end
end
