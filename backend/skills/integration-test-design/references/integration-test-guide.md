# 集成测试编写指南

> 决策记录：`docs/methodology/integration-test-design.md` §2  
> 权威 Rule：[`rules/integration-test-conventions.md`](../../../rules/integration-test-conventions.md)（硬约束，冲突听 Rule）  
> 配套：[mock-strategy.md](./mock-strategy.md)（Mock 边界）、[seeding-guide.md](./seeding-guide.md)（数据）

本指南管集成测试**怎么编**：何时写、写前加载什么、数据准备与隔离、超时控制、断言对齐。执行层（SKILL）在第 4 步落地后点名加载本指南。

---

## 1. 什么时候写集成测试

| 场景 | 写 | 说明 |
|------|----|------|
| 关键链路含「HTTP 入口 → Filter → BFF → 域 provider/facade/service → 真实 Mapper/DB」全路径 | ✅ | 默认触发时机：跨域编排、状态机、事务落库要真实验证时 |
| 命中测试 DB 切换触发器（Rule 必守 1 的四条） | ✅ | 触发器命中后**连 Mapper 测试一起**切 Testcontainers |
| 外部契约保真（`PaymentClient` 请求/回调解析、厂商 adapter HTTP 接口） | ✅（WireMock） | 见 [mock-strategy.md](./mock-strategy.md) |
| 单 Service / 单 Facade 逻辑 | ❌ | `*-impl/src/test/java/` 单元测试（Mock Mapper/Client） |
| BFF 守卫、参数校验、`Result` 包装 | ❌ | `booking-bff-*/src/test/java/`（`MOCK` + MockMvc + `@MockBean XxxApi`） |
| 仅验证「启动不报错」 | ❌ | 属冒烟，不属于用例 |

**判定口诀**：链路里有没有**真实的 Servlet 容器 + 真实 Mapper/DB**？没有就不是集成测试。MockMvc 内部派发，测不到 Filter 完整行为，**禁止冒充**。

---

## 2. 上下文复用（写之前加载）

| # | 资产 | 路径 | 为什么读 |
|---|------|------|---------|
| 1 | 集成测试 Rule | [`rules/integration-test-conventions.md`](../../../rules/integration-test-conventions.md) | 硬约束：位置、触发器、入口形态、Mock 边界、红线 |
| 2 | 三个决策记录 | [integration-test-design.md](../../../docs/methodology/integration-test-design.md) §2 | 决策 A/B/C 的完整推理与反例 |
| 3 | 系统画像集成矩阵 | [system-landscape.md](../../../architecture/system-landscape.md) §四 | 外部依赖（支付/auth/车场/室内导航）的集成方式 |
| 4 | 跨域约定 | [system-landscape.md](../../../architecture/system-landscape.md) §3.6 | V1 同 JVM `@Autowired XxxApi` 经 `app/client` |
| 5 | 详设时序图 + §9 测试策略 | `docs/design/{迭代}/DD-STORY-*.md` | 被测链路的真实调用序列与覆盖目标 |
| 6 | Mock 边界细则 | [mock-strategy.md](./mock-strategy.md) | 本用例该 Mock 什么、不 Mock 什么 |
| 7 | 数据规则 | [seeding-guide.md](./seeding-guide.md) | 种子来源、schema 事实源、共享数据归属 |
| 8 | 现有集成测试范本 | `booking-app/src/test/java/`（如 `it/SpaceQueryRecommendIT`） | 复用基类/工厂/种子，禁止另起炉灶 |

---

## 3. 基建三件套（已落地，此处为使用契约）

| 资产 | 位置 | 用法 |
|------|------|------|
| `AbstractIntegrationTest` | `booking-app/src/test/java/com/hema/booking/app/AbstractIntegrationTest.java` | 集成测试基类：继承 `AbstractMySqlContainerTest`（共用 Testcontainers MySQL），叠加 `RANDOM_PORT` + `TestRestTemplate` + `JdbcTemplate` + `url(path)` + `issueTestAccessToken(...)`（复用真实 `AppTokenService` 签发，不依赖 iam） |
| `TestDataFactory` | `booking-app/src/test/java/com/hema/booking/app/TestDataFactory.java` | 代码构造请求体/DO/DTO；只放**跨用例复用**的构造方法 |
| 种子 SQL | `booking-app/src/test/resources/db/test-data/*.sql` | 静态主数据（车场/区域/车位/厂商配置）；见 seeding-guide |

所有集成测试类**必须继承 `AbstractIntegrationTest`**；禁止每类自建一套配置。外部依赖的 `@MockBean`（`PaymentClient` / `ParkingLotGateway` 等）按**各 IT 实际链路**在测试类上声明——基类不预置固定 `@MockBean`，避免无关 IT 加载多余 Mock。

---

## 4. 编写步骤

```text
1. 选链路：从详设时序图选「含真实 DB 落库」的关键路径，命名 `{链路}IT`
2. 加载资产（§2），确认触发场景（§1）
3. 定 Mock：按 mock-strategy 决策——本用例是「链路通过」还是「契约保真」
4. 定数据：@Sql 前置 / TestDataFactory / 共享种子（seeding-guide）
5. 写断言：对齐 AC 可见结果（HTTP 状态、Result.code、关键 data 字段）
6. mvn test -pl booking-app 跑通；核对单条 < 10s、全量 < 5min
```

类骨架（与 Rule 反模式节的 ✅ 示例一致）：

```java
// booking-app/src/test/java/com/hema/booking/app/it/BookingOrderCreateIT.java
@DisplayName("STORY-2026-S02-0xx AC-01：创建预约全链路落库")
class BookingOrderCreateIT extends AbstractIntegrationTest {

    @Autowired
    private BookingOrderMapper bookingOrderMapper;   // 验证真实落库

    @Test
    void createBookingOrder_persistsRowAndReturnsCode200() {
        // given（种子：lot/space 已在共享 test-data 或 @Sql 前置）
        // when（真实 HTTP → Filter → BFF → order-impl → Mapper/DB）
        ResponseEntity<Result<BookingOrderCreateVO>> resp = restTemplate
                .postForEntity("/api/v1/booking/app/reservations", requestBody, Result.class);
        // then（对齐 AC：code==200 + 查库断言）
        assertThat(resp.getBody().getCode()).isEqualTo(200);
        BookingOrderDO row = bookingOrderMapper.selectByBookingNo("...");
        assertThat(row.getStatus()).isEqualTo(BookingOrderStatus.PENDING_PAYMENT.name());
    }
}
```

`AbstractIntegrationTest` 提供：`restTemplate`（`TestRestTemplate`）、`jdbcTemplate`（清理/断言用）、`url(path)`（构造绝对 URL）、`issueTestAccessToken(...)`（测试 JWT）。外部 `@MockBean` 与 WireMock 在各 IT 按需声明。

---

## 5. 数据准备与隔离清理

### 5.1 为什么 RANDOM_PORT 下不能靠 `@Transactional` 回滚

`RANDOM_PORT` 下测试方法与 HTTP 请求**分属不同线程、不同连接**：`TestRestTemplate` 发起的请求在服务端线程里跑自己的事务，测试方法的 `@Transactional` 边界**覆盖不到**。依赖事务回滚做清理是**必然失效**的（共享的 Testcontainers MySQL 容器还会把「脏数据」留到下一个用例）。

**清理三选一**（优先前两者，禁止依赖事务回滚）：

| 方式 | 用法 | 适用 |
|------|------|------|
| ① 唯一业务标识 | 每用例生成 `userId` / `bookingNo`（`UUID`/时间戳后缀），数据天然不冲突 | 写链路 |
| ② `@Sql` 前后置脚本 | `BEFORE_TEST_METHOD` 插数据、`AFTER_TEST_METHOD` 清理（`DELETE`/`TRUNCATE`） | 需要指定数据形态的用例 |
| ③ 手动清理 | `@AfterEach` 用 `jdbcTemplate` 删用例产生的行 | 兜底 |

```java
@Sql(scripts = {
        "/db/test-data/one-lot-one-space.sql",   // 前置：共享主数据
        "/db/test-data/cleanup-order.sql"        // 后置：清本用例数据
}, executionPhase = Sql.ExecutionPhase.BEFORE_TEST_METHOD)
@Sql(scripts = "/db/test-data/cleanup-order.sql",
        executionPhase = Sql.ExecutionPhase.AFTER_TEST_METHOD)
@Test
void ...() { }
```

### 5.2 隔离原则

- **每用例独立数据**；禁止共享可变 DB 状态
- 只读断言（查库）用 `jdbcTemplate` 或 `Mapper`，**不 Mock** 本链路 Mapper
- 集成测试不依赖用例执行顺序（除明确 `@Order` 的场景）；全量跑前需可重复
- 多用例共享同一 Spring Context（见 §6），容器与 schema 只初始化一次

---

## 6. 超时控制（Rule 必守 5）

| 红线 | 值 | 落地做法 |
|------|-----|---------|
| 单条集成用例 | < 10s | `@Timeout(10)` 兜底；断言尽早失败（先查库再查 HTTP 也行，按链路） |
| booking-app 全量集成测试 | < 5min | 上下文复用：同配置多用例共享单 Context；**`@DirtiesContext` 仅必要时使用** |
| 上下文复用 | 复用 | 不在每类上换 `@SpringBootTest` 配置；Testcontainers 容器跨类共享 |

- Testcontainers 启动（首次拉起容器 + schema 初始化）计入单类首条用例时长，用「共享容器 + 类级 `@BeforeAll`」摊薄
- 网络/外部桩（WireMock）超时用 `WireMock` 的延迟 stub 模拟，不要真 sleep

---

## 7. 断言对齐 AC

| 层 | 断言 |
|----|------|
| HTTP | HTTP 状态 + `Result.code`（业务成败看 `code===200`）+ `message` |
| 数据 | Mapper/jdbcTemplate 查库断言状态、金额、`deleted` 等落库结果 |
| 事件/状态 | 跨域副作用（库存锁定、订单状态迁移）以**可见结果**断言，禁止断言实现细节 |

`@DisplayName` 或注释标明 `STORY-xxx AC-n`；失败类 AC 必须断言具体文案/错误码，禁止只断言「抛异常」。

---

## 8. 反模式

```java
// ❌ 用 MockMvc 冒充集成测试（绕 Servlet 容器 + Filter）
@SpringBootTest @AutoConfigureMockMvc class FakeIT { MockMvc mockMvc; }

// ❌ 集成测试 Mock 本 Story 核心链路
@MockBean InventoryApi // 跨域编排被 Mock，链路未验证

// ❌ 依赖事务回滚清理数据（RANDOM_PORT 下必然失效）
@Test @Transactional void leakData() { restTemplate.postForEntity(...); }

// ❌ 每类自建 @SpringBootTest 配置（上下文无法复用，全量超红线）
@SpringBootTest(webEnvironment = RANDOM_PORT, properties = "...") class XIT { }

// ❌ 固定端口（并发冲突）
@SpringBootTest(webEnvironment = DEFINED_PORT)
```

---

## 9. 与其它测试的边界

| 测试 | 位置 | 判定 |
|------|------|------|
| 单元测试 | `*-impl/src/test/java/` | 无 DB，Mock Mapper/Client |
| BFF API 测试 | `booking-bff-*/src/test/java/` | 无 DB，Mock `XxxApi` |
| 集成测试（本指南） | `booking-app/src/test/java/` | 真实 HTTP + 真实 Mapper/DB，Mock 外部依赖 |
