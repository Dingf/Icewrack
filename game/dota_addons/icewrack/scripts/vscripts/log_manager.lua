if not CLogManager then 

local stLogSeverityEnum =
{
	LOG_SEVERITY_DEBUG = 0,
	LOG_SEVERITY_INFO = 1,
	LOG_SEVERITY_WARNING = 2,
	LOG_SEVERITY_ERROR = 3,
}

for k,v in pairs(stLogSeverityEnum) do _G[k] = v end

local stLogSeverityTags =
{
	[LOG_SEVERITY_DEBUG]   = "DEBUG",
	[LOG_SEVERITY_INFO]    = "INFO",
	[LOG_SEVERITY_WARNING] = "WARN",
	[LOG_SEVERITY_ERROR]   = "ERROR",
}

CLogManager = { _szLogDirectory = ICEWRACK_GAME_DIR .. "logs\\" }
InitLogFile(CLogManager._szLogDirectory, "")		--This creates the logs folder if it doesn't exist

function LogMessage(szMessage, nSeverity, ...)
	if IsServer() then
		if not nSeverity then nSeverity = LOG_SEVERITY_INFO end
		if stLogSeverityTags[nSeverity] and type(szMessage) == "string" then
			local szSystemDate = GetSystemDate()
			local tCallbackArgs = {...}
			local _,_,m,d,y = string.find(szSystemDate, "(%d+)/(%d+)/(%d+)")
			local szFilename = string.format("icewrack_%d_%02d%02d%02d.log", ICEWRACK_GAME_MODE_ID, d, m, y)
			if tCallbackArgs then
				szMessage = string.format(szMessage, unpack(tCallbackArgs))
			end
			AppendToLogFile(CLogManager._szLogDirectory .. szFilename, string.format("%s %s:\t%s", GetSystemTime(), stLogSeverityTags[nSeverity], szMessage .. "\n"))
			print(string.format("[%s]: %s", stLogSeverityTags[nSeverity], szMessage))
			if nSeverity >= LOG_SEVERITY_ERROR then
				local szTraceback = debug.traceback()
				for k in string.gmatch(szTraceback, "[^\n]+") do
					AppendToLogFile(CLogManager._szLogDirectory .. szFilename, string.format("%s %s: %s\n", GetSystemTime(), stLogSeverityTags[LOG_SEVERITY_DEBUG], k))
				end
				error(szMessage)
			end
		end
	end
end

function LogAssert(v, szMessage, ...)
	if IsServer() and not v then
		local tCallbackArgs = {...}
		if szMessage and tCallbackArgs then
			szMessage = string.format(szMessage, unpack(tCallbackArgs))
		elseif not szMessage then
			szMessage = "Assertion failed!"
		end
		LogMessage(szMessage, LOG_SEVERITY_ERROR)
	end
end

return getfenv()

end