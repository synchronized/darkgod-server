-- Windows/skyuv runtime configuration.
-- Paths are relative to the project root, where the launcher starts.
server_root = "server"
common_root = "common"
skyuv_root = "3rd/skyuv"
skyuv_build_root = skyuv_root.."/build/darkgod"
skyuv_runtime_root = skyuv_build_root.."/3rd/portable"
darkgod_build_root = "build/windows-vs2022-debug/project"
darkgod_build_configuration = "Debug"
darkgod_module_root = darkgod_build_root.."/modules"
pb_root = "3rd/pb"

thread = 8
harbor = 0
start = "main"
bootstrap = "snlua bootstrap"

lua_path = server_root.."/lualib/?.lua;"
    ..common_root.."/lualib/?.lua;"
    ..skyuv_root.."/3rd/skynet/lualib/?.lua;"
    ..pb_root.."/?.lua"

lua_cpath = darkgod_module_root.."/server/luaclib/?.dll;"
    ..darkgod_module_root.."/server/luaclib/?/?.dll;"
    ..darkgod_module_root.."/common/luaclib/?.dll;"
    ..skyuv_runtime_root.."/luaclib/?.dll;"
    ..skyuv_runtime_root.."/luaclib/?/?.dll"

cpath = darkgod_module_root.."/server/cservice/?.dll;"
    ..skyuv_runtime_root.."/cservice/?.dll"

luaservice = server_root.."/service/?.lua;"
    ..skyuv_root.."/3rd/skynet/service/?.lua"

lualoader = skyuv_root.."/3rd/skynet/lualib/loader.lua"
snax = skyuv_root.."/3rd/skynet/lualib/?.lua;"
