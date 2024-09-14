--[=[
	@interface RayworksConfiguration
	.WaitForServer boolean
	.SearchDepth number
	.LoadKey string
	@within Rayworks
]=]
type RayworksConfiguration = {
	WaitForServer: boolean,
	SearchDepth: number,
	LoadKey: string
}


local defaultConfiguration: RayworksConfiguration = {
	WaitForServer = true,
	SearchDepth = 100,
	LoadKey = "RayworksLoaded"
}


--[=[
	@interface Module
	.Init (Module, Rayworks) -> ()
	.Start (Module, Rayworks) -> ()
	@within Rayworks
]=]
type Module = {
	Init: (self: Module, Rayworks: table) -> (),
	Start: (self: Module, Rayworks: table) -> (),
	[any]: any
}

-- util
local function DirectorySearchFilterWithCallback(directory: Instance, t: string, callback: (instance: Instance) -> (), currentDepth: number, maxDepth: number, ...)
	for _, child in directory:GetChildren() do
		if child:IsA("Folder") then
			if currentDepth >= maxDepth then
				continue
			end
			DirectorySearchFilterWithCallback(child, t, callback, currentDepth + 1, maxDepth)
		elseif child:IsA(t) then
			callback(child, ...)

			if currentDepth >= maxDepth then
				continue
			end
			DirectorySearchFilterWithCallback(child, t, callback, currentDepth + 1, maxDepth)
		end
	end
end


local function ForEach(callback: (element: any) -> (), t: {any}, ...)
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
local modules: { [string]: table } = {}


-- requires a module script and adds it to the init/start tables if their respective functions are found
local function Load(moduleScript: ModuleScript, framework)
	local success, _ = pcall(function()
		-- require the module
		local module = require(moduleScript)
		-- add it to the loaded table
		loadedModules[moduleScript] = module
		-- add to init/start
		if module.Init then
			table.insert(modulesWithInit, moduleScript)
		end
		if module.Start then
			table.insert(modulesWithStart, moduleScript)
		end
	end)

	if not success then
		framework.__logger:LogError("Failed to load module:", moduleScript, _)
		modulesThatFailed[moduleScript] = true
	end
end


-- initializes a module script by calling its Init function
local function Init(moduleScript: ModuleScript, framework)
	if modulesThatFailed[moduleScript] then return end

	local success, _ = pcall(function()
		local module = loadedModules[moduleScript]
		module:Init(framework)
	end)

	if not success then
		framework.__logger:LogError("Failed to initialize module:", moduleScript, _)
		modulesThatFailed[moduleScript] = true
	end
end


-- starts a module script by calling its Start function
local function Start(moduleScript: ModuleScript, framework)
	if modulesThatFailed[moduleScript] then return end

	local success, _ = pcall(function()
		local module = loadedModules[moduleScript]
		module:Start(framework)
	end)

	if not success then
		framework.__logger:LogError("Failed to start module:", moduleScript, _)
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
	local CONFIG = Rayworks.CreateConfiguration(true, 2, "ExampleKey")

	-- start rayworks
	Rayworks.Start(ReplicatedStorage.Client.Core, CONFIG)
	```
]=]
local Rayworks = {}


--[=[
	@return RayworksConfiguration
]=]
function Rayworks.CreateConfiguration(waitForServer: boolean, searchDepth: number, loadKey: string) : RayworksConfiguration
	local configClone = table.clone(defaultConfiguration)
	configClone.LoadKey = loadKey or configClone.LoadKey
	configClone.SearchDepth = searchDepth or configClone.SearchDepth
	configClone.WaitForServer = waitForServer or configClone.WaitForServer

	return configClone
end

--[=[
	@prop Util Folder
	@readonly
	@within Rayworks
]=]
Rayworks.Util = {
	Logger = require(script.Util.Logger)
}

--[=[
	@prop __logger Logger
	@within Rayworks
	@private

	Used to log Rayworks debug information.
]=]
Rayworks.__logger = Rayworks.Util.Logger.new("Rayworks")


--[=[
	@return table
	@param moduleName string

	```lua
	local SomeModule = Rayworks:GetModule("SomeModule")
	```
]=]
function Rayworks:GetModule(moduleName: string)
	return modules[moduleName]
end


--[=[
	@param directory Instance
	@param configuration RayworksConfiguration?

	Starts the framework by recursively requiring all the modules inside the specified directory.
	If a configuration isn't provided, the default Rayworks configuration will be used.
	```lua
	local Rayworks = require(...)
	Rayworks.Start(ReplicatedStorage.Client)
	```
]=]
function Rayworks.Start(directory: Instance, configuration: RayworksConfiguration?)
	-- get configuration or default
	local config = configuration or defaultConfiguration

	-- if WAIT_FOR_SERVER option is set to true, the client loader will pause the code execution until the LOAD_KEY attribute is set
	if IS_CLIENT and config.WaitForServer then
		repeat
			task.wait()
		until script:GetAttribute(config.LoadKey)
	end

	-- in-depth search of the directory to load all the modulescripts
	DirectorySearchFilterWithCallback(directory, "ModuleScript", Load, 0, config.SearchDepth, Rayworks)
	Rayworks.__logger:LogInfo("Load ✔️")

	-- initialize all the loaded modules
	ForEach(Init, modulesWithInit, Rayworks)
	Rayworks.__logger:LogInfo("Init ✔️")

	-- post start
	for moduleScript, module in loadedModules do
		if not modulesThatFailed[moduleScript] then
			modules[moduleScript.Name] = module
		end
	end

	-- start all the loaded modules
	ForEach(Start, modulesWithStart, Rayworks)
	Rayworks.__logger:LogInfo("Start ✔️")

	-- sets the LOAD_KEY attribute to true
	if not IS_CLIENT and config.WaitForServer then
		script:SetAttribute(config.LoadKey, true)
		Rayworks.__logger:LogInfo("Client can start Rayworks now.")
	end
end


return Rayworks