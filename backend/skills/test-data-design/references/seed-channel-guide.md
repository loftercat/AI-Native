# 造数通道指引

> 配套 `test-data-design` Skill。明确造数通道分层、首版 SQL 通道规范、Admin API 后续演进。

## 1. 通道分层

| 通道 | 状态 | 适用场景 | 执行方 |
|------|------|----------|--------|
| **SQL/文档**（首版） | ✅ 本卡落地 | 所有黑盒前置数据 | 运维/CI 执行 SQL |
| Admin API | 🔜 后续 Story | 需经业务校验的写路径（如创建订单） | CI deploy stage 调 HTTP |
| 进程内 `@Sql` | ❌ 不归本 Skill | MR 进程内 IT | `integration-test-design` |

## 2. 首版 SQL 通道规范

### 2.1 生成与执行分离

- `seed_*.py` **仅生成 SQL 文本**（`print(sql)`），**不嵌入 DB 驱动**
- 执行由运维或 CI deploy stage 完成：
  ```bash
  python -m tests.data.seed_s02_007_space_query --profile smoke-main > seed.sql
  mysql -h $SEED_DB_HOST ... < seed.sql
  ```

### 2.2 幂等（BR-3）

每个画像的 SQL 必须可重跑：

```sql
-- 先 DELETE 再 INSERT（按 seed_key）
DELETE FROM parking_space WHERE seed_key = 's02-007-smoke-main';
DELETE FROM parking_lot  WHERE seed_key = 's02-007-smoke-main';
DELETE FROM project       WHERE seed_key = 's02-007-smoke-main';

INSERT INTO project (id, name, ..., seed_key) VALUES (...);
-- ...
```

### 2.3 `seed_key` 列

业务表（V1 DDL 确认）**无 `remark` 字段**，首版策略：

1. **运维 `ALTER TABLE ADD COLUMN seed_key VARCHAR(64) NULL`**（推荐，幂等）
2. 或手动标记（文档化，不推荐）

正式加列另 Story；首版 seed 脚本生成的 SQL 含 `seed_key` 列，运维执行前需先 `ALTER`。

### 2.4 `seed_key` 命名约定（BR-04）

`seed_key` 是 **清理与幂等 DELETE 的标签**，不是业务主键，也不自动生成。**真源以 DP（`docs/qa/data-profiles/.../DP-*.yaml`）里 `entities[].seed_key` 显式写出的字符串为准**；seed 脚本生成的 SQL 必须与 DP 完全一致。

**格式**：

```text
{迭代缩写}-{Story序号}-{profile_id}
```

| 片段 | 含义 | 例子 |
|------|------|------|
| `{迭代缩写}` | 迭代号小写简写，`S02` → `s02` | `s02` |
| `{Story序号}` | Story 卡末三段数字，去前导 `STORY-` | `007` |
| `{profile_id}` | DP 内画像 ID（见 `data-profile-template.md`） | `smoke-main` |

合起来：`s02-007-smoke-main`、`s02-007-regression-charger`。

**粒度规则**：

1. **一 profile 一 key**：同一 profile 下多张表、多行 **共用同一个 `seed_key`**，便于一次 `DELETE WHERE seed_key = ?` 清整画像。
2. **`extends` 追加画像用独立 key**：如 `regression-charger` 只在多出来的 `parking_space` 行上打 `s02-007-regression-charger`，父画像行保持 `s02-007-smoke-main`；清理时各删各的，互不误删。
3. **不写 AC 编号**：AC → profile 的追溯走 DP `profiles[].ac_ids`（一条 profile 常对应多条 AC，如 `smoke-main` → `[AC-1, AC-6]`）；把 `AC-x` 嵌进 `seed_key` 会与「一 profile 一 key」冲突。
4. **Story 内唯一**：同一 DP 内 `seed_key` 不重复；跨 Story 靠前缀 `{迭代}-{序号}` 区分，避免同测试库语义撞车。
5. **长度 ≤ 64**：受 `VARCHAR(64)` 列约束；profile_id 起名用短 slug（`smoke-main` 而非 `smoke-main-with-charger`）。

**与 `profile_id` 的关系**：

| 字段 | 层级 | 作用 |
|------|------|------|
| `profile_id` | DP / CI / 环境变量 | 选哪套画像跑 seed：`--profile smoke-main` |
| `seed_key` | 数据库行 | 清理与幂等 DELETE；通常 = `{迭代}-{序号}-{profile_id}` |

`profile_id` 改名时，DP 里 `seed_key` 与 seed 脚本必须同步改，避免清理对不上。

### 2.5 不直连生产

- seed 脚本入口校验 `SEED_DB_URL`：缺失 → `sys.exit(0)` + 提示（AC-05 skip 非 fail）
- **禁止**默认连本地 dev DB

## 3. Admin API 后续演进（规划）

- 依赖 S02-004 等接口在测试环境稳定开放
- 优势：经业务校验（如唯一约束、状态机），避免脏数据
- 落地后：`seed_*.py` 可选 `--channel=sql|admin-api`；优先 Admin API

## 4. 与进程内 `@Sql` 边界

| 维度 | 进程内 `@Sql`（IT） | 部署环境 seed（本 Skill） |
|------|---------------------|--------------------------|
| 环境 | H2/测试库（MR 进程内） | 已部署测试环境 DB |
| 时机 | MR 每次 PR | 发版前/提测前 |
| 维护 | `booking-*-impl/src/test/resources/` | `tests/data/` + `docs/qa/data-profiles/` |
| 边界 | 不归本 Skill | 本 Skill |

**禁止**把进程内 `@Sql` 搬到 `tests/data/`；**禁止**把部署环境 seed 嵌入 Java `*IT`。

## 5. 身份列值对齐（功能/数据权限）

当 AC 涉及数据权限时，seed SQL 里的**身份列**（`partner_id`/`project_id`/`lot_id`/`created_by`/`owner_id` 等）必须与测试 Token 解出的身份信息对齐。**具体 id 从 [system-landscape §4.3.4 测试账号约定表](../../../architecture/system-landscape.md#434-测试账号约定供-test-data-design-skill-消费) 取**，不在 DP/seed 里自己编。

| 数据权限类型 | seed 写什么列 | 对齐谁 |
|--------------|---------------|--------|
| 层级 scope | `partner_id`/`project_id`/`lot_id`（归属键） | Token 的 `scopeIds` 含此值 |
| 行级创建人 | `created_by` | Token 解出的 `userId` |
| C 端车主本人 | `owner_id` | App Token 的 `ownerId` |

**功能权限不靠造数**：403 / 权限码类 AC 不改 seed；黑盒挑对应 Token（如 `ADMIN_TOKEN_DENIED`）。

**seed 脚本只写列值，不验证账号是否存在**；账号/Token 由 iam/App 侧按 §4.3.4 约定准备。

**禁止**：
- seed 脚本连 iam 库插账号
- seed 脚本调 App 登录接口造车主
- seed 脚本签发 Token
- seed 脚本调 `/user/me` 校验 Token
