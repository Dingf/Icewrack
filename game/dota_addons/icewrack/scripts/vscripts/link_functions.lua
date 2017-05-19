require("mechanics/damage_primary")
require("mechanics/heal")

stLinkedFunctionsTable =
{
	Damage = DealDamage,
	AttackDamage = DealAttackDamage,
	HealHP = HealTarget,
	--HealMP = ExtRestoreMP,
	--HealSP = ExtRestoreSP,
	--AddAbility = ExtAddAbility,
	--RemoveAbility = ExtRemoveAbility,
	--LearnAbility = ExtLearnAbility,
	--UnlearnAbility = ExtUnlearnAbility,
	--ApplyModifier = ExtApplyModfier,
	--RemoveModifier = ExtRemoveModifier,
}

function GetLinkedFunction(szFunctionName, tFunctionArgs)
	if szFunctionName == "RunScript" then
		local szScriptFilename = tFunctionArgs.ScriptFile
		local szScriptFunction = tFunctionArgs.Function
		if szScriptFilename and szScriptFunction then
			local tSandbox = setmetatable({}, { __index = getfenv() })
			szScriptFilename = string.gsub(szScriptFilename, "\\", "/")
			szScriptFilename = string.gsub(szScriptFilename, "scripts/vscripts/", "")
			szScriptFilename = string.gsub(szScriptFilename, ".lua", "")
			setfenv(1, tSandbox)
			dofile(szScriptFilename)
			return tSandbox[szScriptFunction]
		end
	else
		for k,v in pairs(stLinkedFunctionsTable) do
			if szFunctionName == k then return v end
		end
	end
	return nil
end