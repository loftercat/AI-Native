# schema 与 DDL 约定（MySQL · love-*）

> 落盘路径：
> - `docs/schema/{服务标识}/schema.md` — 设计权威：字段表 + 内嵌 DDL
> - `docs/schema/{服务标识}/ddl/V{序号}__{Story}.sql` — 设计阶段版本化 DDL（见 §1.3）
> - `love-app/src/main/resources/db/migration/V{n}__{Story}.sql` — **运行时权威**：Flyway 迁移（见 §1.4）
> 与 `rules/mybatis-conventions.md` 配合：schema 定义表结构；§6.2 / §8 定义 Mapper 与 XML。

## 1. 每张表的两段式结构（必守）

每张表在 `docs/schema/{服务}/schema.md` 中**须同时包含**：

1. **字段说明表**（Markdown 表格）— 便于评审与 AC 追溯  
2. **`CREATE TABLE` DDL**（`sql` 代码块）— 供 feature-coding / 联调 / 测试环境建表

禁止只有字段表、没有可执行 DDL（除非该 Story 明确不涉及持久化）。

### 1.1 推荐章节模板

```markdown
## N. 表：`table_name`（中文名）

| 列名 | 类型 | 空 | 说明 |
|------|------|----|------|
| `id` | BIGINT | N | PK，应用侧雪花生成 |
| …业务列… | | | |
| `created_at` | DATETIME | N | |
| `updated_at` | DATETIME | N | |
| `deleted` | TINYINT(1) | N | 软删除，0=未删除 1=已删除 |
| `deleted_at` | DATETIME | Y | 删除时间；未删为 NULL |

**索引**：

- `idx_xxx` (`col_a`, `col_b`) — 用途说明

```sql
CREATE TABLE table_name (
    id         BIGINT       NOT NULL COMMENT 'PK，应用侧雪花生成',
    ...
    created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted    TINYINT(1)   NOT NULL DEFAULT 0 COMMENT '软删除，0=未删除 1=已删除',
    deleted_at DATETIME     NULL COMMENT '删除时间',
    PRIMARY KEY (id),
    KEY idx_xxx (col_a, col_b)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='中文表名';
```
```

索引在 DDL 中须与上方「索引」列表一致。

### 1.2 标准列（必守）

业务表默认具备下列标准列；append-only / 技术表（日志、幂等记录等）若省略软删除，须在详设 §6.1 注明例外。

| 列 | 类型 | 约定 |
|----|------|------|
| `id` | `BIGINT NOT NULL` | PK；**禁止** `AUTO_INCREMENT`；应用侧雪花生成（见下） |
| `created_at` | `DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP` | 创建时间 |
| `updated_at` | `DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP` | 更新时间 |
| `deleted` | `TINYINT(1) NOT NULL DEFAULT 0` | 软删除标记：`0`=未删除，`1`=已删除 |
| `deleted_at` | `DATETIME NULL` | 执行软删时写入；未删为 `NULL`（可省略仅当 §6.1 说明） |

#### 主键：雪花 ID

| 项 | 约定 |
|----|------|
| DDL | `id BIGINT NOT NULL COMMENT 'PK，应用侧雪花生成'`（**无** `AUTO_INCREMENT`） |
| 生成器 | `com.loveforecast.common.core.util.SnowflakeIdGenerator`（`love-common` → `common-core`） |
| 依赖坐标 | `com.loveforecast:common-core`；版本与 **`love-common` 根 POM `<version>`** 对齐（当前 `1.0.0-SNAPSHOT`），本仓库用 `${love-common.version}` 管理 |
| 用法 | `*-impl` 写路径注入 `@Component`，`INSERT` 前 `do.setId(idGenerator.nextId())` |
| 落点 | `*CommandService` / `*Facade`（编排层）；**禁止**在 BFF 生成业务主键 |
| 测试种子 | 验收 `INSERT` 可用固定小 ID（如 `1`、`101`）；单测可 mock `SnowflakeIdGenerator` |
| 多实例 | 默认 `workerId=1` 仅适合单机；多实例须配置 `workerId`，在详设 §1.3 轻量 ADR 说明 |

结构：1 位符号位 + 41 位时间戳 + 10 位机器 ID + 12 位序列号；时钟回拨时生成器抛异常。

#### 软删除

| 项 | 约定 |
|----|------|
| 业务删除 | `UPDATE ... SET deleted=1, deleted_at=NOW() WHERE id=? AND deleted=0`；**禁止**对业务表用 `BaseMapper.deleteById` 物理删 |
| 业务查询 | 条件/列表 XML 默认加 `AND deleted = 0` |
| 主键查询 | `selectById` 若需排除已删行，详设 §6.2 写明（XML 封装或 Service 校验 `deleted`） |
| 唯一索引 | 业务键需唯一时，详设 §1.3 / 索引说明写清：`uk_(biz_key, deleted)` 或仅应用层保证未删唯一 |
| 物理删除 | 仅运维/合规场景，不进默认业务 API |

### 1.3 版本化 DDL 脚本（必守：涉及建表/改表时）

每张新表 / 每次增量变更，除 `docs/schema/{服务}/schema.md` 内嵌 DDL 外，**另落一份可执行脚本**：

| 项 | 约定 |
|----|------|
| 位置 | `docs/schema/{服务标识}/ddl/` |
| 命名 | `V{序号}__{Story编号}-{slug}.sql`，序号**服务内递增**（V1、V2…） |
| 示例 | `V{n}__{Story}.sql` |
| 内容 | `CREATE TABLE`（新表）或 `ALTER TABLE`（增量），与 `docs/schema/{服务}/schema.md` 内嵌 DDL **一一对应** |
| 多语句 | 同一 Story 多表/多次变更 → 同一脚本多条语句，不拆多文件 |
| 执行 | detail-design 阶段落盘；feature-coding 时**同步复制**到 `love-app/.../db/migration/`（见 §1.4） |

> 目的：设计评审可追踪；`docs/schema/.../ddl/` 与 Flyway 迁移脚本**内容一一对应**，命名均遵循 `V{n}__{Story}.sql`。

### 1.4 Flyway 迁移与 Mapper 测试 schema（必守：涉及建表/改表时）

运行时与集成测试的表结构由 **Flyway** 管理，不再使用单一 `{项目}/db/schema.sql`。

| 项 | 约定 |
|----|------|
| 运行时权威 | `love-app/src/main/resources/db/migration/V{n}__{Story}.sql` |
| 配置 | `{启动模块}/src/main/resources/application.yml` → `spring.flyway.locations: classpath:db/migration` |
| 序号 | **全局递增**（当前已有 V1…V28）；新 Story 取下一个未占用序号 |
| 已发布脚本 | **禁止修改**已合并的 `V{n}__*.sql`；增量变更只能新增更高序号脚本 |
| 设计 → 运行时 | feature-coding 将 `docs/schema/{服务}/ddl/V{n}__{Story}.sql` **复制或等价落盘**到 `love-app/.../db/migration/`（内容一致，序号对齐） |
| 集成测试建表 | `@SpringBootTest` 启动 `love-app` 上下文时 **Flyway 自动迁移**；**禁止** `@Sql(schema.sql)` 或 `withInitScript` 重复建表 |
| Mapper 测试建表 | `advice-impl` / `profile-impl` 的 `{模块}/src/test/resources/schema.sql` 保留**本模块表**子集，与 Flyway 迁移结果**逐表同构**；`AbstractMySqlContainerTest.withInitScript("schema.sql")` |
| **机械同步（推荐）** | 落盘 Flyway 后执行 `scripts/sync-mapper-schema-from-flyway.sh {order\|inventory\|all}`（需 Docker）：在容器内跑完全部迁移，再 `mysqldump` 导出对应表 DDL，避免手写漂移 |

**表结构变更同步清单**（feature-coding 必过）：

1. `docs/schema/{服务}/schema.md` + `ddl/V{n}__{Story}.sql`（设计权威）
2. `love-app/src/main/resources/db/migration/V{n}__{Story}.sql`（Flyway，禁止改已发布脚本）
3. 若涉及 `advice-impl` / `profile-impl` Mapper 测试表 → **执行 sync 脚本**（见上表）或手工维护 `*-impl/src/test/resources/schema.sql` 与 Flyway 结果逐表同构

## 2. DDL 书写规范

| 项 | 约定 |
|----|------|
| 方言 | **MySQL 8**（与 V1 单体部署一致） |
| 表名 | `snake_case`，与 DO 去后缀对应（`parking_lot` → `ParkingLotDO`） |
| 主键 | 见 **§1.2**（雪花 `BIGINT`，禁止 `AUTO_INCREMENT`） |
| 时间 | `DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP`；`updated_at` 加 `ON UPDATE CURRENT_TIMESTAMP` |
| 布尔 | `TINYINT(1) NOT NULL`，注释写 `1=是/0=否` |
| 枚举存库 | `VARCHAR(n)` 存枚举 **name**（如 `AVAILABLE`），与 `*-api` 枚举一致 |
| 可空 | 业务可空列显式 `NULL`；必填列 `NOT NULL` |
| 注释 | 业务列写 `COMMENT`；表尾 `COMMENT='…'` |
| 引擎/字符集 | `ENGINE=InnoDB DEFAULT CHARSET=utf8mb4` |
| 索引名 | `uk_` 唯一索引；`idx_` 普通索引；与字段说明表「索引」小节一致 |
| 外键 | V1 **默认不写** `FOREIGN KEY` 约束（应用层保证）；在字段说明写 `FK → 表.列` |

## 3. 增量变更

Story 只改部分字段时，`docs/schema/{服务}/schema.md` 追加：

```markdown
### 变更：`table_name`（STORY-xxx）

| 操作 | 列/索引 | 说明 |
|------|---------|------|
| ADD | `new_col` | … |

```sql
ALTER TABLE table_name
    ADD COLUMN new_col VARCHAR(64) NULL COMMENT '…' AFTER existing_col,
    ADD KEY idx_new (new_col);
```
```

- **全新表**：写完整 `CREATE TABLE`  
- **仅改索引/列**：写 `ALTER TABLE`，并在变更记录注明 Story 编号  
- 存量行影响（默认值、回填）须在变更表或详设 §6.1 说明

## 4. 验收种子数据

- 与 DDL **分节**：`## N. 验收种子数据` 单独 `INSERT` 代码块  
- `INSERT` 列名与当前 DDL 列一致；主键 ID 与测试 Fixture 约定对齐（可用固定小 ID，不必用雪花值）  
- 种子行默认 `deleted=0`、`deleted_at=NULL`  
- 种子数据**不能替代** `CREATE TABLE`

## 5. 与详设 §6 的分工

| 位置 | 内容 |
|------|------|
| 详设 §6.1 | 变更摘要、影响 Story、是否新建表；软删/雪花例外说明 |
| `docs/schema/{服务}/schema.md` | 权威字段表 + **完整/增量 DDL** + 变更记录 |
| 详设 §6.2 | Mapper 方法 + XML `id`（不写 SQL 正文）；写路径注明 `SnowflakeIdGenerator` |
| 详设 §8 | DO 类名与表字段映射；CommandService 注入生成器 |

## 6. feature-coding 消费方式

1. 将 `docs/schema/{服务}/ddl/V{n}__{Story}.sql` 落盘到 `love-app/src/main/resources/db/migration/`；启动应用或集成测试时 Flyway 自动建表/改表；`docs/schema/{服务}/schema.md` 为字段设计权威  
2. 涉及 Mapper 测试表时，执行 `scripts/sync-mapper-schema-from-flyway.sh order|inventory|all`（推荐）或手工同步 `advice-impl` / `profile-impl` 的 `{模块}/src/test/resources/schema.sql`（本模块表子集，与 Flyway 结果逐表同构）  
3. DO 字段与 DDL 列名一一对应（驼峰 ↔ snake_case），含 `deleted` / `deletedAt`  
4. 写操作：`SnowflakeIdGenerator.nextId()` → `setId` → `insert`；依赖 `com.loveforecast:common-core:${love-common.version}`  
5. 无 DDL 仅有字段表 → **阻断**，须先补 `detail-design` 或本文件约定

## 7. 自检清单（落盘前）

- [ ] 每张表有字段说明表 + `CREATE TABLE`（或增量 `ALTER TABLE`）
- [ ] 涉及建表/改表时，`ddl/` 下已按 `V{序号}__{Story}.sql` 落盘脚本，且与 `docs/schema/{服务}/schema.md` DDL 一致
- [ ] feature-coding 清单：`love-app/.../db/migration/V{n}__{Story}.sql` 已落盘（或详设注明由 feature-coding 同步）；已发布脚本未篡改
- [ ] 涉及 Mapper 测试表时，已执行 `scripts/sync-mapper-schema-from-flyway.sh`（源项目脚本，未随模板）（或手工对齐）且 `*-impl/src/test/resources/schema.sql` 与 Flyway 结果逐表同构
- [ ] 主键 DDL **无** `AUTO_INCREMENT`；说明为应用侧雪花生成
- [ ] 详设 §6.2 / §8 写明写操作注入 `SnowflakeIdGenerator` 及 `setId` 时机
- [ ] `common-core` 版本与 `love-common` 根 POM / `${love-common.version}` 一致
- [ ] 业务表含 `deleted`（及约定的 `deleted_at`），或 §6.1 注明例外
- [ ] 条件查询 XML 含 `deleted = 0`（或等价过滤）
- [ ] 软删用 `UPDATE`，非业务路径 `deleteById`
- [ ] 索引在说明表与 DDL 中一致
- [ ] 枚举列注释或 § 枚举表与 Java 枚举 name 一致
- [ ] `docs/schema/{服务}/schema.md` 顶部链到权威 DD；底部有变更记录
- [ ] 种子 `INSERT` 与 DDL 列匹配（若有验收数据）
