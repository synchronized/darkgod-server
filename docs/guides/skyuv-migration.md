# 迁移到 skyuv

## 适用场景

当需要在 Linux 之外运行本项目，或希望使用 libuv 提供跨平台网络和平台适配能力时，使用本指南。
skyuv 项目地址：[synchronized/skyuv](https://github.com/synchronized/skyuv)。

## 当前结论

本项目可以迁移到 skyuv，但不是替换一个可执行文件即可完成。Lua 业务层应优先保持不变，启动
配置、CMake 构建、自定义 C 服务和 Lua C 模块需要逐项迁移并验证。

## 迁移边界

可以优先复用：

- `server/service/` 下的 Lua 服务。
- `server/lualib/` 和 `common/lualib/` 下的 Lua 库。
- 现有协议文件和 Redis 数据结构。
- Skynet 的 Actor、消息、定时器和 socket 使用方式。

需要重新确认：

- `tool/server/start.sh`、`tool/server/start.ps1` 的运行时入口，以及对应的 `status`/`stop` 生命周期脚本。
- `server/config`、`server/config-pb` 中的路径。
- `server/service-src/service_package.c`。
- `server/lualib-src/lua-uuid.c`、cjson、pb 和 skyuv `client.socket` 的编译产物。
- Windows 动态库后缀、路径和外部 socket fd 语义。

## 推荐迁移步骤

1. 固定 skyuv 版本，并初始化其 Skynet、libuv 子模块。
2. 使用 skyuv 官方 CMake preset 构建最小运行时和 TCP echo 示例。
3. 复制 skyuv 示例配置，替换 `start`、`lua_path`、`lua_cpath`、`cpath` 和 `luaservice`。
4. 先启动不加载自定义 C 服务的业务 Lua 节点。
5. 重新构建 cjson、pb、uuid 和 skyuv 客户端 socket 模块。
6. 将 `package` C 服务接入 skyuv 的 CMake 构建并重新编译。
7. 依次验证登录、角色、地图、移动、战斗、AOI 和正常退出。
8. 在目标平台执行长时间运行和连接压力测试后，再替换生产入口。

Windows 当前可以使用 [start.ps1](../../tool/server/start.ps1) 启动入口；该入口
使用 [config-skyuv-pb.lua](../../server/config-skyuv-pb.lua)，不依赖原版 Skynet 可执行文件。

## 验证重点

- Lua 服务能否正常加载。
- gate/socket 的监听、接收、拆包和回包是否正常。
- 定时器和服务间消息顺序是否保持。
- 自定义 `package` 服务的 socket 生命周期和超时处理是否保持。
- Redis 连接失败、客户端断开和服务退出时是否能正确清理。
- Windows 下是否存在 `.dll`、`.so`、运行库或路径编码问题。

## 常见问题

### 可以直接把原版 Skynet 可执行文件换成 skyuv 吗？

不建议。skyuv 使用自己的 CMake 构建和运行时目录，项目配置及自定义模块也需要跟随调整。

### 旧的 `.so` 能继续使用吗？

不应假定可以。自定义 C 模块依赖 Skynet/Lua 的内部头文件和符号，应使用目标平台和 skyuv 对应
版本重新编译。

### 是否需要重写 Lua 业务服务？

第一阶段不需要。只有兼容性测试发现 API、socket 事件顺序或关闭语义差异时，才针对具体服务修改。

### Windows 是否完全等价？

不一定。skyuv 对旧版 `socket.bind(int fd)` 的 Windows 外部句柄接管存在明确限制；本项目应优先验证
普通监听和连接流程，不要把 Unix fd 接管能力视为跨平台能力。
