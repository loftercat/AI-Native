# Java 微服务项目约束

读代码或改代码前，先扫一眼 [AGENTS.md](../../AGENTS.md) 与 [architecture/system-landscape.md](../architecture/system-landscape.md)（重点看 §二 服务清单、§3.6 通信矩阵、§5.4 两档技术选型）。

## 服务分层与依赖方向

```text
统一入口（API 网关，可选模块）
    └── 路由转发至 BFF、清理外部伪造请求头、拦截内部路径

对外 HTTP（独立启动服务）
    booking-bff-app / booking-bff-admin
        └── 仅依赖各领域服务 *-api（远程契约）与通用公共库；无业务库

领域微服务（每服务独立启动、独立数据库）
    order-impl / inventory-impl / adapter-impl / iot-impl
        ├── 依赖本服务 *-api + 下游服务 *-api（远程契约）+ 通用公共库
        └── 严禁依赖任何其他服务的 *-impl
```

**服务间同步调用**：严格按画像 §5.4 **P-2** 选定的远程协议（如 OpenFeign / Dubbo / gRPC 等）通过 `*-api` 契约经 `app/client` 封装调用；**严禁假设服务同进程直调**。若画像 P-2 仍为 `[TBD]`，编码与详设前必须阻断请用户拍板。

## 必守底线

> 仓库组织与聚合模块约定见 [project-layout.md](project-layout.md)。

1. **API 网关 + BFF + 领域服务职责分离**：
   - 对外 C 端 / B 端 HTTP 只在对应 BFF（`booking-bff-app` / `booking-bff-admin`）暴露，由 API 网关统一路由；
   - 领域微服务只暴露供服务间互调的**内部远程接口**（按画像 P-2：HTTP 内部 Controller 或 RPC Provider），不直接对外网用户开放。
2. **每服务独立启动与独立数据库**：
   - 每个 BFF 与每个领域服务的 `*-impl` 各自持有独立启动类、独立配置与独立数据源（BFF 通常无业务库）；
   - **严禁跨服务连表查询（JOIN）、严禁跨服务外键、严禁把跨服务调用包进本地 `@Transactional`**；跨服务写一致性按画像 §5.4 **E-3** 执行（未定则阻断）。
3. **契约与实现分离（`*-api` / `*-impl`）**：
   - `*-api` 仅放远程契约接口/客户端、DTO、枚举、域错误码（及按需事件对象）；
   - 严禁跨服务依赖对方 `*-impl` 内部类；外部南向适配（如车场厂商 API、硬件 IoT 网关）须收拢在各自专属适配微服务中，业务域不直连外部厂商。
4. **内部接口防外泄与鉴权底线**：
   - 拆成微服务后内部接口经网络可达，**严禁依赖单体的进程内不可达假设**；
   - 严禁直接信任来自公网客户端的身份/内部请求头；具体隔离方式、内部鉴权机制与透传头名严格按画像 §5.4 **P-5** 执行（未定则阻断）。
5. **公共库防膨胀（`*-common`）**：
   - 严格遵守画像 §5.4 **P-6** 边界；仅放通用横切工具与基础抽象，**严禁放入业务 DTO/DO、业务枚举或具体领域逻辑**，避免微服务退化为紧耦合单体。
6. **数据访问（ORM）**：
   - 按画像 §5.4 **P-3** 选型执行（未定则阻断）；若选用 MyBatis，须遵守 [mybatis-conventions.md](./mybatis-conventions.md)；若选用 JPA/jOOQ 等，按接入时替换的持久化 Rule 执行。
7. **领域模型**：
   - 默认 **Service + DO + DTO**；复杂场景可选 **贫血** `domain/model`；状态迁移优先条件更新，非「查聚合 → 内存改 → 全量覆盖」（见 [domain-model-guide.md](../skills/detail-design/references/domain-model-guide.md)）。

## 依赖注入写法

- 纯 Bean 依赖：`@RequiredArgsConstructor` + `private final` 字段（Controller / Provider / Service / Facade 主流写法）。
- 带 `@Value` 配置注入、或需构造期归一化/校验：**手写显式构造器** + `private final` 字段；**禁止 `@Value` 字段注入**（非 final 可变字段，不可测）；把 `@Value` 挪到 `final` 字段也不行——Lombok 生成构造器**不携带** `@Value`，Spring 按类型解析失败。
- 同前缀多个 `@Value` 优先收拢为 `@ConfigurationProperties` 配置类。

## 典型目录归属（按画像 §二 调整）

| 路径 | 归属 |
|------|------|
| `booking-gateway/`（可选） | API 网关路由、外部不可信头剥离、内部路径拦截 |
| `booking-bff-app/` | 独立启动；C 端对外 Controller、车主鉴权、DTO↔VO 转换、下游远程调用封装 |
| `booking-bff-admin/` | 独立启动；B 端对外 Controller、运营鉴权、DTO↔VO 转换、下游远程调用封装 |
| `booking-*-service/*-api/` | 远程契约客户端/接口、DTO、域错误码（及按 E-4 约定的事件对象） |
| `booking-*-service/*-impl/interfaces/` 或 `app/provider/` | 独立启动类 + 内部远程服务入口（HTTP 内部 Controller 或 RPC Provider，按 P-2） |
| `booking-*-service/*-impl/app/facade\|service\|client/` | 编排、域逻辑、下游微服务/外部系统 Client 封装 |
| `booking-*-service/*-impl/domain/model/` | 可选贫血领域类（复杂 Story） |
| `booking-*-service/*-impl/infrastructure/` | 数据实体 DO、持久化访问层（Mapper/Repository）、DO↔DTO 转换 |
| `booking-*-service/*-impl/src/main/resources/db/migration/` | 本服务独立数据库迁移脚本（每服务各自维护） |
| `booking-common/` | 横切通用工具（严格受画像 P-6 约束；响应/异常公共基建按画像 §3.7） |
| `docs/api/{服务标识}/` | 对外 BFF OpenAPI + 内部服务间接口契约（按 P-2） |

## URL 与接口文档约定

- 对外 BFF URL 前缀以画像 §六 为准（示例：`/api/v1/booking/app/`、`/api/v1/booking/admin/`）；内部接口前缀与防外泄策略以画像 §5.4 P-5 为准（示例：`/internal/v1/...`）。
- 响应格式与业务成败判据以画像 §3.7（P-4）与 [exception-and-result.md](exception-and-result.md) 为准。
- HTTP Controller / VO（含对外 BFF 与内部 HTTP 入口）：**中文 JavaDoc** + `@Tag` / `@Operation` / `@Schema`（`swagger-annotations-jakarta`），文案对齐 OpenAPI（细则见 [layer-guides.md](../skills/feature-coding/references/layer-guides.md) §5.1）。

## 严禁事项

- 严禁跨服务依赖对方 `*-impl` 或绕过远程契约直接读取他服务数据库表。
- 严禁在未拍板画像 §5.4 第一档（P-1 ~ P-6）或命中未定第二档（E-1 ~ E-7）时，由 AI 自行猜测具体中间件或协议写法。
- 严禁在 `booking-bff-app` 暴露 Admin 接口，或在 `booking-bff-admin` 暴露 C 端接口（除双端评审过的共用回调）。
- 严禁将领域服务内部远程路径暴露到公网 API 网关路由。
