if not CExtAbility then

if _VERSION < "Lua 5.2" then
    bit = require("lib/numberlua")
    bit32 = bit.bit32
end

require("instance")
require("link_ext_ability")

local stBaseAbilityData = LoadKeyValues("scripts/npc/npc_abilities_custom.txt")
local stExtAbilityData = LoadKeyValues("scripts/npc/npc_abilities_extended.txt")

CExtAbility = setmetatable(ext_class({}), { __call = 
	function(self, hAbility, nInstanceID)
		LogAssert(IsInstanceOf(hAbility, CDOTABaseAbility), LOG_MESSAGE_ASSERT_TYPE, "CDOTABaseAbility", type(hAbility))
		if hAbility._bIsExtendedAbility then
			return hAbility
		end
		
		--TODO: Make it so that if there is no data, it stops loading and logs a warning like the others
		local szAbilityName = hAbility:GetAbilityName()
		local tBaseAbilityTemplate = stBaseAbilityData[szAbilityName] or {}
		local tExtAbilityTemplate = stExtAbilityData[szAbilityName] or {}
		if not tExtAbilityTemplate then
			return nil
		end
		
		hAbility = CInstance(hAbility, nInstanceID)
		ExtendIndexTable(hAbility, CExtAbility, CExtAbilityLinker)
		
		hAbility._tModifierList = {}
		hAbility._tActiveModifierList = {}
		hAbility._tModifierSeeds = {}
		local tModifierTemplate = tBaseAbilityTemplate.Modifiers or {}
		for k,v in pairs(tModifierTemplate) do
			hAbility._tModifierList[k] = stIcewrackModifierTriggers[v] or IW_MODIFIER_NO_TRIGGER
			hAbility._tModifierSeeds[k] = {}
			local hModifierTemplate = stExtModifierTemplates[k]
			if hModifierTemplate and hModifierTemplate.GetModifierSeedList then
				local tModifierSeedList = hModifierTemplate:GetModifierSeedList()
				for k2,v2 in pairs(tModifierSeedList) do
					hItem._tModifierSeeds[k][v2] = hItem:GetModifierSeed(k, v2)
				end
			end
		end
		
		hAbility._tAbilitySpecialTable = {}
		local tAbilitySpecial = tBaseAbilityTemplate.AbilitySpecial or {}
		for k,v in pairs(tAbilitySpecial) do
			for k2,v2 in pairs(v) do
				if k2 ~= "var_type" then
					hAbility._tAbilitySpecialTable[k2] = v2
					break
				end
			end
		end
		
		for k,v in pairs(hAbility._tPropertyList or {}) do
			local nPropertyID = stIcewrackPropertyEnum[k]
			if nPropertyID then
				hAbility:SetPropertyValue(nPropertyID, v)
			end
		end
		return hAbility
	end})

function CExtAbility:GetCaster()
	if IsServer() then
		return self._hOverrideCaster or CDOTABaseAbility.GetCaster(self)
	else
		return C_DOTABaseAbility.GetCaster(self)
	end
end

function CExtAbility:GetModifierSeed(szModifierName, nPropertyID)
	local tModifierSeeds = self._tModifierSeeds[szModifierName]
	if not tModifierSeeds[nPropertyID] then
		tModifierSeeds[nPropertyID] = RandomInt(0, 2147483647)
	end
	return tModifierSeeds[nPropertyID]
end

function CExtAbility:SetCaster(hEntity)
	if bit32.btest(self:GetAbilityFlags(), IW_ABILITY_FLAG_KEYWORD_SPELL) then
		self:RemoveChild(self:GetCaster())
		self:AddChild(hEntity)
	end
	self._hOverrideCaster = hEntity
	self:SetOwner(hEntity)
end

function CExtAbility:ApplyModifiers(nTrigger, hEntity)
	if not hEntity then hEntity = self:GetCaster() end
	for k,v in pairs(self._tModifierList) do
		if not nTrigger or v == nTrigger then
			local hModifier = nil
			if IsInstanceOf(self, CDOTA_Ability_Lua) then
				hModifier = hEntity:AddNewModifier(hEntity, self, k, self._tAbilitySpecialTable)
			else
				hModifier = self:ApplyDataDrivenModifier(hEntity, hEntity, k, self._tAbilitySpecialTable)
			end
			if hModifier then
				self._tActiveModifierList[hModifier] = v
			end
		end
	end
end

function CExtAbility:RemoveModifiers(nTrigger, hEntity)
	for k,v in pairs(self._tActiveModifierList) do
		if not nTrigger or v == nTrigger then
			if not hEntity or k:GetParent() == hEntity then
				k:Destroy()
				self._tActiveModifierList[k] = nil
			end
		end
	end
end

function IsLuaAbility(hAbility)
	return IsInstanceOf(hAbility, CDOTA_Ability_Lua)
end

function IsValidExtendedAbility(hAbility)
    return (IsValidEntity(hAbility) and IsInstanceOf(hAbility, CExtAbility))
end

local function ParseAbilitySpecialValues(tBaseTemplate)
	local tAbilitySpecialValues = {}
	for k,v in pairs(tBaseTemplate.AbilitySpecial or {}) do
		for k2,v2 in pairs(v) do
			if k2 ~= "var_type" then
				tAbilitySpecialValues[k2] = v2
				break
			end
		end
	end
	return tAbilitySpecialValues
end

local stAbilityNetTable = {}
for k,v in pairs(stExtAbilityData) do
	local tBaseAbilityTemplate = stBaseAbilityData[k]
	if tBaseAbilityTemplate then
		CExtAbilityLinker:LinkExtAbility(k, tBaseAbilityTemplate, v)
		if IsServer() then
			stAbilityNetTable[k] =
			{
				skill = v.AbilitySkill or 0,
				mana = v.ManaCost or 0,
				stamina = v.StaminaCost or 0,
				mana_upkeep = v.ManaUpkeep or 0,
				stamina_upkeep = v.StaminaUpkeep or 0,
				extflags = GetFlagValue(v.AbilityFlags, stExtAbilityFlagEnum),
				castrange = tBaseAbilityTemplate.AbilityCastRange or 0,
				radius = tBaseAbilityTemplate.AbilityAOERadius or 0,
				cooldown = tBaseAbilityTemplate.AbilityCooldown or 0,
				texture = tBaseAbilityTemplate.AbilityTextureName or k,
				behavior = GetFlagValue(tBaseAbilityTemplate.AbilityBehavior, DOTA_ABILITY_BEHAVIOR),
				targetflag = GetFlagValue(tBaseAbilityTemplate.AbilityUnitTargetFlags, DOTA_UNIT_TARGET_FLAGS),
				targettype = GetFlagValue(tBaseAbilityTemplate.AbilityUnitTargetType, DOTA_UNIT_TARGET_TYPE),
				targetteam = DOTA_UNIT_TARGET_TEAM[tBaseAbilityTemplate.AbilityUnitTargetTeam] or DOTA_UNIT_TARGET_TEAM_NONE,
				channeltime = tBaseAbilityTemplate.AbilityChannelTime or 0,
				special = ParseAbilitySpecialValues(tBaseAbilityTemplate),
			}
			CustomNetTables:SetTableValue("abilities", k, stAbilityNetTable[k])
		end
	end
end

end