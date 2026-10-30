# 外部依赖 Mock 策略（@MockBean vs WireMock）

> 决策记录：`docs/methodology/integration-test-design.md` §2.3（决策 C）  
> 权威 Rule：[`rules/integration-test-conventions.md`](../../../rules/integration-test-conventions.md) 必守 3  
> 配套：[integration-test-guide.md](./integration-test-guide.md) §4 步骤 3

本指南是「决策 C」的可执行细则：**什么场景用 `@MockBean` 替 Bean、什么场景用 WireMock 起真实 HTTP 桩、iam-server 怎么处理**。两者**不可混用同一测试方法**。

---

## 1. 两条线（先定线，再选工具）

| 线 | 目标 | 机制 | 验证什么 |
|----|------|------|---------|
| **链路通过** | 跨域编排、状态机、DB 事务成立 | `@MockBean` 替换外部 Bean，stub 返回值 | 「HTTP → Filter → BFF → 域 → 真实 Mapper/DB」**本链路** |
| **契约保真** | 外部 Client 的真实 HTTP 行为 | WireMock 独立端口起 HTTP 桩 | 请求格式/签名/响应解析/错误码映射**外部契约** |

- **本 Story 核心链路不得 Mock**（如集成测试 Mock 掉 `InventoryApi` 就测不到跨域）
- 只有「外部依赖」才有 Mock 空间；内部 `XxxApi`/Mapper 属核心链路，一律真实

---

## 2. 判定决策树

```text
被测点是否涉及外部依赖的「HTTP 契约」？
├─ 否 → 链路通过性 → @MockBean 替换外部 Bean
│       （Service/Facade 用 @Mock；集成测试用 @MockBean）
└─ 是 → 是哪种契约？
        ├─ PaymentClient 请求格式/签名/回调解析/错误码映射 → WireMock
        ├─ {厂商}ParkingAdapter 的 HTTP 接口（入参拼装/响应解析）→ WireMock
        ├─ 支付回调（第三方主动回调本仓库）→ WireMock 反向 stub
        └─ 仅是「它能不能返回」 → @MockBean（链路通过）
```

触发线写进 Rule：`@MockBean` 管「链路通过」，WireMock 管「外部契约保真」。

---

## 3. 四类外部依赖逐项处理

| 外部依赖 | 链路通过性 | 契约保真 | 备注 |
|---------|-----------|---------|------|
| **支付系统**（`order-impl/app/client/PaymentClient`） | `@MockBean PaymentClient` | **WireMock**：请求参数/签名、响应解析、错误码映射；回调解析用例必用 WireMock | `PaymentClient` 在 `order-impl`，集成测试在 `booking-app`，`@MockBean` 直接替换 Spring Bean |
| **封闭式车场系统**（`adapter-api` `ParkingLotGateway` → `adapter-impl` `{厂商}ParkingAdapter`） | `@MockBean ParkingLotGateway` | **WireMock**：厂商 HTTP 接口请求/响应 | ⚠️ **生产 Mock 通道已于 STORY-2026-S02-070（2026-09-15）删除**：`MockParkingLotGateway` / `AdapterMockProperties` / `adapter.mock.*` 均已移除，`ParkingLotGateway` 恒为真实适配器（常驻装配）⇒ **必须**用 `@MockBean` 或在测试配置中自建 stub |
| **iam-server**（B 端 Token，`booking-bff-admin`） | 测试 JWT 或 Mock 校验组件，**不依赖真实认证服务** | 不做真实联调 | 详见 §5 |
| **室内导航系统**（BFF 直调第三方） | `@MockBean` 第三方 Client | 契约保真按需 WireMock | 接入点在 BFF，Mock 在 `booking-app` 上下文同样生效 |

---

## 4. `@MockBean` 细则

### 4.1 语义与位置

- `@MockBean` 替换的是 **Spring 容器里的 Bean**（服务端）；`RANDOM_PORT` 下 `TestRestTemplate` 的请求同样命中 Mock
- 集成测试**公共**的 `@MockBean`（如 `PaymentClient`）放 `AbstractIntegrationTest`；用例级差异用子类/方法内 `@MockBean` 覆盖
- Service/Facade 单元测试用 Mockito `@Mock`（`*-impl`），集成测试用 `@MockBean`（`booking-app`），两者按层区分

### 4.2 禁止

```java
// ❌ 集成测试 Mock 核心链路（跨域/状态机未验证）
@MockBean InventoryApi

// ❌ 一个测试方法里 @MockBean + WireMock 混用（线不清）
```

---

## 5. iam-server（B 端 Token）处理

**原则**：集成测试不依赖真实认证服务（Rule 必守 3；沿用 `rules/tdd-project-conventions.md`）。

| 方式 | 做法 | 适用 |
|------|------|------|
| **测试 JWT（推荐）** | 测试配置提供测试签名密钥（`admin.auth.jwt-secret`），测试用同一密钥签发带 `userId`/角色声明的 JWT，放入 `Authorization` 头 | 需走完整 Filter 栈验证 Admin 链路 |
| Mock 校验组件 | `@MockBean` Admin 端 Token 校验组件（如 `AdminTokenVerifier`） | 链路重点不在鉴权时 |

**统一放 `AbstractIntegrationTest`**：提供 `issueAdminToken(...)` / `issueUserToken(...)` 帮助方法，App 端同理（`AppAuthFilter` 的 `USER_ID_HEADER`）。

> `booking-bff-admin` 落地后，本仓库 `admin` 测试以 `issueAdminToken()` 为准；未落地前不引入真实认证依赖。

---

## 6. WireMock 细则

### 6.1 依赖（由 Rule 触发条件判定后引入，禁止盲目添加）

```xml
<!-- booking-app/pom.xml，scope=test -->
<dependency>
  <groupId>org.wiremock</groupId>
  <artifactId>wiremock-standalone</artifactId>
  <scope>test</scope>
</dependency>
```

> 引入前确认命中「契约保真」场景（Rule 必守 3）；仅链路通过不需要 WireMock。

### 6.2 配置与使用

```java
// AbstractIntegrationTest 或 {X}IT
private static WireMockServer wireMockServer;

@BeforeAll
static void startWireMock() {
    wireMockServer = new WireMockServer(0);          // 动态端口，避免冲突
    wireMockServer.start();
}

@AfterAll
static void stopWireMock() {
    wireMockServer.stop();
}

// 把桩地址注入被测 Client 的配置（如 PaymentClient base-url）
@DynamicPropertySource
static void wireMockProperties(DynamicPropertyRegistry registry) {
    registry.add("pay.client.base-url", wireMockServer::baseUrl);
}
```

```java
@Test
@DisplayName("STORY-xxx AC-0x：支付回调解析真实响应")
void paymentCallback_parsesSignatureAndBody() {
    // 契约保真：真实 HTTP 桩
    wireMockServer.stubFor(post("/callback")
            .withHeader("Content-Type", containing("json"))
            .willReturn(okJson("{\"code\":200,\"data\":{\"paid\":true}}")));

    // 触发 order-impl 真实走 PaymentClient HTTP → 断言解析结果 / 错误码映射
    ResponseEntity<Result<...>> resp = restTemplate.postForEntity("/api/v1/booking/app/pay/callback", payload, Result.class);
    assertThat(resp.getBody().getCode()).isEqualTo(200);
}
```

### 6.3 要点

- 用**动态端口**（`new WireMockServer(0)`），base-url 经 `@DynamicPropertySource` 注入，禁止硬编码端口
- stub 返回 JSON 与 `PaymentClient`/`{厂商}ParkingAdapter` 解析代码的期望**逐字段一致**，否则测的是「解析代码」而非「契约」
- 失败/超时/5xx 类契约用例：stub 返回对应状态码，验证 Client 的错误码映射
- 回调场景（第三方主动调本仓库）：WireMock 反向 stub 验证**本仓库签名校验**对请求的处理

---

## 7. 反模式

| ❌ | 为什么 |
|----|--------|
| 同一测试方法 `@MockBean` + WireMock 混用 | 链路通过线与契约保真线混在一起，谁没验证对说不清 |
| `@MockBean` Mock 本 Story 核心链路 | 集成测试失去意义 |
| 用 WireMock 测「只要它返回某值」 | 场景不涉及 HTTP 契约，杀鸡用牛刀且慢 |
| 硬编码 WireMock 端口 / `DEFINED_PORT` | 并发冲突 |
| 集成测试依赖真实支付/认证服务 | 违反 V1 约束，环境不可重复 |

---

## 8. 一句话记忆

> **`@MockBean` 管「链路通不通」，WireMock 管「外部契约真不真」；核心链路永不 Mock，测试环境永不连真实外部系统。**
