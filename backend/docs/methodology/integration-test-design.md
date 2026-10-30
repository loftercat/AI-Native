# 集成测试设计 Skill（integration-test-design）核心思想

> **规划正文**：`skills/integration-test-design/SKILL.md`（✅ 已落地，STORY-2026-S01-005）  
> **配套指南**：`skills/integration-test-design/references/`（✅ 已落地）  
> **横切 Rule**：`rules/integration-test-conventions.md`（✅ 已落地）  
> **测试线全景**：[test-line.md](test-line.md)

---

## 1. 一句话定位

**把「双 BFF + 域 + Mapper + 外部依赖」的真实链路在 `booking-app` 里编排成可重复的集成测试，并建立「测试 DB / 测试入口 / 外部 Mock」三个前置决策的统一规范。**

- **输入**：详设时序图 + 跨域调用矩阵 + 系统画像集成矩阵
- **产出**：`booking-app/src/test/java/` 集成测试方案 + 基建（BaseIT、TestDataFactory、种子数据、Mock 策略）
- **不做**：单元测试 / BFF API 测试（`feature-coding` 承担）、存量测试审计（`test-quality-audit`）、Bug 修复（`bug-fix`）
- **触发时机**：V1 末期接入真实支付/车场前，或需要验证「关键链路真实 SQL + 事务 + 约束」时

**与 `feature-coding` 的边界**：`feature-coding` 的集成测试是「按需、Mock 外部支付/车场」；本 Skill 专管**真实编排与保真策略**，是集成测试的权威入口。

---

## 2. 三个前置决策

三个决策**必须在写任何指南/Skill 之前拍板**，否则配套文档会互相矛盾。

### 2.1 决策 A：测试 DB（已落地：全部 Testcontainers MySQL）

**解决什么问题**：测试环境与生产 MySQL 的**保真度**——H2 只近似 MySQL，会漏掉 XML SQL / 事务 / 约束的真实行为，导致测试误报或漏报。

**当前仓库事实（已取消 H2）**：

| 项 | 现状 |
|----|------|
| `booking-app` 数据源 | `jdbc:mysql://localhost:3306/booking`（运行时）；测试由 Testcontainers MySQL 注入 |
| Mapper 测试 | `@MybatisTest` + `@AutoConfigureTestDatabase(replace = NONE)` + Testcontainers MySQL（`order-impl` / `inventory-impl` 各一个 `AbstractMySqlContainerTest` 基类） |
| 集成测试 | `booking-app` 集成测试继承 `AbstractIntegrationTest`（其再继承 `AbstractMySqlContainerTest`），`RANDOM_PORT` + Testcontainers MySQL |
| schema 初始化 | Mapper 测试：`withInitScript("schema.sql")`（`order-impl` / `inventory-impl` 本模块表子集）；集成测试：`@SpringBootTest` 启动时 **Flyway 自动迁移** `booking-app/src/main/resources/db/migration/`；种子数据由各 `*IT` 的 `@Sql` 引用 `db/test-data/*.sql` |
| 根 pom | `testcontainers-bom`（2.0.5）优先于 spring-boot-dependencies 声明；`commons-lang3` 显式升至 3.14 |

**兼容性风险分层**（已不存在 H2 近似问题，MySQL 直接验证真实行为）：

| 层 | 表现 | 危险度 |
|----|------|--------|
| 1. MySQL 特有语法（`FOR UPDATE`、`ON DUPLICATE KEY UPDATE`、`GROUP_CONCAT`、`DATE_FORMAT`） | MySQL 直接执行 | 中（可发现） |
| 2. 语义行为（`TIMESTAMP` 自动更新、事务隔离级别、唯一约束冲突文案、字符集排序） | MySQL 直接保真 | **无失真** |
| 3. DDL/schema 方言（`DATETIME(6)`、`JSON` 类型、`TINYINT(1)`） | MySQL 直接建表 | 无分叉 |

**结论：全部走 MySQL（Testcontainers 隔离，不依赖本机库）**：

| 层 | 测试 | DB |
|----|------|-----|
| 单元测试 | Service/Facade/Converter（Mock Mapper） | **无 DB**（0 依赖） |
| BFF API 测试 | `@WebMvcTest` / Mock `XxxApi` | **无 DB** |
| Mapper 测试 | `@MybatisTest`（验证 XML SQL 真实可执行） | **Testcontainers MySQL** |
| 关键链路集成测试 | `booking-app/src/test/` | **Testcontainers MySQL** |

**共享决策原则**：Mapper 测试与集成测试跑同一批 XML，**共用一套 DB 判定、一个 MySQL 容器**；Mapper 测试 schema 与 Flyway 迁移结果逐表同构，禁止各自为政（同一 SQL 一边绿一边红 = 谁都没验证对）。

**配套动作（已落地）**：运行时与集成测试由 Flyway 管理 `booking-app/src/main/resources/db/migration/`；`order-impl` / `inventory-impl` 各保留本模块 `schema.sql` 供 `@MybatisTest` 使用，须与 Flyway 结果逐表同构。

### 2.2 决策 B：测试入口形态（MOCK vs RANDOM_PORT）

**对比**：

| 维度 | `@SpringBootTest`（webEnvironment=**MOCK**）+ MockMvc | `@SpringBootTest`（webEnvironment=**RANDOM_PORT**）+ `TestRestTemplate` / `WebTestClient` |
|------|------------------------------------------------------|--------------------------------------------------------------------------|
| 是否 bind 端口 | ❌ 否，内部派发 DispatcherServlet | ✅ 真实监听随机端口 |
| 是否走完整 Filter 栈 | ⚠️ 需显式配置 | ✅ 完整（`AppAuthFilter` 鉴权、CORS 等） |
| 是否走真实 HTTP 序列化 | ❌ 内部 dispatch | ✅ 真实序列化/反序列化 |
| 是否启动 Servlet 容器 | ❌ | ✅ |
| 能否验证「启动级真实链路」 | 不能 | 能 |
| DB 要求 | 可无 DB（Mock 上游） | 通常要真实 DB |
| 速度 | 快 | 稍慢（容器启动开销） |

**结论：两层都保留，不二选一**：

| 层 | 推荐形态 | 位置 |
|----|----------|------|
| BFF API 测试（现状） | `@SpringBootTest(MOCK)` + MockMvc + `@MockBean XxxApi` | 保持不变（快、无 DB、测 Controller 守卫） |
| 关键链路集成测试（新） | **`RANDOM_PORT` + `TestRestTemplate`** | `booking-app/src/test/java/` |

理由：集成测试要验证「HTTP 入口 → Filter 鉴权 → BFF → 域 provider/facade/service → 真实 Mapper/DB」全链路成立，MockMvc 绕过真实 Servlet 容器和 Socket，测不到 Filter 完整行为，不叫集成测试。同步单体用 `TestRestTemplate` 足够；`WebTestClient` 是加分项。**禁止 `DEFINED_PORT`**（固定端口并发冲突）。

### 2.3 决策 C：外部依赖 Mock 形态（@MockBean vs WireMock）

**仓库外部依赖**（system-landscape §四）：支付系统（`PaymentClient`）、iam-server（B 端 Token）、封闭式车场系统（`ParkingLotGateway` → 厂商 adapter）、室内导航（BFF 直调）。

**选项对比**：

| 形态 | 机制 | 优点 | 缺点 | 适用 |
|------|------|------|------|------|
| `@MockBean` / `@Mock` | Spring 容器内替换 Bean，stub 方法返回值 | 简单、快、零配置 | 完全绕过 Client 的 HTTP 序列化/超时/重试/错误映射 | 链路通过性测试（Service/Facade/BFF） |
| **WireMock** | 独立端口起 HTTP 桩，返回预置 JSON | Client 走真实 HTTP，能验证请求格式/签名/响应解析/错误码映射 | 慢一点、需维护 wiremock 映射 JSON | **Client / Adapter 契约保真测试**（`PaymentClient`、`{厂商}ParkingAdapter`） |
| MockWebServer（OkHttp） | 轻量 HTTP 桩 | 更轻量、直接断言请求 | 生态不如 WireMock 完善 | 底层请求/响应验证（可选） |

**结论：按「外部契约 vs 链路通过」分层，不全局统一**：

| 测试目标 | Mock 形态 |
|----------|-----------|
| Service / Facade 单元测试 | Mockito `@Mock`（Mock `XxxApi`、Mapper、Client）—— 现状 |
| BFF API 测试 | `@MockBean XxxApi` —— 现状 |
| 集成测试「链路通过性」（跨域编排、状态机、DB 事务） | `@MockBean` 替换 `PaymentClient` / `ParkingLotGateway` —— **不 Mock 本 Story 核心链路** |
| 集成测试「外部契约保真」（`PaymentClient` 请求/回调解析、`{厂商}ParkingAdapter` HTTP 接口、支付回调） | **WireMock** 起真实 HTTP 桩 |
| iam-server Token 校验 | 集成测试提供测试 JWT（或 Mock 校验组件），**不依赖真实认证服务** |

**边界写入 `mock-strategy.md`**：`@MockBean` 管「链路通过」，WireMock 管「外部契约」，两者不可混用。当前 `feature-coding` 已强制「V1 集成测试不依赖 Nacos / 外部支付真实环境（Mock Client）」——本决策在其之上补齐「何时用 WireMock 做保真」。

---

## 3. 上下文工程清单

### 3.1 可直接复用（已存在）

| 资产 | 路径 | 关键内容 |
|------|------|----------|
| 测试分层 Rule | `rules/tdd-project-conventions.md` | 集成测试位置 `booking-app/src/test/java/`；Mock Client |
| Mock 边界 | `skills/feature-coding/references/test-quality.md` | 集成测试 Mock `PaymentClient` / `ParkingLotGateway`，不 Mock 核心链路 |
| 集成矩阵 | `docs/architecture/system-landscape.md` §四 | 支付/iam-server/车场/室内导航的集成方式 |
| 跨域约定 | `docs/architecture/system-landscape.md` §3.6 | V1 同 JVM `@Autowired XxxApi` 经 `app/client` |
| 集成测试样板 | `booking-bff-app/.../AppReservationControllerTest.java` | `@SpringBootTest(classes=...)` + `@AutoConfigureMockMvc` + `@MockBean` |
| 启动配置 | `booking-app/src/main/resources/application.yml` | MySQL（`localhost:3306/booking`）、schema.sql、MyBatis XML |
| 聚合模块 | `booking-app/pom.xml` | 唯一 `@SpringBootApplication` |

### 3.2 需新建（当前缺口）

| 层 | 资产 | 职责 |
|----|------|------|
| 横切 | `rules/integration-test-conventions.md` | 集成测试唯一权威 Rule：位置、Mock 边界、触发器、数据隔离、时长红线 |
| 配套 | `skills/integration-test-design/references/integration-test-guide.md` | 何时写集成测试、上下文复用、`@Sql` 数据准备、隔离清理、超时控制 |
| 配套 | `skills/integration-test-design/references/mock-strategy.md` | `@MockBean` vs WireMock 判定、iam-server 处理 |
| 配套 | `skills/integration-test-design/references/seeding-guide.md` | 种子数据来源、单一 schema 事实源、跨 Story 共享数据归属 |
| 样例 | `docs/design/_golden/` 补集成测试用例 / `docs/test-spec/_golden/` | Few-shot |
| 执行 | `skills/integration-test-design/SKILL.md` | 步骤 1 点名加载上述资产 + 缺失阻断策略 |

> **`docs/test-spec/_golden/` 归属**：由 `test-spec-alignment`（未落地）维护；本 Skill 与其边界待定：
>
> - TS 模板**含集成层用例** → 本 Skill **消费** `TS-STORY-*.md` 中的集成测试段落，不重复设计用例
> - TS 模板**仅单元/API 层** → 本 Skill **自行设计**集成用例，仅参考 `_golden/` 的文档格式

---

## 4. 落地步骤（依赖拓扑）

```text
第 0 步：拍板三个决策（本文件 §2）—— 先于一切
   │
   ▼
第 1 步：新建 rules/integration-test-conventions.md（横切 Rule：先定约束，含切换触发器）
   │
   ▼
第 2 步：写 `skills/integration-test-design/references/` 三份配套指南
   │
   ▼
第 3 步：搭 booking-app/src/test 基建（BaseIT、TestDataFactory、种子 SQL、Testcontainers 配置、WireMock 配置）
   │
   ▼
第 4 步：写 skills/integration-test-design/SKILL.md（执行层，引用 1~3 步资产 + Golden）
   │
   ▼
第 5 步：联动更新 feature-coding SKILL / tdd rule / methodology readme（声明「集成测试从 integration-test-design 消费」）
```

### 各步验收标准

| 步骤 | 验收 |
|------|------|
| 0 | 三决策成文（本文件 §2 即决策记录） |
| 1 | Rule 可被 Agent 在写任何 Mapper/集成测试时自查（含 4 条触发器） |
| 2 | 三指南成文，Mock 边界与决策 C 一致 |
| 3 | `mvn test` 在 `booking-app` 可跑通一条最小集成链路（示例：创建预约 → Mapper 落库 → 查回） |
| 4 | Skill 步骤 1 资产清单完整，缺失阻断策略明确 |
| 5 | `feature-coding` 不再自行发明集成测试规范 |

---

## 5. 与现有流水线衔接

```text
detail-design（时序图 + §9 测试策略）
        │
        ├──────────────────────────────┐
        ▼                              ▼
test-spec-alignment（未落地）    integration-test-design（决策 + 指南 + 基建 + SKILL）
产出 TS-STORY-*.md               │
        │                          ▼
        └──── 集成层用例（若有）──► booking-app/src/test/ 集成测试
```

- `feature-coding` 只负责 Story 范围的单元/BFF API 测试；涉及**关键链路集成测试**时切换到本 Skill
- `test-spec-alignment`（测试规格，P0）与本 Skill 并行于 `detail-design` 之后：若 TS 含集成层用例，本 Skill 消费 TS；否则自行设计，见 §3.2 归属说明
- `test-quality-audit`（存量治理）与 `bug-fix`（缺陷闭环）是相邻后续 Skill，见 [test-line.md](test-line.md)

---

## 6. 延伸阅读

| 主题 | 文档 |
|------|------|
| 测试线 Skill 全景 | [test-line.md](test-line.md) |
| AI Native 方法论总览 | [docs/methodology/readme.md](readme.md) |
| 功能编码（TDD 流程） | [docs/methodology/feature-coding.md](feature-coding.md) |
| 单元测试质量约定 | [skills/feature-coding/references/test-quality.md](../../skills/feature-coding/references/test-quality.md) |
| 系统画像（集成矩阵） | [docs/architecture/system-landscape.md](../../architecture/system-landscape.md) |
| TDD Rule | `rules/tdd-project-conventions.md` |

---

## 变更记录

| 日期 | 变更 |
|------|------|
| 2026-08-05 | 初版：三个前置决策（测试 DB / 测试入口 / 外部 Mock）+ 上下文工程清单 + 落地步骤 |
| 2026-08-08 | 补充 `test-spec-alignment` 与 `docs/test-spec/_golden/` 归属、流水线衔接 |
