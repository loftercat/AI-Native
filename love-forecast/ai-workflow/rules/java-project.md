# Java 项目约束

读代码或改代码前，先扫一眼 [AGENTS.md](../../AGENTS.md) 与 [architecture/system-landscape.md](../architecture/system-landscape.md)。

## 依赖方向（V1 单体：双 BFF + 单包）

```text
love-app（@SpringBootApplication，可执行 jar）
    └── 依赖 love-app、advice-impl、profile-impl、parking-adapter-impl、iot-impl

love-app  →  @Autowired XxxApi（order / inventory 等）；依赖 love-common-web
advice-impl / profile-impl        →  parking-adapter-api、iot-api、love-common-core、love-common（按需）
```

域间调用：同 JVM 直调 `XxxApi`，经 `app/client` 封装；**V1 不用 OpenFeign**。

## 必守

> 布局与域聚合模块约定见 [project-layout.md](project-layout.md)。

1. **单一 BFF**：对外 HTTP 只在 `love-app`；本项目无 Admin BFF
2. **唯一启动类**：`love-app`；域模块 **不得**含 `main`
3. **api/impl 分离**：`*-api` 仅契约 + DTO；业务在 `*-impl`；**`*-impl` 无 Controller**
4. **LLM 调用仅在 `love-advice`**（`ChatClient`）；`love-profile` 不得直连模型；邮件服务仅 `love-app` 调用
5. **数据访问**：ORM 为 MyBatis；主键查询允许 MyBatis Plus `BaseMapper`，**其余 SQL 仅 XML**（见 [mybatis-conventions.md](./mybatis-conventions.md)）
6. **领域模型**：默认 **Service + DO + DTO**；复杂可选 **贫血** `domain/model`；状态迁移优先 **Mapper 条件 `UPDATE`**，非「查聚合 → 内存改 → 全量 save」（见 [domain-model-guide.md](../skills/detail-design/references/domain-model-guide.md)）

## 依赖注入写法

- 纯 Bean 依赖：`@RequiredArgsConstructor` + `private final` 字段（Controller / Service / Facade 的主流写法，参照各 Controller）
- 带 `@Value` 配置注入、或需构造期归一化/校验：**手写显式构造器** + `private final` 字段；**禁止 `@Value` 字段注入**（非 final 可变字段，不可测）；把 `@Value` 挪到 `final` 字段也不行——Lombok 生成构造器**不携带** `@Value`（仓库无 `lombok.config`），Spring 按类型解析失败、启动即报错
- 同前缀多个 `@Value` 优先收拢为 `@ConfigurationProperties` 配置类（先例：`profile-impl/.../config/DeviceMonitorProperties.java`）
- 范本：`profile-impl/.../app/client/Wxb3dIndoorNavigationClient.java`（手写构造器 + `@Value` 回退 + 构造期归一化）

## 目录归属

| 路径 | 归属 |
|------|------|
| `love-app/` | 唯一 `SpringBootApplication`、Controller、JWT 鉴权 Filter、`converter/`（DTO↔VO MapStruct）、Flyway 迁移入口 |
| `love-{domain}/{domain}-api/` | `XxxApi`、DTO、错误码枚举 |
| `love-{domain}/{domain}-impl/app/provider/` | `XxxApiImpl` |
| `love-{domain}/{domain}-impl/app/facade|service|client/` | 编排、域逻辑、跨域/外部 Client |
| `love-{domain}/{domain}-impl/domain/model/` | 可选贫血领域类（复杂 Story）；**写库仍走 Mapper XML** |
| `love-{domain}/{domain}-impl/infrastructure/` | DO、Mapper、Repository、`converter/`（DO↔DTO MapStruct） |
| `love-common/` | `LoveErrorCode` 基类；缓存等横向抽象；**Result/BizException → `love-common`** |
| `docs/api/love-app/` | OpenAPI 契约 |

## URL

- 对外：`/api/v1/love/app/`（本项目只有 C 端）
- BFF 统一 `com.loveforecast.common.core.result.Result<T>`；业务成败看 `code === 200`（见 `rules/exception-and-result.md`）

## BFF 文档注解

- 契约权威：`docs/api/**/openapi.yaml`
- Controller / VO：**中文 JavaDoc** + `@Tag` / `@Operation` / `@Schema`（`swagger-annotations-jakarta`），文案对齐 OpenAPI
- 细则：[layer-guides.md](../skills/feature-coding/references/layer-guides.md) §5.1

## 不做

- V1 不引入 Nacos / OpenFeign / 独立域进程
- 不在 love-app 暴露域内部实现；跨域调用只走 `*-api`；本项目无 Admin 端
