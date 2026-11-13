# Java 项目约束

读代码或改代码前，先扫一眼 [AGENTS.md](../../AGENTS.md) 与 [architecture/system-landscape.md](../architecture/system-landscape.md)。

## 依赖方向（V1 单体：双 BFF + 单包）

```text
booking-app（@SpringBootApplication，可执行 jar）
    └── 依赖 booking-bff-app、booking-bff-admin、order-impl、inventory-impl、parking-adapter-impl、iot-impl

booking-bff-app / booking-bff-admin  →  @Autowired XxxApi（order / inventory 等）；依赖 hema-common-web
order-impl / inventory-impl        →  parking-adapter-api、iot-api、hema-common-core、booking-common（按需）
```

域间调用：同 JVM 直调 `XxxApi`，经 `app/client` 封装；**V1 不用 OpenFeign**。

## 必守

> 布局与域聚合模块约定见 [project-layout.md](project-layout.md)。

1. **App/Admin BFF 分离**：App HTTP 只在 `booking-bff-app`；Admin HTTP 只在 `booking-bff-admin`
2. **唯一启动类**：`booking-app`；BFF 模块 **不得**含 `main`
3. **api/impl 分离**：`*-api` 仅契约 + DTO；业务在 `*-impl`；**`*-impl` 无 Controller**
4. 车场厂商 API **仅**在 `booking-parking-adapter`（`ParkingLotGateway`）；**硬件 IoT（地锁/摄像头）仅在 `booking-iot`（`IotDeviceGateway`，经 EMQX）**；order/inventory 不直连车场/设备
5. **数据访问**：ORM 为 MyBatis；主键查询允许 MyBatis Plus `BaseMapper`，**其余 SQL 仅 XML**（见 [mybatis-conventions.md](./mybatis-conventions.md)）
6. **领域模型**：默认 **Service + DO + DTO**；复杂可选 **贫血** `domain/model`；状态迁移优先 **Mapper 条件 `UPDATE`**，非「查聚合 → 内存改 → 全量 save」（见 [domain-model-guide.md](../skills/detail-design/references/domain-model-guide.md)）

## 依赖注入写法

- 纯 Bean 依赖：`@RequiredArgsConstructor` + `private final` 字段（Controller / Service / Facade 的主流写法，参照各 Controller）
- 带 `@Value` 配置注入、或需构造期归一化/校验：**手写显式构造器** + `private final` 字段；**禁止 `@Value` 字段注入**（非 final 可变字段，不可测）；把 `@Value` 挪到 `final` 字段也不行——Lombok 生成构造器**不携带** `@Value`（仓库无 `lombok.config`），Spring 按类型解析失败、启动即报错
- 同前缀多个 `@Value` 优先收拢为 `@ConfigurationProperties` 配置类（先例：`inventory-impl/.../config/DeviceMonitorProperties.java`）
- 范本：`inventory-impl/.../app/client/Wxb3dIndoorNavigationClient.java`（手写构造器 + `@Value` 回退 + 构造期归一化）

## 目录归属

| 路径 | 归属 |
|------|------|
| `booking-bff-app/` | App Controller、车主鉴权 Filter、`converter/`（DTO↔VO MapStruct） |
| `booking-bff-admin/` | Admin Controller、运营 Token 校验（iam-server）、`converter/`（DTO↔VO MapStruct） |
| `booking-app/` | `SpringBootApplication`、全局配置、可执行打包 |
| `booking-*-service/*-api/` | `XxxApi`、DTO |
| `booking-*-service/*-impl/app/provider/` | `XxxApiImpl` |
| `booking-*-service/*-impl/app/facade|service|client/` | 编排、域逻辑、跨域/外部 Client |
| `booking-*-service/*-impl/domain/model/` | 可选贫血领域类（复杂 Story）；**写库仍走 Mapper XML** |
| `booking-*-service/*-impl/infrastructure/` | DO、Mapper、Repository、`converter/`（DO↔DTO MapStruct） |
| `booking-parking-adapter/` | 车场系统南向适配 |
| `booking-iot-service/` | 硬件 IoT 南向（EMQX 直连） |
| `booking-common/` | `BookingErrorCode`（BFF 守卫）；缓存/MQ 等横向抽象；**Result/BizException → `hema-common`** |
| `docs/api/booking-bff-app/`、`docs/api/booking-bff-admin/` 等 | OpenAPI 契约 |

## URL

- App：`/api/v1/booking/app/`
- Admin：`/api/v1/booking/admin/`
- BFF 统一 `com.hema.common.core.result.Result<T>`；业务成败看 `code === 200`（见 `rules/exception-and-result.md`）

## BFF 文档注解

- 契约权威：`docs/api/**/openapi.yaml`
- Controller / VO：**中文 JavaDoc** + `@Tag` / `@Operation` / `@Schema`（`swagger-annotations-jakarta`），文案对齐 OpenAPI
- 细则：[layer-guides.md](../skills/feature-coding/references/layer-guides.md) §5.1

## 不做

- V1 不引入 Nacos / OpenFeign / 独立域进程
- 不在 booking-bff-app 暴露 Admin 接口；不在 booking-bff-admin 暴露 App 车主接口（除双端评审过的共用回调）
