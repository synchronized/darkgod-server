cmake_minimum_required(VERSION 3.23)

project(darkgod_server LANGUAGES C)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS ON)

option(DARKGOD_BUILD_CJSON "Build the cjson Lua module" ON)
option(DARKGOD_BUILD_PB "Build the protobuf Lua module" ON)
option(DARKGOD_BUILD_UUID "Build the uuid Lua module" ON)
option(DARKGOD_BUILD_PACKAGE "Build the custom package Skynet service" OFF)
set(DARKGOD_SKYUV_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/3rd/skyuv" CACHE PATH
    "skyuv source directory")

set(DARKGOD_OUTPUT_BIN_DIR "${CMAKE_BINARY_DIR}/project/bin" CACHE PATH
    "Runtime executable and module output root")
set(DARKGOD_OUTPUT_LIB_DIR "${CMAKE_BINARY_DIR}/project/lib" CACHE PATH
    "Static and import library output root")
set(DARKGOD_OUTPUT_MODULE_DIR "${CMAKE_BINARY_DIR}/project/modules" CACHE PATH
    "Lua C module and C service output root")
set(DARKGOD_COMMON_LUACLIB_DIR "${DARKGOD_OUTPUT_MODULE_DIR}/common/luaclib" CACHE PATH
    "Output directory for common Lua C modules")
set(DARKGOD_SERVER_LUACLIB_DIR "${DARKGOD_OUTPUT_MODULE_DIR}/server/luaclib" CACHE PATH
    "Output directory for server Lua C modules")
set(DARKGOD_SERVER_CSERVICE_DIR "${DARKGOD_OUTPUT_MODULE_DIR}/server/cservice" CACHE PATH
    "Output directory for Skynet C services")
# Visual Studio is a multi-configuration generator and normally appends
# Debug/Release to target output directories. The preset directory already
# identifies the configuration, so use a harmless generator expression to
# suppress that automatic suffix.
set(DARKGOD_OUTPUT_BIN_PATH "$<1:${DARKGOD_OUTPUT_BIN_DIR}>")
set(DARKGOD_OUTPUT_LIB_PATH "$<1:${DARKGOD_OUTPUT_LIB_DIR}>")
if(NOT EXISTS "${DARKGOD_SKYUV_ROOT}/3rd/skynet/3rd/lua/lua.h")
    message(FATAL_ERROR "skyuv submodules are not initialized; run git submodule update --init --recursive")
endif()

set(SKYUV_BUILD_TESTS OFF CACHE BOOL "不构建 skyuv 测试" FORCE)
# skyuv v0.1.1 的 Skynet 补丁流程要求二进制目录位于 skyuv 源码树内。
# 该目录由 .gitignore 排除，不会污染 skyuv 子模块的源码提交。
set(DARKGOD_SKYUV_BINARY_DIR "${DARKGOD_SKYUV_ROOT}/build/darkgod" CACHE PATH
    "Embedded skyuv binary directory")
add_subdirectory("${DARKGOD_SKYUV_ROOT}" "${DARKGOD_SKYUV_BINARY_DIR}")

set(DARKGOD_LUA_ROOT "${DARKGOD_SKYUV_ROOT}/3rd/skynet/3rd/lua" CACHE PATH
    "Lua source directory" FORCE)
set(DARKGOD_LUA_TARGET skyuv::lua)
set(DARKGOD_SKYUV_PLATFORM_TARGET skyuv::platform)
set(DARKGOD_SKYUV_RUNTIME_TARGET skyuv)
set(DARKGOD_SKYUV_PATCHED_SKYNET_INCLUDE_DIR
    "${DARKGOD_SKYUV_BINARY_DIR}/3rd/skynet-patched/skynet-src")
if(TARGET skyuv)
    set_target_properties(skyuv PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${DARKGOD_OUTPUT_BIN_PATH}"
        LIBRARY_OUTPUT_DIRECTORY "${DARKGOD_OUTPUT_BIN_PATH}"
        ARCHIVE_OUTPUT_DIRECTORY "${DARKGOD_OUTPUT_LIB_PATH}"
    )
endif()
if(MSVC)
    set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
endif()
if(WIN32)
    set(DARKGOD_MODULE_SUFFIX ".dll")
else()
    set(DARKGOD_MODULE_SUFFIX ".so")
endif()

function(darkgod_configure_module target output_dir)
    set_target_properties(${target} PROPERTIES
        PREFIX ""
        SUFFIX "${DARKGOD_MODULE_SUFFIX}"
        LIBRARY_OUTPUT_DIRECTORY "$<1:${output_dir}>"
        RUNTIME_OUTPUT_DIRECTORY "$<1:${output_dir}>"
        ARCHIVE_OUTPUT_DIRECTORY "${DARKGOD_OUTPUT_LIB_PATH}"
    )
    if(MSVC)
        set_target_properties(${target} PROPERTIES WINDOWS_EXPORT_ALL_SYMBOLS TRUE)
    endif()
    target_include_directories(${target} PRIVATE "${DARKGOD_LUA_ROOT}")
    target_link_libraries(${target} PRIVATE
        ${DARKGOD_LUA_TARGET}
        ${DARKGOD_SKYUV_PLATFORM_TARGET}
    )
endfunction()

if(DARKGOD_BUILD_CJSON)
    add_library(darkgod_cjson MODULE
        3rd/lua-cjson/lua_cjson.c
        3rd/lua-cjson/strbuf.c
        3rd/lua-cjson/fpconv.c
    )
    target_compile_definitions(darkgod_cjson PRIVATE MULTIPLE_THREADS)
    target_include_directories(darkgod_cjson PRIVATE 3rd/lua-cjson)
    darkgod_configure_module(darkgod_cjson "${DARKGOD_COMMON_LUACLIB_DIR}")
    set_target_properties(darkgod_cjson PROPERTIES OUTPUT_NAME cjson)
endif()

if(DARKGOD_BUILD_PB)
    add_library(darkgod_pb MODULE 3rd/pb/pb.c)
    target_include_directories(darkgod_pb PRIVATE 3rd/pb)
    darkgod_configure_module(darkgod_pb "${DARKGOD_COMMON_LUACLIB_DIR}")
    set_target_properties(darkgod_pb PROPERTIES OUTPUT_NAME pb)
endif()

if(DARKGOD_BUILD_UUID)
    add_library(darkgod_uuid MODULE server/lualib-src/lua-uuid.c)
    darkgod_configure_module(darkgod_uuid "${DARKGOD_SERVER_LUACLIB_DIR}")
    # server/lualib/uuid.lua loads "uuid.core", so Lua searches uuid/core.dll
    # and the module must export luaopen_uuid_core.
    set_target_properties(darkgod_uuid PROPERTIES
        OUTPUT_NAME core
        LIBRARY_OUTPUT_DIRECTORY "$<1:${DARKGOD_SERVER_LUACLIB_DIR}/uuid>"
        RUNTIME_OUTPUT_DIRECTORY "$<1:${DARKGOD_SERVER_LUACLIB_DIR}/uuid>"
    )
endif()

if(DARKGOD_BUILD_PACKAGE)
    add_library(darkgod_package MODULE EXCLUDE_FROM_ALL server/service-src/service_package.c)
    target_include_directories(darkgod_package PRIVATE
        "${DARKGOD_SKYUV_PATCHED_SKYNET_INCLUDE_DIR}"
        "${DARKGOD_LUA_ROOT}"
        "${DARKGOD_SKYUV_ROOT}/include"
        "${DARKGOD_SKYUV_ROOT}/src/compat/skynet"
    )
    set_target_properties(darkgod_package PROPERTIES
        PREFIX ""
        SUFFIX "${DARKGOD_MODULE_SUFFIX}"
        OUTPUT_NAME package
        LIBRARY_OUTPUT_DIRECTORY "$<1:${DARKGOD_SERVER_CSERVICE_DIR}>"
        RUNTIME_OUTPUT_DIRECTORY "$<1:${DARKGOD_SERVER_CSERVICE_DIR}>"
        ARCHIVE_OUTPUT_DIRECTORY "${DARKGOD_OUTPUT_LIB_PATH}"
    )
    target_link_libraries(darkgod_package PRIVATE
        ${DARKGOD_SKYUV_RUNTIME_TARGET}
    )
endif()

add_custom_target(darkgod_build_summary ALL
    COMMAND ${CMAKE_COMMAND} -E echo "darkgod CMake build configured"
    COMMAND ${CMAKE_COMMAND} -E echo "skyuv: ${DARKGOD_SKYUV_ROOT}"
    COMMAND ${CMAKE_COMMAND} -E echo "Lua: ${DARKGOD_LUA_ROOT}"
    VERBATIM
)
