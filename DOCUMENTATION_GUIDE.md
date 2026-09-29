<!-- SPDX-License-Identifier: MIT -->

# 项目文档规范

## 目的

本规范约束项目文档的职责、组织和生命周期，使读者能够找到唯一可信的信息来源，并明确区分
当前实现、未来计划和历史记录。

## 核心原则

### 单一职责

每份文档只回答一种主要问题。README 负责入口，Guide 负责操作，Concept 负责原理，Plan 负责
尚未完成的实现方案，Record 负责已经发生的执行和验证结果。

### 单一事实来源

同一事实只在一个文档中维护。其他文档只保留摘要和链接，不复制会持续变化的任务清单、接口说明
或验证结果。

### 区分现状、未来与历史

- 当前代码已经具备的能力写入 Guide、Reference 或 Concept。
- 尚未完成的能力写入 Plan 或 Roadmap。
- 已完成的迁移、测试、性能数据和偏差写入 Record。
- 计划文档不得使用“已支持”描述尚未验收的功能。

## 文档类型

| 类型 | 主要问题 | 目录 |
|---|---|---|
| README | 这是什么，如何快速运行 | 根目录 |
| 文档中心 | 应该从哪里开始阅读 | `docs/README.md` |
| Guide | 如何完成一个具体操作 | `docs/guides/` |
| Reference | 当前接口和行为是什么 | `docs/reference/` |
| Concept | 模块如何协作，为什么这样设计 | `docs/concepts/` |
| Roadmap | 当前阶段、优先级和顺序 | `docs/roadmap.md` |
| Plan | 某项能力如何实现和验收 | `docs/plans/` |
| ADR | 为什么选择某个方案 | `docs/decisions/` |
| Record | 实际执行和验证结果是什么 | `docs/records/` |

## 推荐目录

```text
README.md
DOCUMENTATION_GUIDE.md
docs/
├─ README.md
├─ guides/
├─ reference/
├─ concepts/
├─ plans/
├─ decisions/
└─ records/
```

目录可以渐进创建，不为了匹配结构进行无价值的大规模移动。

## 链接规则

- 文档之间使用相对链接。
- `docs/README.md` 是分类索引和推荐阅读入口。
- 根 README 只保留快速开始和文档中心链接，不维护完整文档索引。
- Plan 可以链接 Concept、Guide 和 ADR，但不应依赖 Record 才能理解计划目标。
- 移动文件时必须检查入链和出链。

## 修改范围

| 变化 | 通常修改 |
|---|---|
| 构建或运行流程变化 | 对应 Guide |
| 架构边界变化 | ADR，并更新 Concept 摘要 |
| skyuv 迁移方案变化 | 对应 Plan |
| 测试或迁移结果 | Record |
| 项目定位或快速开始变化 | 根 README |

## Plan 模板

```markdown
# 任务编号：标题

## 状态
## 背景与目标
## 非目标
## 已确认决策
## 实施顺序
## 测试与验收
## 风险与未决问题
```

## 内容要求

- 先写结论、用途或当前状态，再写细节。
- 使用项目当前真实的命令、路径和接口；草案命令必须明确标注。
- 连续步骤使用编号列表，并给出可验证结果。
- 长文档超过约 300 行时，检查是否混合了多个文档职责。
- 新文档必须加入 `docs/README.md`。

## 提交检查

- 是否只有一个主要职责？
- 是否清楚区分当前实现、未来计划和历史记录？
- 是否重复维护了另一份文档中的事实？
- 相对链接和命令是否有效？
- 内容是否与当前仓库代码一致？

## 当前项目映射

- `README.md`：项目定位、旧版 Skynet 快速开始和客户端示例。
- `docs/README.md`：文档总入口。
- `docs/concepts/architecture.md`：当前服务、网络和构建边界。
- `docs/guides/skyuv-migration.md`：skyuv 迁移操作边界和检查项。
- `docs/plans/001-skyuv-migration.md`：skyuv 迁移的实施计划和验收标准。
- `docs/records/`：迁移执行日志、测试结果和性能数据；完成迁移后再创建具体记录。
