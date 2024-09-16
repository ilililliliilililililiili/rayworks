type Logger = {
    LogInfo: (Logger, ...any) -> (),
    LogWarning: (Logger, ...any) -> (),    
    LogError: (Logger, ...any) -> (),
}


--[=[
    @class Logger

    Logger class used by Rayworks. Can be used by non-Rayworks modules/scripts.

    ```lua
    -- logger creation
    local myLogger = Rayworks.CreateLogger("Ray's Logger")

    -- log data
    myLogger:LogInformation("I am a logger and I have just been created!")
    myLogger:LogError("Oops :3 System malfunction :D")
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

    self.INFO_LOG_PREFIX = ("✅ [%s] [Info]"):format(loggerName)
    self.WARN_LOG_PREFIX = ("⚠️ [%s] [Warn]"):format(loggerName)
    self.ERROR_LOG_PREFIX = ("❌ [%s] [Error]"):format(loggerName)
    self.Name = loggerName
    self.Logs = {}

    return setmetatable(self, Logger)
end


--[=[
    @param ... ...any

    Information-level log function.
]=]
function Logger:LogInfo(...)
    print(self.INFO_LOG_PREFIX, ...)
    Logger.storeLog(self, "Info", (...))
end


--[=[
    @param ... ...any

    Warning-level log function.
]=]
function Logger:LogWarning(...)
    print(self.WARN_LOG_PREFIX, ...)
    Logger.storeLog(self, "Warn", (...))
end


--[=[
    @param ... ...any

    Error-level log function.
]=]
function Logger:LogError(...)
    print(self.ERROR_LOG_PREFIX, ...)
    Logger.storeLog(self, "Error", (...))
end

return Logger