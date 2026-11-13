# 领域模型指引（Java · api/impl 分层）

## 务实领域模型（本仓库默认）

> **分层架构不变**；领域「厚度」按 Story 复杂度渐进。**非**经典 DDD「查整聚合 → 内存改 → save 整包」。

### 一句话

- **简单业务**：`Service` + `*DO` + DTO，业务逻辑可直接写在 Service；**不必**建 `domain.model` 类。  
- **复杂业务**：可选 **贫血** `domain/model/*` 做校验/状态机判断；**持久化仍以 Mapper XML 条件 `UPDATE`/`INSERT` 为主**。  
- **§4 概念名**（预约单、聚合根）是统一语言；**§8 必须写真实 Java 落点**（常为 `*DO` + DTO，而非 `BookingOrder` 实体类）。

### 简单 vs 复杂（详设 §1.3 或 §4.4 须标明 `领域厚度`）

| 倾向 | 场景示例 |
|------|----------|
| **薄（无 domain 类）** | 只读查询；规则主要在 SQL；单表 CRUD；无状态迁移 |
| **中（Service 闭环）** | 少量 `if` + 枚举；`QueryService` 组装 DTO |
| **厚（可选贫血 domain）** | 状态机迁移；多不变量；支付/取消/超时编排；规则多入口复用 |

### 持久化（写操作默认）

| 推荐 | 避免（V1 默认不做） |
|------|---------------------|
| `UPDATE ... WHERE id=? AND status=?` 条件更新 | 查整行 DO → 改字段 → `updateById` 全量覆盖 |
| `affected_rows=0` → 并发/状态非法 → `BizException` | 无旧状态条件的盲 `UPDATE` |
| 批量超时：`UPDATE ... WHERE status=? AND deadline<?` | 定时任务逐条 load 聚合再 save |
| 跨表：`@Transactional` + 多个 Mapper 方法 | 单一「聚合仓储 save」包全部副作用 |

条件更新 SQL 须在详设 **§6.2** 列出 Mapper 方法名与 XML `id`。

### 贫血 domain 用法（复杂 Story 可选）

```text
advice-impl/
  domain/model/BookingOrder.java     # 贫血：字段 + canPay()/validateCancel() 等
  app/service/BookingOrderCommandService.java  # 编排：校验 → mapper.updateStatus(...)
  infrastructure/mapper/...        # 实际落库
```

- Domain 类 **可不** 负责持久化；校验后可调 `mapper.updateStatus(id, fromStatus, toStatus)`。  
- 读路径可继续 **Mapper → DO → DTO**，不必经过 domain 类。

---

## 完整范例（本仓库 Story）

### 范例 A：薄 — 查询当前进行中预约（STORY-2026-S01-002）

**场景**：只读；规则在 SQL（哪些状态算进行中、BR-02 优先级）；无状态迁移。

**详设 §4.4（摘录）**

| AC | 领域概念 | 代码落点（§8） | 领域厚度 | 说明 |
|----|----------|----------------|----------|------|
| AC-01～06 | 预约单（文档） | `BookingOrderDO`、`BookingOrderStatus` | **薄** | 无 `domain.model.BookingOrder` |
| AC-01～06 | 进行中预约 | `ActiveReservationQueryResultDTO` | **薄** | 读模型 DTO |
| BR-02 | — | `BookingOrderMapper.selectTopActiveByUserId` | **薄** | XML 内 `ORDER BY` + `LIMIT 1` |

**代码路径（与现网一致）**

```text
BookingOrderMapper.selectTopActiveByUserId(userId)
  → BookingOrderDO
  → BookingOrderQueryService.toSummary()
  → ActiveReservationSummaryDTO
  → ActiveReservationQueryResultDTO
  → BookingOrderApi → AppReservationController → Result<VO>
```

**Service 核心逻辑（示意）**

```java
BookingOrderDO order = bookingOrderMapper.selectTopActiveByUserId(userId);
if (order == null) {
    return ActiveReservationQueryResultDTO.noActive();
}
return ActiveReservationQueryResultDTO.of(toSummary(order));
```

**不做什么**：不建 `BookingOrder` 领域类；不把 DO 查出来再 `updateById`（本 Story 无写操作）。

---

### 范例 B：厚 — 支付成功 → 待使用（后续 Story 示意）

**场景**：状态迁移；需校验「当前必须是待支付」；可能与库存域同事务；规则会在回调、重试中复用。

**领域厚度**：**厚** — 可选贫血 `BookingOrder` 做 `canMarkPaid()`；**落库仍用条件 UPDATE**。

**详设 §6.2（写操作须写清）**

| Mapper 方法 | XML `id` | SQL 要点 |
|-------------|----------|----------|
| `updateStatusIfMatch` | `updateStatusIfMatch` | `UPDATE booking_order SET status='PENDING_USE' WHERE id=? AND status='PENDING_PAYMENT'` |
| （inventory）`updateSpaceStatusIfMatch` | 同上模式 | 车位 `LOCKED` → `RESERVED` |

**编排（示意）**

```java
@Transactional
public void onPaymentSuccess(Long orderId, String paymentNo) {
    BookingOrderDO row = bookingOrderMapper.selectById(orderId);
    BookingOrder order = BookingOrder.from(row); // 贫血：仅承载校验

    if (!order.canMarkPaid(paymentNo)) {
        throw new BizException(AdviceErrorCode.INVALID_STATE);
    }

    int n = bookingOrderMapper.updateStatusIfMatch(
            orderId, BookingOrderStatus.PENDING_PAYMENT, BookingOrderStatus.PENDING_USE);
    if (n == 0) {
        throw new BizException(AdviceErrorCode.CONCURRENT_UPDATE); // 并发或已处理
    }
    inventoryApi.markSpaceReserved(row.getSpaceId()); // 另一 Mapper 条件 UPDATE
}
```

**贫血 domain（示意）**

```java
public boolean canMarkPaid(String paymentNo) {
    return status == PENDING_PAYMENT && payDeadline != null && !payDeadline.isBefore(now());
}
```

**对比经典 DDD（本仓库默认不做）**

```text
❌ selectById → 改 DO 字段 → updateById(整行)
✅ updateStatusIfMatch(id, from, to) + affected_rows 判断
```

---

## 四步

1. **识概念**：AC 名词 → 实体 / 值对象 / 聚合根（**文档概念**，不一定 1:1 Java 类）  
2. **定边界**：聚合内外；`*-api` DTO 与 `*-impl` 分离；**§4.4 写概念 → §8 代码落点**  
3. **定不变量**：BR → 唯一性、状态迁移、订金/时段规则（见 domain-glossary）  
4. **建映射表**：§4.4（含代码落点列）与 §8 类名可追溯  
5. **写 §4.3**：主标题白话 + `> 技术：` 引导句；查询子集单独 **§4.3.2**（见下方）  
6. **标领域厚度**：§4.4 或 §8.2 注明 **薄 / 中 / 厚** 及是否建 `domain/model`

## 落点（本仓库）

### 域 Service 命名（与 code-skeleton-guide §3.1 一致）

- **`{实体}QueryService`**：只读（SELECT、统计、**只读推荐**如 `allocateNearest`）
- **`{实体}CommandService`**：写库（INSERT、条件 UPDATE、软删）；动作在**方法名**（`lockSpace`、`createPendingOrder`）
- **禁止** `{动作}Service`（如 `SpaceLockService`、`SpaceAllocateService`）— 易与 Facade 职责混淆

| 概念（§4） | 常见代码落点（§8） |
|------------|-------------------|
| 聚合根 / 实体（文档） | 薄：`BookingOrderDO` + `*Status` 枚举；厚：可选 `domain/model/BookingOrder`（贫血） |
| 查询视图 / 读模型 | `*QueryResultDTO`、`*SummaryDTO`；或 BFF `*VO` |
| 域 Service（简单） | `app/service/*QueryService`、`*CommandService` — 直接编排 Mapper |
| 域 Service（复杂编排） | `app/facade/` 或 `*CommandService` + `@Transactional` |
| 对外契约 | `*-api/.../dto/`、`XxxApi` |
| 枚举 | `*-api/.../enums/` 或 `domain` 包 |
| 持久化 | `infrastructure/dataobject/*DO` + `*Mapper` + **XML**（写操作用条件 UPDATE） |
| 转换 | BFF：`bff.app|admin/converter/*Converter`（DTO↔VO，MapStruct）；impl：`infrastructure/converter/*Converter`（DO↔DTO，MapStruct） |

## §4.3 状态文档（结构 + 可读性）

### 结构（必填）

| 规则 | 说明 |
|------|------|
| **状态归属聚合/实体** | 状态机只挂在有生命周期的聚合根或实体；词表见 [domain-glossary.md](../../../glossary/domain-glossary.md) §三 |
| **查询视图分节** | §4.1 若同时有聚合根与查询视图（如「预约单」+「进行中预约」），全量状态 **§4.3.1**，子集筛选 **§4.3.2** |
| **只读 Story** | 标题注明「本 Story 只读」；不写迁移，只列状态全集 + 本 Story 用到的子集 |
| **与 BR 对齐** | 筛选表与 Story BR 可追溯；BR 编号写在 §4.3.2 引导句或表列，**不写进 §4.3.2 主标题** |

### 可读性（必填）

| 规则 | 说明 |
|------|------|
| **主标题白话** | 用「{对象}有哪些状态」「哪些{对象}算{业务说法}」；英文类名放括号 |
| **技术下沉** | 聚合根、枚举、表字段、查询视图/DTO 类名 → 标题下 `> **技术**：…` |
| **避免术语标题** | 主标题不用「查询视图」「查询过滤」「筛选规则」「生命周期（聚合根）」 |
| **§4.1 先定义查询视图** | 用一句话说明「从谁按什么规则筛出的读模型」，避免读者在 §4.3 才第一次见概念 |

### 标题正反例

| 场景 | 推荐 | 不推荐 |
|------|------|--------|
| §4.3 总节 | `预约单有哪些状态（BookingOrder）（本 Story 只读）` | `预约单（BookingOrder）状态与生命周期` |
| §4.3.1 | `预约单全量状态` | `预约单生命周期（聚合根）` |
| §4.3.2 | `哪些预约单算「进行中」` | `进行中预约查询过滤（查询视图 · Story BR-01）` |
| 车位 Story | `哪些车位算「可售/可推荐」` | `可售车位筛选规则` |

### 引导句范例

```markdown
### 4.3 预约单有哪些状态（BookingOrder）（本 Story 只读）

> **技术**：聚合根 `BookingOrder`；枚举 `BookingOrderStatus`；字段 `booking_order.status`。

#### 4.3.2 哪些预约单算「进行中」

> **技术**：读模型 `ActiveReservationQueryResult`；对齐 Story **BR-01**。本接口只返回下表为「是」的状态。
```

## 与持久化

- §4 定义语义与不变量  
- §6 schema 定义表字段，引用 §4 概念名  
- `docs/schema/{服务}/schema.md`：**字段说明表 + `CREATE TABLE`/`ALTER TABLE` DDL**（见 [schema-conventions.md](./schema-conventions.md) §1.2 标准列）  
- §6.2 定义 Mapper 方法 + XML `id`；主键查询可用 MyBatis Plus，其余 SQL 仅 XML  
- **写操作主键**：`SnowflakeIdGenerator.nextId()` 在 Service 编排层生成，再 `INSERT`（禁止库端自增）  
- **软删除**：业务删用条件 `UPDATE deleted=1`；条件查询默认 `deleted=0`；条件状态 `UPDATE` 亦须带 `deleted=0`（若适用）  
- 状态枚举（如 `BookingOrderStatus`）须在 §4.3.1 与 schema §2、BR 对齐  

## 词表

术语以 [domain-glossary.md](../../../glossary/domain-glossary.md) 为准（预约单、订金、入位、分账等）。
