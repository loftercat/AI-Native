# 下游微服务与外部依赖 Mock 策略（微服务单服务版）

> 决策记录：`docs/methodology/integration-test-design.md` §2.3（决策 C）
> 权威 Rule：[`rules/integration-test-conventions.md`](../../../rules/integration-test-conventions.md) 必守 3
> 配套：[integration-test-guide.md](./integration-test-guide.md) §4 步骤 3

本指南是微服务单服务集成测试中「决策 C」的可执行细则：**本服务边界内哪些绝不能 Mock、进程外下游微服务怎么模拟、第三方外部系统什么时候用 `@MockBean` 什么时候用 WireMock**。对同一依赖，两者**不可混用同一测试方法**。

---

## 1. 微服务单服务集成测试的核心边界（铁律）

| 归属 | 规则 | 说明 |
|------|------|------|
| **本服务内部**（入口 Filter/拦截器 → Controller/Provider → Facade → Service → 持久化层 → 本服务容器 DB） | **一律真实，严禁 Mock** | 否则测不到本服务真实 SQL、事务和状态机 |
| **进程外下游微服务**（如 `{project}-{domain-a}` 调 `{project}-{domain-b}`、BFF 调领域微服务） | **必须模拟隔离，不启动真实下游进程** | 保证单服务 `{Scenario}IT` 独立、快速、离线可重复运行 |
| **第三方外部系统**（支付网关、厂商系统、外部认证服务） | **必须模拟隔离** | 区分「链路通过」与「外部契约保真」两条线 |
| **服务注册与配置中心**（Nacos / Consul 等，见画像 §5.4 E-1） | **测试 profile 一律关闭** | 不依赖外部基础设施 |

---

## 2. 两条模拟线（先定线，再选工具）

| 线 | 目标 | 机制 | 验证什么 |
|----|------|------|---------|
| **契约保真（下游微服务推荐默认）** | 验证远程 Client 的真实网络序列化、路径、头透传、超时与错误码解包 | HTTP/OpenFeign（画像 P-2）用 **WireMock** 动态端口起真实 HTTP 桩；RPC（Dubbo/gRPC）用对应框架测试 Stub 或契约测试工具（画像 E-5） | 「本服务真实代码 + 真实 DB + **下游远程调用真实协议层**」 |
| **轻量链路通过** | 聚焦本服务内复杂状态机与多步写库，下游响应极简 | `@MockBean` 替换下游远程 Client Bean | 仅验证本服务编排与落库（仍须另有契约保真用例覆盖远程协议层） |

---

## 3. 判定决策树

```text
该依赖是否属于「当前被测微服务」的内部代码或数据库？
├─ 是 → 严禁 Mock，必须跑本服务真实代码 + 本服务 Testcontainers DB
└─ 否 → 是「进程外下游微服务」还是「第三方外部系统」？
        ├─ 进程外下游微服务（见画像 §3.6 通信矩阵）：
        │   ├─ 画像 §5.4 P-2 为 HTTP（如 OpenFeign / RestClient）→ 优先 WireMock 真实 HTTP 桩（对齐下游 docs/api/{下游服务}/openapi.yaml）
        │   ├─ 画像 §5.4 P-2 为 RPC（如 Dubbo / gRPC）→ 使用框架测试 Stub 或 @MockBean 远程客户端接口
        │   └─ 画像 §5.4 E-5 选定了 Spring Cloud Contract / Pact → 按工具生成与校验契约桩
        └─ 第三方外部系统（第三方支付、外部厂商平台、外部认证中心等）：
            ├─ 需验证请求格式/签名/回调解析/错误码映射/超时处理 → WireMock
            └─ 仅需「它返回一个固定结果」→ @MockBean
```

---

## 4. 常见依赖逐项处理（按画像 §3.6 / §四 映射）

| 依赖 | 类别 | 单服务集成测试处理 | 备注 |
|------|------|--------------------|------|
| **下游领域微服务**（如 `{project}-{domain-a}` 调 `{project}-{domain-b}` 的 `{Domain}Client`） | 进程外下游微服务 | **优先 WireMock**（若 P-2 为 HTTP）：桩响应体严格对齐 `docs/api/{project}-{domain-b}/openapi.yaml`，验证路径、透传头（P-5）与错误解包（P-4）；RPC 协议用对应 Stub / `@MockBean` | 不拉起下游服务进程，不连下游库 |
| **第三方外部服务**（`{domain-a}-impl/app/client/{External}Client`） | 第三方外部系统 | 链路通过性 → `@MockBean {External}Client`；请求签名/回调解析/错误码映射 → **WireMock** | 仅在归属领域服务 `*IT` 中声明 |
| **外部厂商南向平台**（`{project}-adapter` 的 `adapter-impl`） | 第三方外部系统 | 仅在适配微服务 `*IT` 中用 **WireMock** 验厂商 HTTP 契约；上游业务服务测的是「调用 `{project}-adapter`」而非直连厂商 | 隔离南向厂商依赖 |
| **外部认证服务**（如 B 端 Token 校验） | 外部认证系统 | 测试 JWT 或 Mock 校验组件，**不依赖真实认证服务** | 详见 §5 |
| **异步消息中间件**（若已启用画像 E-2） | 基础设施 | 本服务发件箱表/业务表真实验证；MQ Broker 按画像 E-2 选择 Testcontainers Broker 或 Mock Producer | 不依赖共享测试环境 MQ |

---

## 5. 认证与内部透传头处理（对齐画像 §5.4 P-5）

**原则**：单服务集成测试不依赖真实认证服务或真实 API 网关。

| 场景 | 做法 |
|------|------|
| **BFF 集成测试** | 测试配置提供测试签名密钥或 Mock Token 校验组件，在基类提供 `issueUserToken(...)` / `issueAdminToken(...)` 帮助方法，走完整 Filter 栈 |
| **领域微服务集成测试** | 请求按画像 §5.4 **P-5** 带上约定的内部鉴权凭证与身份/追踪透传头（如内部 Token、`X-User-Id`、`X-Trace-Id`）；同时覆盖「缺少或伪造内部凭证被拒绝」的负向用例 |

---

## 6. WireMock 细则（当画像 P-2 为 HTTP 或测外部 HTTP 契约时）

### 6.1 依赖（在目标服务的 `pom.xml` 引入，scope=test）

```xml
<dependency>
  <groupId>org.wiremock</groupId>
  <artifactId>wiremock-standalone</artifactId>
  <scope>test</scope>
</dependency>
```

### 6.2 配置与使用

```java
// 本服务 AbstractIntegrationTest 或具体 {X}IT
protected static WireMockServer wireMockServer;

@BeforeAll
static void startWireMock() {
    wireMockServer = new WireMockServer(0);          // 动态端口，避免并发冲突
    wireMockServer.start();
}

@AfterAll
static void stopWireMock() {
    if (wireMockServer != null) {
        wireMockServer.stop();
    }
}

// 将桩地址注入下游微服务客户端或外部 Client 的 base-url（关闭服务发现后直连桩地址）
@DynamicPropertySource
static void wireMockProperties(DynamicPropertyRegistry registry) {
    registry.add("clients.{domain-b}.base-url", wireMockServer::baseUrl);
    registry.add("clients.{external}.base-url", wireMockServer::baseUrl);
}
```

```java
@Test
@DisplayName("STORY-{迭代}-{序号} AC-0x：下游业务错误码按画像 P-4 正确处理")
void execute_handlesDownstreamBizError() {
    wireMockServer.stubFor(post("/internal/v1/{service}/{resources}/reserve")
            .willReturn(okJson("{\"code\":{下游错误码},\"message\":\"{预期错误文案}\"}")));

    ResponseEntity<{Result<T>}> resp = restTemplate.postForEntity(
            url("/internal/v1/{service}/{resources}"), payload, {Result}.class);
    assertThat(resp.getBody().getCode()).isEqualTo({Domain}ErrorCode.{ERR_ENUM}.getCode());
}
```

### 6.3 要点

- 必须用**动态端口**（`new WireMockServer(0)`），经 `@DynamicPropertySource` 注入 URL，禁止硬编码端口。
- stub 返回 JSON 必须与下游服务 `docs/api/{下游服务标识}/openapi.yaml` **逐字段一致**，防止自说自话导致契约漂移。
- 覆盖失败/超时/5xx 场景：验证下游错误码解包/映射（画像 P-4）与本服务失败回滚/补偿逻辑。
- **跨服务真实联调补位**：单服务 WireMock 只能守住单边契约，多微服务真实串联验收由部署后 `api-blackbox-test` 承担。

---

## 7. 反模式

| ❌ | 为什么 |
|----|--------|
| 在单服务 `*IT` 中 `@MockBean` 本服务自己的 Service 或 Mapper/Repository | 核心持久化与本地事务未验证，沦为假集成测试 |
| 单服务 `*IT` 要求先手动起 3 个下游微服务和本地 Nacos | 脆弱、慢、CI 不可重复 |
| 同一测试方法里对同一个下游既 `@MockBean` 又挂 WireMock | 模拟边界混乱，WireMock 桩永远不会被命中 |
| 手编与下游 OpenAPI 契约不符的假 JSON | 测试全绿但联调必炸 |
