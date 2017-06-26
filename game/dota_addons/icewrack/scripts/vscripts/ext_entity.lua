--[[
    Icewrack Extended Entity
]]

--Flags
--  *Leaves no corpse
--  *Massive (can't be affected by some effects)
--  *Flying (can't trigger some ground effects)

--TODO: Add an overencumbered debuff that applies whenever the character's carry weight exceeds its limit

if not CExtEntity then

if _VERSION < "Lua 5.2" then
    bit = require("lib/numberlua")
    bit32 = bit.bit32
end

require("mechanics/attributes")
require("mechanics/skills")
require("instance")
require("container")

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
	IW_UNIT_SUBTYPE_HUMANOID = 1,
	IW_UNIT_SUBTYPE_BEAST = 2,
	IW_UNIT_SUBTYPE_MECHANICAL = 3,
	IW_UNIT_SUBTYPE_ELEMENTAL = 4,
	IW_UNIT_SUBTYPE_UNDEAD = 5,
	IW_UNIT_SUBTYPE_DEMON = 6,
	IW_UNIT_SUBTYPE_DRAGON = 7,
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
	IW_UNIT_FLAG_MASSIVE = 1,
	IW_UNIT_FLAG_FLYING = 2,
	IW_UNIT_FLAG_NO_CORPSE = 4,
	IW_UNIT_FLAG_CAN_REVIVE = 8,
	IW_UNIT_FLAG_CONSIDERED_DEAD = 16,
	IW_UNIT_FLAG_REQ_ATTACK_SOURCE = 32,
}

for k,v in pairs(stExtEntityUnitClassEnum) do _G[k] = v end
for k,v in pairs(stExtEntityUnitTypeEnum) do _G[k] = v end
for k,v in pairs(stExtEntityUnitSubtypeEnum) do _G[k] = v end
for k,v in pairs(stExtEntityFlagEnum) do _G[k] = v end

local shItemAttackModifier = CreateItem("internal_attack", nil, nil)
local shItemStaminaModifier = CreateItem("internal_stamina", nil, nil)
local shItemMoveNoiseModifier = CreateItem("internal_movement_noise", nil, nil)
local shItemAttributeModifier = CreateItem("internal_attribute_bonus", nil, nil)
local shItemSkillModifier = CreateItem("internal_skill_bonus", nil, nil)

local stExtEntityData = LoadKeyValues("scripts/npc/npc_units_extended.txt")
local shDefaultProperties = CInstance({}, 0)
for k,v in pairs(stExtEntityData["default"]) do
	local nPropertyID = stIcewrackPropertiesName[k]
	if nPropertyID and type(v) == "number" then
		shDefaultProperties:SetPropertyValue(nPropertyID, v)
	end
end

local tIndexTableList = {} 
CExtEntity = setmetatable({}, { __call = 
	function(self, hEntity, nInstanceID)
		LogAssert(IsInstanceOf(hEntity, CDOTA_BaseNPC), "Type mismatch (expected \"%s\", got %s)", "CDOTA_BaseNPC", type(hEntity))
		if hEntity._bIsExtendedEntity then
			return hEntity
		end
		
		local tExtEntityTemplate = stExtEntityData[hEntity:GetUnitName()]
		LogAssert(tExtEntityTemplate, "Failed to load template \"%s\" - no data exists for this entry.", hEntity:GetUnitName())
		
		hEntity = CContainer(hEntity, nInstanceID)
		local tBaseIndexTable = getmetatable(hEntity).__index
		local tExtIndexTable = tIndexTableList[tBaseIndexTable]
		if not tExtIndexTable then
			tExtIndexTable = ExtendIndexTable(hEntity, CExtEntity)
			tExtIndexTable.__index._bIsExtendedEntity = true
			tIndexTableList[tBaseIndexTable] = tExtIndexTable
		end
		setmetatable(hEntity, tExtIndexTable)
		
		hEntity._nUnitClass   = stExtEntityUnitClassEnum[tExtEntityTemplate.UnitClass] or IW_UNIT_CLASS_NORMAL
		hEntity._nUnitType 	  = stExtEntityUnitTypeEnum[tExtEntityTemplate.UnitType] or 0
		hEntity._nUnitSubtype = stExtEntityUnitSubtypeEnum[tExtEntityTemplate.UnitSubtype] or IW_UNIT_SUBTYPE_NONE
		hEntity._nUnitFlags   = GetFlagValue(tExtEntityTemplate.UnitFlags, stExtEntityFlagEnum)
		hEntity._nAlignment   = stExtEntityAlignment[tExtEntityTemplate.Alignment] or IW_ALIGNMENT_TRUE_NEUTRAL
		hEntity._fUnitHeight  = tExtEntityTemplate.UnitHeight or 0
		hEntity._nEquipFlags  = tExtEntityTemplate.EquipFlags or 0
		hEntity._szLootTable  = tExtEntityTemplate.LootTable		--TODO: Rework the loot mechanic for npcs
		
		hEntity:AddChild(shDefaultProperties)
		
		for k,v in pairs(tExtEntityTemplate) do
			local nPropertyID = stIcewrackPropertiesName[k]
			hEntity:SetPropertyValue(nPropertyID, v)
		end
		
		hEntity._tAttackingTable = setmetatable({}, stZeroDefaultMetatable)
		hEntity._tAttackedByTable = setmetatable({}, stZeroDefaultMetatable)
		hEntity._tAttackQueue = {}
		
		hEntity._tAttackSourceTable = {}
		hEntity._hOrbAttackSource = nil
		hEntity._bOrbAttackState = nil
		
		hEntity._tExtModifierEventTable = {}
		hEntity._tExtModifierEventIndex = {}
		
		hEntity._nLastOrderID = 0
		hEntity._tOrderTable = { UnitIndex = hEntity:entindex() }
		
		hEntity._bRunMode = true
		hEntity._fStamina = hEntity:GetMaxStamina()
		hEntity._fStaminaRegenTime = 0.0
		hEntity._fLastStaminaPercent = 1.0
		hEntity._fLastMaxStamina = hEntity:GetMaxStamina()
		
		hEntity._fLifestealRegen = 0
		
		hEntity._fTotalXP = 0
		hEntity._fLevelXP = 0

		if GameRules:GetMapInfo():IsInside() then
			local fVisionMultiplier = 1.0 - (1.0 - GameRules:GetMapInfo():GetMapVisionMultiplier()) * (1.0 - hEntity:GetPropertyValueClamped(IW_PROPERTY_NIGHT_VISION, 0.0, 1.0))
			hEntity:SetDayTimeVisionRange(hEntity:GetDayTimeVisionRange() * fVisionMultiplier)
			hEntity:SetNightTimeVisionRange(hEntity:GetNightTimeVisionRange() * fVisionMultiplier)
		else
			local fVisionMultiplier = 1.0 - 0.5 * (1.0 - hEntity:GetPropertyValueClamped(IW_PROPERTY_NIGHT_VISION, 0.0, 1.0))
			hEntity:SetDayTimeVisionRange(hEntity:GetDayTimeVisionRange() * fVisionMultiplier)
			hEntity:SetNightTimeVisionRange(hEntity:GetNightTimeVisionRange() * fVisionMultiplier)
		end
		
		hEntity._tRefreshList = {}
		hEntity:AddNewModifier(hEntity, shItemAttackModifier, "modifier_internal_attack", {})
		hEntity:AddNewModifier(hEntity, shItemStaminaModifier, "modifier_internal_stamina", {})
		hEntity:AddNewModifier(hEntity, shItemAttributeModifier, "modifier_internal_attribute_bonus", {})
		hEntity:AddNewModifier(hEntity, shItemMoveNoiseModifier, "modifier_internal_movement_noise", {})
		hEntity:AddNewModifier(hEntity, shItemSkillModifier, "modifier_internal_skill_bonus", {})
		
		if tExtEntityTemplate.IsPlayableHero == 1 then
			hEntity._tNetTable =
			{
				attack_source = { Level = 0 },
				current_action = "",
				run_mode = hEntity._bRunMode,
				stamina = hEntity._fStamina,
				stamina_max = hEntity:GetMaxStamina(),
				stamina_time = hEntity._fStaminaRegenTime,
				fatigue = hEntity:GetFatigueMultiplier(),	--This could be calculated client-side, but its much more efficient to just put it here
				properties_base = {},
				properties_bonus = {},
			}
			hEntity:SetThink("CurrentActionThink", hEntity, "CurrentAction", 0.03)
		end
		
		FireGameEventLocal("iw_ext_entity_load", { entindex = hEntity:entindex() })
		
		if hEntity.OnSpawn then hEntity:OnSpawn() end
		
		hEntity:RefreshEntity()
		return hEntity
	end})
	
CustomGameEventManager:RegisterListener("iw_character_attributes_confirm", Dynamic_Wrap(CExtEntity, "OnAttributesConfirm"))
CustomGameEventManager:RegisterListener("iw_character_skills_confirm", Dynamic_Wrap(CExtEntity, "OnSkillsConfirm"))
CustomGameEventManager:RegisterListener("iw_toggle_run", Dynamic_Wrap(CExtEntity, "OnToggleRun"))

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
	local nFlags = self._nUnitFlags
	for k,v in pairs(self:GetChildren()) do
		if k.GetUnitFlags and v then
			nFlags = bit32.bor(nFlags, k:GetUnitFlags())
		end
	end
	return nFlags
end

function CExtEntity:GetUnitHeight()
	return self._fUnitHeight
end

function CExtEntity:GetEquipFlags()
	return self._nEquipFlags
end

function CExtEntity:GetRunMode()
    return self._bRunMode
end

function CExtEntity:GetLootTableName()
	return self._szLootTable
end

function CExtEntity:GetStamina()
    return math.min(self._fStamina, self:GetMaxStamina())
end

function CExtEntity:GetStaminaRegenTime()
    return self._fStaminaRegenTime
end

function CExtEntity:GetTotalExperience()
	return self._fTotalXP
end

function CExtEntity:GetCurrentLevelExperience()
	return self._fLevelXP
end

function CExtEntity:GetLastOrderID()
	return self._nLastOrderID
end

function CExtEntity:IsMassive()
	return bit32.btest(self:GetUnitFlags(), IW_UNIT_FLAG_MASSIVE)
end

function CExtEntity:IsFlying()
	return bit32.btest(self:GetUnitFlags(), IW_UNIT_FLAG_FLYING)
end

function CExtEntity:IsRevivable()
	return GameRules:GetCustomGameDifficulty() <= IW_DIFFICULTY_NORMAL and bit32.btest(self:GetUnitFlags(), IW_UNIT_FLAG_CAN_REVIVE)
end

function CExtEntity:IsCorpse()
	return self:HasModifier("modifier_internal_corpse_state") or bit32.btest(self:GetUnitFlags(), IW_UNIT_FLAG_CONSIDERED_DEAD)
end

function CExtEntity:IsAlive()
	if self:IsCorpse() then
		return false
	else
		return CBaseEntity.IsAlive(self)
	end
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

function CExtEntity:UpdateNetTable(bSkipProperties)
	if self._tNetTable then
		if not bSkipProperties then
			local tPropertiesBase = self._tNetTable.properties_base
			local tPropertiesBonus = self._tNetTable.properties_bonus
			for k,v in pairs(stIcewrackPropertyEnum) do
				tPropertiesBase[v] = self:GetBasePropertyValue(v)
				tPropertiesBonus[v] = self:GetPropertyValue(v) - tPropertiesBase[v]
			end
			self._tNetTable.fatigue = self:GetFatigueMultiplier()
		end
		CustomNetTables:SetTableValue("entities", tostring(self:entindex()), self._tNetTable)
	end
end

function CExtEntity:GetCurrentAction()
	local hActiveAbility = self:GetCurrentActiveAbility()
	if hActiveAbility then
		return hActiveAbility:GetAbilityName()
	elseif not self:IsIdle() then
		local tOrderTable = self._tOrderTable
		local nOrderType = tOrderTable.OrderType
		if nOrderType == DOTA_UNIT_ORDER_MOVE_TO_POSITION or nOrderType == DOTA_UNIT_ORDER_MOVE_TO_TARGET then
			return "internal_move"
		elseif self:IsAttacking() or nOrderType == DOTA_UNIT_ORDER_ATTACK_MOVE or nOrderType == DOTA_UNIT_ORDER_ATTACK_TARGET then
			return "internal_attack"
		end
	end	
end

function CExtEntity:IsTargetInLOS(target)
	local tTraceArgs =
	{
		startpos = self:GetAbsOrigin() + Vector(0, 0, self:GetUnitHeight()),
		mask = MASK_PLAYERSOLID,
		ignore = 0
	}
	
	--Offset the endpos slightly to prevent automatic collision with the ground
	if type(target) == "userdata" then
		tTraceArgs.endpos = target + Vector(0, 0, 32)
	elseif IsInstanceOf(target, CBaseEntity) then
		tTraceArgs.endpos = target:GetAbsOrigin() + Vector(0, 0, 32)
		if IsValidExtendedEntity(target) then
			tTraceArgs.endpos = tTraceArgs.endpos + Vector(0, 0, target:GetUnitHeight())
		end
	end
	
	if tTraceArgs.endpos then
		TraceLine(tTraceArgs)
		if not tTraceArgs.enthit then
			return true
		end
	end
	return false
end

function CExtEntity:IssueOrder(nOrder, hTarget, hAbility, vPosition, bQueue, bRepeatOnly)
    local tOrderTable = self._tOrderTable
	local nTargetEntindex = IsValidEntity(hTarget) and hTarget:entindex() or 0
	local nAbilityEntindex = IsValidEntity(hAbility) and hAbility:entindex() or 0
	if bRepeatOnly == true then
		if tOrderTable.OrderType ~= nOrder then
			return false
		elseif hTarget and tOrderTable.TargetIndex ~= nTargetEntindex then
			return false
		elseif hAbility and tOrderTable.AbilityIndex ~= nAbilityEntindex then
			return false
		elseif vPosition and tOrderTable.Position ~= vPosition then
			return false
		end
	end
	
	tOrderTable.OrderType = nOrder
	tOrderTable.TargetIndex = nTargetEntindex
	tOrderTable.AbilityIndex = nAbilityEntindex
	tOrderTable.Position = vPosition
	tOrderTable.Queue = bQueue
    ExecuteOrderFromTable(tOrderTable)
	return true
end

function CExtEntity:AddExperience(fAmount)
	if fAmount > 0 and self:IsRealHero() then
		local nOldLevel = self:GetLevel()
		fAmount = math.max(0, fAmount * (1.0 + self:GetPropertyValue(IW_PROPERTY_EXPERIENCE_MULTI)/100.0))
		CDOTA_BaseNPC_Hero.AddExperience(self, fAmount, DOTA_ModifyXP_Unspecified, false, true)
		self._fTotalXP = self._fTotalXP + fAmount
		self._fLevelXP = self._fTotalXP - GameRules.XPTable[self:GetLevel()]
		local nLevelDiff = self:GetLevel() - nOldLevel
		if nLevelDiff > 0 then
			local nParticleID = ParticleManager:CreateParticle("particles/generic_hero_status/iw_hero_levelup.vpcf", PATTACH_WORLDORIGIN, self)
			ParticleManager:SetParticleControl(nParticleID, 0, self:GetAbsOrigin())
			ParticleManager:ReleaseParticleIndex(nParticleID)
			EmitSoundOn("Icewrack.LevelUp", self)
			for k,v in pairs(stIcewrackAttributeEnum) do
				self:SetPropertyValue(v + 1, self:GetBasePropertyValue(v + 1) + nLevelDiff)
			end
			self:SetPropertyValue(IW_PROPERTY_ATTRIBUTE_POINTS, self:GetBasePropertyValue(IW_PROPERTY_ATTRIBUTE_POINTS) + (nLevelDiff * 6))
			self:SetPropertyValue(IW_PROPERTY_SKILL_POINTS, self:GetBasePropertyValue(IW_PROPERTY_SKILL_POINTS) + nLevelDiff)
			self:RefreshEntity()
		end
	end
end

function CExtEntity:CreateCorpse()
	self:RespawnUnit()
	self._hCorpseItem = CreateItem("internal_corpse", nil, nil)
	self:AddItem(self._hCorpseItem)
	self._hCorpseItem:ApplyDataDrivenModifier(self, self, "modifier_internal_corpse_state", {})
	
	--This is a dumb hack but Valve hasn't exposed a method for making targets unattackable with attack-move
	AddModifier("elder_titan_echo_stomp", "modifier_elder_titan_echo_stomp", self, self, { duration=99999999 })
	
	if not self:IsRevivable() then
		local hInventory = self:GetInventory()		
		if hInventory:IsEmpty() then
			self._hCorpseItem:ApplyDataDrivenModifier(self, self, "modifier_internal_corpse_unselectable", {})
		else
			self._nCorpseListener = CustomGameEventManager:RegisterListener("iw_lootable_interact", function(_, args) self:OnCorpseLootableInteract(args) end)
		end
	end
end

function CExtEntity:OnCorpseLootableInteract(args)
	if args.lootable == self:entindex() then
		local hInventory = self:GetInventory()
		if hInventory:IsEmpty() then
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
end

function CExtEntity:SetAttacking(hEntity)
	if hEntity:GetTeamNumber() ~= self:GetTeamNumber() and IsValidExtendedEntity(hEntity) then
	    local nEntityIndex = hEntity:entindex()
		local nSelfIndex = self:entindex()
		self._tAttackingTable[nEntityIndex] = self._tAttackingTable[nEntityIndex] + 1
		hEntity._tAttackedByTable[nSelfIndex] = hEntity._tAttackedByTable[nSelfIndex] + 1
		
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
			self._tNetTable.attack_source[nLevel] = {}
		end
		table.insert(self._tAttackSourceTable[nLevel], hSource)
		hSource:ApplyModifiers(IW_MODIFIER_ON_ATTACK_SOURCE, self)
		self:RefreshEntity()
		if self._tNetTable then
			local tAttackSourceNetTable = self._tNetTable.attack_source
			local nHighestSourceLevel = tAttackSourceNetTable.Level
			if nLevel > nHighestSourceLevel then
				tAttackSourceNetTable.Level = nLevel
			end
			table.insert(self._tNetTable.attack_source[nLevel], hSource:entindex())
			self:UpdateNetTable(true)
		end
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
				if self._tNetTable then
					local tAttackSourceNetTable = self._tNetTable.attack_source
					if nLevel == tAttackSourceNetTable.Level and not next(tAttackSourceNetTable[nLevel]) then
						tAttackSourceTable[nLevel] = nil
						local nHighestLevel = 0
						for k2,v2 in pairs(self._tAttackSourceTable) do
							if next(v2) and k2 > nHighestLevel then
								nHighestLevel = k2
							end
						end
						tAttackSourceNetTable.Level = nHighestLevel
					end
					table.remove(tAttackSourceNetTable[nLevel], k)
					self:UpdateNetTable(true)
				end
				return true
			end
		end
	end
	return false
end

function CExtEntity:CanPayAttackCosts()
	local hAttackSource = self:GetCurrentAttackSource() or self
	return self:GetHealth() >= hAttackSource:GetAttackHealthCost() and self:GetMana() >= hAttackSource:GetAttackManaCost() and self:GetStamina() >= hAttackSource:GetAttackStaminaCost()
end

function CExtEntity:TriggerExtendedEvent(nEventID, args)
	local szEventAlias = stExtModifierEventAliases[nEventID]
	if szEventAlias and self._tExtModifierEventIndex[nEventID] then
		for k,v in ipairs(self._tExtModifierEventIndex[nEventID]) do
			local hEventFunction = v[szEventAlias]
			if type(hEventFunction) == "function" then
				local result = hEventFunction(v, args)
				if result then
					return result
				end
			end
		end
	end
end

function CExtEntity:AddToRefreshList(hEntity)
	table.insert(self._tRefreshList, 1, hEntity)
end

function CExtEntity:RemoveFromRefreshList(hEntity)
	for k,v in ipairs(self._tRefreshList) do
		if v == hEntity then
			table.remove(self._tRefreshList, k)
			break
		end
	end
end

function CExtEntity:DispelModifiers(nStatusEffectMask)
	local tDispelledModifiers = {}
	for k,v in pairs(self:FindAllModifiers()) do
		if IsValidExtendedModifier(v) then
			local nStatusEffect = bit32.lshift(1, v:GetStatusEffect() - 1)
			if bit32.btest(nStatusEffect, nStatusEffectMask) then
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
	fHealthRegenPerSec = fHealthRegenPerSec + math.min(self._fLifestealRegen, self:GetMaxHealth() * self:GetPropertyValue(IW_PROPERTY_LIFESTEAL_RATE))
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
	local fMovementSpeed = self:GetPropertyValue(IW_PROPERTY_MOVE_SPEED_FLAT)
	if not self._bRunMode then
		fMovementSpeed = fMovementSpeed * 0.5
	end
	fMovementSpeed = fMovementSpeed * (self:GetFatigueMultiplier() + self:GetPropertyValue(IW_PROPERTY_MOVE_SPEED_PCT)/100)
	self:SetBaseMoveSpeed(math.max(100, fMovementSpeed))
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

function CExtEntity:SetRunMode(bRunMode)
	if type(bRunMode) == "boolean" then
		self._bRunMode = bRunMode
		if self._tNetTable then
			self._tNetTable.run_mode = bRunMode
		end
		self:RefreshMovementSpeed()
		self:UpdateNetTable(true)
	end
end

function CExtEntity:ToggleRunMode()
	self:SetRunMode(not self._bRunMode)
end

function CExtEntity:SetStamina(fStamina)
	self._fStamina = math.max(0, math.min(self:GetMaxStamina(), fStamina))
end

function CExtEntity:SpendStamina(fStamina)
	if fStamina >= 0 then
		self._fStamina = math.max(0, self:GetStamina() - fStamina)
		self._fStaminaRegenTime = math.max(self._fStaminaRegenTime, GameRules:GetGameTime() + (5.0 * (1.0 + self:GetPropertyValue(IW_PROPERTY_SP_REGEN_TIME_PCT)/100)))
	end
end

function CExtEntity:CurrentActionThink()
	if self._tNetTable then
		local szCurrentAction = self:GetCurrentAction()
		if szCurrentAction ~= self._tNetTable.current_action then
			self._tNetTable.current_action = szCurrentAction
			self:UpdateNetTable(true)
		end
	end
	return 0.03
end

function CExtEntity:RefreshEntity()
	for k,v in ipairs(self._tRefreshList) do
		v:OnEntityRefresh()
	end
	
	self:RefreshBaseAttackTime()
	self:RefreshHealthRegen()
	self:RefreshManaRegen()
	self:RefreshMovementSpeed()
	self:SetAcquisitionRange(self:GetAttackRange() + 300.0)
	
	self:SetPropertyValue(IW_PROPERTY_ATK_SPEED_DUMMY, self:GetIncreasedAttackSpeed() * 100)		--Only used for clientside display, since Panorama truncates to int
	self:SetBaseMagicalResistanceValue(self:GetFatigueMultiplier())		--Hack to get fatigue multiplier on client side lua without nettables
	
	self:UpdateNetTable()
end

function CExtEntity:RemoveEntity()
	self:RemoveSelf()
end

function CExtEntity:GetAutomator()
	return nil
end

function CExtEntity:GetSpellbook()
	return nil
end

function CExtEntity:RefreshLoadout()
	return nil
end

function CExtEntity:IsTargetDetected(hEntity)
	return true
end

function CExtEntity:OnEntityRefresh()
	self:RefreshEntity()
end

function CExtEntity:OnAttributesConfirm(args)
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

function CExtEntity:Interact(hEntity)
	if not self:HasModifier("modifier_internal_corpse_state") then
		return false
	elseif self:IsRevivable() and self:GetTeamNumber() == hEntity:GetTeamNumber() then
		--TODO: Implement revives for friendly party members/revivable units
		return true
	end
end

function CExtEntity:InteractFilterExclude(hEntity)
	return not self:IsAlive() and hEntity:IsRealHero()
end

function CExtEntity:GetCustomInteractError(hEntity)
end

function IsValidExtendedEntity(hEntity)
    return (IsValidInstance(hEntity) and IsValidEntity(hEntity) and hEntity._bIsExtendedEntity == true)
end

function RemoveEntity(hEntity)
    if IsValidExtendedEntity(hEntity) then
	    hEntity:RemoveEntity()
	end
end

end