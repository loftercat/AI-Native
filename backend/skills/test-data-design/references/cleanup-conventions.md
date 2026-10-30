# 清理约定

> 配套 `test-data-design` Skill。明确造数清理的幂等、可追溯、不误删规则。

## 1. 清理原则

| 原则 | 说明 |
|------|------|
| **按 `seed_key` 反序删除** | 每条数据带 `seed_key`；清理按 `cleanup_order` 反序 `DELETE WHERE seed_key=?` |
| **不误删** | **禁止**无 `WHERE` 的 DELETE/UPDATE；**禁止**按业务字段（如 `name LIKE '%万象城%'`）删，可能误伤生产数据 |
| **幂等** | 清理脚本可重跑；无 `seed_key` 数据时 `DELETE` 影响 0 行，不报错 |
| **可追溯** | 每条清理 SQL 注释含 `-- cleanup profile={profile_id} table={table}` |
| **粒度 = profile** | `seed_key` 按 **画像** 标记（一 profile 一 key），**不**按单条 AC；AC 追溯走 DP `ac_ids`。命名见 [seed-channel-guide §2.4](seed-channel-guide.md#24-seed_key-命名约定br-04)。**注意**：`seed_key` 是清理标签，≠ 业务归属列（如 `partner_id`/`owner_id`）；业务归属列对齐见 [system-landscape §4.3.4](../../../architecture/system-landscape.md#434-测试账号约定供-test-data-design-skill-消费) |
| **`extends` 子画像独立清理** | 子画像（如 `regression-charger`）用独立 `seed_key`，只删自己追加的行；**不**连带删父画像行。多 profile 同库时按依赖反序 cleanup（先子后父） |

## 2. 清理 SQL 示例

```sql
-- cleanup profile=smoke-main
DELETE FROM parking_space WHERE seed_key = 's02-007-smoke-main';
DELETE FROM parking_lot  WHERE seed_key = 's02-007-smoke-main';
DELETE FROM project       WHERE seed_key = 's02-007-smoke-main';
```

## 3. cleanup_order 约定

- **反序**：依赖最后的表先删（如 `parking_space` → `parking_lot` → `project`）
- 与造数 `entities` 顺序**相反**
- `smoke-empty` 画像 `cleanup_order: []`

## 4. 执行

```bash
python -m tests.data.seed_s02_007_space_query --profile smoke-main --cleanup > cleanup.sql
mysql -h $SEED_DB_HOST ... < cleanup.sql
```

## 5. CI 衔接建议

- 发版后/提测后跑完 blackbox → 可选跑 cleanup
- 或保留数据供下次冒烟（幂等 seed 会先 DELETE 再 INSERT，不冲突）
