# MyBatis 数据访问约定（条件规则）

> **生效条件**：本规则仅当项目画像 [system-landscape.md](../architecture/system-landscape.md) §5.4 **P-3（数据库访问框架）** 选定 **MyBatis / MyBatis-Plus** 时生效。
> - 若画像 P-3 仍为 `[TBD]`：详设与编码前须阻断请用户拍板 ORM 选型。
> - 若画像 P-3 选定 JPA / jOOQ 等其他 ORM：接入时按 [MIGRATION.md](../MIGRATION.md) §一.3 删除并替换为目标 ORM 规范，同时遵守下方「微服务通用数据红线」。

读代码或改数据访问层前，先扫 [AGENTS.md](../../AGENTS.md)、画像 §5.4 P-3，以及下文「项目实现」。

## 项目实现（接入时按画像 §5.4 P-3 填写）

> 本节是本项目主键与删除方式的执行口径。`detail-design` 与 `feature-coding` 先读本节，只执行已填写的那一支。主键或删除任一格仍为 `[TBD]` 时阻断，不得自行选择分支，也不得把下文未选中的示例当成必守。

| 项 | 本项目结论 |
|----|------------|
| 主键 | `[TBD]`（应用侧分布式 ID / UUID / 数据库自增） |
| 删除 | `[TBD]`（软删 / 状态作废） |

接入时把两格写成画像 P-3 的结论。下文未选中的分支不执行。

## 微服务通用数据红线（无论选用何种 ORM 均必守）

1. **每服务独立数据库**：每个领域微服务只访问自身独占的表（见画像 §二 数据归属列）；**严禁跨服务 SQL JOIN**、**严禁跨服务建数据库外键**。
2. **禁止跨服务直连他库**：需要其他微服务数据时，一律通过服务间远程接口（画像 §5.4 P-2）或本服务异步冗余副本获取。
3. **BFF 无业务库**：BFF 服务不直接访问领域数据库或依赖持久化 Mapper/Repository。

## MyBatis ORM 基线（当画像 P-3 选定 MyBatis 时）

- **ORM**：MyBatis 3.x；**主键 CRUD** 允许 MyBatis Plus `BaseMapper`
- **落点**：各领域服务 `*-impl/.../infrastructure/dataobject/`、`mapper/` 接口、`resources/mapper/**/*.xml`

## 必守（与主键、删除分支无关）

1. **主键查询**：Mapper 可继承 `BaseMapper<DO>`，仅用内置方法（`selectById`、`selectBatchIds` 等）。是否排除已删除行，按下方删除分支。
2. **其余 SQL**：**仅** 写在 XML；Mapper 接口只声明方法签名，与 XML `id` 一一对应。
3. **禁止**：`@Select` / `@Update` / `@Insert` / `@Delete` 写 SQL。
4. **禁止**：`QueryWrapper` / `LambdaQueryWrapper` 等业务条件查询。
5. **禁止**：BFF 或 `*-api` 依赖 Mapper；BFF 不生成业务主键。
6. **新建写入与业务删除**只执行「项目实现」选定的分支，两套主键或两套删除不得混用。

## 主键分支（按「项目实现」择一）

### 应用侧分布式 ID 或 UUID

| 项 | 约定 |
|----|------|
| DDL | `id BIGINT NOT NULL`，**无** `AUTO_INCREMENT` |
| 写入 | `*-impl` 写路径在 `INSERT` 前赋值。分布式 ID 示例：注入 `{IdGenerator}`，`do.setId(idGenerator.nextId())` |
| 生成器 | `{basePackage}.common.core.util.{IdGenerator}`（`{company-common}` → `common-core`）；版本与 `{company-common}` 根 POM 对齐 |
| 落点 | `{Entity}CommandService` / `{Entity}Facade`（编排层） |
| 多实例 | 雪花一类生成器默认 `workerId=1` 仅适合单机；多实例须在详设 §1.3 说明 `workerId` |
| 测试种子 | 验收 `INSERT` 可用固定小 ID（如 `1`、`101`）；单测可 mock `{IdGenerator}` |

### 数据库自增

| 项 | 约定 |
|----|------|
| DDL | `id BIGINT NOT NULL AUTO_INCREMENT` |
| 写入 | 应用不调用 `setId`，不引入 `{IdGenerator}` 填主键 |
| 禁止 | 与应用侧生成器混用；BFF 仍不生成业务主键 |

## 删除分支（按「项目实现」择一）

### 软删

| 项 | 约定 |
|----|------|
| 列 | 业务表含 `deleted TINYINT(1) NOT NULL DEFAULT 0`、`deleted_at DATETIME NULL` |
| 业务删除 | Mapper XML：`UPDATE {table_name} SET deleted=1, deleted_at=NOW() WHERE id=? AND deleted=0`；**禁止**对业务表用 `deleteById` 物理删 |
| 业务查询 | 条件/列表 XML 默认加 `AND deleted = 0` |
| 主键查询 | `selectById` 若需排除已删行，详设 §6.2 写明（XML 封装或 Service 校验 `deleted`） |
| 状态迁移 | 条件 `UPDATE` 带 `AND deleted = 0` |
| 唯一索引 | 业务键需唯一时，详设写清 `uk_(biz_key, deleted)` 或仅应用层保证未删唯一 |
| 技术表 | 日志、幂等记录等可省略软删列，详设 §6.1 注明 |

### 状态作废

| 项 | 约定 |
|----|------|
| 列 | 业务表不建 `deleted`、`deleted_at`。作废语义用画像规定的状态列（如 `CANCELLED`） |
| 业务删除 | 按该状态列做条件 `UPDATE`；**禁止**把 `deleteById` 当作业务删除 |
| 业务查询 | 按有效状态过滤，**不**追加 `deleted = 0` |
| 状态迁移 | `WHERE id=? AND status=?`，不带 `deleted` 条件；`affected_rows=0` 抛业务异常 |
| DO | 不生成 `deleted` / `deletedAt` 字段 |

## 抽象示意

软删支：

```java
// 应用侧主键分支才在 INSERT 前赋值；自增分支不调用 setId
entity.setId(idGenerator.nextId());
{entity}Mapper.insert(entity);

// 条件查询 → XML（软删支：XML 内 AND deleted = 0）
List<{Entity}DO> list = {entity}Mapper.selectByOwnerAndStatus(ownerId, status);

// 软删 → XML
{entity}Mapper.softDeleteById(id);
```

```xml
<select id="selectByOwnerAndStatus" resultType="{basePackage}.infrastructure.dataobject.{Entity}DO">
  SELECT id, owner_id, status FROM {table_name}
  WHERE owner_id = #{ownerId} AND status = #{status} AND deleted = 0
</select>

<update id="softDeleteById">
  UPDATE {table_name}
  SET deleted = 1, deleted_at = NOW()
  WHERE id = #{id} AND deleted = 0
</update>
```

状态作废支：

```xml
<select id="selectByOwnerAndStatus" resultType="{basePackage}.infrastructure.dataobject.{Entity}DO">
  SELECT id, owner_id, status FROM {table_name}
  WHERE owner_id = #{ownerId} AND status = #{status}
</select>

<update id="markCancelled">
  UPDATE {table_name}
  SET status = 'CANCELLED', updated_at = NOW()
  WHERE id = #{id} AND status = #{expectedStatus}
</update>
```

```java
// 禁止：未选中的分支、Wrapper 条件查询、业务路径物理删、跨服务表 JOIN
```

## 详设追溯

DD §6 写表/索引 + **可执行 DDL**（见 `skills/detail-design/references/schema-conventions.md` §1.2；列集合与本节「项目实现」同一分支）；§8 写持久化方法与写路径主键策略；`feature-coding` 按此实现。
