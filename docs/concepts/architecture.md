# 项目架构

## 当前状态

项目当前使用 Skynet 兼容的 Lua 服务模型，所有平台由 skyuv 提供兼容运行时。运行时负责
Actor/Service 生命周期、服务间消息、定时器和网络事件分发；
业务代码位于 `server/` 和 `common/`，协议和数据位于 `proto/`。

## 目录职责

```text
server/service/       业务服务：main、login、map、agent 等
server/lualib/        服务端 Lua 库和配置
server/service-src/   自定义 Skynet C 服务
server/lualib-src/    服务端 Lua C 模块
common/lualib/        客户端和服务端共享 Lua 库、协议辅助代码
client/               测试客户端
proto/                sproto/protobuf 协议和生成数据
3rd/skyuv/            skyuv 运行时及其内部 Skynet、libuv 子模块
tool/                 构建、启动和 Redis 辅助脚本
```

## 运行关系

```text
客户端
  │ TCP / 协议消息
  ▼
Skynet gate/socket
  ▼
server/service/main.lua
  ├─ loginserver / loginwork
  ├─ agent
  ├─ map / world
  ├─ database
  └─ manager / hub / gdd
```

业务服务通过 `require "skynet"` 使用运行时 API。配置文件通过 `lua_path`、`lua_cpath`、
`cpath` 和 `luaservice` 指向业务代码与 Skynet 运行时目录。

## 构建边界

当前 CMake 工程生成 skyuv 运行时以及 `cjson`、`pb`、`uuid`、`lsocket` 和 `package` 等模块；项目自己的
C 模块必须针对 skyuv 兼容层重新编译，不能直接复用旧二进制。

## skyuv 的位置

skyuv 不是新的业务框架，而是保留 Skynet 上层模型、使用 libuv 替换底层平台和网络实现的运行时。
因此迁移的主要边界是：

- Lua 服务模型和消息语义尽量保持不变。
- 启动程序和配置路径需要调整。
- 自定义 C 服务和 Lua C 模块需要重新构建。
- Windows 下涉及原生 socket fd 的代码需要单独验证。

## 运行时依赖

- Redis：账号、角色和数据库相关服务使用。
- protobuf/sproto：客户端和服务端协议。
- OpenSSL crypto：项目部分 C 模块的编译依赖。
- skyuv：迁移目标运行时，仍包含兼容的 Skynet 核心和 Lua 环境。
