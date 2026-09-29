# 001：迁移到 skyuv

## 状态

- 状态：实施中
- 日期：2026-09-28
- 前置计划：[000：迁移到 CMake 构建](000-cmake-migration.md)
- 目标：在保留现有 Lua 业务逻辑的前提下，让项目使用 skyuv 运行时构建和启动
- 当前阶段：skyuv v0.1.0 已完成 CMake 子项目接入和 Windows 模块构建，等待 Redis 后继续完整回归

## 背景与目标

项目当前通过 `3rd/skynet`、Makefile 和 shell 启动脚本构建运行。skyuv 保留 Skynet 的 Actor、
消息队列、服务调度和上层 Lua API，同时以 libuv 替换底层网络及平台能力，适合作为跨平台运行时。

本计划的目标是：

- 在 Linux 上建立原版 Skynet 基线，并在 Windows 上直接建立 skyuv 运行基线。
- 使用 skyuv 启动现有业务 Lua 服务。
- 将项目自有 C 模块纳入可重复的 CMake 构建。
- 验证登录、角色、地图、战斗和 AOI 主流程。
- 为 Windows/macOS 后续验证保留清晰的边界和记录入口。

## 非目标

- 不重写现有 Actor/Service 业务架构。
- 不在本阶段替换 Redis、协议格式或数据库结构。
- 不将 skyuv 改造成独立于 Skynet 的新框架。
- 不在没有测试数据的情况下承诺性能优于原版 Skynet。
- 不直接删除原 `3rd/skynet`；它在 Linux 上继续作为行为对照基线，Windows 不再依赖其可执行文件。

## 已确认决策

1. 采用 skyuv 的 CMake 构建和运行时，不继续把原 Makefile 作为唯一入口。
2. Lua 服务先按兼容模式迁移，只有测试发现差异时才修改业务代码。
3. `package`、`uuid`、`cjson`、`pb` 和 `lsocket` 必须针对 skyuv 重新编译。
4. 迁移期间保留原 Skynet 启动路径，允许通过配置或脚本切换运行时。
5. 详细命令输出、平台矩阵和性能结果写入 `docs/records/`，不持续膨胀本计划。
6. skyuv 固定使用发布版本 `v0.1.0`，通过 CMake 子项目目标接入，不再手动拼接 skyuv `.lib` 路径。

## 实施顺序

### 阶段 0：确认 CMake 前置计划完成

- 确认 [000：迁移到 CMake 构建](000-cmake-migration.md) 已达到出口条件。
- 确认项目自有 C 模块不再依赖 Skynet `platform.mk`。
- 确认使用独立构建目录可以生成全部项目模块。
- 确认 `3rd/skyuv` 已固定到 `v0.1.0`，并通过 `skyuv::lua`、`skyuv::platform` 和
  `skyuv_skynet_portable` 目标完成链接。

出口：项目构建系统已经可以独立切换 Skynet 运行时来源；Windows skyuv 模式不再依赖
预先生成的外部 `.lib` 路径。

### 阶段 1：建立基线

- Linux：记录当前 Skynet 提交、编译器、Lua 版本和启动方式。
- Linux：完成当前项目的登录、角色、地图和客户端回归。
- Windows：记录当前编译器、skyuv 提交和目标运行时目录；不把原版 Skynet 构建作为前置条件。
- 保存启动日志、端口、Redis 配置和已知失败行为。

出口：Linux 有原版 Skynet 对照基线，Windows 有 skyuv 最小节点启动条件。

### 阶段 2：构建 skyuv 运行时

- 固定 skyuv 提交和子模块版本。
- 使用 skyuv 官方 preset 构建最小运行时、Lua 服务和 TCP echo。
- 确认 `cservice`、`lualib`、`luaclib`、`service` 的输出位置。
- 确认项目当前编译器和 skyuv CMake 工具链兼容。
- 使用 skyuv `v0.1.0` 发布的 CMake targets 供 darkgod 模块链接。

出口：skyuv 最小节点和 echo 示例通过，构建结果可从干净目录启动。skyuv `v0.1.0`
作为 darkgod CMake 子项目的 Windows 配置和模块构建已验证；skyuv 独立运行时验证见
[Windows 构建记录](../records/skyuv-windows-build.md)。

### 阶段 3：迁移配置和 Lua 服务

- 建立 skyuv 版本的业务配置和 Windows 启动脚本。
- 调整 `skynet_root`、Lua 搜索路径、服务路径和启动入口。
- 先启动 `main.lua` 及其依赖，确认项目自定义 `package` C 服务可以加载。
- 验证服务加载、定时器、消息调用和 Redis 初始化。

出口：skyuv 可以加载业务 Lua 服务和 `package.dll`，Redis 可用时登录入口可监听并接受测试连接。

### 阶段 4：迁移项目 C 模块

- 把 cjson、pb、uuid 和 lsocket 的编译规则迁移到 CMake。
- 为 `service_package.c` 增加 skyuv 运行时兼容头文件和链接目标。
- 确认动态模块命名、搜索路径和 Windows 导出规则。
- 明确每个模块的 Lua ABI、外部库和所有权要求。

出口：所有项目自有模块能在目标平台加载，且不存在旧 Skynet 二进制混用。

### 阶段 5：业务回归

- 登录、账号创建和角色创建。
- 角色列表、角色选择和数据库读写。
- 地图进入、移动、AOI 通知和地图退出。
- 战斗请求、目标同步和错误处理。
- 客户端断线、服务关闭、Redis 重启后的恢复行为。

出口：核心业务用例与阶段 0 基线结果一致，差异已经记录并判断是否可接受。

### 阶段 6：跨平台与稳定性

- Linux：对照原 Skynet 执行长时间运行和连接压力测试。
- Windows：验证普通 TCP 监听、动态模块加载、路径和正常退出。
- macOS：验证构建、动态库加载和普通 TCP 流程。
- 收集 CPU、内存、连接数、消息延迟和异常退出数据。

出口：目标平台矩阵和已知限制写入 Record，生产入口替换得到明确结论。

## 测试与验收

### 功能验收

- skyuv 最小节点能启动并正常退出。
- 业务配置能加载所有 Lua 服务。
- 客户端能完成登录、角色创建、角色选择、地图移动和战斗。
- `package`、protobuf、uuid、cjson 等模块加载成功。
- 客户端断开和服务器退出不产生未释放连接或持续增长的服务。

### 兼容性验收

- 服务间消息调用的成功、错误和超时语义无未解释变化。
- 定时器触发顺序满足业务要求。
- TCP 拆包、粘包、空包和大包行为满足现有协议。
- Linux 上 skyuv 与原 Skynet 的关键 socket 行为完成对照。

### 交付验收

- 新环境可以按文档完成构建和启动。
- 运行时、配置、Lua 文件和 C 模块目录边界清晰。
- Linux 原版 Skynet 启动路径仍可作为回退和行为对照方案；Windows 运行入口使用 skyuv。
- 迁移结果、平台限制和性能数据已写入 `docs/records/`。

## 风险与未决问题

| 风险/问题 | 影响 | 处理方式 |
|---|---|---|
| skyuv CMake 子项目的补丁流程要求源码树内构建目录 | 外部二进制目录配置会失败 | darkgod 固定使用 `3rd/skyuv/build/darkgod`，并在构建指南中说明 |
| 当前 Makefile 依赖 Skynet `platform.mk` | 不能直接沿用旧构建 | 新增 CMake 入口，迁移完成后再决定 Makefile 去留 |
| socket 事件顺序或关闭语义差异 | 登录和连接清理可能异常 | 用阶段 0 基线和协议测试对照 |
| Windows 旧 `int fd` 接口限制 | 外部 socket 接管不可直接迁移 | 第一阶段只验收普通监听和连接 |
| OpenSSL 和 Redis 外部依赖 | 构建或启动失败 | 在构建前固定版本、路径和健康检查 |
| skyuv 与当前 Skynet 提交不一致 | 私有符号或头文件不兼容 | 固定版本，不混用两个运行时的头文件和库 |

## 后续文档

- 构建命令稳定后补充 `docs/guides/build.md`。
- 配置路径和启动入口稳定后补充 `docs/reference/runtime-layout.md`。
- 每个平台完成验证后新增 `docs/records/skyuv-<platform>-validation.md`。
- 如果决定长期保留 skyuv 作为唯一运行时，再新增对应 ADR 并更新项目 README。
