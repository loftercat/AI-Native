---
name: integration-test-design
description: >-
  把关键链路写成 love-app 内可重复的白盒集成/场景测试（*IT/*ScenarioIT，RANDOM_PORT 真实 HTTP），
  只 Mock 外部系统。用于集成测试设计、跨域链路验证、接入真实支付/车场前的链路语义守护等场景。
---

> **模板版说明**：本 Skill 自已落地的源项目抽取为通用模板。文中项目专属值（模块名 `booking-*`、包名 `com.loveforecast`、错误码号段、具体路径与 Story 号）均为**示例**，接入项目时按 [MIGRATION.md](../../../MIGRATION.md) 清单替换；「本仓库」指接入后的目标项目。


# integration-test-design

## 1. 定位

把关键链路写成 `love-app` 内可重复的白盒集成/场景测试——真实 HTTP 请求经鉴权过滤器进入 BFF、调用领域服务、落到真实 Mapper/数据库，只 Mock 外部系统。

- **输入**：已实现业务 Story + 详设（含时序图或 §9）+ 可选 TS（含或不含集成段）
- **输出**：`love-app/src/test/java/` 下 `*IT` / `*ScenarioIT`（继承 `AbstractIntegrationTest`）
- **不做**：单元测试 / BFF API `@WebMvcTest` / MockMvc 测试（归 `feature-coding`）；存量测试审计（`test-quality-audit`）；Bug 修复（`bug-fix`）；改业务实现代码；改 Story/详设正文
- **触发时机**：需验证「关键链路真实 SQL + 事务 + 跨域编排 + 落库」时；接入真实支付/车场前

**与 `feature-coding` 的边界**：`feature-coding` 管单元 / BFF API / Mapper 测试；本 Skill 专管 `love-app` 关键链路 `*IT`/`*ScenarioIT`，是集成测试的权威入口。

## 2. 何时触发

- 已实现业务 Story + 详设时序/§9，需验证跨域编排、状态机、事务落库
- TS 含集成层用例需消费
- 接入真实外部系统前需守住链路语义

**不触发**：单 Service/Facade 逻辑（单元测试）；BFF 守卫/参数校验/`Result` 包装（BFF API 测试）；仅验证「启动不报错」（冒烟，归 `feature-coding`）。

## 3. 前置加载（按序点名）

| # | 资产 | 路径 | 缺失时 |
|---|------|------|--------|
| 1 | 集成测试 Rule | `rules/integration-test-conventions.md` | **阻断** |
| 2 | 三个决策记录 | `docs/methodology/integration-test-design.md` §2 | **阻断** |
| 3 | 集成测试编写指南 | `references/integration-test-guide.md` | **阻断** |
| 4 | Mock 策略指南 | `references/mock-strategy.md` | **阻断** |
| 5 | 种子数据指南 | `references/seeding-guide.md` | **阻断** |
| 6 | 系统画像集成矩阵 | `architecture/system-landscape.md` §四 | 降级并标注 |
| 7 | 当前 Story 详设时序/§9 | `docs/design/{迭代}/DD-STORY-*.md` | **阻断**（AC-09） |
| 8 | 测试规格 TS（若存在） | `docs/test-spec/{迭代}/TS-STORY-*.md` | 不存在则跳过 |

> **缺失阻断提示**：Rule 或任一配套指南（1~5）缺失 → **阻断**，输出「缺集成测试 Rule/指南，无法确定入口形态与 Mock 边界」，不写 `*IT`。
> **无详设阻断**：第 7 项缺失（无详设时序图且无 §9）→ **阻断**，输出「缺详设时序图/§9，无法确定集成链路与类归属」，不输出空 `*IT`。

## 4. 输入

- **必备**：已实现业务 Story（AC/BR）+ 详设（含时序图或 §9）
- **可选**：TS（含或不含集成段）；OpenAPI；schema

## 5. 输出

- `love-app/src/test/java/` 下 `*IT` / `*ScenarioIT`（继承 `AbstractIntegrationTest`）
- 必要时增量补 `TestDataFactory` 方法、共享种子 SQL（`love-app/src/test/resources/db/test-data/`）
- **不产生业务功能代码；不改 Story/详设正文**

## 6. 标准流程

```text
1. 加载资产清单（§3）；Rule 或任一指南缺失 → 阻断；无详设时序/§9 → 阻断
2. TS 集成段判定（AC-03）：
   - TS 含已展开集成层用例（写明主路径/断言/Mock 边界，非「可选」占位）→ 消费该段，HTTP 调用顺序与 TS 一致
   - TS 无集成层用例（或仅标「可选/归 integration-test-design」未展开）→ 按详设时序图 + 系统画像自行设计，或明确跳过（须给理由）
   - 不得新建/改写 TS 冒充 test-spec-alignment
3. 定 Mock（mock-strategy.md）：
   - 链路通过性 → @MockBean 替换外部 Bean（PaymentClient / ParkingLotGateway 等）
   - 外部契约保真 → WireMock 起真实 HTTP 桩
   - 同一测试方法内两条线不可混用
   - 本 Story 核心链路（HTTP → Filter → BFF → 域 XxxApi → 真实 Mapper/DB）不得 Mock
4. 定数据（seeding-guide.md）：
   - 建表：集成测试随 `@SpringBootTest` 由 Flyway 自动迁移 `love-app/src/main/resources/db/migration/`；Mapper 测试用本模块 `{模块}/src/test/resources/schema.sql`（与 Flyway 结果逐表同构）
   - 共享主数据放 `db/test-data/*.sql`；用例数据用 TestDataFactory 构造
   - 每用例独立数据，@Sql 后置或 @AfterEach 清理；禁止依赖 @Transactional 回滚（RANDOM_PORT 下失效）
5. 写断言（对齐 AC）：
   - HTTP：Result.code（业务成败看 code===200）+ message + 关键 data 字段
   - DB：jdbcTemplate/Mapper 查库断言落库结果（状态、金额、deleted）
   - 禁止只 assert 未抛异常
6. 命名：{链路}IT / {链路}ScenarioIT；@DisplayName 标 STORY-xxx AC-n
7. mvn test -pl love-app -am 跑通；核对单条 < 10s、全量 < 5min（Rule 必守 5）
8. 代码审查（合入前）：按 [code-review.md](../../rules/code-review.md) §二 定档（脚本/测试改动通常 L1/L2；核心链路/契约/跨模块 → L3）；按 §三 给全输入，审查人只读、实现者落盘；重点：测试真实性、Mock 边界、稳定性/隔离、数据清理；报告落 docs/reviews/{迭代}/REVIEW-CODE-IT-{Story编号}-{slug}.md；按 §五 档位闭环；L0 例外：文档/路径/重命名/机械移动不送审，回复说明跳过原因
```

## 7. 边界

- **不写**单元测试 / `*ControllerTest`（归 `feature-coding`）
- **不改**业务实现代码
- **禁止**用 MockMvc 冒充集成测试——若被要求「用 `@SpringBootTest(MOCK)` + MockMvc 写 love-app 集成测试」，**拒绝并提示**「MockMvc 不是集成测试，须 RANDOM_PORT + 真实 HTTP」
- **禁止** `DEFINED_PORT`（固定端口并发冲突）
- **禁止** `@MockBean` 本 Story 核心链路（域 `XxxApi` / Mapper）
- **禁止**集成测试依赖真实支付/车场/iam（用 `@MockBean`/WireMock/测试 Token）
- **禁止**依赖 `@Transactional` 回滚清理数据（RANDOM_PORT 下必然失效）

## 8. 延伸阅读

- [docs/methodology/integration-test-design.md](../../docs/methodology/integration-test-design.md)（三决策）
- [integration-test-guide.md](references/integration-test-guide.md)
- [mock-strategy.md](references/mock-strategy.md)
- [seeding-guide.md](references/seeding-guide.md)
- [test-line.md](../../docs/methodology/test-line.md)
