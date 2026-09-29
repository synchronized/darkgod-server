# 使用 CMake 构建

## 适用场景

本指南说明如何使用 CMake 构建当前项目自有 Lua C 模块。当前 Windows 构建已验证使用 CMake、
Clang 和 MinGW Makefiles。Windows 运行时不依赖原版 Skynet，而应由 skyuv 提供；Linux 可以继续
使用原版 Skynet 做行为基线。

## 前置条件

- CMake 3.23 或更高版本。
- 支持 C11 的编译器。
- 已初始化 `3rd/skynet`、`3rd/lua-cjson`、`3rd/lsocket` 和 `3rd/pb` 子模块。
- Linux：原版 Skynet 或 skyuv 运行时。
- Windows：skyuv 运行时。

初始化子模块：

```powershell
git submodule update --init --recursive
```

## Windows 构建

配置并构建：

```powershell
cmake -S . -B cmake-build-mingw -G "MinGW Makefiles" `
  -DDARKGOD_BUILD_LSOCKET=OFF `
  -DDARKGOD_BUILD_PACKAGE=OFF
cmake --build cmake-build-mingw --parallel 4
```

构建结果直接输出到业务配置使用的目录：

```text
build/cmake-build-mingw/bin/modules/common/luaclib/cjson.so
build/cmake-build-mingw/bin/modules/common/luaclib/pb.so
build/cmake-build-mingw/bin/modules/server/luaclib/uuid/core.so
```

Windows 当前暂时关闭 lsocket，因为仓库中的旧版 Windows 兼容代码与现代 Windows SDK 的
`inet_ntop` 声明冲突。该模块属于后续跨平台适配任务。

使用 skyuv 构建项目模块：

```powershell
cmake --preset windows-vs2022-debug
cmake --build --preset windows-vs2022-debug --parallel 4
```

该模式参考 skyuv 的 `CMakePresets.json`，将 `3rd/skyuv` v0.1.0 作为 CMake 子项目构建，并通过
`skyuv::lua`、`skyuv::platform` 和 `skyuv_skynet_portable` 目标完成链接。
skyuv 的子构建目录固定在 `3rd/skyuv/build/darkgod`，这是 v0.1.0 补丁流程要求的
源码树内构建路径；该目录属于构建产物，不应提交。

构建结果：

```text
build/windows-vs2022-debug/bin/skyuv_skynet_portable.exe
build/windows-vs2022-debug/bin/modules/common/luaclib/cjson.dll
build/windows-vs2022-debug/bin/modules/common/luaclib/pb.dll
build/windows-vs2022-debug/bin/modules/server/luaclib/uuid/core.dll
build/windows-vs2022-debug/bin/modules/server/cservice/package.dll
build/windows-vs2022-debug/lib/*.lib
```

其中 `bin` 放运行时和 Lua/C 服务模块，`lib` 放导入库及其他链接产物；
preset 目录本身负责区分 Debug 和 Release，目录布局与 Granit 的 CMake 输出约定一致。

查看可用 preset：

```powershell
cmake --list-presets
```

## 可选目标

### 构建 lsocket

Linux/macOS 默认启用：

```shell
cmake -S . -B cmake-build
cmake --build cmake-build --parallel
```

Windows 上只有在完成 lsocket 兼容代码更新后才启用：

```powershell
cmake -S . -B cmake-build-mingw -DDARKGOD_BUILD_LSOCKET=ON
```

### 构建 package 服务

`package` 依赖 Skynet 或 skyuv 运行时导出的 `skynet_*` 符号，默认不加入构建。
启用 `DARKGOD_USE_SKYUV` 时会自动链接同一次 CMake 配置生成的
`skyuv_skynet_portable` 目标；原版 Skynet 仍可通过 `DARKGOD_SKYNET_RUNTIME_LIBRARY`
显式指定运行时库：

```powershell
cmake -S . -B cmake-build-mingw `
  -DDARKGOD_BUILD_PACKAGE=ON `
  -DDARKGOD_SKYNET_RUNTIME_LIBRARY="path/to/runtime.lib"
cmake --build cmake-build-mingw --target darkgod_package
```

## 当前限制

- CMake 当前负责项目自有 Lua C 模块、自定义 C 服务目标以及 skyuv 子项目的构建。
- 原版 Skynet 主程序、gate、snlua 等运行时服务不作为 Windows 构建目标。
- Windows skyuv 模式使用 `.dll` 模块后缀；Linux 原版 Skynet 模式仍使用 `.so`。
