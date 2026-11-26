# schema 与 DDL 约定（MySQL · 微服务）

> 落盘路径（微服务每服务独立数据库与迁移目录）：
> - `docs/schema/{服务标识}/schema.md` — 设计权威：字段表 + 内嵌 DDL
> - `docs/schema/{服务标识}/ddl/V{序号}__STORY-{迭代}-{序号}-{slug}.sql` — 设计阶段版本化 DDL（见 §1.3）
> - `{service}-impl/src/main/resources/db/migration/V{n}__STORY-{迭代}-{序号}-{slug}.sql` — **本服务运行时权威**：Flyway 迁移（见 §1.4，每服务独立递增）
> 与画像 §5.4 **P-3（ORM 选型）**配合（选 MyBatis 时见 `rules/mybatis-conventions.md`）；**严禁跨服务 SQL JOIN、严禁跨服务外键**。

## 1. 每张表的两段式结构（必守）

每张表在 `docs/schema/{服务标识}/schema.md` 中**须同时包含**：

1. **字段说明表**（Markdown 表格）— 便于评审与 AC 追溯  
2. **`CREATE TABLE` DDL**（`sql` 代码块）— 供 feature-coding / 联调 / 测试环境建表

禁止只有字段表、没有可执行 DDL（除非该 Story 明确不涉及持久化）。

### 1.1 推荐章节模板

业务列与时间列始终出现。主键列、删除相关列只写入 §1.2 已选定的那一支。不要把未选中的分支抄进 DDL。

```markdown
## N. 表：`{table_name}`（中文名）

| 列名 | 类型 | 空 | 说明 |
|------|------|----|------|
| `id` | BIGINT | N | PK，生成方式见 §1.2 主键分支 |
| …业务列… | | | |
| `created_at` | DATETIME | N | |
| `updated_at` | DATETIME | N | |

**索引**：

- `idx_xxx` (`col_a`, `col_b`) — 用途说明

```sql
CREATE TABLE {table_name} (
    id         BIGINT       NOT NULL COMMENT 'PK，生成方式见 §1.2',
    ...
    created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_xxx (col_a, col_b)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='中文表名';
```
```

索引在 DDL 中须与上方「索引」列表一致。自增支把 `id` 写成 `BIGINT NOT NULL AUTO_INCREMENT`。软删支在时间列之后追加 `deleted`、`deleted_at`。

### 1.2 标准列（必守）与分支

业务表默认具备下列标准列。主键生成方式与删除方式不在本表写死，按画像 §5.4 P-3 择一。MyBatis / MyBatis-Plus 的执行口径是 `rules/mybatis-conventions.md`「项目实现」；JPA / jOOQ 等是接入时替换的持久化 Rule 文首。两处都未写明主键或删除时阻断。

| 列 | 类型 | 约定 |
|----|------|------|
| `id` | `BIGINT NOT NULL` | PK。自增或应用侧生成见下方主键分支，两支不得混用 |
| `created_at` | `DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP` | 创建时间 |
| `updated_at` | `DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP` | 更新时间 |

#### 主键分支（按「项目实现」择一）

**应用侧分布式 ID 或 UUID**

| 项 | 约定 |
|----|------|
| DDL | `id BIGINT NOT NULL COMMENT 'PK，应用侧生成'`（**无** `AUTO_INCREMENT`） |
| 生成器 | `{basePackage}.common.core.util.{IdGenerator}`（`{company-common}` → `common-core`） |
| 依赖坐标 | `{groupId}:{common-core}`；版本与 **`{company-common}` 根 POM `<version>`** 对齐，由父 POM 统一版本属性管理 |
| 用法 | `*-impl` 写路径注入 `@Component`，`INSERT` 前 `do.setId(idGenerator.nextId())` |
| 落点 | `{Entity}CommandService` / `{Entity}Facade`（编排层）；**禁止**在 BFF 生成业务主键 |
| 测试种子 | 验收 `INSERT` 可用固定小 ID（如 `1`、`101`）；单测可 mock `{IdGenerator}` |
| 多实例 | 雪花一类生成器默认 `workerId=1` 仅适合单机；多实例须配置 `workerId`，在详设 §1.3 轻量 ADR 说明 |

雪花算法示例：1 位符号位 + 41 位时间戳 + 10 位机器 ID + 12 位序列号；时钟回拨时生成器抛异常。UUID 由应用侧生成后写入，同样禁止 `AUTO_INCREMENT`。

**数据库自增**

| 项 | 约定 |
|----|------|
| DDL | `id BIGINT NOT NULL AUTO_INCREMENT` |
| 写入 | 应用不调用 `setId`，不引入 `{IdGenerator}` 填主键 |
| 禁止 | 与应用侧生成器混用 |

#### 删除分支（按「项目实现」择一）

**软删**

| 项 | 约定 |
|----|------|
| 列 | `deleted TINYINT(1) NOT NULL DEFAULT 0`；`deleted_at DATETIME NULL` |
| 业务删除 | `UPDATE {table_name} SET deleted=1, deleted_at=NOW() WHERE id=? AND deleted=0`；**禁止**对业务表用 `BaseMapper.deleteById` 物理删 |
| 业务查询 | 条件/列表 XML 默认加 `AND deleted = 0` |
| 主键查询 | `selectById` 若需排除已删行，详设 §6.2 写明（XML 封装或 Service 校验 `deleted`） |
| 唯一索引 | 业务键需唯一时，详设 §1.3 / 索引说明写清：`uk_(biz_key, deleted)` 或仅应用层保证未删唯一 |
| 技术表 | 日志、幂等记录等可省略软删列，详设 §6.1 注明 |
| 物理删除 | 仅运维/合规场景，不进默认业务 API |

**状态作废**

| 项 | 约定 |
|----|------|
| 列 | 业务表不建 `deleted`、`deleted_at`。作废语义用画像规定的状态列 |
| 业务删除 | 按该状态列做条件 `UPDATE`；**禁止**把 `deleteById` 当作业务删除 |
| 业务查询 | 按有效状态过滤，不追加 `AND deleted = 0` |
| 状态迁移 | `WHERE id=? AND status=?`，不带 `deleted` 条件 |

### 1.3 版本化 DDL 脚本（必守：涉及建表/改表时）

每张新表 / 每次增量变更，除 `docs/schema/{服务标识}/schema.md` 内嵌 DDL 外，**另落一份可执行脚本**：

| 项 | 约定 |
|----|------|
| 位置 | `docs/schema/{服务标识}/ddl/` |
| 命名 | `V{序号}__STORY-{迭代}-{序号}-{slug}.sql`，序号**服务内递增**（V1、V2…） |
| 示例 | `V{n}__STORY-{迭代}-{序号}-{slug}.sql` |
| 内容 | `CREATE TABLE`（新表）或 `ALTER TABLE`（增量），与 `docs/schema/{服务标识}/schema.md` 内嵌 DDL **一一对应** |
| 多语句 | 同一 Story 多表/多次变更 → 同一脚本多条语句，不拆多文件 |
| 执行 | detail-design 阶段落盘；feature-coding 时**同步复制**到本服务 `{service}-impl/src/main/resources/db/migration/`（见 §1.4） |

> 目的：设计评审可追踪；`docs/schema/{服务标识}/ddl/` 与本服务 Flyway 迁移脚本**内容一一对应**，命名均遵循 `V{n}__STORY-{迭代}-{序号}-{slug}.sql`。

### 1.4 每服务独立 Flyway 迁移与持久化测试 schema（必守：涉及建表/改表时）

每个有数据库的微服务各自独立管理表结构与 Flyway 迁移脚本，**严禁多个微服务共享同一迁移目录或跨库访问表**。

| 项 | 约定 |
|----|------|
| 运行时权威 | **本服务** `{service}-impl/src/main/resources/db/migration/V{n}__STORY-{迭代}-{序号}-{slug}.sql` |
| 配置 | 本服务 `application.yml` → `spring.flyway.locations: classpath:db/migration` |
| 序号 | **服务内递增**（V1、V2…）；新 Story 取本服务下一个未占用序号 |
| 已发布脚本 | **禁止修改**已合并的 `V{n}__*.sql`；增量变更只能新增更高序号脚本 |
| 设计 → 运行时 | feature-coding 将 `docs/schema/{服务标识}/ddl/V{n}__STORY-{迭代}-{序号}-{slug}.sql` **复制或等价落盘**到本服务 `{service}-impl/.../db/migration/`（内容一致，序号对齐） |
| 单服务集成测试建表 | `@SpringBootTest` 启动本服务上下文时 **Flyway 自动迁移本服务容器库**；**禁止** `@Sql(schema.sql)` 或 `withInitScript` 重复建表 |
| 持久化单测建表 | 若本服务持久化单测使用 `{service}-impl/src/test/resources/schema.sql`，须与本服务 Flyway 迁移结果**逐表同构**（也可直接由 Flyway 初始化容器库） |

**表结构变更同步清单**（feature-coding 必过）：

1. `docs/schema/{服务标识}/schema.md` + `ddl/V{n}__STORY-{迭代}-{序号}-{slug}.sql`（设计权威）
2. `{service}-impl/src/main/resources/db/migration/V{n}__STORY-{迭代}-{序号}-{slug}.sql`（本服务 Flyway，禁止改已发布脚本）
3. 若本服务持久化单测另维护 `src/test/resources/schema.sql`，确保与本服务 Flyway 结果逐表同构

## 2. DDL 书写规范

| 项 | 约定 |
|----|------|
| 方言 | **MySQL 8**（与各微服务独立数据库基线一致） |
| 表名 | `snake_case`，与 DO/Entity 对应（`{table_name}` → `{Entity}DO`） |
| 主键 | 见 **§1.2**：自增支使用 `AUTO_INCREMENT`，应用侧 ID 支禁止 `AUTO_INCREMENT` |
| 时间 | `DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP`；`updated_at` 加 `ON UPDATE CURRENT_TIMESTAMP` |
| 布尔 | `TINYINT(1) NOT NULL`，注释写 `1=是/0=否` |
| 枚举存库 | `VARCHAR(n)` 存枚举 **name**（如 `AVAILABLE`），与 `*-api` 枚举一致 |
| 可空 | 业务可空列显式 `NULL`；必填列 `NOT NULL` |
| 注释 | 业务列写 `COMMENT`；表尾 `COMMENT='…'` |
| 引擎/字符集 | `ENGINE=InnoDB DEFAULT CHARSET=utf8mb4` |
| 索引名 | `uk_` 唯一索引；`idx_` 普通索引；与字段说明表「索引」小节一致 |
| 外键与跨库关联 | **严禁跨服务外键与跨服务 SQL JOIN**；服务内默认不建数据库 `FOREIGN KEY` 约束（应用层保证），在字段说明写 `逻辑引用 → {服务/表}.列` |

## 3. 增量变更

Story 只改部分字段时，`docs/schema/{服务标识}/schema.md` 追加：

```markdown
### 变更：`{table_name}`（STORY-{迭代}-{序号}）

| 操作 | 列/索引 | 说明 |
|------|---------|------|
| ADD | `new_col` | … |

```sql
ALTER TABLE {table_name}
    ADD COLUMN new_col VARCHAR(64) NULL COMMENT '…' AFTER existing_col,
    ADD KEY idx_new (new_col);
```
```

- **全新表**：写完整 `CREATE TABLE`  
- **仅改索引/列**：写 `ALTER TABLE`，并在变更记录注明 Story 编号  
- 存量行影响（默认值、回填）须在变更表或详设 §6.1 说明

## 4. 验收种子数据

- 与 DDL **分节**：`## N. 验收种子数据` 单独 `INSERT` 代码块  
- `INSERT` 列名与当前 DDL 列一致；主键 ID 与测试 Fixture 约定对齐（可用固定小 ID，不必用分布式 ID 值）  
- 软删支的种子行写 `deleted=0`、`deleted_at=NULL`；状态作废支不写这两列  
- 种子数据**不能替代** `CREATE TABLE`

## 5. 与详设 §6 的分工

| 位置 | 内容 |
|------|------|
| 详设 §6.1 | 变更摘要、影响 Story、是否新建表；主键分支与删除分支（与「项目实现」一致） |
| `docs/schema/{服务标识}/schema.md` | 权威字段表 + **完整/增量 DDL** + 变更记录 |
| 详设 §6.2 | `{Entity}Mapper` 方法 + XML `id`（不写 SQL 正文）；写路径注明主键生成方式（应用侧生成器或数据库自增） |
| 详设 §8 | `{Entity}DO` 类名与表字段映射；仅应用侧主键分支在 `{Entity}CommandService` 注入生成器 |

## 6. feature-coding 消费方式

1. 将 `docs/schema/{服务标识}/ddl/V{n}__STORY-{迭代}-{序号}-{slug}.sql` 落盘到**本服务** `{service}-impl/src/main/resources/db/migration/`；启动本服务或单服务集成测试时 Flyway 自动建表/改表；`docs/schema/{服务标识}/schema.md` 为字段设计权威
2. 若本服务持久化单测另维护 `{service}-impl/src/test/resources/schema.sql`，确保与本服务 Flyway 结果逐表同构
3. DO/Entity 字段与 DDL 列名一一对应（驼峰 ↔ snake_case），持久化实现严格遵循画像 §5.4 P-3（ORM 选型）
4. 主键生成按 §1.2 选定的分支执行：应用侧分支在 `INSERT` 前 `setId`；自增分支不 `setId`
5. 无 DDL 仅有字段表 → **阻断**，须先补 `detail-design` 或本文件约定

## 7. 自检清单（落盘前）

- [ ] 每张表只归属当前微服务，无跨服务 SQL JOIN、无跨服务数据库外键
- [ ] 每张表有字段说明表 + `CREATE TABLE`（或增量 `ALTER TABLE`）
- [ ] 涉及建表/改表时，`ddl/` 下已按 `V{序号}__STORY-{迭代}-{序号}-{slug}.sql` 落盘脚本，且与 `docs/schema/{服务标识}/schema.md` DDL 一致
- [ ] feature-coding 清单：**本服务** `{service}-impl/.../db/migration/V{n}__STORY-{迭代}-{序号}-{slug}.sql` 已落盘（或详设注明由 feature-coding 同步）；已发布脚本未篡改
- [ ] 持久化单测 schema（若另行维护）与本服务 Flyway 结果逐表同构
- [ ] 主键与删除方式与 §1.2 的执行口径及画像 §5.4 P-3 为同一分支（应用侧 ID 则 DDL 无 `AUTO_INCREMENT`；自增则 DDL 为 `AUTO_INCREMENT` 且应用不生成 id；软删则条件查询含 `deleted = 0` 且删除用 `UPDATE`；状态作废则无 `deleted` 列且查询不带 `deleted = 0`）
- [ ] 索引在说明表与 DDL 中一致
- [ ] 枚举列注释或 § 枚举表与 Java 枚举 name 一致
- [ ] `docs/schema/{服务标识}/schema.md` 顶部链到权威 DD；底部有变更记录
- [ ] 种子 `INSERT` 与 DDL 列匹配（若有验收数据）
