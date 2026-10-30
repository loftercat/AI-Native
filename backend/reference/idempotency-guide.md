# 幂等性设计实践指南（Java）

> **L1 静态层上下文资产**：`detail-design` 步骤 6 在 AC/BR 出现创建、提交、回调、重复通知、重试、防重复等关键词时加载本指南。  
> 异常与错误码见 [exception-and-result.md](./exception-and-result.md)；支付/库存场景见 [special-scenarios.md](../skills/detail-design/references/special-scenarios.md)。

---

## 一、什么是幂等性

**同一操作执行一次和执行多次，对系统状态的影响完全相同。**

重复请求不可避免：用户双击、前端超时重试、网关重试、支付系统重复回调、MQ 重复投递（V2+）、服务间超时重试。

**本仓库高风险示例**：

| 重复后果 | 业务 |
|----------|------|
| 重复扣款 / 重复推进支付成功 | 支付回调 |
| 超卖 / 重复锁定 | 创建预约单 + 占库存 |
| 重复释放库存 | 取消、超时扫描 |
| 重复创建预约单 | 下单 POST |

---

## 二、适用场景

| 场景 | 触发原因 | 本仓库典型业务 |
|------|---------|----------------|
| 前端重复提交 | 双击、刷新 | 创建预约单、发起支付 |
| 接口超时重试 | App / 网关重试 | BFF 写操作 POST |
| 支付回调重复 | 支付系统 at-least-once | `PaymentCallbackController` |
| 服务间重试 | 同 JVM 或 V2+ Feign | `order` → `inventory` 锁定 |
| MQ 重复消费 | V2+ | Spring Event 监听器亦建议幂等 |
| 定时任务重跑 | 见 [scheduled-task-guide.md](./scheduled-task-guide.md) | 超时取消、释放库存 |

---

## 三、HTTP 方法的天然幂等性

| 方法 | 天然幂等？ | 说明 |
|------|----------|------|
| GET | 是 | 只读 |
| PUT | 是 | 全量替换 |
| DELETE | 是 | 最终「已删除」 |
| PATCH | 不一定 | 「设为某值」幂等；「+N」非幂等 |
| **POST** | **否** | 创建/动作类 → **须评估幂等设计** |

本仓库 BFF 对外写操作以 **POST** 为主（预约、支付、分配等），详设 §5 须标注幂等方案。

---

## 四、幂等方案选型

### 方案 A：幂等键 + Redis（敏感写操作，按需）

**适用**：交易、资金、库存、状态机不可逆推进等 **重复不可接受** 的 POST。

**不适用**（可降级）：

- 普通配置、草稿、低价值重复一条可人工处理
- 读多写少、重复概率极低的 Admin 配置

> 全站 POST 统一幂等键成本高；**先判断重复后果，再决定是否上方案 A**。

**流程**：

```text
客户端 X-Idempotency-Key → BFF
    → Redis SETNX idempotency:{key} processing EX 86400
        ├─ 成功：执行业务 → 缓存 Result JSON → 返回
        └─ 失败：GET 缓存结果返回；或 processing → 返回「处理中」
```

**幂等键建议**：

| 场景 | Key 格式 | 示例 |
|------|---------|------|
| 前端表单 | UUID（打开页生成） | `550e8400-e29b-41d4-a716-446655440000` |
| 业务单据 | `{biz}:{id}:{action}` | `reservation:10001:pay` |
| 支付回调 | 支付系统通知 ID | `payment:notify:{outTradeNo}` |
| 服务间 | `{source}:{txnId}` | `payment:txn-abc-123` |

**BFF 实现要点（Java 骨架）**：

```java
// booking-bff-app/.../IdempotencyFilter 或 AOP（详设命名）
public Optional<Result<?>> check(String key) {
    String cached = redisTemplate.opsForValue().get("idempotency:" + key);
    if (cached != null && !"processing".equals(cached)) {
        return Optional.of(objectMapper.readValue(cached, Result.class));
    }
    Boolean locked = redisTemplate.opsForValue()
        .setIfAbsent("idempotency:" + key, "processing", Duration.ofHours(24));
    if (Boolean.FALSE.equals(locked)) {
        throw new BizException(CommonErrorCode.REQUEST_PROCESSING); // 或返回 409 语义业务码
    }
    return Optional.empty();
}

public void save(String key, Result<?> response) {
    redisTemplate.opsForValue().set("idempotency:" + key, toJson(response), Duration.ofHours(24));
}
```

V1 无 Redis 时：敏感接口改用 **方案 B/C** 或 DB 幂等表，详设 §1.3 记 ADR。

### 方案 B：数据库唯一索引（创建类，简单有效）

**适用**：有天然唯一业务键的创建/回调。

| 本仓库场景 | 唯一约束 | 说明 |
|-----------|---------|------|
| 支付回调 | `payment_notify_id` 或 `(out_trade_no, notify_type)` | 支付系统流水号 |
| 预约单（可选） | `(user_id, client_request_id)` | 前端传 `clientRequestId` |
| 车场主数据 | `(lot_code)` 等 | Admin 配置 Story |

```java
public ReservationOrderDTO createOrder(CreateOrderCommand cmd) {
    try {
        orderMapper.insert(orderDO);
        return toDto(orderDO);
    } catch (DuplicateKeyException e) {
        return orderMapper.selectByUserAndClientRequestId(cmd.getUserId(), cmd.getClientRequestId())
            .map(this::toDto)
            .orElseThrow(() -> new BizException(OrderErrorCode.CONFLICT));
    }
}
```

MyBatis：唯一冲突由 DB 抛出，Service 捕获 `DuplicateKeyException`（Spring 包装）处理。

### 方案 C：幂等表（更新/回调无天然唯一键）

```sql
CREATE TABLE idempotency_record (
    id              BIGINT PRIMARY KEY AUTO_INCREMENT,
    idempotency_key VARCHAR(128) NOT NULL,
    biz_type        VARCHAR(64)  NOT NULL COMMENT '如 PAYMENT_CALLBACK',
    response_body   TEXT COMMENT '可选：缓存 Result JSON',
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_key_type (idempotency_key, biz_type)
);
```

**与事务**：幂等记录插入与业务更新**同一 `@Transactional`**；先插幂等行，冲突则查历史返回。

```java
@Transactional
public void handlePaymentCallback(PaymentNotify notify) {
    String key = notify.getOutTradeNo();
    if (!idempotencyRepository.tryInsert(key, "PAYMENT_CALLBACK")) {
        return; // 已处理，直接返回（HTTP 200）
    }
    orderService.markPaid(notify); // 内部状态机条件更新
}
```

### 方案 D：状态机条件更新（更新类，本仓库最常用）

**适用**：库存锁定/释放、预约单状态迁移——**不新增幂等键**，用 `WHERE status = ?` 保证重复执行无副作用。

```java
// inventory-impl
int updated = parkingSpaceMapper.updateStatus(
    spaceId, SpaceStatus.AVAILABLE, SpaceStatus.LOCKED, orderId);
if (updated == 0) {
    // 已锁定或已占用 → 查当前状态决定返回或抛错
}
```

```xml
<!-- ParkingSpaceMapper.xml -->
<update id="updateStatus">
  UPDATE parking_space
  SET status = #{toStatus}, lock_order_id = #{orderId}, updated_at = NOW()
  WHERE id = #{spaceId} AND status = #{fromStatus}
</update>
```

支付回调 + 订单状态：

```java
int rows = orderMapper.updateStatus(orderId, PENDING_PAYMENT, PAID, payTime);
if (rows == 0) {
    log.info("Payment callback idempotent skip orderId={}", orderId);
    return;
}
```

**与方案 A/B/C 组合**：回调用 B 或 C 防重复入口；领域内用 D 防重复推进。

---

## 五、本仓库分层落点

| 层级 | 幂等职责 |
|------|----------|
| **BFF** | 可选 `X-Idempotency-Key` 过滤器（方案 A）；支付回调 HTTP 入口 |
| **order-impl Service** | 预约单状态机（D）；支付回调编排（B/C+D） |
| **inventory-impl Service** | 锁定/释放（D + 乐观锁） |
| **Mapper/XML** | 条件更新、`UNIQUE` 约束 |

**禁止**：仅在 Controller 判重而不做 DB 条件更新（并发仍可能双写）。

---

## 六、方案选型决策表

| 条件 | 推荐方案 |
|------|---------|
| POST 创建 + 天然唯一键（支付流水、clientRequestId） | **B** 唯一索引 |
| POST 创建 + 普通业务、重复可容忍 | 前端防抖；必要时 **B** |
| 支付/占库存/退款 + 重复不可接受 | **A**（有 Redis）或 **B/C** + **D** |
| 支付/第三方回调 | **B**（notifyId）或 **C** + **D** |
| 状态迁移（锁定、取消、支付成功） | **D** 条件更新（必选） |
| 定时任务批量处理 | **D** + [scheduled-task-guide.md](./scheduled-task-guide.md) checkpoint |

**是否上方案 A 的快速判断**：

1. 重复会 **扣款、超卖、重复锁定**？→ 是 → A 或 B/C+D  
2. 重复仅多一条非关键记录？→ **不必 A**

---

## 七、重复请求的响应语义

| 情况 | 建议 |
|------|------|
| 已完成，有缓存 | 返回**首次** `Result`（`code===200` 与相同 `data`） |
| 处理中（并发窗口） | `BizException` 业务码「请求处理中」或 HTTP 200 + 明确 message |
| 业务已处于目标状态（方案 D） | 返回成功（幂等成功），勿报 500 |

OpenAPI：回调接口须在 §5.3 与 `examples` 注明重复回调仍返回 200。

---

## 八、设计 Checklist（详设专项节）

- [ ] 是否写操作？GET 跳过
- [ ] 重复调用风险？（前端/回调/重试/定时任务）
- [ ] 重复后果是否不可接受？
- [ ] 选定方案 A/B/C/D（可组合）
- [ ] 幂等键谁生成、放 Header 还是 body/回调字段？
- [ ] 过期时间（Redis 建议 24h；DB 幂等表归档策略）
- [ ] 重复请求返回首次结果还是「处理中」？
- [ ] §7 时序图 `alt` 重复回调/重复提交
- [ ] §8 类：`IdempotencyFilter`、`IdempotencyRepository`、`XxxMapper.updateStatus`
- [ ] §9 测试：连续两次调用状态不变、Mock 重复回调

---

## 九、测试策略（feature-coding）

```java
@Test
void handleCallback_whenDuplicateNotify_doesNotDoubleMarkPaid() {
    PaymentNotify notify = buildNotify("notify-001");
    service.handlePaymentCallback(notify);
    service.handlePaymentCallback(notify); // 第二次
    verify(orderMapper, times(1)).updateStatus(eq(1L), eq(PENDING_PAYMENT), eq(PAID), any());
}
```

- Service 层覆盖 **D**；BFF 层覆盖 **A**（Mock Redis）
- 不依赖真实 Redis/支付环境

---

## 十、与公司级 Python 指南的差异

| Python Demo | 本仓库 Java |
|-------------|-------------|
| `async` + Redis | `StringRedisTemplate` / Redisson；V1 可无 Redis |
| `IntegrityError` | `DuplicateKeyException` |
| `t_idempotency_record` | `idempotency_record`（表名与 schema 统一） |
| 全站中间件 | BFF Filter + 域 Service 条件更新 |
| 错误码 `10409` | 用 `hema-common` / 域 `*ErrorCode`，详设 §5.3 定义 |

---

## 延伸阅读

- [exception-and-result.md](./exception-and-result.md)
- [scheduled-task-guide.md](./scheduled-task-guide.md)
- [domain-glossary.md](../glossary/domain-glossary.md) — 预约单/车位状态
