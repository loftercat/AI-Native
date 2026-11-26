# 领域模型指引（Java · api/impl 分层）

## 务实领域模型（本仓库默认）

> **分层架构不变**；领域「厚度」按 Story 复杂度渐进。**非**经典 DDD「查整聚合 → 内存改 → save 整包」。

### 一句话

- **简单业务**：`Service` + `{Entity}DO` + `{Entity}DTO`，业务逻辑可直接写在 Service；**不必**建 `domain.model` 类。  
- **复杂业务**：可选 **贫血** `domain/model/{Entity}` 做校验/状态机判断；**持久化仍以 Mapper XML 条件 `UPDATE`/`INSERT` 为主**。  
- **§4 概念名**（主实体、聚合根）是统一语言；**§8 必须写真实 Java 落点**（常为 `{Entity}DO` + `{Entity}DTO`，而非 `{Entity}` 实体类）。

### 简单 vs 复杂（详设 §1.3 或 §4.4 须标明 `领域厚度`）

| 倾向 | 场景示例 |
|------|----------|
| **薄（无 domain 类）** | 只读查询；规则主要在 SQL；单表 CRUD；无状态迁移 |
| **中（Service 闭环）** | 少量 `if` + 枚举；`{Entity}QueryService` 组装 DTO |
| **厚（可选贫血 domain）** | 状态机迁移；多不变量；外部回调/取消/超时编排；规则多入口复用 |

### 持久化（写操作默认）

| 推荐 | 避免（V1 默认不做） |
|------|---------------------|
| `UPDATE {table_name} ... WHERE id=? AND {status}=?` 条件更新 | 查整行 DO → 改字段 → `updateById` 全量覆盖 |
| `affected_rows=0` → 并发/状态非法 → `{BizException}` | 无旧状态条件的盲 `UPDATE` |
| 批量超时：`UPDATE {table_name} ... WHERE {status}=? AND deadline<?` | 定时任务逐条 load 聚合再 save |
| 本服务跨表：`@Transactional` + 多个 Mapper 方法 | 单一「聚合仓储 save」包全部副作用 |

条件更新 SQL 须在详设 **§6.2** 列出 `{Entity}Mapper` 方法名与 XML `id`。

### 贫血 domain 用法（复杂 Story 可选）

```text
{domain-a}-impl/
  domain/model/{Entity}.java                # 贫血：字段 + canTransitToConfirmed()/validateCancel() 等
  app/service/{Entity}CommandService.java   # 编排：校验 → mapper.updateStatusIfMatch(...)
  infrastructure/mapper/{Entity}Mapper.java # 实际落库
```

- Domain 类 **可不** 负责持久化；校验后可调 `mapper.updateStatusIfMatch(id, fromStatus, toStatus)`。  
- 读路径可继续 **Mapper → `{Entity}DO` → `{Entity}DTO`**，不必经过 domain 类。

---

## 完整范例（抽象 Story 示意）

### 范例 A：薄 — 查询当前有效主实体（STORY-{YYYY-Snn}-002）

**场景**：只读；规则在 SQL（哪些状态算「进行中/有效」、BR-02 排序优先级）；无状态迁移。

**详设 §4.4（摘录）**

| AC | 领域概念 | 代码落点（§8） | 领域厚度 | 说明 |
|----|----------|----------------|----------|------|
| AC-01～06 | {主实体}（文档） | `{Entity}DO`、`{Entity}Status` | **薄** | 无 `domain.model.{Entity}` |
| AC-01～06 | 当前有效{主实体} | `Active{Entity}QueryResultDTO` | **薄** | 读模型 DTO |
| BR-02 | — | `{Entity}Mapper.selectTopActiveByUserId` | **薄** | XML 内 `ORDER BY` + `LIMIT 1` |

**代码路径**

```text
{Entity}Mapper.selectTopActiveByUserId(userId)
  → {Entity}DO
  → {Entity}QueryService.toSummary()
  → Active{Entity}SummaryDTO
  → Active{Entity}QueryResultDTO
  → {DomainA}Api → App{Entity}Controller → {Result<T>}<{Entity}VO>
```

**Service 核心逻辑（示意）**

```java
{Entity}DO row = entityMapper.selectTopActiveByUserId(userId);
if (row == null) {
    return Active{Entity}QueryResultDTO.empty();
}
return Active{Entity}QueryResultDTO.of(toSummary(row));
```

**不做什么**：不建 `{Entity}` 领域类；不把 DO 查出来再 `updateById`（本 Story 无写操作）。

---

### 范例 B：厚 — 外部回调成功驱动状态迁移（复杂写 Story 示意）

**场景**：状态迁移；需校验「当前必须是待确认状态且未超时」；可能需联动下游领域服务（按画像 §5.4 E-3 一致性方案）；规则会在回调、重试中复用。

**领域厚度**：**厚** — 可选贫血 `{Entity}` 做 `canTransitToConfirmed()`；**落库仍用条件 UPDATE**。

**详设 §6.2（写操作须写清）**

| Mapper 方法 | XML `id` | SQL 要点 |
|-------------|----------|----------|
| `updateStatusIfMatch` | `updateStatusIfMatch` | `UPDATE {table_name} SET {status}='CONFIRMED' WHERE id=? AND {status}='PENDING'` |
| （`{domain-b}`）`updateResourceStatusIfMatch` | 同上模式 | 子资源 `LOCKED` → `OCCUPIED`（各自独立库） |

**编排（示意）**

```java
@Transactional // 仅包裹本服务本地写；跨服务下游调用须隔离在本地事务外或按画像 §5.4 E-3（Outbox/Saga）编排
public void onCallbackConfirmed(Long entityId, String externalBizNo) {
    {Entity}DO row = entityMapper.selectById(entityId);
    {Entity} entity = {Entity}.from(row); // 贫血：仅承载校验

    if (!entity.canTransitToConfirmed(externalBizNo)) {
        throw new {BizException}({Domain}ErrorCode.INVALID_STATE);
    }

    int n = entityMapper.updateStatusIfMatch(
            entityId, {Entity}Status.PENDING, {Entity}Status.CONFIRMED);
    if (n == 0) {
        throw new {BizException}({Domain}ErrorCode.CONCURRENT_UPDATE); // 并发或已处理
    }
    // 联动下游领域服务状态流转（按画像 §5.4 E-3 保证跨服务一致性，严禁本地事务跨服务）
}
```

**贫血 domain（示意）**

```java
public boolean canTransitToConfirmed(String externalBizNo) {
    return status == PENDING && deadline != null && !deadline.isBefore(now());
}
```

**对比经典 DDD（本仓库默认不做）**

```text
❌ selectById → 改 DO 字段 → updateById(整行)
✅ updateStatusIfMatch(id, from, to) + affected_rows 判断
```

---

## 六步推导

1. **识概念**：AC 名词 → 实体 / 值对象 / 聚合根（**文档概念**，不一定 1:1 Java 类）  
2. **定边界**：聚合内外；`*-api` DTO 与 `*-impl` 分离；**§4.4 写概念 → §8 代码落点**  
3. **定不变量**：BR → 唯一性、状态迁移、金额/时段等核心业务规则（见 domain-glossary）  
4. **建映射表**：§4.4（含代码落点列）与 §8 类名可追溯  
5. **写 §4.3**：主标题白话 + `> 技术：` 引导句；查询子集单独 **§4.3.2**（见下方）  
6. **标领域厚度**：§4.4 或 §8.2 注明 **薄 / 中 / 厚** 及是否建 `domain/model`

## 落点（本仓库）

### 域 Service 命名（与 code-skeleton-guide §3.1 一致）

- **`{Entity}QueryService`**：只读（SELECT、统计、**只读推荐**如 `findBestCandidate`）
- **`{Entity}CommandService`**：写库（INSERT、条件 UPDATE，以及「项目实现」删除分支规定的删除）；动作在**方法名**（`lockResource`、`createPending{Entity}`）
- **禁止** `{动作}Service`（如 `ResourceLockService`、`CandidateAllocateService`）— 易与 `{Entity}Facade` 职责混淆

| 概念（§4） | 常见代码落点（§8） |
|------------|-------------------|
| 聚合根 / 实体（文档） | 薄：`{Entity}DO` + `{Entity}Status` 枚举；厚：可选 `domain/model/{Entity}`（贫血） |
| 查询视图 / 读模型 | `{Entity}QueryResultDTO`、`{Entity}SummaryDTO`；或 BFF `{Entity}VO` |
| 域 Service（简单） | `app/service/{Entity}QueryService`、`{Entity}CommandService` — 直接编排 Mapper |
| 域 Service（复杂编排） | `app/facade/{Entity}Facade` 或 `{Entity}CommandService` + `@Transactional` |
| 对外契约 | `*-api/.../dto/`、`{Domain}Api` |
| 枚举 | `*-api/.../enums/` 或 `domain` 包 |
| 持久化 | `infrastructure/dataobject/{Entity}DO` + `{Entity}Mapper` + **XML**（写操作用条件 UPDATE） |
| 转换 | BFF：`bff.{end}/converter/*Converter`（DTO↔VO，MapStruct）；impl：`infrastructure/converter/*Converter`（DO↔DTO，MapStruct） |

## §4.3 状态文档（结构 + 可读性）

### 结构（必填）

| 规则 | 说明 |
|------|------|
| **状态归属聚合/实体** | 状态机只挂在有生命周期的聚合根或实体；词表见 [domain-glossary.md](../../../glossary/domain-glossary.md) §三 |
| **查询视图分节** | §4.1 若同时有聚合根与查询视图（如「{主实体}」+「当前有效{主实体}」），全量状态 **§4.3.1**，子集筛选 **§4.3.2** |
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
| §4.3 总节 | `{主实体}有哪些状态（{Entity}）（本 Story 只读）` | `{主实体}（{Entity}）状态与生命周期` |
| §4.3.1 | `{主实体}全量状态` | `{主实体}生命周期（聚合根）` |
| §4.3.2 | `哪些{主实体}算「{业务子集A}」` | `{业务子集A}查询过滤（查询视图 · Story BR-01）` |
| 子资源 Story | `哪些{子资源}算「{业务子集B}」` | `{业务子集B}筛选规则` |

### 引导句范例

```markdown
### 4.3 {主实体}有哪些状态（{Entity}）（本 Story 只读）

> **技术**：聚合根 `{Entity}`；枚举 `{Entity}Status`；字段 `{table_name}.{status}`。

#### 4.3.2 哪些{主实体}算「{业务子集A}」

> **技术**：读模型 `Active{Entity}QueryResult`；对齐 Story **BR-01**。本接口只返回下表为「是」的状态。
```

## 与持久化

- §4 定义语义与不变量  
- §6 schema 定义表字段，引用 §4 概念名  
- `docs/schema/{服务标识}/schema.md`：**字段说明表 + `CREATE TABLE`/`ALTER TABLE` DDL**（见 [schema-conventions.md](./schema-conventions.md) §1.2 标准列）  
- §6.2 定义 `{Entity}Mapper` 方法 + XML `id`；主键查询可用 MyBatis Plus，其余 SQL 仅 XML  
- **写操作主键**：按 [schema-conventions.md](./schema-conventions.md) §1.2 的执行口径。应用侧分支在 Service 编排层 `{IdGenerator}.nextId()` 后 `INSERT`，DDL 无自增；自增分支由数据库生成 id，应用不 `setId`
- **删除**：只执行 §1.2 选定的一支。软删支用条件 `UPDATE deleted=1`，条件查询与状态 `UPDATE` 默认 `deleted=0`；状态作废支不建 `deleted` 列，删除改为状态更新，查询与状态 `UPDATE` 不带 `deleted=0`  
- 状态枚举（如 `{Entity}Status`）须在 §4.3.1 与 schema §2、BR 对齐  

## 词表

术语以 [domain-glossary.md](../../../glossary/domain-glossary.md) 为准（如主实体、业务状态、核心动作与边界规则等）。
