# skyuv Windows 业务启动记录

## 日期

2026-09-29

## 构建结果

使用 skyuv 已构建的 Windows Debug 运行时，并通过项目 CMake 的 `DARKGOD_USE_SKYUV` 模式生成：

+ `build/windows-vs2022-debug/bin/modules/common/luaclib/cjson.dll`
+ `build/windows-vs2022-debug/bin/modules/common/luaclib/pb.dll`
+ `build/windows-vs2022-debug/bin/modules/server/luaclib/uuid/core.dll`
+ `build/windows-vs2022-debug/bin/modules/server/cservice/package.dll`
+ `build/windows-vs2022-debug/bin/skyuv_skynet_portable.exe`

构建命令和参数见 [CMake 构建指南](../guides/build-cmake.md)。

## 启动验证

启动入口：

```powershell
.\tool\server\start-skyuv.ps1
```

使用配置：[server/config-skyuv-pb.lua](../../server/config-skyuv-pb.lua)。

已观察到：

- skyuv portable runtime 启动成功。
- `snlua bootstrap`、`service_mgr`、`main` 成功加载。
- `console`、`debug_console`、`protod` 和 `database` 服务成功创建。
- 项目 Lua 搜索路径和 skyuv 服务路径配置生效。

## Redis 与业务启动

通过 `tool/server/start-windows.ps1` 自动启动 Redis 后，业务服务已完整进入运行状态：

- `snlua bootstrap`、`database`、`loginserver`、`world`、`map` 和 `hub` 均成功启动。
- Hub 成功监听 `0.0.0.0:9777`。
- `package.dll`、protobuf 和 UUID 模块均完成加载。
