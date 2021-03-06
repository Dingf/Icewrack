--[[
    Icewrack Extended Ability Linker
]]

--TODO: Investigate whether we can stop the game from generating a dozen CastFilterResult calls
--There was a similar problem a while back with modifiers, see http://dev.dota2.com/showthread.php?t=172252&p=1247001&viewfull=1#post1247001
--However we don't have any identifying information this time, as all the calls are the same...

--TODO: Implement weather abilities (i.e. make it so that only one weather ability can be active at a time)

if not CExtAbilityLinker then CExtAbilityLinker = {}

if _VERSION < "Lua 5.2" then
    bit = require("lib/numberlua")
    bit32 = bit.bit32
end

if IsServer() then
require("timer")
require("mechanics/modifier_triggers")
require("mechanics/skills")
require("instance")
require("entity_base")
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
	IW_ABILITY_FLAG_IGNORE_LOS_BLOCKERS = 2048,
	IW_ABILITY_FLAG_CAN_CAST_IN_TOWN    = 4096,		--TODO: Implement me
	IW_ABILITY_FLAG_USES_ATTACK_RANGE   = 8192,
	IW_ABILITY_FLAG_AUTOCAST_ATTACK     = 16384,
	IW_ABILITY_FLAG_TOGGLE_OFF_ON_DEATH = 32768,
	IW_ABILITY_FLAG_KEYWORD_SPELL       = 65536,
	IW_ABILITY_FLAG_KEYWORD_ATTACK      = 131072,
	IW_ABILITY_FLAG_KEYWORD_SINGLE      = 262144,
	IW_ABILITY_FLAG_KEYWORD_AOE         = 524288,
	IW_ABILITY_FLAG_KEYWORD_WEATHER     = 1048576,
	IW_ABILITY_FLAG_KEYWORD_AURA        = 2097152,
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
	return self._nAbilityTargetTeam or DOTA_UNIT_TARGET_TEAM_NONE
end

function CExtAbilityLinker:GetAbilityTargetType()
	return self._nAbilityTargetType or DOTA_UNIT_TARGET_NONE
end

function CExtAbilityLinker:GetAbilityTargetFlags()
	return self._nAbilityTargetFlags or DOTA_UNIT_TARGET_FLAG_NONE
end

function CExtAbilityLinker:GetCastAnimation()
	if self._tAbilityCastAnimations then
		local tAnimationTable = self._tAbilityCastAnimations[self:GetCaster():GetUnitName()]
		if tAnimationTable then
			self._nLastAnimationIndex = RandomInt(1, #tAnimationTable)
			return GameActivity_t[tAnimationTable[self._nLastAnimationIndex]] or 0
		end
	end
	local tBaseFunctions = self._tBaseFunctions
	if tBaseFunctions then
		local hBaseFunction = tBaseFunctions.GetCastAnimation
		if hBaseFunction then
			return hBaseFunction(self)
		end
	end
	return 0
end

function CExtAbilityLinker:GetPlaybackRateOverride()
	if self._tAbilityPlaybackRates then
		local tPlaybackTable = self._tAbilityPlaybackRates[self:GetCaster():GetUnitName()]
		if tPlaybackTable and self._nLastAnimationIndex then
			return tPlaybackTable[self._nLastAnimationIndex]
		end
	end
	local tBaseFunctions = self._tBaseFunctions
	if tBaseFunctions then
		local hBaseFunction = tBaseFunctions.GetPlaybackRateOverride
		if hBaseFunction then
			return hBaseFunction(self)
		end
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
	local hEntity = self:GetCaster()
	if not vLocation then vLocation = hEntity:GetAbsOrigin() end
	
	local tBaseFunctions = self._tBaseFunctions
	if tBaseFunctions then
		local hBaseFunction = tBaseFunctions.GetCastRange
		if hBaseFunction then
			return hBaseFunction(self, vLocation, hTarget)
		end
	end
	
	local nAbilityFlags = self:GetAbilityFlags()
	if bit32.btest(nAbilityFlags, IW_ABILITY_FLAG_USES_ATTACK_RANGE) then
		return hEntity:GetAttackRange()
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

function CExtAbilityLinker:GetBaseHealthCost(nLevel)
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
	local nAbilityFlags = self:GetAbilityFlags()
	if bit32.btest(nAbilityFlags, IW_ABILITY_FLAG_KEYWORD_ATTACK) then
		local hAttackSource = hEntity:GetCurrentAttackSource()
		if not hAttackSource then
			hAttackSource = hEntity
		end
		fHealthCost = fHealthCost + hAttackSource:GetBasePropertyValue(IW_PROPERTY_ATTACK_HP_FLAT)
	end
	return fHealthCost
end

function CExtAbilityLinker:GetHealthCost(nLevel)
	local hEntity = self:GetCaster()
	return floor(self:GetBaseHealthCost(nLevel) * (1.0 + hEntity:GetPropertyValue(IW_PROPERTY_HP_COST_PCT)/100.0))
end

function CExtAbilityLinker:GetBaseManaCost(nLevel)
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
	local nAbilityFlags = self:GetAbilityFlags()
	if bit32.btest(nAbilityFlags, IW_ABILITY_FLAG_KEYWORD_ATTACK) then
		local hAttackSource = hEntity:GetCurrentAttackSource()
		if not hAttackSource then
			hAttackSource = hEntity
		end
		fManaCost = fManaCost + hAttackSource:GetBasePropertyValue(IW_PROPERTY_ATTACK_MP_FLAT)
	end
	return fManaCost
end

function CExtAbilityLinker:GetManaCost(nLevel)
	local hEntity = self:GetCaster()
	return floor(self:GetBaseManaCost(nLevel) * (1.0 + hEntity:GetPropertyValue(IW_PROPERTY_MP_COST_PCT)/100.0))
end

function CExtAbilityLinker:GetManaUpkeep()
	local hEntity = self:GetCaster()
	local fManaUpkeep = self._fManaUpkeep or 0
	local tBaseFunctions = self._tBaseFunctions
	if tBaseFunctions and tBaseFunctions.GetManaUpkeep then
		fManaUpkeep = tBaseFunctions.GetManaUpkeep(self)
	end
	fManaUpkeep = fManaUpkeep * (1.0 + hEntity:GetPropertyValue(IW_PROPERTY_MP_COST_PCT)/100.0)
	return fManaUpkeep
end

function CExtAbilityLinker:GetBaseStaminaCost(nLevel)
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
	if bit32.btest(nAbilityFlags, IW_ABILITY_FLAG_KEYWORD_ATTACK) then
		local hAttackSource = hEntity:GetCurrentAttackSource()
		if not hAttackSource then
			hAttackSource = hEntity
		end
		fStaminaCost = fStaminaCost + hAttackSource:GetBasePropertyValue(IW_PROPERTY_ATTACK_SP_FLAT)
	end
	return fStaminaCost
end

function CExtAbilityLinker:GetStaminaCost(nLevel)
	local hEntity = self:GetCaster()
	return floor(self:GetBaseStaminaCost(nLevel) * (1.0 + hEntity:GetPropertyValue(IW_PROPERTY_SP_COST_PCT)/100.0))
end

function CExtAbilityLinker:GetStaminaUpkeep()
	local hEntity = self:GetCaster()
	local fStaminaUpkeep = self._fStaminaUpkeep or 0
	local tBaseFunctions = self._tBaseFunctions
	local nAbilityFlags = self:GetAbilityFlags()
	if tBaseFunctions and tBaseFunctions.GetStaminaUpkeep then
		fStaminaUpkeep = tBaseFunctions.GetStaminaUpkeep(self)
	end
	fStaminaUpkeep = fStaminaUpkeep * (1.0 + hEntity:GetPropertyValue(IW_PROPERTY_SP_COST_PCT)/100.0)
	return fStaminaUpkeep
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

--[[function CExtAbilityLinker:GetIntrinsicModifierName()
	local tBaseFunctions = self._tBaseFunctions
	if tBaseFunctions then
		local hBaseFunction = tBaseFunctions.GetIntrinsicModifierName
		if hBaseFunction then
			return hBaseFunction(self)
		end
	end
	return self._szIntrinsicModifierName
end]]

function CExtAbilityLinker:CheckSkillRequirements(hEntity)
	if IsServer() then
		local nAbilitySkill = self:GetSkillRequirements()
		for i=1,4 do
			local nLevel = bit32.extract(nAbilitySkill, (i-1)*8, 3)
			local nSkill = bit32.extract(nAbilitySkill, ((i-1)*8)+3, 5)
			--TODO: Make this not hardcoded
			if nSkill ~= 0 and nSkill <= 26 then
				if hEntity:GetPropertyValue(IW_PROPERTY_SKILL_FIRE + nSkill - 1) < nLevel then
					return false
				end
			end
		end
	end
	return true
end

function CExtAbilityLinker:IsSkillRequired(nSkill)
	if IsServer() and stIcewrackSkillValues[nSkill] then
		local nAbilitySkill = self:GetSkillRequirements()
		for i=1,4 do
			if bit32.extract(nAbilitySkill, ((i-1)*8)+3, 5) == nSkill then
				return true
			end
		end
	end
	return false
end

function CExtAbilityLinker:IsWeatherAbility()
	return bit32.btest(self._nAbilityFlags, IW_ABILITY_FLAG_KEYWORD_WEATHER)
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
		for k,v in pairs(self._tPrereqCasterModifiers) do
			if not hEntity:HasModifier(v) then return false end
		end
		
		local nAbilityBehavior = self:GetBehavior()
		if bit32.btest(nAbilityBehavior, DOTA_ABILITY_BEHAVIOR_UNIT_TARGET) then
			if hTarget then
				for k,v in pairs(self._tPrereqTargetModifiers) do
					if not hTarget:HasModifier(v) then return false end
				end
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
		local hEntity = self:GetCaster()
		if not self:IsFullyCastable() then
			return UF_FAIL_CUSTOM
		end
	
		self._bCastFilterLock = true
		CTimer(0.03, function() self._bCastFilterLock = nil end)
		
		self._bSkillsFailed = false
		if not self:CheckSkillRequirements(hEntity) then
			self._bSkillsFailed = true
			return UF_FAIL_CUSTOM
		end
		
		
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
		
		self._bEventFailed = false
		if hEntity:TriggerExtendedEvent(IW_MODIFIER_EVENT_ON_CAST_FILTER) == UF_FAIL_CUSTOM then
			self._bEventFailed = true
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
		if self._bSkillsFailed then return "#iw_error_insufficient_skill" end
		if self._bFlagsFailed then return self:GetCustomCastErrorFlags(vLocation, hTarget) end
		if self._bPrereqFailed then return "#iw_error_prereq_not_met" end
		if self._bEventFailed then return self:GetCaster():TriggerExtendedEvent(IW_MODIFIER_EVENT_ON_CAST_ERROR) end
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
	local hCaster = self:GetCaster()
	local nResult = ExtUnitFilter(hCaster, hTarget, self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), self:GetAbilityTargetFlags())
	if nResult ~= UF_SUCCESS then
		return nResult
	end
	return self:CastFilterResult(nil, hTarget)
end

function CExtAbilityLinker:GetCustomCastErrorTarget(hTarget)
	local hCaster = self:GetCaster()
	local nResult = ExtUnitFilter(hCaster, hTarget, self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), self:GetAbilityTargetFlags())
	if nResult ~= UF_SUCCESS then
		return stUnitFilterCastErrors[nResult]
	end
	return self:GetCustomCastError(nil, hTarget)
end

function CExtAbilityLinker:OnAbilityLearned(hEntity)
	self:RemoveModifiers(IW_MODIFIER_ON_LEARN)
	self:ApplyModifiers(IW_MODIFIER_ON_LEARN, hEntity)
	local tBaseFunctions = self._tBaseFunctions
	if tBaseFunctions then
		local hBaseFunction = tBaseFunctions.OnAbilityLearned
		if hBaseFunction then
			return hBaseFunction(self, hEntity)
		end
	end
end

function CExtAbilityLinker:OnAbilityPhaseStart()
	local hEntity = self:GetCaster()
	hEntity:TriggerExtendedEvent(IW_MODIFIER_EVENT_ON_PRE_ABILITY_CAST, self)
	
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
	
	local fStaminaCost = self:GetStaminaCost()
	if fStaminaCost > 0 and IsValidExtendedEntity(hEntity) then
		local fCurrentStamina = hEntity:GetStamina()
		if fCurrentStamina > fStaminaCost then
			hEntity:SpendStamina(fStaminaCost)
		end
	end
	
	self:ApplyModifiers(IW_MODIFIER_ON_USE)
	local hCursorTarget = self:GetCursorTarget()
	if hCursorTarget and hEntity:IsTargetEnemy(hCursorTarget) then
		hEntity:SetAttacking(hCursorTarget)
	end
	
	local tBaseFunctions = self._tBaseFunctions
	if tBaseFunctions then
		local hBaseFunction = tBaseFunctions.OnSpellStart
		if hBaseFunction then
			hBaseFunction(self)
		end
	end
	
	hEntity:TriggerExtendedEvent(IW_MODIFIER_EVENT_ON_POST_ABILITY_CAST, self)
end

function CExtAbilityLinker:OnChannelThink(fInterval)
	local hEntity = self:GetCaster()
	local fManaUpkeep = self:GetManaUpkeep() * fInterval
	if fManaUpkeep > 0 then
		local fEntityMana = hEntity:GetMana()
		if fManaUpkeep >= fEntityMana then
			hEntity:SetMana(0)
			hEntity:Interrupt()
		else
			hEntity:SetMana(fEntityMana - fManaUpkeep)
		end
	end
	local fStaminaUpkeep = self:GetStaminaUpkeep() * fInterval
	if fStaminaUpkeep > 0 then
		local fEntityStamina = hEntity:GetStamina()
		if fStaminaUpkeep >= fEntityStamina then
			hEntity:Interrupt()
		else
			hEntity:SpendStamina(fStaminaUpkeep)
		end
	end
	
	local tBaseFunctions = self._tBaseFunctions
	if tBaseFunctions then
		local hBaseFunction = tBaseFunctions.OnChannelThink
		if hBaseFunction then
			hBaseFunction(self, fInterval)
		end
	end
end

function CExtAbilityLinker:OnChannelFinish(bInterrupted)
	self:ApplyModifiers(IW_MODIFIER_ON_CHANNEL_END)
	if not bInterrupted then self:ApplyModifiers(IW_MODIFIER_ON_CHANNEL_SUCCESS) end
	local tBaseFunctions = self._tBaseFunctions
	if tBaseFunctions then
		local hBaseFunction = tBaseFunctions.OnChannelFinish
		if hBaseFunction then
			hBaseFunction(self)
		end
	end
end

local function OnExtAbilityUpkeepThink(self)
	local hEntity = self:GetCaster()
	if self:GetToggleState() then
		local fManaUpkeep = self:GetManaUpkeep()/10.0
		if fManaUpkeep > 0 then
			local fEntityMana = hEntity:GetMana()
			if fManaUpkeep >= fEntityMana then
				hEntity:SetMana(0)
				self:ToggleAbility()
				return
			else
				hEntity:SetMana(fEntityMana - fManaUpkeep)
			end
		end
		local fStaminaUpkeep = self:GetStaminaUpkeep()/10.0
		if fStaminaUpkeep > 0 then
			local fEntityStamina = hEntity:GetStamina()
			hEntity:SpendStamina(fStaminaUpkeep)
			if fStaminaUpkeep >= fEntityStamina then
				self:ToggleAbility()
				return
			end
		end
		return 0.1
	end
end

function CExtAbilityLinker:OnToggle()
	if self:GetToggleState() then
		self:ApplyModifiers(IW_MODIFIER_ON_TOGGLE)
		if self:GetManaUpkeep() > 0 or self:GetStaminaUpkeep() > 0 then
			CTimer(0.03, OnExtAbilityUpkeepThink, self)
		end
		self:EndCooldown()
	else
		self:RemoveModifiers(IW_MODIFIER_ON_TOGGLE)
		local fCooldownTime = self:GetCooldown(self:GetLevel())
		if fCooldownTime > 0 then
			self:StartCooldown(fCooldownTime)
		end
	end
	local tBaseFunctions = self._tBaseFunctions
	if tBaseFunctions then
		local hBaseFunction = tBaseFunctions.OnToggle
		if hBaseFunction then
			hBaseFunction(self)
		end
	end
end

function CExtAbilityLinker:OnToggleAutoCast()
	--Unlike OnToggle(), OnToggleAutoCast() is called when the command is issued, not when the ability changes toggle states
	if not self:GetAutoCastState() then
		self:ApplyModifiers(IW_MODIFIER_ON_TOGGLE)
		if self:GetManaUpkeep() > 0 or self:GetStaminaUpkeep() > 0 then
			CTimer(0.03, OnExtAbilityUpkeepThink, self)
		end
	else
		self:RemoveModifiers(IW_MODIFIER_ON_TOGGLE)
	end
	local tBaseFunctions = self._tBaseFunctions
	if tBaseFunctions then
		local hBaseFunction = tBaseFunctions.OnToggleAutoCast
		if hBaseFunction then
			hBaseFunction(self)
		end
	end
end

local function OnOwnerDiedToggleThink(self)
	if self:GetToggleState() then
		self:ToggleAbility()
		return 0.03
	elseif self:GetAutoCastState() then
		self:ToggleAutoCast()
		return 0.03
	end
end

function CExtAbilityLinker:OnOwnerDied()
	local tBaseFunctions = self._tBaseFunctions
	if tBaseFunctions then
		local hBaseFunction = tBaseFunctions.OnOwnerDied
		if hBaseFunction then
			hBaseFunction(self)
		end
	end
	
	local nAbilityFlags = self:GetAbilityFlags()
	if bit32.btest(nAbilityFlags, IW_ABILITY_FLAG_TOGGLE_OFF_ON_DEATH) then
		CTimer(0.03, OnOwnerDiedToggleThink, self)
	end
end

function CExtAbilityLinker:OnRefreshEntity()
	local tBaseFunctions = self._tBaseFunctions
	if tBaseFunctions then
		local hBaseFunction = tBaseFunctions.OnRefreshEntity
		if hBaseFunction then
			hBaseFunction(self)
		end
	end
end

function CExtAbilityLinker:OnAbilityBind(hEntity)
	if self:CheckSkillRequirements(hEntity) then
		self:ApplyModifiers(IW_MODIFIER_ON_ACQUIRE, hEntity)
		local tBaseFunctions = self._tBaseFunctions
		if tBaseFunctions then
			local hBaseFunction = tBaseFunctions.OnAbilityBind
			if hBaseFunction then
				hBaseFunction(self, hEntity)
			end
		end
	end
end

function CExtAbilityLinker:OnAbilityUnbind(hEntity)
	if self:GetToggleState() then
		self:ToggleAbility()
	elseif self:GetAutoCastState() then
		self:ToggleAutoCast()
	end
	self:RemoveModifiers(IW_MODIFIER_ON_ACQUIRE, hEntity)
	
	local tBaseFunctions = self._tBaseFunctions
	if tBaseFunctions then
		local hBaseFunction = tBaseFunctions.OnAbilityUnbind
		if hBaseFunction then
			hBaseFunction(self, hEntity)
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
	local tContext = getfenv()
	local szScriptFilename = tExtTemplate.ScriptFile
	if szScriptFilename then
		szScriptFilename = string.gsub(szScriptFilename, "\\", "/")
		szScriptFilename = string.gsub(szScriptFilename, "scripts/vscripts/", "")
		szScriptFilename = string.gsub(szScriptFilename, ".lua", "")
		local tSandbox = setmetatable({}, { __index = tContext })
		setfenv(1, tSandbox)
		dofile(szScriptFilename)
		tContext[szAbilityName] = tSandbox[szAbilityName]
		setfenv(1, tContext)
	end
	
	if not tContext[szAbilityName] then tContext[szAbilityName] = class({}) end
	local hExtAbility = tContext[szAbilityName]
	
	for k,v in pairs(tBaseTemplate.Modifiers or {}) do
		LinkLuaModifier(k, "link_ext_modifier", LUA_MODIFIER_MOTION_NONE)
	end
	
	hExtAbility._tBaseFunctions = {}
	for k,v in pairs(hExtAbility) do
		if type(hExtAbility[k]) == "function" then
			hExtAbility._tBaseFunctions[k] = hExtAbility[k]
		end
	end
	ExtendIndexTable(hExtAbility, CExtAbilityLinker)
	
	hExtAbility._tPropertyList = {}
	for k,v in pairs(tExtTemplate.Properties or {}) do
		if stIcewrackPropertyEnum[k] then
			if type(v) == "number" then
				hExtAbility._tPropertyList[k] = v
			else
				LogMessage("Unsupported type \"" .. type(v) .. "\" for property \"" .. k .. "\" in ability \"" .. szAbilityName .. "\"", LOG_SEVERITY_WARNING)
			end
		else
			LogMessage("Unknown property \"" .. k .. "\" in ability \"" .. szAbilityName .. "\"", LOG_SEVERITY_WARNING)
		end
	end
	
	--hExtAbility._szIntrinsicModifierName = tExtTemplate.IntrinsicModifier
	
	hExtAbility._nAbilitySkill = tExtTemplate.AbilitySkill or 0
	--hExtAbility._nAbilityBehavior = GetFlagValue(tBaseTemplate.AbilityBehavior, DOTA_ABILITY_BEHAVIOR)
	hExtAbility._nAbilityTargetTeam = DOTA_UNIT_TARGET_TEAM[tBaseTemplate.AbilityUnitTargetTeam]
	hExtAbility._nAbilityTargetType = GetFlagValue(tBaseTemplate.AbilityUnitTargetType, DOTA_UNIT_TARGET_TYPE)
	hExtAbility._nAbilityTargetFlags = GetFlagValue(tBaseTemplate.AbilityUnitTargetFlags, DOTA_UNIT_TARGET_FLAGS)
	hExtAbility._nAbilityFlags = GetFlagValue(tExtTemplate.AbilityFlags, stExtAbilityFlagEnum)
	hExtAbility._nAbilityAOERadius = tonumber(tBaseTemplate.AbilityAOERadius) or 0
	
	hExtAbility._fManaUpkeep = tExtTemplate.ManaUpkeep or 0
	hExtAbility._fStaminaUpkeep = tExtTemplate.StaminaUpkeep or 0
	
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
	
	hExtAbility._tAbilityCastAnimations = {}
	hExtAbility._tAbilityPlaybackRates = {}
	if type(tExtTemplate.AbilityCastAnimation) == "table" then
		for k,v in pairs(tExtTemplate.AbilityCastAnimation) do
			hExtAbility._tAbilityCastAnimations[k] = {}
			hExtAbility._tAbilityPlaybackRates[k] = {}
			for k2,v2 in pairs(v) do
				table.insert(hExtAbility._tAbilityCastAnimations[k], k2)
				table.insert(hExtAbility._tAbilityPlaybackRates[k], v2)
			end
		end
	end
	
	if IsServer() then
		local tExtAbilityPrereqs = tExtTemplate.Prequisites or {}
			
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