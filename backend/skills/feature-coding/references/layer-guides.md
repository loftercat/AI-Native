# 分层编码指引（Java）

> `feature-coding` 步骤 6 进入对应层前按需读取。对应公司级 `api-layer`、`service-layer`、`integration-client`、`repository` 等 Rule 的本仓库落点。

## 总原则

- 编码权威：**详设 §8** + 对外/对内接口契约（按画像 §5.4 **P-2**）
- 依赖方向见 `rules/java-project.md`：对外 HTTP 仅在 BFF；领域微服务按画像 **P-2** 暴露内部远程入口（HTTP 内部 Controller 或 RPC Provider），严禁跨服务依赖对方 `*-impl`
- **领域厚度**：按详设 §4.4 / §8 标注；默认 **贫血 + 条件更新**，见 [domain-model-guide.md](../../detail-design/references/domain-model-guide.md)
- 每层完成后跑单服务测试子集（单仓库多服务用 `mvn test -pl {service-module} -am`，一服务一仓用 `mvn test`）

---

## 1. 持久化（Repository / Mapper，按画像 §5.4 P-3 ORM 选型）

> **选型说明**：下方表格以项目在画像 §5.4 **P-3** 选定 **MyBatis / MyBatis-Plus** 为例（须遵守 `rules/mybatis-conventions.md`）；若选用 JPA / jOOQ 等其他 ORM，按接入时替换的持久化 Rule 执行。无论何种 ORM，均须守住 **每服务独立库、禁止跨服务 SQL JOIN 与外键**。

| 项 | 约定（MyBatis 示例） |
|----|------|
| DO | `*-impl/infrastructure/dataobject/*DO.java`（仅软删支含 `deleted` / `deletedAt`） |
| Mapper | 接口在 `infrastructure/mapper/`；XML 在 `resources/mapper/` |
| 主键 | 按 schema-conventions §1.2：应用侧 ID 无 `AUTO_INCREMENT` 且写前赋值；自增则 `AUTO_INCREMENT` 且应用不 `setId`。其他 ORM 以替换规则文首为准 |
| 主键查询 | 允许 `BaseMapper<DO>`；软删支排除已删行按详设 §6.2 |
| 其它 SQL | **仅 XML**；禁止 `@Select` 复杂查询。软删支条件查询默认 `AND deleted = 0`；状态作废支不追加 |
| 业务删除 | 软删支 XML `UPDATE deleted=1`；状态作废支按状态列更新。两支都禁止把 `deleteById` 当作业务删除 |
| **状态迁移写库** | **条件 `UPDATE`**：`WHERE id=? AND status=?`；软删支再加 `deleted=0`。`affected_rows=0` 抛业务异常 |
| **禁止默认** | 查整行 → 改 DO 字段 → 全量覆盖（除非详设明确） |
| 测试 | Service 层 Mock 持久化层；复杂 SQL 可选容器持久化单测（Testcontainers MySQL） |

详见 `rules/mybatis-conventions.md`、详设 §6.2、[schema-conventions.md](../../detail-design/references/schema-conventions.md) §1.2、[domain-model-guide.md](../../detail-design/references/domain-model-guide.md)。

---

## 2. 域 Service 与 Domain（可选）

| 项 | 约定 |
|----|------|
| 位置 | `app/service/`（默认）；复杂可选 `domain/model/` + `domain/service/` |
| 简单 Story | `{Entity}QueryService` / `{Entity}CommandService`：`持久化 → DO → Converter → DTO`；**只读推荐归 Query** |
| **复杂 Story** | 可选贫血 `domain/model/*` 做 `canXxx()` / 状态判断；落库仍走条件更新 |
| 职责 | 业务规则、抛 `{BizException}`；跨服务调用走 `app/client` 远程封装（按 P-2）；本地 `@Transactional` 仅限本服务单库 |
| **对象转换** | DO↔DTO（及可选 domain）放 `infrastructure/converter/`，**优先 MapStruct `@Mapper(componentModel = "spring")`**；条件字段用 `@Mapping` / `@AfterMapping` |
| 禁止 | 在 Service 直接散落原生 HTTP/RPC 调用代码；直连外部厂商；大段手写字段拷贝（应进 Converter） |
| **单点** | 匹配/normalize/推荐等算法**仅**在归属领域微服务一处；BFF 不得重复同名工具类 |
| 测试 | `{Entity}QueryServiceTest` / `{Entity}CommandServiceTest`；JUnit 5 + `@ExtendWith(MockitoExtension.class)` |
| Mock | `@Mock` 持久化层、下游远程 `{Domain}Client`、外部 `{External}Client` |
| 断言 | 断言 `{BizException}` 的 `code` / `message` 对齐 AC（响应/异常规则见画像 §3.7） |

**快捷路径**：持久化层未就绪时先 Mock 持久化层写 Service 测试，不得直连 DB。

---

## 3. Facade 与领域服务内部远程入口（内部 Controller / RPC Provider）

| 项 | 约定 |
|----|------|
| 内部远程入口 | 按画像 §5.4 **P-2** 落地：HTTP 协议为 `interfaces/*InternalController`（路径前缀与防外泄按 **P-5**，严禁暴露到公网网关）；RPC 协议为 `app/provider/*ProviderImpl`——均薄委托 Facade |
| Facade | `app/facade/` — 本服务多 Service 编排；跨服务写按画像 **E-3** 落实一致性（严禁本地 `@Transactional` 跨服务） |
| 测试 | HTTP 内部入口可用 `@WebMvcTest` Mock Facade/Service；复杂编排单测 `*FacadeTest` |

---

## 4. 服务远程契约（`*-api`）

| 项 | 约定 |
|----|------|
| 契约接口 | 远程客户端/接口（按画像 §5.4 **P-2**）+ DTO/枚举（及按 **E-4** 的事件对象） |
| 错误码 | 领域服务：`*-api` 的 `{Domain}ErrorCode`（号段对齐画像 §3.7）；入口守卫 `{GuardErrorCode}` 与系统错误码 `{SystemErrorCode}` 对齐 `rules/exception-and-result.md` |
| 禁止 | 放入业务实现类或违反画像 **P-6** 公共库边界的内部实体 |

---

## 5. BFF API（对外 Controller）

| 项 | 约定 |
|----|------|
| 位置 | `{project}-bff-app` / `{project}-bff-admin` `controller/` |
| URL | 对外前缀对齐画像 §六（如 `/api/v1/{project}/app/` 或 `/api/v1/{project}/admin/` + OpenAPI path） |
| 响应 | 严格遵循画像 §3.7（**P-4**）与 `rules/exception-and-result.md`（若采用统一包装体 `{Result<T>}`，按约定的成功码判定成功） |
| 依赖 | 经 `client/` 注入下游服务的 `*-api` 远程客户端（按画像 **P-2**）；**严禁**依赖任何领域服务的 `*-impl` |
| **守卫** | 鉴权、空参/`isBlank`、简单格式（如 `endTime > startTime`）；**禁止** normalize/匹配/状态机/跨服务复杂写编排 |
| **守卫异常** | 抛入口守卫错误码枚举 `{GuardErrorCode}`；**禁止** Controller 内 magic number / 硬编码文案 |
| **系统异常** | 鉴权/框架层用公共系统错误码枚举 `{SystemErrorCode}` |
| **对象转换** | DTO↔VO 放 `{basePackage}.bff.app.converter`（或 `bff.admin.converter`），**优先 MapStruct**；**禁止**在 Controller 内手写字段 builder 映射 |
| **中文说明** | 类与公开方法须有中文 JavaDoc；`summary` 对齐 OpenAPI |
| **Swagger** | 见下方「文档注解」；依赖 `swagger-annotations-jakarta` |
| 测试 | `{Resource}ControllerTest`：`@WebMvcTest` + `@MockBean` 下游远程客户端 + MockMvc |
| 断言 | 按画像 §3.7 响应格式断言状态码、业务码、提示文案与关键字段 |

路径与 OpenAPI、详设 §5.1 三者一致。守卫 vs 领域规则见 `rules/bff-domain-boundary.md` 与 [bff-domain-boundary-guide.md](../../detail-design/references/bff-domain-boundary-guide.md)。

### 5.0 对象转换（MapStruct）

| 项 | 约定 |
|----|------|
| 包 | `{basePackage}.bff.app.converter` / `{basePackage}.bff.admin.converter` |
| 实现 | MapStruct `@Mapper(componentModel = "spring")`；接口名 `*Converter` |
| Controller | 返回 `{Result<T>}` 封装（如 `return {Result}.success(converter.toVo(dto));`）— **不**内联 `toVo`/`toSummaryVo` |
| 职责边界 | 仅 DTO↔VO；**禁止**在 BFF converter 写域规则（状态筛选、截止时间业务判断等属领域微服务 `*-impl`） |
| 依赖 | `org.mapstruct:mapstruct`；父 POM 已配 `mapstruct-processor` + `lombok-mapstruct-binding` |

示意：

```java
@Mapper(componentModel = MappingConstants.ComponentModel.SPRING)
public interface {Entity}BffConverter {
    {Entity}QueryResultVO toVo({Entity}QueryResultDTO dto);
    {Entity}SummaryVO toSummaryVo({Entity}SummaryDTO dto);
}
```

### 5.1 文档注解（必守）

**契约权威**仍是 `docs/api/**/openapi.yaml`；Java 注解用于代码可读性 + springdoc UI，须与 YAML **语义一致**（`summary` / `description` / 字段说明）。

| 落点 | 注解 / 文档 | 要求 |
|------|-------------|------|
| Controller 类 | 中文 JavaDoc + `@Tag(name, description)` | `name` 对齐 OpenAPI `tags` |
| 公开方法 | 中文 JavaDoc + `@Operation(summary, description)` | `summary` = YAML `summary`；`description` 含 Story AC 编号 |
| 请求/路径/查询参数 | `@Parameter` 或 `@Schema` | 中文 `description` |
| 响应 VO / 请求体字段 | `@Schema(description = "…")` | 中文；必填可加 `requiredMode` |
| 鉴权接口 | `@SecurityRequirement(name = "bearerAuth")`（若 YAML 声明了 security） | 与 OpenAPI `securitySchemes` 名一致 |

依赖：

```xml
<!-- {project}-bff-*：编译期注解 -->
<dependency>
  <groupId>io.swagger.core.v3</groupId>
  <artifactId>swagger-annotations-jakarta</artifactId>
</dependency>

<!-- 独立启动 HTTP 服务（BFF 或需要暴露 Swagger UI 的服务）：运行时 Swagger UI（按需引入） -->
<dependency>
  <groupId>org.springdoc</groupId>
  <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
</dependency>
```

示意：

```java
/**
 * App 端 {资源} 查询。
 */
@Tag(name = "{resource}", description = "{资源}查询")
@RestController
@RequestMapping("/api/v1/{project}/app/{resources}")
public class {Resource}Controller {

    /**
     * 查询当前进行中 {实体} 摘要。
     */
    @Operation(
            summary = "查询当前进行中{实体}摘要",
            description = "Story AC-01～04、AC-06。无进行中记录时返回空状态标记，非业务错误。")
    @SecurityRequirement(name = "bearerAuth")
    @GetMapping("/active")
    public {Result<T>} getActive() { ... }
}
```

**禁止**：无中文说明的空 `@Operation`；注解文案与 OpenAPI YAML 明显冲突；将领域服务内部 HTTP Controller 暴露到对外网网关。

---

## 6. 跨服务与外部集成 Client

| 场景 | 落点 |
|------|------|
| 跨服务同步调用 | `*-impl/app/client/{Domain}Client`（或 BFF `client/`）→ 封装下游 `*-api` 远程契约（协议见画像 §5.4 **P-2**，如 OpenFeign / Dubbo / gRPC），并落实请求头透传（**P-5**）与错误解包（**P-4**） |
| 第三方外部服务 | `{domain-a}-impl/app/client/{External}Client` |
| 外部厂商南向对接 | 专属适配微服务 `{project}-adapter` 的 `adapter-api` 契约接口；实现在 `adapter-impl` |

Service **调 Client**，不直接把原生 HTTP/RPC 调用代码散落在业务逻辑里。单元测试 Mock Client；单服务集成测试按 `rules/integration-test-conventions.md` 对下游微服务做模拟隔离。

**写操作幂等与消息防重**：见 [idempotency-guide.md](../../../reference/idempotency-guide.md)；状态迁移优先 **方案 D** 条件更新。

---

## 8. 定时 / 批处理任务

| 项 | 约定 |
|----|------|
| 落点 | 业务在归属领域微服务 `*-impl`；**禁止** BFF 写定时/批处理入口 |
| 触发与防重 | 微服务多副本下**默认必须防重叠执行**，具体调度/分布式锁框架按画像 §5.4 **E-6**（未定则阻断） |
| 入口层 | `*-impl/app/scheduler/`（或等价包）— **薄入口**：触发、加锁、执行记录、委托 Job |
| 编排层 | `*Job` / `*TaskRunner` — 防重叠、重试、批处理游标 |
| 业务层 | `*Service` — 状态机、幂等；跨服务调用走 `app/client` 远程客户端 |
| 设计 | [scheduled-task-guide.md](../../../reference/scheduled-task-guide.md) |

**禁止**：BFF 写定时触发；入口类内大段状态机/业务逻辑；多副本微服务省略防重设计。

---

## 9. 服务独立启动与网关配置

- 每个 BFF 与每个领域服务 `*-impl` 各自维护独立启动类与配置（`application.yml` / `application-test.yml`）
- 测试配置须关闭外部服务注册与远程配置拉取（按画像 §5.4 E-1），确保离线可测
- 涉及对外路由调整时，确认 API 网关不转发领域服务内部路径并清理外部伪造请求头（按画像 P-5）

---

## 公司级 Rule 映射

| 公司级 | 本仓库 |
|--------|--------|
| `architecture`（公司级示例） | `rules/java-project.md` |
| `api-layer`（公司级规则） | 本章 §5 + `rules/exception-and-result.md` + `rules/bff-domain-boundary.md` |
| `service-layer`（公司级规则） | 本章 §2、§3 |
| `integration-client`（公司级规则） | 本章 §6 |
| `repository`（公司级规则） / `database-model`（公司级规则） | 本章 §1 + `rules/mybatis-conventions.md` |
| `data-objects`（公司级规则） | DO/DTO 命名；§8 详设 |
| `exception-handling`（公司级规则） | `rules/exception-and-result.md` |
