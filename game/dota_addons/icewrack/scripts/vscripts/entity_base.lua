--[[
    Icewrack Entity Base
]]


if not CEntityBase then

IW_DEFAULT_INTERACT_RANGE = 128

local stInteractableResultEnum =
{
	IW_INTERACTABLE_RESULT_FAIL = 0,
	IW_INTERACTABLE_RESULT_SUCCESS = 1,
	IW_INTERACTABLE_RESULT_EN_ROUTE = 2,
}

for k,v in pairs(stInteractableResultEnum) do _G[k] = v end

CEntityBase = setmetatable(ext_class({}), { __call = 
	function(self, hEntity, nInstanceID)
		LogAssert(IsInstanceOf(hEntity, CDOTA_BaseNPC), LOG_MESSAGE_ASSERT_TYPE, "CDOTA_BaseNPC", type(hEntity))
		if IsInstanceOf(hEntity, CEntityBase) then
			return hEntity
		end
		
		hEntity = CInstance(hEntity, nInstanceID)
		ExtendIndexTable(hEntity, CEntityBase)
		
		hEntity._nFactionMask = 0
		hEntity._fInteractRange = IW_DEFAULT_INTERACT_RANGE
		hEntity._szInteractZone = nil
		
		hEntity._tRefreshList = {}
		
		return hEntity
	end})
	
function CEntityBase:IsEnemy(hTarget)
	if IsValidFactionEntity(hTarget) then
	--TODO: Implement me
	
	end
end

function CEntityBase:SetFactionMask(nFactionMask)
	if type(nFactionMask) == "number" then
		self._nFactionMask = nFactionMask
	end
end
	
function CEntityBase:GetFactionWeight(nFactionMask)

	--TODO: Implement me
end

function CEntityBase:AddToRefreshList(hEntity)
	table.insert(self._tRefreshList, 1, hEntity)
end

function CEntityBase:RemoveFromRefreshList(hEntity)
	for k,v in ipairs(self._tRefreshList) do
		if v == hEntity then
			table.remove(self._tRefreshList, k)
			break
		end
	end
end

function CEntityBase:RefreshEntity()
	for k,v in ipairs(self._tRefreshList) do
		v:OnEntityRefresh()
	end
	
	local tEntityMetatable = getmetatable(self).__index
	while type(tEntityMetatable) == "table" do
		local hEventFunction = rawget(tEntityMetatable, "OnEntityRefresh")
		if hEventFunction then
			hEventFunction(self)
		end
		local tParentMetatable = getmetatable(tEntityMetatable)
		if tParentMetatable then
			tEntityMetatable = tParentMetatable.__index
		else
			break
		end
	end
end

function CEntityBase:IsInInteractRange(hEntity)
	local fDistance = self:GetRangeToUnit(hEntity) - self:GetHullRadius() - hEntity:GetHullRadius()
	if fDistance > self:GetInteractRange() then
		return false
	end
	if self._szInteractZone then
		local hTrigger = Entities:FindByName(nil, self._szInteractZone)
		if IsInstanceOf(hTrigger, CBaseTrigger) and not hTrigger:IsTouching(hEntity) then
			return false
		end
	end
	return true
end

function CEntityBase:InteractFilterInclude(hEntity)
	return false
end

function CEntityBase:InteractFilterExclude(hEntity)
	return false
end

function CEntityBase:Interact(hEntity)
	return false
end

function CEntityBase:GetCustomInteractError(hEntity)
	return nil
end

function CEntityBase:GetInteractRange()
	return self._fInteractRange
end

function CEntityBase:GetInteractZone()
	if self._szInteractZone then
		local hTrigger = Entities:FindByName(nil, self._szInteractZone)
		if hTrigger and hTrigger.IsTouching then
			return hTrigger
		end
	end
end

function CEntityBase:SetInteractRange(fRange)
	if type(fRange) == "number" then
		self._fInteractRange = fRange
	end
end

function CEntityBase:SetInteractZone(szInteractZone)
	if type(szInteractZone) == "string" then
		self._szInteractZone = szInteractZone
	end
end

function CEntityBase:OnInteractFilter(hEntity)
	local tIndexMetatable = self
	while tIndexMetatable do
		local hIncludeFunction = rawget(tIndexMetatable, "InteractFilterInclude")
		local hExcludeFunction = rawget(tIndexMetatable, "InteractFilterExclude")
		if hIncludeFunction and hIncludeFunction(self, hEntity) then
			return true
		elseif hExcludeFunction and not hExcludeFunction(self, hEntity) then
			return false
		end
		tIndexMetatable = getmetatable(tIndexMetatable).__index
	end
	return false
end

function CEntityBase:OnInteract(hEntity)
	local tIndexMetatable = self
	while tIndexMetatable do
		local hFunction = rawget(tIndexMetatable, "Interact")
		if hFunction then
			local bResult = hFunction(self, hEntity)
			if type(bResult) == "boolean" then return bResult end
		end
		tIndexMetatable = getmetatable(tIndexMetatable).__index
	end
	return true
end

function CEntityBase:OnGetCustomInteractError(hEntity)
	local tIndexMetatable = self
	while tIndexMetatable do
		local hFunction = rawget(tIndexMetatable, "GetCustomInteractError")
		if hFunction then
			local szMessage = hFunction(self, hEntity)
			if type(szMessage) == "boolean" then return szMessage end
		end
		tIndexMetatable = getmetatable(tIndexMetatable).__index
	end
	return true
end
	
end