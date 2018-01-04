--[[
    Icewrack Extended Hero
]]

if not CExtHero then

require("ext_entity")
require("aam")

local shItemHoldModifier = CreateItem("item_internal_hold_position", nil, nil)

CExtHero = setmetatable(ext_class({}), { __call = 
	function(self, hEntity, nInstanceID)
		LogAssert(IsInstanceOf(hEntity, CDOTA_BaseNPC_Hero), LOG_MESSAGE_ASSERT_TYPE, "CDOTA_BaseNPC_Hero")
		if IsInstanceOf(hEntity, CExtHero) then
			LogMessage(LOG_MESSAGE_WARN_EXISTS, LOG_SEVERITY_WARNING, "CExtHero", hEntity:GetUnitName())
			return hEntity
		end

		if not IsInstanceOf(hEntity, CExtEntity) then
			hEntity = CExtEntity(hEntity, nInstanceID)
		end
		--hEntity = CAbilityAutomatorModule(hEntity)
		ExtendIndexTable(hEntity, CExtHero)
		
		hEntity._fTotalXP = 0
		hEntity._fLevelXP = 0
		hEntity._bRunMode = true
		hEntity._bHoldPosition = false
		
		hEntity._tNetTable =
		{
			attack_source = { Level = 0 },
			current_action = "",
			current_actionindex = -1,
			run_mode = hEntity._bRunMode,
			hold_position = hEntity._bHoldPosition,
			stamina_max = hEntity:GetMaxStamina(),
			properties_base = {},
			properties_bonus = {},
		}
		hEntity:SetThink("CurrentActionThink", hEntity, "CurrentAction", 0.03)

		return hEntity
	end})

function CExtHero:GetAbilityAutomator()
	return self._hAutomator
end

function CExtHero:GetTotalExperience()
	return self._fTotalXP
end

function CExtHero:GetCurrentLevelExperience()
	return self._fLevelXP
end

function CExtHero:GetCurrentAction()
	local hActiveAbility = self:GetCurrentActiveAbility()
	if hActiveAbility then
		return hActiveAbility:GetAbilityName(), hActiveAbility:entindex()
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

function CExtHero:IsRunning()
    return self._bRunMode
end

function CExtHero:IsHoldingPosition()
    return self._bHoldPosition
end

function CExtHero:AddAttackSource(hSource, nLevel)
	if IsValidInstance(hSource) and type(nLevel) == "number" and nLevel > 0 then
		local tAttackSourceNetTable = self._tNetTable.attack_source
		if not tAttackSourceNetTable[nLevel] then
			tAttackSourceNetTable[nLevel] = {}
		end
		
		local nHighestSourceLevel = tAttackSourceNetTable.Level
		if nLevel > nHighestSourceLevel then
			tAttackSourceNetTable.Level = nLevel
		end
		table.insert(tAttackSourceNetTable[nLevel], hSource:entindex())
		CExtEntity.AddAttackSource(self, hSource, nLevel)
	end
end

function CExtHero:RemoveAttackSource(hSource, nLevel)
	if type(nLevel) == "number" and self._tAttackSourceTable[nLevel] then
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
		return CExtEntity.RemoveAttackSource(self, hSource, nLevel)
	end
	return false
end

function CExtHero:SetRunMode(bRunMode)
	if type(bRunMode) == "boolean" then
		self._bRunMode = bRunMode
		self._tNetTable.run_mode = bRunMode
		self:RefreshMovementSpeed()
		self:UpdateEntityNetTable(true)
	end
end

function CExtHero:ToggleRunMode()
	self:SetRunMode(not self._bRunMode)
end

function CExtHero:SetHoldPosition(bHoldMode)
	if type(bHoldMode) == "boolean" then
		self._bHoldPosition = bHoldMode
		self._tNetTable.hold_position = bHoldMode
		if bHoldMode then
			shItemHoldModifier:ApplyDataDrivenModifier(self, self, "modifier_internal_hold_position", {})
		else
			self:RemoveModifierByName("modifier_internal_hold_position")
		end
		self:UpdateEntityNetTable(true)
	end
end

function CExtHero:ToggleHoldPosition()
	self:SetHoldPosition(not self._bHoldPosition)
end

--[[function CExtHero:FindAbilityByName(szAbilityName)
	local hSpellbook = self:GetSpellbook()
	if hSpellbook then
		return hSpellbook:FindAbilityByName(szAbilityName)
	end
	return CDOTA_BaseNPC.FindAbilityByName(self, szAbilityName)
end
]]
function CExtHero:UpdateEntityNetTable(bSkipProperties)
	if self._tNetTable then
		if not bSkipProperties then
			local tPropertiesBase = self._tNetTable.properties_base
			local tPropertiesBonus = self._tNetTable.properties_bonus
			for k,v in pairs(stIcewrackPropertyEnum) do
				tPropertiesBase[v] = self:GetBasePropertyValue(v)
				tPropertiesBonus[v] = self:GetPropertyValue(v) - tPropertiesBase[v]
			end
		end
		self._tNetTable.stamina = self._fStamina
		self._tNetTable.stamina_max = self:GetMaxStamina()
		CustomNetTables:SetTableValue("entities", tostring(self:entindex()), self._tNetTable)
	end
end

function CExtHero:AddExperience(fAmount)
	if fAmount > 0 then
		local nOldLevel = self:GetLevel()
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

function CExtHero:OnRefreshEntity()
	self:UpdateEntityNetTable(false)
end

function CExtHero:CurrentActionThink()
	if self._tNetTable then
		local szCurrentAction, nActionIndex = self:GetCurrentAction()
		if szCurrentAction ~= self._tNetTable.current_action then
			self._tNetTable.current_action = szCurrentAction
			self._tNetTable.current_actionindex = nActionIndex
			self:UpdateEntityNetTable(true)
		end
	end
	return 0.03
end

local CExtHeroEventHandler = {}
function CExtHeroEventHandler:OnAttributesConfirm(args)
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
		hEntity:RefreshHealthAndMana()
	end
end

function CExtHeroEventHandler:OnSkillsConfirm(args)
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
		hEntity:RefreshHealthAndMana()
	end
end

function CExtHeroEventHandler:OnToggleRun(args)
	local hEntity = EntIndexToHScript(args.entindex)
	if IsValidExtendedEntity(hEntity) and hEntity:IsControllableByAnyPlayer() then
		hEntity:ToggleRunMode()
	end
end

function CExtHeroEventHandler:OnToggleHold(args)
	local hEntity = EntIndexToHScript(args.entindex)
	if IsValidExtendedEntity(hEntity) and hEntity:IsControllableByAnyPlayer() then
		hEntity:ToggleHoldPosition()
	end
end

function IsValidExtendedHero(hEntity)
    return (IsValidExtendedEntity(hEntity) and IsInstanceOf(hEntity, CExtHero))
end
	
CustomGameEventManager:RegisterListener("iw_character_attributes_confirm", CExtHeroEventHandler.OnAttributesConfirm)
CustomGameEventManager:RegisterListener("iw_character_skills_confirm", CExtHeroEventHandler.OnSkillsConfirm)
CustomGameEventManager:RegisterListener("iw_toggle_run", CExtHeroEventHandler.OnToggleRun)
CustomGameEventManager:RegisterListener("iw_toggle_hold", CExtHeroEventHandler.OnToggleHold)

end