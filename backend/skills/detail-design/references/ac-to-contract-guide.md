# AC → 契约映射指引（源项目 · Java）

> 配套 `detail-design` Skill。边界以 [system-landscape.md](../../../architecture/system-landscape.md) 为准。

## 1. 先判断 Story 类型

| 类型 | 主契约 | 次要契约 |
|------|--------|----------|
| **App/Admin 对外 HTTP** | BFF OpenAPI + BFF Controller 骨架 | 响应格式与错误码（按画像 §3.7 / P-4） |
| **领域微服务能力** | 按画像 §5.4 P-2：内部 OpenAPI（HTTP）或 `*-api` 远程接口/`.proto`（RPC）+ Service 骨架 | Facade、跨服务时序图、内部防护（P-5） |
| **支付集成** | `PaymentClient` + 时序图 | 回调 URL、幂等 |
| **车场南向** | `ParkingLotGateway` + 厂商适配微服务 | 超时、重试 |
| **异步消息 / 事件** | 按画像 §5.4 E-2 / E-4（消息中间件与事件契约，未定则阻断） | 消费侧幂等、失败重试/死信 |

## 2. HTTP 类 AC → API（五步）

1. **定 BFF**：C 端 → `booking-bff-app`；运营 → `booking-bff-admin`  
2. **识资源**：名词 → REST 资源（常复数）  
3. **映射 Method**：GET/POST/PATCH；动作用 `POST .../动词`  
4. **推字段与错误码**：Given→path/query；When→body；Then→`Result.data`；异常→业务码（1500/1550/1600/1700/1800/1900 段，号段见 `rules/exception-and-result.md`）  
5. **建映射表**：path 必须以 `/api/v1/booking/app/` 或 `/api/v1/booking/admin/` 开头  
6. **写 OpenAPI**：按 [openapi-conventions.md](./openapi-conventions.md) — `BusinessErrorBody`、每接口 success/fail `examples`、`servers`、`securitySchemes`

## 3. 领域微服务 AC → 内部契约与服务（六步）

1. **识能力**：动词 → Facade/Service 方法  
2. **定服务**：按画像 §二 确定归属微服务（如 order / inventory / adapter）  
3. **定内部远程入口**：按画像 §5.4 **P-2**（HTTP 协议 → `*-impl` 内部 Controller + `docs/api/{领域服务}/openapi.yaml` + `*-api` 客户端；RPC 协议 → `*-api` 远程接口/`.proto` + `*-impl` Provider）；内部防外泄按 **P-5**  
4. **定领域对象**：§4 聚合/实体；契约 DTO 在 `*-api`  
5. **定跨服务调用**：如 order 调 inventory → `order-impl/app/client/InventoryClient` 封装 `inventory-api` 远程客户端（按 P-2）；若涉及跨服务写库，一致性方案按画像 **E-3**（未定则阻断）  
6. **建追溯表**：每条 AC 一行落点或 N/A  

## 4. 何时画时序图

- BFF → order → inventory（下单占库存，标注各服务本地事务与一致性边界）  
- order → PaymentClient → 支付系统  
- order/inventory → 适配微服务 → 外部厂商  
- 取消/退款 + 释放库存 + 回调 / 异步消息  

## 5. 增量对齐检查清单

- [ ] 已读 system-landscape 服务清单、URL 与 §5.4 两档选型（命中的 `[TBD]` 已阻断拍板）  
- [ ] 已读存量 `*-api`/`*-impl`/BFF  
- [ ] 已查 `docs/api/{服务标识}/openapi.yaml`（含 BFF 对外与领域内部契约）  
- [ ] 对外 HTTP 仅放 BFF，领域服务内部接口已落实防外泄要求（P-5）  
- [ ] §8 骨架符合 [code-skeleton-guide.md](./code-skeleton-guide.md)  
- [ ] BFF/领域服务职责符合 [bff-domain-boundary-guide.md](./bff-domain-boundary-guide.md) §6  
- [ ] 持久化符合画像 §5.4 P-3（选 MyBatis 时见 `rules/mybatis-conventions.md`），无跨服务 JOIN/外键  
- [ ] OpenAPI 符合 [openapi-conventions.md](./openapi-conventions.md)（examples、security、响应语义对齐画像 §3.7）  
- [ ] Story 失败类 AC 均在 OpenAPI `examples` 或详设 §5.3 标 N/A  
- [ ] 同名 DD 不静默覆盖  
- [ ] OpenAPI / 内部契约变更已用户确认
