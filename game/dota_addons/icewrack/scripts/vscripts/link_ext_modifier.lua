if IsServer() then
require("timer")
require("instance")
require("ext_modifier")
require("link_functions")
end

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
if not _G.stExtModifierTemplates then
	_G.stExtModifierTemplates = {}
end

local function ApplyPropertyValues(self)
	local hTarget = self:GetParent()
	if IsValidInstance(hTarget) then
		hTarget:UpdateNetTable()
	end
end

local function RemovePropertyValues(self)
	local hTarget = self:GetParent()
	if IsValidInstance(hTarget) then
		hTarget:UpdateNetTable()
	end
end

function RefreshModifier(self, bRerollRandom)
	RemovePropertyValues(self)
	for k,v in pairs(self._tPropertyList or {}) do
		local szPropertyType = type(v)
		if szPropertyType == "table" and (bRerollRandom or not rawget(self._tPropertyValues, k)) then
			local k2,v2 = next(v)
			k2 = (type(k2) == "string" and string.sub(k2, 1, 1) == "%") and self._tModifierArgs[string.sub(k2, 2, #k2)] or tonumber(k2)
			v2 = (type(v2) == "string" and string.sub(v2, 1, 1) == "%") and self._tModifierArgs[string.sub(v2, 2, #v2)] or v2
			if k2 and type(k2) == "number" and v2 and type(v2) == "number" then
				local nModifierSeed = self:GetAbility():GetModifierSeed(self:GetName(), k)
				self:SetPropertyValue(k, k2 + (nModifierSeed % v2))
			end
		elseif szPropertyType == "number" then
			self:SetPropertyValue(k, v)
		elseif szPropertyType == "string" and string.sub(v, 1, 1) == "%" then
			self:SetPropertyValue(k, self._tModifierArgs[string.sub(v, 2, #v)])
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
		local tModifierList = hParent:FindAllModifiers()
		for k,v in pairs(tModifierList) do
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
		hTarget:AddChild(self)
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
		
		if IsValidExtendedEntity(hTarget) then
			if self:IsDebuff() then
				local hCaster = self:GetCaster()
				hCaster:SetAttacking(hTarget)
			end
			
			local tExtModifierEvents = self:DeclareExtEvents()
			for k,v in pairs(tExtModifierEvents) do
				local tExtModifierEventList = hTarget._tExtModifierEventTable[k]
				local tExtModifierEventIndex = hTarget._tExtModifierEventIndex[k]
				if not tExtModifierEventList then
					hTarget._tExtModifierEventTable[k] = { [self] = v }
					hTarget._tExtModifierEventIndex[k] = { self }
				else
					local bIsAdded = false
					for k2,v2 in pairs(tExtModifierEventIndex) do
						if tExtModifierEventList[v2] > v then
							bIsAdded = true
							table.insert(tExtModifierEventIndex, k2, self)
							break
						end
					end
					if not bIsAdded then
						table.insert(tExtModifierEventIndex, self)
					end
					tExtModifierEventList[self] = v
				end
			end
			hTarget:AddToRefreshList(self)
		end
	end
end

local function OnModifierDestroyDefault(self)
	local hTarget = self:GetParent()
	if IsServer() and IsValidInstance(hTarget) then
		RemovePropertyValues(self)
		hTarget:RemoveChild(self)
		if IsValidExtendedEntity(hTarget) then
			local tExtModifierEvents = self:DeclareExtEvents()
			for k,v in pairs(tExtModifierEvents) do
				local tExtModifierEventList = hTarget._tExtModifierEventTable[k]
				local tExtModifierEventIndex = hTarget._tExtModifierEventIndex[k]
				tExtModifierEventList[self] = nil
				for k2,v2 in pairs(tExtModifierEventIndex) do
					if v2 == self then
						table.remove(tExtModifierEventIndex, k2)
						break
					end
				end
			end
			hTarget:RemoveFromRefreshList(self)
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
	local hTarget = self:GetParent()
	if IsServer() and IsValidExtendedEntity(hTarget) then
		hTarget:RefreshEntity()
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

function GetModifierSeedList(self)
	return self._tModifierSeedList
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
		
	end
end

local function ParseDatadrivenProperties(hLuaModifier, tLinkLuaModifierTemplate)
	local tDatadrivenProperties = tLinkLuaModifierTemplate.DatadrivenProperties
	if tDatadrivenProperties then
		hLuaModifier._tDatadrivenPropertyTable = {}
		for k,v in pairs(tDatadrivenProperties) do
			local nPropertyID = modifierproperty[k]
			local szPropertyAlias = stLuaModifierPropertyAliases[k]
			if szPropertyAlias then
				if type(v) == "table" then
					table.insert(hLuaModifier._tModifierSeedList, nPropertyID + 1000)
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
							local nModifierSeed = self:GetAbility():GetModifierSeed(self:GetName(), nPropertyID + 1000)
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
end

local function ParseDatadrivenEvents(hLuaModifier, tLinkLuaModifierTemplate)
	local tDatadrivenEvents = tLinkLuaModifierTemplate.DatadrivenEvents
	if tDatadrivenEvents and IsServer() then
		for k,v in pairs(tDatadrivenEvents) do
			local szEventAlias = stLuaModifierEventAliases[k]
			if szEventAlias then
				for k2,v2 in pairs(v) do
					local hEventFunction = GetLinkedFunction(k2,v2)
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

local function ParseExtendedEvents(hLuaModifier, tLinkLuaModifierTemplate)
	local tExtendedEvents = tLinkLuaModifierTemplate.ExtendedEvents
	if tExtendedEvents and IsServer() then
		for k,v in pairs(tExtendedEvents) do
			local nEventID = stExtModifierEventValues[k]
			local szEventAlias = stExtModifierEventAliases[nEventID]
			local nEventPriority = v.Priority
			if nEventID and type(nEventPriority) == "number" then
				for k2,v2 in pairs(v) do
					local hEventFunction = GetLinkedFunction(k2,v2)
					local hBaseFunction = hLuaModifier[szEventAlias]
					if hEventFunction then
						local hWrappedEventFunction = 
						function(self, args)
							if IsServer() and not self:IsNull() then
								local params = {}
								for k3,v3 in pairs(v2) do
									params[k3] = (type(v3) == "string" and string.sub(v3, 1, 1) == "%") and self._tModifierArgs[string.sub(v3, 2, #v3)] or v3
								end
								hEventFunction(self, params)
								if hBaseFunction and type(hBaseFunction) == "function" then
									return hBaseFunction(self, args, params)
								end
							end
						end
						hLuaModifier._tDeclareExtEventList[nEventID] = nPriority
						hLuaModifier[szEventAlias] = hWrappedEventFunction
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
		_G.stExtModifierTemplates[k2] = hLuaModifier
		
		if not hLuaModifier._tDeclareFunctionList then hLuaModifier._tDeclareFunctionList = {} end
		if not hLuaModifier._tDeclareExtEventList then hLuaModifier._tDeclareExtEventList = {} end
		if not hLuaModifier._tOnCreatedList then hLuaModifier._tOnCreatedList = {} end
		if not hLuaModifier._tOnDestroyList then hLuaModifier._tOnDestroyList = {} end
		if not hLuaModifier._tOnRefreshList then hLuaModifier._tOnRefreshList = {} end
		if not hLuaModifier._tModifierSeedList then hLuaModifier._tModifierSeedList = {} end
		
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
			hLuaModifier.GetModifierSeedList = GetModifierSeedList
			
			hLuaModifier._fDuration = tLinkLuaModifierTemplate.Duration or -1
			hLuaModifier._nMaxStacks = tLinkLuaModifierTemplate.MaxStacks or 0
			hLuaModifier._nMaxStacksPerCaster = tLinkLuaModifierTemplate.MaxStacksPerCaster or 0
			
			hLuaModifier._tPropertyList = {}
			for k3,v3 in pairs(tLinkLuaModifierTemplate.Properties or {}) do
				local nPropertyID = stIcewrackPropertyEnum[k3]
				if nPropertyID then
					hLuaModifier._tPropertyList[nPropertyID] = v3
					if type(v3) == "table" then
						table.insert(hLuaModifier._tModifierSeedList, nPropertyID)
					end
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
			
			tLinkLuaModifierTemplate.GetModifierSeedList = GetModifierSeedList
			
			ParseDatadrivenEvents(hLuaModifier, tLinkLuaModifierTemplate)
			ParseExtendedEvents(hLuaModifier, tLinkLuaModifierTemplate)
		end
		
		hLuaModifier._nModifierID = 0
		hLuaModifier.RetrieveModifierID = function(self) hLuaModifier._nModifierID = hLuaModifier._nModifierID + 1 return hLuaModifier._nModifierID end
		hLuaModifier._tModifierNetTable = {}
		
		if hLuaModifier.CheckState then
			local tBaseResults = hLuaModifier:CheckState()
			for k,v in pairs(tBaseResults or {}) do
				hLuaModifier._tDatadrivenStateTable[k] = v
			end
		end
		if hLuaModifier.DeclareFunctions then
			local tBaseResults = hLuaModifier:DeclareFunctions()
			for k,v in pairs(tBaseResults or {}) do
				table.insert(hLuaModifier._tDeclareFunctionList, v)
			end
		end
		if hLuaModifier.DeclareExtEvents then
			local tBaseResults = hLuaModifier:DeclareExtEvents()
			for k,v in pairs(tBaseResults or {}) do
				hLuaModifier._tDeclareExtEventList[k] = v
			end
		end
		
		hLuaModifier.CheckState = function() return hLuaModifier._tDatadrivenStateTable end
		hLuaModifier.DeclareFunctions = function() return hLuaModifier._tDeclareFunctionList end
		hLuaModifier.DeclareExtEvents = function() return hLuaModifier._tDeclareExtEventList end
		
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