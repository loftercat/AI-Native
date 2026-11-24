# 集成测试设计 Skill（integration-test-design）核心思想

> **规划正文**：`skills/integration-test-design/SKILL.md`（✅ 已落地，STORY-2026-S01-005）  
> **配套指南**：`skills/integration-test-design/references/`（✅ 已落地）  
> **横切 Rule**：`rules/integration-test-conventions.md`（✅ 已落地）  
> **测试线全景**：[test-line.md](test-line.md)

---

## 1. 一句话定位

**把单个微服务内「真实入口 → 业务逻辑 → 持久化/独立容器 DB」的关键链路编排成可重复的单服务集成测试（进程外下游微服务与第三方系统一律模拟隔离），并建立「测试 DB / 测试入口 / 模拟边界」三个前置决策的统一规范。**

- **输入**：详设时序图 + 跨服务通信矩阵 + 系统画像（§3.6 / §四 / §5.4）
- **产出**：各微服务 `src/test/java/` 独立集成测试基建（本服务 `AbstractIntegrationTest`、`TestDataFactory`、本服务种子数据、Mock/WireMock 策略）
- **不做**：单元测试 / 入口 MockMvc 测试（`feature-coding` 承担）、多微服务真实联调主链路验证（部署后归 `api-blackbox-test`）、存量测试审计（`test-quality-audit`）、Bug 修复（`bugfix`）
- **触发时机**：需要验证单个微服务内真实 SQL + 本地事务 + 状态机落库 + 下游远程契约保真时

**与 `feature-coding`、`api-blackbox-test` 的边界**：`feature-coding` 管单服务单元与入口 MockMvc 测试；本 Skill 管**单服务**白盒集成测试 `*IT`（真实 DB + 下游微服务模拟隔离）；**跨服务真实主链路**由部署后 `api-blackbox-test`（及可选画像 §5.4 E-5 契约测试）守卫。

---

## 2. 三个前置决策

三个决策**必须在写任何指南/Skill 之前拍板**，否则配套文档会互相矛盾。

### 2.1 决策 A：测试 DB（已落地：全部 Testcontainers MySQL）

**解决什么问题**：测试环境与生产 MySQL 的**保真度**——H2 只近似 MySQL，会漏掉 XML SQL / 事务 / 约束的真实行为，导致测试误报或漏报。

**微服务下每服务独立数据库事实（已取消 H2）**：

| 项 | 约定 |
|----|------|
| 每服务独立数据源 | 每个有库的微服务各自维护独立数据源与独立 Flyway 目录 `{service}-impl/src/main/resources/db/migration/`；测试由 Testcontainers MySQL 注入 |
| 持久化单测 | 按画像 §5.4 P-3 ORM 选型（如 MyBatis `@MybatisTest` / JPA `@DataJpaTest`）+ Testcontainers MySQL |
| 单服务集成测试 | 每个微服务各自维护 `AbstractIntegrationTest`（继承容器基类）+ 测试 profile 关闭外部注册发现（按画像 E-1） |
| schema 初始化 | 单服务集成测试由**本服务 Flyway 自动迁移**；若持久化单测另建 `src/test/resources/schema.sql`，须与本服务 Flyway 结果逐表同构；种子数据由本服务 `*IT` 引用本服务 `db/test-data/*.sql` |

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
| 关键链路单服务集成测试 | 各微服务 `src/test/java/` | **本服务 Testcontainers MySQL** |

**独立迁移原则**：各服务只管理自己独占表的迁移脚本，禁止多个微服务共享同一 Flyway 目录或跨库建测试表。

### 2.2 决策 B：测试入口形态（MOCK vs RANDOM_PORT）

**结论：两层都保留，按服务入口协议适配**：

| 层 | 推荐形态 | 位置 |
|----|----------|------|
| 入口 API 测试 | `@SpringBootTest(MOCK)` / `@WebMvcTest` + MockMvc + Mock 下游远程客户端 | 各 BFF / 领域服务 `src/test/java/` |
| 单服务集成测试（HTTP 入口） | **`RANDOM_PORT` + `TestRestTemplate`（或 `WebTestClient`）** | 各微服务 `src/test/java/` |
| 单服务集成测试（RPC 入口，若 P-2 选 Dubbo/gRPC） | 启动本服务真实 Spring 上下文 + 真实容器 DB，调本服务真实 Provider 入口 | 各微服务 `src/test/java/` |

**禁止 `DEFINED_PORT`**（固定端口并发冲突）；测试 profile 必须关闭外部注册中心（按画像 §5.4 E-1）。

### 2.3 决策 C：下游微服务与外部依赖 Mock 边界

**微服务核心原则**：本服务边界之内一律真实（禁止 Mock 本服务 Service/持久化/DB）；**本服务边界之外（所有进程外下游微服务 + 第三方外部系统）一律模拟隔离**。

| 测试目标 | 模拟形态 |
|----------|----------|
| 单元测试 | Mockito `@Mock`（Mock 持久化层、下游远程 Client、外部 Client） |
| 入口 API 测试 | `@MockBean` 下游远程 Client 或 Service |
| 单服务集成测试 — **进程外下游微服务**（见画像 §3.6） | 画像 P-2 为 HTTP → **优先 WireMock**（对齐下游 OpenAPI）；P-2 为 RPC → RPC 测试 Stub / `@MockBean`；若画像 E-5 选定 SCC/Pact → 按工具生成校验契约桩 |
| 单服务集成测试 — **第三方外部系统**（支付/车场） | 链路通过用 `@MockBean`，请求格式/签名/回调/错误码保真用 **WireMock** |
| 外部认证（iam-server） | 测试 JWT 或 Mock 校验组件，不依赖真实认证服务 |

**跨服务真实联调补位**：单服务集成测试不启动真实下游进程；多微服务真实串联主链路验收由部署后 `api-blackbox-test` 承担。

---

## 3. 上下文工程清单

### 3.1 可直接复用（已存在）

| 资产 | 路径 | 关键内容 |
|------|------|----------|
| 测试分层 Rule | `rules/tdd-project-conventions.md` | 单服务测试分层与关闭注册中心约定 |
| Mock 边界 | `skills/feature-coding/references/test-quality.md` | 本服务内真实，外部与下游模拟隔离 |
| 通信矩阵与外部集成 | `architecture/system-landscape.md` §3.6 / §四 / §5.4 | 下游微服务清单、P-2 调用协议、P-3 ORM、E-1 注册中心、E-5 契约测试 |

### 3.2 需新建（当前缺口）

| 层 | 资产 | 职责 |
|----|------|------|
| 横切 | `rules/integration-test-conventions.md` | 集成测试唯一权威 Rule：位置、Mock 边界、触发器、数据隔离、时长红线 |
| 配套 | `skills/integration-test-design/references/integration-test-guide.md` | 何时写集成测试、上下文复用、`@Sql` 数据准备、隔离清理、超时控制 |
| 配套 | `skills/integration-test-design/references/mock-strategy.md` | `@MockBean` vs WireMock 判定、iam-server 处理 |
| 配套 | `skills/integration-test-design/references/seeding-guide.md` | 种子数据来源、单一 schema 事实源、跨 Story 共享数据归属 |
| 样例 | `docs/design/_golden/` 补集成测试用例 / `docs/test-spec/_golden/` | Few-shot |
| 执行 | `skills/integration-test-design/SKILL.md` | 步骤 1 点名加载上述资产 + 缺失阻断策略 |

> **`docs/test-spec/_golden/` 归属**：由 `test-spec-alignment`（已落地）维护；本 Skill 与其边界：
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
第 3 步：在各目标微服务搭 `{service}-impl/src/test` 基建（本服务 `AbstractIntegrationTest`、`TestDataFactory`、种子 SQL、Testcontainers 配置、WireMock/Stub 配置）
   │
   ▼
第 4 步：写 skills/integration-test-design/SKILL.md（执行层，引用 1~3 步资产 + Golden）
   │
   ▼
第 5 步：联动更新 feature-coding SKILL / tdd rule / methodology readme（声明「单服务集成测试从 integration-test-design 消费，跨服务主链路归 api-blackbox-test」）
```

### 各步验收标准

| 步骤 | 验收 |
|------|------|
| 0 | 三决策成文（本文件 §2 即决策记录） |
| 1 | Rule 可被 Agent 在写任何持久化/集成测试时自查 |
| 2 | 三指南成文，Mock 边界与决策 C 一致 |
| 3 | 在目标微服务中可独立跑通一条最小单服务集成链路（示例：创建预约 → 本服务落库 → 下游库存 WireMock 桩校验） |
| 4 | Skill 步骤 1 资产清单完整，缺失阻断策略明确 |
| 5 | `feature-coding` 不再自行发明集成测试规范 |

---

## 5. 与现有流水线衔接

```text
detail-design（时序图 + §9 测试策略）
        │
        ├──────────────────────────────┐
        ▼                              ▼
test-spec-alignment（已落地）    integration-test-design（决策 + 指南 + 基建 + SKILL）
产出 TS-STORY-*.md               │
        │                          ▼
        └──── 单服务集成用例 ───► 各微服务 `src/test/` 单服务 `*IT`（跨服务主链路 → `api-blackbox-test`）
```

- `feature-coding` 只负责 Story 范围的单元/BFF API 测试；涉及**关键链路集成测试**时切换到本 Skill
- `test-spec-alignment`（测试规格，P0）与本 Skill 并行于 `detail-design` 之后：若 TS 含集成层用例，本 Skill 消费 TS；否则自行设计，见 §3.2 归属说明
- `test-quality-audit`（存量治理）与 `bugfix`（缺陷闭环）是相邻后续 Skill，见 [test-line.md](test-line.md)

---

## 6. 延伸阅读

| 主题 | 文档 |
|------|------|
| 测试线 Skill 全景 | [test-line.md](test-line.md) |
| AI Native 方法论总览 | [docs/methodology/readme.md](readme.md) |
| 功能编码（TDD 流程） | [docs/methodology/feature-coding.md](feature-coding.md) |
| 单元测试质量约定 | [skills/feature-coding/references/test-quality.md](../../skills/feature-coding/references/test-quality.md) |
| 系统画像（集成矩阵） | [architecture/system-landscape.md](../../architecture/system-landscape.md) |
| TDD Rule | `rules/tdd-project-conventions.md` |

---

## 变更记录

| 日期 | 变更 |
|------|------|
| 2026-08-05 | 初版：三个前置决策（测试 DB / 测试入口 / 外部 Mock）+ 上下文工程清单 + 落地步骤 |
| 2026-08-08 | 补充 `test-spec-alignment` 与 `docs/test-spec/_golden/` 归属、流水线衔接 |
