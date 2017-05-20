if not CExtAbility then

if _VERSION < "Lua 5.2" then
    bit = require("lib/numberlua")
    bit32 = bit.bit32
end

require("instance")
require("link_ext_ability")

local stBaseAbilityData = LoadKeyValues("scripts/npc/npc_abilities_custom.txt")
local stExtAbilityData = LoadKeyValues("scripts/npc/npc_abilities_extended.txt")

local tIndexTableList = {}
CExtAbility = setmetatable({ _tIndexTableList = {} }, { __call = 
	function(self, hAbility, nInstanceID)
		LogAssert(IsInstanceOf(hAbility, CDOTABaseAbility), "Type mismatch (expected \"%s\", got %s)", "CDOTABaseAbility", type(hAbility))
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
		local tBaseIndexTable = getmetatable(hAbility).__index
		local tExtIndexTable = tIndexTableList[tBaseIndexTable]
		if not tExtIndexTable then
			tExtIndexTable = ExtendIndexTable(hAbility, CExtAbilityLinker, CExtAbility)
			tIndexTableList[tBaseIndexTable] = tExtIndexTable
		end
		setmetatable(hAbility, tExtIndexTable)
		
		hAbility._bIsExtendedAbility = true
		
		hAbility._tModifierList = {}
		hAbility._tActiveModifierList = {}
		hAbility._tModifierSeeds = {}
		local tModifierTemplate = tBaseAbilityTemplate.Modifiers or {}
		for k,v in pairs(tModifierTemplate) do
			hAbility._tModifierList[k] = stIcewrackModifierTriggers[v] or IW_MODIFIER_NO_TRIGGER
			hAbility._tModifierSeeds[k] = {}
		end
		
		for k,v in pairs(hAbility._tPropertyList or {}) do
			local nPropertyID = stIcewrackPropertyEnum[k] or stIcewrackPropertiesName[k]
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
	self:RemoveChild(self:GetCaster())
	self._hOverrideCaster = hEntity
	self:AddChild(hEntity)
end

function CExtAbility:ApplyModifiers(hEntity, nTrigger)
	for k,v in pairs(self._tModifierList) do
		if not nTrigger or v == nTrigger then
			local hModifier = nil
			if IsInstanceOf(self, CDOTA_Ability_Lua) then
				hModifier = hEntity:AddNewModifier(hEntity, self, k, {})
			else
				hModifier = self:ApplyDataDrivenModifier(hEntity, hEntity, k, {})
			end
			if hModifier then
				self._tActiveModifierList[hModifier] = v
			end
		end
	end
end

function CExtAbility:RemoveModifiers(nTrigger)
	for k,v in pairs(self._tActiveModifierList) do
		if not nTrigger or v == nTrigger then
			k:Destroy()
			self._tActiveModifierList[k] = nil
		end
	end
end

function IsLuaAbility(hAbility)
	return IsInstanceOf(hAbility, CDOTA_Ability_Lua)
end

function IsValidExtendedAbility(hAbility)
    return (IsValidInstance(hAbility) and IsValidEntity(hAbility) and hAbility._bIsExtendedAbility)
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
				extflags = GetFlagValue(v.AbilityFlags, stExtAbilityFlagEnum),
				castrange = tBaseAbilityTemplate.AbilityCastRange or 0,
				texture = tBaseAbilityTemplate.AbilityTextureName or k,
				behavior = GetFlagValue(tBaseAbilityTemplate.AbilityBehavior, DOTA_ABILITY_BEHAVIOR),
				targetflag = GetFlagValue(tBaseAbilityTemplate.AbilityUnitTargetFlags, DOTA_UNIT_TARGET_FLAGS),
				targettype = GetFlagValue(tBaseAbilityTemplate.AbilityUnitTargetType, DOTA_UNIT_TARGET_TYPE),
				targetteam = DOTA_UNIT_TARGET_TEAM[tBaseAbilityTemplate.AbilityUnitTargetTeam] or DOTA_UNIT_TARGET_TEAM_NONE,
			}
			CustomNetTables:SetTableValue("abilities", k, stAbilityNetTable[k])
		end
	end
end

end