# AC → 契约映射指引（Java 微服务）

> 配套 `detail-design` Skill。边界以 [system-landscape.md](../../../architecture/system-landscape.md) 为准。

## 1. 先判断 Story 类型

| 类型 | 主契约 | 次要契约 |
|------|--------|----------|
| **App/Admin 对外 HTTP** | BFF OpenAPI + BFF Controller 骨架 | 响应格式与错误码（按画像 §3.7 / P-4） |
| **领域微服务能力** | 按画像 §5.4 P-2：内部 OpenAPI（HTTP）或 `*-api` 远程接口/`.proto`（RPC）+ Service 骨架 | Facade、跨服务时序图、内部防护（P-5） |
| **外部系统集成** | `{External}Client` + 时序图 | 回调 URL、幂等 |
| **第三方南向适配** | `{External}Gateway` + `{project}-adapter` 适配微服务 | 超时、重试 |
| **异步消息 / 事件** | 按画像 §5.4 E-2 / E-4（消息中间件与事件契约，未定则阻断） | 消费侧幂等、失败重试/死信 |

## 2. HTTP 类 AC → API（六步）

1. **定 BFF**：C 端 → `{project}-bff-app`；B 端/运营 → `{project}-bff-admin`  
2. **识资源**：名词 → REST 资源（常复数）  
3. **映射 Method**：GET/POST/PATCH；动作用 `POST .../动词`  
4. **推字段与错误码**：Given→path/query；When→body；Then→`{Result<T>}.data`；异常→业务码（各领域服务错误码号段以画像 §3.7 与 `rules/exception-and-result.md` 为准）  
5. **建映射表**：path 必须以 `/api/v1/{project}/app/` 或 `/api/v1/{project}/admin/` 开头  
6. **写 OpenAPI**：按 [openapi-conventions.md](./openapi-conventions.md) — `BusinessErrorBody`、每接口 success/fail `examples`、`servers`、`securitySchemes`

## 3. 领域微服务 AC → 内部契约与服务（六步）

1. **识能力**：动词 → `{Entity}Facade` / `{Entity}QueryService` / `{Entity}CommandService` 方法  
2. **定服务**：按画像 §二 确定归属微服务（如 `{project}-{domain-a}` / `{project}-{domain-b}` / `{project}-adapter`）  
3. **定内部远程入口**：按画像 §5.4 **P-2**（HTTP 协议 → `*-impl` 内部 Controller（如 `/internal/v1/{service}/...`）+ `docs/api/{领域服务标识}/openapi.yaml` + `*-api` 客户端；RPC 协议 → `*-api` 远程接口/`.proto` + `*-impl` Provider）；内部防外泄按 **P-5**  
4. **定领域对象**：§4 聚合/实体；契约 `{Entity}DTO` 在 `*-api`  
5. **定跨服务调用**：如 `{domain-a}` 调 `{domain-b}` → `{domain-a}-impl/app/client/{DomainB}Client` 封装 `{domain-b}-api` 远程客户端（按 P-2 与画像 §3.6）；若涉及跨服务写库，一致性方案按画像 **E-3**（未定则阻断）  
6. **建追溯表**：每条 AC 一行落点或 N/A  

## 4. 何时画时序图

- BFF → `{domain-a}` → `{domain-b}`（跨服务写与资源占用，标注各服务本地事务与一致性边界）  
- `{domain-a}` → `{External}Client` → 外部系统（对接边界见画像 §四）  
- `{domain-a}` / `{domain-b}` → `{project}-adapter` 适配微服务 → 外部厂商系统  
- 逆向取消 / 补偿 + 资源释放 + 外部回调 / 异步消息  

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
