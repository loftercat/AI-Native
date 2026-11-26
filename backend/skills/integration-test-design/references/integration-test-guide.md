# 集成测试编写指南（微服务单服务版）

> 决策记录：`docs/methodology/integration-test-design.md` §2
> 权威 Rule：[`rules/integration-test-conventions.md`](../../../rules/integration-test-conventions.md)（硬约束，冲突听 Rule）
> 配套：[mock-strategy.md](./mock-strategy.md)（Mock 边界）、[seeding-guide.md](./seeding-guide.md)（数据）

本指南管微服务架构下**单服务集成测试**怎么编：何时写、写前加载什么、数据准备与隔离、超时控制、断言对齐。

---

## 1. 什么时候写单服务集成测试

| 场景 | 写 | 说明 |
|------|----|------|
| 关键链路含「本服务真实入口 → Filter/拦截器 → Facade/Service → 真实持久化/DB」全路径 | ✅ | 验证本服务内本地事务、真实 SQL、状态机与落库 |
| 下游微服务 / 外部系统远程契约保真（请求路径、透传头、签名、响应解析、错误码处理） | ✅（WireMock / RPC Stub） | 见 [mock-strategy.md](./mock-strategy.md) |
| 单 Service / 单 Facade 纯逻辑 | ❌ | 本服务 `*-impl/src/test/java/` 单元测试（Mock 持久化层与 Client） |
| 纯参数守卫、格式校验、VO 转换 | ❌ | 入口 `@WebMvcTest` + MockMvc 测试（无 DB） |
| 仅验证「启动不报错」 | ❌ | 属冒烟，不属于集成用例 |
| 跨多个真实微服务的完整业务主链路 | ❌（不写进单服务 `*IT`） | 归部署后 `api-blackbox-test`（测试环境真实多服务联调） |

**判定口诀**：本服务测试里有没有**本服务真实入口 + 本服务真实容器 DB**，且**所有进程外下游服务都已隔离**？MockMvc 内部派发测不到完整容器/拦截器行为，**禁止冒充 HTTP 集成测试**。

---

## 2. 上下文复用（写之前加载）

| # | 资产 | 路径 | 为什么读 |
|---|------|------|---------|
| 1 | 集成测试 Rule | [`rules/integration-test-conventions.md`](../../../rules/integration-test-conventions.md) | 硬约束：位置、入口形态、服务发现隔离、Mock 边界、红线 |
| 2 | 三个决策记录 | [integration-test-design.md](../../../docs/methodology/integration-test-design.md) §2 | 决策 A/B/C 的完整推理与反例 |
| 3 | 系统画像通信矩阵与选型 | [system-landscape.md](../../../architecture/system-landscape.md) §3.6 / §四 / §5.4 | 确认下游微服务清单、同步调用协议（P-2）、ORM（P-3）、注册中心关闭方式（E-1） |
| 4 | 下游契约文档 | `docs/api/{下游服务标识}/` 或下游 `*-api` | 确保模拟桩（WireMock/Stub）返回体与真实下游契约一致 |
| 5 | 详设时序图 + §9 测试策略 | `docs/design/{迭代}/DD-STORY-*.md` | 被测链路的真实调用序列与覆盖目标 |
| 6 | Mock 边界细则 | [mock-strategy.md](./mock-strategy.md) | 哪些真实跑、哪些必须模拟隔离 |
| 7 | 数据规则 | [seeding-guide.md](./seeding-guide.md) | 本服务独立 Flyway 迁移、种子数据归属与清理 |
| 8 | 本服务现有集成测试范本 | `{service}-impl/src/test/java/` | 复用本服务基类/工厂/种子，禁止另起炉灶 |

---

## 3. 每服务独立的基建三件套

每个有持久化或需要跑集成测试的微服务各自维护一套（互不共享）：

| 资产 | 位置（按服务） | 用法 |
|------|----------------|------|
| `AbstractIntegrationTest` | `{service}-impl/src/test/java/.../AbstractIntegrationTest.java` | 本服务集成测试基类：继承本服务容器基类（Testcontainers MySQL），加载 `application-test.yml`（关闭外部注册发现），提供 `RANDOM_PORT` + `TestRestTemplate`（HTTP 服务）或入口 Bean + `JdbcTemplate` + 测试鉴权/透传头构造工具 |
| `TestDataFactory` | `{service}-impl/src/test/java/.../TestDataFactory.java` | 代码构造本服务请求体/DO/DTO；只放**本服务跨用例复用**的构造方法 |
| 种子 SQL | `{service}-impl/src/test/resources/db/test-data/*.sql` | 本服务静态主数据；见 seeding-guide |

本服务所有集成测试类**必须继承本服务 `AbstractIntegrationTest`**；禁止每类自建一套启动配置。下游微服务与外部系统的 WireMock / Stub / `@MockBean` 按各 `*IT` 实际依赖声明。

---

## 4. 编写步骤

```text
1. 选链路：从详设时序图选「含本服务真实 DB 落库或下游契约验证」的关键路径，命名 `{Scenario}IT`
2. 加载资产（§2），确认触发场景（§1）与画像 §5.4 选型（P-2 / P-3 / E-1）
3. 定模拟边界：本服务内部全部真实；进程外下游微服务按 P-2 用 WireMock/Stub 隔离；第三方按 mock-strategy 处理
4. 定数据：本服务 Flyway 自动建表 + @Sql 前置 / TestDataFactory / 本服务共享种子
5. 写断言：对齐 AC 可见结果（响应码/字段对齐画像 §3.7 + 查本服务库断言 + 校验发往下游的请求契约）
6. 运行本服务测试（单仓库：`mvn test -pl {service-module} -am`；多仓：`mvn test`）；核对单条 < 10s、单服务全量 < 3min
```

HTTP 微服务类骨架示意（以 `{project}-{domain-a}` 调用下游 `{project}-{domain-b}` 为例）：

```java
// {project}-{domain-a}/{domain-a}-impl/src/test/java/.../it/{Scenario}IT.java
@DisplayName("STORY-{YYYY-Snn}-{序号} AC-01：{domain-a} 创建业务单落库并调用下游 {domain-b}")
class {Scenario}IT extends AbstractIntegrationTest {

    @Autowired
    private {Entity}Mapper entityMapper;   // 验证本服务真实落库

    @Test
    void createEntity_persistsRecordAndCallsDownstream() {
        // given：下游微服务用 WireMock 桩模拟（对齐 docs/api/{project}-{domain-b}/openapi.yaml）
        wireMockServer.stubFor(post("/internal/v1/{service}/{resources}/reserve")
                .willReturn(okJson("{\"code\":200,\"data\":{\"reserved\":true}}")));

        // when：真实 HTTP 进入本服务内部入口 → 业务逻辑 → 落本服务库 → 调下游桩
        ResponseEntity<{Result<T>}> resp = restTemplate
                .postForEntity(url("/internal/v1/{service}/{resources}"), requestBody, {Result}.class);

        // then：断言响应 + 本服务真实落库 + 下游调用符合契约
        assertThat(resp.getBody().getCode()).isEqualTo(200);
        {Entity}DO row = entityMapper.selectByBizNo("...");
        assertThat(row.getStatus()).isEqualTo({Entity}Status.CREATED.name());
        wireMockServer.verify(postRequestedFor(urlEqualTo("/internal/v1/{service}/{resources}/reserve")));
    }
}
```

---

## 5. 数据准备与隔离清理

### 5.1 为什么 `RANDOM_PORT` 下不能靠 `@Transactional` 回滚

`RANDOM_PORT` 下测试方法与 HTTP 请求**分属不同线程、不同连接**：服务端线程跑自己的事务，测试方法的 `@Transactional` **覆盖不到**。依赖事务回滚做清理**必然失效**。

**清理三选一**（优先前两者，禁止依赖事务回滚）：

| 方式 | 用法 | 适用 |
|------|------|------|
| ① 唯一业务标识 | 每用例生成 `userId` / `bizNo`（UUID/时间戳后缀），数据天然不冲突 | 写链路 |
| ② `@Sql` 前后置脚本 | `BEFORE_TEST_METHOD` 插数据、`AFTER_TEST_METHOD` 清理（`DELETE`/`TRUNCATE`） | 需要指定数据形态的用例 |
| ③ 手动清理 | `@AfterEach` 用 `jdbcTemplate` 删本用例产生的行 | 兜底 |

### 5.2 隔离原则

- **每用例独立数据**；禁止共享可变 DB 状态。
- 只读断言（查本服务库）用 `jdbcTemplate` 或持久化访问层，**不 Mock** 本服务持久化层。
- 集成测试不依赖用例执行顺序（除明确 `@Order` 的场景）；全量跑前须可重复。
- 同服务内多用例共享同一 Spring Context（见 §6），容器与 schema 只初始化一次。

---

## 6. 超时控制（Rule 必守 5）

| 红线 | 值 | 落地做法 |
|------|-----|---------|
| 单条集成用例 | < 10s | `@Timeout(10)` 兜底 |
| 单服务全量集成测试 | < 3min | 同服务同配置多用例共享单 Context；**`@DirtiesContext` 仅必要时使用** |
| 上下文复用 | 复用 | 不在每类上换 `@SpringBootTest` 配置；Testcontainers 容器跨类共享 |

- 下游超时/慢响应测试使用 WireMock 延迟 stub 模拟，不要真实 `Thread.sleep`。

---

## 7. 断言对齐 AC

| 层 | 断言 |
|----|------|
| 服务响应 | 状态码、业务码（对齐画像 §3.7）与关键返回字段 |
| 本服务 DB | 持久化层/`jdbcTemplate` 查库断言状态、金额，以及「项目实现」删除分支规定的列（软删支含 `deleted`）等真实落库结果 |
| 下游交互 | 校验对下游微服务的调用路径、关键入参、内部透传头（画像 §5.4 P-5）与下游错误码处理（P-4） |

`@DisplayName` 或注释标明 `STORY-xxx AC-n`；失败类 AC 必须断言具体文案/错误码，禁止只断言「抛异常」。

---

## 8. 反模式

```java
// ❌ 用 MockMvc 冒充 HTTP 集成测试（绕 Servlet 容器 + Filter）
@SpringBootTest @AutoConfigureMockMvc class FakeIT { MockMvc mockMvc; }

// ❌ 单服务集成测试 Mock 本服务内部的 Service / 持久化层
@MockBean {Entity}Mapper

// ❌ 单服务集成测试强依赖真实下游微服务进程或真实注册中心（Nacos/Consul）

// ❌ 依赖事务回滚清理数据（RANDOM_PORT 下必然失效）
@Test @Transactional void leakData() { ... }

// ❌ 固定端口（并发冲突）
@SpringBootTest(webEnvironment = DEFINED_PORT)
```

---

## 9. 与其它测试的边界

| 测试 | 位置 | 判定 |
|------|------|------|
| 单元测试 | 各服务 `*-impl/src/test/java/` | 无 DB，Mock 持久化层与远程 Client |
| 入口 API 测试 | 各 BFF / 领域服务 `src/test/java/` | 无 DB，MockMvc + Mock 下游或 Service |
| 单服务集成测试（本指南） | 各微服务 `src/test/java/` | 本服务真实入口 + 真实容器 DB，**下游微服务与外部系统模拟隔离** |
| 跨服务主链路验证 | `tests/blackbox/`（部署后） | 多微服务真实联调（`api-blackbox-test`） |
