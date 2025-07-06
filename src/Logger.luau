type Logger = {
    logInfo: (Logger, ...any) -> (),
    logWarning: (Logger, ...any) -> (),    
    logError: (Logger, ...any) -> (),
}


--[=[
    @class Logger

    Logger class used by Rayworks. Can be used by non-Rayworks modules/scripts.

    ```lua
    -- logger creation
    local myLogger = Rayworks.createLogger("Ray's Logger")

    -- log data
    myLogger:LogInformation("I am a logger and I have just been created!")
    myLogger:logError("Oops :3 System malfunction :D")
    ```
]=]
local Logger = {}
Logger.__index = Logger

--[[
    Static function used by the Logger object to store logs
]]
function Logger.storeLog(logger: Logger, logType: string, log: string)
    local logData = {}
    logData.Timestamp = DateTime.now().UnixTimestampMillis
    logData.Log = log
    logData.LogType = logType

    table.insert(logger.Logs, logData)
    
    Logger.exportLogs(logger)
end

--[[
    Static function used by the Logger object to export logs
]]
function Logger.exportLogs(logger: Logger)
    -- some functionality that sends json logs to a server :3
end

--[=[
    The default Logger constructor used to create a logger. The default loggerName is "Logger".

    @param loggerName string?
]=]
function Logger.new(loggerName: string?) : Logger
    loggerName = loggerName or "Logger"

    local self = {}

    self.Name = loggerName
    self.Logs = {}

    return setmetatable(self, Logger)
end


--[=[
    @param ... ...any

    Information-level log function.
]=]
function Logger:logInfo(...)
    print(`✅ [{self.Name}] [Info]`, ...)
    Logger.storeLog(self, "Info", (...))
end


--[=[
    @param ... ...any

    Warning-level log function.
]=]
function Logger:logWarning(...)
    warn(`⚠️ [{self.Name}] [Warn]`, ...)
    Logger.storeLog(self, "Warn", (...))
end


--[=[
    @param ... ...any

    Error-level log function.
]=]
function Logger:logError(...)
    warn(`❌ [{self.Name}] [Error]`, ...)
    Logger.storeLog(self, "Error", (...))
end

return Logger
