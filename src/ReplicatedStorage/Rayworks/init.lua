-- util
local function DirectorySearchFilterWithCallback(directory: Instance, t: string, callback: (instance: Instance) -> (), currentDepth: number, maxDepth: number)
	for _, child in directory:GetChildren() do
		if child:IsA("Folder") then
			if currentDepth >= maxDepth then
				continue
			end
			DirectorySearchFilterWithCallback(child, t, callback, currentDepth + 1, maxDepth)
		elseif child:IsA(t) then
			callback(child)

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
local PRINT_PREFIX = IS_CLIENT and "[Client]" or "[Server]"

-- logging
local _print = print
local _warn = warn

local print = function(...)
	_print(PRINT_PREFIX, ...)
end

local warn = function(...)
	_warn(PRINT_PREFIX, ...)
end

-- loader setup
local Loaded = {}
local Init = {}
local Start = {}
local Failed = {}
local ModulesByName = {}

-- requires a module script and adds it to the init/start tables if their respective functions are found
local function LoadModuleScript(moduleScript: ModuleScript)
	local success, _ = pcall(function()
		-- require the module
		local module = require(moduleScript)
		-- add it to the loaded table
		Loaded[moduleScript] = module
		-- add to init/start
		if module.Init then
			table.insert(Init, moduleScript)
		end
		if module.Start then
			table.insert(Start, moduleScript)
		end
	end)

	if not success then
		warn("Failed to load module:", moduleScript)
		Failed[moduleScript] = true
	end
end

-- initializes a module script by calling its Init function
local function InitializeModule(moduleScript: ModuleScript, framework)
	if Failed[moduleScript] then return end

	local success, _ = pcall(function()
		local module = Loaded[moduleScript]
		module:Init(framework)
	end)

	if not success then
		warn("Failed to initialize module:", moduleScript)
		Failed[moduleScript] = true
	end
end

-- starts a module script by calling its Start function
local function StartModule(moduleScript: ModuleScript, framework)
	if Failed[moduleScript] then return end

	local success, _ = pcall(function()
		local module = Loaded[moduleScript]
		module:Start(framework)
	end)

	if not success then
		warn("Failed to start module:", moduleScript)
		Failed[moduleScript] = true
	end
end


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
	@return table
	@param moduleName string

	```lua
	local SomeModule = Rayworks:GetModule("SomeModule")
	```
]=]
function Rayworks:GetModule(moduleName: string)
	return ModulesByName[moduleName]
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
	DirectorySearchFilterWithCallback(directory, "ModuleScript", LoadModuleScript, 0, config.SearchDepth)
	print("Loaded modules ✅")

	-- initialize all the loaded modules
	ForEach(InitializeModule, Init)
	print("Initialized modules ✅")

	-- post start
	for moduleScript, module in Loaded do
		if not Failed[moduleScript] then
			ModulesByName[moduleScript.Name] = module
		end
	end

	-- start all the loaded modules
	ForEach(StartModule, Start, Rayworks)
	print("Started modules ✅")

	-- sets the LOAD_KEY attribute to true
	if not IS_CLIENT and config.WaitForServer then
		script:SetAttribute(config.LoadKey, true)
	end
end


return Rayworks