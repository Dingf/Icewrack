--[[
    Icewrack Party
]]
if not CParty then

require("ext_entity")

IW_MAX_PARTY_SIZE = 4

--The order in which to place party members by default.
--Technically only the first IW_MAX_PARTY_SIZE members are needed, but we include all of the locations
--for good measure. By default, this creates a loose box formation centered just behind the cursor.
stDefaultGridOrder =
{
	 1,  3, 11, 13,  7,
	 2,  6,  8, 12,  0,
	 4,  5,  9, 10, 14,
	15, 16, 17, 18, 19,
	20, 21, 22, 23, 24,
}

CParty = 
{
	_hFocusTarget = nil,
	_tGridValues = {},
	_tGridStates = {},
	_tMembers = {},
	_tNetTable =
	{
		Members = {},
		GridStates = {},
	}
}

for i = 0,24 do
	CParty._tGridStates[i] = 0
end

function CParty:GetPartyFocusTarget()
	return self._hFocusTarget
end

function CParty:SetPartyFocusTarget(hEntity)
	if IsValidExtendedEntity(hEntity) then
		self._hFocusTarget = hEntity
	end
end

function CParty:GetMemberBySlot(nSlot)
	return self._tMembers[nSlot]
end

function CParty:GetSlotByMember(hEntity)
	if hEntity.GetInstanceID then
		for k,v in pairs(self._tMembers) do
			if v == hEntity:GetInstanceID() then
				return k
			end
		end
	end
end

function CParty:GetPartySize()
	return #CParty._tMembers
end

function CParty:UpdateNetTable()
	local tMembersTable = CParty._tNetTable.Members
	for k,v in pairs(CParty._tMembers) do
		local hEntity = GetInstanceByID(v)
		if IsValidExtendedEntity(hEntity) then
			tMembersTable[k] = hEntity:entindex()
		end
	end
	local tGridStatesTable = CParty._tNetTable.GridStates
	for k,v in pairs(CParty._tGridStates) do
		tGridStatesTable[k] = v
		if v ~= 0 then
			local hEntity = GetInstanceByID(v)
			if hEntity then
				tGridStatesTable[k] = hEntity:entindex()
			end
		end
	end
	CustomNetTables:SetTableValue("party", "Members", tMembersTable)
	CustomNetTables:SetTableValue("party", "GridStates", tGridStatesTable)
end

--[[local function PartySetGoldAmount(self, nAmount)
	for k,v in pairs(CParty._tMembers) do
		local hEntity = GetInstanceByID(v)
		if hEntity then
			local hInventory = hEntity:GetInventory()
			CInventory.SetGoldAmount(hInventory, nAmount)
		end
	end
end

local function PartyAddGoldAmount(self, nAmount)
	for k,v in pairs(CParty._tMembers) do
		local hEntity = GetInstanceByID(v)
		if hEntity then
			local hInventory = hEntity:GetInventory()
			CInventory.AddGoldAmount(hInventory, nAmount)
		end
	end
end]]

local function InitPartyEntity(hEntity, nSlot)
	--local hInventory = hEntity:GetInventory()
	--local hPlayerHero = GameRules:GetPlayerHero()
	--if IsValidExtendedEntity(hPlayerHero) then
	--	hInventory:SetGoldAmount(hPlayerHero:GetInventory():GetGoldAmount())
	--end
	--hInventory.SetGoldAmount = PartySetGoldAmount
	--hInventory.AddGoldAmount = PartyAddGoldAmount
	CParty._tMembers[nSlot] = hEntity:GetInstanceID()
	CParty:SetPartyMemberFormation(hEntity)
	CParty:UpdateNetTable()
end

function CParty:AddToParty(hEntity, nSlot)
	local nPartySize = CParty:GetPartySize()
	if not nSlot then nSlot = nPartySize + 1 end
	if IsValidExtendedEntity(hEntity) and hEntity:IsHero() then
		if nSlot <= IW_MAX_PARTY_SIZE and nSlot > 0 then
			local nPrevSlot = CParty:GetSlotByMember(hEntity) or 0
			if nSlot == nPartySize + 1 and nPrevSlot == 0 then
				InitPartyEntity(hEntity, nSlot)
				return true
			elseif nSlot < nPartySize then
				if nPrevSlot == 0 and nPartySize < IW_MAX_PARTY_SIZE then
					CParty._tMembers[nPartySize + 1] = CParty._tMembers[nSlot]
					InitPartyEntity(hEntity, nSlot)
					return true
				elseif nPrevSlot ~= 0 then
					CParty._tMembers[nPrevSlot] = CParty._tMembers[nSlot]
					InitPartyEntity(hEntity, nSlot)
					return true
				end
			end
		end
	end
	return false
end

function CParty:RemoveFromParty(hEntity)
	if IsValidExtendedEntity(hEntity) then
		local nInstanceID = hEntity:GetInstanceID()
		for k,v in pairs(CParty._tMembers) do
			if v == nInstanceID then
				table.remove(CParty._tMembers, k)
				CParty:UpdateNetTable()
				break
			end
		end
	elseif type(hEntity) == "number" and hEntity > 0 and hEntity <= CParty:GetPartySize() then
		table.remove(CParty._tMembers, hEntity)
		CParty:UpdateNetTable()
	end
end

function CParty:GetPartyMemberFormation(hEntity)
	if IsValidExtendedEntity(hEntity) then
		return CParty._tGridValues[hEntity:GetInstanceID()]
	end
end

function CParty:SetPartyMemberFormation(hEntity, nLocation)
	if not nLocation then
		for k,v in ipairs(stDefaultGridOrder) do
			if CParty._tGridStates[v] == 0 then
				nLocation = v
				break
			end
		end
	end
	local nInstanceID = hEntity:GetInstanceID()
	for k,v in pairs(CParty._tMembers) do
		if v == nInstanceID and CParty._tGridStates[nLocation] then
			nLocation = math.floor(nLocation)
			if CParty._tGridStates[nLocation] ~= 0 and CParty._tGridStates[nLocation] ~= nInstanceID then
				CParty._tGridValues[nLocation] = CParty._tGridValues[nInstanceID]
				CParty._tGridStates[CParty._tGridValues[nInstanceID]] = nLocation
			end
			CParty._tGridValues[nInstanceID] = nLocation
			CParty._tGridStates[nLocation] = nInstanceID
			CParty:UpdateNetTable()
		end
	end
end

--[[function GetFormationPosition(vTargetPosition, vDirection, nLocation)
	vDirection = Vector(vDirection.x, vDirection.y, 0):Normalized() * 128.0
	local vCrossDirection = vDirection:Cross(Vector(0, 0, 1))
	vCrossDirection = vCrossDirection:Normalized() * 128.0
	
	return vTargetPosition + ((((nLocation - 1) % 5) - 2) * vCrossDirection) - (math.floor((nLocation - 1)/5) * vDirection)
end]]

end