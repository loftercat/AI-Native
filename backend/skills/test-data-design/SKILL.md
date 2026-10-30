---
name: test-data-design
description: >-
  从 090 产出的 AC-STORY-*.md 中 Given + OpenAPI 生成数据画像（DP）+ 造数/清理脚本，
  为 api-blackbox-test 的 execution=blackbox 行提供环境级前置数据。
  用于部署环境造数、提测前置数据准备、黑盒 pytest 数据依赖等场景。
---

> **模板版说明**：本 Skill 自已落地的源项目抽取为通用模板。文中项目专属值（模块名 `booking-*`、包名 `com.hema`、错误码号段、具体路径与 Story 号）均为**示例**，接入项目时按 [MIGRATION.md](../../../MIGRATION.md) 清单替换；「本仓库」指接入后的目标项目。


# 测试数据设计（AC Given → 数据画像 + 造数/清理脚本）

以 090 产出 `AC-STORY-*.md` 中 **Given** + OpenAPI 为输入，生成 **数据画像（DP）+ 造数/清理脚本**，为 `api-blackbox-test` 的 `execution=blackbox` 行提供**环境级前置数据**。

本 Skill 对齐 [test-line.md](../../docs/methodology/test-line.md) §4.2、§150，是 QA 专线部署环境造数层。
**产出为 DP + seed 脚本**，**不写** Java 测试、**不改** Story/TS/OpenAPI、**不直连** DB 执行（首版 SQL/文档）。

## 定位与边界

- **做什么**：从 blackbox 行 Given + OpenAPI 生成 DP（YAML）+ seed 脚本（Python，生成 SQL 文本）；标 `seed_key` 幂等可重跑
- **不做**：写 Java 测试（归 `feature-coding` / `integration-test-design`）
- **不做**：进程内 `@Sql`/`TestDataFactory`（归 `integration-test-design`，MR 进程内）
- **不做**：直连 DB 执行造数（首版生成 SQL 文本，执行由运维/CI）
- **不做**：Admin API 造数通道（后续 Story）
- **不做**：改 Story/TS/OpenAPI/Rule 正文
- **不做**：定义 GitLab CI job（仅 README 描述衔接；CI 另 Story）
- **不做**：接生产 DB；仅测试/预发环境
- **不做**：性能压测数据规模（归 `performance-test`）

## 何时触发

- `api-blackbox-test` 产出 `execution=blackbox` 行后，pytest 需要环境数据时
- 提测前/发版前，测试环境需要前置数据时
- 需求变更时：先增量更新 DP + seed，废弃 AC 标 `obsolete`

## 前置加载（按序点名）

| # | 资产 | 路径 | 缺失时 |
|---|------|------|--------|
| 1 | 数据画像模板 | `templates/data-profile-template.md` | **阻断** |
| 2 | 造数通道指引 | `references/seed-channel-guide.md` | **阻断** |
| 3 | 清理约定 | `references/cleanup-conventions.md` | **阻断** |
| 4 | blackbox 衔接指引 | `references/blackbox-integration-guide.md` | **阻断** |
| 4.5 | 身份与权限对齐指引 | `references/identity-and-permission-guide.md` | 降级（AC 涉及权限时建议读） |
| 5 | Golden DP 范本 | `docs/qa/data-profiles/_golden/DP-STORY-GOLDEN-*.yaml` | 降级 |
| 6 | 验收清单（090 产出） | `docs/qa/{迭代}/AC-STORY-{迭代}-{序号}-*.md` | 阻断见步骤 2 |
| 7 | OpenAPI | 从 AC-STORY「来源」字段解析 | 阻断见步骤 2 |
| 8 | 业务表 DDL | `docs/schema/{服务}/ddl/*.sql` | 降级（字段名核对） |
| 9 | 系统画像（含 §4.3.4 测试账号约定） | `architecture/system-landscape.md` | 降级（字段名核对）；**AC 涉及权限时 §4.3.4 阻断** |
| 10 | 迭代 | `config/current-sprint` | — |

> **缺失阻断提示**：「缺数据画像模板/造数指引，无法确定 DP 字段与 seed 脚本结构」

## 输入

- **必备**：Story 编号（`STORY-{迭代}-{序号}`）；按编号自动查找 `AC-STORY-{迭代}-{序号}-*.md`，OpenAPI 路径从其「来源」字段解析
- **可选**：TS §4 Fixture（语义对齐）、业务表 DDL（字段名核对）

### 触发示例

```text
/test-data-design STORY-2026-S02-007

增量：为 STORY-xxx 补 regression-charger 画像
```

## 输出

- `docs/qa/data-profiles/{迭代}/DP-STORY-{迭代}-{序号}-{slug}.yaml`（数据画像）
- `tests/data/seed_{迭代}_{序号}_{slug}.py`（造数/清理脚本，生成 SQL 文本）
- `tests/data/README.md`（本地/CI 如何跑；与 blackbox 衔接）
- **不产生** Java 代码；**不改** Story/TS/OpenAPI/Rule

## 标准流程

### 步骤 1：加载资产清单

按 §「前置加载」点名；模板/指引缺失 → **阻断**，输出「缺数据画像模板/造数指引…」。

### 步骤 2：核对输入

- 按 Story 编号在 `docs/qa/{迭代}/` 下 glob `AC-STORY-{迭代}-{序号}-*.md` 自动加载
- 无 `AC-STORY-*.md` → **阻断**，提示提供 090 产出
- 解析 AC-STORY「来源」字段取 OpenAPI 路径并加载
- **只处理 `execution=blackbox` 行**的 Given；`ci_covered`/`manual`/`frontend_only`/`obsolete` 行 **跳过**（不造数）
- 读业务表 DDL 核对字段名（如 `support_charge` 非 `has_charger`；`project.latitude/longitude` 非 `parking_lot`）

### 步骤 3：展开 AC Given → 数据画像（DP）

- 一个 AC（或一组同接口 AC）一个 `profile`；profile 间共享实体用 `extends` 引用（BR-5）
- 每个 `profile` 含：`profile_id` / `ac_ids` / `entities`（表、字段、状态、`seed_key`）/ `cleanup_order` / `env_vars`
- **不造数**的 AC（如 AC-2 无匹配、AC-7 空关键字）标 `smoke-empty` profile，仅校验 skip 行为
- 字段名严格按 DDL；不确定时查 `docs/schema/{服务}/ddl/*.sql`
- **身份列按测试账号约定表写**：若 AC 涉及数据权限（scope / 创建人 / 车主本人），seed 里的 `partner_id`/`created_by`/`owner_id` 等身份列按 [system-landscape §4.3.4](../../architecture/system-landscape.md#434-测试账号约定供-test-data-design-skill-消费) 测试账号约定表写死，**不在 DP 里展开 identity 契约**
- **功能权限不靠造数**：403 / 权限码类 AC 不改 seed；黑盒挑对应 Token（如 `ADMIN_TOKEN_DENIED`）
- 详见 [identity-and-permission-guide.md](references/identity-and-permission-guide.md)

### 步骤 4：生成 seed 脚本

- 每个画像 → `generate_sql(profile_id)` + `generate_cleanup_sql(profile_id)`
- 幂等：`DELETE WHERE seed_key=?` + `INSERT` 带 `seed_key`（BR-3）
- 清理：按 `cleanup_order` 反序 `DELETE WHERE seed_key=?`（BR-4）
- `seed_key` 命名：`{迭代缩写}-{Story序号}-{profile_id}`（如 `s02-007-smoke-main`），一 profile 一 key，**不**嵌 AC 编号；详见 [seed-channel-guide §2.4](references/seed-channel-guide.md#24-seed_key-命名约定br-04)
- 入口校验 `SEED_DB_URL`：缺失 → `sys.exit(0)` + 提示（AC-05 skip 非 fail）
- **不嵌入 DB 驱动**：仅 `print(sql)` 输出文本；执行由运维/CI 重定向

### 步骤 5：与 blackbox 衔接

- DP 的 `env_vars` 节定义 blackbox pytest 读的环境变量（如 `BLACKBOX_SEARCH_KEYWORD`）
- 身份列已按 [system-landscape §4.3.4](../../architecture/system-landscape.md#434-测试账号约定供-test-data-design-skill-消费) 约定写死；黑盒按 AC 挑对应 Token 环境变量（如 `ADMIN_TOKEN_PARTNER` / `APP_TOKEN`），Token 值由运维/CI 注入
- 更新 `tests/data/README.md` 说明执行顺序：seed → blackbox → cleanup

### 步骤 6：落盘 + 产出汇总

- 路径：`docs/qa/data-profiles/{迭代}/DP-STORY-{迭代}-{序号}-{slug}.yaml` + `tests/data/seed_*.py`
- **落盘路径约束**：`docs/qa/data-profiles/_golden/` 仅存 Golden 范本（如 `DP-STORY-GOLDEN-001-*.yaml`），**禁止**向 `_golden` 写入真实迭代 Story 产出；真实 DP 落 `docs/qa/data-profiles/{迭代}/`
- 命名见 [card-naming-conventions.md](../../rules/card-naming-conventions.md)；**不静默覆盖**
- 产出汇总（对话输出，默认不落盘）：

```markdown
## 测试数据设计汇总 — {Story编号}
### 1. 产出文件清单
### 2. AC Given → 数据画像映射表
### 3. 造数/清理脚本说明
### 4. 与 blackbox 衔接的环境变量
### 5. 身份列对齐说明（引用 §4.3.4 约定；若有）
### 6. [AI推断] 清单
### 7. 阻断问题清单（若有）
### 8. 建议后续 → 运维/CI 执行 seed + 准备 Token
```

## 降级策略

| 缺失资产 | 处理 | 严重度 |
|----------|------|--------|
| 模板/指引 | **阻断**，输出「缺数据画像模板/造数指引…」 | 致命 |
| AC-STORY（090 产出） | **阻断**，提示提供 090 产出 | 致命 |
| OpenAPI | **阻断**，输出「缺 OpenAPI，无法确定实体字段」 | 致命 |
| Golden DP 范本 | 降级，照模板结构自拟并标 `[AI推断]` | 中 |
| 业务表 DDL | 降级，字段名按 OpenAPI schema 推断，标 `[AI推断]` | 中 |
| 系统画像 | 字段名核对降级；**§4.3.4 测试账号约定在 AC 涉及权限时阻断**（身份列 id 无真源） | 中 |

## 边界（再次强调）

- **只产出** DP + seed 脚本，**不写** Java、**不改** Story/TS/OpenAPI/Rule
- **不直连** DB 执行（首版 SQL 文本）；Admin API 通道后续 Story
- **不替代** `integration-test-design` 进程内造数
- **不接** 生产 DB
- **下游衔接**：
  - `api-blackbox-test` 经环境变量读 DP 约定；不在 pytest 内嵌 SQL
  - 运维/CI 执行 seed 生成的 SQL 到测试环境 DB

## 延伸阅读

- [test-line.md](../../docs/methodology/test-line.md) §4.2、§150（设计源头）
- [qa-acceptance-case-design SKILL](../qa-acceptance-case-design/SKILL.md)（上游 Given 来源）
- [api-blackbox-test SKILL](../api-blackbox-test/SKILL.md)（下游消费）
- [data-profile-template.md](templates/data-profile-template.md)
- [seed-channel-guide.md](references/seed-channel-guide.md)
- [cleanup-conventions.md](references/cleanup-conventions.md)
- [blackbox-integration-guide.md](references/blackbox-integration-guide.md)
- [identity-and-permission-guide.md](references/identity-and-permission-guide.md)
