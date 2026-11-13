# AI Native 测试线 Skill 规划

> **测试线**方法论：测试金字塔、各层测试分工、研发/QA 两条 Skill 线及流水线衔接。  
> 模板版：自已落地的源项目抽取，项目实例（模块名、Story 号）保留作示例。开发线 Skill 见 [readme.md](readme.md)。

---

## 1. 现状一览

| 类别 | Skill | 状态 |
|------|-------|------|
| **研发线（已落地）** | `high-level-design` / `story-splitting` / `detail-design` / `feature-coding` | ✅ |
| **测试线（已落地）** | `test-spec-alignment` | ✅ → 产出 `docs/test-spec/{迭代}/TS-STORY-*.md` |
| **测试线（已落地）** | `integration-test-design` | ✅（STORY-2026-S01-005）→ `booking-app` `*IT` / `*ScenarioIT` |
| **测试线（未落地）** | `test-quality-audit` / `bug-fix` / `regression-guard` / `contract-test` | 规划中 |
| **QA 专线（部分落地）** | `qa-acceptance-case-design` ✅（S01-090）/ `api-blackbox-test` ✅（S01-091）/ `test-data-design` ✅（S01-092，SQL 通道骨架）/ `performance-test` | 有 QA 团队再落地 |
| **前端另仓（规划）** | `frontend-high-level-design`（可选）/ `frontend-story-splitting` / `frontend-detail-design` / `frontend-feature-coding` / `frontend-test-spec-alignment`（推荐）/ `frontend-contract-test` / `e2e-test` | 前端仓落地；本仓库只定协作接口（§4.4~§4.5） |

命名契约：`TS-STORY-*` 路径见 [card-naming-conventions.md](../agile/card-naming-conventions.md)。

---

## 2. 测试金字塔

### 2.1 三个正交维度

| 维度 | 回答什么 | 取值 |
|------|---------|------|
| **范围**（金字塔层） | 测多大一块 | 单元 → BFF API → 集成/场景 → 黑盒（部署后）→ E2E |
| **实现路径** | 谁写、在哪跑 | 研发 Java（进程内、每次 PR）／ QA Python（部署后、发版时） |
| **策略** | 这次测的目的 | 冒烟 / 回归 / 契约 / 性能 / 手工验收 |

```text
定位 = 范围 × 实现路径 × 策略
例：Java 集成/场景 = 集成/场景 × Java 进程内 × 回归
例：Python API 冒烟 = 集成/场景（部署后）× Python × 冒烟
```

### 2.2 金字塔图

```text
                    △
                   / E2E \          少、慢、脆（UI，前端另仓）
                  /───────\
                 / 黑盒(部署后)\    Python 可选；无 QA 则由 Java 冒烟取代
                /─────────────\
               /  集成/场景      \   Java 进程内 + 真实 DB（*IT / *ScenarioIT）
              /─────────────────\
             /   BFF API 测试     \  单接口，Mock 域层（*ControllerTest）
            /─────────────────────\
           /     单元测试           \  单方法，全 Mock（*ServiceTest）
          /──────────────────────────\
```

**原则**：层表达范围大小；路径和策略横切各层。底层多、顶层少。

### 2.3 分层对照表（本仓库）

| 测试类型 | 测什么 | Mock | 路径 | 何时跑 | Skill | 位置 | 类名 |
|----------|--------|------|------|--------|-------|------|------|
| 单元测试 | 单方法逻辑 | 全 Mock | Java 进程内 | 每次 PR | `feature-coding` | `*-impl/src/test/` | `*ServiceTest` |
| BFF API | 单 HTTP 接口 | Mock 域层 | Java 进程内 | 每次 PR | `feature-coding` | `booking-bff-*/src/test/` | `*ControllerTest` |
| 集成测试 | 单链路真实编排 | 只 Mock 系统外依赖 | Java 进程内 | 每次 PR | `integration-test-design` | `booking-app/src/test/` | `*IT` |
| 场景测试 | 多 API 串联 | 只 Mock 系统外依赖 | Java 进程内 | 每次 PR | `integration-test-design` | 同上 | `*ScenarioIT` |
| API 黑盒 | 部署后接口/主流程 | 环境级假 | Python | 发版后 | `api-blackbox-test`（可选） | 独立 Python 套件 | `test_*.py` |
| E2E | 小程序/UI 全流程 | 几乎不 Mock | 前端另仓 | 发版/定时 | `e2e-test`（另仓） | — | — |

> **Mock 边界**：集成/场景测**本系统内**真实编排（BFF → 域 → Mapper/DB），只 Mock **系统边界外**出站依赖（`PaymentClient`、`ParkingLotGateway`、iam）。BFF API 用 MockMvc，**不算**集成测试；集成必须 `RANDOM_PORT` + 真实 HTTP（见 `rules/integration-test-conventions.md`）。

### 2.4 怎么选

```text
单方法 if/else、状态机？           → 单元测试（feature-coding）
接口参数错 400、未登录 401？       → BFF API（feature-coding）
创建订单后 DB 真有记录？           → 集成测试（integration-test-design）
登录→搜索→预约 多步串联？          → 场景测试（integration-test-design）
部署后主接口还能通？               → API 黑盒冒烟（api-blackbox-test；无 QA 用 Java 冒烟子集）
小程序点一遍全流程？               → E2E（前端另仓）
```

### 2.5 横切策略

| 策略 | 作用 | 本仓库 Skill |
|------|------|-------------|
| 冒烟 | 抽核心主路径确认「没死」 | Java 集成冒烟子集 / `api-blackbox-test` |
| 回归 | 变更后重跑既有用例 | `regression-guard`（可选）/ `test-quality-audit` |
| 契约 | 服务间接口约定一致 | V2+ `contract-test` |
| 性能 | 并发容量 | `performance-test`（可选） |
| 手工验收 | UAT、联调 | `qa-acceptance-case-design`（可选） |

### 2.6 覆盖率：白盒与黑盒分工

白盒（单元 + 集成/场景）加入后，**黑盒覆盖率不必追求 100%**——总需求覆盖不变，白盒承担大部分逻辑验证，黑盒只补盲区：

| | 黑盒独有（白盒替代不了） | 黑盒不必重复（白盒已覆盖） |
|---|--------------------------|--------------------------|
| 价值 | 部署/环境验证、UI/E2E、真实第三方联调、UAT 验收路径 | 业务逻辑、状态机、事务、边界分支、DB 断言 |

**建议 KPI**：白盒高覆盖 + 黑盒补盲区 + 冒烟通过率，而非「黑盒用例数越多越好」。

---

## 3. Java 进程内 vs Python 部署后

同一「集成/场景」范围的两条实现路径，**不是换语言，是守不同质量关口**：

| 维度 | Java 集成/场景 | Python 黑盒 |
|------|---------------|-------------|
| 谁写 | 开发 | QA |
| 跑在哪 | 本地/CI，`mvn test` | 已部署测试环境 |
| 视角 | 白盒：可 `@MockBean`、直查 DB | 黑盒：只认 HTTP |
| 守什么 | **代码写对了吗**（每次 PR） | **部署跑得起来吗**（发版后） |
| 断言 | 精细（DB、状态机、错误码） | 粗糙（`code=200`、关键字段） |
| 外部依赖 | 代码级 `@MockBean` / WireMock | 环境级沙箱 |

**避免重复（推荐方案 C）**：

```text
1. Java 集成/场景 → 每次 PR 守链路逻辑
2. Python          → 只写 Java 够不着的：发版冒烟、UI/E2E、压测、真实联调
3. 同一场景只写一遍，按「何时跑 + 守什么」分工
```

`integration-test-design` 是 **Java 专用**；Python 归 `api-blackbox-test` 等独立 Skill，二者不共用。

---

## 4. Skill 全景

### 4.1 研发测试线

| Skill | 职责 | 产出 | 触发时机 | 状态 |
|-------|------|------|---------|------|
| `test-spec-alignment` | 编码前：AC→用例、分层、Mock 边界 | `TS-STORY-*.md` | DD 完成后、FC 前 | ✅ |
| `feature-coding` | 单元 + BFF API + Mapper + 实现 | `*Test.java` + 业务代码 | 按 TS 编码 | ✅ |
| `integration-test-design` | 白盒集成/场景 | `*IT` / `*ScenarioIT` | TS 含集成层或按详设自行设计 | ✅ |
| `test-quality-audit` | 全库测试债务扫描 | 审计报告 | 迭代末/发版前 | 规划中 |
| `regression-guard` | 需求变更影响面 + 回归集 | 回归用例集 | 需求变更/跨 Story BR | 规划中 |
| `bug-fix` | 先复现再修，不改 AC | 复现测试 + 根因记录 | 联调/上线后 | 规划中 |
| `contract-test` | 微服务契约守护 | Pact / SCC | V2+ 拆服务后 | 未规划 |

### 4.2 QA 测试工程师专线（可选）

有 QA 团队才落地整条专线；无 QA 时黑盒冒烟由 Java 集成测取代，验收由研发测试 + UAT 承担。

| Skill | 职责 | 产出 | 与研发 Skill 关系 | 状态 |
|-------|------|------|------------------|------|
| `qa-acceptance-case-design` | **验收用例设计**（给人执行） | 外部用例系统/Excel（GWT） | 同源 Story；TS 对齐参考 | ✅ 已落地（S01-090） |
| `api-blackbox-test` | **黑盒集成**（部署后 API） | pytest 脚本 | 同范围不同路径 vs `integration-test-design` | ✅ 已落地（S01-091） |
| `test-data-design` | **环境级造数** | 造数脚本 + 清理 | vs 研发 `@Sql`/`TestDataFactory`（进程内） | ✅ 已落地（S01-092，SQL 通道骨架） |
| `e2e-test` | UI 端到端 | Playwright/Appium | 前端另仓，本仓库不规划 | 另仓 |
| `performance-test` | 压测 | Locust/JMeter | 复用集成测链路设计 | 可选 |
| `regression-guard` | 跨 Story 回归 | 回归集 | 互补 `feature-coding` 单 Story 增量 | 共用 |
| `bug-fix`（QA 消费） | 提复现路径 + Bug 单 | Bug 单 | 研发侧修代码 | 共用 |

**QA 用例 ≠ TS**：TS 是研发测试规格（哪层测、断言什么、Mock 什么）；验收用例是用户可见断言（`code=200`、主流程通），面向手工/UAT。二者平行、同源于需求卡，不可互相替代。

**验收用例 vs 自动化脚本**：`qa-acceptance-case-design` 产出给人点的用例；`api-blackbox-test` 产出给机器跑的脚本。

### 4.3 研发线与 QA 专线关系图

```text
                需求卡（Story AC/BR）←──── 共同源头
                        │
            ┌───────────┴───────────────┐
            ▼                           ▼
   test-spec-alignment          QA 专线（可选）
      （产出 TS）               ├── qa-acceptance-case-design（验收用例）
            │                   ├── api-blackbox-test（黑盒自动化）
   ┌────────┼────────┐          ├── test-data-design（造数）
   ▼        ▼        ▼          ├── e2e-test / performance-test
feature-  integration-          └── regression-guard / bug-fix
coding    test-design                │
   ▲        ▲        ▲              │
   └────────┴────────┴── TS 对齐 ───┘
```

**五条原则**：

1. **同源非上下游**：QA 不以研发测试为输入，TS 是 QA 的**对齐参考**（非硬依赖）；QA 硬依赖是 Story + OpenAPI。
2. **同场景只写一遍**：Java 守代码逻辑（PR），Python 守部署/环境（发版后）。
3. **TS 依赖强度递减**：单元（TS 主输入）> 白盒集成（TS 可选）> 黑盒（Story + OpenAPI 为主）。
4. **研发执行 Skill 不归 QA 专线**：`feature-coding` / `integration-test-design` 是研发侧的。
5. **TS 是粘合层，非唯一数据源**：实现细节仍回详设 §8；QA 验收仍回需求卡 + OpenAPI。

### 4.4 前端仓 Skill 线（另仓）

> B 端运营后台前端、C 端小程序/App **不在本仓库**（见 [AGENTS.md](../../../AGENTS.md)）。前端仓若推行 AI Native，建议落地以下 Skill；本仓库只定义**协作接口**，不定义前端仓内部 Skill 正文。详见 前端仓 Skill 规划（源项目 AI-NATIVE-FRONTEND.md，模板未随附；协作接口思想见本节）。

前端仓的 Skill **不是后端 Skill 的镜像**——前端没有「域状态机/Mapper/集成测试」那一层，重点是 **spec → 组件实现 + 契约 + E2E**，且强依赖后端契约。研发线前段（story-splitting / detail-design）与后端对称，测试线按 Kent C. Dodds「Trophy」分层（单元/组件/契约/E2E）。

| Skill | 职责 | 产出 | 主输入 | 触发时机 |
|-------|------|------|--------|----------|
| `frontend-high-level-design`（可选） | 前端 HLD（边界、页面树、设计系统） | `HLD-FE-*.md` | Epic/PRD | 有独立前端 Epic 时；或并入后端 HLD §前端 |
| `frontend-story-splitting` | 拆前端 Story（按页面/组件切，不按层切） | `STORY-FE-*.md`（AC/BR + 本卡 `operationId` 范围表） | Epic/PRD + handoff OpenAPI + 后端 Story 摘要 | Epic 定稿后 |
| `frontend-detail-design` | 前端详设（路由、组件树、状态机、AC→operationId 映射、错误展示） | `DD-FE-*.md` | `STORY-FE-*` + OpenAPI + 原型 | Story 定稿后、编码前 |
| `frontend-feature-coding` | 页面/组件实现 + 组件单元测试（TDD） | `*.vue`/`*.tsx` + `*.spec.ts`（Vitest + Testing Library） | `STORY-FE-*` + `DD-FE-*` | 按 Story 编码 |
| `frontend-test-spec-alignment`（推荐） | 前端 TS：组件测试 + E2E 用例追溯 | `TS-FE-STORY-*.md` | `STORY-FE-*` + OpenAPI | DD 后、编码前 |
| `frontend-contract-test` | 契约测试（前后端独立部署门禁） | MSW handler + Vitest 契约断言；或 Pact | handoff OpenAPI + 前端 API client 调用点 | 编码期；CI 每次 PR |
| `e2e-test` | UI 端到端自动化 | Playwright/Minium/Appium `*.spec.ts` + 冒烟 manifest | `AC-STORY-*` 中 `execution=frontend_only` + 页面路由 + OpenAPI | 需求开发阶段（生成）；部署后（执行） |

**为什么有 `frontend-contract-test`**：本仓前后端**不同 GitLab、独立部署**，行业最佳实践（Kent C. Dodds Trophy、Spotify Honeycomb、alexop.dev §6）强烈推荐此时做契约测试。后端已发 OpenAPI（provider-driven），前端做 consumer-side 校验（MSW + Vitest 验响应形状；或 Pact consumer-driven）。**契约测试验「接口形状对不对」（schema/错误码/examples），E2E 验「用户旅程通不通」**，二者不可互替。

**输入从哪来（跨仓消费）**：

| 前端 Skill 的输入 | 后端仓哪里产 | 怎么拿 |
|-------------------|--------------|--------|
| Story / AC | `docs/requirements/{迭代}/STORY-*.md` | 拉后端仓 tag/commit（或 monorepo/子模块） |
| OpenAPI 契约 | `docs/api/**/openapi.yaml` | 同上；前端据此生成 API client / 手写请求；契约测试据此校验响应形状 |
| QA 验收清单（GWT） | `docs/qa/{迭代}/AC-STORY-*.md` | 只消费 `execution=frontend_only` 行；`ci_covered`/`blackbox` 不归前端 |
| TS（去重参考） | `docs/test-spec/{迭代}/TS-STORY-*.md` | 只读，避免 E2E 重复白盒已覆盖分支 |

**前端仓不消费**：`*Test.java`、`*IT`、`tests/blackbox/*.py`——这些是后端仓的执行资产，前端只认 **Story/AC + OpenAPI + 验收清单**。

### 4.5 后端仓 ↔ 前端仓协同

协同分**两条链**，不要混：一条是「设计/开发期同步脚本」，一条是「部署后执行已有脚本」。

#### 4.5.1 设计/开发链（需求发生时）

```text
后端仓                              前端仓
─────────                           ─────────
story-splitting → STORY/AC
detail-design   → OpenAPI
test-spec-alignment → TS
qa-acceptance-case-design
  → AC-STORY（标 frontend_only）
        │
        └──拉取（tag/commit）──→  frontend-feature-coding
                                   → 页面/组件 + 组件测试
                                 e2e-test
                                   → 生成 *.spec.ts（绑 AC）
                                   → 评审 + 提交前端 MR
```

要点：
- 前端 **锁后端 commit/tag** 拉文档，避免对着未评审需求写脚本；
- E2E 脚本在**需求开发阶段**生成、评审、提交，**不是**部署后临时生成；
- `e2e-test` 的硬输入是 `AC-STORY`（frontend_only）+ 页面路由；TS 仅作去重参考。

#### 4.5.2 部署/执行链（提测/发版时）

```text
后端仓 CI                           前端仓 CI
─────────                           ─────────
mvn verify（白盒门禁）
  ↓ 通过
部署测试环境（后端 + 前端）
  ↓
pytest -m smoke（API 黑盒）
  ↓ 通过
trigger ──────────────────→  npx playwright test --grep @smoke
  传 BASE_URL/Story/AC            执行已提交的 *.spec.ts
  ↓                              ↓
  ↓                          JUnit XML / Allure
  ←── 结果回传 ───────────────
  ↓
汇总门禁（白盒+API+E2E）
```

要点：
- **PR 阶段**前端不跑 E2E（无稳定部署环境）；
- **API 黑盒通过后**触发的是「执行前端仓**已有**脚本」，不是临时通知 AI 生成；
- 三处 JUnit XML 汇总到 Allure + 禅/Kiwi，按 AC 追溯。

#### 4.5.3 需求变更时的双向同步

```text
Story/AC 变更（后端仓 §7 变更记录）
  ├─ 后端：test-spec-alignment 增量 TS → feature-coding/IT 改测试（同 MR）
  ├─ 后端：qa-acceptance-case-design 更新 execution；废弃 AC 标 obsolete
  └─ 前端：拉新 AC-STORY → e2e-test 改 *.spec.ts（前端独立 MR）
        ↓
联合部署 → API 冒烟 + E2E 验证变更
```

**协同三原则**：

1. **同源非上下游**：前端不以后端测试代码为输入，硬依赖是 Story/AC + OpenAPI + `AC-STORY`（frontend_only）。
2. **脚本提前生成、部署后只执行**：E2E 脚本在设计阶段提交，部署后 trigger 的是执行，不是生成。
3. **跨仓靠 ID 串联**：`STORY-{迭代}-{序号}` + `AC-xx` 在分支名、PR、`@Tag`、CSV、禅道里复用；不靠拷贝正文。

---

## 5. `test-spec-alignment` 详解

> 设计源头章节；Skill 执行器见 `skills/test-spec-alignment/SKILL.md`。

### 5.1 一句话

编码前把「要测什么、测哪一层、Mock 什么」从 Story + 详设拆出，落成 `TS-STORY-*.md`，校验 AC 均有测试覆盖计划。

### 5.2 产出内容（TS 文档）

1. **AC → 用例追溯表**（方法名、成功/失败、预期 `code`/`message`）
2. **分层测试矩阵**（ServiceTest / ControllerTest / IT；Mock 边界）
3. **Fixture / 种子数据设计**
4. **前端-only / N/A 标注**
5. **缺口与阻断项**（AC 无计划、错误码与 OpenAPI 不一致 → 阻断）

详设 §9 只到「类名 + AC 编号」；TS 细化到用例级 Given-When-Then。

### 5.3 与相邻 Skill 边界

| Skill | 产出 |
|-------|------|
| `story-splitting` | Story（AC/BR） |
| `detail-design` | DD（§9 粗粒度测试策略） |
| **`test-spec-alignment`** | **TS（用例级测试规格）** |
| `feature-coding` | `*Test.java` + 实现 |
| `integration-test-design` | `*IT`（TS 含集成层时消费，否则按详设设计） |
| `qa-acceptance-case-design` | 禅道/Excel 验收用例（平行于 TS，不对等） |

### 5.4 TS 的消费者

| 消费者 | 主输入 | 产出 | 断言粒度 |
|--------|--------|------|----------|
| `feature-coding` | **TS**（兜底 Story/详设） | 单元/BFF/Mapper 测试 | DB、状态机、错误码 |
| `integration-test-design` | TS（若含集成层）或详设时序图 | `*IT` | 同上 + 跨域编排 |
| QA（`qa-acceptance-case-design`） | Story + OpenAPI（TS 对齐参考） | 验收用例 | 用户可见结果 |

**研发不以 QA 用例为输入**（时序冲突、断言粒度不同、职责不同）。TS 落地后 `feature-coding` 步骤 4「缺口清单」以 TS 为权威来源。

### 5.5 TS 依赖强度

| 测试 | 依赖 TS | 说明 |
|------|---------|------|
| 单元测试 | 🔺🔺🔺 最强 | AC→用例表 ≈ `*ServiceTest` 清单 |
| 白盒集成/场景 | 🔺🔺 中等 | TS 无集成层则按详设自行设计 |
| 黑盒（Python） | 🔺 最弱 | 硬依赖 OpenAPI；TS 防重复设计 |

---

## 6. 流水线衔接

```text
Epic/PRD → HLD → Story → DD + OpenAPI + §9
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
      test-spec-alignment  feature-coding  integration-test-design
           （TS）          （单元/BFF/实现）  （*IT，按 TS 或详设）
              │               │               │
              └─────── AC/用例追溯 ───────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
      test-quality-audit   bug-fix    regression-guard
                              │
                              ▼ 部署到测试环境（可选，有 QA）
              ┌───────────────┴───────────────┐
              ▼                               ▼
      api-blackbox-test              qa-acceptance-case-design
      （Python 冒烟/回归）            （手工验收用例）
              │
              │ API 冒烟通过
              ▼
      trigger 前端仓 ───────────────→ e2e-test（前端另仓）
                                      npx playwright test --grep @smoke
                                      （执行已提交的 *.spec.ts）
                                      ↓
                              JUnit XML / Allure 回传汇总
```

> 前端仓 Skill 线详见 §4.4；跨仓协同详见 §4.5。前端仓内部流水线（`frontend-story-splitting` → `frontend-detail-design` → `frontend-feature-coding` + `frontend-contract-test` + `e2e-test`）见 前端仓 Skill 规划（源项目 AI-NATIVE-FRONTEND.md，模板未随附；协作接口思想见本节） §2。

---

## 7. 落地优先级

| 优先级 | Skill | 说明 |
|--------|-------|------|
| **P0** | `test-spec-alignment` | ✅ 已落地 |
| **P1** | `test-quality-audit` | 存量测试债治理 |
| **P2** | `bug-fix` | 联调期缺陷闭环 |
| **P3** | `integration-test-design` | ✅ 基建已落地（S01-005）；业务 `*IT` 按 Story 节奏增量 |
| **P4** | `contract-test` / `regression-guard` | V2+ 拆微服务后 |
| **可选** | QA 专线全套 | 有 QA 团队时：`qa-acceptance-case-design` → `api-blackbox-test` → `test-data-design` |
| **前端另仓** | `frontend-story-splitting` / `frontend-detail-design` / `frontend-feature-coding` / `frontend-contract-test` / `e2e-test` | 前端仓落地；本仓库只定协作接口（§4.4~§4.5） |

---

## 8. 延伸阅读

| 主题 | 文档 |
|------|------|
| AI Native 方法论 | [docs/methodology/readme.md](readme.md) |
| 集成测试三个决策 | [docs/methodology/integration-test-design.md](docs/methodology/integration-test-design.md) |
| 集成测试 Rule | `rules/integration-test-conventions.md` |
| 单元测试质量 | [skills/feature-coding/references/test-quality.md](skills/feature-coding/references/test-quality.md) |
| TS / Story 命名 | [docs/agile/card-naming-conventions.md](docs/agile/card-naming-conventions.md) |
| `test-spec-alignment` Skill | `skills/test-spec-alignment/SKILL.md` |
| `integration-test-design` Skill | `skills/integration-test-design/SKILL.md` |

---

## 变更记录

| 日期 | 变更 |
|------|------|
| 2026-08-05 | 初版 |
| 2026-08-08~15 | 测试金字塔、Java/Python 分工、TS 消费关系、QA 验收层、覆盖率分层 |
| 2026-08-29 | `integration-test-design` 落地；新增 QA 测试工程师专线 |
| 2026-08-29 | **全文重构**：合并重复章节，922 行→约 300 行；§5 保留为 `test-spec-alignment` 锚点 |
| 2026-10-03 | 新增 §4.4 前端仓 Skill 线、§4.5 跨仓协同；§6 流水线补 `e2e-test` 触发；§1/§7 同步 |
| 2026-10-04 | §4.4 前端仓 Skill 线补全：新增 `frontend-high-level-design`（可选）/ `frontend-story-splitting` / `frontend-detail-design` / `frontend-contract-test`，`frontend-test-spec-alignment` 由可选升推荐；§1/§7 同步；§1 `api-blackbox-test` 补 ✅（S01-091） |

**旧章节对照（重构后）**：§2.3 各层详解 + §2.4 对照表 → §2.3；§2.7 覆盖率 → §2.6；§3 Java/Python → §3；§4.1~§4.7 Skill → §4；§5 TS 详解 → §5（§5.6~§5.8 并入 §4.3 / §5.4~§5.5）；§6 流水线 → §6；§7 优先级 → §7；§8 后续动作（已删除，多数已完成）；§9 延伸阅读 → §8
