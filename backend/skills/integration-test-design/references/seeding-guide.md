# 种子数据与每服务独立 schema 事实源（微服务版）

> 决策记录：`docs/methodology/integration-test-design.md` §2.1（决策 A）
> 权威 Rule：[`rules/integration-test-conventions.md`](../../../rules/integration-test-conventions.md) 必守 1
> 配套：[integration-test-guide.md](./integration-test-guide.md) §5（数据准备与隔离）

本指南管微服务单服务集成测试的**数据层**：每服务独立 schema 事实源、种子数据从哪来、本服务共享数据归谁管、怎么做到每用例隔离。

---

## 1. 每服务独立 schema 事实源（决策 A 配套）

### 1.1 各服务唯一权威 DDL

每个有数据库的微服务只管理自己独占的表（见画像 §二 数据归属列），**严禁多个微服务共享同一份 Flyway 迁移目录**。

| 项 | 值 |
|----|-----|
| 本服务权威 DDL | `{service}-impl/src/main/resources/db/migration/V{n}__*.sql`（Flyway 版本化建表/改表，**只建表/改表，不含建库**） |
| 建库 | 本服务 `application.yml` `datasource.url` 参数 `createDatabaseIfNotExist=true` 自动创建本服务独立库（utf8mb4） |
| 方言 | **MySQL 可执行 DDL**（生产保真；运行时 MySQL 与 Testcontainers MySQL 容器共享同一份） |
| 初始化 | 本服务运行时与单服务集成测试（继承本服务 `AbstractIntegrationTest`）均随 `@SpringBootTest` 由 Flyway 自动迁移本服务库；种子数据由本服务 `*IT` 的 `@Sql` 引用本服务 `src/test/resources/db/test-data/*.sql` |

### 1.2 严禁 schema 分叉

| 动作 | 说明 |
|------|------|
| 权威源 | 本服务所有表 DDL **只写在** `{service}-impl/src/main/resources/db/migration/`（**禁止修改已发布脚本**） |
| 持久化单测资源 | 若本服务持久化单测（按画像 §5.4 P-3 ORM 选型）另维护 `{service}-impl/src/test/resources/schema.sql`，必须与本服务 Flyway 迁移结果**逐表同构**（或直接由 Flyway 初始化容器库） |
| 主键与删除 | 遵循画像 §5.4 P-3 与 schema-conventions §1.2（应用侧 ID 则 DDL 无 `AUTO_INCREMENT`；自增则使用 `AUTO_INCREMENT`；仅软删支断言 `deleted`） |
| 变更顺序 | 先更新设计权威 `docs/schema/{服务标识}/schema.md` + `ddl/V{n}__*.sql`，再同步本服务 `db/migration/`（见 [schema-conventions.md](../../detail-design/references/schema-conventions.md) §1.4） |

---

## 2. 本服务种子数据分层

| 层 | 内容 | 位置 | 使用方式 |
|----|------|------|---------|
| **本服务共享种子** | 跨 Story 复用的**本服务静态主数据**（如基础配置、字典或静态资源定义） | `{service}-impl/src/test/resources/db/test-data/*.sql` | 本服务集成测试类级 `@Sql(BEFORE_TEST_METHOD)` 或 `TestDataFactory` 引用 |
| **用例私有数据** | 单用例的业务行（如业务单据、状态流转记录、流水记录） | 用例内 `@Sql` 脚本或本服务 `TestDataFactory` 构造 | 每用例独立、唯一标识（integration-test-guide §5.2） |

**跨服务依赖数据不写 SQL**：如果被测服务（如 `{project}-{domain-a}`）依赖下游服务（如 `{project}-{domain-b}`）的数据，**绝不在本服务测试库里建下游服务的表或插下游 SQL**——改为通过 WireMock / RPC Stub 模拟下游接口返回！

### 2.1 TestDataFactory 职责

- 每个微服务维护自己的 `TestDataFactory`，只放**本服务跨用例复用**的构造方法
- 内部用唯一序列或生成器生成主键，**禁止硬编码同一条主键被多用例复用**

---

## 3. 本服务共享数据归属规则

1. 新 Story 需要本服务主数据 → 先查本服务 `src/test/resources/db/test-data/` 是否已有；没有才新增并登记用途。
2. 共享种子文件名表意，内容注释标注来源 Story 与用途。
3. 用例私有数据（状态机流转行）**不得**混入共享种子；共享种子**不得**被单个用例随意改删。
4. 时间敏感数据（如截止时间字段、有效时间窗起止时间）在用例内相对 `LocalDateTime.now()` 生成，避免过期变红。

---

## 4. 隔离与清理（与 integration-test-guide §5 一致）

- 共享种子幂等（可重复执行）。
- 用例数据唯一标识隔离；`AFTER_TEST_METHOD` 清理（`@Sql` 后置或 `@AfterEach` + `jdbcTemplate`）。
- **禁止**依赖 `@Transactional` 回滚（`RANDOM_PORT` 下必然失效）。

---

## 5. 反模式

```sql
-- ❌ 在当前服务的测试库里建下游微服务的表或插跨服务种子 SQL
-- ❌ 多个微服务共用同一份 Flyway 迁移目录
-- ❌ 本服务 test schema.sql 与 Flyway 权威源分叉
-- ❌ 用例私有数据写进共享种子（跨用例污染）
-- ❌ 固定写死时间戳（用例过期后变红）
```

---

## 6. 一句话记忆

> **每服务只管自己的库与自己的 `{service}-impl/.../db/migration/`；跨服务数据靠 WireMock/Stub 模拟不靠插表；主数据归本服务共享种子，用例数据归用例自己；每用例独立、可重跑、不靠事务回滚。**
