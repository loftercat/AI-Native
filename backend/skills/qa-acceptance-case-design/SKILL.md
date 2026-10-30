---
name: qa-acceptance-case-design
description: >-
  从 Story + OpenAPI 产出给人执行的验收用例（GWT），按筛选漏斗标注 execution 与 suite，
  并对照 TS 去重。用于验收用例设计、提测清单、UAT、冒烟/回归选集等场景。
---

> **模板版说明**：本 Skill 自已落地的源项目抽取为通用模板。文中项目专属值（模块名 `booking-*`、包名 `com.hema`、错误码号段、具体路径与 Story 号）均为**示例**，接入项目时按 [MIGRATION.md](../../../MIGRATION.md) 清单替换；「本仓库」指接入后的目标项目。


# 验收用例设计（Story + OpenAPI → 验收清单 GWT）

以 Story 需求卡（AC/BR）+ OpenAPI 为**硬依赖**，产出**给人执行**的验收用例（用户可见 GWT），
按筛选漏斗标注 `execution` 与 `suite`，并对照研发 TS **对齐参考、去重**，避免与 PR 白盒重复设计。

本 Skill 对齐 [test-line.md](../../docs/methodology/test-line.md) §4.2~§4.3，是 QA 专线最上游落地项。
**产出为 Skill 资产 + 模板 + Golden**，**不强制**批量写入外部用例系统（禅道/Jira/Xray 等）API；**不含** pytest 黑盒脚本（归 `api-blackbox-test`）。

## 定位与边界

- **做什么**：从 Story AC/BR + OpenAPI 产出验收用例 Given-When-Then（GWT）+ 追溯表；标 `execution` / `suite` / `blackbox_rationale`（含义见下节「字段与枚举定义」）；与 TS 对齐去重
- **不做**：写 pytest/Java 测试代码（归 `api-blackbox-test` / `feature-coding`）
- **不做**：替代 TS（验收用例**不以** TS 为主输入；TS 仅**对齐参考**，硬依赖仍为 Story + OpenAPI）
- **不做**：实现外部用例系统（禅道/Jira 等）API 自动回写（可文档化「链接型用例」规范；集成另 Story）
- **不做**：落地 `test-data-design` / `e2e-test` / `performance-test` / `regression-guard`
- **不做**：改 Story / 详设 / OpenAPI / TS / Rule 正文（边界同 `story-splitting` / `detail-design`）
- **不做**：为每个 AC 在外部用例系统复制 TS 全文（避免双维护正文）

## 字段与枚举定义

> 权威语义与 STORY-2026-S01-090（源项目 QA Skill 需求卡）§3.1 一致。`status`（TC 生命周期）见追溯表模板，与 `execution` **分两维度**（BR-07）。

### `execution`（单条用例怎么验收）

| 值 | 含义 | 典型场景 |
|----|------|----------|
| `manual` | **人工执行** | 需人工点击、查看 UI、现场联调说明等；不宜或无法由 CI/黑盒替代，仍须展开 GWT |
| `ci_covered` | **CI 已覆盖** | TS 对该 AC 标单元/BFF/IT 全覆盖，**且**无部署态独有验证点（BR-05）；Then 写「以 MR 流水线 `mvn test` 通过为准」，**不**再写等价 pytest 步骤 |
| `blackbox` | **部署后黑盒要跑** | 真实 HTTP/网关/Filter、跨进程串联、真实第三方、UAT 主路径、历史缺陷路径等；下游 `api-blackbox-test` 消费 |
| `frontend_only` | **前端另仓验收** | Story/TS 标前端-only；后端不写黑盒脚本，前端仓 `e2e-test` 消费 |
| `obsolete` | **已废弃** | AC 废弃或合并；保留追溯，不再执行 |

### `suite`（黑盒归入哪一批；非 blackbox 时多为 `N/A`）

| 值 | 含义 |
|----|------|
| `smoke` | **冒烟集**：迭代级约 5～15 条（各域 P0 主路径 + 横切 health/未授权探测，单条 &lt;2 min）；提测/发版优先跑 |
| `regression` | **回归集**：其余黑盒候选，按**本次变更影响面**选子集，非每次全量 |
| `N/A` | **不适用**：`ci_covered` / `manual` / `frontend_only` 等不走黑盒冒烟/回归选集 |

### `blackbox_rationale`（黑盒入选理由）

- **类型**：自由文本（非枚举）。
- **何时必填**：仅当 `execution=blackbox`。
- **写什么**：说明为何白盒/CI 不够、必须部署态验证（如「真实 App Filter + 鉴权，部署态独有」「用户可见主路径 UAT 粗断言」）。

## 何时触发

- 提测前 / UAT 前；Story + OpenAPI 齐备时
- TS 落地后作**对齐参考**（非硬依赖）；TS 未落盘可降级为仅 Story + OpenAPI
- 需求变更时：先增量更新验收清单（变更记录），废弃 AC 标 `obsolete`

## 前置加载（按序点名）

| # | 资产 | 路径 | 缺失时 |
|---|------|------|--------|
| 1 | 验收用例模板 | `templates/acceptance-case-template.md` | **阻断** |
| 2 | Story→验收映射指引 | `references/story-to-acceptance-guide.md` | **阻断** |
| 3 | 提测追溯表模板 | `templates/tc-traceability-template.csv` | **阻断** |
| 4 | Golden 范本 | `docs/qa/_golden/AC-STORY-GOLDEN-001-*.md` | 降级 |
| 5 | Story 需求卡 | `docs/requirements/{迭代}/STORY-{迭代}-{序号}-*.md`（按 Story 号自动查找） | 阻断见步骤 2 |
| 6 | 详设 DD（OpenAPI 来源） | `docs/design/{迭代}/DD-STORY-{迭代}-{序号}-*.md`（按 Story 号自动查找） | 阻断见步骤 2 |
| 7 | OpenAPI | 从 DD 解析（`docs/api/{服务标识}/openapi.yaml`，可多个） | 阻断见步骤 2 |
| 8 | 测试规格 TS（可选只读对齐） | `docs/test-spec/{迭代}/TS-STORY-*.md` | 跳过 |
| 9 | 测试线设计 + 黑盒判定 | `docs/methodology/test-line.md` §4.2~§4.3、`docs/training/blackbox-test-case-selection.marp.md` §3 | 降级 |
| 10 | 系统画像 | `architecture/system-landscape.md` | 降级 |
| 11 | 词表 | `glossary/domain-glossary.md` | 降级 |
| 12 | 迭代 | `config/current-sprint`（Story 路径推断优先） | — |

> **缺失阻断提示**：「缺验收用例模板/指引，无法确定 GWT 字段与黑盒判定」

## 输入

- **必备**：Story 编号（`STORY-{迭代}-{序号}`）；按编号自动查找 Story + DD，OpenAPI 路径从 DD 解析
- **可选**：TS（只读对齐参考）、原型 HTML/图片、词表、存量外部 TC ID（任意 TMS）；显式 `@` Story / DD / OpenAPI 可覆盖自动查找结果

### 触发示例

```text
/qa-acceptance-case-design STORY-2026-S01-001

增量：为 STORY-xxx 补 execution=blackbox 行的 blackbox_rationale
```

## 输出

- `docs/qa/{迭代}/AC-STORY-{迭代}-{序号}-{slug}.md`（验收清单，GWT + 追溯 + 冒烟集）
- 追溯表 CSV：`docs/qa/{迭代}/tc-traceability-{Story编号}.csv`（结构对照 `templates/tc-traceability-template.csv`）
- **不产生** Java/pytest 代码；**不改** Story/详设/OpenAPI/TS/Rule

## 标准流程

### 步骤 1：加载资产清单

按 §「前置加载」点名；模板/指引/CSV 缺失 → **阻断**，输出「缺验收用例模板/指引…」。

### 步骤 2：核对输入

- 按 Story 编号 `STORY-{迭代}-{序号}` 自动查找 Story 与 DD：
  - Story：`docs/requirements/{迭代}/STORY-{迭代}-{序号}-*.md`
  - DD：`docs/design/{迭代}/DD-STORY-{迭代}-{序号}-*.md`
- 无 Story → **阻断**，提示提供需求卡
- 无 DD → **阻断**（AC-08），message 含「未找到 DD-STORY-{迭代}-{序号}-*.md，请先跑 `/detail-design` 产出详设」
- 有 DD → 解析其中 OpenAPI 路径（`docs/api/{服务标识}/openapi.yaml`，从「服务标识」字段或正文 OpenAPI 章节提取，可多个）并加载
- DD 未引用 OpenAPI → **阻断**（AC-08），message 含「DD 未引用 OpenAPI，请回 `/detail-design` 补全 §OpenAPI 章节」
- DD 引用的 OpenAPI 文件不存在 → **阻断**（AC-08），message 含「DD 引用的 `docs/api/{服务标识}/openapi.yaml` 不存在，请先落盘 OpenAPI」
- **HTTP Story 无 OpenAPI**（DD 无引用且文件缺失）→ **阻断**（AC-08），不输出伪造 URL 用例
- 非 HTTP Story（如域内 Job）→ 允许纯 manual 验收表，阻断 HTTP 黑盒引用
- Story 失败 AC 缺具体文案 → 记录进验收清单 §8「缺口与阻断项」，不猜

### 步骤 3：展开 AC → 验收用例追溯（清单 §2）

- 每条 AC（含成功与失败）至少一行；无映射 → **缺口阻断**（BR-03）
- 优先级 P0/P1/P2 默认继承 Story/项目约定；**不擅自降级 P0**；缺失 → AskQuestion（BR-08）
- 行字段：`AC` / `验收用例 ID` / `priority` / `execution` / `suite` / `blackbox_rationale` / `备注`

### 步骤 4：标 execution（按漏斗 + 黑盒判定 + ci_covered 双条件）

按 [story-to-acceptance-guide.md](references/story-to-acceptance-guide.md)：

1. **筛选漏斗**（§1）：全量候选 → 剔除白盒已细测 → 黑盒候选 → 冒烟 5~15 → 回归按影响面
2. **黑盒候选判定**（§2，照搬 marp §3 共 7 类场景）：其中 **2 类不进黑盒**（白盒已覆盖：参数校验/鉴权/状态机/事务/DB 断言/单字段映射/业务计算 + 仅 Mock 第三方超时异常），**5 类方可标 `blackbox`**（真实 HTTP/跨进程串联/真实第三方联调/用户可见主路径/历史缺陷）
3. **ci_covered 双条件**（§3，BR-05）：① TS 矩阵对该 AC 标单元/BFF/IT 全覆盖 **且** ② 该 AC 无部署态独有验证点；仅 ① 不满足 ② → `blackbox`
4. **反例**：BFF 测参数校验 ≠ 黑盒无部署态增量（真实 iam 鉴权、网关 Filter、TLS 是部署态独有）

`execution` 枚举：`manual` / `ci_covered` / `blackbox` / `frontend_only` / `obsolete`
`suite` 枚举：`smoke` / `regression` / `N/A`（非 blackbox 时）

### 步骤 5：写 GWT（清单 §3，用户可见断言）

- **Given/When/Then**：Then 不断言 Mapper 内部状态或 Mock 边界；允许 `code=200`、列表字段可见、业务失败 `message` 与 Story 一致（AC-04）
- **失败 AC Then 必须含 Story 具体文案**（如「无可预约的车位」「车场不存在」），禁止「提示错误」（AC-03）
- `execution=ci_covered` 行 Then 写「以 MR 流水线 `mvn test` 通过为准」+ Pipeline 引用占位，**不生成等价 pytest 步骤**（BR-05）
- `manual` / `frontend_only` 的 AC，以及 TS 矩阵中标 `N/A` 的 AC，须**展开 GWT**（含失败类用户可见文案，与 Story AC 一致）（BR-06）
- `blackbox` 行必填 `blackbox_rationale`

### 步骤 6：分层 smoke / regression（清单 §7）

- **冒烟集**（`suite=smoke`）= 各核心业务域 1 条 P0 主路径 + 横切（≥1 健康检查 `/actuator/health` + 各 BFF 未授权拦截探测 Admin/App 各 ≤1）+ 每条 <2 min，规模 **5~15 条**（AC-12/BR-11）
  - **单 Story 贡献**：本 Story 标 `smoke` 的条数（通常 1~3 条主路径 + 横切探测）并入**既有迭代 smoke 集**；单 Story 不必填满 5~15，合并后总数须在 5~15
  - **横切探测**（health / 未授权拦截）属迭代级共享，不重复为每个 Story 新增；首次落地 Story 负责建立，后续 Story 维护
- **回归集**（`suite=regression`）= 其余黑盒候选，**按本次变更影响面选集**（可数十~数百，非每次全量）

### 步骤 7：与 TS 对齐去重（清单 §5）

- TS 覆盖矩阵**只读引用**（不复制正文）；`ci_covered` 判定结果写入清单 §5
- 前端-only / N/A 标注：Story §2.2 或 TS 标前端另仓 → `execution=frontend_only` 或 `manual`，`suite=N/A`（AC-07）
- **禁止与 TS 双份长期维护相同步骤**（BR-04）：外部用例系统正文以 Git 生成 GWT 为草稿，字段链接至 `STORY-*` / `TS-*` / MR Pipeline

### 步骤 8：回归库可追溯检查（清单 §6）

- 回归库每条须可追溯 `Story / OpenAPI operation / 矩阵行`（AC-13/BR-12）
- 无 Story 的遗留 TC 标 `legacy_tc_id`，`status` 取 `automated` / `manual` / `merged` / `obsolete`
- **不允许**无追溯的「孤儿回归用例」；下次触达补 Story 或标 `obsolete`
- `status`（TC 生命周期）与 `execution`（单条怎么跑）**分两维度**，模板分别标注（BR-07）

### 步骤 9：落盘 + 产出汇总

- 路径：`docs/qa/{迭代}/AC-STORY-{迭代}-{序号}-{slug}.md`（迭代取 Story 目录名 > `config/current-sprint`）
- 命名见 [card-naming-conventions.md](../../rules/card-naming-conventions.md)；**不静默覆盖**已存在文件
- 追溯表 CSV 行同步落盘
- 产出汇总（对话输出，默认不落盘）：

```markdown
## 验收清单汇总 — {Story编号}
### 1. 产出文件清单
### 2. AC → 验收用例映射表（含 execution/suite）
### 3. 冒烟集条数与构成（5~15 + 横切）
### 4. ci_covered 判定结果（双条件）
### 5. 与 TS 去重对齐说明
### 6. 回归库追溯状态（legacy_tc_id / obsolete）
### 7. [AI推断] 清单
### 8. 阻断问题清单（若有）
### 9. 建议后续 → api-blackbox-test（消费 execution=blackbox 行）
```

## 降级策略

| 缺失资产 | 处理 | 严重度 |
|----------|------|--------|
| `acceptance-case-template.md` / `story-to-acceptance-guide.md` / `tc-traceability-template.csv` | **阻断**，输出「缺验收用例模板/指引…」 | 致命 |
| Story 需求卡 | **阻断**，提示提供需求卡 | 致命 |
| OpenAPI（HTTP Story） | **阻断**（AC-08），输出「缺 OpenAPI，无法确定验收接口与字段」 | 致命 |
| Golden 范本 | 降级，照模板结构自拟并标 `[AI推断]` | 中 |
| TS（只读对齐） | 跳过；`ci_covered` 判定降级为仅 Story+OpenAPI 推断，标 `[AI推断]` | 中 |
| `docs/methodology/test-line.md` / marp §3 | 降级，黑盒候选判定按通用知识 + `[AI推断]` | 中 |
| 系统画像 / 词表 | 跳过，汇总提示 | 低 |

> **落盘路径约束**：`docs/qa/_golden/` 仅存 Golden 范本，**禁止**向其写入真实 Story 产出；真实迭代产出落 `docs/qa/{迭代}/`。

## 边界（再次强调）

- **只产出**验收清单 + 追溯表 CSV，**不写** Java/pytest、**不改** Story/详设/OpenAPI/TS/Rule
- 验收用例 ≠ TS：二者**平行、同源 Story**；TS 是对齐参考，非输入真源
- **不实现**外部用例系统 API 回写；仅文档化「链接型用例」规范（BR-04）
- **不擅自降级 P0**；缺失优先级 → AskQuestion（BR-08）
- **下游衔接**：
  - `api-blackbox-test` 消费 `execution=blackbox` 行（按 `suite` 跑 smoke/regression）；本 Skill **不编写** pytest、**不执行**黑盒
  - 前端仓 `e2e-test` 消费 `execution=frontend_only` 行
- 需求小变更：先增量更新验收清单（变更记录），废弃 AC 标 `obsolete`

## 延伸阅读

- [test-line.md](../../docs/methodology/test-line.md) §4.2~§4.3（设计源头）
- [blackbox-test-case-selection.marp.md](../../docs/training/blackbox-test-case-selection.marp.md) §3（黑盒候选判定）
- [acceptance-case-template.md](templates/acceptance-case-template.md)
- [story-to-acceptance-guide.md](references/story-to-acceptance-guide.md)
- [tc-traceability-template.csv](templates/tc-traceability-template.csv)
- [docs/qa/_golden/AC-STORY-GOLDEN-001-query-allocate-space.md](../../docs/qa/_golden/AC-STORY-GOLDEN-001-query-allocate-space.md)
