# 异常处理与响应封装

**实现不在本仓库**：`Result`、`BizException`、`ErrorCode`、`BizErrorCode`、`GlobalExceptionHandler` 由 **`hema-common`** 提供。

| 能力 | Maven 坐标 | 包名 |
|------|------------|------|
| 响应 / 异常 / 分页 | `com.hema:common-core` | `com.hema.common.core.*` |
| 全局异常处理 | `com.hema:common-web` | `com.hema.common.web.handler.GlobalExceptionHandler` |

> 源码：`hema-common/common-core`、`hema-common/common-web`。本仓库 **禁止** 在 `booking-common` 重复定义上述类型。

## Maven 依赖（按模块）

| 模块 | 依赖 |
|------|------|
| `*-api` | `common-core`（域错误码实现 `BizErrorCode`） |
| `*-impl` | `common-core` |
| `booking-bff-app` / `booking-bff-admin` | `common-web`（含 `common-core`） |
| `booking-app` | `common-web`（扫描生效 `GlobalExceptionHandler`） |
| `booking-common` | `common-core` + **`BookingErrorCode`**（BFF 守卫）；**不**放 Result/BizException |
| `booking-bff-app` / `booking-bff-admin` | `common-web` + **`booking-common`** |

版本由父 POM `dependencyManagement` 统一管理（与 `hema-common` 发布版本对齐）。

## 统一响应体 `Result<T>`

```java
// 成功
return Result.success(data);      // code=200

// 业务失败（HTTP 状态仍为 200，通过 code 字段判断）
return Result.fail(InventoryErrorCode.SLOT_NOT_AVAILABLE);
```

- **HTTP 状态码多数为 200**；客户端以 `result.code === 200` 判业务成功
- 分页：`Result<PageResult<T>>`
- 域 `XxxApi` **禁止** 返回 `Result<T>`（避免双层包装）

## 业务异常 `BizException`

```java
// ✅ 推荐：域错误码枚举
throw new BizException(InventoryErrorCode.SLOT_NOT_AVAILABLE);

// ✅ 通用场景
throw new BizException(ErrorCode.PARAM_ERROR);

// ❌ 禁止在 Controller try/catch 后手动 Result.fail
```

- **不设 `SystemException`**：未捕获异常由 `GlobalExceptionHandler` → `ErrorCode.SYSTEM_ERROR(500)`
- V1 同 JVM：`BizException` 直传，无需 Dubbo/Feign 解包

## 错误码分层

| 层级 | 位置 | 号段 / 说明 |
|------|------|-------------|
| 通用（系统） | `com.hema.common.core.exception.ErrorCode` | 200 / 401 / 403 / 404 / 500 / 502 等；鉴权失败、系统异常 |
| 平台横切 | `booking-common` → `BookingErrorCode implements BizErrorCode` | BFF **守卫**；**与 OpenAPI 对齐时 `code=400`**；App/Admin 共享 |
| 订单域 | `order-api` → `OrderErrorCode` | **1500~1599** |
| 库存域 | `inventory-api` → `InventoryErrorCode` | **1600~1699** |
| 适配器域 | `adapter-api` → `AdapterErrorCode` | **1700~1799** |
| 硬件 IoT 域 | `iot-api` → `IotErrorCode` | **1900~1999** |

```java
// booking-common/.../BookingErrorCode.java — BFF 守卫，禁止 Controller 内写 magic number
throw new BizException(BookingErrorCode.INCOMPLETE_BOOKING_INFO);

// booking-bff-app Filter — 系统级用 hema-common
Result.fail(ErrorCode.UNAUTHORIZED.getCode(), ErrorCode.UNAUTHORIZED.getMessage());

// order-api/.../exception/OrderErrorCode.java — 域规则
throw new BizException(OrderErrorCode.PENDING_ORDER_EXISTS);
```

- Story AC 失败 `message` 须与枚举文案一致
- **禁止** Controller 内 `private static final int ... = 400` 或硬编码 `BizException(400, "...")`；BFF 守卫用 `BookingErrorCode`
- **禁止** 在 `ErrorCode`（hema-common）或域 `*ErrorCode` 重复定义 BFF 守卫项
- **禁止** 在 `booking-common` 定义 order/inventory/adapter/iot 域业务细项（仍放各 `*-api`）

## Controller 约定

```java
@PostMapping("/spaces/recommend")
public Result<SpaceRecommendDTO> recommend(@Valid @RequestBody RecommendRequest req) {
    return Result.success(inventoryApi.recommend(req));
}
```

- Controller **不写** try/catch 业务异常
- BFF **不做** i18n（V1：`message` 为中文，前端直接展示或按 `code` 映射）

## 全局处理器（了解即可）

`GlobalExceptionHandler`（`common-web`）行为：

- `BizException` → `Result.fail(code, message)`
- 校验异常 → `PARAM_ERROR(400)`
- 其他 `Exception` → `SYSTEM_ERROR(500)`，不返回堆栈

完整用法与速查见 [reference/exception-and-result.md](../reference/exception-and-result.md)（公司级公共库 API 速查未随模板，接入项目替换为本项目公共库文档）。

---

## API 速查（AI 编码直接照抄，禁止造同名轮子）

下列类型**全部来自 `hema-common`**，本仓库一律 `import com.hema.common.*`，**禁止**在 `booking-common` 或任何模块新建同名类。

### `com.hema.common.core.result.Result<T>`（`@Data`，字段 `code`/`message`/`data`）

| 静态方法 | 说明 |
|----------|------|
| `Result.success()` | 成功无数据（code=200） |
| `Result.success(T data)` | 成功带数据 |
| `Result.fail(String message)` | 失败（code=500 SYSTEM_ERROR） |
| `Result.fail(Integer code, String message)` | 失败指定 code |
| `Result.fail(ErrorCode errorCode)` | 失败用错误码枚举 |
| `boolean isSuccess()` | code==200 判成功（**不是 0**） |

### `com.hema.common.core.exception.BizException`（extends RuntimeException，`@Getter` 字段 `code`）

| 构造器 | 用途 |
|--------|------|
| `BizException(ErrorCode errorCode)` | 通用错误码（系统级） |
| `BizException(BizErrorCode errorCode)` | **域错误码**（常用；域 `*ErrorCode` 实现 `BizErrorCode`） |
| `BizException(Integer code, String message)` | 直接指定（Feign 透传） |
| `BizException(String message)` | 仅消息（code=500） |

### `com.hema.common.core.exception.ErrorCode`（系统级枚举，`@Getter` 字段 `code`/`message`）

`SUCCESS(200)` / `PARAM_ERROR(400)` / `UNAUTHORIZED(401)` / `FORBIDDEN(403)` / `NOT_FOUND(404)` / `SYSTEM_ERROR(500)` / `REMOTE_SERVICE_ERROR(502)`

### `com.hema.common.core.exception.BizErrorCode`（域错误码接口）

```java
public interface BizErrorCode {
    Integer getCode();
    String getMessage();
}
```

域错误码范本（照抄 `OrderErrorCode`）：

```java
@Getter @RequiredArgsConstructor
public enum OrderErrorCode implements BizErrorCode {
    PENDING_ORDER_EXISTS(1501, "您有待支付的预约单，请先完成支付或取消后再预约");
    private final Integer code;
    private final String message;
}
```

### `com.hema.common.core.result.PageResult<T>`（`@Data`，字段 `list`/`total`/`pageNum`/`pageSize`）

`static <T> PageResult<T> of(List<T> list, long total, int pageNum, int pageSize)`

### `com.hema.common.core.page.PageQuery`（分页 RequestDTO 基类，`@Data`）

字段：`pageNum`（默认 1，`@Min(1)`）/ `pageSize`（默认 20，`@Min(1) @Max(100)`）。分页 RequestDTO 继承此类。

### `com.hema.common.core.util.SnowflakeIdGenerator`（`@Component`，注入用）

`long nextId()` — 同步生成雪花 ID。**禁止** DDL `AUTO_INCREMENT`、BFF 生成业务主键。

```java
@RequiredArgsConstructor
public class BookingOrderCommandService {
    private final SnowflakeIdGenerator idGenerator;
    public void create(...) {
        do.setId(idGenerator.nextId());   // INSERT 前赋值
    }
}
```

### AI 常见错误对照

| ❌ AI 常犯 | ✅ 正确 |
|-----------|---------|
| `com.hema.booking.common.Result` | `com.hema.common.core.result.Result` |
| 在 `booking-common` 新建 `Result.java` | 依赖 `common-core`，只 import |
| `Result.ok()` / `code === 0` | `Result.success()` / `code === 200` |
| 自编 `BizException` 构造 | `throw new BizException(XxxErrorCode.YYY)` |
| DDL `AUTO_INCREMENT` | `idGenerator.nextId()` 注入赋值 |
| 重复定义 `GlobalExceptionHandler` | `booking-app` 依赖 `common-web` 即生效 |

### 本仓库可直接照抄的范本

- BFF Controller：`booking-bff-app/.../AppReservationController.java`
- 域错误码：`order-api/.../OrderErrorCode.java`
- 域 Service 抛异常 + 主键生成：`order-impl/.../BookingOrderCommandService.java`
