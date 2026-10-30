# 分层编码指引（Java）

> `feature-coding` 步骤 6 进入对应层前按需读取。对应公司级 `api-layer`、`service-layer`、`integration-client`、`repository` 等 Rule 的本仓库落点。

## 总原则

- 编码权威：**详设 §8** + OpenAPI（BFF HTTP）
- 依赖方向见 `rules/java-project.md`：BFF → `XxxApi`；`*-impl` 不暴露 HTTP
- **领域厚度**：按详设 §4.4 / §8 标注；默认 **贫血 + SQL 条件更新**，见 [domain-model-guide.md](../../detail-design/references/domain-model-guide.md)
- 每层完成后跑 `mvn test -pl {module} -am` 子集

---

## 1. 持久化（Repository / Mapper）

| 项 | 约定 |
|----|------|
| DO | `*-impl/infrastructure/dataobject/*DO.java`（含 `deleted` / `deletedAt`） |
| Mapper | 接口在 `infrastructure/mapper/`；XML 在 `resources/mapper/` |
| 主键 | `BIGINT` 雪花；**无** `AUTO_INCREMENT`；写前 `SnowflakeIdGenerator.nextId()`（`common-core`） |
| 主键查询 | 允许 `BaseMapper<DO>`；排除已删行按详设 §6.2 |
| 其它 SQL | **仅 XML**；禁止 `@Select` 复杂查询；条件查询默认 `AND deleted = 0` |
| 业务删除 | XML 软删 `UPDATE deleted=1`；禁止业务路径 `deleteById` |
| **状态迁移写库** | **条件 `UPDATE`**：`WHERE id=? AND status=?`（及 `deleted=0`）；`affected_rows=0` 抛 `BizException` |
| **禁止默认** | 查整行 → 改 DO 字段 → `updateById` 全量覆盖（除非详设明确） |
| 测试 | Service 层 Mock Mapper；复杂 SQL 可选 `@MybatisTest` |

详见 `rules/mybatis-conventions.md`、详设 §6.2、[schema-conventions.md](../../detail-design/references/schema-conventions.md) §1.2、[domain-model-guide.md](../../detail-design/references/domain-model-guide.md)。

---

## 2. 域 Service 与 Domain（可选）

| 项 | 约定 |
|----|------|
| 位置 | `app/service/`（默认）；复杂可选 `domain/model/` + `domain/service/` |
| 简单 Story | `{实体}QueryService` / `{实体}CommandService`：`Mapper → DO → Converter → DTO`；**只读推荐归 Query** |
| **复杂 Story** | 可选贫血 `domain/model/*` 做 `canXxx()` / 状态判断；**落库仍走 Mapper XML** |
| 职责 | 业务规则、抛 `BizException`；跨域用 `XxxApi` / Client |
| **对象转换** | DO↔DTO（及可选 domain）放 `infrastructure/converter/`，**优先 MapStruct `@Mapper(componentModel = "spring")`**；条件字段用 `@Mapping` / `@AfterMapping` |
| 禁止 | 直接写 HTTP；在 Service 调厂商 HTTP（走 Client/Gateway）；在 Service 内大段字段拷贝（应进 Converter） |
| **单点** | 匹配/normalize/推荐等算法**仅**在域内一处；BFF 不得重复同名工具类 |
| 测试 | `*ServiceTest`；JUnit 5 + `@ExtendWith(MockitoExtension.class)` |
| Mock | `@Mock` Mapper、`*Client`、其它 `XxxApi` |
| 断言 | `assertThrows(BizException.class)` + `getCode()` / message 对齐 AC |

**快捷路径**：Mapper 未就绪时先 Mock Mapper 写 Service 测试，不得直连 DB。

---

## 3. Facade / Provider（XxxApiImpl）

| 项 | 约定 |
|----|------|
| Provider | `app/provider/XxxApiImpl.java` — 薄委托 Facade |
| Facade | `app/facade/` — 多 Service 编排 |
| 测试 | 简单委托由 Service 测试覆盖；复杂编排可 `*FacadeTest` |

---

## 4. 域契约（*-api）

| 项 | 约定 |
|----|------|
| 接口 | `XxxApi` + DTO/枚举 |
| 错误码 | 域：`*-api` 的 `*ErrorCode`；BFF 守卫：`booking-common` 的 `BookingErrorCode`；系统：`hema-common` `ErrorCode` |
| 禁止 | Spring 业务注解、实现类 |

---

## 5. BFF API（Controller）

| 项 | 约定 |
|----|------|
| 位置 | `booking-bff-app` / `booking-bff-admin` `controller/` |
| URL | `/api/v1/booking/app/` 或 `/admin/` + OpenAPI path |
| 响应 | `Result<T>`；成功 `code === 200` |
| 依赖 | `@Autowired XxxApi`；**禁止** 注入 impl 内部 Service/Mapper |
| **守卫** | 鉴权、空参/`isBlank`、简单格式（如 `endTime > startTime`）；**禁止** normalize/匹配/状态机 |
| **守卫异常** | `throw new BizException(BookingErrorCode.…)`（`booking-common`）；**禁止** Controller 内 magic number / 硬编码文案 |
| **系统异常** | Filter/框架层用 `com.hema.common.core.exception.ErrorCode`（如 `UNAUTHORIZED`） |
| **对象转换** | DTO↔VO 放 `bff.app.converter`（或 `bff.admin.converter`），**优先 MapStruct**；**禁止**在 Controller 内手写字段 builder 映射 |
| **中文说明** | 类与公开方法须有中文 JavaDoc；`summary` 对齐 OpenAPI |
| **Swagger** | 见下方「文档注解」；依赖 `swagger-annotations-jakarta` |
| 测试 | `@WebMvcTest` + `@MockBean XxxApi` + MockMvc |
| 断言 | `jsonPath("$.code")`、`$.message`、`$.data.*` |

路径与 OpenAPI、详设 §5.1 三者一致。守卫 vs 领域规则见 `rules/bff-domain-boundary.md` 与 [bff-domain-boundary-guide.md](../../detail-design/references/bff-domain-boundary-guide.md)。

### 5.0 对象转换（MapStruct）

| 项 | 约定 |
|----|------|
| 包 | `com.hema.booking.bff.app.converter` / `...bff.admin.converter` |
| 实现 | MapStruct `@Mapper(componentModel = "spring")`；接口名 `*Converter` |
| Controller | `return Result.success(converter.toVo(dto));` — **不**内联 `toVo`/`toSummaryVo` |
| 职责边界 | 仅 DTO↔VO；**禁止**在 BFF converter 写域规则（状态筛选、payDeadline 业务判断等属 order-impl） |
| 依赖 | `org.mapstruct:mapstruct`；父 POM 已配 `mapstruct-processor` + `lombok-mapstruct-binding` |

示意：

```java
@Mapper(componentModel = MappingConstants.ComponentModel.SPRING)
public interface ActiveReservationBffConverter {
    ActiveReservationQueryResultVO toVo(ActiveReservationQueryResultDTO dto);
    ActiveReservationSummaryVO toSummaryVo(ActiveReservationSummaryDTO dto);
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
<!-- booking-bff-*：编译期注解 -->
<dependency>
  <groupId>io.swagger.core.v3</groupId>
  <artifactId>swagger-annotations-jakarta</artifactId>
</dependency>

<!-- booking-app：运行时 Swagger UI（可选，实现启动模块时引入） -->
<dependency>
  <groupId>org.springdoc</groupId>
  <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
</dependency>
```

示意：

```java
/**
 * App 端预约单查询。
 */
@Tag(name = "reservation", description = "预约单查询")
@RestController
@RequestMapping("/api/v1/booking/app/reservations")
public class AppReservationController {

    /**
     * 查询当前进行中预约单摘要（首页进度卡片）。
     */
    @Operation(
            summary = "查询当前进行中预约单摘要",
            description = "Story AC-01～04、AC-06。无进行中单时 hasActiveReservation=false，非业务错误。")
    @SecurityRequirement(name = "bearerAuth")
    @GetMapping("/active")
    public Result<ActiveReservationQueryResultVO> getActiveReservation() { ... }
}
```

**禁止**：无中文说明的空 `@Operation`；注解文案与 OpenAPI YAML 明显冲突；在 `*-impl` 写 Swagger 注解（域无 HTTP）。

---

## 6. 集成 Client（外部 HTTP）

| 场景 | 落点 |
|------|------|
| 支付 | `order-impl/app/client/PaymentClient` |
| 跨域 | `*-impl/app/client/*Client` → 注入其它 `XxxApi` |
| 车场南向 | `adapter-api` `ParkingLotGateway`；实现在 `adapter-impl` |

Service **调 Client**，不直接 `RestTemplate` 散落。测试 Mock Client。

**写操作幂等**：见 [idempotency-guide.md](../../../reference/idempotency-guide.md)；状态迁移优先 **方案 D** 条件更新。

---

## 8. 定时 / 批处理任务

| 项 | 约定 |
|----|------|
| 落点 | 业务在 `*-impl`；**禁止** BFF 写定时/批处理入口 |
| 触发方式 | 由详设 §1.3 选定，**不绑定**具体框架：`@Scheduled`、XXL-Job、Quartz、Admin 手动触发、MQ 延迟等均可 |
| 入口层 | `*-impl/app/scheduler/`（或等价包）— **薄入口**：触发、加锁、执行记录、委托 Job |
| 编排层 | `*Job` / `*TaskRunner` — 防重叠、重试、批处理游标 |
| 业务层 | `*Service` — 状态机、幂等；跨域调 `XxxApi` |
| 设计 | [scheduled-task-guide.md](../../../reference/scheduled-task-guide.md) |

**禁止**：BFF 写定时触发；入口类内大段状态机/业务逻辑（无论用何种调度写法）。

---

## 9. 启动与配置（booking-app）

- 仅 Story 明确要求时改 `{项目}/pom.xml` 聚合、全局配置
- 不新增第二个 `@SpringBootApplication`
- 集成测试 Mock 外部支付/车场

---

## 公司级 Rule 映射

| 公司级 | 本仓库 |
|--------|--------|
| `architecture（公司级示例） | `rules/java-project.md` |
| `api-layer（公司级规则） | 本章 §5 + `rules/exception-and-result.md` + `rules/bff-domain-boundary.md` |
| `service-layer（公司级规则） | 本章 §2、§3 |
| `integration-client（公司级规则） | 本章 §6 |
| `repository（公司级规则） / `database-model（公司级规则） | 本章 §1 + `rules/mybatis-conventions.md` |
| `data-objects（公司级规则） | DO/DTO 命名；§8 详设 |
| `exception-handling（公司级规则） | `rules/exception-and-result.md` |
