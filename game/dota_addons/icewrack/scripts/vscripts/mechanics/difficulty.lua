--[[
    Icewrack Difficulties
	
	EASY
	  *1000 Starting Gold
	  *0% Friendly Fire
	  *NPCs have 1.0 AAM think rate
	  *Characters can be revived after combat with 100% HP and 100% MP/SP
	  *Players have 25% all resistances (TODO)
	  *Players have 50% increased healing effectiveness (TODO)
	  *Players deal 25% increased damage (TODO)
	
	NORMAL
	  *500 Starting Gold
	  *50% Friendly Fire
	  *NPCs have 0.25 AAM think rate
	  *Characters can be revived after combat with 50% HP and 50% MP/SP
	
	HARD
	  *250 Starting Gold
	  *100% Friendly Fire
	  *NPCs have 0.1 AAM think rate
	  *Characters can be revived after combat with 10% HP and 0% MP/SP
	  *Improved NPC tactics (TODO)
	  *Additional spawns which exist only in Hard/Unthaw difficulty (TODO)
	  *Experience gain reduced by 25% (TODO)	--Note that this is to accomodate for the additional spawns, so there will be 4/3 times as many mobs
	  *Threat decays at a rate of .5% every 0.1s
	
	UNTHAW
	  *100 Starting Gold
	  *100% Friendly Fire
	  *NPCs have 0.03 AAM think rate
	  *Characters cannot be revived at all
	  *Improved NPC tactics (TODO)
	  *Additional spawns which exist only in Unthaw difficulty (TODO)
	  *Experience gain reduced by 50% (TODO)	--Note that this is to accomodate for the additional spawns, so there will be 2 times as many mobs
	  *Party members can be shattered
	  *You may only save at an expedition base camp; quicksave/load is disabled (TODO)
	  *Threat decays at a rate of 1% every 0.1s
]]

IW_DIFFICULTY_EASY = 0
IW_DIFFICULTY_NORMAL = 1
IW_DIFFICULTY_HARD = 2
IW_DIFFICULTY_UNTHAW = 3

local stReviveHealthPercent =
{
	[IW_DIFFICULTY_EASY] = 1.0,
	[IW_DIFFICULTY_NORMAL] = 0.5, 
	[IW_DIFFICULTY_HARD] = 0.1,
	[IW_DIFFICULTY_UNTHAW] = 0.0,
}

local stReviveManaStaminaPercent =
{
	[IW_DIFFICULTY_EASY] = 1.0,
	[IW_DIFFICULTY_NORMAL] = 0.5, 
	[IW_DIFFICULTY_HARD] = 0.0,
	[IW_DIFFICULTY_UNTHAW] = 0.0,
}

local stFriendlyFireMultipliers =
{
	[IW_DIFFICULTY_EASY] = 0.0,
	[IW_DIFFICULTY_NORMAL] = 0.5, 
	[IW_DIFFICULTY_HARD] = 1.0,
	[IW_DIFFICULTY_UNTHAW] = 1.0,
}

local stAAMNPCThinkRates =
{
	[IW_DIFFICULTY_EASY] = 1.0,
	[IW_DIFFICULTY_NORMAL] = 0.5,
	[IW_DIFFICULTY_HARD] = 0.25,
	[IW_DIFFICULTY_UNTHAW] = 0.1,
}

local stNPCDetectionTime =
{
	[IW_DIFFICULTY_EASY] = 1.0,
	[IW_DIFFICULTY_NORMAL] = 2.0,
	[IW_DIFFICULTY_HARD] = 3.0,
	[IW_DIFFICULTY_UNTHAW] = 5.0
}

local stNPCNoiseDecayRate =
{
	[IW_DIFFICULTY_EASY] = 0.9,
	[IW_DIFFICULTY_NORMAL] = 0.95,
	[IW_DIFFICULTY_HARD] = 0.98,
	[IW_DIFFICULTY_UNTHAW] = 0.99,
}

GameRules.GetReviveHealthPercent = function() return stReviveHealthPercent[GameRules:GetCustomGameDifficulty()] end
GameRules.GetReviveManaStaminaPercent = function() return stReviveManaStaminaPercent[GameRules:GetCustomGameDifficulty()] end
GameRules.GetFriendlyFireMultiplier = function() return stFriendlyFireMultipliers[GameRules:GetCustomGameDifficulty()] end
GameRules.GetNPCThinkRate = function() return stAAMNPCThinkRates[GameRules:GetCustomGameDifficulty()] end
GameRules.GetNPCDetectDuration = function() return stNPCDetectionTime[GameRules:GetCustomGameDifficulty()] end
GameRules.GetNPCNoiseDecayRate = function() return stNPCNoiseDecayRate[GameRules:GetCustomGameDifficulty()] end