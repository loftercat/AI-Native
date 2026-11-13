---
name: test-spec-alignment
description: >-
  在编码前把 Story + 详设 §9 转化为用例级测试规格 TS（AC→用例追溯、分层测试矩阵、
  Fixture 设计、前端-only 标注、缺口阻断），并校验 AC 是否都有测试覆盖计划。
  用于测试规格设计、TS 编写、AC 对齐、测试用例拆分、Mock 边界梳理、feature-coding 前置等场景。
---

> **模板版说明**：本 Skill 自已落地的源项目抽取为通用模板。文中项目专属值（模块名 `booking-*`、包名 `com.hema`、错误码号段、具体路径与 Story 号）均为**示例**，接入项目时按 [MIGRATION.md](../../../MIGRATION.md) 清单替换；「本仓库」指接入后的目标项目。


# 测试规格对齐（Story + 详设 → TS）

以 Story 需求卡 + 详设（§9 测试策略）为输入，**在写任何 Java 测试代码之前**产出用例级测试规格
`TS-STORY-*.md`，供 `feature-coding` / `integration-test-design` 与 QA 共享同一契约。

本 Skill 对齐 [test-line.md](../../docs/methodology/test-line.md) §5 的设计，是其落地执行器。

## 定位与边界

- **做什么**：把「要测什么、怎么测、测哪一层」从 Story + 详设拆出来，落盘 TS；校验 AC 覆盖；标缺口与阻断
- **不做**：写 Java 测试代码或业务实现（那是 `feature-coding` / `integration-test-design`）
- **不做**：改 Story / 详设正文（缺断言文案或错误码 → 标阻断回溯，不静默改卡）
- **不做**：存量测试审计、Bug 单处理（无 `test-quality-audit` / `bug-fix` Skill）
- **不做**：改 Rule、`docs/*/_golden/` 既有范本（新 Golden 需确认）

## 输入方式

- **必备**：Story 需求卡（`@` 或按编号自动查找 `docs/requirements/{迭代}/STORY-*.md`）
- **必备**：详设 `DD-STORY-{迭代}-{序号}-*.md`（§9 测试策略；缺失则按 §6 阻断降级）
- **强烈推荐**：OpenAPI（`docs/api/{服务标识}/openapi.yaml`，校验错误码）
- **可选**：指定 AC 子集；`@` 模板、Golden、词表

### 触发示例

```text
/test-spec-alignment 生成 STORY-2026-S01-001 的测试规格
@docs/requirements/2026-S01/STORY-2026-S01-001-query-allocate-space.md
@docs/design/_golden/DD-STORY-GOLDEN-001-*.md
```

---

## 流程

### 步骤 1：加载上下文资产

按顺序读取（Selection：只加载当前 Story 相关部分）：

1. `templates/ts-template.md`（**缺失则阻断**）
2. `references/ac-to-case-guide.md`（**缺失则阻断**）
3. Golden 范本 `docs/test-spec/_golden/TS-STORY-GOLDEN-001-query-allocate-space.md`（**缺失则降级**，照模板结构自拟）
4. Story 需求卡 + 详设 + OpenAPI（用户 `@` 或自动查找）
5. 显式读取 Rule：`rules/story-ac-conventions.md`、`rules/integration-test-conventions.md`、`rules/mybatis-conventions.md`（含 Mapper 层时）
6. `../feature-coding/references/test-quality.md`（分层 Mock 边界）

### 步骤 2：核对输入

- 无 Story → **阻断**，提示提供需求卡。
- 无详设或详设缺 §9 → **阻断并降级**：提示「缺详设 §9，无法确定测试层级与类归属」；如用户坚持生成，按 `ac-to-case-guide.md` §2 归属表自拟并全部标 `[AI推断]` 入 §6。
- Story 失败 AC 缺具体文案 或 详设错误码与 OpenAPI 不一致 → 记录进 TS §6 阻断项，不猜。

### 步骤 3：展开 AC → 用例追溯表（TS §2）

对每条 AC（含成功与失败）按 `ac-to-case-guide.md` §2 落层：

- 行字段：`测试类#方法`、层、成败、断言（`code`/`message`/关键字段）、备注（关联 BR）
- 失败 AC 断言文案：Story `Then` 优先，其次详设错误码表
- 一条 AC 可多行（跨层），成功/失败分行

### 步骤 4：填分层测试矩阵（TS §3）

- 以详设 §9 测试类清单为骨架，补 Mock 什么 / 不 Mock 什么
- 对齐 `test-quality.md`：单元 Mock 依赖、BFF API `@WebMvcTest` Mock 域（无 DB）、Mapper 走真实 H2、集成（可选）归 `integration-test-design`

### 步骤 5：Fixture / 种子数据设计（TS §4）

- 每个场景给 `输入 → Mock/种子返回 → 边界值`
- 必查边界见 `ac-to-case-guide.md` §4（空串 vs null、恰好阈值、等距、跨日、空配置）

### 步骤 6：前端-only / N/A 标注（TS §5）

- Story §2.2「前端另仓」、纯 UI 展示、无法后端单独验收的 AC → 标 `前端-only` / `N/A` + 原因
- 防止 `feature-coding` 误写 Java 测试

### 步骤 7：缺口与阻断项（TS §6）

逐项检查后汇总：

| 类别 | 处置 |
|------|------|
| AC 无对应测试计划 | 补用例或标 N/A |
| 详设 §9 与 OpenAPI 错误码不一致 | 标阻断，回溯 `detail-design` |
| 失败 AC 缺具体断言文案 | 标阻断，补 Story |
| 无详设 §9 降级生成 | 全部测试类标 `[AI推断]`，阻断解除前不得进 `feature-coding` |

### 步骤 8：落盘

- 路径：`docs/test-spec/{迭代}/TS-STORY-{迭代}-{序号}-{slug}.md`（迭代取 `config/current-sprint`）
- 命名见 `rules/card-naming-conventions.md`；**不静默覆盖**已存在文件（有则先读差异再确认）
- 使用模板结构，删除模板说明块

### 步骤 9：送审与产出汇总

- **送审**：按 [rules/artifact-review.md](../../rules/artifact-review.md) §二 的 TS 三项必查派独立审查人，报告落 `docs/reviews/{迭代}/REVIEW-TS-{slug}.md`；通过后状态改「已确认」
- TS 落盘路径 + AC 覆盖统计（N 条 AC → N 行映射）
- 缺口与阻断项清单
- 下游提示：`feature-coding` 以本 TS 为用例来源；含集成层用例时提示 `integration-test-design`

---

## 边界（再次强调）

- **只产出 TS 文档**，不写 Java、不改 Story/详设、不做存量审计
- TS 是研发与 QA 的**共同契约**，二者都以需求卡为源头，本 Skill 只负责对齐
- 需求小变更：先增量更新 TS（变更记录），再让 `feature-coding` 按变更改测改实现

## 延伸阅读

- [test-line.md](../../docs/methodology/test-line.md) §5（设计源头）
- [ts-template.md](templates/ts-template.md)
- [ac-to-case-guide.md](references/ac-to-case-guide.md)
- [docs/test-spec/_golden/TS-STORY-GOLDEN-001-query-allocate-space.md](../../docs/test-spec/_golden/TS-STORY-GOLDEN-001-query-allocate-space.md)
