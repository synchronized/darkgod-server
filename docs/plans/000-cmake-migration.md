# 000：迁移到 CMake 构建

## 状态

- 状态：实施中
- 日期：2026-09-28
- 优先级：高
- 前置条件：无
- 后续依赖：[001：迁移到 skyuv](001-skyuv-migration.md)
- 进度：项目自有 Lua C 模块已可由 CMake 在 Windows 上构建；运行时接入转由 skyuv 计划完成

## 背景与目标

当前项目的 [Makefile](../../Makefile) 依赖 Skynet 的 `platform.mk`，并通过多个子目录中的 Makefile
生成 Lua C 模块和自定义 C 服务。skyuv 使用 CMake 构建，因此需要先建立项目自己的 CMake 构建入口，
再进行运行时迁移。

本计划的目标是：

- 用 CMake 替代项目自定义模块对 `platform.mk` 的直接依赖。
- 让项目模块可以使用外部运行时目标构建；Linux 可用原版 Skynet 做行为基线，Windows 直接面向 skyuv。
- 统一生成 `cjson`、`pb`、`uuid`、`lsocket` 和 `package`。
- 让同一套项目构建目标可以切换到 Skynet 或 skyuv 的 CMake 运行时。

## 非目标

- 第一阶段不实现 Skynet/skyuv 主运行时；运行时由外部项目提供。
- 不修改 Lua 业务逻辑、协议格式或 Redis 数据结构。
- 不在本计划中解决 skyuv 的 socket 兼容性问题。
- 不强行删除旧 Makefile；完成过渡前保留回退入口。
- 不把第三方 Skynet、Redis 和 OpenSSL 的全部构建纳入项目 CMake。

## 已确认决策

1. 项目 CMake 负责项目自有目标，第三方依赖优先通过 imported target、变量或外部构建结果接入。
2. CMake 目标必须明确区分 Lua C 模块、Skynet C 服务和普通可执行文件。
3. 输出目录保持与现有配置兼容：`common/luaclib`、`server/luaclib`、`server/cservice` 和
   `client/luaclib`。
4. CMake 构建结果必须能够被现有 `server/config` 和 `server/config-pb` 加载。
5. 迁移期间用旧 Makefile 构建结果和客户端流程作为行为对照。

## 目标结构

```text
CMakeLists.txt
cmake/
├─ ProjectOptions.cmake       # 项目选项和编译警告
├─ Dependencies.cmake         # Lua、Skynet、OpenSSL 等依赖定位
└─ ProjectModules.cmake       # 模块和服务目标定义
```

最终目录可以根据实际实现调整，不要求一次创建所有辅助文件。

## 实施顺序

### 阶段 0：记录旧构建基线

- 记录编译器、Lua 版本、Skynet 提交和系统环境。
- 执行旧 Makefile 的完整构建。
- 确认每个 `.so` 的输出位置、依赖和加载名称。
- 使用测试客户端完成登录、角色、地图和战斗最小流程。

出口：旧 Makefile 构建和核心业务流程可重复运行。

### 阶段 1：建立最小 CMake 工程

- 添加顶层 `CMakeLists.txt`。
- 设置 C11、Lua 头文件、输出目录和基础编译选项。
- 增加 Debug/Release 配置。
- 增加 `cmake --build` 和 `cmake --install` 的基本路径。

出口：CMake 能配置并生成项目构建文件，不要求所有模块立即完成。

### 阶段 2：迁移 Lua C 模块

- 添加 `cjson` 目标。
- 添加 `pb` 目标。
- 添加 `uuid` 目标。
- 添加客户端 `lsocket` 目标。
- 确认每个模块的 Lua ABI、包含目录、链接库和输出名称。

出口：生成的模块可以被 Linux Skynet 或 Windows skyuv 配置加载，且与旧 Makefile 结果完成基本对照。

### 阶段 3：迁移自定义 C 服务

- 添加 `package` C 服务目标。
- 接入 skyuv 内部 Skynet 兼容头文件和 Lua 头文件。
- 确认 `skynet_malloc`、`skynet_send`、`skynet_socket_*` 等符号由 Skynet/skyuv 运行时提供。
- Linux 使用 Skynet 做基线验证，Windows 使用 skyuv 完成监听、收包、回包、关闭和超时流程验证。

出口：`server/service-src/service_package.c` 可由 CMake 编译并被当前配置加载。

### 阶段 4：切换构建入口

- 更新启动文档和脚本，使 Linux 可选择原版 Skynet、Windows 使用 skyuv。
- 增加一个干净构建目录验证流程。
- 对比两种构建结果的模块加载和业务回归结果。
- 明确旧 Makefile 的保留期限和删除条件。

出口：CMake 成为项目模块的推荐构建方式，旧 Makefile 仅作为 Linux 回退方式。

### 阶段 5：为 skyuv 接入做准备

- 把 Skynet 运行时依赖抽象为可配置路径或 CMake target。
- 避免项目代码直接假设 Skynet `platform.mk` 存在。
- 确认自定义模块可以使用 skyuv 提供的兼容头文件和链接目标重新构建。
- 将 skyuv 迁移计划的构建部分改为复用本计划的目标。

出口：进入 [001：迁移到 skyuv](001-skyuv-migration.md) 时，不再需要重新设计项目构建系统。

## 测试与验收

### 构建验收

- Linux Debug 和 Release 配置均可完成配置和构建。
- CMake 生成的所有模块输出到当前配置可搜索的目录。
- 干净构建不依赖上一次 Makefile 生成的对象文件或动态库。
- CMake 构建不修改第三方源码。

### 加载验收

- cjson、pb、uuid、lsocket 加载成功。
- `package` C 服务加载成功。
- `server/config` 和 `server/config-pb` 均可启动。
- 模块名称和 Lua `require` 名称与旧构建一致。

### 回归验收

- 登录和账号创建。
- 角色创建、列表和选择。
- 地图进入、移动和 AOI。
- 战斗请求和结果同步。
- 客户端断开、服务退出和 Redis 连接失败处理。

## 风险与未决问题

| 风险/问题 | 影响 | 处理方式 |
|---|---|---|
| Skynet 运行时没有稳定的 CMake SDK | 自定义服务链接可能依赖内部目标 | 第一阶段固定本地 Skynet 版本，明确 include 和 link 边界 |
| Lua C 模块输出扩展名与平台有关 | Windows 可能无法沿用 `.so` | 使用 CMake MODULE target 和平台输出规则，配置中使用平台通配路径 |
| OpenSSL 静态库路径不统一 | uuid 或其他模块构建失败 | 提供显式 `OPENSSL_ROOT_DIR` 和构建前检查 |
| 旧 Makefile 与 CMake 产物混用 | 出现难以定位的 ABI 问题 | 使用独立构建目录和干净运行目录验收 |
| skyuv 目标名称和内部 ABI 变化 | 后续接入成本变化 | 固定 skyuv 提交，在迁移记录中记录 target 和头文件版本 |

## 完成后的文档

- 新增 `docs/guides/build-cmake.md`，说明依赖、配置、构建和清理。
- 在 `docs/records/` 保存不同编译器和平台的构建结果。
- 更新 [001：迁移到 skyuv](001-skyuv-migration.md) 的状态和前置条件。
