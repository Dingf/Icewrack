--[[
    Icewrack Extended Ability Linker
]]

--TODO: Investigate whether we can stop the game from generating a dozen CastFilterResult calls
--There was a similar problem a while back with modifiers, see http://dev.dota2.com/showthread.php?t=172252&p=1247001&viewfull=1#post1247001
--However we don't have any identifying information this time, as all the calls are the same...

--TODO: Implement weather abilities (i.e. make it so that only one weather ability can be active at a time)

if not CExtAbilityLinker then CExtAbilityLinker = {}

if IsServer() then
require("timer")
require("mechanics/modifier_triggers")
require("instance")
require("expression")
end

stExtAbilityFlagEnum =
{
	IW_ABILITY_FLAG_ONLY_CAST_OUTSIDE   = 1,
	IW_ABILITY_FLAG_ONLY_CAST_INSIDE    = 2,
	IW_ABILITY_FLAG_ONLY_CAST_AT_DAY    = 4,
	IW_ABILITY_FLAG_ONLY_CAST_AT_NIGHT  = 8,
	IW_ABILITY_FLAG_CAN_TARGET_CORPSES  = 16,
	IW_ABILITY_FLAG_ONLY_TARGET_CORPSES = 32,
	IW_ABILITY_FLAG_CAN_TARGET_OBJECTS  = 64,		--TODO: Implement me
	IW_ABILITY_FLAG_ONLY_TARGET_OBJECTS = 128,		--TODO: Implement me
	IW_ABILITY_FLAG_ONLY_CAST_IN_COMBAT = 256,
	IW_ABILITY_FLAG_ONLY_CAST_NO_COMBAT = 512,
	IW_ABILITY_FLAG_DOES_NOT_REQ_VISION = 1024,
	IW_ABILITY_FLAG_CAN_CAST_IN_TOWN    = 2048,		--TODO: Implement me
	IW_ABILITY_FLAG_USES_ATTACK_STAMINA = 4096,
	IW_ABILITY_FLAG_KEYWORD_SPELL       = 8192,
	IW_ABILITY_FLAG_KEYWORD_ATTACK      = 16384,
	IW_ABILITY_FLAG_KEYWORD_SINGLE      = 32768,
	IW_ABILITY_FLAG_KEYWORD_AOE         = 65536,
}

for k,v in pairs(stExtAbilityFlagEnum) do _G[k] = v end

local stUnitFilterCastErrors =
{
	[UF_FAIL_ANCIENT]               = "#dota_hud_error_cant_cast_on_ancient",
	[UF_FAIL_ATTACK_IMMUNE]         = "#dota_hud_error_target_attack_immune",
	[UF_FAIL_BUILDING]              = "#dota_hud_error_cant_cast_on_building",
	[UF_FAIL_CONSIDERED_HERO]       = "#dota_hud_error_cant_cast_on_considered_hero",
	[UF_FAIL_COURIER]               = "#dota_hud_error_cant_cast_on_courier",
	[UF_FAIL_CREEP]                 = "#dota_hud_error_cant_cast_on_creep",
	[UF_FAIL_CUSTOM]                = "#dota_hud_error_cant_cast_on_other",
	[UF_FAIL_DEAD]                  = "#dota_hud_error_unit_dead",
	[UF_FAIL_DISABLE_HELP]          = "#dota_hud_error_target_has_disable_help",
	[UF_FAIL_DOMINATED]             = "#dota_hud_error_cant_cast_on_dominated",
	[UF_FAIL_ENEMY]                 = "#dota_hud_error_cant_cast_on_enemy"	,
	[UF_FAIL_FRIENDLY]              = "#dota_hud_error_cant_cast_on_ally",
	[UF_FAIL_HERO]                  = "#dota_hud_error_cant_cast_on_hero",
	[UF_FAIL_ILLUSION]              = "#dota_hud_error_cant_cast_on_illusion",
	[UF_FAIL_INVALID_LOCATION]      = "#dota_hud_error_invalid_location",
	[UF_FAIL_INVISIBLE]             = "#dota_hud_error_target_invisible",
	[UF_FAIL_INVULNERABLE]          = "#dota_hud_error_target_invulnerable",
	[UF_FAIL_IN_FOW]                = "#dota_hud_error_cant_target_unexplored",
	[UF_FAIL_MAGIC_IMMUNE_ALLY]     = "#dota_hud_error_target_magic_immune",
	[UF_FAIL_MAGIC_IMMUNE_ENEMY]    = "#dota_hud_error_target_magic_immune",
	[UF_FAIL_MELEE]                 = "#dota_hud_error_target_melee",
	[UF_FAIL_NIGHTMARED]            = "#dota_hud_error_target_nightmared",
	[UF_FAIL_NOT_PLAYER_CONTROLLED] = "#dota_hud_error_cant_cast_not_player_controlled",
	[UF_FAIL_OTHER]                 = "#dota_hud_error_cant_cast_on_other",
	[UF_FAIL_OUT_OF_WORLD]          = "#dota_hud_error_target_out_of_world",
	[UF_FAIL_RANGED]                = "#dota_hud_error_target_ranged",
	[UF_FAIL_SUMMONED]              = "#dota_hud_error_cant_cast_on_summoned",
}

local floor = math.floor

function CExtAbilityLinker:GetAbilityFlags()
	return self._nAbilityFlags or 0
end

function CExtAbilityLinker:GetSkillRequirements()
	return self._nAbilitySkill or 0
end

function CExtAbilityLinker:GetBehavior()
	return self._nAbilityBehavior or self.BaseClass.GetBehavior(self)
end

function CExtAbilityLinker:GetAbilityTargetTeam()
	return self._nAbilityTargetTeam
end

function CExtAbilityLinker:GetAbilityTargetType()
	return self._nAbilityTargetType
end

function CExtAbilityLinker:GetAbilityTargetFlags()
	return self._nAbilityTargetFlags
end

function CExtAbilityLinker:GetCastAnimation()
	if self._tAbilityCastAnimations then
		local tAnimationTable = self._tAbilityCastAnimations[self:GetCaster():GetUnitName()]
		return GameActivity_t[tAnimationTable.Animation] or 0
	end
	return 0
end

function CExtAbilityLinker:GetPlaybackRateOverride()
	if self._tAbilityCastAnimations then
		local tAnimationTable = self._tAbilityCastAnimations[self:GetCaster():GetUnitName()]
		return tAnimationTable.Rate or 1.0
	end
	return 1.0
end

function CExtAbilityLinker:GetAOERadius()
	local tBaseFunctions = self._tBaseFunctions
	if tBaseFunctions then
		local hBaseFunction = tBaseFunctions.GetAOERadius
		if hBaseFunction then
			return hBaseFunction(self)
		end
	end
	return self._nAbilityAOERadius
end

function CExtAbilityLinker:GetCastRange(vLocation, hTarget)
	if not vLocation then vLocation = self:GetCaster():GetAbsOrigin() end
	local tBaseFunctions = self._tBaseFunctions
	if tBaseFunctions then
		local hBaseFunction = tBaseFunctions.GetCastRange
		if hBaseFunction then
			return hBaseFunction(self, vLocation, hTarget)
		end
	end
	return self.BaseClass.GetCastRange(self, vLocation, hTarget)
end

function CExtAbilityLinker:GetChannelTime()
	local tBaseFunctions = self._tBaseFunctions
	if tBaseFunctions then
		local hBaseFunction = tBaseFunctions.GetChannelTime
		if hBaseFunction then
			return hBaseFunction(self)
		end
	end
	return self.BaseClass.GetChannelTime(self)
end

function CExtAbilityLinker:GetCooldown(nLevel)
	local tBaseFunctions = self._tBaseFunctions
	if tBaseFunctions then
		local hBaseFunction = tBaseFunctions.GetCooldown
		if hBaseFunction then
			return hBaseFunction(self, nLevel)
		end
	end
	return self.BaseClass.GetCooldown(self, nLevel)
end

function CExtAbilityLinker:GetHealthCost(nLevel)
	local hEntity = self:GetCaster()
	local fHealthCost = 0
	local tBaseFunctions = self._tBaseFunctions
	if tBaseFunctions and tBaseFunctions.GetHealthCost then
		fHealthCost = tBaseFunctions.GetHealthCost(self, nLevel)
	elseif self._tAbilityCosts then
		local tHealthCosts = self._tAbilityCosts.HealthCost
		if not nLevel or nLevel == -1 then nLevel = self:GetLevel() end
		fHealthCost = tHealthCosts[nLevel] or 0
	end
	
	if IsServer() then
		fHealthCost = fHealthCost * (hEntity and hEntity:GetFatigueMultiplier() or 1.0)
	else
		fHealthCost = fHealthCost * (hEntity and hEntity:GetMagicalArmorValue() or 1.0)
	end
	return floor(fHealthCost)
end

function CExtAbilityLinker:GetManaCost(nLevel)
	local hEntity = self:GetCaster()
	local fManaCost = 0
	local tBaseFunctions = self._tBaseFunctions
	if tBaseFunctions and tBaseFunctions.GetManaCost then
		fManaCost = tBaseFunctions.GetManaCost(self, nLevel)
	elseif self._tAbilityCosts then
		local tManaCosts = self._tAbilityCosts.ManaCost
		if not nLevel or nLevel == -1 then nLevel = self:GetLevel() end
		fManaCost = tManaCosts[nLevel] or 0
	end
	
	if IsServer() then
		fManaCost = fManaCost * (hEntity and hEntity:GetFatigueMultiplier() or 1.0)
	else
		fManaCost = fManaCost * (hEntity and hEntity:GetMagicalArmorValue() or 1.0)
	end
	return floor(fManaCost)
end

function CExtAbilityLinker:GetStaminaCost(nLevel)
	local hEntity = self:GetCaster()
	local fStaminaCost = 0
	local tBaseFunctions = self._tBaseFunctions
	if tBaseFunctions and tBaseFunctions.GetStaminaCost then
		fStaminaCost = tBaseFunctions.GetStaminaCost(self, nLevel)
	elseif self._tAbilityCosts then
		local tStaminaCosts = self._tAbilityCosts.StaminaCost
		if not nLevel or nLevel == -1 then nLevel = self:GetLevel() end
		fStaminaCost = tStaminaCosts[nLevel] or 0
	end
	
	local nAbilityFlags = self:GetAbilityFlags()
	if bit32.btest(nAbilityFlags, IW_ABILITY_FLAG_USES_ATTACK_STAMINA) then
		local _, hAttackSource = next(hEntity._tAttackSourceTable)
		if not hAttackSource then
			hAttackSource = hEntity
		end
		fStaminaCost = fStaminaCost + hAttackSource:GetBasePropertyValue(IW_PROPERTY_ATTACK_SP_FLAT) * (hEntity:GetFatigueMultiplier() + hAttackSource:GetPropertyValue(IW_PROPERTY_ATTACK_SP_PCT)/100.0)
	end
	fStaminaCost = fStaminaCost * (hEntity and hEntity:GetFatigueMultiplier() or 1.0)
	return floor(fStaminaCost)
end

function CExtAbilityLinker:GetGoldCost(nLevel)
	local tBaseFunctions = self._tBaseFunctions
	if tBaseFunctions and tBaseFunctions.GetGoldCost then
		return tBaseFunctions.GetGoldCost(self, nLevel)
	elseif self._tAbilityCosts then
		local tGoldCosts = self._tAbilityCosts.GoldCost
		if not nLevel or nLevel == -1 then nLevel = self:GetLevel() end
		local fBaseCost = tGoldCosts[nLevel] or 0
		return fBaseCost
	end
	return 0
end

function CExtAbilityLinker:IsWeatherAbility()
	return (self._bIsWeatherAbility == true)
end

function CExtAbilityLinker:IsFullyCastable()
	if IsServer() then
		local hEntity = self:GetCaster()
		local nAbilityFlags = self:GetAbilityFlags()
		if not self:IsActivated() then
			return false, "hidden"
		elseif self:GetCooldownTimeRemaining() > 0 then
			return false, "cd"
		elseif self:GetHealthCost() > hEntity:GetHealth() then
			return false, "hp"
		elseif self:GetManaCost() > hEntity:GetMana() then
			return false, "mp"
		elseif hEntity.GetStamina and self:GetStaminaCost() > hEntity:GetStamina() then
			return false, "sp"
		elseif bit32.btest(nAbilityFlags, IW_ABILITY_FLAG_ONLY_CAST_OUTSIDE) and not GameRules:GetMapInfo():IsOutside() then
			return false, "outside"
		elseif bit32.btest(nAbilityFlags, IW_ABILITY_FLAG_ONLY_CAST_INSIDE) and not GameRules:GetMapInfo():IsInside() then
			return false, "inside"
		elseif bit32.btest(nAbilityFlags, IW_ABILITY_FLAG_ONLY_CAST_AT_DAY) and not GameRules:IsDaytime() then
			return false, "day"
		elseif bit32.btest(nAbilityFlags, IW_ABILITY_FLAG_ONLY_CAST_AT_NIGHT) and GameRules:IsDaytime() then
			return false, "night"
		elseif bit32.btest(nAbilityFlags, IW_ABILITY_FLAG_ONLY_CAST_IN_COMBAT) and not GameRules:IsInCombat() then
			return false, "combat"
		elseif bit32.btest(nAbilityFlags, IW_ABILITY_FLAG_ONLY_CAST_NO_COMBAT) and GameRules:IsInCombat() then
			return false, "nocombat"
		--TODO: Re-enable me after you've finished testing
		--elseif not bit32.btest(nAbilityFlags, IW_ABILITY_FLAG_CAN_CAST_IN_TOWN) and GameRules:GetMapInfo():IsTown() then
		--	return false, "town"
		end
		return CDOTABaseAbility.IsFullyCastable(self), "other"
	end
	return true
end

function CExtAbilityLinker:EvaluateFlags(vLocation, hTarget)
	if IsServer() then
		local nAbilityFlags = self:GetAbilityFlags()
		if hTarget then
			if bit32.btest(nAbilityFlags, IW_ABILITY_FLAG_CAN_TARGET_CORPSES) and not bit32.btest(nAbilityFlags, IW_ABILITY_FLAG_ONLY_TARGET_CORPSES) then
				if not hTarget:IsAlive() then
					return false
				end
			elseif bit32.btest(nAbilityFlags, IW_ABILITY_FLAG_ONLY_TARGET_CORPSES) and hTarget:IsAlive() then
				return false
			end
		end
	end
	return true
end

function CExtAbilityLinker:GetCustomCastErrorFlags(vLocation, hTarget)
	if IsServer() then
		local nAbilityFlags = self:GetAbilityFlags()
		if hTarget then
			if not bit32.btest(nAbilityFlags, IW_ABILITY_FLAG_CAN_TARGET_CORPSES) and not bit32.btest(nAbilityFlags, IW_ABILITY_FLAG_ONLY_TARGET_CORPSES) then
				if not hTarget:IsAlive() then
					return "#iw_error_flag_no_corpse"
				end
			elseif bit32.btest(nAbilityFlags, IW_ABILITY_FLAG_ONLY_TARGET_CORPSES) and hTarget:IsAlive() then
				return "#iw_error_flag_only_corpse"
			end
		end
	end
	return
end

function CExtAbilityLinker:EvaluatePrereqs(vLocation, hTarget)
	if IsServer() and IsInstanceOf(self, CDOTA_Ability_Lua) then
		local hEntity = self:GetCaster()
		for k,v in pairs(self._tPrereqExpressions) do
			if not v:EvaluateExpression(hEntity) then return false end
		end
		
		for k,v in pairs(self._tPrereqCasterModifiers) do
			if not hEntity:HasModifier(v) then return false end
		end
		
		local nAbilityBehavior = self:GetBehavior()
		if bit32.btest(nAbilityBehavior, DOTA_ABILITY_BEHAVIOR_UNIT_TARGET) then
			if not hTarget then return false end
			for k,v in pairs(self._tPrereqTargetModifiers) do
				if not hTarget:HasModifier(v) then return false end
			end
		end
		
		for k,v in pairs(self._tPrereqScripts) do
			if not v(self, vLocation, hTarget) then return false end
		end
	end
	return true
end

function CExtAbilityLinker:CastFilterResult(vLocation, hTarget)
	if not IsServer() then
		local nAbilityIndex = self:entindex()
		local nEntityIndex = self:GetCaster():entindex()
		local tSpellbookNetTable = CustomNetTables:GetTableValue("spellbook", tostring(nEntityIndex))
		local tEntityNetTable = CustomNetTables:GetTableValue("entities", tostring(nEntityIndex))
		
		local fStaminaCost = 0
		for k,v in pairs(tSpellbookNetTable.Spells) do
			if v.entindex == nAbilityIndex then
				fStaminaCost = v.stamina
				break
			end
		end
		
		self._bStaminaFailed = false
		if tEntityNetTable.stamina < fStaminaCost then
			self._bStaminaFailed = true
			return UF_FAIL_CUSTOM
		end
	elseif IsServer() and not self._bCastFilterLock then
		if not self:IsFullyCastable() then
			return UF_FAIL_CUSTOM
		end
	
		self._bSkillFailed = false
		self._bCastFilterLock = true
		CTimer(0.03, function() self._bCastFilterLock = nil end)
		
		self._bFlagsFailed = false
		if not self:EvaluateFlags(vLocation, hTarget) then
			self._bFlagsFailed = true
			return UF_FAIL_CUSTOM
		end
		
		self._bPrereqFailed = false
		if not self:EvaluatePrereqs(vLocation, hTarget) then
			self._bPrereqFailed = true
			return UF_FAIL_CUSTOM
		end
	end
	
	local tBaseFunctions = self._tBaseFunctions
	if tBaseFunctions then
		local args = nil
		local hBaseFunction = nil
		if vLocation then
			hBaseFunction = tBaseFunctions.CastFilterResultLocation
			args = vLocation
		elseif hTarget then
			hBaseFunction = tBaseFunctions.CastFilterResultTarget
			args = hTarget
		else
			hBaseFunction = tBaseFunctions.CastFilterResult
		end
		
		if hBaseFunction and type(hBaseFunction) == "function" then
			return hBaseFunction(self, args) or UF_SUCCESS
		end
	end
	return UF_SUCCESS
end

function CExtAbilityLinker:GetCustomCastError(vLocation, hTarget)
	bResult, szMessage = self:IsFullyCastable()
	if not bResult then
		return "#iw_error_cast_" .. szMessage
	end
	
	if IsServer() then
		--if self._bSkillFailed  then return "#iw_error_prereq_not_met" end --TODO: Investigate whether we can create a more dynamic message that shows what skill you're missing
		if self._bFlagsFailed then return self:GetCustomCastErrorFlags(vLocation, hTarget) end
		if self._bPrereqFailed then return "#iw_error_prereq_not_met" end
	else
		if self._bStaminaFailed then return "#iw_error_cast_sp" end
	end
	
	local tBaseFunctions = self._tBaseFunctions
	if tBaseFunctions then
		local args = nil
		local hBaseFunction = nil
		if vLocation then
			hBaseFunction = tBaseFunctions.GetCustomCastErrorLocation
			args = vLocation
		elseif hTarget then
			hBaseFunction = tBaseFunctions.GetCustomCastErrorTarget
			args = hTarget
		else
			hBaseFunction = tBaseFunctions.GetCustomCastError
		end
		if hBaseFunction and type(hBaseFunction) == "function" then
			local szErrorString = hBaseFunction(self, args)
			if szErrorString then
				return szErrorString
			end
		end
	end
	return ""
end

function CExtAbilityLinker:CastFilterResultLocation(vLocation)
	return self:CastFilterResult(vLocation, nil)
end

function CExtAbilityLinker:GetCustomCastErrorLocation(vLocation)
	return self:GetCustomCastError(vLocation, nil)
end

function CExtAbilityLinker:CastFilterResultTarget(hTarget)
	local nResult = UnitFilter(hTarget, self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), self:GetAbilityTargetFlags(), self:GetCaster():GetTeamNumber())
	if nResult ~= UF_SUCCESS then
		return nResult
	end
	return self:CastFilterResult(nil, hTarget)
end

function CExtAbilityLinker:GetCustomCastErrorTarget(hTarget)
	local nResult = UnitFilter(hTarget, self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), self:GetAbilityTargetFlags(), self:GetCaster():GetTeamNumber())
	if nResult ~= UF_SUCCESS then
		return stUnitFilterCastErrors[nResult]
	end
	return self:GetCustomCastError(nil, hTarget)
end

function CExtAbilityLinker:OnAbilityPhaseStart()
	local tBaseFunctions = self._tBaseFunctions
	if tBaseFunctions then
		local hBaseFunction = tBaseFunctions.OnAbilityPhaseStart
		if hBaseFunction then
			return hBaseFunction(self)
		end
	end
	return true
end

function CExtAbilityLinker:OnSpellStart()
	local hEntity = self:GetCaster()
	local fHealthCost = self:GetHealthCost()
	if fHealthCost > 0 then
		local fCurrentHealth = hEntity:GetHealth()
		if fCurrentHealth > fHealthCost then
			hEntity:ModifyHealth(fCurrentHealth - fHealthCost, hEntity, true, 0)
		end
	end
	
	local fManaCost = self:GetManaCost()
	if fManaCost > 0 then
		local fCurrentMana = hEntity:GetMana()
		if fCurrentMana > fManaCost then
			hEntity:SetMana(fCurrentMana - fManaCost) 
		end
	end
	
	local fStaminaCost = self:GetStaminaCost()
	if fStaminaCost > 0 and IsValidExtendedEntity(hEntity) then
		local fCurrentStamina = hEntity:GetStamina()
		if fCurrentStamina > fStaminaCost then
			hEntity:SpendStamina(fStaminaCost)
		end
	end
	
	self:ApplyModifiers(self:GetCaster(), IW_MODIFIER_ON_USE)
	local hCursorTarget = hEntity:GetCursorCastTarget()
	if hCursorTarget and hCursorTarget:GetTeamNumber() ~= hEntity:GetTeamNumber() then
		hEntity:SetAttacking(hCursorTarget)
	end
	
	local tBaseFunctions = self._tBaseFunctions
	if tBaseFunctions then
		local hBaseFunction = tBaseFunctions.OnSpellStart
		if hBaseFunction then
			hBaseFunction(self)
		end
	end
end

function CExtAbilityLinker:OnChannelFinish(bInterrupted)
	self:ApplyModifiers(self:GetCaster(), IW_MODIFIER_ON_CHANNEL_END)
	if not bInterrupted then self:ApplyModifiers(self:GetCaster(), IW_MODIFIER_ON_CHANNEL_SUCCESS) end
	local tBaseFunctions = self._tBaseFunctions
	if tBaseFunctions then
		local hBaseFunction = tBaseFunctions.OnChannelFinish
		if hBaseFunction then
			hBaseFunction(self)
		end
	end
end

function CExtAbilityLinker:OnToggle()
	if self:GetToggleState() then
		self:RemoveModifiers(self:GetCaster(), IW_MODIFIER_ON_TOGGLE)
	else
		self:ApplyModifiers(IW_MODIFIER_ON_TOGGLE)
	end
	local tBaseFunctions = self._tBaseFunctions
	if tBaseFunctions then
		local hBaseFunction = tBaseFunctions.OnToggle
		if hBaseFunction then
			hBaseFunction(self)
		end
	end
end

function CExtAbilityLinker:ApplyModifiers(hEntity, nTrigger)
	--This function should be overriden by the implementing classes (ext_ability, ext_item)
	LogMessage("Tried to access virtual function CExtAbilityLinker:ApplyModifiers()", LOG_SEVERITY_WARNING)
end

function CExtAbilityLinker:RemoveModifiers(nTrigger)
	--This function should be overriden by the implementing classes (ext_ability, ext_item)
	LogMessage("Tried to access virtual function CExtAbilityLinker:RemoveModifiers()", LOG_SEVERITY_WARNING)
end

function CExtAbilityLinker:LinkExtAbility(szAbilityName, tBaseTemplate, tExtTemplate)
	if IsServer() then
		local szScriptFilename = tExtTemplate.ScriptFile
		if szScriptFilename then
			szScriptFilename = string.gsub(szScriptFilename, "\\", "/")
			szScriptFilename = string.gsub(szScriptFilename, "scripts/vscripts/", "")
			szScriptFilename = string.gsub(szScriptFilename, ".lua", "")
			local tSandbox = setmetatable({}, { __index = _G })
			local tContext = getfenv()
			setfenv(1, tSandbox)
			dofile(szScriptFilename)
			_G[szAbilityName] = tSandbox[szAbilityName]
			setfenv(1, tContext)
		end
	end
	
	if not _G[szAbilityName] then _G[szAbilityName] = class({}) end
	local hExtAbility = _G[szAbilityName]
	
	for k,v in pairs(tBaseTemplate.Modifiers or {}) do
		LinkLuaModifier(k, "link_ext_modifier", LUA_MODIFIER_MOTION_NONE)
	end
	
	hExtAbility._tBaseFunctions = {}
	for k,v in pairs(CExtAbilityLinker) do
		if hExtAbility[k] and type(hExtAbility[k]) == "function" then
			hExtAbility._tBaseFunctions[k] = hExtAbility[k]
		end
		hExtAbility[k] = v
	end
	
	hExtAbility._nAbilitySkill = tExtTemplate.AbilitySkill or 0
	--hExtAbility._nAbilityBehavior = GetFlagValue(tBaseTemplate.AbilityBehavior, DOTA_ABILITY_BEHAVIOR)
	hExtAbility._nAbilityTargetTeam = DOTA_UNIT_TARGET_TEAM[tBaseTemplate.AbilityUnitTargetTeam]
	hExtAbility._nAbilityTargetType = GetFlagValue(tBaseTemplate.AbilityUnitTargetType, DOTA_UNIT_TARGET_TYPE)
	hExtAbility._nAbilityTargetFlags = GetFlagValue(tBaseTemplate.AbilityUnitTargetFlags, DOTA_UNIT_TARGET_FLAGS)
	hExtAbility._nAbilityFlags = GetFlagValue(tExtTemplate.AbilityFlags, stExtAbilityFlagEnum)
	hExtAbility._nAbilityAOERadius = tonumber(tBaseTemplate.AbilityAOERadius) or 0
	
	hExtAbility._bIsWeatherAbility = (tExtTemplate.IsWeather == 1)
	
	hExtAbility._tAbilityCosts =
	{
		HealthCost = {},
		ManaCost = {},
		StaminaCost = {},
		GoldCost = {}
	}
	for k,v in pairs(hExtAbility._tAbilityCosts) do
		local szCostValue = tExtTemplate[k]
		if szCostValue then
			for k2 in string.gmatch(tostring(szCostValue), "[-+]*[%d]+[.]*[%d]*") do
				local fValue = tonumber(k2)
				if fValue then
					table.insert(v, fValue)
				end
			end
		end
	end
	
	if type(tExtTemplate.AbilityCastAnimation) == "table" then
		hExtAbility._tAbilityCastAnimations = {}
		for k,v in pairs(tExtTemplate.AbilityCastAnimation) do
			hExtAbility._tAbilityCastAnimations[k] = v
		end
	end
	
	if IsServer() then
		local tExtAbilityPrereqs = tExtTemplate.Prequisites or {}
			
		hExtAbility._tPrereqExpressions = {}
		local tExtAbilityPrereqExpressions = tExtAbilityPrereqs.Expressions or {}
		for k,v in pairs(tExtAbilityPrereqExpressions) do
			table.insert(hExtAbility._tPrereqExpressions, CExpression(v))
		end
			
		hExtAbility._tPrereqCasterModifiers = tExtAbilityPrereqs.CasterModifiers or {}
		hExtAbility._tPrereqTargetModifiers = tExtAbilityPrereqs.TargetModifiers or {}
			
		--TODO: Test this implementation
		hExtAbility._tPrereqScripts = {}
		local tPrereqScripts = tExtAbilityPrereqs.Scripts or {}
		for k,v in pairs(tPrereqScripts) do
			if v and type(v) == "table" then
				local szScriptFilename = v.Filename
				local szScriptFunction = v.Function
				if szScriptFilename and szScriptFunction then
					if not pcall(require(szScriptFilename)) then
						error("[CExtAbility]: Failed to load script file " .. szScriptFilename)
					end
					local hScriptFunction = _G[szScriptFunction]
					if hScriptFunction and type(hScriptFunction) == "function" then
						table.insert(hAbility._tPrereqScripts, hScriptFunction)
					end
				end
			end
		end
	end
	return hExtAbility
end

end