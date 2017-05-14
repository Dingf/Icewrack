--[[
    Icewrack Spellbook
]]

if not CSpellbook then

require("timer")
require("mechanics/combat")
require("ext_entity")
require("ext_ability")
require("ext_modifier")

IW_SPELLBOOK_BIND_SLOTS = 10

local function GetSpellbook(self)
	return self._hSpellbook
end

stAbilityComboData = LoadKeyValues("scripts/npc/npc_abilities_combo.txt")

CSpellbook = setmetatable({ _stAbilityCombos = {} }, { __call = 
	function(self, hEntity)
		LogAssert(IsValidExtendedEntity(hEntity), "Type mismatch (expected \"%s\", got %s)", "CExtEntity", type(hEntity))
		if hEntity._hSpellbook and hEntity._hSpellbook._bIsSpellbook then
			return hEntity._hSpellbook
		end
		
		self = setmetatable({}, {__index =
		function(self, k)
			return CSpellbook[k] or nil
		end})
		
		hEntity._hSpellbook = self
		hEntity.GetSpellbook = GetSpellbook
		hEntity.FindAbilityByName = Dynamic_Wrap(CSpellbook, "FindAbilityByName")
		if IsValidExtendedEntity(hEntity) then
			table.insert(hEntity._tRefreshList, self)
		end
		
		self._bIsSpellbook = true
		self._hEntity = hEntity
		
		self._tSpellList = {}
		self._tSpellUnits = {}
		
		self._tCooldownList = {}
		
		self._tNetTable = {}
		self._tNetTable.Spells = {}
		self._tNetTable.Binds = {}
		
		self._tBindTable = {}
		for i = 1,IW_SPELLBOOK_BIND_SLOTS do
			self._tBindTable[i] = -1
		end
		
		self:UpdateNetTable()
		return self
	end})

CSpellbook.CallWrapper = function(self, keys) if keys.entindex then CSpellbook(EntIndexToHScript(keys.entindex)) end end
ListenToGameEvent("iw_ext_entity_load", Dynamic_Wrap(CSpellbook, "CallWrapper"), CSpellbook)
ListenToGameEvent("iw_ability_combo", Dynamic_Wrap(CSpellbook, "OnAbilityCombo"), CSpellbook)
ListenToGameEvent("iw_actionbar_bind", Dynamic_Wrap(CSpellbook, "OnAbilityBind"), CSpellbook)
CustomGameEventManager:RegisterListener("iw_actionbar_bind", Dynamic_Wrap(CSpellbook, "OnAbilityBind"))

function CSpellbook:GetKnownAbilities()
	return self._tSpellList
end

function CSpellbook:FindAbilityByName(szAbilityName)
	local hEntity = IsValidExtendedEntity(self) and self or self._hEntity
	local hSpellUnit = hEntity._hSpellbook._tSpellList[szAbilityName]
	if hSpellUnit then
		return hSpellUnit:FindAbilityByName(szAbilityName)
	end
	return CDOTA_BaseNPC.FindAbilityByName(hEntity, szAbilityName)
end

function CSpellbook:UpdateNetTable()
	if self._bIsSpellbook then
		local tNetTable = self._tNetTable
		for k,v in pairs(tNetTable.Spells) do
			local hAbility = EntIndexToHScript(k)
			v.stamina = hAbility:GetStaminaCost()
		end
		CustomNetTables:SetTableValue("spellbook", tostring(self._hEntity:entindex()), tNetTable);
	end
	CustomNetTables:SetTableValue("spellbook", "combos", CSpellbook._stAbilityCombos);
end

function CSpellbook:OnEntityRefresh()
	local hEntity = self._hEntity
	for k,v in pairs(self._tSpellList) do
		local hAbility = v:FindAbilityByName(k)
		if hAbility:CheckSkillRequirements(hEntity) then
			hAbility:SetActivated(true)
			hAbility:ApplyModifiers(hEntity, IW_MODIFIER_ON_ACQUIRE)
		else
			hAbility:SetActivated(false)
			hAbility:RemoveModifiers(hEntity, IW_MODIFIER_ON_ACQUIRE)
		end
	end
	self:UpdateNetTable()
end

function CSpellbook:UnlearnAbility(szAbilityName)
	if self._tSpellList[szAbilityName] then
		local hAbility = self._tSpellList[szAbilityName]:FindAbilityByName(szAbilityName)
		if hAbility then
			local nAbilityIndex = hAbility:entindex()
			for k,v in pairs(self._tBindTable) do
				if v == nAbilityIndex then
					self._tBindTable[k] = -1
					self._tNetTable.Binds[k] = nil
				end
			end
			if hAbility:GetToggleState() then
				hAbility:ToggleAbility()
			end
			hAbility:RemoveModifiers(IW_MODIFIER_ON_ACQUIRE)
			self:UpdateNetTable()
		end
		self._tSpellList[szAbilityName]:RemoveAbility(szAbilityName)
		self._tSpellList[szAbilityName] = nil
		
		for k,v in pairs(self._tNetTable.Spells) do
			if EntIndexToHScript(k):GetAbilityName() == szAbilityName then
				table.remove(self._tNetTable.Spells, k)
				break
			end
		end
		self:UpdateNetTable()
		return true
	end
	return false
end

function CSpellbook:LearnAbility(szAbilityName, nLevel)
	local hEntity = self._hEntity
	local hSpellUnit = nil
	if szAbilityName and nLevel and not self._tSpellList[szAbilityName] then
		local hOwner = hEntity:GetOwner()
		for k,v in pairs(self._tSpellUnits) do
			for i = 0,15 do
				if not v:GetAbilityByIndex(i) then
					hSpellUnit = v
					break
				end
			end
			if hSpellUnit then
				break
			end
		end
		
		if not hSpellUnit then
			hSpellUnit = CreateDummyUnit(hEntity:GetAbsOrigin(), hOwner, hEntity:GetTeamNumber())
			table.insert(self._tSpellUnits, hSpellUnit)
		end
		hSpellUnit:AddAbility(szAbilityName)
		local hAbility = hSpellUnit:FindAbilityByName(szAbilityName)
		if IsInstanceOf(hAbility, CDOTA_Ability_Lua) then
			local hAbility = CExtAbility(hAbility)
			hAbility:SetCaster(hEntity)
			hAbility:SetLevel(nLevel)
			hAbility:SetOwner(hEntity)
			self._tSpellList[szAbilityName] = hSpellUnit
			self._tNetTable.Spells[hAbility:entindex()] =
			{
				skills = hAbility:GetSkillRequirements(),
				stamina = hAbility:GetStaminaCost(),
			}
			self:UpdateNetTable()
			return hAbility
		else
			hSpellUnit:RemoveAbility(szAbilityName)
			LogMessage("Tried to add non-lua ability \"" .. szAbilityName .. "\" to spellbook of entity " .. hEntity:entindex() .. "(" .. hEntity:GetUnitName() .. ")", LOG_SEVERITY_WARNING)
		end
	elseif self._tSpellList[szAbilityName] then
		hSpellUnit = self._tSpellList[szAbilityName]
		local hAbility = hSpellUnit:FindAbilityByName(szAbilityName)
		if hAbility then
			hAbility:SetLevel(nLevel)
			self:UpdateNetTable()
			return hAbility
		end
	end
end

function CSpellbook:OnAbilityBind(args)
	local hEntity = EntIndexToHScript(args.entindex)
	local hSpellbook = hEntity:GetSpellbook()
	if IsValidExtendedEntity(hEntity) and hSpellbook and hSpellbook._tBindTable[args.slot] and not GameRules:IsInCombat() then
		local hAbility = EntIndexToHScript(args.ability)
		local szAbilityName = hAbility and hAbility:GetAbilityName() or ""
		local hSpellUnit = hSpellbook._tSpellList[szAbilityName]
		if args.ability == -1 or (hSpellUnit and hSpellUnit:FindAbilityByName(szAbilityName) == hAbility) then
			local tBindNetTable = hSpellbook._tNetTable.Binds
			if hSpellbook._tBindTable[args.slot] ~= -1 then
				local hOldAbility = EntIndexToHScript(hSpellbook._tBindTable[args.slot])
				if hOldAbility:GetToggleState() then
					hOldAbility:ToggleAbility()
				end
				hOldAbility:RemoveModifiers(IW_MODIFIER_ON_ACQUIRE)
			end
			hSpellbook._tBindTable[args.slot] = args.ability
			if hAbility then
				if hAbility:CheckSkillRequirements(hEntity) then
					hAbility:ApplyModifiers(hEntity, IW_MODIFIER_ON_ACQUIRE)
				end
				tBindNetTable[args.slot] = args.ability
			else
				tBindNetTable[args.slot] = nil
			end
			hSpellbook:UpdateNetTable()
		end
	end
end

function CSpellbook:OnAbilityCombo(args)
	local szAbilityName = args.name
	local tAbilityComboTemplate = stAbilityComboData[szAbilityName]
	if not CSpellbook._stAbilityCombos[szAbilityName] and tAbilityComboTemplate then
		local tAbilityComboData = {}
		for k,v in pairs(tAbilityComboTemplate) do
			local nIndex = tonumber(k)
			tAbilityComboData[nIndex] = {}
			for k2,v2 in pairs(v) do
				table.insert(tAbilityComboData[nIndex], v2)
			end
		end
		CSpellbook._stAbilityCombos[szAbilityName] = tAbilityComboData
		CSpellbook:UpdateNetTable()
	end
end

end