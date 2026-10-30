# Story → 验收用例映射指引

> 配套 `qa-acceptance-case-design` Skill。把 Story AC/BR + OpenAPI 展开为**给人执行**的验收用例（GWT）时的筛选漏斗、黑盒候选判定、与 TS 去重、冒烟/回归分层、回归库可追溯规则。

## 1. 筛选漏斗（全量 → 冒烟 / 回归 / 不进黑盒）

> 照搬 [blackbox-test-case-selection.marp.md](../../../docs/training/blackbox-test-case-selection.marp.md) §1 漏斗。

```text
① 全量候选 = 本迭代 AC + Epic 主路径（链路级场景）+ 历史缺陷复现（典型 200～700 条意向）
② 剔除 → 白盒已细测、黑盒无部署态增量 → 不进黑盒
③ 黑盒候选 → 真实 HTTP / 跨进程 / 真实第三方 / 用户可见 / 历史缺陷
④ 冒烟 5～15 条 → P0 主路径 + 横切（健康检查 + 各 BFF 未授权拦截）+ <2 min
⑤ 回归 → 其余黑盒候选，按本次变更影响面选集（可数十～数百，非每次全量）
```

## 2. 黑盒候选判定（7 类，照搬 marp §3）

> 归属「不进黑盒」的，`execution` 不得标 `blackbox`。

| 场景 | 归属 | 落点 / 理由 |
|:--|:--|:--|
| 参数校验全分支、401/403 鉴权分支；业务状态机、事务逻辑、数据库断言；单字段映射、业务计算逻辑 | **不进黑盒** | PR 阶段白盒已覆盖（`*ServiceTest` / `*ControllerTest` / `*IT`） |
| 仅 Mock 第三方的超时 / 异常 | **不进黑盒** | `*IT` `@MockBean` 即可验证，无需部署环境 |
| 真实 HTTP（网关、Filter、TLS） | **黑盒候选** | 部署态独有 |
| 跨进程 / 跨服务串联（BFF→iam→域） | **黑盒候选** | 进程外视角；进程内多模块归白盒 IT |
| 真实第三方联调（支付沙箱、iam） | **黑盒候选** | 白盒 Mock 不了真环境 |
| 用户可见主路径、导出、列表 | **黑盒候选** | UAT / 黑盒粗断言 |
| 线上曾出过缺陷的路径 | **黑盒候选** | 回归必留 |

## 3. 与 TS 去重 + `ci_covered` 双条件（BR-05）

### 3.1 `ci_covered` 双条件

`execution=ci_covered` 须**同时满足**：

- ① TS 矩阵对该 AC 标 **单元 / BFF / IT 全覆盖**
- ② 该 AC **无部署态独有验证点**（真实网关 401/403、TLS、跨进程串联、真实第三方联调等，见 §2）

**仅 ① 不满足 ②** → `execution=blackbox`（`suite=smoke` 或 `regression`）。
Then 写「以 MR 流水线 `mvn test` 通过为准」，**不得**再生成等价 pytest 步骤。

### 3.2 反例（重点）

- **BFF 测了参数校验 ≠ 黑盒无部署态增量**：参数非法 400 是白盒已覆盖（§2 第 1 行），但真实 iam 鉴权、网关 Filter、TLS 是部署态独有（§2 第 3~5 行），即便 TS 标 BFF 全覆盖，仍应标 `blackbox`
- **`*IT` 用 `@MockBean` 模拟外部 ≠ 黑盒无增量**：真实第三方联调（支付沙箱、iam）白盒 Mock 不了，仍需 `blackbox`

### 3.3 禁止双维护

- 外部用例系统正文以 Git 生成 GWT 为草稿；字段链接至 `STORY-*` / `TS-*` / MR Pipeline
- **禁止**要求与 TS 双份长期维护相同步骤（BR-04）
- `ci_covered` 行 Then 写「以 MR 流水线 `mvn test` 通过为准」+ Pipeline 引用占位

## 4. 冒烟 / 回归分层（BR-11）

| 集合 | 构成 | 规模 |
|------|------|------|
| **冒烟** `suite=smoke` | 各核心业务域 1 条 P0 主路径 + 横切（健康检查 `/actuator/health` + 各 BFF 未授权拦截探测 Admin/App 各 ≤1）+ 每条 <2 min | **5~15 条** |
| **回归** `suite=regression` | 其余黑盒候选，**按本次变更影响面选集** | 可数十~数百，非每次全量 |

> `suite=smoke` 须满足「主路径 + 横切 + <2 min」三要素，缺一不可。

## 5. 回归库可追溯（BR-12）

- 回归库可含**历史 Story 沉淀路径**，但每条须可追溯 `Story / OpenAPI operation / 矩阵行`
- **无法追溯**的遗留 TC 须标 `legacy_tc_id`，并在下次触达时补 Story 或标 `obsolete`
- **不允许**无追溯的「孤儿回归用例」

## 6. 前端-only / N/A 标注（AC-07）

- Story §2.2「前端另仓」、TS 标前端-only、纯 UI 展示、无法后端单独验收的 AC → `execution=frontend_only` 或 `manual`，`suite=N/A`
- Then 描述**用户可见交互**；**不要求**后端黑盒脚本
- 防止 `api-blackbox-test` 误写后端脚本

## 7. 存量外部 TC 合并 / 废弃（BR-07）

- 存量外部 TC（无 Story，来自任意 TMS：禅道/Jira/Xray 等）：追溯表用 `legacy_tc_id` 关联
- `status` 取 `automated` / `manual` / `merged` / `obsolete`
- **`status`（TC 生命周期）与 `execution`（单条怎么跑）是两个维度**，模板须分别标注，不混用
- 不在本 Skill 内编造 Story AC

## 8. 优先级（BR-08）

- P0 / P1 / P2 默认继承 Story / 项目约定
- Skill **不擅自降级 P0**
- 缺失优先级 → **阻断并 AskQuestion**

## 9. 常见坑

| 坑 | 解法 |
|----|------|
| 把应 `manual` 的 UI 体验标成 `ci_covered` | UI 体验无自动化覆盖，标 `manual` 或 `frontend_only` |
| `ci_covered` 误判：BFF 测参数校验 → 标 ci_covered | 检查是否有部署态独有验证点（真实 iam/网关/TLS）；有则 `blackbox` |
| 黑盒候选判定错位：参数非法 400 标 blackbox | 参数非法归白盒（§2 第 1 行），标 `ci_covered` 或 `manual` |
| 冒烟集膨胀：smoke 超 15 条或漏横切 | smoke 严格 5~15 + 横切三要素；其余归 regression |
| 回归库孤儿：无 Story/OpenAPI 追溯的遗留 TC 长期滞留 | 标 `legacy_tc_id`，下次触达补 Story 或标 `obsolete` |
| 外部用例系统与 TS 双维护正文漂移 | 外部系统字段链接，正文以 Git GWT 为草稿（BR-04） |
