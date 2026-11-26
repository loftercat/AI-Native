---
name: integration-test-design
description: >-
  把单个微服务内的关键链路写成可重复的白盒集成/场景测试（*IT/*ScenarioIT，独立容器 DB，
  进程外下游微服务与外部系统一律模拟隔离）。用于单服务集成测试设计、真实 SQL/事务/落库验证、
  下游微服务契约保真守护等场景。
---

# integration-test-design（微服务单服务集成测试）

## 1. 定位

把**单个微服务内**的关键链路写成可重复的白盒集成/场景测试——真实请求经本服务完整入口栈进入业务逻辑、落到本服务真实持久化层与独立容器数据库，**本服务边界之外的下游微服务与第三方系统一律模拟隔离**。

- **输入**：已实现业务 Story + 详设（含时序图或 §9）+ 可选 TS（含或不含集成段）
- **输出**：归属微服务 `*-impl/src/test/java/`（或 BFF `src/test/java/`）下 `*IT` / `*ScenarioIT`（继承本服务 `AbstractIntegrationTest`）
- **不做**：单元测试 / `@WebMvcTest` MockMvc 测试（归 `feature-coding`）；多微服务真实联调主链路验证（部署后归 `api-blackbox-test`）；存量测试审计（`test-quality-audit`）；Bug 修复（`bugfix`）；改业务实现代码；改 Story/详设正文
- **触发时机**：需验证「本服务真实入口 + SQL + 本地事务 + 落库 + 下游远程调用契约」时

**与 `feature-coding`、`api-blackbox-test` 的边界**：
- `feature-coding` 管单服务的单元测试 / 入口 MockMvc 测试 / 持久化单测；
- 本 Skill 专管**单服务**白盒集成测试 `*IT`（真实 DB + 模拟下游微服务）；
- **跨微服务完整主链路**在测试环境部署后由 `api-blackbox-test`（及可选画像 §5.4 E-5 契约测试）验证。

## 2. 何时触发

- 已实现业务 Story + 详设时序/§9，需验证本服务内真实落库、本地事务、状态机与下游远程调用契约
- TS 含单服务集成层用例需消费
- 接入真实下游服务或外部第三方前需守住契约边界

**不触发**：单 Service/Facade 逻辑（单元测试）；纯参数守卫/VO 转换（BFF MockMvc 测试）；仅验证「启动不报错」（冒烟，归 `feature-coding`）。

## 3. 前置加载（按序点名）

| # | 资产 | 路径 | 缺失时 |
|---|------|------|--------|
| 1 | 集成测试 Rule | `rules/integration-test-conventions.md` | **阻断** |
| 2 | 三个决策记录 | `docs/methodology/integration-test-design.md` §2 | **阻断** |
| 3 | 集成测试编写指南 | `references/integration-test-guide.md` | **阻断** |
| 4 | Mock 策略指南 | `references/mock-strategy.md` | **阻断** |
| 5 | 种子数据指南 | `references/seeding-guide.md` | **阻断** |
| 6 | 系统画像（通信矩阵、外部系统与 §5.4 选型） | `architecture/system-landscape.md` §3.6 / §四 / §5.4 | 第一档（P-1~P-6）或本阶段命中的 E-1 / E-5 仍为 `[TBD]` 时 **阻断** |
| 7 | 当前 Story 详设时序/§9 | `docs/design/{迭代}/DD-STORY-*.md` | **阻断**（AC-09） |
| 8 | 测试规格 TS（若存在） | `docs/test-spec/{迭代}/TS-STORY-*.md` | 不存在则跳过 |

> **缺失阻断提示**：Rule 或任一配套指南（1~5）缺失 → **阻断**，输出「缺集成测试 Rule/指南，无法确定入口形态与 Mock 边界」，不写 `*IT`。
> **无详设阻断**：第 7 项缺失（无详设时序图且无 §9）→ **阻断**，输出「缺详设时序图/§9，无法确定集成链路与服务归属」，不输出空 `*IT`。

## 4. 输入

- **必备**：已实现业务 Story（AC/BR）+ 详设（含时序图或 §9）
- **可选**：TS（含或不含集成段）；对外/内部接口契约（`docs/api/{服务标识}/`）；schema

## 5. 输出

- 归属微服务 `src/test/java/` 下 `*IT` / `*ScenarioIT`（继承本服务 `AbstractIntegrationTest`）
- 必要时增量补本服务 `TestDataFactory` 方法、本服务共享种子 SQL（`src/test/resources/db/test-data/`）
- **不产生业务功能代码；不改 Story/详设正文**

## 6. 标准流程

```text
1. 加载资产清单（§3）；Rule 或任一指南缺失 → 阻断；无详设时序/§9 → 阻断；画像 §5.4 第一档（P-1~P-6）或本阶段命中的 E-1（服务注册配置隔离）/ E-5（契约测试）为 `[TBD]` → 阻断
2. TS 集成段判定（AC-03）：
   - TS 含已展开单服务集成层用例（写明主路径/断言/Mock 边界，非「可选」占位）→ 消费该段
   - TS 无集成层用例（或仅标「可选/归 integration-test-design」未展开）→ 按详设时序图 + 系统画像自行设计，或明确跳过（须给理由）
   - 不得新建/改写 TS 冒充 test-spec-alignment
3. 定 Mock 与下游模拟边界（mock-strategy.md）：
   - 本服务内部链路（入口 → Facade → Service → 持久化 → 本服务容器 DB）一律真实，不得 Mock
   - 进程外下游微服务（见画像 §3.6 通信矩阵）必须模拟隔离：
     · 画像 P-2 为 HTTP/OpenFeign → 优先 WireMock 起动态端口 HTTP 桩（对齐下游 docs/api/{下游服务}/openapi.yaml）
     · 画像 P-2 为 Dubbo/gRPC → 使用对应 RPC 测试 Stub 或 @MockBean 远程客户端
   - 第三方外部系统（支付/外部平台/外部认证）→ 链路通过性用 @MockBean，HTTP 契约保真用 WireMock
   - 同一测试方法内对同一依赖不可混用 @MockBean 与 WireMock
   - 若画像 §5.4 E-5 选定了自动化契约测试（Spring Cloud Contract / Pact），按所选工具生成/校验契约桩
4. 定数据与环境隔离（seeding-guide.md）：
   - 建表：本服务 `@SpringBootTest` 由本服务 Flyway 自动迁移 `{service}-impl/src/main/resources/db/migration/`
   - 环境隔离：测试 profile 关闭服务注册发现与远程配置（按画像 E-1），确保离线可跑
   - 共享主数据放本服务 `src/test/resources/db/test-data/*.sql`；用例数据用本服务 `TestDataFactory` 构造
   - 每用例独立数据，@Sql 后置或 @AfterEach 清理；禁止依赖 @Transactional 回滚（RANDOM_PORT 下失效）
5. 写断言（对齐 AC）：
   - 响应：状态码、业务码与关键返回字段（对齐画像 §3.7）
   - DB：查本服务真实容器库断言落库结果（状态、金额，以及「项目实现」删除分支规定的列；仅软删支断言 `deleted`）
   - 下游交互：必要时断言 WireMock/Stub 收到符合契约的请求路径、透传头（P-5）与入参
   - 禁止只 assert 未抛异常
6. 命名：{Scenario}IT / {链路}ScenarioIT；@DisplayName 标 STORY-{迭代}-{序号} AC-n
7. 运行本服务集成测试（单仓库多服务用 `mvn test -pl {service-module} -am`，多仓用 `mvn test`）；核对单条 < 10s、单服务全量 < 3min
8. 代码审查（合入前）：按 [code-review.md](../../rules/code-review.md) §二 定档（通常 L1/L2；核心链路/契约 → L3）；报告落 docs/reviews/{迭代}/REVIEW-CODE-IT-{Story编号}-{slug}.md
```

## 7. 边界

- **不写**单元测试 / `*ControllerTest`（归 `feature-coding`）
- **不改**业务实现代码
- **禁止**用 MockMvc 冒充 HTTP 集成测试——若被要求「用 `@SpringBootTest(MOCK)` + MockMvc 写集成测试」，**拒绝并提示**「MockMvc 不是集成测试，须 RANDOM_PORT + 真实 HTTP」
- **禁止** `DEFINED_PORT`（固定端口并发冲突）
- **禁止** Mock 本服务内部的 Service / 持久化层 / 本服务 DB
- **禁止**单服务集成测试强依赖真实下游微服务进程、真实注册中心（Nacos/Consul）或真实第三方外部环境
- **禁止**依赖 `@Transactional` 回滚清理数据（RANDOM_PORT 下必然失效）

## 8. 延伸阅读

- [docs/methodology/integration-test-design.md](../../docs/methodology/integration-test-design.md)（三决策）
- [integration-test-guide.md](references/integration-test-guide.md)
- [mock-strategy.md](references/mock-strategy.md)
- [seeding-guide.md](references/seeding-guide.md)
- [test-line.md](../../docs/methodology/test-line.md)
