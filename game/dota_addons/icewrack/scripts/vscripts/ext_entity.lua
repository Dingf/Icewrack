--[[
    Icewrack Extended Entity
]]

--Flags
--  *Leaves no corpse
--  *Massive (can't be affected by some effects)
--  *Flying (can't trigger some ground effects)

--TODO: Add an overencumbered debuff that applies whenever the character's carry weight exceeds its limit

if not CExtEntity then

require("mechanics/attributes")
require("mechanics/skills")
require("mechanics/zone_los_blocker")
require("instance")
require("container")
require("spellbook")
require("dialogue")
require("aam")

stExtEntityUnitClassEnum =
{  
    IW_UNIT_CLASS_CRITTER = 1,  IW_UNIT_CLASS_NORMAL = 2, IW_UNIT_CLASS_VETERAN = 3, IW_UNIT_CLASS_ELITE = 4, IW_UNIT_CLASS_BOSS = 5,
	IW_UNIT_CLASS_ACT_BOSS = 6, IW_UNIT_CLASS_HERO = 7,
}

stExtEntityUnitTypeEnum =
{
	IW_UNIT_TYPE_NONE = 0,
    IW_UNIT_TYPE_MELEE = 1,
	IW_UNIT_TYPE_RANGED = 2,
	IW_UNIT_TYPE_MAGIC = 3,
}

stExtEntityUnitSubtypeEnum =
{
    IW_UNIT_SUBTYPE_NONE = 0,
	IW_UNIT_SUBTYPE_BIOLOGICAL = 1,
	IW_UNIT_SUBTYPE_MECHANICAL = 2,
	IW_UNIT_SUBTYPE_ELEMENTAL = 4,
	IW_UNIT_SUBTYPE_HUMANOID = 8,
	IW_UNIT_SUBTYPE_BEAST = 16,
	IW_UNIT_SUBTYPE_UNDEAD = 32,
	IW_UNIT_SUBTYPE_DEMON = 64,
}

--TODO: Make it so that disposition gains are harder based on relative morality distance
--i.e. lawful good has a distance of 4 vs. chaotic evil (lawful - chaotic = 2, good - evil = 2)
--so disposition gains are harder and disposition losses are greater
--
--If you would gain 20 disposition, then with the following distances,
--  at 0: +24 = +20 * (1 - (2 * 0.1))
--  at 1: +22 = +20 * (1 - (1 * 0.1))
--  at 2: +20 = +20 * (1 - (0 * 0.1))
--  at 3: +18 = +20 * (1 - (-1 * 0.1))
--  at 4: +16 = +20 * (1 - (-2 * 0.1))
--
--Likewise, if you would lose 20 disposition, then
--  at 0: -16 = -20 * (1 - (2 * -0.1))
--  at 1: -18 = -20 * (1 - (1 * -0.1))
--  at 2: -20 = -20 * (1 - (0 * -0.1))
--  at 3: -22 = -20 * (1 - (-1 * -0.1))
--  at 4: -24 = -20 * (1 - (-2 * -0.1))
--
--TODO: Actually implement alignment
stExtEntityAlignment =
{
	IW_UNIT_ALIGNMENT_LAWFUL_GOOD = 1,
	IW_UNIT_ALIGNMENT_NEUTRAL_GOOD = 2,
	IW_UNIT_ALIGNMENT_CHAOTIC_GOOD = 3,
	IW_UNIT_ALIGNMENT_LAWFUL_NEUTRAL = 4,
	IW_UNIT_ALIGNMENT_TRUE_NEUTRAL = 5,
	IW_UNIT_ALIGNMENT_CHAOTIC_NEUTRAL = 6,
	IW_UNIT_ALIGNMENT_LAWFUL_EVIL = 7,
	IW_UNIT_ALIGNMENT_NEUTRAL_EVIL = 8,
	IW_UNIT_ALIGNMENT_CHAOTIC_EVIL = 9,
}

stExtEntityFlagEnum =
{
    IW_UNIT_FLAG_NONE = 0,
	IW_UNIT_FLAG_MASSIVE = 1,					-- Unit is large and can't be affected by some abilities that only affect smaller units
	IW_UNIT_FLAG_FLYING = 2,					-- Unit is flying and can't be affected by ground-based abilities
	IW_UNIT_FLAG_NO_CORPSE = 4,					-- Unit does not provide a corpse when it dies
	IW_UNIT_FLAG_CAN_REVIVE = 8,				-- Unit is revivable (TODO: rework the revive mechanic)
	IW_UNIT_FLAG_CONSIDERED_DEAD = 16,			-- Unit is considered dead and can be targeted by abilities that target corpses
	IW_UNIT_FLAG_REQ_ATTACK_SOURCE = 32,		-- Unit requires an attack source before it can attack
	IW_UNIT_FLAG_WEATHER_IMMUNE = 64,			-- Unit is immune to all weather effects (TODO: When implementing weather, skip units with weather immunity)
	IW_UNIT_FLAG_DONT_RECEIVE_DAMAGE = 128,		-- Unit does not receive health loss from damage (all calculations and on-damage effects are still applied)
	IW_UNIT_FLAG_CANNOT_DRAIN = 256,			-- Unit cannot be affected by drain effects (lifesteal, life/mana drain, etc.)
}

for k,v in pairs(stExtEntityUnitClassEnum) do _G[k] = v end
for k,v in pairs(stExtEntityUnitTypeEnum) do _G[k] = v end
for k,v in pairs(stExtEntityUnitSubtypeEnum) do _G[k] = v end
for k,v in pairs(stExtEntityFlagEnum) do _G[k] = v end

local shItemAttackModifier = CreateItem("item_internal_attack", nil, nil)
local shItemStaminaModifier = CreateItem("item_internal_stamina", nil, nil)
local shItemAttributeModifier = CreateItem("item_internal_attribute_bonus", nil, nil)
local shItemSkillModifier = CreateItem("item_internal_skill_bonus", nil, nil)
local shItemCarryModifier = CreateItem("item_internal_carry_weight", nil, nil)

local stExtEntityData = LoadKeyValues("scripts/npc/npc_units_extended.txt")

local shDefaultProperties = CInstance(setmetatable({}, { __index = {} }), 0)
for k,v in pairs(stExtEntityData["default"]) do
	local nPropertyID = stIcewrackPropertiesName[k]
	if nPropertyID and type(v) == "number" then
		shDefaultProperties:SetPropertyValue(nPropertyID, v)
	end
end

CExtEntity = setmetatable(ext_class({}), { __call = 
	function(self, hEntity, nInstanceID)
		LogAssert(IsInstanceOf(hEntity, CDOTA_BaseNPC), LOG_MESSAGE_ASSERT_TYPE, "CDOTA_BaseNPC")
		if IsInstanceOf(hEntity, CExtEntity) then
			LogMessage(LOG_MESSAGE_WARN_EXISTS, LOG_SEVERITY_WARNING, "CExtEntity", hEntity:GetUnitName())
			return hEntity
		end
		
		local tExtEntityTemplate = stExtEntityData[hEntity:GetUnitName()]
		LogAssert(tExtEntityTemplate, LOG_MESSAGE_ASSERT_TEMPLATE, hEntity:GetUnitName())
		
		hEntity = CContainer(hEntity, nInstanceID)
		hEntity = CSpellbook(hEntity)
		hEntity = CAbilityAutomatorModule(hEntity)
		hEntity = CDialogueEntity(hEntity)
		ExtendIndexTable(hEntity, CExtEntity)
		
		hEntity._nUnitClass   = stExtEntityUnitClassEnum[tExtEntityTemplate.UnitClass] or IW_UNIT_CLASS_NORMAL
		hEntity._nUnitType 	  = stExtEntityUnitTypeEnum[tExtEntityTemplate.UnitType] or 0
		hEntity._nUnitSubtype = GetFlagValue(tExtEntityTemplate.UnitSubtype, stExtEntityUnitSubtypeEnum)
		hEntity._nUnitFlags   = GetFlagValue(tExtEntityTemplate.UnitFlags, stExtEntityFlagEnum)
		hEntity._nAlignment   = stExtEntityAlignment[tExtEntityTemplate.Alignment] or IW_ALIGNMENT_TRUE_NEUTRAL
		hEntity._fUnitHeight  = tExtEntityTemplate.UnitHeight or 0
		
		hEntity:SetEquipFlags(tExtEntityTemplate.EquipFlags)
		hEntity:AddChild(shDefaultProperties)
		
		for k,v in pairs(tExtEntityTemplate) do
			local nPropertyID = stIcewrackPropertiesName[k]
			hEntity:SetPropertyValue(nPropertyID, v)
		end
		
		hEntity._nRealUnitFlags = 0
		
		hEntity._tAttackingTable = setmetatable({}, stZeroDefaultMetatable)
		hEntity._tAttackedByTable = setmetatable({}, stZeroDefaultMetatable)
		hEntity._tAttackQueue = {}
		
		hEntity._tAttackSourceTable = {}
		hEntity._hOrbAttackSource = nil
		hEntity._bOrbAttackState = nil
		
		hEntity._bCanExceedCapacity = true
		hEntity._fStamina = hEntity:GetMaxStamina()
		hEntity._fStaminaRegenTime = 0.0
		hEntity._fLastStaminaPercent = 1.0
		hEntity._fLastMaxStamina = hEntity:GetMaxStamina()
		
		hEntity._tDetectTable = {}
		hEntity._tThreatTable = setmetatable({}, stZeroDefaultMetatable)
		hEntity._tNoiseTable = setmetatable({}, stZeroDefaultMetatable)
		
		--hEntity._tRefreshList = {}
		hEntity:AddNewModifier(hEntity, shItemAttackModifier, "modifier_internal_attack", {})
		hEntity:AddNewModifier(hEntity, shItemStaminaModifier, "modifier_internal_stamina", {})
		hEntity:AddNewModifier(hEntity, shItemSkillModifier, "modifier_internal_skill_bonus", {})
		hEntity:AddNewModifier(hEntity, shItemAttributeModifier, "modifier_internal_attribute_bonus", {})
		hEntity:AddNewModifier(hEntity, shItemCarryModifier, "modifier_internal_carry_weight", {})
		
		hEntity:SetThink("OnNoiseDecayThink", hEntity, "NoiseDecayThink", 0.1)
		hEntity:SetThink("OnMoveNoiseThink", hEntity, "MoveNoiseThink", 0.03)
		hEntity:SetThink("OnDetectThink", hEntity, "DetectThink", 0.03)
		
		if type(tExtEntityTemplate.Abilities) == "table" then
			for k,v in pairs(tExtEntityTemplate.Abilities) do
				hEntity:LearnAbility(v)
			end
		end
		
		if hEntity.OnSpawn then hEntity:OnSpawn() end
		
		hEntity:RefreshEntity()
		return hEntity
	end})

function CExtEntity:GetUnitClass()
    return self._nUnitClass
end

function CExtEntity:GetUnitType()
    return self._nUnitType
end

function CExtEntity:GetUnitSubtype()
    return self._nUnitSubtype
end

function CExtEntity:GetAlignment()
	return self._nAlignment
end

function CExtEntity:GetUnitFlags()
	return self._nRealUnitFlags
end

function CExtEntity:GetUnitHeight()
	return self._fUnitHeight
end

function CExtEntity:GetStamina()
    return math.min(self._fStamina, self:GetMaxStamina())
end

function CExtEntity:GetStaminaRegenTime()
    return self._fStaminaRegenTime
end

function CExtEntity:GetCarryCapacity()
	return (self:GetAttributeValue(IW_ATTRIBUTE_STRENGTH) * 2.0) + self:GetPropertyValue(IW_PROPERTY_CARRY_CAPACITY)
end

function CExtEntity:GetLastOrderID()
	return self._nLastOrderID
end

function CExtEntity:GetHighestThreatTarget()
	local hHighestTarget = nil
	local fHighestThreat = -1
	for k,v in pairs(self._tThreatTable) do
		local hTarget = EntIndexToHScript(k)
		if hTarget:IsLowAttackPriority() then v = 0 end
		if not hTarget:IsAlive() or hTarget:GetTeamNumber() == self:GetTeamNumber() then
			self._tThreatTable[nEntityIndex] = nil
		elseif v > fHighestThreat and self:CanEntityBeSeenByMyTeam(hTarget) and not hTarget:IsInvulnerable() then
			hHighestTarget = hTarget
			fHighestThreat = v
		end
	end
	return hHighestTarget
end

function CExtEntity:GetThreatForTarget(hTarget)
	local nEntityIndex = hTarget:entindex()
	if hTarget:IsAlive() and self._tThreatTable[nEntityIndex] then
		return self._tThreatTable[nEntityIndex]
	end
	return 0
end

function CExtEntity:IsMassive()
	return bit32.btest(self:GetUnitFlags(), IW_UNIT_FLAG_MASSIVE)
end

function CExtEntity:IsFlying()
	return bit32.btest(self:GetUnitFlags(), IW_UNIT_FLAG_FLYING)
end

function CExtEntity:IsConsideredDead()
	return bit32.btest(self:GetUnitFlags(), IW_UNIT_FLAG_CONSIDERED_DEAD)
end

function CExtEntity:IsDualWielding()
	local bResult = false
	local nHighestLevel = 0
	for k,v in pairs(self._tAttackSourceTable) do
		if k > nHighestLevel then
			local nAttackSourceCount = #v
			if nAttackSourceCount > 0 then
				nHighestLevel = k
				bResult = (nAttackSourceCount >= 2)
			end
		end
	end
	return bResult
end

function CExtEntity:IsRunning()
    return true
end

function CExtEntity:IsHoldingPosition()
    return false
end

function CExtEntity:IsAlive()
	if self:HasModifier("modifier_internal_corpse_state") then
		return false
	else
		return CDOTA_BaseNPC.IsAlive(self)
	end
end

function CExtEntity:IsTargetInLOS(target, bIgnoreLOSBlockers)
	local tTraceArgs =
	{
		startpos = self:GetAbsOrigin() + Vector(0, 0, self:GetUnitHeight()),
		mask = MASK_PLAYERSOLID,
		ignore = 0
	}
	
	--Offset the endpos slightly to prevent automatic collision with the ground
	if type(target) == "userdata" then
		tTraceArgs.endpos = target + Vector(0, 0, 32)
	elseif IsInstanceOf(target, CEntityBase) then
		tTraceArgs.endpos = target:GetAbsOrigin() + Vector(0, 0, 128)
		if IsValidExtendedEntity(target) then
			tTraceArgs.endpos = tTraceArgs.endpos + Vector(0, 0, target:GetUnitHeight())
		end
	end
	
	if tTraceArgs.endpos then
		TraceLine(tTraceArgs)
		if not tTraceArgs.enthit then
			local bResult = true
			if type(target) == "userdata" then
				if (target - self:GetAbsOrigin()):Length2D() < 128.0 then
					return bResult
				end
			elseif IsInstanceOf(target, CEntityBase) then
				if CalcDistanceBetweenEntityOBB(self, target) < 128.0 then
					return bResult
				end
			end
			
			if not bIgnoreLOSBlockers then
				local v1 = tTraceArgs.endpos - tTraceArgs.startpos
				local tBlockerZones = CLOSBlockerZone:GetLOSBlockerZones()
				for k,v in pairs(tBlockerZones) do
					if v:IsTargetInZone(tTraceArgs.startpos) or v:IsTargetInZone(tTraceArgs.endpos) then
						bResult = false
						break
					end
					local v2 = v:GetOrigin() - tTraceArgs.startpos
					local u = v2:Dot(v1)/v1:Dot(v1)
					local v3 = (u * v1)
					if (v2 - v3):Length() <= v:GetRadius() and u > 0.0 and u < 1.0 then
						bResult = false
						break
					end
				end
			end
			return bResult
		end
	end
	return false
end

function CExtEntity:IsTargetInVisionMask(target)
	if self:IsTargetInLOS(target) then
		local vForward = self:GetForwardVector():Normalized()
		local vTargetPos = (type(target) == "userdata") and target or target:GetAbsOrigin()
		local vTargetVector = (vTargetPos - self:GetAbsOrigin()):Normalized()
		local fCosTheta = math.min(1.0, math.max(-1.0, vForward:Dot(vTargetVector)))
		return bit32.btest(self:GetPropertyValue(IW_PROPERTY_VISION_MASK), bit32.lshift(1, math.floor(math.acos(fCosTheta)/0.1308996939)))
	end
	return false
end

function CExtEntity:IsTargetDetected(hTarget)
	if self:IsTargetInLOS(hTarget) then
		local fCurrentTime = GameRules:GetGameTime()
		local fLastDetectTime = self._tDetectTable[hTarget:entindex()]
		if self:IsControllableByAnyPlayer() then
			return true
		elseif fLastDetectTime then
			return fLastDetectTime >= fCurrentTime
		end
	end
	return false
end

function CExtEntity:AddThreat(hEntity, fThreatAmount, bUseDistance)
	if not self:IsControllableByAnyPlayer() then
		if fThreatAmount > 0 and IsValidExtendedEntity(hEntity) and self:IsTargetEnemy(hEntity) then
			local nEntityIndex = hEntity:entindex()
			local tThreatTable = self._tThreatTable
			local fThreatRadius = self:GetPropertyValue(IW_PROPERTY_THREAT_RADIUS)
			local fDistance = math.min((self:GetAbsOrigin() - hEntity:GetOrigin()):Length2D(), fThreatRadius)
			local fDistanceMultiplier = bUseDistance and (0.5 * (1.0 - (fDistance/fThreatRadius))) + 0.5 or 1.0
			local fThreatMultiplier = 1.0 + self:GetPropertyValue(IW_PROPERTY_THREAT_MULTI)/100.0
			local fThreatValue = fThreatAmount * fDistanceMultiplier * fThreatMultiplier
			tThreatTable[nEntityIndex] = tThreatTable[nEntityIndex] + fThreatValue
			
			local fShareRadius = self:GetPropertyValue(IW_PROPERTY_SHARE_RADIUS)
			local hNearbyEntities = FindUnitsInRadius(self:GetTeamNumber(), self:GetAbsOrigin(), nil, fShareRadius, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, 0, 0, false)
			for k,v in pairs(hNearbyEntities) do
				if v:GetFactionID() == self:GetFactionID() and v ~= self and IsValidExtendedEntity(v) then
					v._tThreatTable[nEntityIndex] = v._tThreatTable[nEntityIndex] + fThreatValue * self:GetPropertyValue(IW_PROPERTY_THREAT_SHARE_PCT)
				end
			end
		end
	end
end

function CExtEntity:AddNoiseEvent(vNoiseOrigin, fNoiseValue)
	if not self:HasStatusEffect(IW_STATUS_MASK_DEAF) then
		local fNoiseThreshold = self:GetPropertyValue(IW_PROPERTY_NOISE_THRESHOLD)
		local fNoiseValue = fNoiseValue/math.pow(math.max(1, (vNoiseOrigin - self:GetAbsOrigin()):Length2D()/256.0), 2)
		if fNoiseValue > fNoiseThreshold then
			local x = GridNav:WorldToGridPosX(vNoiseOrigin.x)
			local y = GridNav:WorldToGridPosY(vNoiseOrigin.y)
			if x < 0 then x = x + 1024 end
			if y < 0 then y = y + 1024 end
			local nGridIndex = (x * 1024) + y
			local tNoiseTable = self._tNoiseTable
			tNoiseTable[nGridIndex] = tNoiseTable[nGridIndex] + fNoiseValue
		end
	end
end

function CExtEntity:DetectEntity(hEntity, fDetectTime)
	local nEntityIndex = hEntity:entindex()
	local bIsTargetEnemy = self:IsTargetEnemy(hEntity)
	
	self._tDetectTable[nEntityIndex] = GameRules:GetGameTime() + fDetectTime
	hEntity:MakeVisibleToTeam(self:GetTeamNumber(), fDetectTime)
	if self._tThreatTable[nEntityIndex] and bIsTargetEnemy then
		self._tThreatTable[nEntityIndex] = 1.0
	end
	
	if bIsTargetEnemy then
		local fShareRadius = self:GetPropertyValue(IW_PROPERTY_SHARE_RADIUS)
		local hNearbyEntities = FindUnitsInRadius(self:GetTeamNumber(), self:GetAbsOrigin(), nil, fShareRadius, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, 0, 0, false)
		for k,v in pairs(hNearbyEntities) do
			if IsValidExtendedEntity(v) and v:GetFactionID() == self:GetFactionID() and v ~= self then
				v._tDetectTable[nEntityIndex] = GameRules:GetGameTime() + fDetectTime
				if not v._tThreatTable[nEntityIndex] then
					v._tThreatTable[nEntityIndex] = 1.0
				end
			end
		end
	end
end

--[[function CExtEntity:CreateCorpse()
	self:RespawnUnit()
	self._hCorpseItem = CreateItem("internal_corpse", nil, nil)
	self:AddItem(self._hCorpseItem)
	self._hCorpseItem:ApplyDataDrivenModifier(self, self, "modifier_internal_corpse_state", {})
	
	--This is a dumb hack but Valve hasn't exposed a method for making targets unattackable with attack-move
	AddModifier("elder_titan_echo_stomp", "modifier_elder_titan_echo_stomp", self, self, { duration=99999999 })
	
	if not self:IsRevivable() then	
		if self:IsInventoryEmpty() then
			self._hCorpseItem:ApplyDataDrivenModifier(self, self, "modifier_internal_corpse_unselectable", {})
		else
			self._nCorpseListener = CustomGameEventManager:RegisterListener("iw_lootable_interact", function(_, args) self:OnCorpseLootableInteract(args) end)
		end
	end
end]]

--[[function CExtEntity:OnCorpseLootableInteract(args)
	if args.lootable == self:entindex() then
		if self:IsInventoryEmpty() then
			self._hCorpseItem:ApplyDataDrivenModifier(self, self, "modifier_internal_corpse_unselectable", {})
			CustomGameEventManager:UnregisterListener(self._nCorpseListener)
		end
	end
end

function CExtEntity:OnCorpseReviveInterrupted(args)
	--self:RemoveItem(self._hCorpseItem)
end

function CExtEntity:OnCorpseReviveFinish(args)
	self:RemoveAbility("elder_titan_echo_stomp")
	self:RemoveModifierByName("modifier_elder_titan_echo_stomp")
	self:RemoveItem(self._hCorpseItem)
	self.RemoveModifierByName("modifier_internal_corpse_state")
	self.RemoveModifierByName("modifier_internal_corpse_unselectable")
	self._hCorpseItem = nil
end]]

function CExtEntity:SetAttacking(hEntity)
	if self:IsTargetEnemy(hEntity) and IsValidExtendedEntity(hEntity) then
	    local nEntityIndex = hEntity:entindex()
		local nSelfIndex = self:entindex()
		self._tAttackingTable[nEntityIndex] = self._tAttackingTable[nEntityIndex] + 1
		hEntity._tAttackedByTable[nSelfIndex] = hEntity._tAttackedByTable[nSelfIndex] + 1
		
		if hEntity:IsControllableByAnyPlayer() then
			TriggerCombatEvent()
		end
		CTimer(IW_COMBAT_LINGER_TIME, function()
			self._tAttackingTable[nEntityIndex] = self._tAttackingTable[nEntityIndex] - 1
			if self._tAttackingTable[nEntityIndex] == 0 then
				self._tAttackingTable[nEntityIndex] = nil
			end
			hEntity._tAttackedByTable[nSelfIndex] = hEntity._tAttackedByTable[nSelfIndex] - 1
			if hEntity._tAttackedByTable[nSelfIndex] == 0 then
				hEntity._tAttackedByTable[nSelfIndex] = nil
			end
		end)
	end
end

function CExtEntity:SetOrbAttackSource(hSource)
	if IsValidInstance(hSource) then
		self._hOrbAttackSource = hSource
		self._bOrbAttackState = true
	end
end

function CExtEntity:GetOrbAttackSource()
	if self._bOrbAttackState ~= nil then
		return self._hOrbAttackSource
	end
end

function CExtEntity:OnOrbPreAttack()
	if self._hOrbAttackSource and self._bOrbAttackState == false then
		self._bOrbAttackState = nil
		self._hOrbAttackSource = nil
	end
end

function CExtEntity:OnOrbPostAttack()
	if self._hOrbAttackSource and self._bOrbAttackState == true then
		self._bOrbAttackState = false
	end
end

function CExtEntity:AddAttackSource(hSource, nLevel)
	if IsValidInstance(hSource) and type(nLevel) == "number" and nLevel > 0 then
		if not self._tAttackSourceTable[nLevel] then
			self._tAttackSourceTable[nLevel] = {}
		end
		table.insert(self._tAttackSourceTable[nLevel], hSource)
		hSource:ApplyModifiers(IW_MODIFIER_ON_ATTACK_SOURCE, self)
		self:RefreshEntity()
	end
end

function CExtEntity:GetCurrentAttackSource(bSwapSource)
	local nHighestLevel = 0
	local hHighestSource = nil
	local hOrbAttackSource = self:GetOrbAttackSource()
	if hOrbAttackSource then
		return hOrbAttackSource, -1
	end
	for k,v in pairs(self._tAttackSourceTable) do
		if k > nHighestLevel then
			local _,hSource = next(v)
			if hSource then
				nHighestLevel = k
				hHighestSource = hSource
			end
		end
	end
	if bSwapSource and hHighestSource and #self._tAttackSourceTable[nHighestLevel] > 1 then
		table.remove(self._tAttackSourceTable[nHighestLevel], 1)
		table.insert(self._tAttackSourceTable[nHighestLevel], hHighestSource)
		self:RefreshEntity()
	end
	return hHighestSource, nHighestLevel
end

function CExtEntity:RemoveAttackSource(hSource, nLevel)
	if type(nLevel) == "number" and self._tAttackSourceTable[nLevel] then
		for k,v in pairs(self._tAttackSourceTable[nLevel]) do
			if v == hSource then
				hSource:RemoveModifiers(IW_MODIFIER_ON_ATTACK_SOURCE, self)
				table.remove(self._tAttackSourceTable[nLevel], k)
				self:RefreshEntity()
				return true
			end
		end
	end
	return false
end

function CExtEntity:CanPayAttackCosts()
	local hAttackSource = self:GetCurrentAttackSource() or self
	local fHealthCost  = math.max(0, hAttackSource:GetBasePropertyValue(IW_PROPERTY_ATTACK_HP_FLAT) * (1.0 + self:GetPropertyValue(IW_PROPERTY_HP_COST_PCT)/100.0))
	local fManaCost    = math.max(0, hAttackSource:GetBasePropertyValue(IW_PROPERTY_ATTACK_MP_FLAT) * (1.0 + self:GetPropertyValue(IW_PROPERTY_MP_COST_PCT)/100.0))
	local fStaminaCost = math.max(0, hAttackSource:GetBasePropertyValue(IW_PROPERTY_ATTACK_SP_FLAT) * (1.0 + self:GetPropertyValue(IW_PROPERTY_SP_COST_PCT)/100.0))
	return self:GetHealth() >= fHealthCost and self:GetMana() >= fManaCost and self:GetStamina() >= fStaminaCost
end

--[[function CExtEntity:AddToRefreshList(hEntity)
	table.insert(self._tRefreshList, 1, hEntity)
end

function CExtEntity:RemoveFromRefreshList(hEntity)
	for k,v in ipairs(self._tRefreshList) do
		if v == hEntity then
			table.remove(self._tRefreshList, k)
			break
		end
	end
end]]

function CExtEntity:HasStatusEffect(nStatusEffectMask)
	for k,v in pairs(self:FindAllModifiers()) do
		if IsValidExtendedModifier(v) then
			if bit32.btest(v:GetStatusMask(), nStatusEffectMask) then
				return true
			end
		end
	end
	return false
end

function CExtEntity:DispelStatusEffects(nStatusEffectMask)
	local tDispelledModifiers = {}
	for k,v in pairs(self:FindAllModifiers()) do
		if IsValidExtendedModifier(v) and v:IsDispellable() then
			if bit32.btest(v:GetStatusMask(), nStatusEffectMask) then
				table.insert(tDispelledModifiers, v)
			end
		end
	end
	for k,v in pairs(tDispelledModifiers) do
		v:Destroy()
	end
end

function CExtEntity:RefreshHealthRegen()
	local fHealthRegenPerSec = self:GetPropertyValue(IW_PROPERTY_HP_REGEN_FLAT)
	fHealthRegenPerSec = fHealthRegenPerSec + (self:GetPropertyValue(IW_PROPERTY_MAX_HP_REGEN)/100.0 * self:GetMaxHealth())
	fHealthRegenPerSec = fHealthRegenPerSec + math.min(self:GetPropertyValue(IW_PROPERTY_HP_LIFESTEAL), self:GetMaxHealth() * self:GetPropertyValue(IW_PROPERTY_LIFESTEAL_RATE))
	fHealthRegenPerSec = fHealthRegenPerSec * (1.0 + self:GetPropertyValue(IW_PROPERTY_HP_REGEN_PCT)/100)
	fHealthRegenPerSec = fHealthRegenPerSec * self:GetHealEffectiveness()
	self:SetBaseHealthRegen(math.max(0, fHealthRegenPerSec))
end

function CExtEntity:RefreshManaRegen()
	local fManaRegenPerSec = self:GetPropertyValue(IW_PROPERTY_MP_REGEN_FLAT) + (self:GetAttributeValue(IW_ATTRIBUTE_WISDOM) * 0.05)
	fManaRegenPerSec = fManaRegenPerSec + (self:GetPropertyValue(IW_PROPERTY_MAX_MP_REGEN)/100.0 * self:GetMaxHealth())
	fManaRegenPerSec = fManaRegenPerSec * (1.0 + self:GetPropertyValue(IW_PROPERTY_MP_REGEN_PCT)/100)
	self:SetBaseManaRegen(math.max(0, fManaRegenPerSec))
end

function CExtEntity:RefreshMovementSpeed()
	local fMovementSpeed = self:GetPropertyValue(IW_PROPERTY_MOVE_SPEED_FLAT) + (self:GetAttributeValue(IW_ATTRIBUTE_AGILITY) * 1.0)
	if not self:IsRunning() then
		fMovementSpeed = fMovementSpeed * 0.5
	end
	fMovementSpeed = fMovementSpeed * (1.0 + self:GetPropertyValue(IW_PROPERTY_MOVE_SPEED_PCT)/100) * (1.0 - self:GetPropertyValue(IW_PROPERTY_FATIGUE_MULTI)/100.0)
	self:SetBaseMoveSpeed(fMovementSpeed)
end

function CExtEntity:RefreshVisionRange()
	local fBaseVisionRange = self:GetPropertyValue(IW_PROPERTY_VISION_RANGE_FLAT) * (1.0 + self:GetPropertyValue(IW_PROPERTY_VISION_RANGE_PCT)/100.0)
	if GameRules:GetMapInfo():IsInside() then
		local fVisionMultiplier = 1.0 - (1.0 - GameRules:GetMapInfo():GetMapVisionMultiplier()) * (1.0 - self:GetPropertyValueClamped(IW_PROPERTY_DARK_SIGHT_PCT, 0, 100)/100.0)
		self:SetDayTimeVisionRange(fBaseVisionRange * fVisionMultiplier)
		self:SetNightTimeVisionRange(fBaseVisionRange * fVisionMultiplier)
	else
		local fNightVisionFactor = 0.25
		local fVisionMultiplier = 1.0 - fNightVisionFactor * (1.0 - self:GetPropertyValueClamped(IW_PROPERTY_DARK_SIGHT_PCT, 0, 100)/100.0)
		self:SetDayTimeVisionRange(fBaseVisionRange)
		self:SetNightTimeVisionRange(fBaseVisionRange * fVisionMultiplier)
	end
end

function CExtEntity:RefreshBaseAttackTime()
	local hAttackSource = self:GetCurrentAttackSource()
	if hAttackSource then
		local fBaseAttackTime = hAttackSource:GetBaseAttackTime()
		if self:IsDualWielding() then
			fBaseAttackTime = fBaseAttackTime * 0.75
		end
		self:SetBaseAttackTime(fBaseAttackTime)
	else
		local fBaseAttackTime = self:GetBaseAttackTime()
		self:SetBaseAttackTime(fBaseAttackTime)
	end
end

function CExtEntity:SetStamina(fStamina)
	self._fStamina = math.max(0, math.min(self:GetMaxStamina(), fStamina))
end

function CExtEntity:SpendStamina(fStamina)
	if fStamina >= 0 then
		self._fStamina = math.max(0, self:GetStamina() - fStamina)
		self._fStaminaRegenTime = math.max(self._fStaminaRegenTime, GameRules:GetGameTime() + self:GetPropertyValue(IW_PROPERTY_SP_RECHARGE_TIME))
		
		--This is a hack to get stamina values clientside without constantly updating the entity nettables
		self:SetBaseMagicalResistanceValue(self._fStaminaRegenTime)
	end
end

function CExtEntity:RefreshUnitFlags()
	local nFlags = self._nUnitFlags
	local tChildren = self:GetChildren()
	for k,v in pairs(tChildren) do
		if IsValidExtendedModifier(k) then
			nFlags = bit32.bor(nFlags, k:GetAddFlags())
		end
	end
	for k,v in pairs(tChildren) do
		if IsValidExtendedModifier(k) then
			nFlags = bit32.band(nFlags, bit32.bnot(k:GetRemoveFlags()))
		end
	end
	self._nRealUnitFlags = nFlags
end

function CExtEntity:RefreshHealthAndMana()
	self:AddNewModifier(self, shItemAttributeModifier, "modifier_internal_attribute_refresh", {})
	self:RemoveModifierByName("modifier_internal_attribute_refresh")
end

function CExtEntity:OnRefreshEntity()
	self:RefreshUnitFlags()
	self:RefreshBaseAttackTime()
	self:RefreshHealthRegen()
	self:RefreshManaRegen()
	self:RefreshMovementSpeed()
	self:RefreshVisionRange()
	self:SetAcquisitionRange(self:GetAttackRange() + 300.0)
	
	self:SetPropertyValue(IW_PROPERTY_ATK_SPEED_DUMMY, self:GetIncreasedAttackSpeed() * 100)		--Only used for clientside display, since Panorama truncates to int
	
	local fMaxStamina = self:GetMaxStamina()
	if fMaxStamina ~= self._fLastMaxStamina then
		self._fLastMaxStamina = fMaxStamina
		self:SetStamina(math.max(0, math.min(fMaxStamina, self._fLastStaminaPercent * fMaxStamina)))
	end
end

function CExtEntity:OnEquip(hItem, nSlot)
	if hItem:IsAttackSource() then
		self:AddAttackSource(hItem, 1)
	end
end

function CExtEntity:OnUnequip(hItem)
	if hItem:IsAttackSource() then
		self:RemoveAttackSource(hItem, 1)
	end
end

function CExtEntity:OnNoiseDecayThink()
	if not self:IsControllableByAnyPlayer() and not GameRules:IsGamePaused() then
		local tNoiseTable = self._tNoiseTable
		local fDecayRate = GameRules:GetNPCNoiseDecayRate()
		local fNoiseThreshold = self:GetPropertyValue(IW_PROPERTY_NOISE_THRESHOLD)
		for k,v in pairs(tNoiseTable) do
			local fNewValue = v * fDecayRate
			if fNewValue < fNoiseThreshold then
				tNoiseTable[k] = nil
			else
				tNoiseTable[k] = fNewValue
			end
		end
	end
	return 0.01
end

function CExtEntity:OnMoveNoiseThink()
	if self:IsMoving() and not GameRules:IsGamePaused() then
		local fNoiseValue = math.max(0, self:GetPropertyValue(IW_PROPERTY_MOVE_NOISE_FLAT) * (1.0 + self:GetPropertyValue(IW_PROPERTY_MOVE_NOISE_PCT)/100.0))
		if not self:IsRunning() then
			fNoiseValue = fNoiseValue * 0.25
		end
		local fNoiseRadius = fNoiseValue * 100.0
		if fNoiseRadius > 0 then
			local vNoiseOrigin = self:GetAbsOrigin()
			local hNearbyEntities = FindUnitsInRadius(self:GetTeamNumber(), vNoiseOrigin, nil, fNoiseRadius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, 0, false)
			for k,v in pairs(hNearbyEntities) do
				if IsValidExtendedEntity(v) and self:IsTargetEnemy(v) then
					v:AddNoiseEvent(vNoiseOrigin, fNoiseValue, self)
				end
			end
		end
	end
	return 0.03
end

function CExtEntity:OnDetectThink()
	if not self:IsControllableByAnyPlayer() and not GameRules:IsGamePaused() then
		local nVisionRange = self:GetCurrentVisionRange()
		local nVisionMask = self:GetPropertyValue(IW_PROPERTY_VISION_MASK)
		local fVisionThreshold = self:GetPropertyValue(IW_PROPERTY_VISION_THRESHOLD)
		
		local hNearbyEntities = FindUnitsInRadius(self:GetTeamNumber(), self:GetAbsOrigin(), nil, math.max(128.0, nVisionRange * 2.0), DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, 0, 0, false)
		for k,v in pairs(hNearbyEntities) do
			if IsValidExtendedEntity(v) and v:IsAlive() and self:IsTargetEnemy(v) then
				if self:IsTargetInVisionMask(v) then
					local vTargetVector = v:GetAbsOrigin() - self:GetAbsOrigin()
					local fVisionValue = v:GetPropertyValue(IW_PROPERTY_VISIBILITY_FLAT) * nVisionRange/math.max(128.0, vTargetVector:Length2D())
					local fVisionMultiplier = 1.0 + v:GetPropertyValue(IW_PROPERTY_VISIBILITY_PCT)/100.0
					if v:IsMoving() then
						fVisionMultiplier = fVisionMultiplier + 1.0
					end
					fVisionValue = fVisionValue * math.max(0.0, fVisionMultiplier)
					if fVisionValue > fVisionThreshold then
						self:DetectEntity(v, GameRules:GetNPCDetectDuration())
					end
				else
					local fDistance = self:GetRangeToUnit(v) - v:GetHullRadius() - self:GetHullRadius()
					if fDistance < 128.0 then
						self:DetectEntity(v, GameRules:GetNPCDetectDuration())
					end
				end
			end
		end
	end
	return 0.03
end

function CExtEntity:RefreshLoadout()
	return nil
end

--[[function CExtEntity:OnAttributesConfirm(args)
	local hEntity = EntIndexToHScript(args.entindex)
	if IsValidExtendedEntity(hEntity) and hEntity:IsRealHero() then
		for k,v in pairs(args) do
			if k ~= "entindex" then
				local nIndex = tonumber(k)
				if nIndex and v <= hEntity._tPropertyValues[IW_PROPERTY_ATTRIBUTE_POINTS] then
					hEntity._tPropertyValues[nIndex] = hEntity._tPropertyValues[nIndex] + v
					hEntity._tPropertyValues[IW_PROPERTY_ATTRIBUTE_POINTS] = hEntity._tPropertyValues[IW_PROPERTY_ATTRIBUTE_POINTS] - v
				end
			end
		end
		hEntity:RefreshEntity()
	end
end

function CExtEntity:OnSkillsConfirm(args)
	local hEntity = EntIndexToHScript(args.entindex)
	if IsValidExtendedEntity(hEntity) and hEntity:IsRealHero() then
		local szSkillsString = args.value
		for i=1,szSkillsString:len() do
			local nSkillPoints = hEntity._tPropertyValues[IW_PROPERTY_SKILL_POINTS];
			local nIndex = IW_PROPERTY_SKILL_FIRE + (i - 1)
			local m = hEntity._tPropertyValues[nIndex] + 1
			local n = hEntity._tPropertyValues[nIndex] + tonumber(szSkillsString:sub(i,i))
			local nSpentPoints = ((n + 1 - m) * (n + m))/2
			if nSpentPoints <= nSkillPoints and n <= IW_MAX_ASSIGNABLE_SKILL then
				hEntity._tPropertyValues[nIndex] = n
				hEntity._tPropertyValues[IW_PROPERTY_SKILL_POINTS] = nSkillPoints - nSpentPoints
			end
		end
		hEntity:RefreshEntity()
	end
end

function CExtEntity:OnToggleRun(args)
	local hEntity = EntIndexToHScript(args.entindex)
	if IsValidExtendedEntity(hEntity) and hEntity:IsControllableByAnyPlayer() then
		hEntity:ToggleRunMode()
	end
end

function CExtEntity:OnToggleHold(args)
	local hEntity = EntIndexToHScript(args.entindex)
	if IsValidExtendedEntity(hEntity) and hEntity:IsControllableByAnyPlayer() then
		hEntity:ToggleHoldPosition()
	end
end]]

function IsValidExtendedEntity(hEntity)
    return (IsValidEntity(hEntity) and IsInstanceOf(hEntity, CExtEntity))
end

end