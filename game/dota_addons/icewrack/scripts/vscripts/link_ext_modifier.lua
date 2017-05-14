if IsServer() then
require("timer")
require("instance")
require("ext_modifier")
require("link_functions")
end

local stLuaModifierPropertyAliases =
{
	MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE = "GetModifierPreAttack_BonusDamage",
	MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE_POST_CRIT = "GetModifierPreAttack_BonusDamagePostCrit",
	MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE = "GetModifierBaseAttack_BonusDamage",
	MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PHYSICAL = "GetModifierProcAttack_BonusDamage_Physical",
	MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_MAGICAL = "GetModifierProcAttack_BonusDamage_Magical",
	MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PURE = "GetModifierProcAttack_BonusDamage_Pure",
	MODIFIER_PROPERTY_PROCATTACK_FEEDBACK = "GetModifierProcAttack_Feedback",
	MODIFIER_PROPERTY_PRE_ATTACK = "GetModifierPreAttack",
	MODIFIER_PROPERTY_INVISIBILITY_LEVEL = "GetModifierInvisibilityLevel",
	MODIFIER_PROPERTY_PERSISTENT_INVISIBILITY = "GetModifierPersistentInvisibility",
	MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT = "GetModifierMoveSpeedBonus_Constant",
	MODIFIER_PROPERTY_MOVESPEED_BASE_OVERRIDE = "GetModifierMoveSpeedOverride",
	MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE = "GetModifierMoveSpeedBonus_Percentage",
	MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE_UNIQUE = "GetModifierMoveSpeedBonus_Percentage_Unique",
	MODIFIER_PROPERTY_MOVESPEED_BONUS_UNIQUE = "GetModifierMoveSpeedBonus_Special_Boots",
	MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE = "GetModifierMoveSpeed_Absolute",
	MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE_MIN = "GetModifierMoveSpeed_AbsoluteMin",
	MODIFIER_PROPERTY_MOVESPEED_LIMIT = "GetModifierMoveSpeed_Limit",
	MODIFIER_PROPERTY_MOVESPEED_MAX = "GetModifierMoveSpeed_Max",
	MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT = "GetModifierAttackSpeedBonus_Constant",
	MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT_POWER_TREADS = "GetModifierAttackSpeedBonus_Constant_PowerTreads",
	MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT_SECONDARY = "GetModifierAttackSpeedBonus_Constant_Secondary",
	MODIFIER_PROPERTY_COOLDOWN_REDUCTION_CONSTANT = "GetModifierCooldownReduction_Constant",
	MODIFIER_PROPERTY_BASE_ATTACK_TIME_CONSTANT = "GetModifierBaseAttackTimeConstant",
	MODIFIER_PROPERTY_ATTACK_POINT_CONSTANT = "GetModifierAttackPointConstant",
	MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE = "GetModifierDamageOutgoing_Percentage",
	MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE_ILLUSION = "GetModifierDamageOutgoing_Percentage_Illusion",
	MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE = "GetModifierTotalDamageOutgoing_Percentage",
	MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE = "GetModifierBaseDamageOutgoing_Percentage",
	MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE_UNIQUE = "GetModifierBaseDamageOutgoing_PercentageUnique",
	MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE = "GetModifierIncomingDamage_Percentage",
	MODIFIER_PROPERTY_INCOMING_PHYSICAL_DAMAGE_PERCENTAGE = "GetModifierIncomingPhysicalDamage_Percentage",
	MODIFIER_PROPERTY_INCOMING_SPELL_DAMAGE_CONSTANT = "GetModifierIncomingSpellDamageConstant",
	MODIFIER_PROPERTY_EVASION_CONSTANT = "GetModifierEvasion_Constant",
	MODIFIER_PROPERTY_AVOID_DAMAGE = "GetModifierAvoidDamage",
	MODIFIER_PROPERTY_AVOID_SPELL = "GetModifierAvoidSpell",
	MODIFIER_PROPERTY_MISS_PERCENTAGE = "GetModifierMiss_Percentage",
	MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS = "GetModifierPhysicalArmorBonus",
	MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS_ILLUSIONS = "GetModifierPhysicalArmorBonusIllusions",
	MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS_UNIQUE = "GetModifierPhysicalArmorBonusUnique",
	MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS_UNIQUE_ACTIVE = "GetModifierPhysicalArmorBonusUniqueActive",
	MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS = "GetModifierMagicalResistanceBonus",
	MODIFIER_PROPERTY_MAGICAL_RESISTANCE_ITEM_UNIQUE = "GetModifierMagicalResistanceItemUnique",
	MODIFIER_PROPERTY_MAGICAL_RESISTANCE_DECREPIFY_UNIQUE = "GetModifierMagicalResistanceDecrepifyUnique",
	MODIFIER_PROPERTY_BASE_MANA_REGEN = "GetModifierBaseRegen",
	MODIFIER_PROPERTY_MANA_REGEN_CONSTANT = "GetModifierConstantManaRegen",
	MODIFIER_PROPERTY_MANA_REGEN_CONSTANT_UNIQUE = "GetModifierConstantManaRegenUnique",
	MODIFIER_PROPERTY_MANA_REGEN_PERCENTAGE = "GetModifierPercentageManaRegen",
	MODIFIER_PROPERTY_MANA_REGEN_TOTAL_PERCENTAGE = "GetModifierTotalPercentageManaRegen",
	MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT = "GetModifierConstantHealthRegen",
	MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE = "GetModifierHealthRegenPercentage",
	MODIFIER_PROPERTY_HEALTH_BONUS = "GetModifierHealthBonus",
	MODIFIER_PROPERTY_MANA_BONUS = "GetModifierManaBonus",
	MODIFIER_PROPERTY_EXTRA_STRENGTH_BONUS = "GetModifierExtraStrengthBonus",
	MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS = "GetModifierExtraHealthBonus",
	MODIFIER_PROPERTY_EXTRA_MANA_BONUS = "GetModifierExtraManaBonus",
	MODIFIER_PROPERTY_EXTRA_HEALTH_PERCENTAGE = "GetModifierExtraHealthPercentage",
	MODIFIER_PROPERTY_STATS_STRENGTH_BONUS = "GetModifierBonusStats_Strength",
	MODIFIER_PROPERTY_STATS_AGILITY_BONUS = "GetModifierBonusStats_Agility",
	MODIFIER_PROPERTY_STATS_INTELLECT_BONUS = "GetModifierBonusStats_Intellect",
	MODIFIER_PROPERTY_ATTACK_RANGE_BONUS = "GetModifierAttackRangeBonus",
	MODIFIER_PROPERTY_PROJECTILE_SPEED_BONUS = "GetModifierProjectileSpeedBonus",
	MODIFIER_PROPERTY_REINCARNATION = "ReincarnateTime",
	MODIFIER_PROPERTY_RESPAWNTIME = "GetModifierConstantRespawnTime",
	MODIFIER_PROPERTY_RESPAWNTIME_PERCENTAGE = "GetModifierPercentageRespawnTime",
	MODIFIER_PROPERTY_RESPAWNTIME_STACKING = "GetModifierStackingRespawnTime",
	MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE = "GetModifierPercentageCooldown",
	MODIFIER_PROPERTY_CASTTIME_PERCENTAGE = "GetModifierPercentageCasttime",
	MODIFIER_PROPERTY_MANACOST_PERCENTAGE = "GetModifierPercentageManacost",
	MODIFIER_PROPERTY_DEATHGOLDCOST = "GetModifierConstantDeathGoldCost",
	MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE = "GetModifierPreAttack_CriticalStrike",
	MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK = "GetModifierPhysical_ConstantBlock",
	MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK_UNAVOIDABLE_PRE_ARMOR = "GetModifierPhysical_ConstantBlockUnavoidablePreArmor",
	MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK = "GetModifierTotal_ConstantBlock",
	MODIFIER_PROPERTY_OVERRIDE_ANIMATION = "GetOverrideAnimation",
	MODIFIER_PROPERTY_OVERRIDE_ANIMATION_WEIGHT = "GetOverrideAnimationWeight",
	MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE = "GetOverrideAnimationRate",
	MODIFIER_PROPERTY_ABSORB_SPELL = "GetAbsorbSpell",
	MODIFIER_PROPERTY_REFLECT_SPELL = "GetReflectSpell",
	MODIFIER_PROPERTY_DISABLE_AUTOATTACK = "GetDisableAutoAttack",
	MODIFIER_PROPERTY_BONUS_DAY_VISION = "GetBonusDayVision",
	MODIFIER_PROPERTY_BONUS_NIGHT_VISION = "GetBonusNightVision",
	MODIFIER_PROPERTY_BONUS_NIGHT_VISION_UNIQUE = "GetBonusNightVisionUnique",
	MODIFIER_PROPERTY_BONUS_VISION_PERCENTAGE = "GetBonusVisionPercentage",
	MODIFIER_PROPERTY_FIXED_DAY_VISION = "GetFixedDayVision",
	MODIFIER_PROPERTY_FIXED_NIGHT_VISION = "GetFixedNightVision",
	MODIFIER_PROPERTY_MIN_HEALTH = "GetMinHealth",
	MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL = "GetAbsoluteNoDamagePhysical",
	MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL = "GetAbsoluteNoDamageMagical",
	MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE = "GetAbsoluteNoDamagePure",
	MODIFIER_PROPERTY_IS_ILLUSION = "GetIsIllusion",
	MODIFIER_PROPERTY_ILLUSION_LABEL = "GetModifierIllusionLabel",
	MODIFIER_PROPERTY_SUPER_ILLUSION = "GetModifierSuperIllusion",
	MODIFIER_PROPERTY_TURN_RATE_PERCENTAGE = "GetModifierTurnRate_Percentage",
	MODIFIER_PROPERTY_DISABLE_HEALING = "GetDisableHealing",
	MODIFIER_PROPERTY_OVERRIDE_ATTACK_MAGICAL = "GetOverrideAttackMagical",
	MODIFIER_PROPERTY_UNIT_STATS_NEEDS_REFRESH = "GetModifierUnitStatsNeedsRefresh",
	MODIFIER_PROPERTY_BOUNTY_CREEP_MULTIPLIER = "GetModifierBountyCreepMultiplier",
	MODIFIER_PROPERTY_BOUNTY_OTHER_MULTIPLIER = "GetModifierBountyOtherMultiplier",
	MODIFIER_PROPERTY_TOOLTIP = "OnTooltip",
	MODIFIER_PROPERTY_MODEL_CHANGE = "GetModifierModelChange",
	MODIFIER_PROPERTY_MODEL_SCALE = "GetModifierModelScale",
	MODIFIER_PROPERTY_IS_SCEPTER = "GetModifierScepter",
	MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS = "GetActivityTranslationModifiers",
	MODIFIER_PROPERTY_TRANSLATE_ATTACK_SOUND = "GetAttackSound",
	MODIFIER_PROPERTY_LIFETIME_FRACTION = "GetUnitLifetimeFraction",
	MODIFIER_PROPERTY_PROVIDES_FOW_POSITION = "GetModifierProvidesFOWVision",
	MODIFIER_PROPERTY_SPELLS_REQUIRE_HP = "GetModifierSpellsRequireHP",
	MODIFIER_PROPERTY_FORCE_DRAW_MINIMAP = "GetForceDrawOnMinimap",
	MODIFIER_PROPERTY_DISABLE_TURNING = "GetModifierDisableTurning",
	MODIFIER_PROPERTY_IGNORE_CAST_ANGLE = "GetModifierIgnoreCastAngle",
	MODIFIER_PROPERTY_CHANGE_ABILITY_VALUE = "GetModifierChangeAbilityValue",
	MODIFIER_PROPERTY_ABILITY_LAYOUT = "GetModifierAbilityLayout",
}

local stLuaModifierEventAliases = 
{
	MODIFIER_EVENT_ON_ATTACK_RECORD = "OnAttackRecord",
	MODIFIER_EVENT_ON_ATTACK_START = "OnAttackStart",
	MODIFIER_EVENT_ON_ATTACK = "OnAttack",
	MODIFIER_EVENT_ON_ATTACK_LANDED = "OnAttackLanded",
	MODIFIER_EVENT_ON_ATTACK_FAIL = "OnAttackFail",
	MODIFIER_EVENT_ON_ATTACK_ALLIED = "OnAttackAllied",
	MODIFIER_EVENT_ON_ATTACK_FINISHED = "OnAttackFinished",
	MODIFIER_EVENT_ON_PROJECTILE_DODGE = "OnProjectileDodge",
	MODIFIER_EVENT_ON_ORDER = "OnOrder",
	MODIFIER_EVENT_ON_UNIT_MOVED = "OnUnitMoved",
	MODIFIER_EVENT_ON_ABILITY_START = "OnAbilityStart",
	MODIFIER_EVENT_ON_ABILITY_EXECUTED = "OnAbilityExecuted",
	MODIFIER_EVENT_ON_ABILITY_FULLY_CAST = "OnAbilityFullyCast",
	MODIFIER_EVENT_ON_BREAK_INVISIBILITY = "OnBreakInvisibility",
	MODIFIER_EVENT_ON_ABILITY_END_CHANNEL = "OnAbilityEndChannel",
	MODIFIER_EVENT_ON_TAKEDAMAGE = "OnTakeDamage",
	MODIFIER_EVENT_ON_STATE_CHANGED = "OnStateChanged",
	MODIFIER_EVENT_ON_ATTACKED = "OnAttacked",
	MODIFIER_EVENT_ON_DEATH = "OnDeath",
	MODIFIER_EVENT_ON_RESPAWN = "OnRespawn",
	MODIFIER_EVENT_ON_SPENT_MANA = "OnSpentMana",
	MODIFIER_EVENT_ON_TELEPORTING = "OnTeleporting",
	MODIFIER_EVENT_ON_TELEPORTED = "OnTeleported",
	MODIFIER_EVENT_ON_SET_LOCATION = "OnSetLocation",
	MODIFIER_EVENT_ON_HEALTH_GAINED = "OnHealthGained",
	MODIFIER_EVENT_ON_MANA_GAINED = "OnManaGained",
	MODIFIER_EVENT_ON_TAKEDAMAGE_KILLCREDIT = "OnTakeDamageKillCredit",
	MODIFIER_EVENT_ON_HERO_KILLED = "OnHeroKilled",
	MODIFIER_EVENT_ON_HEAL_RECEIVED = "OnHealReceived",
	MODIFIER_EVENT_ON_BUILDING_KILLED = "OnBuildingKilled",
	MODIFIER_EVENT_ON_MODEL_CHANGED = "OnModelChanged",
	MODIFIER_EVENT_ON_CREATED = "OnModifierCreated",
	MODIFIER_EVENT_ON_DESTROY = "OnModifierDestroy",
	MODIFIER_EVENT_ON_REFRESH = "OnModifierRefresh",
	MODIFIER_EVENT_ON_INTERVAL_THINK = "OnIntervalThink",
}

local stLuaModifierIgnoredArgs =
{
	creationtime = true,
	unit = true,
	attacker = true,
	target = true,
	entity = true,
}

local tContext = getfenv()
local stExtModifierData = LoadKeyValues("scripts/npc/npc_modifiers_extended.txt")

local function ApplyPropertyValues(self)
	local hTarget = self:GetParent()
	if IsValidInstance(hTarget) then
		hTarget:AddChild(self)
		hTarget:UpdateNetTable()
	end
end

local function RemovePropertyValues(self)
	local hTarget = self:GetParent()
	if IsValidInstance(hTarget) then
		hTarget:RemoveChild(self)
		hTarget:UpdateNetTable()
	end
end

function RefreshModifier(self, bRerollRandom)
	RemovePropertyValues(self)
	for k,v in pairs(self._tPropertyList or {}) do
		local nPropertyID = stIcewrackPropertyEnum[k] or stIcewrackPropertiesName[k]
		if nPropertyID then
			local szPropertyType = type(v)
			if szPropertyType == "table" and (bRerollRandom or not rawget(self._tPropertyValues, nPropertyID)) then
				local k2,v2 = next(v)
				k2 = (type(k2) == "string" and string.sub(k2, 1, 1) == "%") and self._tModifierArgs[string.sub(k2, 2, #k2)] or tonumber(k2)
				v2 = (type(v2) == "string" and string.sub(v2, 1, 1) == "%") and self._tModifierArgs[string.sub(v2, 2, #v2)] or v2
				if k2 and type(k2) == "number" and v2 and type(v2) == "number" then
					local nModifierSeed = self:GetAbility():GetModifierSeed(self:GetName(), nPropertyID)
					self:SetPropertyValue(nPropertyID, k2 + (nModifierSeed % v2))
				end
			elseif szPropertyType == "number" then
				self:SetPropertyValue(nPropertyID, v)
			elseif szPropertyType == "string" and string.sub(v, 1, 1) == "%" then
				self:SetPropertyValue(nPropertyID, self._tModifierArgs[string.sub(v, 2, #v)])
			end
		end
	end
	self:OnRefresh()
	ApplyPropertyValues(self)
end

local function CullModifierStacks(self)
	local hParent = self:GetParent()
	if self._nMaxStacks > 0 or self._nMaxStacksPerCaster > 0 then
		local nGlobalStackCount = 0
		local nSourceStackCount = 0
		local hGlobalCullTarget = nil
		local hSourceCullTarget = nil
		for k,v in pairs(hParent._tExtModifierTable) do
			if v:GetName() == self:GetName() then
				if v:GetCaster() == self:GetCaster() then
					if not hSourceCullTarget or v:GetRemainingTime() < hSourceCullTarget:GetRemainingTime() then hSourceCullTarget = v end
					nSourceStackCount = nSourceStackCount + 1
				end
				if not hGlobalCullTarget or v:GetRemainingTime() < hGlobalCullTarget:GetRemainingTime() then hGlobalCullTarget = v end
				nGlobalStackCount = nGlobalStackCount + 1
			end
		end
		if self._nMaxStacksPerCaster > 0 and nSourceStackCount >= self._nMaxStacksPerCaster and hSourceCullTarget then
			hSourceCullTarget:Destroy()
			return hSourceCullTarget
		elseif self._nMaxStacks > 0 and nGlobalStackCount >= self._nMaxStacks and hGlobalCullTarget then
			hGlobalCullTarget:Destroy()
			return hGlobalCullTarget
		end
	end
	return nil
end

local function RecordModifierArgs(self, keys)
	for k,v in pairs(keys) do
		if not stLuaModifierIgnoredArgs[k] then
			local nPropertyID = k
			self._tModifierArgs[k] = v
			if type(self._tModifierArgs[k]) == "table" then
				local k2,v2 = next(self._tModifierArgs[k])
				k2 = tonumber(k2)
				v2 = tonumber(v2)
				if k2 and v2 then
					local nModifierSeed = self:GetAbility():GetModifierSeed(self:GetName(), nPropertyID)
					self._tModifierArgs[k] = k2 + (nModifierSeed % v2)
				end
			end
		end
	end
end

local function OnModifierCreatedDefault(self, keys)
	self._tModifierArgs = {}
	if not keys then keys = {} end
	
	local tDatadrivenPropertyTable = {}
	for k,v in pairs(self._tDatadrivenPropertyTable) do
		tDatadrivenPropertyTable[k] = v
	end
	self._tDatadrivenPropertyTable = tDatadrivenPropertyTable
	
	local hTarget = self:GetParent()
	if not IsServer() then
		local tModifierStringBuilder = {}
		local tModifierArgsTable = CustomNetTables:GetTableValue("modifier_args", self:GetName())
		if tModifierArgsTable then
			keys = tModifierArgsTable[tostring(self:RetrieveModifierID())]
			if keys then
				RecordModifierArgs(self, keys)
				for k,v in pairs(keys) do
					if k ~= "texture" and type(v) ~= "table" then
						table.insert(tModifierStringBuilder, k)
						table.insert(tModifierStringBuilder, "=")
						table.insert(tModifierStringBuilder, v)
						table.insert(tModifierStringBuilder, " ")
					end
				end
			end
		end
		table.insert(tModifierStringBuilder, "texture=")
		table.insert(tModifierStringBuilder, self._szTextureName)
		self._szTextureArgsString = table.concat(tModifierStringBuilder, "")
	elseif IsServer() and IsValidInstance(hTarget) then
		self = CExtModifier(CInstance(self))
		RecordModifierArgs(self, keys)
		local nModifierID = self:RetrieveModifierID()
		local szModifierName = self:GetName()
		local tNetTableModifierArgs = {}
		for k,v in pairs(keys) do
			if not stLuaModifierIgnoredArgs[k] then
				tNetTableModifierArgs[k] = v
			end
		end
		if next(tNetTableModifierArgs) ~= nil then
			--TODO: Investigate a better method of passing modifier args
			self._tModifierNetTable[nModifierID] = tNetTableModifierArgs
			CustomNetTables:SetTableValue("modifier_args", szModifierName, self._tModifierNetTable)
			CTimer(3.0, function() self._tModifierNetTable[nModifierID] = nil end)
		end
		
		if type(self._fDuration) == "table" and next(self._fDuration) then
			local k,v = next(self._fDuration)
			self:SetDuration((k > v) and RandomFloat(k, v) or RandomFloat(v, k), true)
		elseif type(self._fDuration) == "string" and string.sub(self._fDuration, 1, 1) == "%" then
			self:SetDuration(self._tModifierArgs[string.sub(self._fDuration, 2, #self._fDuration)], true)
		else
			self:SetDuration(self._fDuration, true)
		end
		
		CullModifierStacks(self)
		RefreshModifier(self)
		
		if IsValidExtendedEntity(hTarget) then
			if self:IsDebuff() then
				local hCaster = self:GetCaster()
				hCaster:SetAttacking(hTarget)
			end
			
			local tTargetModifierTable = hTarget._tExtModifierTable
			local fDuration = self:GetDuration()
			if fDuration > 0 then
				for k,v in pairs(tTargetModifierTable) do
					if v:GetRemainingTime() > fDuration then
						table.insert(tTargetModifierTable, k, self)
						hTarget:RefreshEntity()
						return
					end
				end
			end
			table.insert(tTargetModifierTable, self)
			hTarget:RefreshEntity()
		end
	end
end

local function OnModifierDestroyDefault(self)
	local hTarget = self:GetParent()
	if IsServer() and IsValidInstance(hTarget) then
		RemovePropertyValues(self)
		if IsValidExtendedEntity(hTarget) then
			local tTargetModifierTable = hTarget._tExtModifierTable
			for k,v in pairs(tTargetModifierTable) do
				if v == self then
					table.remove(tTargetModifierTable, k)
					break
				end
			end
			hTarget:RefreshEntity()
		end
		
		if self._hBuffDummy then self._hBuffDummy:RemoveSelf() end
	end
end

local function OnModifierRefreshDefault(self)
	local hTarget = self:GetParent()
	if IsServer() and hTarget:IsHero() then
		hTarget:CalculateStatBonus()
	end
end

function OnCreated(self, params)
	if not params.entity then
		params.entity = self:GetParent()
	end
	for k,v in ipairs(self._tOnCreatedList) do
		v(self, params)
	end
end

function OnDestroy(self)
	for k,v in ipairs(self._tOnDestroyList) do
		v(self)
	end
end

function OnRefresh(self)
	for k,v in ipairs(self._tOnRefreshList) do
		v(self)
	end
end

function GetTexture(self)
	return self._szTextureArgsString
end

local function ParseDatadrivenStates(hLuaModifier, tLinkLuaModifierTemplate)
	local tDatadrivenStates = tLinkLuaModifierTemplate.DatadrivenStates
	if tDatadrivenStates then
		hLuaModifier._tDatadrivenStateTable = {}
		for k,v in pairs(tDatadrivenStates) do
			local nKeyValue = _G[k]
			if string.find(k, "MODIFIER_STATE_") and nKeyValue then
				if v == "MODIFIER_STATE_VALUE_ENABLED" then
					hLuaModifier._tDatadrivenStateTable[nKeyValue] = true
				elseif v == "MODIFIER_STATE_VALUE_DISABLED" then
					hLuaModifier._tDatadrivenStateTable[nKeyValue] = false
				end
			end
		end
		if hLuaModifier.CheckState then
			hLuaModifier.OldCheckState = hLuaModifier.CheckState
			hLuaModifier.CheckState = function()
				local tBaseResults = hLuaModifier:OldCheckState()
				for k,v in pairs(tBaseResults or {}) do hLuaModifier._tDatadrivenStateTable[k] = v end
				return hLuaModifier._tDatadrivenStateTable
			end
		else
			hLuaModifier.CheckState = function() return hLuaModifier._tDatadrivenStateTable end
		end
	end
end

local function ParseDatadrivenProperties(hLuaModifier, tLinkLuaModifierTemplate)
	local tDatadrivenProperties = tLinkLuaModifierTemplate.DatadrivenProperties
	if tDatadrivenProperties then
		hLuaModifier._tDatadrivenPropertyTable = {}
		for k,v in pairs(tDatadrivenProperties) do
			local nPropertyID = _G[k]
			local szPropertyAlias = stLuaModifierPropertyAliases[k]
			if szPropertyAlias then
				if type(v) == "table" then
					table.insert(hLuaModifier._tDeclareFunctionList, nPropertyID)
					hLuaModifier._tDatadrivenPropertyTable[k] = {next(v)}
					hLuaModifier[szPropertyAlias] = function(self, params)
						local fValue = self._tDatadrivenPropertyTable[k][1]
						if (type(fValue) == "string" and string.sub(fValue, 1, 1) == "%") then
							fValue = self._tModifierArgs[string.sub(fValue, 2, #fValue)]
						else
							fValue = tonumber(fValue)
						end
									
						local fRange = self._tDatadrivenPropertyTable[k][2]
						if (type(fRange) == "string" and string.sub(fRange, 1, 1) == "%") then
							fRange = self._tModifierArgs[string.sub(fRange, 2, #fRange)]
						end
						
						if fValue and type(fValue) == "number" and fRange and type(fRange) == "number" then
							local nModifierSeed = self:GetAbility():GetModifierSeed(self:GetName(), nPropertyID)
							return fValue + (nModifierSeed % fRange)
						end
						return 0
					end
				elseif type(v) == "number" or type(v) == "string" then
					table.insert(hLuaModifier._tDeclareFunctionList, nPropertyID)
					hLuaModifier._tDatadrivenPropertyTable[k] = v
					hLuaModifier[szPropertyAlias] = function(self, params)
						local fBaseValue = self._tDatadrivenPropertyTable[k]
						if type(fBaseValue) == "string" and string.sub(fBaseValue, 1, 1) == "%" then
							fBaseValue = self._tModifierArgs[string.sub(fBaseValue, 2, #fBaseValue)]
						end
						if type(fBaseValue) == "number" then
							return fBaseValue
						elseif type(fBaseValue) == "string" then
							return _G[fBaseValue] or fBaseValue
						end
						return 0
					end
				end
			end
		end
	end
		
	if hLuaModifier.DeclareFunctions then
		hLuaModifier.OldDeclareFunctions = hLuaModifier.DeclareFunctions
		hLuaModifier.DeclareFunctions = function()
			local tBaseResults = hLuaModifier:OldDeclareFunctions()
			for k,v in pairs(tBaseResults) do hLuaModifier._tDeclareFunctionList[k] = v end
			return hLuaModifier._tDeclareFunctionList
		end
	else
		hLuaModifier.DeclareFunctions = function() return hLuaModifier._tDeclareFunctionList end
	end
end

local function ParseDatadrivenEvents(hLuaModifier, tLinkLuaModifierTemplate)
	local tDatadrivenEvents = tLinkLuaModifierTemplate.DatadrivenEvents
	if tDatadrivenEvents and IsServer() then
		for k,v in pairs(tDatadrivenEvents) do
			local szEventAlias = stLuaModifierEventAliases[k]
			if szEventAlias then
				for k2,v2 in pairs(v) do
					local hEventFunction = GetExtendedFunction(k2,v2)
					local hBaseFunction = hLuaModifier[szEventAlias]
					if hEventFunction then
						local hWrappedEventFunction = 
						function(self, params)
							if IsServer() and not self:IsNull() then
								if params then
									if szEventAlias ~= "OnModifierCreated" then
										params.entity = params.unit or params.attacker or params.target
										if szEventAlias == "OnAttacked" then params.entity = params.target end
										if not params.entity or self:GetParent() ~= params.entity then return end
										if not params.attacker then params.attacker = params.entity end
										if not params.target then params.target = params.entity end
									end
									for k3,v3 in pairs(v2) do
										params[k3] = (type(v3) == "string" and string.sub(v3, 1, 1) == "%") and self._tModifierArgs[string.sub(v3, 2, #v3)] or v3
									end
								end
								hEventFunction(self, params)
								if hBaseFunction and type(hBaseFunction) == "function" then hBaseFunction(self, params) end
								return v.ThinkInterval
							end
						end
						if szEventAlias == "OnModifierCreated" then
							table.insert(hLuaModifier._tOnCreatedList, hWrappedEventFunction)
						elseif szEventAlias == "OnModifierDestroy" then
							table.insert(hLuaModifier._tOnDestroyList, hWrappedEventFunction)
						elseif szEventAlias == "OnIntervalThink" then
							if v.ThinkInterval then
								table.insert(hLuaModifier._tOnCreatedList, function(self, params)
									params.unit = self:GetParent()
									self._hThinkTimer = CTimer(0.0, hWrappedEventFunction, self, params)
								end)
							end
						else
							table.insert(hLuaModifier._tDeclareFunctionList, _G[k])
							hLuaModifier[szEventAlias] = hWrappedEventFunction
						end
						break
					end
				end
			end
		end
	end
end

for k,v in pairs(stExtModifierData) do
	for k2,v2 in pairs(v) do
		local tLinkLuaModifierTemplate = v2
		
		local szScriptFilename = tLinkLuaModifierTemplate.ScriptFile
		if szScriptFilename then
			szScriptFilename = string.gsub(szScriptFilename, "\\", "/")
			szScriptFilename = string.gsub(szScriptFilename, "scripts/vscripts/", "")
			szScriptFilename = string.gsub(szScriptFilename, ".lua", "")
			local tSandbox = setmetatable({}, { __index = tContext })
			setfenv(1, tSandbox)
			dofile(szScriptFilename)
			tContext[k2] = tSandbox[k2]
			setfenv(1, tContext)
		end
	
		if not tContext[k2] then tContext[k2] = class({}) end
		
		local hLuaModifier = tContext[k2]
		if not hLuaModifier._tDeclareFunctionList then hLuaModifier._tDeclareFunctionList = {} end
		if not hLuaModifier._tOnCreatedList then hLuaModifier._tOnCreatedList = {} end
		if not hLuaModifier._tOnDestroyList then hLuaModifier._tOnDestroyList = {} end
		if not hLuaModifier._tOnRefreshList then hLuaModifier._tOnRefreshList = {} end
		
		ParseDatadrivenStates(hLuaModifier, tLinkLuaModifierTemplate)
		ParseDatadrivenProperties(hLuaModifier, tLinkLuaModifierTemplate)
		
		if not hLuaModifier.IsDebuff then
			if tLinkLuaModifierTemplate.IsDebuff == 1 then
				hLuaModifier.IsDebuff = function() return true end
			else
				hLuaModifier.IsDebuff = function() return false end
			end
		end
		if not hLuaModifier.IsHidden then
			if tLinkLuaModifierTemplate.IsHidden == 1 then
				hLuaModifier.IsHidden = function() return true end
			else
				hLuaModifier.IsHidden = function() return false end
			end
		end

		if not IsServer() then
			if tLinkLuaModifierTemplate.VisualStatus then
				hLuaModifier._szVisualStatusName = tLinkLuaModifierTemplate.VisualStatus
				hLuaModifier.GetStatusEffectName = function() return hLuaModifier._szVisualStatusName end
				hLuaModifier._nVisualStatusPriority = tLinkLuaModifierTemplate.VisualStatusPriority or 1
				hLuaModifier.StatusEffectPriority = function() return hLuaModifier._nVisualStatusPriority end
				hLuaModifier._nVisualHeroPriority = tLinkLuaModifierTemplate.VisualHeroPriority or 1
				hLuaModifier.HeroEffectPriority = function() return hLuaModifier._nVisualHeroPriority end
			end
			
			if tLinkLuaModifierTemplate.VisualEffect then
				hLuaModifier._szVisualName = tLinkLuaModifierTemplate.VisualEffect
				hLuaModifier.GetEffectName = function() return hLuaModifier._szVisualName end
				if tLinkLuaModifierTemplate.HeroVisualEffect then
					hLuaModifier._szHeroVisualName = tLinkLuaModifierTemplate.HeroVisualEffect
					hLuaModifier.GetHeroEffectName = function() return hLuaModifier._szHeroVisualName end
				else
					hLuaModifier.GetHeroEffectName = hLuaModifier.GetEffectName
				end
				hLuaModifier._nVisualAttachType = _G[tLinkLuaModifierTemplate.VisualAttachType] or PATTACH_ABSORIGIN
				hLuaModifier.GetEffectAttachType = function() return hLuaModifier._nVisualAttachType end
			end
			
			hLuaModifier._szTextureName = tLinkLuaModifierTemplate.Texture or k
			hLuaModifier.GetTexture = GetTexture
		else
			hLuaModifier.ApplyPropertyValues = ApplyPropertyValues
			hLuaModifier.RemovePropertyValues = RemovePropertyValues
			hLuaModifier.RefreshModifier = RefreshModifier
			
			hLuaModifier._fDuration = tLinkLuaModifierTemplate.Duration or -1
			hLuaModifier._nMaxStacks = tLinkLuaModifierTemplate.MaxStacks or 0
			hLuaModifier._nMaxStacksPerCaster = tLinkLuaModifierTemplate.MaxStacksPerCaster or 0
			
			hLuaModifier._tPropertyList = {}
			for k3,v3 in pairs(tLinkLuaModifierTemplate.Properties or {}) do
				if stIcewrackPropertyEnum[k3] then
					hLuaModifier._tPropertyList[k3] = v3
				else
					LogMessage("Unknown property \"" .. k3 .. "\" in modifier \"" .. k2 .. "\"", LOG_SEVERITY_WARNING)
				end
			end
			
			local szDatadrivenAttributes = tLinkLuaModifierTemplate.DatadrivenAttributes
			if szDatadrivenAttributes then
				hLuaModifier._bIsPermanent = false
				hLuaModifier._nAttributes = 0
				for w in string.gmatch(szDatadrivenAttributes, "MODIFIER_ATTRIBUTE_[%w_]+") do
					local nAttributeValue = _G[w]
					if nAttributeValue then
						hLuaModifier._nAttributes = hLuaModifier._nAttributes + nAttributeValue
						if nAttributeValue == MODIFIER_ATTRIBUTE_PERMANENT then
							hLuaModifier._bIsPermanent = true
						end
					end
				end
				hLuaModifier.GetAttributes = function() if IsServer() then return hLuaModifier._nAttributes end end
				hLuaModifier.RemoveOnDeath = function() return not hLuaModifier._bIsPermanent end
			end
			
			if tLinkLuaModifierTemplate.SoundEffect then
				hLuaModifier._szSoundName = tLinkLuaModifierTemplate.SoundEffect
				table.insert(hLuaModifier._tOnCreatedList,
					function(self, params)
						local hEntity = self:GetParent()
						EmitSoundOn(hLuaModifier._szSoundName, hEntity)
					end)
				table.insert(hLuaModifier._tOnDestroyList,
					function(self, params)
						local hEntity = self:GetParent()
						if hEntity and not hEntity:IsNull() and not hEntity:HasModifier(self:GetName()) then
							--1f delay for correct behavior when created and destroyed simultaneously
							CTimer(0.03, StopSoundOn, hLuaModifier._szSoundName, hEntity)
						end
					end)
			end
			
			ParseDatadrivenEvents(hLuaModifier, tLinkLuaModifierTemplate)
		end
		
		hLuaModifier._nModifierID = 0
		hLuaModifier.RetrieveModifierID = function(self) hLuaModifier._nModifierID = hLuaModifier._nModifierID + 1 return hLuaModifier._nModifierID end
		hLuaModifier._tModifierNetTable = {}
		
		if hLuaModifier.OnCreated then table.insert(hLuaModifier._tOnCreatedList, hLuaModifier.OnCreated) end
		table.insert(hLuaModifier._tOnCreatedList, 1, OnModifierCreatedDefault)
		hLuaModifier.OnCreated = OnCreated
		if hLuaModifier.OnDestroy then table.insert(hLuaModifier._tOnDestroyList, hLuaModifier.OnDestroy) end
		table.insert(hLuaModifier._tOnDestroyList, OnModifierDestroyDefault)
		hLuaModifier.OnDestroy = OnDestroy
		if hLuaModifier.OnRefresh then table.insert(hLuaModifier._tOnRefreshList, hLuaModifier.OnRefresh) end
		table.insert(hLuaModifier._tOnRefreshList, OnModifierRefreshDefault)
		hLuaModifier.OnRefresh = OnRefresh
	end
end