--[=[
	@interface RayworksConfiguration
	.WaitForServer boolean
	.SearchDepth number
	.LoadKey string
	@within Rayworks
]=]
type RayworksConfiguration = {
	WaitForServer: boolean?,
	SearchDepth: number?,
	LoadKey: string?,
	Verbose: boolean?
}


local defaultConfiguration: RayworksConfiguration = {
	WaitForServer = true,
	SearchDepth = math.huge,
	LoadKey = "RayworksLoaded",
	Verbose = false
}


--[=[
	@interface Module
	.init (Module, Rayworks) -> ()
	.start (Module, Rayworks) -> ()
	@within Rayworks
]=]
type Module = {
	init: (self: Module, Rayworks: {}) -> (),
	start: (self: Module, Rayworks: {}) -> (),
	[any]: any
}

-- util
local function directorySearchFilterWithCallback(directory: Instance, t: string, currentDepth: number, maxDepth: number, callback: (instance: Instance) -> (), ...)
	for _, child in directory:GetChildren() do
		if child:IsA("Folder") then
			if child.Name == "Classes" then
				continue
			end
			if currentDepth >= maxDepth then
				continue
			end
			directorySearchFilterWithCallback(child, t, currentDepth + 1, maxDepth, callback, ...)
		elseif child:IsA(t) then
			callback(child, ...)

			if currentDepth >= maxDepth then
				continue
			end
			directorySearchFilterWithCallback(child, t, currentDepth + 1, maxDepth, callback, ...)
		end
	end
end


local function forEach(callback: (element: any) -> (), t: {any}, ...)
	for _, element in t do
		callback(element, ...)
	end
end


-- consts
local IS_CLIENT = game:GetService("RunService"):IsClient()


-- loader setup
local loadedModules = {}
local modulesWithInit = {}
local modulesWithStart = {}
local modulesThatFailed = {}
local modules: { [string]: {any} } = {}


-- requires a module script and adds it to the init/start tables if their respective functions are found
local function load(moduleScript: Instance, framework)
	local success, response = pcall(function()
		-- return if not modulescript
		if not moduleScript:IsA("ModuleScript") then return end

		-- require the module
		local module = require(moduleScript)

		-- discard if its not a table
		if typeof(module) ~= "table" then return end

		-- add it to the loaded table
		loadedModules[moduleScript] = module

		-- add to init/start
		if module.init then
			table.insert(modulesWithInit, moduleScript)
		end
		
		if module.start then
			table.insert(modulesWithStart, moduleScript)
		end
	end)

	if not success then
		framework.__logger:logError("Failed to load module:", moduleScript, response)
		modulesThatFailed[moduleScript] = true
	end
end


-- initializes a module script by calling its init function
local function init(moduleScript: ModuleScript, framework)
	if modulesThatFailed[moduleScript] then return end

	local success, response = pcall(function()
		local module = loadedModules[moduleScript]
		module:init(framework)
	end)

	if not success then
		framework.__logger:logError("Failed to initialize module:", moduleScript, response)
		modulesThatFailed[moduleScript] = true
	end
end


-- starts a module script by calling its start function
local function start(moduleScript: ModuleScript, framework)
	if modulesThatFailed[moduleScript] then return end

	local success, response = pcall(function()
		local module = loadedModules[moduleScript]
		module:start(framework)
	end)

	if not success then
		framework.__logger:logError("Failed to start module:", moduleScript, response)
		modulesThatFailed[moduleScript] = true
	end
end


--[=[
	@class Rayworks
	@server
	@client

	```lua
	-- require the framework
	local Rayworks = require(Packages.Rayworks)

	-- create a config
	local CONFIG = Rayworks.createConfiguration(true, 2, "ExampleKey")

	-- start rayworks
	Rayworks.start(ReplicatedStorage.Client.Core, CONFIG)
	```
]=]
local Rayworks = {}


--[=[
	@return RayworksConfiguration
]=]
function Rayworks.createConfiguration(configuration: RayworksConfiguration) : RayworksConfiguration
	local configClone = table.clone(defaultConfiguration)
	configClone.LoadKey = configuration.LoadKey or configClone.LoadKey
	configClone.SearchDepth = configuration.SearchDepth or configClone.SearchDepth
	configClone.WaitForServer = configuration.WaitForServer or configClone.WaitForServer
	configClone.Verbose = configuration.Verbose or configClone.Verbose

	return configClone
end


--[=[
	@return Logger
	@param loggerName string

	```lua
	local myLogger = Rayworks.createLogger("myLogger")
	```
]=]
local Logger = require(script.Logger)
function Rayworks.createLogger(loggerName: string)
	return Logger.new(loggerName)
end


--[=[
	@prop __logger Logger
	@within Rayworks
	@private

	Used to log Rayworks debug information.
]=]
Rayworks.__logger = Rayworks.createLogger("Rayworks")


--[=[
	@return table
	@param moduleName string

	```lua
	local SomeModule = Rayworks:getModule("SomeModule")
	```
]=]
function Rayworks:getModule(moduleName: string)
	return modules[moduleName]
end


--[=[
	@param directory Instance
	@param configuration RayworksConfiguration?

	Starts the framework by recursively requiring all the modules inside the specified directory.
	If a configuration isn't provided, the default Rayworks configuration will be used.
	```lua
	local Rayworks = require(...)
	Rayworks.start(ReplicatedStorage.Client)
	```
]=]
function Rayworks.start(directory: Instance, configuration: RayworksConfiguration?)
	-- get configuration or default
	local config = configuration or defaultConfiguration

	-- if WAIT_FOR_SERVER option is set to true, the client loader will pause the code execution until the LOAD_KEY attribute is set
	if IS_CLIENT and config.WaitForServer then
		repeat
			task.wait()
		until script:GetAttribute(config.LoadKey)
	end

	-- in-depth search of the directory to load all the modulescripts
	directorySearchFilterWithCallback(directory, "ModuleScript", 0, config.SearchDepth, load, Rayworks)
	if config.Verbose then
		Rayworks.__logger:logInfo("Load ✔️")
	end

	-- initialize all the loaded modules
	forEach(init, modulesWithInit, Rayworks)
	if config.Verbose then
		Rayworks.__logger:logInfo("Init ✔️")
	end

	-- post start
	for moduleScript, module in loadedModules do
		if not modulesThatFailed[moduleScript] then
			modules[moduleScript.Name] = module
		end
	end

	-- start all the loaded modules
	forEach(start, modulesWithStart, Rayworks)
	if config.Verbose then
		Rayworks.__logger:logInfo("Start ✔️")
	end


	-- sets the LOAD_KEY attribute to true
	if not IS_CLIENT and config.WaitForServer then
		script:SetAttribute(config.LoadKey, true)
		if config.Verbose then
			Rayworks.__logger:logInfo("Client can start Rayworks now.")
		end	
	end
end


return Rayworks
