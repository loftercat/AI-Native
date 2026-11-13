# AC-STORY-{迭代}-{序号}-{slug}

| 字段 | 值 |
|------|-----|
| 迭代 | {迭代} |
| 状态 | 草稿 / 评审中 / 已确认 |
| 来源 | `STORY-{迭代}-{序号}-{slug}.md` · `docs/api/{服务标识}/openapi.yaml` · 可选 `TS-STORY-{迭代}-{序号}-{slug}.md`（只读对齐） |
| 服务/模块 | {love-app / love-advice / love-profile / ...} |
| 复杂度 | 简单 / 中等 / 高复杂 |

> **模板说明**：由 `qa-acceptance-case-design` Skill 在提测前根据 Story + OpenAPI（可选 TS 对齐）生成。删除本说明块。命名与落盘：`docs/qa/{迭代}/AC-STORY-{迭代}-{序号}-{slug}.md`（见 [card-naming-conventions.md](../../../docs/agile/card-naming-conventions.md)）。

## 1. 定位

> **解决什么问题**：让读者（QA / 研发 / 评审人）一眼知道这份验收清单**验的是哪个 Story、覆盖哪些 AC、冒烟/回归怎么选**，避免拿着用例却不知道范围与边界。

一句话：本 Story 验收什么、用户可见断言是什么、冒烟/回归如何选集。

## 2. Story/AC 追溯表

> **解决什么问题**：证明「每条 AC 都有验收用例兜底」（BR-03），避免漏验；同时给出每条用例的执行方式与选集归属，让提测评审能快速判断覆盖完整性与执行策略。
>
> 每条 AC（含成功与失败）至少一行。失败 AC 的 Then 须写具体 `message`，与 Story 一致，禁止「提示错误」。

| AC（验收标准） | acceptance_id（验收用例 ID） | priority（优先级） | execution（执行方式） | suite（用例集） | blackbox_rationale（黑盒入选理由） | 备注 |
|----|------------------------------|------------------------|--------------------|-----------------------|-------------------------------------|------|
| AC-01 | AC-{迭代}-{序号}-01 | P0 | | | | |
| AC-02 | AC-{迭代}-{序号}-02 | P1 | | | | |

## 3. GWT 用例表

> **解决什么问题**：把 AC 翻译成「**给人照着点一遍**」的操作步骤与可见结果断言——QA 拿来能直接执行，不必再回看 Story/详设；研发/评审人据此判断断言是否落在用户可见层（而非白盒内部状态）。
>
> - **Given**：前置条件（数据、登录态、配置）。
> - **When**：用户操作 / 接口调用（含 HTTP 方法与路径）。
> - **Then**：用户**能看见**的结果（`code=200`、列表字段、业务失败 `message`）；**不**断言 Mapper 内部状态或 Mock 边界（AC-04）。
> - 失败 AC 的 Then **必须含 Story 具体文案**（如「无可预约的车位」），禁止「提示错误」（AC-03）。
> - `execution=ci_covered` 行 Then 写「以 MR 流水线 `mvn test` 通过为准」+ Pipeline 引用占位，**不生成**等价 pytest 步骤（BR-05）。
> - `manual` / `frontend_only` 的 AC，以及 TS 矩阵中标 `N/A` 的 AC，须**展开 GWT**（含失败类用户可见文案，与 Story AC 一致）（BR-06）。

| 用例 ID | AC | Given | When | Then（用户可见） | execution | suite | blackbox_rationale |
|---------|----|-------|------|------------------|-----------|-------|--------------------|
| AC-{迭代}-{序号}-01 | AC-01 | | | | | | |
| AC-{迭代}-{序号}-02 | AC-02 | | | | | | |

## 4. 外部用例系统导出映射

> **解决什么问题**：Git 仓内的 GWT 与外部用例系统（禅道 / Jira / Xray / TestRail / Kiwi 等）**不双维护正文**——外部系统只存草稿 + 链接，正文以 Git 为唯一真源（SSOT），避免两边改一边漏。

- **正文**：以 Git 生成的 GWT 为草稿
- **链接字段**：`story_id` / `ts_id` / `mr_pipeline` / `legacy_tc_id`
- **禁止**与 TS 双份长期维护相同步骤（BR-04）；外部系统字段允许链接至 `STORY-*` / `TS-*` / MR Pipeline

## 5. 与 TS 对齐节

> **解决什么问题**：避免验收用例与研发 TS **重复设计同一条断言**——在此显式记录「哪条 AC 已被 CI 全覆盖（`ci_covered`）、哪条因部署态独有仍需黑盒（`blackbox`）」，让 `api-blackbox-test` 只挑真正需要部署态的行去写 pytest。

- **TS 覆盖矩阵只读引用**（不复制正文）
- **`ci_covered` 双条件判定**（BR-05）：
  - ① TS 矩阵对该 AC 标单元/BFF/IT 全覆盖
  - ② 该 AC 无部署态独有验证点（真实网关 401/403、TLS、跨进程串联、真实第三方联调）
  - 仅 ① 不满足 ② → `execution=blackbox`（suite=smoke 或 regression）
- **反例**：BFF 测参数校验 ≠ 黑盒无部署态增量
- **前端-only / N/A 标注**：Story §2.2 或 TS 标前端另仓 → `execution=frontend_only` 或 `manual`，`suite=N/A`

| AC | TS 覆盖（单元/BFF/IT） | 部署态独有验证点 | execution 判定 | 说明 |
|----|------------------------|------------------|----------------|------|
| AC-01 | | | | |
| AC-02 | | | | |

## 6. 回归库追溯

> **解决什么问题**：防止「**孤儿回归用例**」——回归库里堆着没人说得清来源的旧用例，改了需求也没人同步，跑过了却不知道验的是什么。本节强制每条回归用例都能追溯到 `Story / OpenAPI operation / 矩阵行`，无追溯的遗留 TC 必须显式标 `legacy_tc_id` 并在下次触达时补 Story 或标 `obsolete`（AC-13/BR-12）。

- 本 Story 新建用例：无 `legacy_tc_id`
- 关联存量外部 TC：`legacy_tc_id` + `status`（`automated` / `manual` / `merged` / `obsolete`）
- 无法追溯的遗留 TC：下次触达补 Story 或标 `obsolete`

| 验收用例 ID | legacy_tc_id | status | 追溯说明 |
|------------|--------------|--------|----------|
| | | | |

## 7. 冒烟集（suite=smoke）

> **解决什么问题**：提测/发版时**先跑什么**才能确认「系统没死」——冒烟集是**最小可执行的健康证明**，规模收敛在 5~15 条，含主路径 + 横切探测，2 分钟内跑完，避免每次都全量回归。

> 总数 **5~15 条**；含 ≥1 健康检查（`/actuator/health` 或等价）+ 各 BFF 未授权拦截探测（Admin/App 各 ≤1）；每条标注预计 <2 min（AC-12/BR-11）。

| # | 验收用例 ID | AC | 类型（主路径/health/auth_probe） | 预计耗时 |
|---|------------|----|--------------------------------|----------|
| 1 | | | | <2 min |
| 2 | | | | <2 min |

## 8. 缺口与阻断项

> **解决什么问题**：把「**生成验收清单时发现的、但本 Skill 不能自行解决**」的问题显式留痕——AC 没对应用例、失败文案缺失、OpenAPI 缺失等——避免带着缺口悄悄进入 `api-blackbox-test`，事后才发现没得验。

> 阻断项解除前不得进入 `api-blackbox-test`。

| 类别 | 内容 | 动作 |
|------|------|------|
| AC 无 Story 映射 | | 补用例或标 N/A |
| 失败 AC 缺具体文案 | | 回溯 Story 补 Then |
| 缺 OpenAPI（HTTP Story） | | 阻断，提示提供 OpenAPI |

## 9. 变更记录

> **解决什么问题**：需求变更时**不静默改用例**——废弃的 AC 标 `obsolete`、新增/修改的 AC 留痕，让评审人能看清这份清单的演进轨迹，避免「用例与最新 Story 对不上」。

| 日期 | 变更 | 作者 |
|------|------|------|
| | | |

---

## 枚举速查

> **解决什么问题**：把分散在多节的枚举值集中在一处，便于填表时快速查「这个字段能填什么、什么含义」，不必在 SKILL/指引/Story 之间来回跳。

| 字段 | 枚举 | 说明 |
|------|------|------|
| `execution`（单条怎么跑） | `manual` / `ci_covered` / `blackbox` / `frontend_only` / `obsolete` | 由本 Skill 按漏斗 + 黑盒判定 + ci_covered 双条件标注 |
| `suite`（黑盒跑哪批） | `smoke` / `regression` / `N/A`（非 blackbox 时） | 冒烟 5~15 + 横切；回归按变更影响面 |
| `status`（TC 生命周期） | `automated` / `manual` / `merged` / `obsolete` | 与 `execution` **分两维度**，不混用（BR-07） |
| `priority` | `P0` / `P1` / `P2` | 默认继承 Story/项目约定；不擅自降级 P0（BR-08） |
| `blackbox_rationale` | 自由文本 | 仅 `execution=blackbox` 时**必填** |
