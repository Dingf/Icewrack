--[[
    Icewrack Accuracy
]]

require("ext_entity")

ACCURACY_PENALTY_MIN = 256		--Minimum range at which accuracy penalty is applied; values nearer than this range do not receive any penalty
ACCURACY_PENALTY_MAX = 1800		--Maximum range at which accuracy penalty is applied; values further than this range do not receive additional penalty
ACCURACY_PENALTY_DIFF = ACCURACY_PENALTY_MAX - ACCURACY_PENALTY_MIN

function PerformAccuracyCheck(hVictim, hAttacker, fBonusAccuracy)
	local fDistance = (hVictim:GetAbsOrigin() - hAttacker:GetAbsOrigin()):Length2D()
	local fAccuracyMultiplier = 1.0 - math.min(math.max(fDistance - ACCURACY_PENALTY_MIN, 0), ACCURACY_PENALTY_DIFF)/(ACCURACY_PENALTY_DIFF * 2)
	if #hAttacker._tAttackSourceTable >= 2 then
		fAccuracyMultiplier = fAccuracyMultiplier * 0.75
	end
	
	local fDodgeMultiplier = (hVictim:GetCurrentActiveAbility() or hVictim:IsAttacking()) and 0.5 or 1.0
	if hVictim:IsMoving() then
		fDodgeMultiplier = fDodgeMultiplier * 1.5
	end
	local fScoreDiff = (hVictim:GetDodgeScore() * fDodgeMultiplier) - ((hAttacker:GetAccuracyScore() + fBonusAccuracy) * fAccuracyMultiplier)
	local fDodgeChance = (math.tanh(math.max(-2.0, math.min(2.0, (fScoreDiff/100.0)))) + 1.0)/2.0
	return RandomFloat(0.0, 1.0) >= fDodgeChance
end