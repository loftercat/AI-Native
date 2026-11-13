# 集成测试约定

> 完整方法论与决策记录见 [docs/methodology/integration-test-design.md](../docs/methodology/integration-test-design.md)。  
> 本 Rule 管可执行的集成测试硬约束；流程与质量见 [feature-coding/SKILL.md](../skills/feature-coding/SKILL.md)、[test-quality.md](../skills/feature-coding/references/test-quality.md)。

## 定位

| 测试 | 位置 | 说明 |
|------|------|------|
| 单元测试 | `*-impl/src/test/java/` | Mock Mapper、`XxxApi`、Client；**无 DB** |
| BFF API 测试 | `love-app/src/test/java/` | `@SpringBootTest(MOCK)` + MockMvc；Mock 域 `XxxApi`；**无 DB** |
| **集成测试** | `love-app/src/test/java/` | `@SpringBootTest` **关键链路**；真实 Mapper/DB；Mock 外部依赖 |

**边界**：MockMvc 不是集成测试。`@WebMvcTest` / `@SpringBootTest(MOCK)` 用于 BFF API 测试；集成测试必须 `RANDOM_PORT` + 真实 HTTP。

## 必守

### 1. 测试 DB（决策 A）

- **无 DB 层**（单元 / BFF API）：禁止引入 H2 或 Testcontainers；Mapper 一律 Mock
- **Mapper 测试**（`@MybatisTest`）：Testcontainers MySQL（继承各模块 `AbstractMySqlContainerTest`，`withInitScript` 指向本模块 `src/test/resources/schema.sql`）
- **集成测试**：Testcontainers MySQL（继承 `love-app` `AbstractIntegrationTest`）；**Flyway 自动迁移** `love-app/src/main/resources/db/migration/`；种子数据用 `@Sql` 引用 `db/test-data/*.sql`
- **共享决策**：Mapper 测试与集成测试跑同一批 XML，**共用一套 DB 判定、一个 MySQL 容器**；禁止「Mapper 用 H2、集成用 MySQL」或各模块各自为政
- **schema 事实源**：
  - **运行时 / 集成测试**：`love-app/src/main/resources/db/migration/V{n}__*.sql`（Flyway，**禁止修改已发布脚本**）
  - **Mapper 测试**：`advice-impl` / `profile-impl` 的 `src/test/resources/schema.sql`（本模块表子集，与 Flyway 迁移结果**逐表同构**）
  - **禁止**另造 H2 schema 或分叉 DDL

> **历史说明**：早期方案曾以 H2（`MODE=MySQL`）为默认、命中触发器后切 Testcontainers。本仓库 XML 已普遍使用 MySQL 特有语法（`ST_Distance_Sphere` / `ON DUPLICATE KEY UPDATE` 等），H2 无法承载，故**已统一为 Testcontainers MySQL**，不再保留 H2 路径。下方触发器仅作「为何弃用 H2」的判定依据留存，不再用于「切换」。

**弃用 H2 的判定依据**（命中任一即不应走 H2，本仓库已全部命中）：

```text
① XML 出现 MySQL 特有语法（FOR UPDATE / ON DUPLICATE KEY UPDATE / GROUP_CONCAT / ST_Distance_Sphere / DATE_FORMAT 等）
② Mapper 测试为绕过 H2 而改 SQL 或加 @Disabled（失真最强信号）
③ 需验证事务隔离 / 自动更新时间戳 / 唯一约束冲突行为
④ 表数量 > 10 张，schema 维护成本反超容器成本
```

统一容器镜像（`mysql:8.x`）、统一 connection 复用（基类 `AbstractMySqlContainerTest` / `AbstractIntegrationTest`）、统一种子脚本。

### 2. 测试入口形态（决策 B）

| 层 | 形态 | 位置 |
|----|------|------|
| BFF API 测试 | `@SpringBootTest(webEnvironment = MOCK)` + `@AutoConfigureMockMvc` + `@MockBean XxxApi` | `love-app/src/test/java/` |
| 集成测试 | `@SpringBootTest(webEnvironment = RANDOM_PORT)` + `TestRestTemplate` | `love-app/src/test/java/` |

- 集成测试**必须** `RANDOM_PORT` + `TestRestTemplate`（或 `WebTestClient`）走真实 HTTP + Filter 栈；**禁止**用 MockMvc 冒充集成测试
- **禁止 `DEFINED_PORT`**（固定端口并发冲突）
- `TestRestTemplate` 为本仓库默认（同步单体）；`WebTestClient` 是加分项，不强制

### 3. 外部依赖 Mock 边界（决策 C）

| 依赖 | 集成测试处理 |
|------|--------------|
| 支付系统（`PaymentClient`） | 链路通过性 → `@MockBean`；**回调/请求契约保真 → WireMock** |
| 封闭式车场系统（`ParkingLotGateway` → 厂商 adapter） | 链路通过性 → `@MockBean`；**HTTP 接口契约 → WireMock** |
| iam-server（B 端 Token） | 测试 JWT 或 Mock 校验组件；**不依赖真实认证服务** |
| 室内导航（BFF 直调第三方） | `@MockBean`；契约保真按需 WireMock |

- **`@MockBean` 管「链路通过」**：跨域编排、状态机、DB 事务；**不 Mock 本 Story 核心链路**
- **WireMock 管「外部契约保真」**：`PaymentClient` 请求格式/签名/响应解析/错误码映射、`{厂商}ParkingAdapter` HTTP 接口
- 两者不可混用同一测试方法；`mock-strategy.md` 为权威细则
- **V1 集成测试不依赖 Nacos / 外部支付真实环境**（沿用 `rules/tdd-project-conventions.md`）

### 4. 数据隔离

- 每个用例独立数据；**禁止共享可变 DB 状态**
- 优先 `@Sql(scripts=...)` 或 `TestDataFactory` 构造种子；**RANDOM_PORT 下 `@Transactional` 回滚失效，须显式清理**（`@Sql(AFTER_TEST_METHOD)` 或 `@AfterEach`），不得依赖自动回滚
- 集成测试不依赖用例执行顺序（除明确 `@Order` 场景）

### 5. 运行时长

| 红线 | 值 |
|------|-----|
| 单条集成用例 | < 10s |
| love-app 全量集成测试 | < 5min |
| 上下文复用 | 同一配置多用例复用单 Spring Context；`@DirtiesContext` 仅必要时使用 |

### 6. 命名与追溯

- 集成测试类：`{链路}IT`（如 `BookingOrderCreateIT`），位于 `love-app/src/test/java/`
- `@DisplayName` 或注释标明 `STORY-xxx AC-n`；断言对齐 AC 可见结果（HTTP 状态、`Result.code`、关键 `data` 字段）

## 反模式

```java
// ❌ 用 MockMvc 冒充集成测试（绕 Filter/Servlet 容器）
@SpringBootTest(classes = BffAppTestApplication.class)
@AutoConfigureMockMvc
class FakeIntegrationTest { MockMvc mockMvc; }

// ❌ 固定端口
@SpringBootTest(webEnvironment = DEFINED_PORT)

// ❌ 为绕过 H2 改 XML SQL 或 @Disabled Mapper 测试
// 本仓库已统一 Testcontainers MySQL，不再有 H2 路径；XML 写 MySQL 特有语法直接在容器上跑

// ❌ 集成测试 Mock 本 Story 核心链路
@MockBean InventoryApi // 核心跨域编排被 Mock，链路未验证

// ❌ 各模块 schema 与 love-app 单一事实源分叉
```

```java
// ✅ 集成测试：真实端口 + 真实 HTTP + 外部依赖 Mock
@SpringBootTest(webEnvironment = RANDOM_PORT)
class BookingOrderCreateIT {
    @Autowired TestRestTemplate restTemplate;
    @MockBean PaymentClient paymentClient;      // 链路通过性
    @Autowired BookingOrderMapper bookingOrderMapper; // 验证真实落库
}

// ✅ 契约保真：WireMock 起 HTTP 桩
@Test
void paymentCallback_parsesRequestSignature() {
    wireMockServer.stubFor(post("/callback")
        .willReturn(okJson("{\"code\":200}")));
    // 触发 advice-impl 真实走 PaymentClient HTTP → 断言解析结果
}
```

## 与 Rule 的协作

- 覆盖 `rules/tdd-project-conventions.md`「启动集成」行：本 Rule 为集成测试**唯一权威**；两者冲突时听本 Rule
- 覆盖 `test-quality.md`「集成测试」行：Mock 边界细则以本 Rule 决策 C 为准
- `love-app/pom.xml` 变更（Testcontainers / WireMock 依赖）**必须**经本 Rule 触发条件判定后引入，禁止盲目添加
