# skyuv v0.1.0 CMake 集成记录

## 环境

- 平台：Windows x64
- 编译器：Visual Studio 2022 / MSVC
- skyuv：`v0.1.0` (`c6ec175`)
- 生成器：Visual Studio 17 2022
- skyuv 测试：由 skyuv 独立构建记录覆盖，本次 darkgod 集成关闭测试目标

## 配置

```powershell
cmake -S . -B cmake-build-skyuv-v010 `
  -G "Visual Studio 17 2022" -A x64 `
  -DDARKGOD_BUILD_PACKAGE=ON `
  -DDARKGOD_BUILD_LSOCKET=OFF `
  -DDARKGOD_BUILD_PACKAGE=ON `
  -DSKYUV_USE_SHARED_LIBUV=OFF `
  -DSKYUV_BUILD_TESTS=OFF
```

darkgod 通过 `add_subdirectory` 接入 skyuv，并链接 `skyuv::lua`、
`skyuv::platform` 和 `skyuv_skynet_portable`。skyuv 子构建目录为
`3rd/skyuv/build/darkgod`，以满足 v0.1.0 Skynet 补丁流程的路径要求。

## 结果

以下目标构建成功：

- `cjson.dll`
- `pb.dll`
- `uuid/core.dll`（Lua 模块名为 `uuid.core`）
- `package.dll`
- `skyuv_skynet_portable.exe`

构建过程中存在 libuv 原有的 MSVC 转换警告，以及 skyuv 头文件的代码页警告，
均未阻止构建。`lua-cjson` 的旧版指针转换警告仍然存在，属于后续清理项。

## 业务启动验证

使用 `tool/server/start-windows.ps1` 启动两个 Redis 实例后，skyuv 业务节点已成功加载：

- `database`、`loginserver`、`loginwork`；
- `socket_proxyd`、`manager`、`sharedatad`；
- `world`、`map`、`agent`、`hub`；
- hub 监听 `0.0.0.0:9777`。

仍未完成登录协议、角色、地图和战斗的客户端回归，以及 Windows 长时间运行和连接压力测试。
