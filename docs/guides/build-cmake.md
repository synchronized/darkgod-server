# 使用 CMake 构建

## 适用场景

本指南说明如何使用 CMake 构建 skyuv 运行时和当前项目自有 Lua C 模块。所有平台均由 skyuv
提供运行时，不再依赖父项目的原版 Skynet 子模块。

## 前置条件

- CMake 3.23 或更高版本。
- 支持 C11 的编译器。
- 已递归初始化 `3rd/skyuv`、`3rd/lua-cjson`、`3rd/lsocket` 和 `3rd/pb` 子模块。
- 所有平台：skyuv 运行时及其内部 Skynet 子模块。

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
build/cmake-build-mingw/project/modules/common/luaclib/cjson.so
build/cmake-build-mingw/project/modules/common/luaclib/pb.so
build/cmake-build-mingw/project/modules/server/luaclib/uuid/core.so
```

Windows 当前暂时关闭 lsocket，因为仓库中的旧版 Windows 兼容代码与现代 Windows SDK 的
`inet_ntop` 声明冲突。该模块属于后续跨平台适配任务。

使用 skyuv 构建项目模块：

```powershell
cmake --preset windows-vs2022-debug
cmake --build --preset windows-vs2022-debug --parallel 4
```

该模式参考 skyuv 的 `CMakePresets.json`，将 `3rd/skyuv` v0.1.1 作为 CMake 子项目构建，并通过
`skyuv::lua`、`skyuv::platform` 和 `skyuv` 目标完成链接。
skyuv 的子构建目录固定在 `3rd/skyuv/build/darkgod`，这是 v0.1.1 补丁流程要求的
源码树内构建路径；该目录属于构建产物，不应提交。

构建结果：

```text
build/windows-vs2022-debug/project/bin/skyuv.exe
build/windows-vs2022-debug/project/modules/common/luaclib/cjson.dll
build/windows-vs2022-debug/project/modules/common/luaclib/pb.dll
build/windows-vs2022-debug/project/modules/server/luaclib/uuid/core.dll
build/windows-vs2022-debug/project/modules/server/cservice/package.dll
build/windows-vs2022-debug/project/lib/*.lib
```

其中 `project/bin` 放运行时，`project/modules` 放 Lua/C 服务模块，`project/lib` 放导入库及其他链接产物，
`project/config` 放启动时生成的配置；preset 目录本身负责区分 Debug 和 Release。

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

`package` 依赖 skyuv 运行时导出的 `skynet_*` 符号，默认不加入构建；启用目标后会自动链接同一次
CMake 配置生成的 `skyuv` 目标：

```powershell
cmake -S . -B cmake-build-mingw -DDARKGOD_BUILD_PACKAGE=ON
cmake --build cmake-build-mingw --target darkgod_package
```

## 当前限制

- CMake 当前负责项目自有 Lua C 模块、自定义 C 服务目标以及 skyuv 子项目的构建。
- skyuv 主程序、gate、snlua 等运行时服务由 skyuv 子项目构建。
- 当前 skyuv 集成使用 `.dll` 模块后缀；Linux/macOS 的平台后缀适配待单独验证。
