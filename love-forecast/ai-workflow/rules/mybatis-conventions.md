# MyBatis 数据访问约定

读代码或改 Mapper 前，先扫 [AGENTS.md](../../AGENTS.md) 与 [system-landscape.md](../architecture/system-landscape.md)。

## ORM 基线

- **ORM**：MyBatis 3.x；**主键 CRUD** 允许 MyBatis Plus `BaseMapper`
- **落点**：`*-impl/.../infrastructure/dataobject/`、`mapper/` 接口、`resources/mapper/**/*.xml`

## 必守

1. **主键查询**：Mapper 可继承 `BaseMapper<DO>`，仅用内置方法（`selectById`、`selectBatchIds` 等）；排除已软删行须在 XML 或 Service 校验 `deleted`
2. **业务删除**：用 Mapper XML **软删**（`UPDATE ... SET deleted=1, deleted_at=NOW()`）；**禁止**对业务表用 `deleteById` 物理删
3. **新建写入**：`INSERT` 前由 `*-impl` 注入 `com.loveforecast.common.core.util.SnowflakeIdGenerator` 生成 `id`（`com.loveforecast:common-core`，版本 `${love-common.version}`，与 love-common 根 POM 对齐）；**禁止** DDL `AUTO_INCREMENT`
4. **其余 SQL**：**仅** 写在 XML；Mapper 接口只声明方法签名，与 XML `id` 一一对应；条件查询默认 `AND deleted = 0`
5. **禁止**：`@Select` / `@Update` / `@Insert` / `@Delete` 写 SQL
6. **禁止**：`QueryWrapper` / `LambdaQueryWrapper` 等业务条件查询
7. **禁止**：BFF 或 `*-api` 依赖 Mapper；BFF 不生成业务主键

## 示例

```java
// ✅ 主键
BookingOrderDO order = bookingOrderMapper.selectById(orderId);

// ✅ 新建：雪花 ID
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

DD §6 写表/索引 + **可执行 DDL**（见 `skills/detail-design/references/schema-conventions.md` §1.2 标准列：雪花主键、软删除）；§8 写 Mapper 方法 + **XML id** + 写路径 `SnowflakeIdGenerator`；feature-coding 按此实现。
