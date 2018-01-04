--[[
    Icewrack Spellbook
]]

if not CSpellbook then

require("ext_ability")
require("ext_modifier")

stSpellbookTypeEnum =
{  
    IW_SPELLBOOK_TYPE_ENTITY = 1,
	IW_SPELLBOOK_TYPE_ITEM = 2,
}
for k,v in pairs(stSpellbookTypeEnum) do _G[k] = v end

local stAbilityComboData = LoadKeyValues("scripts/npc/npc_abilities_combo.txt")

CSpellbook = setmetatable(ext_class({ _stAbilityCombos = {} }), { __call = 
	function(self, hEntity, nInstanceID)
		LogAssert(IsInstanceOf(hEntity, CDOTA_BaseNPC) or IsInstanceOf(hEntity, CDOTA_Item), LOG_MESSAGE_ASSERT_TYPE, "CExtEntity\" or \"CDOTA_Item")
		if IsInstanceOf(hEntity, CSpellbook) then
			LogMessage(LOG_MESSAGE_WARN_EXISTS, LOG_SEVERITY_WARNING, "CSpellbook", hEntity:GetName())
			return hEntity
		end
		
		if not IsInstanceOf(hEntity, CInstance) then
			hEntity = CInstance(hEntity, nInstanceID)
		end
		ExtendIndexTable(hEntity, CSpellbook)
		
		hEntity._tSpellList = {}
		hEntity._tSpellDummies = {}
		hEntity._hSpellbookParent = hEntity
		hEntity._tSpellbookChildren = {}
		
		hEntity._tSpellbookNetTable =
		{
			Spells = {},
			Children = {},
		}
		
		hEntity:UpdateSpellbookNetTable()
		return hEntity
	end})

function CSpellbook:GetSpellbookParent()
	local hParent = self._hSpellbookParent
	if hParent and IsInstanceOf(hParent, CSpellbook) then
		if hParent == self then
			return self
		else
			return hParent:GetSpellbookParent() or hParent
		end
	end
end

function CSpellbook:SetSpellbookParent(hParent)
	if IsInstanceOf(hParent, CSpellbook) then
		if IsInstanceOf(hParent, CDOTA_BaseNPC) then
			for k,v in pairs(self._tSpellList) do
				local hAbility = v:FindAbilityByName(k)
				if hAbility then
					hAbility:SetCaster(hParent)
					hAbility:SetOwner(hParent)
					hAbility:OnAbilityLearned(hParent)
				end
			end
		end
		self._hSpellbookParent = hParent
		for k,v in pairs(self._tSpellbookChildren) do
			k:SetSpellbookParent(hParent)
		end
	end
end

function CSpellbook:FindAbilityByName(szAbilityName)
	local hSpellUnit = self._tSpellList[szAbilityName]
	if hSpellUnit then
		return hSpellUnit:FindAbilityByName(szAbilityName)
	else
		for k,v in pairs(self._tSpellbookChildren) do
			local hAbility = k:FindAbilityByName(szAbilityName)
			if hAbility then
				return hAbility
			end
		end
	end
	if IsInstanceOf(self, CDOTA_BaseNPC) then
		return CDOTA_BaseNPC.FindAbilityByName(self, szAbilityName)
	end
end

function CSpellbook:OnRefreshEntity()
	self:UpdateSpellbookNetTable()
end

function CSpellbook:AddChild(hNode)
	if IsInstanceOf(hNode, CSpellbook) then
		local hOldParent = hNode:GetSpellbookParent()
		if hOldParent and hOldParent ~= hNode then
			hOldParent:RemoveChild(hNode)
		end
		
		local hNewParent = self:GetSpellbookParent() or self
		hNode:SetSpellbookParent(hNewParent)
		
		self._tSpellbookChildren[hNode] = true
		self._tSpellbookNetTable.Children[hNode:entindex()] = true
		self:UpdateSpellbookNetTable()
	end
	CInstance.AddChild(self, hNode)
end

function CSpellbook:RemoveChild(hNode)
	if IsInstanceOf(hNode, CSpellbook) and self._tSpellbookChildren[hNode] then
		self._tSpellbookChildren[hNode] = nil
		self._tSpellbookNetTable.Children[hNode:entindex()] = nil
		hNode:SetSpellbookParent(hNode)
	end
	CInstance.RemoveChild(self, hNode)
end

function CSpellbook:LearnAbility(szAbilityName, nInstanceID)
	if szAbilityName and not self._tSpellList[szAbilityName] then
		local hOwner = self:GetOwner()
		local hSpellDummy = nil
		for k,v in pairs(self._tSpellDummies) do
			for i = 0,15 do
				if not v:GetAbilityByIndex(i) then
					hSpellDummy = v
					break
				end
			end
			if hSpellDummy then
				break
			end
		end
		
		if not hSpellDummy then
			hSpellDummy = CreateDummyUnit(self:GetAbsOrigin(), hOwner, self:GetTeamNumber(), true)
			table.insert(self._tSpellDummies, hSpellDummy)
		end
		hSpellDummy:AddAbility(szAbilityName)
		
		local hSpellParent = self:GetSpellbookParent() or self
		local hAbility = CExtAbility(hSpellDummy:FindAbilityByName(szAbilityName), hSpellParent, nInstanceID)
		if IsInstanceOf(hAbility, CDOTA_Ability_DataDriven) then
			hSpellDummy:RemoveAbility(szAbilityName)
			return
		else
			hAbility:SetLevel(1)
			if IsInstanceOf(self, CDOTA_BaseNPC) then
				hAbility:SetOwner(hSpellParent)
				hAbility:ApplyModifiers(IW_MODIFIER_ON_LEARN, hSpellParent)
				hAbility:OnAbilityLearned(hSpellParent)
			end

			self._tSpellList[szAbilityName] = hSpellDummy
			self._tSpellbookNetTable.Spells[hAbility:entindex()] = szAbilityName
			self:UpdateSpellbookNetTable()
			return hAbility
		end
	elseif self._tSpellList[szAbilityName] then
		hSpellUnit = self._tSpellList[szAbilityName]
		local hAbility = hSpellUnit:FindAbilityByName(szAbilityName)
		if hAbility then
			self:UpdateSpellbookNetTable()
			return hAbility
		end
	end
end

function CSpellbook:UnlearnAbility(szAbilityName)
	if self._tSpellList[szAbilityName] then
		local hAbility = self._tSpellList[szAbilityName]:FindAbilityByName(szAbilityName)
		if hAbility then
			local nAbilityIndex = hAbility:entindex()
			for k,v in pairs(self._tBindTable) do
				if v == nAbilityIndex then
					self._tBindTable[k] = -1
					self._tSpellbookNetTable.Binds[k] = nil
				end
			end
			if hAbility:GetToggleState() then
				hAbility:ToggleAbility()
			end
			if IsInstanceOf(self, CDOTA_BaseNPC) then
				hAbility:RemoveModifiers(IW_MODIFIER_ON_ACQUIRE, self)
				hAbility:RemoveModifiers(IW_MODIFIER_ON_LEARN, self)
			end
		end
		self._tSpellList[szAbilityName]:RemoveAbility(szAbilityName)
		self._tSpellList[szAbilityName] = nil
		
		for k,v in pairs(self._tNetTable.Spells) do
			if v == szAbilityName then
				table.remove(self._tNetTable.Spells, k)
				break
			end
		end
		self:UpdateSpellbookNetTable()
		return true
	end
	return false
end

function CSpellbook:UpdateSpellbookNetTable()
	local tSpellbookNetTable = self._tSpellbookNetTable
	for k,v in pairs(tSpellbookNetTable.Spells) do
		local hAbility = EntIndexToHScript(k)
		hAbility:UpdateAbilityNetTable()
	end
	CustomNetTables:SetTableValue("spellbook", tostring(self:entindex()), tSpellbookNetTable)
end

end