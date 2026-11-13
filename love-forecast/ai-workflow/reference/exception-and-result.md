# 异常处理与统一响应（最佳实践）

> **实现来源**：`love-common`（源项目公司级公共库，另仓未随模板；接入项目替换为本项目公共库），本仓库只约定用法与域错误码号段。  
> AI 编码约束见 [`rules/exception-and-result.md`](../rules/exception-and-result.md)。

---

## 1. 为何不在 `love-common` 重复实现

`Result`、`BizException`、`ErrorCode`、`BizErrorCode`、`PageResult` 已在 **`love-common/common-core`** 定义；`GlobalExceptionHandler` 在 **`love-common/common-web`**。

本仓库 `love-common` 承载**源项目横切**抽象（如 BFF 守卫错误码 `LoveErrorCode`、缓存/MQ 等），**不**重复定义 `Result` / `BizException` / `GlobalExceptionHandler`。

---

## 2. Maven 依赖

```xml
<!-- *-api / *-impl：域错误码与抛异常 -->
<dependency>
    <groupId>com.loveforecast</groupId>
    <artifactId>common-core</artifactId>
</dependency>

<!-- BFF / love-app：全局异常处理 -->
<dependency>
    <groupId>com.loveforecast</groupId>
    <artifactId>common-web</artifactId>
</dependency>
```

父 POM 通过 `dependencyManagement` 锁定 `love-common` 版本；本地开发可先 `mvn install` 安装 `love-common` 至本地仓库。

---

## 3. 类型与包名速查

| 类型 | 包 |
|------|-----|
| `Result<T>` | `com.loveforecast.common.core.result` |
| `PageResult<T>` | `com.loveforecast.common.core.result` |
| `BizException` | `com.loveforecast.common.core.exception` |
| `ErrorCode` | `com.loveforecast.common.core.exception` |
| `BizErrorCode` | `com.loveforecast.common.core.exception` |
| `GlobalExceptionHandler` | `com.loveforecast.common.web.handler` |

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
| 200 / 401 / 403 / 404 / 500 / 502 | `ErrorCode`（`love-common/common-core`） | 系统级：鉴权、未找到、内部错误等 |
| BFF 守卫（OpenAPI `code=400`） | `love-common/.../LoveErrorCode` | 空参、时段格式、关键词非法等 |
| 1500~1599 | `advice-api/.../AdviceErrorCode` | 预订订单域 |
| 1600~1699 | `profile-api/.../ProfileErrorCode` | 库存占用域 |
| 1700~1799 | `adapter-api/.../AdapterErrorCode` | 车场南向对接 |

新增业务码：域规则 → 对应 `*-api`；BFF 守卫 → `LoveErrorCode`；Story AC 失败文案与枚举 `message` 对齐。

```java
// BFF Controller 守卫
throw new BizException(LoveErrorCode.INCOMPLETE_BOOKING_INFO);

// AppAuthFilter — 系统级
Result.fail(ErrorCode.UNAUTHORIZED.getCode(), ErrorCode.UNAUTHORIZED.getMessage());
```

---

## 6. V1 与 V2+ 差异

| 场景 | 约定 |
|------|------|
| **V1 单体** | 同 JVM 调 `XxxApi`，`BizException` 直接传播；BFF 无需 RPC 异常解包 |
| **V2+ Feign** | 下游 HTTP 返回 `Result` 失败体时，由 `common-web` 侧 Feign Decoder（按需启用）还原为 `BizException` |
| **i18n** | V1 不做；`message` 中文写死在域错误码枚举；多语言由前端按 `code` 映射（若未来需要） |

---

## 7. 反模式

- 在 `love-common` 再写一套 `Result` / `BizException`
- 域 `XxxApi` 返回 `Result<T>`
- Controller 内 `catch (BizException e) { return Result.fail(...); }`
- 在 `ErrorCode` 枚举中增加 `1501` 等业务码
- 用 `new BizException("自定义字符串")` 代替域错误码（会落 `SYSTEM_ERROR` 的 code）

---

## 7. 相关专项

写操作幂等（支付回调、下单、占库存）见 [idempotency-guide.md](./idempotency-guide.md)。

---

## 变更记录

| 日期 | 变更 |
|------|------|
| 2026-07-26 | 初版：约定依赖 `love-common`，明确 `love-common` 边界与号段 |
