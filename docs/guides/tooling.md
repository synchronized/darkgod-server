# 开发脚本与运行手册

本文档说明项目当前推荐的构建、启动、停止和客户端测试流程。

## 目录约定

脚本按职责放在 `tool/` 下：

```text
tool/client/   客户端测试入口
tool/redis/    Redis 配置与生命周期
tool/server/   skyuv server 生命周期
```

运行产生的数据、PID 和日志不会提交到 Git：

```text
var/redis/     Redis 实例数据、配置和日志
var/server/    server PID 和后台日志
```

## 构建

Linux：

```sh
git submodule update --init --recursive
cmake --preset linux-gcc-debug
cmake --build --preset linux-gcc-debug --parallel 4
```

Windows PowerShell：

```powershell
git submodule update --init --recursive
cmake --preset windows-vs2022-debug
cmake --build --preset windows-vs2022-debug --parallel 4
```

如果只需要构建客户端所需的 Lua C 模块，可以构建：

```powershell
cmake --build --preset windows-vs2022-debug `
  --target skyuv_portable_lua_module_client --parallel 4
```

### 构建客户端 Lua 解释器

skyuv 提供独立 Lua 解释器 target，使用与 skyuv runtime 相同的 Lua 版本。
客户端首次使用前构建该 target 即可，不需要手动进入 skyuv 的 Lua 源码目录：

Windows Visual Studio：

```powershell
cmake --build --preset windows-vs2022-debug `
  --target skyuv_lua_interpreter --parallel 4
```

Windows Clang/Clang-cl：

```powershell
cmake --build --preset windows-clang-debug `
  --target skyuv_lua_interpreter --parallel 4
```

Linux/macOS：

```sh
cmake --build --preset linux-gcc-debug --target skyuv_lua_interpreter --parallel 4
```

Visual Studio preset 的解释器位于 `3rd/skyuv/build/darkgod/3rd/Debug/lua.exe`，
Ninja preset 的解释器位于 `3rd/skyuv/build/darkgod/3rd/lua.exe`。
`tool/client/start.ps1` 会按 preset 自动查找对应路径。

如果解释器放在其他位置，可以通过 `-LuaPath` 显式指定：

```powershell
.\tool\client\start.ps1 -LuaPath "C:\tools\lua.exe"
```

客户端也会自动使用当前 preset 的项目模块目录（例如 `pb.dll` 和 `cjson.dll`）。
使用非默认 Windows preset 时同步指定：

```powershell
.\tool\client\start.ps1 -Preset windows-clang-debug
```

Linux/macOS 可通过 `DARKGOD_PRESET` 指定构建 preset。

## Redis

默认使用两个本地实例：

| 实例 | 地址 | 用途 |
|---|---|---|
| redis0 | `127.0.0.1:6379` | center |
| redis1 | `127.0.0.1:6380` | group 1 |

Linux：

```sh
# 生成配置；start.sh 也会自动执行
tool/redis/setup.sh

# 启动、查看状态、停止
tool/redis/start.sh
tool/redis/status.sh
tool/redis/stop.sh
```

Windows：

```powershell
.\tool\redis\setup.ps1
.\tool\redis\start.ps1 -Action Start
.\tool\redis\status.ps1
.\tool\redis\stop.ps1
```

如果 `redis-server.exe` 不在 `PATH`：

```powershell
.\tool\redis\start.ps1 -Action Start `
  -RedisServerPath "C:\tools\Redis\redis-server.exe"
```

重置本地 Redis 数据前请确认不需要保留角色数据：

```sh
tool/redis/reset.sh
```

```powershell
.\tool\redis\reset.ps1
```

也可以通过环境变量调整实例数量和起始端口：

```sh
REDIS_INSTANCE_COUNT=2 REDIS_BASE_PORT=6379 tool/redis/start.sh
```

PowerShell 使用脚本参数：

```powershell
.\tool\redis\start.ps1 -InstanceCount 2 -BasePort 6379
```

## Server

### 直接运行指定构建产物

推荐先确认 preset，再直接运行该 preset 目录下的 `skyuv` 和配置文件。这样可以明确
知道使用的是哪一份编译产物：

Windows：

```powershell
.\build\windows-vs2022-debug\project\bin\skyuv.exe `
  .\build\windows-vs2022-debug\project\config\config-skyuv-pb.lua
```

Linux/macOS：

```sh
./build/linux-gcc-debug/project/bin/skyuv \
  ./build/linux-gcc-debug/project/config/config-skyuv-pb.lua
```

配置文件由下面的快捷脚本按 preset 生成；如果切换 preset，请先用对应 preset
启动一次脚本，或复制生成的配置文件后再直接运行。

### 前台启动

前台启动适合开发调试，日志直接输出到当前终端。

Linux：

```sh
tool/server/start.sh
```

Windows：

```powershell
.\tool\server\start.ps1
```

脚本启动时会打印实际使用的 preset、`skyuv.exe` 和配置文件，并在路径不存在时直接失败。
可以显式指定其他构建产物：

```powershell
.\tool\server\start.ps1 -Preset windows-clang-debug -Configuration Debug
```

server 启动前需要确保 Redis 的 `6379` 和 `6380` 已经可用。

### 后台启动

后台模式的 PID 和日志位于 `var/server/`。

Linux：

```sh
DARKGOD_BACKGROUND=1 tool/server/start.sh
tool/server/status.sh
tool/server/stop.sh
```

Windows：

```powershell
.\tool\server\start.ps1 -Background
.\tool\server\status.ps1
.\tool\server\stop.ps1
```

Windows 下如果希望 Redis 和 server 一起启动或停止：

```powershell
.\tool\server\start-all.ps1 -Background
.\tool\server\stop-all.ps1
```

前台启动的 server 不由 `stop` 脚本管理，应直接在运行窗口按 `Ctrl+C` 停止。

## 客户端连通性测试

客户端会连接默认地址 `127.0.0.1:9777`，执行登录、角色和基础业务请求。

Linux：

```sh
tool/client/start.sh
```

也可以指定 IP、用户名和密码：

```sh
tool/client/start.sh 127.0.0.1 sunday1 123456
```

Windows：

```powershell
.\tool\client\start.ps1
.\tool\client\start.ps1 `
  -Ip 127.0.0.1 -Username sunday1 -Password 123456
```

客户端脚本也会打印实际使用的 Lua 解释器、skyuv 模块目录和项目模块目录；如果这些目录
不存在会直接失败，避免静默加载旧产物。

如果 Lua 解释器不在 skyuv 子模块默认路径：

```powershell
.\tool\client\start.ps1 `
  -LuaPath "C:\tools\lua.exe" `
  -SkyuvLuaCpath "D:\path\to\skyuv\build\darkgod\3rd\portable\luaclib"
```

客户端加载 skyuv 统一输出的 `client.dll`，同时提供 `client.socket` 和
`client.crypt` 两个 Lua 模块入口。正常构建 preset 会生成该模块；如果只构建
客户端模块，请使用上面的 `skyuv_portable_lua_module_client` target。

## 推荐测试顺序

```text
构建项目
  ↓
启动 Redis
  ↓
确认 Redis 状态
  ↓
启动 server
  ↓
确认 server 状态（后台模式）
  ↓
启动客户端
  ↓
检查登录、角色和业务日志
```

常见检查：

- Redis：`6379`、`6380` 均显示 `running`。
- Server：后台模式下 `status` 显示 PID 和 `running`。
- 客户端：没有 `module 'client.socket' not found`。
- 登录失败：检查 Redis 日志和 server 日志。
- 端口占用：确认 `9777`、`6379`、`6380` 没有被其他进程占用。

## 脚本边界

- `tool/redis/start.*` 会自动生成 Redis 配置。
- `tool/server/start.*` 默认以前台模式运行，不会自动启动 Redis。
- `tool/server/start-all.ps1` 只提供 Windows 下的 Redis + server 组合启动。
- `tool/server/stop.*` 只管理后台模式写入的 server PID，不会强制终止任意同名进程。
