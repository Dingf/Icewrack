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
require("instance")

local stExtEntityUnitClassEnum =
{  
    IW_UNIT_CLASS_CRITTER = 1,  IW_UNIT_CLASS_NORMAL = 2, IW_UNIT_CLASS_VETERAN = 3, IW_UNIT_CLASS_ELITE = 4, IW_UNIT_CLASS_BOSS = 5,
	IW_UNIT_CLASS_ACT_BOSS = 6, IW_UNIT_CLASS_HERO = 7,
}

local stExtEntityUnitTypeEnum =
{
	IW_UNIT_TYPE_NONE = 0,
    IW_UNIT_TYPE_MELEE = 1,
	IW_UNIT_TYPE_RANGED = 2,
	IW_UNIT_TYPE_MAGIC = 3,
}

local stExtEntityUnitSubtypeEnum =
{
    IW_UNIT_SUBTYPE_NONE = 0,       IW_UNIT_SUBTYPE_BIOLOGICAL = 1, IW_UNIT_SUBTYPE_MECHANICAL = 2, IW_UNIT_SUBTYPE_ETHEREAL = 3,
	IW_UNIT_SUBTYPE_ELEMENTAL = 4,  IW_UNIT_SUBTYPE_UNDEAD = 5,     IW_UNIT_SUBTYPE_DEMON = 6,
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

local stExtEntityAlignment =
{
	IW_ALIGNMENT_LAWFUL_GOOD = 1,
	IW_ALIGNMENT_NEUTRAL_GOOD = 2,
	IW_ALIGNMENT_CHAOTIC_GOOD = 3,
	IW_ALIGNMENT_LAWFUL_NEUTRAL = 4,
	IW_ALIGNMENT_TRUE_NEUTRAL = 5,
	IW_ALIGNMENT_CHAOTIC_NEUTRAL = 6,
	IW_ALIGNMENT_LAWFUL_EVIL = 7,
	IW_ALIGNMENT_NEUTRAL_EVIL = 8,
	IW_ALIGNMENT_CHAOTIC_EVIL = 9,
}

local stExtEntityFlagEnum =
{
    IW_UNIT_FLAG_NONE = 0,
	IW_UNIT_FLAG_MASSIVE = 1,
	IW_UNIT_FLAG_FLYING = 2,
	IW_UNIT_FLAG_NO_CORPSE = 4,
	--IW_UNIT_FLAG_REQ_ATTACK_SOURCE = 8
}

for k,v in pairs(stExtEntityUnitClassEnum) do _G[k] = v end
for k,v in pairs(stExtEntityUnitTypeEnum) do _G[k] = v end
for k,v in pairs(stExtEntityUnitSubtypeEnum) do _G[k] = v end
for k,v in pairs(stExtEntityFlagEnum) do _G[k] = v end
	
--local shItemHealthModifier = CreateItem("mod_health", nil, nil)
--local shItemManaModifier = CreateItem("mod_mana", nil, nil)
--local shItemIASModifier = CreateItem("mod_ias", nil, nil)

local shItemAttackModifier = CreateItem("internal_attack", nil, nil)
local shItemStaminaModifier = CreateItem("internal_stamina", nil, nil)
local shItemMovementNoise = CreateItem("internal_movement_noise", nil, nil)
local shItemAttributeModifier = CreateItem("internal_attribute_bonus", nil, nil)
local shItemSkillModifier = CreateItem("internal_skill_bonus", nil, nil)
--local shItemVisibilityModifier = CreateItem("internal_visibility", nil, nil)

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
		LogAssert(tExtEntityTemplate, "Failed to load template \"%d\" - no data exists for this entry.", hEntity:GetUnitName())
		
		hEntity = CInstance(hEntity, nInstanceID)
		local tBaseIndexTable = getmetatable(hEntity).__index
		local tExtIndexTable = tIndexTableList[tBaseIndexTable]
		if not tExtIndexTable then
			tExtIndexTable = ExtendIndexTable(hEntity, CExtEntity)
			tIndexTableList[tBaseIndexTable] = tExtIndexTable
		end
		setmetatable(hEntity, tExtIndexTable)
		
		--local tBaseMetatable = setmetatable({}, { __index = getmetatable(hEntity).__index } )
		--for k,v in pairs(CExtEntity) do tBaseMetatable[k] = v end
		--setmetatable(hEntity, { __index = tBaseMetatable })
		
		hEntity._bIsExtendedEntity = true
		hEntity._nUnitClass   = stExtEntityUnitClassEnum[tExtEntityTemplate.UnitClass] or IW_UNIT_CLASS_NORMAL
		hEntity._nUnitType 	  = stExtEntityUnitTypeEnum[tExtEntityTemplate.UnitType] or 0
		hEntity._nUnitSubtype = stExtEntityUnitSubtypeEnum[tExtEntityTemplate.UnitSubtype] or IW_UNIT_SUBTYPE_NONE
		hEntity._nUnitFlags   = GetFlagValue(tExtEntityTemplate.UnitFlags or "", stExtEntityFlagEnum)
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
		hEntity._tAttackSourceTable = {}
		
		hEntity._tOrderTable = { UnitIndex = hEntity:entindex() }
		hEntity._tExtModifierTable = {}
		
		hEntity._bRunMode = true
		hEntity._fStamina = hEntity:GetMaxStamina()
		hEntity._fStaminaRegenTime = 0.0
		hEntity._fLastStaminaPercent = 1.0
		hEntity._fLastMaxStamina = hEntity:GetMaxStamina()
		
		hEntity._fLifestealRegen = 0

		if GameRules:GetMapInfo():IsInside() then
			local fVisionMultiplier = 1.0 - (1.0 - GameRules:GetMapInfo():GetMapVisionMultiplier()) * (1.0 - hEntity:GetPropertyValueClamped(IW_PROPERTY_NIGHT_VISION, 0.0, 1.0))
			hEntity:SetDayTimeVisionRange(hEntity:GetDayTimeVisionRange() * fVisionMultiplier)
			hEntity:SetNightTimeVisionRange(hEntity:GetNightTimeVisionRange() * fVisionMultiplier)
		else
			local fVisionMultiplier = 1.0 - 0.5 * (1.0 - hEntity:GetPropertyValueClamped(IW_PROPERTY_NIGHT_VISION, 0.0, 1.0))
			hEntity:SetDayTimeVisionRange(hEntity:GetDayTimeVisionRange() * fVisionMultiplier)
			hEntity:SetNightTimeVisionRange(hEntity:GetNightTimeVisionRange() * fVisionMultiplier)
		end
		
		hEntity:AddNewModifier(hEntity, shItemAttackModifier, "modifier_internal_attack", {})
		hEntity:AddNewModifier(hEntity, shItemStaminaModifier, "modifier_internal_stamina", {})
		hEntity:AddNewModifier(hEntity, shItemAttributeModifier, "modifier_internal_attribute_bonus", {})
		hEntity:AddNewModifier(hEntity, shItemMovementNoise, "modifier_internal_movement_noise", {})
		
		if hEntity:IsRealHero() then
			hEntity:SetThink(function() hEntity:AddNewModifier(hEntity, shItemSkillModifier, "modifier_internal_skill_bonus", {}) end, "EntitySkillBonusThink", 0.03)
		end
		
		if tExtEntityTemplate.IsPlayableHero == 1 then
			hEntity._tNetTable =
			{
				attack_source = {},
				current_action = "",
				stamina = hEntity._fStamina,
				stamina_max = hEntity:GetMaxStamina(),
				stamina_time = hEntity._fStaminaRegenTime,
				fatigue = hEntity:GetFatigueMultiplier(),	--This could be calculated client-side, but its much more efficient to just put it here
				properties_base = {},
				properties_bonus = {},
			}
			hEntity:SetThink("CurrentActionThink", hEntity, "CurrentAction", 0.03)
		end
		
		hEntity._tRefreshList = {}
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
	return self._nUnitFlags
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

function CExtEntity:IsMassive()
	return bit32.btest(self._nUnitFlags, IW_UNIT_FLAG_MASSIVE)
end

function CExtEntity:IsFlying()
	return bit32.btest(self._nUnitFlags, IW_UNIT_FLAG_FLYING)
end


function CExtEntity:UpdateNetTable(bSkipProperties)
	if self._tNetTable then
		if not bSkipProperties then
			self:SetPropertyValue(IW_PROPERTY_ATK_SPEED_DUMMY, self:GetIncreasedAttackSpeed() * 100)		--Only used for clientside display, since Panorama truncates to int
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
		local nLevelDiff = self:GetLevel() - nOldLevel
		if nLevelDiff > 0 then
			for k,v in pairs(stIcewrackAttributeEnum) do
				self:SetPropertyValue(v + 1, self:GetBasePropertyValue(v + 1) + nLevelDiff)
			end
			self:SetPropertyValue(IW_PROPERTY_ATTRIBUTE_POINTS, self:GetBasePropertyValue(IW_PROPERTY_ATTRIBUTE_POINTS) + (nLevelDiff * 6))
			self:SetPropertyValue(IW_PROPERTY_SKILL_POINTS, self:GetBasePropertyValue(IW_PROPERTY_SKILL_POINTS) + nLevelDiff)
			self:RefreshEntity()
		end
	end
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

function CExtEntity:AddAttackSource(hSource)
	if IsValidInstance(hSource) then
		table.insert(self._tAttackSourceTable, hSource)
		if self._tNetTable then
			table.insert(self._tNetTable.attack_source, hSource:entindex())
			self:UpdateNetTable(true)
		end
	end
end

function CExtEntity:RemoveAttackSource(hSource)
	if type(hSource) == "number" and self._tAttackSource[hSource] then
		table.remove(self._tAttackSourceTable, hSource)
		if self._tNetTable then
			table.remove(self._tNetTable.attack_source, hSource)
			self:UpdateNetTable(true)
		end
	elseif IsValidInstance(hSource) then
		for k,v in pairs(self._tAttackSourceTable) do
			if v == hSource then
				table.remove(self._tAttackSourceTable, k)
				if self._tNetTable then
					table.remove(self._tNetTable.attack_source, k)
					self:UpdateNetTable(true)
				end
			end
		end
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
	local fManaRegenPerSec = self:GetPropertyValue(IW_PROPERTY_MP_REGEN_FLAT) + (self:GetAttributeValue(IW_ATTRIBUTE_WISDOM) * 0.025)
	fManaRegenPerSec = fManaRegenPerSec + (self:GetPropertyValue(IW_PROPERTY_MAX_MP_REGEN)/100.0 * self:GetMaxHealth())
	fManaRegenPerSec = fManaRegenPerSec * (1.0 + self:GetPropertyValue(IW_PROPERTY_MP_REGEN_PCT)/100)
	self:SetBaseManaRegen(math.max(0, fManaRegenPerSec))
end

function CExtEntity:RefreshMovementSpeed()
	local fMovementSpeed = self:GetPropertyValue(IW_PROPERTY_MOVE_SPEED_FLAT)
	if self._bRunMode then
		fMovementSpeed = fMovementSpeed + (self:GetAttributeValue(IW_ATTRIBUTE_AGILITY) * 1.0)
	else
		fMovementSpeed = fMovementSpeed * 0.5
	end
	fMovementSpeed = fMovementSpeed * (self:GetFatigueMultiplier() + self:GetPropertyValue(IW_PROPERTY_MOVE_SPEED_PCT)/100)
	self:SetBaseMoveSpeed(math.max(100, fMovementSpeed))
end

function CExtEntity:SetRunMode(bRunMode)
	if type(bRunMode) == "boolean" then
		self._bRunMode = bRunMode
		self:RefreshMovementSpeed()
	end
end

function CExtEntity:ToggleRunMode()
	self._bRunMode = (not self._bRunMode)
	self:RefreshMovementSpeed()
end

function CExtEntity:SetStamina(fStamina)
	self._fStamina = math.max(0, math.min(self:GetMaxStamina(), fStamina))
end

function CExtEntity:SpendStamina(fStamina)
	if fStamina >= 0 then
		self._fStamina = math.max(0, self:GetStamina() - fStamina)
		self._fStaminaRegenTime = math.max(self._fStaminaRegenTime, GameRules:GetGameTime() + 3.0)
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
	for k,v in pairs(self._tExtModifierTable) do v:RefreshModifier() end
	--[[if bit32.band(self._nUnitFlags, IW_UNIT_FLAG_REQ_ATTACK_SOURCE) ~= 0 then
		local bHasAttackSource = next(self._tAttackSourceTable)
		if not bHasAttackSource and not self:HasModifier("modifier_internal_disarm") then
			shItemDisarmModifier:ApplyDataDrivenModifier(self, self, "modifier_internal_disarm", {})
		elseif bHasAttackSource and self:HasModifier("modifier_internal_disarm") then
			self:RemoveModifierByName("modifier_internal_disarm")
		end
	end]]
	
	self:RefreshHealthRegen()
	self:RefreshManaRegen()
	self:RefreshMovementSpeed()
	self:SetAcquisitionRange(self:GetAttackRange())
	
	self:SetBaseMagicalResistanceValue(self:GetFatigueMultiplier())		--Hack to get fatigue multiplier on client side lua without nettables
	
	self:UpdateNetTable()
	for k,v in pairs(self._tRefreshList) do
		v:OnEntityRefresh()
	end
end

function CExtEntity:RemoveEntity()
	for k,v in pairs(self._tExtModifierTable) do
		v:Destroy()
	end
	self:RemoveSelf()
end

function CExtEntity:GetAutomator()
	return nil
end

function CExtEntity:GetSpellbook()
	return nil
end

function CExtEntity:GetInventory()
	return nil
end

function CExtEntity:RefreshLoadout()
	return nil
end

function CExtEntity:IsTargetDetected(hEntity)
	return true
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
			if nSpentPoints <= nSkillPoints then
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

function IsValidExtendedEntity(hEntity)
    return (IsValidInstance(hEntity) and IsValidEntity(hEntity) and hEntity._bIsExtendedEntity == true)
end

function RemoveEntity(hEntity)
    if IsValidExtendedEntity(hEntity) then
	    hEntity:RemoveEntity()
	end
end

end