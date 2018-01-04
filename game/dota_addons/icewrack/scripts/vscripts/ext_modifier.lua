--[[
    Icewrack Extended Modifier
]]

if not CExtModifier then

require("mechanics/status_effects")

local stExtModifierData = LoadKeyValues("scripts/npc/npc_modifiers_extended.txt")

CExtModifier = setmetatable(ext_class({}), { __call = 
	function(self, hModifier)
		LogAssert(IsInstanceOf(hModifier, CDOTA_Buff), LOG_MESSAGE_ASSERT_TYPE, "CDOTA_Buff")
		if IsInstanceOf(hModifier, CExtModifier) then
			LogMessage(LOG_MESSAGE_WARN_EXISTS, LOG_SEVERITY_WARNING, "CExtModifier", hModifier:GetName())
			return hModifier
		end

		ExtendIndexTable(hModifier, CExtModifier)

		local szModifierName = hModifier:GetName()
		local szAbilityName = nil
		local hAbility = hModifier:GetAbility()
		local tExtModifierTemplate = nil
		if hAbility then
			szAbilityName = hModifier:GetAbility():GetName()
			local tExtAbilityTemplate = stExtModifierData[szAbilityName] or {}
			tExtModifierTemplate = tExtAbilityTemplate[szModifierName]
		else
			for k,v in pairs(stExtModifierData) do
				for k2,v2 in pairs(v) do
					if k2 == szModifierName then
						szAbilityName = k
						tExtModifierTemplate = v2
						break
					end
				end
			end
		end
		
		LogAssert(tExtModifierTemplate, LOG_MESSAGE_ASSERT_TEMPLATE, szModifierName)
		
		hModifier._bIsLuaModifier = hModifier.OnCreated and true or false
		hModifier._szAbilityName = szAbilityName
		
		hModifier._nModifierAddFlags = GetFlagValue(tExtModifierTemplate.ModifierAddFlags, stExtEntityFlagEnum)
		hModifier._nModifierRemoveFlags = GetFlagValue(tExtModifierTemplate.ModifierRemoveFlags, stExtEntityFlagEnum)
		hModifier._bIsDispellable = tExtModifierTemplate.IsDispellable == 1
		hModifier._bIsStrict =  tExtModifierTemplate.IsStrict == 1
		
		if hModifier._fMinDuration and hModifier._fMaxDuration and hModifier._fMinDuration > hModifier._fMaxDuration then
			local fTemp = hModifier._fMinDuration
			hModifier._fMinDuration = hModifier._fMaxDuration
			hModifier._fMaxDuration = fTemp
		end
		
		local hTarget = hModifier:GetParent()
		if hTarget._bIsLuaModifier and hTarget._bIsExtendedEntity then
			hModifier:OnCreated({})
		end
		return hModifier
	end})

function CExtModifier:GetAbilityName()
	return self._szAbilityName
end

function CExtModifier:GetAddFlags()
	return self._nModifierAddFlags
end

function CExtModifier:GetRemoveFlags()
	return self._nModifierRemoveFlags
end

function CExtModifier:IsDispellable()
	return self._bIsDispellable
end

function CExtModifier:IsStrict()
	return self._bIsStrict
end

function CExtModifier:IsProvidedByAura()
	return (self._tModifierArgs["isProvidedByAura"] == 1)
end

function CExtModifier:GetRealDurationMultiplier(hTarget)
	local hSource = self:GetCaster()
	local fDurationMultiplier = 1.0
	if IsValidInstance(hTarget) and IsValidInstance(hSource) then
		if self:IsDebuff() then
			fDurationMultiplier = hTarget:GetSelfDebuffDuration()
			if self:GetModifierClass() == IW_MODIFIER_CLASS_PHYSICAL then
				fDurationMultiplier = fDurationMultiplier * (100 * hSource:GetOtherDebuffDuration())/(100 + hTarget:GetPhysicalDebuffDefense())
			elseif self:GetModifierClass() == IW_MODIFIER_CLASS_MAGICAL then
				fDurationMultiplier = fDurationMultiplier * (100 * hSource:GetOtherDebuffDuration())/(100 + hTarget:GetMagicalDebuffDefense())
			else
				fDurationMultiplier = fDurationMultiplier * hSource:GetOtherDebuffDuration()
			end
		else
			fDurationMultiplier = hTarget:GetSelfBuffDuration() * hSource:GetOtherBuffDuration()
		end
		
		local nStatusMask = self:GetStatusMask()
		local fMinStatusMultiplier = nil
		for i=IW_STATUS_EFFECT_FIRST,IW_STATUS_EFFECT_LAST do
			if bit32.btest(nStatusMask, bit32.lshift(1, i - 1)) then
				local fStatusMultiplier = hTarget:GetStatusEffectDurationMultiplier(i)
				if not fMinStatusMultiplier or fStatusMultiplier < fMinStatusMultiplier then
					fMinStatusMultiplier = fStatusMultiplier
				end
			end
		end
		
		if fMinStatusMultiplier then
			fDurationMultiplier = fDurationMultiplier * fMinStatusMultiplier
		end
	end
	return fDurationMultiplier
end

function CExtModifier:SetDuration(fDuration, bInformClient)
	local hSource = self:GetCaster()
	local hTarget = self:GetParent()
	
	local fDurationMultiplier = 1.0
	if not self:IsStrict() and IsValidInstance(hTarget) then
		fDurationMultiplier = self:GetRealDurationMultiplier(hTarget)
	end
	if fDuration == -1 then
		if fDurationMultiplier == 0 then
			fDuration = 0
		end
	else
		fDuration = fDuration * math.max(0.0, fDurationMultiplier)
	end
	CDOTA_Buff.SetDuration(self, fDuration, bInformClient)
	return fDuration
end

function CExtModifier:OnRefreshEntity()
	self:RefreshModifier()
end

function IsValidExtendedModifier(hModifier)
    return IsInstanceOf(hModifier, CExtModifier)
end

local function RemoveBuffDummy(hDummy)
	hDummy:RemoveSelf()
end

function AddModifier(szAbilityName, szModifierName, hTarget, hSource, tModifierArgs)
	if not tModifierArgs then tModifierArgs = {} end
	local hAbility = nil
	if type(szAbilityName) == "table" then
		hAbility = szAbilityName
	else
		local hBuffDummy = CreateDummyUnit(hTarget:GetAbsOrigin(), nil, hTarget:GetTeamNumber(), true)
		hBuffDummy:AddAbility(szAbilityName)
		hAbility = hBuffDummy:FindAbilityByName(szAbilityName)
		hAbility:SetOwner(hSource)
		hBuffDummy.RemoveBuffDummy = RemoveBuffDummy
		hBuffDummy:SetThink("RemoveBuffDummy", hBuffDummy, "BuffDummyRemoveThink", 0.03)
	end
	
	local szClassname = hAbility:GetClassname()
	if IsInstanceOf(hAbility, CDOTA_Ability_DataDriven) or IsInstanceOf(hAbility, CDOTA_Item_DataDriven) then
		hAbility:ApplyDataDrivenModifier(hSource, hTarget, szModifierName, tModifierArgs)
	else
		hTarget:AddNewModifier(hSource, hAbility, szModifierName, tModifierArgs)
	end
	
	local hModifier = nil
	local fLastTime = -1.0
	for _,v in pairs(hTarget:FindAllModifiers()) do
		if v:GetName() == szModifierName and v:GetCreationTime() > fLastTime then
			hModifier = v
		end
	end
	return hModifier
end

end