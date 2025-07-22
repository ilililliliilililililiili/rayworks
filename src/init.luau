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
	Verbose: boolean?
}


--[=[
	@interface Module
	.init (Module, Rayworks) -> ()
	.start (Module, Rayworks) -> ()
	.lateStart (Module, Rayworks) -> ()
	[any]: any
	@within Rayworks
]=]
type Module = {
	init: (self: Module, Rayworks: {}) -> (),
	start: (self: Module, Rayworks: {}) -> (),
	lateStart: (self: Module, Rayworks: {}) -> (),
	[any]: any
}

-- util
local function directorySearchFilterWithCallback(directory: Instance, t: string, currentDepth: number, maxDepth: number, callback: (instance: Instance) -> (), ...)
	for _, child in directory:GetDescendants() do
		if child:IsA(t) then
			callback(child, ...)
		end
	end
end


local function forEach(callback: (element: any, ...any) -> (), t: {any}, ...)
	for _, element in t do
		callback(element, ...)
	end
end


-- consts
local IS_CLIENT = game:GetService("RunService"):IsClient()
local LOAD_KEY = "Loaded"
local DEFAULT_CONFIGURATION: RayworksConfiguration = {
	WaitForServer = true,
	SearchDepth = math.huge,
	Verbose = false
}


-- loader setup
local modules: { [string]: Module } = {}
local modulesByPhase = {
	init = {},
	start = {},
	lateStart = {}
}


-- requires a module script and adds it to the init/start tables if their respective functions are found
local function load(moduleScript: Instance, framework)
	-- check if the module script is a ModuleScript
	if not moduleScript:IsA("ModuleScript") then return end

	-- check if the module script is already loaded, if so, error and prompt the developer to fix the issue
	if modules[moduleScript.Name] then 
		framework.__logger:logError(`Module with name {moduleScript.Name} already exists.`)
		error("Please fix this issue.", 6)
		return
	end

	-- require the module script in a pcall to handle errors gracefully
	local success, module = pcall(require, moduleScript)
	if not success or typeof(module) ~= "table" then return end

	-- register module in modules table
	modules[moduleScript.Name] = module

	-- store the module in the appropriate phase tables
	for phase, modulesInPhase in modulesByPhase do
		if module[phase] and typeof(module[phase]) == "function" then
			table.insert(modulesInPhase, moduleScript.Name)
		end
	end
end


-- runs a phase
local function runPhase(moduleName: string, phase: string, framework)
	local module = modules[moduleName]

	-- get the module
	if not module then
		framework.__logger:logError(`Module not found: {moduleName}`)
		return
	end

	-- run the phase function in a pcall
	local success, response = pcall(module[phase], module, framework)

	-- remove the module if it failed
	if not success then
		framework.__logger:logError(`Failed to run {phase} phase for {moduleName}:`, response)
		modules[moduleName] = nil
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
	local configClone = table.clone(DEFAULT_CONFIGURATION)
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
	SomeModule:someFunction()
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
	local config = configuration or DEFAULT_CONFIGURATION

	-- if WAIT_FOR_SERVER option is set to true, the client loader will pause the code execution until the LOAD_KEY attribute is set
	if IS_CLIENT and config.WaitForServer then
		repeat
			task.wait()
		until script:GetAttribute(LOAD_KEY)
	end

	-- in-depth search of the directory to load all the modulescripts
	directorySearchFilterWithCallback(directory, "ModuleScript", 0, config.SearchDepth, load, Rayworks)
	if config.Verbose then Rayworks.__logger:logInfo("Load ✔️") end

	-- initialize all the loaded modules
	forEach(runPhase, modulesByPhase.init, "init", Rayworks)
	if config.Verbose then Rayworks.__logger:logInfo("Init ✔️") end

	forEach(runPhase, modulesByPhase.start, "start", Rayworks)
	if config.Verbose then Rayworks.__logger:logInfo("Start ✔️") end

	forEach(runPhase, modulesByPhase.lateStart, "lateStart", Rayworks)
	if config.Verbose then Rayworks.__logger:logInfo("LateStart ✔️") end


	-- sets the LOAD_KEY attribute to true
	if not IS_CLIENT and config.WaitForServer then
		script:SetAttribute(LOAD_KEY, true)
		if config.Verbose then
			Rayworks.__logger:logInfo("Client can start Rayworks now.")
		end	
	end
end


return Rayworks
