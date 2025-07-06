export type Log = {
    message: string,
    timestamp: number,
    type: string
}

export type Logger = {
    logInfo: (Logger, ...any) -> (),
    logWarning: (Logger, ...any) -> (),    
    logError: (Logger, ...any) -> (),
    __logs: { Log }
}


--[=[
    @class Logger

    Logger class used by Rayworks. Can be used by non-Rayworks modules/scripts.

    ```lua
    -- logger creation
    local myLogger = Rayworks.createLogger("Ray's Logger")

    -- log data
    myLogger:logInfo("I am a logger and I have just been created!")
    myLogger:logError("Oops :3 System malfunction :D")
    ```
]=]
local Logger = {}
Logger.__index = Logger

--[[
    Static function used by the Logger object to store logs
]]
function Logger.storeLog(logger: Logger, logType: string, log: string)
    local logData = {
        message = log,
        timestamp = os.time(),
        type = logType
    }

    table.insert(logger.__logs, logData)
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

    local self = setmetatable({}, Logger)

    self.Name = loggerName
    self.__logs = {}

    return self
end


--[=[
    @param ... ...any

    Information-level log function.
]=]
function Logger:logInfo(...)
    print(`✅ [{self.Name}] [INFO]`, ...)
    Logger.storeLog(self, "INFO", (...))
end


--[=[
    @param ... ...any

    Warning-level log function.
]=]
function Logger:logWarning(...)
    warn(`⚠️ [{self.Name}] [WARN]`, ...)
    Logger.storeLog(self, "WARN", (...))
end


--[=[
    @param ... ...any

    Error-level log function.
]=]
function Logger:logError(...)
    warn(`❌ [{self.Name}] [ERROR]`, ...)
    Logger.storeLog(self, "ERROR", (...))
end

return Logger
