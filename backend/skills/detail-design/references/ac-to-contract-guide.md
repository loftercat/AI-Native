# AC → 契约映射指引（源项目 · Java）

> 配套 `detail-design` Skill。边界以 [system-landscape.md](../../../architecture/system-landscape.md) 为准。

## 1. 先判断 Story 类型

| 类型 | 主契约 | 次要契约 |
|------|--------|----------|
| **App/Admin HTTP** | OpenAPI + BFF Controller 骨架 | `Result`、错误码 |
| **域服务** | `XxxApi` + 领域模型 + Service 骨架 | Facade、时序图 |
| **支付集成** | `PaymentClient` + 时序图 | 回调 URL、幂等 |
| **车场南向** | `ParkingLotGateway` + 厂商 Adapter | 超时、重试 |
| **进程内事件** | 事件类 + Listener 骨架（V1 Spring Event） | 消费幂等 |

## 2. HTTP 类 AC → API（五步）

1. **定 BFF**：C 端 → `booking-bff-app`；运营 → `booking-bff-admin`  
2. **识资源**：名词 → REST 资源（常复数）  
3. **映射 Method**：GET/POST/PATCH；动作用 `POST .../动词`  
4. **推字段与错误码**：Given→path/query；When→body；Then→`Result.data`；异常→业务码（1500/1550/1600/1700/1800/1900 段，号段见 `rules/exception-and-result.md`）  
5. **建映射表**：path 必须以 `/api/v1/booking/app/` 或 `/api/v1/booking/admin/` 开头  
6. **写 OpenAPI**：按 [openapi-conventions.md](./openapi-conventions.md) — `BusinessErrorBody`、每接口 success/fail `examples`、`servers`、`securitySchemes`

## 3. 域服务 AC → 模块（六步）

1. **识能力**：动词 → Facade/Service 方法  
2. **定域**：order / inventory / adapter  
3. **定入口**：`XxxApi`（`order-api` 等）；**不是** Controller  
4. **定领域对象**：§4 聚合/实体；DTO 在 `*-api`  
5. **定跨域**：order 调 inventory → `order-impl/app/client/InventoryClient` 注入 `InventoryApi`  
6. **建追溯表**：每条 AC 一行落点或 N/A  

## 4. 何时画时序图

- BFF → order → inventory（下单占库存）  
- order → PaymentClient → 支付系统  
- order/inventory → ParkingLotGateway → 厂商  
- 取消/退款 + 释放库存 + 回调  

## 5. 增量对齐检查清单

- [ ] 已读 system-landscape 模块与 URL  
- [ ] 已读存量 `*-api`/`*-impl`/BFF  
- [ ] 已查 `docs/api/**/openapi.yaml`  
- [ ] HTTP 未误放在 `*-impl`  
- [ ] §8 骨架符合 [code-skeleton-guide.md](./code-skeleton-guide.md)  
- [ ] BFF/域职责符合 [bff-domain-boundary-guide.md](./bff-domain-boundary-guide.md) §6  
- [ ] 持久化：主键用 MyBatis Plus；其余 SQL 仅 XML（见 `rules/mybatis-conventions.md`）  
- [ ] OpenAPI 符合 [openapi-conventions.md](./openapi-conventions.md)（examples、security、Result 语义）  
- [ ] Story 失败类 AC 均在 OpenAPI `examples` 或详设 §5.3 标 N/A  
- [ ] 同名 DD 不静默覆盖  
- [ ] OpenAPI 变更已用户确认  
