# 专项设计场景识别（已落地源项目示例）

> `detail-design` 步骤 6 按本表扫描 Story AC/BR 关键词；命中则加载指南或 Rule 并在详设中单开子节。

## 识别规则

| 场景 | AC/BR 关键词（示例） | 设计落点 | 加载资产 |
|------|---------------------|----------|----------|
| **支付编排** | 支付、订金、退款、回调、预下单 | `order-impl` `PaymentClient`；BFF 回调 Controller；时序图 order→支付系统 | [system-landscape.md](../../../architecture/system-landscape.md) §4.1；[exception-and-result.md](../../../reference/exception-and-result.md) |
| **幂等 / 重复提交** | 幂等、重复提交、重试、双击、防重复、重复通知、Webhook | 方案 A/B/C/D；支付回调、下单、占库存见指南 | [idempotency-guide.md](../../../reference/idempotency-guide.md) |
| **库存锁定** | 锁定、占用、释放、超卖 | `inventory-impl` Service + **方案 D** 条件更新；与 order 时序图 | [idempotency-guide.md](../../../reference/idempotency-guide.md)；[domain-glossary.md](../../../glossary/domain-glossary.md) |
| **车场南向** | 开闸、核销、厂商、新伯乐、德立云 | `ParkingLotGateway` + `adapter-impl`；超时/重试策略 | system-landscape §4.3 |
| **车主鉴权** | 车主、登录、Token | `booking-bff-app` Filter；依赖基础设施 Story 或 Mock | system-landscape §4.2 |
| **运营鉴权** | 运营、后台、权限 | `booking-bff-admin` + `iam-server` Token 校验 | 不实现登录页 |
| **异步消息 / 事件** | 事件、异步通知、MQ、延迟消息、削峰 | 按画像 §5.4 **E-2（MQ）** 与 **E-4（事件契约）** 设计（若为 `[TBD]` 则步骤 4 阻断）；含消费侧幂等与失败重试 | [idempotency-guide.md](../../../reference/idempotency-guide.md)；[system-landscape.md](../../../architecture/system-landscape.md) §5.4 |
| **定时任务** | 定时、调度、批处理、超时取消、对账、清理、扫描 | 各微服务独立调度；多实例默认必防重，方案按画像 §5.4 **E-6**（若为 `[TBD]` 则阻断） | [scheduled-task-guide.md](../../../reference/scheduled-task-guide.md) |
| **跨服务写一致性** | 跨服务写、分布式事务、最终一致、Outbox、Saga、补偿、对账 | 单操作涉及 ≥2 个微服务写库 → 按画像 §5.4 **E-3** 设计（若为 `[TBD]` 则阻断）；严禁本地 `@Transactional` 跨服务 | [system-landscape.md](../../../architecture/system-landscape.md) §5.4 |
| **调用链追踪 / 日志** | 链路追踪、traceId、跨服务排障、审计日志 | 按画像 §5.4 **E-7** 约定透传追踪头与日志关联字段（若为 `[TBD]` 则阻断） | [system-landscape.md](../../../architecture/system-landscape.md) §5.4 |
| **大文件 IO** | 导入、导出、ZIP、附件、上传、下载、报表 | BFF 流式上传/下载；`*-impl` 分批查询 + 写文件；异步任务（大数据量） | [memory-safe-io-guide.md](../../../reference/memory-safe-io-guide.md)；`rules/memory-safe-io.md` |

## 多场景同时命中

在详设中各开独立小节，例如：

- §5.5 支付回调接口
- §7.2 支付回调时序图
- §8.3 `PaymentCallbackController`、`PaymentClient`

## 指南缺失时

- 基于通用知识设计
- 标 `[AI推断]`
- 在步骤 11 汇总建议补充 `reference/` 指南

## 本仓库已落地参考

| 指南 | 路径 |
|------|------|
| 响应 / 异常 / 错误码 | [reference/exception-and-result.md](../../../reference/exception-and-result.md) |
| 幂等性 | [reference/idempotency-guide.md](../../../reference/idempotency-guide.md) |
| 定时任务 | [reference/scheduled-task-guide.md](../../../reference/scheduled-task-guide.md) |
| OpenAPI 自动化 | [openapi-conventions.md](./openapi-conventions.md) |
| MyBatis 分工 | `rules/mybatis-conventions.md` |
