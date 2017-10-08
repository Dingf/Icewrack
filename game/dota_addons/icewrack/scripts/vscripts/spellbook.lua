--[[
    Icewrack Spellbook
]]

if not CSpellbook then

require("mechanics/combat")
require("ext_ability")
require("ext_modifier")

IW_SPELLBOOK_BIND_SLOTS = 10

stAbilityComboData = LoadKeyValues("scripts/npc/npc_abilities_combo.txt")

CSpellbook = setmetatable({ _stAbilityCombos = {} }, { __call = 
	function(self, hEntity)
		LogAssert(IsInstanceOf(hEntity, CDOTA_BaseNPC), LOG_MESSAGE_ASSERT_TYPE, "CDOTA_BaseNPC", type(hEntity))
		if hEntity._hSpellbook and hEntity._hSpellbook._bIsSpellbook then
			return hEntity._hSpellbook
		end
		
		self = setmetatable({}, {__index =
		function(self, k)
			return CSpellbook[k] or nil
		end})
		
		self._bIsSpellbook = true
		self._hEntity = hEntity
		
		self._tSpellList = {}
		self._tSpellUnits = {}
		
		self._tCooldownList = {}
		
		self._tNetTable = {}
		self._tNetTable.Spells = {}
		self._tNetTable.SpellList = {}
		self._tNetTable.Binds = {}
		
		self._tBindTable = {}
		for i = 1,IW_SPELLBOOK_BIND_SLOTS do
			self._tBindTable[i] = -1
		end
		
		self:UpdateNetTable()
		return self
	end})


function CSpellbook:GetKnownAbilities()
	return self._tSpellList
end

function CSpellbook:FindAbilityByName(szAbilityName)
	local hSpellUnit = self._tSpellList[szAbilityName]
	if hSpellUnit then
		return hSpellUnit:FindAbilityByName(szAbilityName)
	end
	return CDOTA_BaseNPC.FindAbilityByName(self._hEntity, szAbilityName)
end

function CSpellbook:GetAbility(szAbilityName)
	local hSpellUnit = self._tSpellList[szAbilityName]
	if hSpellUnit then
		return hSpellUnit:FindAbilityByName(szAbilityName)
	end
end

function CSpellbook:UpdateNetTable()
	if self._bIsSpellbook then
		local tNetTable = self._tNetTable
		for k,v in pairs(tNetTable.Spells) do
			local hAbility = EntIndexToHScript(k)
			v.stamina = hAbility:GetStaminaCost()
			v.mana_upkeep = hAbility:GetManaUpkeep()
			v.stamina_upkeep = hAbility:GetStaminaUpkeep()
		end
		CustomNetTables:SetTableValue("spellbook", tostring(self._hEntity:entindex()), tNetTable);
	end
	CustomNetTables:SetTableValue("spellbook", "combos", CSpellbook._stAbilityCombos);
end

function CSpellbook:OnEntityRefresh()
	self:UpdateNetTable()
end

function CSpellbook:UnlearnAbility(szAbilityName)
	local hEntity = self._hEntity
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
			hAbility:RemoveModifiers(IW_MODIFIER_ON_ACQUIRE, hEntity)
			hAbility:RemoveModifiers(IW_MODIFIER_ON_LEARN, hEntity)
			self:UpdateNetTable()
		end
		self._tSpellList[szAbilityName]:RemoveAbility(szAbilityName)
		self._tSpellList[szAbilityName] = nil
		
		self._tNetTable.SpellList[szAbilityName] = nil
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

function CSpellbook:LearnAbility(szAbilityName, nLevel, nInstanceID)
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
		local hAbility = CExtAbility(hSpellUnit:FindAbilityByName(szAbilityName), nInstanceID)
		if IsInstanceOf(hAbility, CDOTA_Ability_DataDriven) then
			hSpellUnit:RemoveAbility(szAbilityName)
			return
		else
			hAbility:SetCaster(hEntity)
			hAbility:SetLevel(nLevel)
			hAbility:SetOwner(hEntity)
			self._tSpellList[szAbilityName] = hSpellUnit
			self._tNetTable.SpellList[szAbilityName] = hAbility:entindex()
			self._tNetTable.Spells[hAbility:entindex()] =
			{
				skill = hAbility:GetSkillRequirements(),
				stamina = hAbility:GetStaminaCost(),
				mana_upkeep = hAbility:GetManaUpkeep(),
				stamina_upkeep = hAbility:GetStaminaUpkeep(),
			}
			self:UpdateNetTable()
			hAbility:ApplyModifiers(IW_MODIFIER_ON_LEARN, hEntity)
			hAbility:OnAbilityLearned()
			return hAbility
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
	if hSpellbook and not GameRules:IsInCombat() then
		local hAbility = EntIndexToHScript(args.ability)
		local szAbilityName = hAbility and hAbility:GetAbilityName() or ""
		local hSpellUnit = hSpellbook._tSpellList[szAbilityName]
		if args.ability == -1 or (hSpellUnit and hSpellUnit:FindAbilityByName(szAbilityName) == hAbility) then
			local tBindNetTable = hSpellbook._tNetTable.Binds
			local nLastAbilityIndex = hSpellbook._tBindTable[args.slot]
			if nLastAbilityIndex ~= -1 and nLastAbilityIndex ~= args.ability then
				local hOldAbility = EntIndexToHScript(hSpellbook._tBindTable[args.slot])
				if hOldAbility:GetToggleState() then
					hOldAbility:ToggleAbility()
				elseif hOldAbility:GetAutoCastState() then
					hOldAbility:ToggleAutoCast()
				end
				hOldAbility:RemoveModifiers(IW_MODIFIER_ON_ACQUIRE, hEntity)
				hOldAbility:OnAbilityUnbind()
			end
			hSpellbook._tBindTable[args.slot] = args.ability
			if hAbility then
				if nLastAbilityIndex ~= args.ability and hAbility:CheckSkillRequirements(hEntity) then
					hAbility:ApplyModifiers(IW_MODIFIER_ON_ACQUIRE, hEntity)
					hAbility:OnAbilityBind()
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

ListenToGameEvent("iw_ability_combo", Dynamic_Wrap(CSpellbook, "OnAbilityCombo"), CSpellbook)
ListenToGameEvent("iw_actionbar_bind", Dynamic_Wrap(CSpellbook, "OnAbilityBind"), CSpellbook)
CustomGameEventManager:RegisterListener("iw_actionbar_bind", Dynamic_Wrap(CSpellbook, "OnAbilityBind"))

end