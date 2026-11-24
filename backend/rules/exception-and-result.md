# 异常处理与响应封装（微服务版）

> **选型驱动原则**：本规则只固化**与具体包装方式无关的通用异常纪律**；项目的对外/对内返回格式、跨服务错误码传递策略（透传 vs 映射）、公共基础库坐标与微服务错误码号段，一律以 [system-landscape.md](../architecture/system-landscape.md) §3.7（及 §5.4 **P-4**）为准。若画像 P-4 仍为 `[TBD]`，详设与编码前须阻断请用户拍板。

## 一、通用异常纪律（必守，不随选型变化）

1. **错误码必须按微服务号段归口枚举**：各领域服务在自己的 `*-api` 定义 `*ErrorCode` 枚举（号段见画像 §3.7）；入口守卫错误码放公共横切模块；**禁止**在代码里硬编码 magic number（如 `400`、`1501`）或用纯字符串代替业务错误码。
2. **禁止入口层吞异常**：Controller / 内部远程入口**不写** `try/catch (BizException)` 手动拼装失败响应，统一交由全局异常处理器或协议拦截器处理。
3. **不重复造公共基础库轮子**：项目已引入统一公共基础库（见画像 §3.7 公共基础库锚点）时，严禁在各微服务或 `*-common` 里重复定义同名响应体、异常类或全局异常处理器。
4. **错误文案与 Story AC 对齐**：失败类 AC 中写明的用户可见提示文案，必须与对应错误码枚举的默认文案或转换规则保持一致。
5. **跨服务异常传播边界**：
   - 调用下游微服务（协议见画像 §5.4 P-2）时，必须在统一客户端解包/拦截层（如 `ErrorDecoder` / RPC Filter）处理下游失败响应，**不得**在业务 Service 中到处散落手工拆解 HTTP 状态码或 JSON 错误体；
   - 下游错误码是**原样透传**还是**映射为上游服务错误码**，以及内部接口是否与对外接口共用同一包装体，严格按画像 §3.7（P-4）结论执行；
   - 网络超时、连接失败、5xx 等不可用故障须归入远程调用失败类错误（如 `REMOTE_SERVICE_ERROR`），不得伪装成业务成功。

## 二、模块依赖原则（微服务独立启动）

- 每个独立启动的服务模块（各 BFF 与各领域服务 `*-impl`）均须引入 Web / 协议异常处理依赖（确保各自的全局异常处理与远程解包组件独立生效）。
- 各 `*-api` 契约模块仅引入最轻量的核心依赖（错误码接口、分页/响应契约），不引入 Web 容器或数据库依赖。

---

## 三、参考示例（源项目 `hema-common` + `Result<T>` 方案）

> **接入提示**：下文为源项目采用「统一 `Result<T>` 包装 + `hema-common` 公共库」时的落地参考。接入项目若在画像 §5.4 P-4 中选择了相同模式，替换公共库锚点与号段后即可直接使用；若选择了「裸 DTO + HTTP 状态码」或其他公共库，接入时按 [MIGRATION.md](../MIGRATION.md) §一.3b 重写本节。

### 示例依赖与坐标

| 能力 | Maven 坐标（示例） | 包名（示例） |
|------|--------------------|--------------|
| 响应 / 异常 / 分页 | `com.hema:common-core` | `com.hema.common.core.*` |
| 全局异常处理 / Feign 解包 | `com.hema:common-web` | `com.hema.common.web.*` |

### 示例响应与异常用法

```java
// ✅ 对外 BFF Controller：成功直接包装，失败异常上浮给 GlobalExceptionHandler
@PostMapping("/spaces/recommend")
public Result<SpaceRecommendDTO> recommend(@Valid @RequestBody RecommendRequest req) {
    return Result.success(inventoryClient.recommend(req));
}

// ✅ 领域服务：抛域错误码枚举
throw new BizException(InventoryErrorCode.SLOT_NOT_AVAILABLE);

// ❌ 禁止在 Controller try/catch 后手动 Result.fail
// ❌ 禁止硬编码数字错误码或自造同名 Result / BizException
```

### 示例微服务错误码号段

| 层级 / 服务 | 位置（示例） | 号段 / 说明 |
|-------------|--------------|-------------|
| 通用（系统） | `com.hema.common.core.exception.ErrorCode` | 200 / 401 / 403 / 404 / 500 / 502 等 |
| 入口守卫 | `booking-common` → `BookingErrorCode implements BizErrorCode` | BFF 守卫（对齐 OpenAPI `code=400`） |
| 订单服务 | `order-api` → `OrderErrorCode` | **1500~1599** |
| 库存服务 | `inventory-api` → `InventoryErrorCode` | **1600~1699** |
| 适配器服务 | `adapter-api` → `AdapterErrorCode` | **1700~1799** |
| 硬件 IoT 服务 | `iot-api` → `IotErrorCode` | **1900~1999** |

### 示例公共库核心 API 速查（仅当沿用 `hema-common` 形态时适用）

- **`Result<T>`**：`Result.success()` / `Result.success(T data)` / `Result.fail(ErrorCode)` / `Result.fail(Integer code, String message)` / `isSuccess()`（`code == 200`）。
- **`BizException`**：`BizException(ErrorCode)` / `BizException(BizErrorCode)` / `BizException(Integer code, String message)`（跨服务透传下游错误码用）。
- **`ErrorCode`**：`SUCCESS(200)` / `PARAM_ERROR(400)` / `UNAUTHORIZED(401)` / `FORBIDDEN(403)` / `NOT_FOUND(404)` / `SYSTEM_ERROR(500)` / `REMOTE_SERVICE_ERROR(502)`。
- **`PageResult<T>` / `PageQuery`**：统一分页请求与响应基类。
- **`SnowflakeIdGenerator#nextId()`**：分布式雪花 ID（若画像 P-3 选用雪花 ID，多实例须配置独立 `workerId`）。

完整实践说明见 [reference/exception-and-result.md](../reference/exception-and-result.md)。
