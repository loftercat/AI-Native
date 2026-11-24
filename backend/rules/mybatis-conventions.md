# MyBatis 数据访问约定（条件规则）

> **生效条件**：本规则仅当项目画像 [system-landscape.md](../architecture/system-landscape.md) §5.4 **P-3（数据库访问框架）** 选定 **MyBatis / MyBatis-Plus** 时生效。
> - 若画像 P-3 仍为 `[TBD]`：详设与编码前须阻断请用户拍板 ORM 选型。
> - 若画像 P-3 选定 JPA / jOOQ 等其他 ORM：接入时按 [MIGRATION.md](../MIGRATION.md) §一.3a 替换本规则，并遵守下方「微服务通用数据红线」。

读代码或改数据访问层前，先扫 [AGENTS.md](../../AGENTS.md) 与 [system-landscape.md](../architecture/system-landscape.md)。

## 微服务通用数据红线（无论选用何种 ORM 均必守）

1. **每服务独立数据库**：每个领域微服务只访问自身独占的表（见画像 §二 数据归属列）；**严禁跨服务 SQL JOIN**、**严禁跨服务建数据库外键**。
2. **禁止跨服务直连他库**：需要其他微服务数据时，一律通过服务间远程接口（画像 §5.4 P-2）或本服务异步冗余副本获取。
3. **BFF 无业务库**：BFF 服务不直接访问领域数据库或依赖持久化 Mapper/Repository。

## MyBatis ORM 基线（当画像 P-3 选定 MyBatis 时）

- **ORM**：MyBatis 3.x；**主键 CRUD** 允许 MyBatis Plus `BaseMapper`
- **落点**：各领域服务 `*-impl/.../infrastructure/dataobject/`、`mapper/` 接口、`resources/mapper/**/*.xml`

## 必守（MyBatis 栈）

1. **主键查询**：Mapper 可继承 `BaseMapper<DO>`，仅用内置方法（`selectById`、`selectBatchIds` 等）；排除已软删行须在 XML 或 Service 校验 `deleted`
2. **业务删除**：用 Mapper XML **软删**（`UPDATE ... SET deleted=1, deleted_at=NOW()`）；**禁止**对业务表用 `deleteById` 物理删
3. **新建写入**：主键策略按画像 §5.4 P-3 执行（示例：雪花 ID 由 `*-impl` 注入生成器在 `INSERT` 前赋值，禁止 DDL `AUTO_INCREMENT`）
4. **其余 SQL**：**仅** 写在 XML；Mapper 接口只声明方法签名，与 XML `id` 一一对应；条件查询默认 `AND deleted = 0`
5. **禁止**：`@Select` / `@Update` / `@Insert` / `@Delete` 写 SQL
6. **禁止**：`QueryWrapper` / `LambdaQueryWrapper` 等业务条件查询
7. **禁止**：BFF 或 `*-api` 依赖 Mapper；BFF 不生成业务主键

## 示例

```java
// ✅ 主键
BookingOrderDO order = bookingOrderMapper.selectById(orderId);

// ✅ 新建：雪花 ID（若画像 P-3 选用雪花 ID）
order.setId(idGenerator.nextId());
bookingOrderMapper.insert(order);

// ✅ 条件查询 → XML 方法（XML 内 AND deleted = 0）
List<BookingOrderDO> list = bookingOrderMapper.selectByUserIdAndStatus(userId, status);

// ✅ 软删 → XML
bookingOrderMapper.softDeleteById(orderId);

// ❌ Wrapper 条件查询
// bookingOrderMapper.selectList(new LambdaQueryWrapper<>()...);

// ❌ 业务路径物理删
// bookingOrderMapper.deleteById(orderId);

// ❌ 跨服务表 JOIN（例如在订单服务 XML 中直接 JOIN 库存服务的表）
```

```xml
<select id="selectByUserIdAndStatus" resultType="...BookingOrderDO">
  SELECT id, user_id, status FROM booking_order
  WHERE user_id = #{userId} AND status = #{status} AND deleted = 0
</select>

<update id="softDeleteById">
  UPDATE booking_order
  SET deleted = 1, deleted_at = NOW()
  WHERE id = #{id} AND deleted = 0
</update>
```

## 详设追溯

DD §6 写表/索引 + **可执行 DDL**（见 `skills/detail-design/references/schema-conventions.md` §1.2 标准列）；§8 写持久化方法与写路径主键策略；`feature-coding` 按此实现。
