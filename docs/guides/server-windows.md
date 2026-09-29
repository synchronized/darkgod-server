# Windows 服务器启动

## 运行前提

- 已初始化 Git 子模块：`git submodule update --init --recursive`。
- 已按 [CMake 构建指南](build-cmake.md) 构建 skyuv v0.1.1 和项目模块。
- 已安装 Windows 版本的 `redis-server.exe`，并将其加入 `PATH`，或者启动时通过
  `-RedisServerPath` 指定完整路径。

项目数据库配置使用两个本地 Redis 实例：

| 实例 | 地址 | 用途 |
|---|---|---|
| redis0 | `127.0.0.1:6379` | center |
| redis1 | `127.0.0.1:6380` | group 1 |

Redis 数据、配置和日志会生成到 `var/windows-redis/`，该目录不应提交。

## 构建

```powershell
cmake --preset windows-vs2022-debug
cmake --build --preset windows-vs2022-debug --parallel 4
```

## 一键启动

如果 `redis-server.exe` 已在 `PATH`：

```powershell
.\tool\server\start-windows.ps1
```

如果 Redis 不在 `PATH`：

```powershell
.\tool\server\start-windows.ps1 `
  -RedisServerPath "C:\tools\Redis\redis-server.exe"
```

脚本会先启动 `6379`、`6380` 两个 Redis 实例，然后启动 skyuv 业务节点。
已经运行的 Redis 实例会被复用，不会被重复启动。

## Redis 管理

```powershell
# 生成 Redis 配置但不启动
.\tool\redis\setup.ps1

# 查看状态
.\tool\redis\status.ps1

# 单独启动 Redis
.\tool\redis\start.ps1 -Action Start `
  -RedisServerPath "C:\tools\Redis\redis-server.exe"

# 停止本项目配置创建的 Redis 实例
.\tool\redis\stop.ps1
```

`Stop` 只根据 `var/windows-redis/redis*.pid` 停止由本项目配置创建、且进程名为
`redis-server` 的实例，不会按端口强制终止其他 Redis 进程。

## 直接启动 skyuv

如果 Redis 已经由其他方式启动，可以跳过 Redis 脚本：

```powershell
.\tool\server\start-skyuv.ps1
```

默认运行 Debug 构建，也可以指定配置目录：

```powershell
.\tool\server\start-skyuv.ps1 -Configuration Release
```

## 故障排查

如果日志出现：

```text
Connect failed connection refused 127.0.0.1 6379
```

先检查 Redis：

```powershell
.\tool\redis\start.ps1 -Action Status
```

确认 `6379` 和 `6380` 均为 `running` 后，再重新启动服务器。Redis 日志位于
`var/windows-redis/redis0/redis0.log` 和 `var/windows-redis/redis1/redis1.log`。
