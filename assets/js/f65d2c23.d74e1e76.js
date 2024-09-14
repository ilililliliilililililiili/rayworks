"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[224],{74464:e=>{e.exports=JSON.parse('{"functions":[{"name":"CreateConfiguration","desc":"","params":[{"name":"waitForServer","desc":"","lua_type":"boolean"},{"name":"searchDepth","desc":"","lua_type":"number"},{"name":"loadKey","desc":"","lua_type":"string"}],"returns":[{"desc":"","lua_type":"RayworksConfiguration"}],"function_type":"static","source":{"line":150,"path":"src/init.luau"}},{"name":"GetModule","desc":"```lua\\nlocal SomeModule = Rayworks:GetModule(\\"SomeModule\\")\\n```","params":[{"name":"moduleName","desc":"","lua_type":"string"}],"returns":[{"desc":"","lua_type":"table"}],"function_type":"method","source":{"line":186,"path":"src/init.luau"}},{"name":"Start","desc":"Starts the framework by recursively requiring all the modules inside the specified directory.\\nIf a configuration isn\'t provided, the default Rayworks configuration will be used.\\n```lua\\nlocal Rayworks = require(...)\\nRayworks.Start(ReplicatedStorage.Client)\\n```","params":[{"name":"directory","desc":"","lua_type":"Instance"},{"name":"configuration","desc":"","lua_type":"RayworksConfiguration?"}],"returns":[],"function_type":"static","source":{"line":202,"path":"src/init.luau"}}],"properties":[{"name":"Util","desc":"","lua_type":"Folder","readonly":true,"source":{"line":164,"path":"src/init.luau"}},{"name":"__logger","desc":"Used to log Rayworks debug information.","lua_type":"Logger","private":true,"source":{"line":175,"path":"src/init.luau"}}],"types":[{"name":"RayworksConfiguration","desc":"","fields":[{"name":"WaitForServer","lua_type":"boolean","desc":""},{"name":"SearchDepth","lua_type":"number","desc":""},{"name":"LoadKey","lua_type":"string","desc":""}],"source":{"line":8,"path":"src/init.luau"}},{"name":"Module","desc":"","fields":[{"name":"Init","lua_type":"(Module, Rayworks) -> ()","desc":""},{"name":"Start","lua_type":"(Module, Rayworks) -> ()","desc":""}],"source":{"line":28,"path":"src/init.luau"}}],"name":"Rayworks","desc":"```lua\\n-- require the framework\\nlocal Rayworks = require(Packages.Rayworks)\\n\\n-- create a config\\nlocal CONFIG = Rayworks.CreateConfiguration(true, 2, \\"ExampleKey\\")\\n\\n-- start rayworks\\nRayworks.Start(ReplicatedStorage.Client.Core, CONFIG)\\n```","realm":["Client","Server"],"source":{"line":144,"path":"src/init.luau"}}')}}]);