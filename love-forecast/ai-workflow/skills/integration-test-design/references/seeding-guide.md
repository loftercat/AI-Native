# 种子数据与单一 schema 事实源

> 决策记录：`docs/methodology/integration-test-design.md` §2.1（决策 A）  
> 权威 Rule：[`rules/integration-test-conventions.md`](../../../rules/integration-test-conventions.md) 必守 1  
> 配套：[integration-test-guide.md](./integration-test-guide.md) §5（数据准备与隔离）

本指南管集成测试的**数据层**：单一 schema 事实源、种子数据从哪来、跨 Story 共享数据归谁管、怎么做到每用例隔离。

---

## 1. 单一 schema 事实源（决策 A 配套）

### 1.1 唯一权威 DDL

| 项 | 值 |
|----|-----|
| 唯一权威 DDL | `love-app/src/main/resources/db/migration/V{n}__*.sql`（Flyway 版本化建表/改表，**只建表/改表，不含建库**） |
| 建库 | `{启动模块}/application.yml` `datasource.url` 参数 `createDatabaseIfNotExist=true` 自动创建（`booking` 库，utf8mb4）；无需手动建库 |
| 方言 | **MySQL 可执行 DDL**（生产保真；运行时 MySQL 与 Testcontainers MySQL 容器共享同一份） |
| 初始化 | 运行时由 Flyway（`spring.flyway.locations=classpath:db/migration`，`baseline-on-migrate=true`）自动迁移；**集成测试**继承 `AbstractMySqlContainerTest` / `AbstractIntegrationTest` 时随 `@SpringBootTest` 上下文启动同样走 Flyway，种子数据由各 `*IT` 的 `@Sql` 引用 `db/test-data/*.sql` |
| 部署顺序 | 启动应用 → 自动建库 → Flyway 自动建表 → （可选）手动执行 `{项目}/db/seed-data-dev.sql` 灌联调种子 |

### 1.2 收敛散落 schema

现状有 2 份 `{模块}/src/test/resources/schema.sql`（`advice-impl` / `profile-impl` 测试资源；`love-app` 已由 Flyway `db/migration/` 接管）。**禁止各自分叉**：

| 动作 | 说明 |
|------|------|
| 权威源 | 所有表 DDL **只写在** `love-app/src/main/resources/db/migration/`（Flyway 版本脚本；**禁止修改已发布脚本**） |
| 各模块测试资源 | `advice-impl` / `profile-impl` 的 `{模块}/src/test/resources/schema.sql` 只保留 `@MybatisTest` 需要的**本模块表**，并与 Flyway 迁移结果**逐表同构**；不得出现权威源没有的表、或同表不同字段 |
| 主键 | 域规范为**雪花 `BIGINT`**（写前 `SnowflakeIdGenerator.nextId()`），非 `AUTO_INCREMENT`；权威源按此落 DDL |
| 变化 | 表结构变更先新增 Flyway 增量脚本，再同步各模块测试资源；`docs/schema/{服务}/schema.md` + `ddl/` 为设计权威（见 [schema-conventions.md](../../detail-design/references/schema-conventions.md) §1.4） |

> 已全局落地 Testcontainers MySQL（取消 H2），无需再判断切换触发器；新增表/字段时**新增 Flyway 增量脚本 `V{n}__desc.sql`（禁止修改已发布脚本）**，并同步各模块测试资源。

---

## 2. 种子数据分层

| 层 | 内容 | 位置 | 使用方式 |
|----|------|------|---------|
| **共享种子** | 跨 Story 复用的**主数据**：车场、区域、车位、厂商配置（MOCK）、计费规则等 | `love-app/src/test/resources/db/test-data/*.sql` | 集成测试类级 `@Sql(BEFORE_TEST_METHOD)` 或 `TestDataFactory` 引用 |
| **用例数据** | 单用例的业务行：预约单、支付单、占用记录、特定状态组合 | 用例内 `@Sql` 脚本或 `TestDataFactory` 构造 | 每用例独立、唯一标识（integration-test-guide §5.2） |

**分工原则**：共享种子放**静态 SQL**（确定性、可审计）；用例数据优先 **`TestDataFactory` 代码构造**（灵活、可带唯一标识）。

### 2.1 TestDataFactory 职责

- 只放**跨用例复用**的构造方法（如 `factory.newBookingOrder(userId, status)`）
- 返回 DO/DTO/请求体，内部用雪花 ID 或唯一序列，**禁止硬编码同一条主键被多用例复用**
- 不进共享 SQL 的数据（用例私有）由它管

---

## 3. 跨 Story 共享数据归属

| 数据 | 归属 | 原因 |
|------|------|------|
| 车场 / 区域 / 车位 / 厂商配置（MOCK）等主数据 | `db/test-data/` 共享种子（本指南管） | 多 Story（订单、库存、适配器）都要引用，重复建会互相踩 |
| 预约单 / 支付单 / 占用行 | **用例私有**，不混入共享种子 | 状态机用例之间天然冲突 |
| 时间敏感数据（`pay_deadline`、`start_time`） | 用例内生成（相对 `LocalDateTime.now()` 偏移） | 避免固定时间过期导致用例变红 |

**规则**：
1. 新 Story 需要主数据 → 先查 `db/test-data/` 是否已有；没有才新增，并登记用途
2. 共享种子文件名表意（如 `{场景种子}.sql`），内容注释标注「供哪些 Story/用例」及来源 Story
3. 用例私有数据**不得**写进共享种子文件；共享种子**不得**被单个用例随意改删

---

## 4. 隔离与清理（与 integration-test-guide §5 一致）

- 共享种子幂等：脚本内 `DELETE`/`INSERT` 或 `INSERT ... ON DUPLICATE KEY UPDATE`（MySQL 方言，命中触发器判定时使用），可重复执行
- 用例数据唯一标识隔离；`AFTER_TEST_METHOD` 清理（`@Sql` 后置或 `@AfterEach` + `jdbcTemplate`）
- **禁止**依赖 `@Transactional` 回滚（RANDOM_PORT 下失效）
- 切 Testcontainers 后：共享容器 + Flyway 迁移 schema + 统一种子脚本（Rule 必守 1）

---

## 5. 反模式

```sql
-- ❌ 各模块 schema 与权威源分叉（同表字段不一致，一边绿一边红）
-- ❌ 用例私有数据写进共享种子（跨用例污染）
-- ❌ 共享种子非幂等（第二次执行报重复主键）
-- ❌ 固定写死时间戳（用例在过期后变红）
-- ❌ AUTO_INCREMENT 主键 + 手写固定 id 混用（与雪花规范冲突）
```

---

## 6. 一句话记忆

> **DDL 只信 `love-app/.../db/migration/`（Flyway 版本化）；Mapper 测试 `{模块}/src/test/resources/schema.sql` 须与 Flyway 结果逐表同构；主数据归共享种子，用例数据归用例自己；每用例独立、可重跑、不靠事务回滚。**
