# 定时任务高可靠设计实践指南（Java）

> **L1 静态层上下文资产**：`detail-design` 步骤 6 在 AC/BR 出现批处理、对账、调度、定时清理、超时扫描等关键词时加载本指南。  
> **微服务多实例要求**：每个领域微服务各自运行自身的定时任务，**禁止**将所有任务集中在单一启动模块；微服务默认多副本部署，**必须设计防重叠执行方案**（具体调度与分布式锁框架见 [system-landscape.md](../architecture/system-landscape.md) §5.4 **E-6**，未定则详设阻断）。

---

## 一、定时任务的核心挑战

| 问题 | 后果 |
|------|------|
| 任务重叠执行 | 多实例 / 多 Pod 同时跑同一 cron → 重复取消、重复释放库存 |
| 执行失败无追溯 | 直到人工发现数据不一致 |
| 长任务中断 | 进程重启后从头扫 → 重复处理或漏处理 |
| 不可观测 | 不知是否执行、耗时、处理条数 |

---

## 二、本仓库适用场景

| 场景 | 典型业务（源项目示例） | 建议模块 |
|------|---------------------|----------|
| 超时扫描 | 待支付 5 分钟未付 → 取消预约、释放锁定 | `order-impl` + 调 `InventoryApi` |
| 爽约 / 未入位 | 预约时段开始仍未入位 → 状态迁移 | `order-impl` |
| 资源清理 | 过期临时数据、历史执行日志归档 | 各域 `*-impl` |
| 对账 / 同步 | 与支付系统、车场系统状态核对 | `order-impl` `PaymentClient` / `ParkingLotGateway` |
| 统计报表 | 日/周预约量（Admin） | `booking-bff-admin` 只读查询；批处理在域 Service |

**选型说明**：多实例防重方案以画像 §5.4 **E-6** 为准；若需延迟消息替代轮询扫描，按画像 §5.4 **E-2**（MQ）拍板决定。

---

## 三、设计原则

### 原则 1：防重叠（同一时刻只有一个实例执行，微服务必守）

微服务默认多副本部署，**禁止以「单实例可接受」跳过防重叠设计**；具体方案按画像 §5.4 **E-6** 选型：

| 方案（画像 E-6 备选） | 说明 |
|------|------|
| **ShedLock（JDBC / Redis）** | 轻量注解式分布式锁，适合轻量 `@Scheduled` |
| **DB 分布式锁表** | 基于本服务独立数据库，不额外引入中间件 |
| **XXL-JOB / K8s CronJob** | 独立调度中心或容器层统一调度，适合大量任务统一管控与重试 |

**DB 锁（示意，详设须定表名与 TTL）**：

```sql
-- 可选：专用锁表，或复用 scheduler_execution 唯一约束
CREATE TABLE scheduler_lock (
    lock_name   VARCHAR(128) PRIMARY KEY COMMENT '任务名',
    locked_by   VARCHAR(64)  NOT NULL COMMENT '实例标识',
    locked_at   DATETIME     NOT NULL,
    expire_at   DATETIME     NOT NULL COMMENT '锁过期时间'
);
```

```java
// order-impl/app/scheduler/LockSupport.java（骨架）
public boolean tryLock(String taskName, Duration ttl) {
    // INSERT ... ON DUPLICATE KEY UPDATE 仅当 expire_at < NOW()
    // 或 SELECT ... FOR UPDATE；SQL 写在 Mapper XML
}
```

**ShedLock（可选，多实例推荐）**：

```java
@Scheduled(cron = "${booking.scheduler.unpaid-cancel-cron:0 */1 * * * ?}")
@SchedulerLock(name = "cancelUnpaidReservations", lockAtMostFor = "PT5M", lockAtLeastFor = "PT30S")
public void cancelUnpaidReservations() {
    unpaidCancelJob.run();
}
```

- `lockAtMostFor`：大于任务最长执行时间，防止死锁
- `lockAtLeastFor`：短于 cron 间隔，避免上一趟未结束下一趟又抢锁（按任务调）

**要点**：

- TTL / `lockAtMostFor` ≈ 预期执行时间 × 2；长任务考虑续期或拆批
- 获锁失败 → **直接 skip**，打 INFO 日志，不抛业务异常

### 原则 2：支持失败重试

**执行记录表**（推荐所有定时任务具备）：

```sql
CREATE TABLE scheduler_execution (
    id              BIGINT PRIMARY KEY AUTO_INCREMENT,
    task_name       VARCHAR(128) NOT NULL COMMENT '任务名',
    status          VARCHAR(16)  NOT NULL COMMENT 'RUNNING/SUCCESS/FAILED',
    started_at      DATETIME     NOT NULL,
    finished_at     DATETIME,
    retry_count     INT          NOT NULL DEFAULT 0,
    error_message   TEXT,
    processed_count INT          DEFAULT 0 COMMENT '本次处理条数',
    success_count   INT          DEFAULT 0,
    failed_count    INT          DEFAULT 0,
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_task_status (task_name, status),
    INDEX idx_started (started_at)
);
```

**重试策略**：

| 策略 | 说明 | 适用 |
|------|------|------|
| 同次立即重试（≤N 次） | 循环 + 指数退避 | 网络抖动、短暂 DB 锁 |
| 下次 cron 重试 | 本次标 FAILED，下趟扫描 | 外部支付/车场不可用 |
| 人工补偿 | Admin 触发或工单 | 连续失败超阈值 |

```java
public void executeWithRetry(String taskName, Runnable task) {
    int maxRetries = 3;
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
        try {
            task.run();
            return;
        } catch (Exception e) {
            if (attempt < maxRetries) {
                long waitMs = (long) Math.pow(2, attempt) * 1000L;
                Thread.sleep(waitMs);
            } else {
                executionRepository.markFailed(taskName, e.getMessage());
                log.error("[Scheduler] task={} failed after retries", taskName, e);
            }
        }
    }
}
```

> 生产代码优先用 Spring `RetryTemplate` 或 Resilience4j，详设写明选型。

### 原则 3：断点续跑（Checkpoint）

大批量（如一次扫 >1000 条待取消单）时：

```java
public void cancelExpiredUnpaid() {
    long lastId = checkpointStore.get("cancel_unpaid").orElse(0L);
    while (true) {
        List<ReservationOrderDO> batch = orderMapper.selectUnpaidExpiredAfterId(lastId, 100);
        if (batch.isEmpty()) {
            checkpointStore.clear("cancel_unpaid");
            break;
        }
        for (ReservationOrderDO order : batch) {
            cancelService.cancelUnpaid(order.getId()); // 须幂等
            lastId = order.getId();
        }
        checkpointStore.save("cancel_unpaid", lastId, Duration.ofHours(24));
    }
}
```

**要点**：

- 排序键稳定（`id` 或 `created_at` + `id`）
- **每批**更新 checkpoint，非全部完成才写
- checkpoint 设过期，避免僵尸进度
- **单条处理须幂等**（状态机条件更新：`WHERE status = 'PENDING_PAYMENT'`）

### 原则 4：可观测性

| 信息 | 落点 |
|------|------|
| 开始/结束时间 | `scheduler_execution` |
| 成功/失败/跳过条数 | `processed_count` 等字段 |
| 状态 | SUCCESS / FAILED |
| 错误堆栈 | `error_message` + SLF4J |

```java
log.info("[Scheduler] task={} started", taskName);
log.info("[Scheduler] task={} progress processed={} success={} failed={}", taskName, p, s, f);
log.info("[Scheduler] task={} completed elapsedMs={}", taskName, elapsed);
log.error("[Scheduler] task={} failed", taskName, exception);
```

连续失败 N 次 → 告警（V1 可 `[AI推断]` 仅日志，V2 对接监控）。

---

## 四、本仓库分层落点

```text
{service}-impl       各服务独立启用调度开关（如 @EnableScheduling 或调度中心执行器，按画像 E-6）
order-impl           app/scheduler/* 薄入口 + *Job；业务在 Service
inventory-impl       库存相关定时释放（归属库存微服务独立调度）
*-impl               infrastructure：本服务独立 SchedulerExecution 持久化
```

| 组件 | 路径 | 职责 |
|------|------|------|
| 薄入口 | `*-impl/app/scheduler/` | 触发适配（`@Scheduled` / XXL-Job / K8s CronJob 等）→ 分布式锁防重 → 委托 Job |
| `*Job` | 同上或 `app/job/` | 编排：记录执行、重试、调 Service |
| `*Service` | `app/service/` | 单条/批量业务；**状态机与幂等** |
| 跨服务调用 | `app/client/*Client` | 释放库存经远程契约调用下游微服务（按画像 P-2），禁止跨服务直连他库 |

**禁止**：

- 在 BFF 写定时/批处理触发入口
- 入口类内写核心状态机大段逻辑（应进 Service，便于单测）
- 定时任务直连支付渠道 HTTP（走 `PaymentClient`）

---

## 五、完整模式（Java 骨架）

```java
@Component
@RequiredArgsConstructor
public class UnpaidReservationCancelScheduler {

    private final SchedulerTaskRunner taskRunner;
    private final UnpaidCancelJob unpaidCancelJob;

    @Scheduled(cron = "${booking.scheduler.unpaid-cancel-cron:0 */1 * * * ?}")
    public void schedule() {
        taskRunner.run("cancelUnpaidReservations", unpaidCancelJob::execute);
    }
}

@Component
@RequiredArgsConstructor
public class SchedulerTaskRunner {

    private final LockSupport lockSupport;
    private final SchedulerExecutionRepository executionRepository;

    public void run(String taskName, Runnable task) {
        if (!lockSupport.tryLock(taskName, Duration.ofMinutes(5))) {
            log.info("[Scheduler] {} skipped (lock held)", taskName);
            return;
        }
        long executionId = executionRepository.recordStart(taskName);
        try {
            task.run();
            executionRepository.recordSuccess(executionId);
        } catch (Exception e) {
            executionRepository.recordFailed(executionId, e);
            throw e;
        } finally {
            lockSupport.unlock(taskName);
        }
    }
}
```

详设 §8 须列出：`UnpaidReservationCancelScheduler`、`UnpaidCancelJob`、`SchedulerTaskRunner`（可复用）、`LockSupport`、Mapper/XML。

---

## 六、方案选型决策表

| 任务特征 | 防重叠 | 重试 | Checkpoint | 本仓库示例 |
|---------|--------|------|------------|------------|
| 单次、数据量小 | 是（多副本时） | 同次立即重试 | 否 | 清理昨日执行日志 |
| 批量 >1000 | 是 | 是 | **是** | 扫描待取消预约单 |
| 调外部系统 | 是 | 指数退避 | 视批量 | 支付对账、车场状态同步 |
| 只读统计 | 是 | 是 | 否 | 日报聚合 |

---

## 七、与预约业务的状态机（须幂等）

定时取消须满足：

1. `UPDATE ... WHERE id = ? AND status = 'PENDING_PAYMENT' AND expire_at < NOW()`
2. 仅当更新行数 = 1 时调用 `InventoryApi.release(...)`
3. 重复执行同一条 → 更新 0 行，**不**重复释放

详设 §4.3 / §7 须画：Scheduler → OrderService → InventoryApi 时序图。

---

## 八、设计 Checklist（详设专项节粘贴）

- [ ] 任务归属微服务（`order-impl` / `inventory-impl`）与调度配置项
- [ ] 多实例防重叠方案已对齐画像 §5.4 E-6（ShedLock / DB 锁 / XXL-JOB / K8s CronJob；禁止省略防重）
- [ ] 锁 TTL / `lockAtMostFor`；长任务是否续期或拆批
- [ ] 失败重试策略与最大次数
- [ ] 是否 `scheduler_execution` 表；字段与索引
- [ ] 批量是否 checkpoint；排序键
- [ ] 单条处理是否幂等（状态条件更新）
- [ ] §8 类清单：`Scheduler`、`Job`、`Service`、Mapper
- [ ] §9 测试：`JobTest` / `ServiceTest` Mock 依赖；不依赖真实 cron 触发
- [ ] 是否 Admin 手动触发（可选 HTTP，走 `booking-bff-admin`）

---

## 九、测试策略（feature-coding）

| 层 | 做法 |
|----|------|
| Service | 测「给定过期待支付单 → 取消 + 调 InventoryApi」；Mock Mapper / Client |
| Job | 测 runner 在获锁/失败时行为；Mock LockSupport |
| Scheduler | 一般不测 cron；集成可选 `@SpringBootTest` + 手动调用 `Job` |

**禁止**：测试依赖真实 sleep 等待 cron；用直接调用 `job.execute()` 代替。

---

## 十、与公司级 Python 指南的差异

| Python Demo | 本仓库 Java |
|-------------|-------------|
| `async def` + Redis 锁 | `@Scheduled` + DB 锁 / ShedLock JDBC |
| `redis` checkpoint | DB 表或 Redis（V2+）；V1 优先 DB |
| `t_scheduler_execution` | `scheduler_execution`（表名详设与 schema 统一） |
| `app/modules/` | `*-impl/app/scheduler/` |

---

## 延伸阅读

- [special-scenarios.md](../skills/detail-design/references/special-scenarios.md) — 关键词识别
- [code-skeleton-guide.md](../skills/detail-design/references/code-skeleton-guide.md) — Service / Client 分层
- HLD（源项目 `HLD-EPIC-{项目}`）——定时任务集成矩阵
