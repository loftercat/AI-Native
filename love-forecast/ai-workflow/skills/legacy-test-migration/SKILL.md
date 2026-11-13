---
name: legacy-test-migration
description: >-
  把「只有文字用例、没有 Story/AC、没有自动化脚本」的存量测试资产，批量归一化为 GWT、
  经门禁（G1~G4）筛查后分类到白盒层（W1~W6）/黑盒桶（B1~B5），产出可审核的分类矩阵与
  遗留测试规格 TS-LEGACY，供下游生成类 Skill 消费。只做前段分类与规格，不生成测试代码。
  用于存量测试自动化改造、历史用例治理、老项目测试资产盘点等场景。
---

> **模板版说明**：本 Skill 自已落地的源项目抽取为通用模板。文中项目专属值（模块名 `booking-*`、包名 `com.loveforecast`、错误码号段、具体路径与 Story 号）均为**示例**，接入项目时按 [MIGRATION.md](../../../MIGRATION.md) 清单替换；「本仓库」指接入后的目标项目。


# legacy-test-migration Skill — 历史测试用例迁移（存量改造前段）

> 核心原则：**先归一化，再门禁，再分层；不可判定不猜；只产规格不产代码；批量分批人工确认。**
> 不靠 AI 猜断言，不强行落层，不按用例条数 1:1 补脚本。
> 设计依据：DD-STORY-2026-S01-095（源项目 legacy 迁移 Skill 设计卡）

## 定位与边界

- **做什么**：从**存量用例导出**出发，归一化 → 门禁 → 分层 → 代码锚定 → 去重 → 落盘（矩阵 + `TS-LEGACY`）
- **不做**：生成测试代码（归 `feature-coding` / `integration-test-design` / `api-blackbox-test`）
- **不做**：改用例正文（只标 `gate` / `layer` / `status` / `coverage` / `merged_into`）
- **不做**：改 Story / TS / OpenAPI / Rule 正文
- **不做**：新需求 TS（有 Story 的走 `test-spec-alignment`）；测试债扫描（归 `test-quality-audit`）
- **不做**：裁决断言对错（断言冲突标 `blocker` 并切 `bugfix`）
- **不做**：直连禅道/测试平台 API（首版输入为导出文件 `[AI推断]`）
- **不做**：前端组件测试与 E2E 的实现（前端另仓；只分类与标注）

## 何时触发

- 存量项目（无 Story/AC）测试用例批量改造，需先分类与规格
- 历史用例治理、老项目测试资产盘点
- 需要产出「P0 黑盒 / P1P2 白盒」分层清单
- **不触发**：新需求（有 Story + 详设）→ 用 `test-spec-alignment`
- **不触发**：只想体检测试质量 → 用 `test-quality-audit`

## 前置判断（动手前强制）

> **核心原则**：分类的前提是「有可读用例」与「有可锚定代码」。缺任一，先澄清再动手。

| # | 检查 | 缺失处理 |
|---|------|----------|
| 1 | 存量用例导出文件（CSV/Excel/文本）存在且可解析 | **阻断**：「未提供用例导出文件，无法开始分类，请提供 CSV/Excel」 |
| 2 | 目标模块 / 代码仓路径可知（用于锚定） | 可降级：先出归一化 + 分层建议，标 `gate=G4` |
| 3 | 目标语言 adapter（`adapters/{lang}.md`）存在 | 缺 → `gate=G4` + `blocker=缺 {lang} adapter` |
| 4 | 用例量是否 > 200 | 是 → 分批（见 Batch 规则） |

- 缺失项用 `AskQuestion` 澄清，最多 2 轮；超 2 轮仍缺 → **阻断**
- **禁止** 在无用例导出的情况下「凭模块名猜用例」

## 前置加载（按序点名）

| # | 资产 | 路径 | 缺失时 |
|---|------|------|--------|
| 1 | 归一化指引 | `references/case-normalize-guide.md` | **阻断** |
| 2 | 分类指引 | `references/classification-guide.md` | **阻断** |
| 3 | 代码锚定指引 | `references/code-anchor-guide.md` | 降级（只出分层建议） |
| 4 | 矩阵模板 | `templates/matrix-template.csv` | **阻断** |
| 5 | TS-LEGACY 模板 | `templates/ts-legacy-template.md` | **阻断** |
| 6 | 语言适配 | `references/adapters/{java,python}.md` | 降级（`gate=G4`） |

> **缺失阻断提示**：「缺分类指引/矩阵模板/TS-LEGACY 模板，无法执行存量分类」

## 输入

- **硬依赖**：存量用例导出文件（CSV/Excel/禅道导出文本）
- **可选**：目标模块名、代码仓路径、OpenAPI、`strategy`（P 级）标注
- **触发示例**：

```text
/legacy-test-migration
用例文件：docs/qa/legacy/{project}/export.csv
目标模块：order
```

## 输出

- 分类矩阵：`docs/qa/legacy/{project}/tc-classification.csv`（8 契约字段 + `title` 展示列，见下）
- 遗留测试规格：`docs/test-spec/legacy/TS-LEGACY-{module}.md`
- 待人工确认清单（`gate=G1/G2/G3/G4` 与 `layer=—` 行汇总）
- **不产生**：任何 `.java` / `.py` 测试文件；用例正文改动

## 分类模型速览

```text
一条用例
  │
  ├─ 门禁（Step 2）──→ gate ∈ {ok, G1, G2, G3, G4}
  │                      gate≠ok ⇒ layer=—（不参与路由）
  │
  └─ gate=ok
       ├─ status=merged ⇒ layer=—
       └─ status≠merged
            ├─ 部署态无增量 ⇒ W1~W6（白盒）
            └─ 部署态有增量 ⇒ B1/B3（黑盒；B2/B4/B5 按场景属性成桶）
```

| 门禁 | 含义 | status |
|------|------|--------|
| `ok` | 可分类 | `automated`（或 `merged`） |
| `G1` | 预期缺失 / 矛盾，需修订 | `needs_revision` |
| `G2` | 探索性 / 环境不可复现 | `manual` |
| `G3` | 功能已下线（**候选**，待确认） | `obsolete` |
| `G4` | 代码不可锚定 / 缺 adapter | `blocked` |

| 白盒 | 层义 | 落点 |
|------|------|------|
| W1 | 单元（单类/方法） | `*ServiceTest` → `feature-coding` |
| W2 | BFF 接口（HTTP 入口） | `*ControllerTest` → `feature-coding` |
| W3 | 集成（跨模块，真实上下文 + DB） | `*IT` → `integration-test-design` |
| W4 | 场景集成（多步骤端到端，进程内） | `*ScenarioIT` → `integration-test-design` |
| W5 | 持久层切片（Mapper SQL） | Mapper 测试 → `feature-coding` |
| W6 | 前端组件（另仓） | `frontend-feature-coding` |

| 黑盒 | 桶义 | 落点 |
|------|------|------|
| B1 | 部署态 HTTP API（网关/鉴权链/契约） | `api-blackbox-test` |
| B2 | UI 端到端 | 前端另仓 `e2e-test` |
| B3 | 真实第三方联调（IAM/支付/车场） | `api-blackbox-test` |
| B4 | 性能/压力 | `performance-test`（规划） |
| B5 | 数据批处理/定时/对账 | `integration-test-design` + `test-data-design` |

> 白/黑裁决（ADR-7，仅 W vs B1/B3）：部署态**无增量** → W；**有增量**（网关/证书/配置/外部集成/多进程）→ B1/B3。B2/B4/B5 按场景属性直接成桶。
> 分类编号（G/W/B）为本 Skill `[AI推断]`，层义对齐培训材料；详见 `classification-guide.md`。

## 标准流程（六步）

### 步骤总览

| Step | 名称 | 输入 | 输出 | 失败回退 |
|------|------|------|------|----------|
| 0 | 前置判断 + 分批 | 用例导出 + 模块 | 可行性结论 + 批次 | 无用例导出 → 阻断 |
| 1 | 归一化 | 原始用例行 | GWT 记录 | 缺预期 → `G1` |
| 2 | 门禁 | GWT 记录 | `gate` + `status` | 不可锚定 → `G4` |
| 3 | 分层 | `gate=ok` 记录 | `layer` + `strategy` | 归属不清 → `layer=—` + 待确认 |
| 4 | 代码锚定 | 分层记录 + 代码仓 | `coverage` + `blocker` | 断言冲突 → `blocker` + 切 `bugfix` |
| 5 | 去重 | 全部记录 | `merged` / `merged_into` | 等价性存疑 → 保留 + 待确认 |
| 6 | 落盘 | 全部记录 | 矩阵 + TS-LEGACY | 超批未确认 → 停止 |

### Step 0：前置判断 + 分批

1. 校验用例导出存在且可解析（否则阻断）。
2. 记录目标模块 / 代码仓 / 语言（用于 adapter）。
3. **Batch 规则**：单批 ≤ 200 条 `[AI推断]`；超限切批，逐批跑 Step 1~6，每批停下等人工确认（AC-08）。

### Step 1：归一化（`case-normalize-guide.md`）

1. 结构映射：前置条件 → Given；操作步骤 → When；预期结果 → Then（多条预期拆为多个可判定 Then）。
2. 保留 `legacy_tc_id` 与原文摘要；**不改用例正文**。
3. 缺失字段（无预期 / 预期矛盾 / 无前置）→ 标 `gate=G1` + `blocker` 记缺失字段，**不猜断言**（BR-03）。
4. 数据依赖 → 记入 Given，供下游 `test-data-design`。

### Step 2：门禁（`classification-guide.md` §2）

判定顺序（首个命中即停；顺序为 `[AI推断]`，tie-break 按 G3→G1→G4→G2）：

1. **G3**：功能已下线**且有证据**（代码删除/接口下线/产品确认）→ `gate=G3`、`status=obsolete`（**候选**，BR-12）
2. **G1**：预期缺失或矛盾 → `gate=G1`、`status=needs_revision`
3. **G4**：代码不可访问 / 缺 adapter / 无法锚定 → `gate=G4`、`status=blocked`、`blocker=代码不可锚定`
4. **G2**：探索性 / 环境不可复现 / 无后端稳定断言点 → `gate=G2`、`status=manual`
5. 否则 `gate=ok`（`status=automated`；合并行 `status=merged`）

> `gate≠ok` ⟹ `layer=—`，不进 Step 3。

### Step 3：分层（`classification-guide.md` §3）

1. 对 `gate=ok` 且 `status≠merged` 的行，按 W 层 / B 层判定表落层。
2. 白/黑裁决：部署态**无增量** → W；**有增量** → B1/B3；B2/B4/B5 按场景属性直接成桶。
3. 归属不清 → `layer=—` + `待人工确认` + 记候选层与理由（BR-04），**不强行落层**。
4. 标 `strategy`（`smoke`/`regression`/`contract`/`perf`/`uat`/`—`）。

### Step 4：代码锚定（`code-anchor-guide.md`）

1. 提取业务对象/动作 → 顺序锚定：OpenAPI `operationId`/路径 → Controller 方法 → Api/DTO 字段 → 错误码 → DDL 表名 → Service 方法。
2. `coverage` 填目标方法名或脚本路径占位；锚不到 → 记 `blocker`（**不猜**）。
3. 断言与现网/契约不符 → `blocker=断言待确认` + 期望 vs 实际，**不改断言**，提示切 `bugfix`（BR-16）。
4. 语言差异走 `adapters/{lang}.md`。

### Step 5：去重（ADR-6）

- 合并条件：同锚点 + 同分支 + **断言集合等价** → 保留代表，其余 `status=merged`、`merged_into=代表编号`、`layer=—`。
- 断言集合不同 → 两条都保留并标 `待人工确认`。
- 跨层重复（UI/接口/集成同一能力）→ 只在最贴近实现的一层落自动化，其余标「已由 {代表编号} 覆盖」。

### Step 6：落盘

- 矩阵：`docs/qa/legacy/{project}/tc-classification.csv`
- TS-LEGACY：`docs/test-spec/legacy/TS-LEGACY-{module}.md`
- 批次未确认完毕 → 停止，输出「本批 N 条已分类，请确认后继续下一批」（AC-08）

## 矩阵字段契约（BR-10）

```csv
legacy_tc_id,title,gate,layer,strategy,status,coverage,merged_into,blocker
TC-0001,查询车位-正常返回,ok,W2,smoke,automated,SpaceQueryController#query,,
```

| 字段 | 取值域 | 必填 | 规则 |
|------|--------|------|------|
| `legacy_tc_id` | 原编号 | 契约（8 个） | 唯一 |
| `title` | 文本 | **展示列** | 摘要，不改原文 |
| `gate` | `ok`/`G1`/`G2`/`G3`/`G4` | 契约 | Step 2 |
| `layer` | `W1~W6`/`B1~B5`/`—` | 契约 | `gate≠ok`、`status=merged` 或不可判定时 `—` |
| `strategy` | `smoke`/`regression`/`contract`/`perf`/`uat`/`—` | 契约 | 横切标签 |
| `status` | `automated`/`merged`/`manual`/`obsolete`/`needs_revision`/`blocked` | 契约 | gate→status 映射 |
| `coverage` | 方法名/路径占位/`—` | 契约 | `gate≠ok` 或 `status=merged` 时 `—`；缺 OpenAPI 时 `—` + `blocker=缺 OpenAPI` |
| `merged_into` | 代表编号/`—` | 契约 | 仅 `status=merged` 非 `—` |
| `blocker` | 文本/`—` | 契约 | 无问题为 `—` |

**不变式（自检）**：
1. `gate≠ok` ⟹ `layer=—`
2. `status=merged` ⟹ `layer=—` 且 `merged_into≠—`
3. `layer∈{W,B}` ⟹ `gate=ok` 且 `status=automated`
4. 无「既 G 又 W/B」的行

## 硬性禁令（违反即停）

1. **禁止** 无用例导出就「凭模块名猜用例」（须阻断或 AskQuestion）
2. **禁止** 缺预期/预期矛盾时猜断言（须标 `G1`）
3. **禁止** 归属不可判定时强行落层（须 `layer=—` + 待确认）
4. **禁止** 在本 Skill 生成任何测试代码（`.java`/`.py`）
5. **禁止** 修改用例正文
6. **禁止** 改 Story / TS / OpenAPI / Rule 正文
7. **禁止** 自行裁决断言对错（标 `blocker` 并切 `bugfix`）
8. **禁止** 把 `G3 obsolete` 当作已确认删除（须产品/QA 确认；确认前不删、不剔提测分母）
9. **禁止** 单批超过 200 条不切批、不等人确认
10. **禁止** `gate≠ok` 或 `status=merged` 的行填 `layer`
11. **禁止** 把语言差异写进核心流程（须放 `adapters/{lang}.md`）
12. **禁止** 越界：触发本 Skill 的定位边界时输出「本 Skill 只产出分类与规格，不生成代码 / 不改正文」并停止该动作

## 与其他 Skill 的关系

| 触发条件（矩阵行） | 切换到 | 衔接契约 |
|--------------------|--------|----------|
| `layer=W1`/`W2`/`W5` | `feature-coding` | 矩阵行 + `TS-LEGACY` 用例段（GWT/锚点） |
| `layer=W3`/`W4` | `integration-test-design` | 矩阵行 + 入口类/接口 |
| `layer=B1`/`B3` | `api-blackbox-test` | 矩阵行 + OpenAPI 路径 |
| 黑盒行需环境前置数据 | `test-data-design` | Given + `seed_key` 命名 + 画像落点 |
| `layer=B5` | `integration-test-design` + `test-data-design` | 链路 + Given + `seed_key` |
| `layer=B4` | `performance-test`（规划） | 矩阵行 + 场景链路 |
| `layer=W6` / `B2` | 前端另仓 `frontend-feature-coding` / `e2e-test` | 标注 |
| 断言冲突行 | `bugfix` | 编号 + 期望 vs 实际 + 锚点 + 复现线索 |
| 核心域需补需求真源 | `story-splitting`（可选） | 逆向 Story 草案 |
| 新需求（已有 Story） | `test-spec-alignment` | 不走本 Skill |

**不切换的边界**：纯质量审计不切本 Skill（`test-quality-audit`）；数据 bug 不切本 Skill。

## 降级策略

| 缺失 / 场景 | 处理 | 严重度 |
|-------------|------|--------|
| 无用例导出 | **阻断**：「未提供用例导出文件，无法开始分类，请提供 CSV/Excel」 | 致命 |
| 缺分类指引 / 矩阵模板 / TS-LEGACY 模板 | **阻断** | 致命 |
| 代码仓不可访问 | `gate=G4` + `blocker=代码不可锚定`；只出归一化 + 分层建议 | 高 |
| 缺目标语言 adapter | `gate=G4` + `blocker=缺 {lang} adapter` | 高 |
| 缺 OpenAPI | B1/B3 行 `coverage=—` + `blocker=缺 OpenAPI` | 中 |
| 用例量 > 200 | 分批，每批人工确认 | 中 |
| 断言与现网/契约不符 | `blocker=断言待确认` + 切 `bugfix`；不改断言 | 高 |

## 检查清单（自验）

- [ ] 从前置判断：用例导出可解析（否则已阻断）
- [ ] 单批 ≤ 200；超批已停下等确认
- [ ] 每条用例已归一化（Given/When/Then）；缺失字段标 `G1` 并记 `blocker`
- [ ] 门禁判定顺序正确（G3→G1→G4→G2→ok）；`gate≠ok` 行 `layer=—`
- [ ] `status=merged` 行 `layer=—` 且 `merged_into` 非空
- [ ] 分层裁决用了 ADR-7（部署态增量）；B2/B4/B5 按场景成桶
- [ ] 归属不清的行 `layer=—` + `待人工确认`（未强行落层）
- [ ] `coverage` 有锚点或 `blocker`；断言冲突已标 `blocker` 并提示 `bugfix`
- [ ] 合并行有 `merged_into`，并保追溯
- [ ] 未生成任何测试代码；未改用例正文 / Story / TS / OpenAPI / Rule
- [ ] 已产出矩阵（8 契约字段 + `title`）与 `TS-LEGACY-{module}.md`
- [ ] `G3` 仅标候选，未删除、未剔提测分母

## 配套资产

- `references/case-normalize-guide.md` — 归一化规则（本 Story 产出物）
- `references/classification-guide.md` — 门禁/分层/裁决（本 Story 产出物）
- `references/code-anchor-guide.md` — 代码锚定（本 Story 产出物）
- `templates/matrix-template.csv` — 矩阵模板（本 Story 产出物）
- `templates/ts-legacy-template.md` — TS-LEGACY 模板（本 Story 产出物）
- `references/adapters/java.md`、`references/adapters/python.md` — 语言适配（本 Story 产出物）

## 延伸阅读

- DD-STORY-2026-S01-095（源项目 legacy 迁移 Skill 设计卡）（详设）
- STORY-2026-S01-095（源项目 legacy 迁移 Skill 需求卡）
- [legacy-test-case-migration.marp.md](../../docs/training/legacy-test-case-migration.marp.md)（存量改造策略）
- [whitebox-layers-qa-boundary.marp.md](../../docs/training/whitebox-layers-qa-boundary.marp.md)（白盒层义）
- [blackbox-test-case-selection.marp.md](../../docs/training/blackbox-test-case-selection.marp.md)（黑盒漏斗）
- [test-spec-alignment SKILL](../test-spec-alignment/SKILL.md)（新需求 TS，边界对照）
- [feature-coding SKILL](../feature-coding/SKILL.md) / [integration-test-design SKILL](../integration-test-design/SKILL.md) / [api-blackbox-test SKILL](../api-blackbox-test/SKILL.md)（下游生成）

