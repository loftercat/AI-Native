# 集成测试约定（微服务版）

> 完整方法论与决策记录见 [docs/methodology/integration-test-design.md](../docs/methodology/integration-test-design.md)。
> 本 Rule 管微服务下可执行的集成测试硬约束；流程与质量见 [feature-coding/SKILL.md](../skills/feature-coding/SKILL.md)、[test-quality.md](../skills/feature-coding/references/test-quality.md)。

## 定位与测试分层

| 测试 | 位置 | 说明 |
|------|------|------|
| 单元测试 | 各服务 `*-impl/src/test/java/` | Mock 持久化层、下游远程客户端、外部 Client；**无 DB** |
| 入口 API 测试 | 各 BFF 或领域服务的 `src/test/java/` | `@SpringBootTest(MOCK)` / `@WebMvcTest` + MockMvc；Mock 下游远程客户端或 Service；**无 DB** |
| **单服务集成测试** | **各服务自己的 `*-impl/src/test/java/`（或 BFF `src/test/java/`）** | `@SpringBootTest` 跑**本服务完整链路**（真实入口 → Service → 真实 DB）；**进程外下游微服务与第三方系统一律模拟隔离** |
| **跨服务主链路验证** | 部署后测试环境 `tests/blackbox/` | 由 `api-blackbox-test`（及可选画像 §5.4 E-5 契约测试）承担多服务联调验证 |

**边界**：MockMvc 不是集成测试。HTTP 服务的单服务集成测试必须 `RANDOM_PORT` + 真实 HTTP；RPC 服务（按画像 §5.4 P-2）按所选框架走真实服务上下文 + 真实 DB。

## 必守

### 1. 每服务独立测试 DB 与迁移事实源（决策 A）

- **无 DB 层**（单元 / 入口 MockMvc 测试）：禁止引入 H2 或 Testcontainers；持久化访问层一律 Mock。
- **持久化层测试**（按画像 §5.4 **P-3** ORM 选型，如 MyBatis 的 `@MybatisTest` 或 JPA 的 `@DataJpaTest`）：使用 Testcontainers（与生产同类型数据库容器，继承本服务容器基类，与本服务迁移脚本同构）。
- **单服务集成测试（`*IT`）**：**每个有库的微服务各自维护独立的** `AbstractIntegrationTest`（Testcontainers）与独立的迁移目录 `{service}-impl/src/main/resources/db/migration/`；种子数据放本服务 `src/test/resources/db/test-data/*.sql`。
- **共享判定**：本服务内持久化测试与集成测试共用同一数据库引擎，**禁止**在项目内混用 H2 与目标数据库，**禁止**跨服务共享同一份 Flyway 迁移目录。
- **禁止修改已发布迁移脚本**；增量改表只能追加新版本号 `V{n}__*.sql`。

**弃用 H2 的判定依据**：
```text
① SQL 含目标数据库特有语法（FOR UPDATE / ON DUPLICATE KEY UPDATE / 地理函数 / 日期函数等）
② 为绕过 H2 而改写 SQL 或加 @Disabled（测试失真信号）
③ 需验证事务隔离 / 自动更新时间戳 / 唯一约束冲突行为
④ 表结构演进后，维护双份 DDL 的成本反超容器成本
```

### 2. 测试入口形态与服务发现隔离（决策 B）

| 层 | 形态 | 位置 |
|----|------|------|
| BFF 入口 API 测试 | `@SpringBootTest(webEnvironment = MOCK)` + `@AutoConfigureMockMvc` + Mock 下游远程客户端 | `{project}-bff-*/src/test/java/` |
| 单服务集成测试（HTTP 入口） | `@SpringBootTest(webEnvironment = RANDOM_PORT)` + `TestRestTemplate`（或 `WebTestClient`） | 各微服务 `src/test/java/` |
| 单服务集成测试（RPC 入口，若 P-2 选 Dubbo/gRPC） | 启动本服务真实 Spring 上下文 + 真实 DB，调用本服务真实 Provider 入口（见画像 §5.4 P-2） | 各微服务 `src/test/java/` |

- HTTP 入口集成测试**必须** `RANDOM_PORT` + 真实 HTTP 走完整 Filter/拦截器栈；**禁止**用 MockMvc 冒充集成测试。
- **禁止 `DEFINED_PORT`**（固定端口并发冲突）。
- **测试期隔离注册与配置中心**：测试 profile（`application-test.yml`）必须关闭服务注册发现与远程配置拉取（具体开关按画像 §5.4 **E-1**），确保单服务 `*IT` 离线可跑、不依赖外部注册中心。

### 3. 下游微服务与外部系统 Mock 边界（决策 C — 微服务核心原则）

在单服务集成测试中，**本服务边界之内一律真实，本服务边界之外一律隔离**：

| 依赖类别 | 单服务集成测试处理 |
|----------|--------------------|
| **本服务内部**（入口 Filter/Controller → Facade → Service → 持久化 → 本服务容器 DB） | **一律真实，禁止 Mock** |
| **进程外下游微服务**（见画像 §3.6 通信矩阵） | **必须模拟隔离**（不拉起真实下游服务）：<br>• 画像 P-2 为 HTTP → 优先 **WireMock** 起动态端口 HTTP 桩（验证请求路径、头透传、反序列化、错误码处理）；仅简单链路可 `@MockBean` 客户端<br>• 画像 P-2 为 RPC（Dubbo/gRPC）→ 使用对应 RPC 测试 Stub 或 `@MockBean` 远程客户端 |
| **第三方外部系统**（见画像 §四） | 链路通过性 → `@MockBean`；HTTP 契约/签名/回调保真 → **WireMock** |
| **异步消息（若已启用画像 E-2）** | 本服务发件箱/落库真实验证；MQ Broker 可用内嵌/Testcontainers 或 Mock Producer，按画像 E-2 决定 |

- 同一测试方法内，`@MockBean` 与 WireMock 不可对同一依赖混用；`mock-strategy.md` 为权威细则。
- **契约漂移防护**：若画像 §5.4 **E-5** 选定了 Spring Cloud Contract / Pact，按对应工具生成与校验契约桩；未选定时须确保模拟桩响应体严格对齐下游服务的 `docs/api/{下游服务标识}/` 契约文档。

### 4. 数据隔离

- 每个用例独立数据；**禁止共享可变 DB 状态**。
- 优先 `@Sql(scripts=...)` 或 `TestDataFactory` 构造种子；**RANDOM_PORT 下 `@Transactional` 回滚失效，须显式清理**（`@Sql(AFTER_TEST_METHOD)` 或 `@AfterEach`），不得依赖自动回滚。
- 集成测试不依赖用例执行顺序（除明确 `@Order` 场景）。

### 5. 运行时长

| 红线 | 值 |
|------|-----|
| 单条集成用例 | < 10s |
| 单服务全量集成测试 | < 3min |
| 上下文复用 | 同一配置多用例复用单 Spring Context；`@DirtiesContext` 仅必要时使用 |

### 6. 命名与追溯

- 集成测试类：`{Scenario}IT` / `{Scenario}ScenarioIT`，位于**归属微服务**的 `src/test/java/`。
- `@DisplayName` 或注释标明 `STORY-xxx AC-n`；断言对齐 AC 可见结果（响应状态/业务码、关键返回字段、本服务真实落库结果）。

## 反模式

```java
// ❌ 用 MockMvc 冒充集成测试（绕 Filter/Servlet 容器）
@SpringBootTest(classes = {Service}Application.class)
@AutoConfigureMockMvc
class FakeIntegrationTest { MockMvc mockMvc; }

// ❌ 固定端口
@SpringBootTest(webEnvironment = DEFINED_PORT)

// ❌ 单服务集成测试 Mock 本服务内部的 Service / 持久化层
@MockBean {Entity}Mapper

// ❌ 单服务集成测试强依赖真实下游微服务进程或真实注册中心

// ❌ 多个微服务共用同一份 Flyway 迁移目录或直连对方数据库验证
```

```java
// ✅ 单服务集成测试（HTTP 协议示意）：真实端口 + 本服务真实 DB + 下游微服务 WireMock 桩
@SpringBootTest(webEnvironment = RANDOM_PORT)
class {Action}IT extends AbstractIntegrationTest {
    @Autowired TestRestTemplate restTemplate;
    @Autowired {Entity}Repository repository; // 验证本服务真实落库

    @Test
    void execute_success() {
        // 下游微服务用 WireMock 桩模拟（响应体对齐 docs/api/{downstream-service}/openapi.yaml）
        wireMockServer.stubFor(post("{internalPath}")
            .willReturn(okJson("{expectedDownstreamBody}")));
        // 调用本服务接口并断言响应（按画像 §3.7）+ 本服务 DB 状态
    }
}
```

## 与 Rule 的协作

- 覆盖 `rules/tdd-project-conventions.md`「单服务集成」行：本 Rule 为集成测试**唯一权威**；两者冲突时听本 Rule。
- 覆盖 `test-quality.md`「集成测试」行：Mock 边界细则以本 Rule 决策 C 为准。
- 各服务构建文件引入 Testcontainers / WireMock / 契约测试依赖前须经本 Rule 与画像 §5.4 判定，禁止盲目添加。
