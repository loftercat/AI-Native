# 异常处理与统一响应（最佳实践）

> **选型说明**：本指南以源项目 `hema-common` + `Result<T>` 方案作实践参考；实际项目的返回格式、跨服务错误码传递规则与公共基础库坐标以 [system-landscape.md](../architecture/system-landscape.md) §3.7（及 §5.4 **P-4**）为准。
> AI 编码约束见 [`rules/exception-and-result.md`](../rules/exception-and-result.md)。

---

## 1. 为何不在 `booking-common` 重复实现

`Result`、`BizException`、`ErrorCode`、`BizErrorCode`、`PageResult` 已在 **`hema-common/common-core`** 定义；`GlobalExceptionHandler` 在 **`hema-common/common-web`**。

本仓库 `booking-common` 承载**源项目横切**抽象（如 BFF 守卫错误码 `BookingErrorCode`、缓存/MQ 等），**不**重复定义 `Result` / `BizException` / `GlobalExceptionHandler`。

---

## 2. Maven 依赖

```xml
<!-- *-api / *-impl：域错误码与抛异常 -->
<dependency>
    <groupId>com.hema</groupId>
    <artifactId>common-core</artifactId>
</dependency>

<!-- 每个独立启动的服务（BFF 与各领域微服务 *-impl）：全局异常处理与远程解包 -->
<dependency>
    <groupId>com.hema</groupId>
    <artifactId>common-web</artifactId>
</dependency>
```

父 POM 通过 `dependencyManagement` 锁定 `hema-common` 版本；本地开发可先 `mvn install` 安装 `hema-common` 至本地仓库。

---

## 3. 类型与包名速查

| 类型 | 包 |
|------|-----|
| `Result<T>` | `com.hema.common.core.result` |
| `PageResult<T>` | `com.hema.common.core.result` |
| `BizException` | `com.hema.common.core.exception` |
| `ErrorCode` | `com.hema.common.core.exception` |
| `BizErrorCode` | `com.hema.common.core.exception` |
| `GlobalExceptionHandler` | `com.hema.common.web.handler` |

---

## 4. 分层职责

| 层级 | 成功 | 失败 |
|------|------|------|
| **BFF Controller** | `return Result.success(dto)` | 不 catch；异常上浮 |
| **域 `XxxApi`** | 返回 DTO / `void` | `throw new BizException(XxxErrorCode.…)` |
| **全局处理** | — | `GlobalExceptionHandler` → `Result.fail` |

**业务成败**：响应 JSON 中 `code === 200`（与 HTTP 状态码解耦，多数失败仍为 HTTP 200）。

---

## 5. 本仓库错误码号段

| 区间 | 枚举（路径） | 用途 |
|------|--------------|------|
| 200 / 401 / 403 / 404 / 500 / 502 | `ErrorCode`（`hema-common/common-core`） | 系统级：鉴权、未找到、内部错误等 |
| BFF 守卫（OpenAPI `code=400`） | `booking-common/.../BookingErrorCode` | 空参、时段格式、关键词非法等 |
| 1500~1599 | `order-api/.../OrderErrorCode` | 预订订单域 |
| 1600~1699 | `inventory-api/.../InventoryErrorCode` | 库存占用域 |
| 1700~1799 | `adapter-api/.../AdapterErrorCode` | 车场南向对接 |

新增业务码：域规则 → 对应 `*-api`；BFF 守卫 → `BookingErrorCode`；Story AC 失败文案与枚举 `message` 对齐。

```java
// BFF Controller 守卫
throw new BizException(BookingErrorCode.INCOMPLETE_BOOKING_INFO);

// AppAuthFilter — 系统级
Result.fail(ErrorCode.UNAUTHORIZED.getCode(), ErrorCode.UNAUTHORIZED.getMessage());
```

---

## 6. 微服务跨服务错误传播参考（按画像 §3.7 / §5.4 P-4 选定）

| 选型模式 | 实践要点 |
|----------|----------|
| **统一 `Result<T>` + 透传下游码**（参考方案 A） | 对外 BFF 与内部 HTTP 均返回 `Result<T>`；下游失败时由调用方统一 Decoder / Filter 还原为 `BizException(code, message)` 并默认透传下游业务码，必要时按场景映射 |
| **裸 DTO + HTTP 状态码**（参考方案 B） | 内部接口成功直接返回 DTO，失败返回 4xx/5xx + 标准错误体；由调用方 `ErrorDecoder` 解析并转为本服务或下游 `BizException` |
| **RPC 异常传播**（若画像 P-2 选 Dubbo/gRPC） | 由统一 RPC Filter 序列化业务错误码与消息，调用方还原为 `BizException` |
| **网络/超时/5xx 故障** | 统一归入 `REMOTE_SERVICE_ERROR(502)` 等远程故障码，禁止伪装成业务成功 |
| **i18n** | 默认 `message` 中文定义在各服务错误码枚举；多语言由前端或网关按 `code` 映射（按需） |

---

## 7. 反模式

- 在 `booking-common` 再写一套与公共基础库同名的 `Result` / `BizException`
- Controller / 内部远程入口内 `catch (BizException e) { return Result.fail(...); }`
- 在业务 Service 中散落手写解析下游 HTTP 状态码或 JSON 错误体（应统一收拢到远程客户端解包层）
- 在通用 `ErrorCode` 枚举中硬塞各微服务的业务码
- 用 `new BizException("自定义字符串")` 代替服务错误码枚举（会落 `SYSTEM_ERROR` 的 code）

---

## 7. 相关专项

写操作幂等（支付回调、下单、占库存）见 [idempotency-guide.md](./idempotency-guide.md)。

---

## 变更记录

| 日期 | 变更 |
|------|------|
| 2026-07-26 | 初版：约定依赖 `hema-common`，明确 `booking-common` 边界与号段 |
