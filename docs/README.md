# 文档中心

本项目是一个基于 Skynet 的 Lua 游戏服务器，包含登录、角色、地图移动、战斗和 AOI 等示例功能。
当前文档重点是评估并实施向 `skyuv` 运行时的迁移。

启动脚本按职责和平台统一放在 `tool/setup/`、`tool/server/`、`tool/redis/` 和
`tool/client/`；Linux 使用 `.sh`，Windows 使用 `.ps1`。旧的根目录脚本保留为兼容入口，
新文档优先使用新目录。

## 推荐阅读顺序

1. [项目架构](concepts/architecture.md)：了解当前目录、服务和依赖边界。
2. [skyuv 迁移指南](guides/skyuv-migration.md)：了解迁移涉及的入口、配置和模块。
3. [skyuv 迁移计划](plans/001-skyuv-migration.md)：查看实施阶段、验收条件和未决问题。
4. [项目文档规范](../DOCUMENTATION_GUIDE.md)：新增或修改文档时遵循的规则。

## 分类索引

### Guides

- [使用 CMake 构建](guides/build-cmake.md)
- [Windows 服务器启动](guides/server-windows.md)
- [skyuv 迁移指南](guides/skyuv-migration.md)

### Concepts

- [项目架构](concepts/architecture.md)

### Plans

- [000：迁移到 CMake 构建](plans/000-cmake-migration.md)
- [001：迁移到 skyuv](plans/001-skyuv-migration.md)

### Records

- [skyuv Windows 构建记录](records/skyuv-windows-build.md)
- [skyuv Windows 业务启动记录](records/skyuv-windows-business-bootstrap.md)
- [skyuv v0.1.0 CMake 集成记录](records/skyuv-v010-cmake-integration.md)

后续将继续在此目录记录业务启动、平台矩阵、兼容性差异和性能结果。

## 当前文档状态

本项目原有文档主要集中在根目录 README 和第三方库文档中，尚未建立完整的 API Reference、ADR
和迁移 Record。这些分类按实际需要逐步补充，不为填充目录创建空文件。
