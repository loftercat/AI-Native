---
name: detail-design
description: >-
  将 Story 需求卡（AC + BR）转化为详细设计：OpenAPI、schema、Java 代码骨架、
  时序图与 DD 文档。支持增量与全新设计，产出可被 feature-coding 直接消费。
  用于详细设计、接口设计、API 设计、数据模型设计、表结构设计、详设等场景。
---

# 详细设计（Story → OpenAPI + schema + Java 骨架 + 时序图 + DD）

把 Story 中的 AC/BR 转化为可直接指导编码与测试的**技术契约**：OpenAPI、领域模型、schema、
Java 类/方法骨架、关键时序图，汇总为 `DD-STORY-{迭代}-{序号}-{slug}.md`。

本 Skill 继承**公司级十一步流程**，按本仓库 **Java 21 + Spring Boot / Spring Cloud 微服务架构**特化（仓库模式、调用协议、ORM、响应格式与内部鉴权等技术选型以画像 §5.4 为准）。权威边界：[system-landscape.md](../../architecture/system-landscape.md)、[java-project.md](../../rules/java-project.md)。

## 定位与边界

- **做什么**：Story + AC + BR → OpenAPI、schema、领域模型、Java 骨架、时序图、详设文档（六类产出）
- **不做**：需求拆解（`story-splitting`）、编码实现与测试（`feature-coding`）
- **不做**：完整架构设计 / 正式 ADR（仅轻量决策记入详设 §1.3）
- **不做**：改 Story 卡、Rule、`_golden/`、system-landscape
- **不做**：同步 Jira/看板；产出仅落本地 Markdown/YAML

## 输入方式

- **必备**：Story 需求卡（用户 `@` 或按编号查找），重点消费 **AC / BR**
- **可选**：原型 HTML/图片、HLD、ADR（`@` 引用）
- **自动获取**：存量 OpenAPI、schema、`*-api`/`*-impl`/BFF Java 代码

### 触发示例

```text
/detail-design STORY-{YYYY-Snn}-{序号}
@docs/requirements/{迭代}/STORY-{迭代}-{序号}-{slug}.md

增量详设：为 STORY-{迭代}-{序号} 补 OpenAPI 错误示例
```

---

## 流程

### 步骤 1：加载上下文资产

按顺序读取（Selection：只加载与当前 Story 相关的内容）：

| # | 资产 | 路径 | 缺失时 |
|---|------|------|--------|
| 1 | 详设模板 | `templates/design-template.md` | **阻断** |
| 2 | AC→契约 | `references/ac-to-contract-guide.md` | **阻断** |
| 3 | 代码骨架 | `references/code-skeleton-guide.md` | **阻断** |
| 4 | 领域模型 | `references/domain-model-guide.md` | **阻断** |
| 4b | schema / DDL | `references/schema-conventions.md` | 含持久化时 **阻断** |
| 4c | BFF / 域边界 | `references/bff-domain-boundary-guide.md` | 含 BFF + 域时 **阻断** |
| 5 | OpenAPI 约定 | `references/openapi-conventions.md` | 含 HTTP 时 **阻断** |
| 6 | Golden DD | `docs/design/_golden/DD-STORY-GOLDEN-001-*.md` | 降级 |
| 7 | 系统画像 | `architecture/system-landscape.md` | 提问 + §1.3 轻量 ADR |
| 8 | HLD（可选） | `docs/design/epics/HLD-EPIC-*.md` | 降级 |
| 9 | 词表 | `glossary/domain-glossary.md` | 降级 |
| 10 | 迭代 | `config/current-sprint` | 步骤 10 从 Story 路径推断 |
| 11 | Rule | `rules/java-project.md`、`rules/bff-domain-boundary.md`、`rules/exception-and-result.md`、`rules/mybatis-conventions.md`（仅画像 §5.4 P-3 选 MyBatis 时） | 含 BFF+域时必读 boundary；画像 §5.4 P-1~P-6 含 `[TBD]` 时在步骤 4 **阻断** |

**Selection 阈值**：Golden ≤ 3 个全量；词表按 Story 关键词子集。

> 产品背景：本仓库以 `system-landscape.md` + Epic/HLD 替代独立 `product-overview.md`。

### 步骤 2：输入处理与 AC/BR 分析

**Story 自动查找**（用户 `@` 优先）：

```text
1. 用户 @ 的 Story 路径 → 直接使用
2. 指令含 STORY-{YYYY-Snn}-{序号} → glob docs/requirements/**/STORY-{编号}*.md
3. 仅关键词 → 标题模糊匹配（多命中则 AskQuestion）
4. 均未命中 → 阻断
```

从每条 **AC** 提取：资源、动作、Given/When/Then、异常、**影响层**（BFF / `{domain-a}` / `{domain-b}` 等）。  
从每条 **BR** 提取：唯一性、数值/格式、状态流转、跨实体引用。  
从 Story §2、§5 提取：非目标、依赖 Story、原型对齐表。  
从 Story **§2.3 校验职责** 提取守卫 vs 领域规则，产出「校验职责落点表」（见 [bff-domain-boundary-guide.md](references/bff-domain-boundary-guide.md) §2）。

### 步骤 3：架构上下文确定

1. **服务归属**：Story「服务/模块」+ 画像 §二 → `{project}-gateway` / `{project}-bff-app` / `{project}-bff-admin` / `{project}-{domain-a}` / `{project}-{domain-b}` / `{project}-adapter`；无法匹配 → 提问，记 §1.3
2. **微服务契约分层（读画像 §5.4 P-2 / P-5 与 §3.6）**：
   - **BFF 层**：对外 HTTP（经 API 网关路由），`/api/v1/{project}/app|admin/...`，维护对外 OpenAPI
   - **领域微服务层**：每服务独立启动与独立数据库；按画像 **P-2** 暴露**内部远程接口**（HTTP 内部 Controller 或 RPC Provider），内部防外泄与透传头按画像 **P-5** 执行
   - 跨服务调用（BFF → `{domain-a}` → `{domain-b}` / `adapter`）的 AC **须**画 Mermaid 时序图
3. **增量契约自动查找**：
   - 对外契约：`docs/api/{bff服务标识}/openapi.yaml`
   - 内部服务间契约：按画像 P-2（HTTP 为 `docs/api/{领域服务标识}/openapi.yaml`；RPC 为 `*-api` 接口定义或 `.proto`）
   - 异步事件契约（若有）：按画像 §5.4 E-4
   - 表结构：`docs/schema/{服务标识}/schema.md`（每服务独立数据库与迁移脚本）
4. **存量代码扫描**（增量场景）：
   - 扫描归属服务的 BFF、`*-api`、`*-impl` 已有接口、Client、Service、持久化代码，供 §8.4 修改清单对齐

### 步骤 4：信息缺口评估与提问

**若 AI 补充错误会导致下游（feature-coding / 测试）实质缺陷 → 阻断，必须问。**

| 类型 | 示例 |
|------|------|
| **阻断** | 服务归属无依据、鉴权方式不明、状态机关键转换未定义、AC/BR 歧义、详设与接口契约业务字段冲突、**同一 BR 在 BFF 与领域服务重复实现且无分工**、**画像 §5.4 第一档（P-1~P-6）任一项仍为 `[TBD]`**、**本 Story 命中异步消息/跨服务写一致性/事件契约/定时任务/链路追踪但画像 §5.4 对应第二档（E-1~E-7）仍为 `[TBD]`** |
| **可补充** | 常规 DTO 类型、审计字段、分页默认值、`[AI推断]` 标注 |

> **选型占位禁令**：画像 §5.4 处于 `[TBD]` 时，**严禁** AI 用 `[AI推断]` 擅自选定 RPC 协议、ORM、响应格式、鉴权或分布式事务方案；必须阻断请用户拍板并回写画像后再继续。

存在阻断 → 集中提问；仅可补充 → 标注后继续。

### 步骤 5：接口设计（AC→对外/内部契约）

按 [ac-to-contract-guide.md](references/ac-to-contract-guide.md) **五步推导法**逐条 AC 推导对外 BFF API 与内部领域服务契约：

- **对外 BFF OpenAPI**（HTTP Story **必守** [openapi-conventions.md](references/openapi-conventions.md)）：
  1. `info.description` 写明响应成功判据（对齐画像 §3.7 / P-4）
  2. `servers` + `securitySchemes.bearerAuth`
  3. 错误响应结构 + 每 operation 成功/失败 `examples`
  4. 每条失败类 AC ↔ §5.3 错误码表 ↔ OpenAPI `examples` 可追溯
  5. `operationId` / `summary` / 请求响应 `example` 完整
- **内部服务间契约**（按画像 §5.4 P-2 / P-5）：
  - 若 P-2 选 HTTP（如 OpenFeign）：同步维护 `docs/api/{领域服务标识}/openapi.yaml`，标明内部路径前缀（如 `/internal/v1/{service}/...`）、防外泄要求与透传头（按 P-5）以及返回结构/错误码（按 P-4）；
  - 若 P-2 选 RPC（如 Dubbo / gRPC）：在详设 §5 与 §8 写明 `*-api` 远程接口/DTO 或 `.proto` 定义，以及错误传播语义（按 P-4）。

### 步骤 6：专项设计场景识别

按 [special-scenarios.md](references/special-scenarios.md) 扫描 AC/BR 关键词；命中则加载对应指南或 Rule，并核对画像 §5.4 对应选型：

| 场景 | 微服务落点与画像依赖 |
|------|----------------------|
| 幂等 / 回调 / 服务间重试 / 消息防重 | 外部回调、创建/扣减/资源占用、跨服务重试、MQ 消费去重；见 [idempotency-guide.md](../../reference/idempotency-guide.md) |
| 外部系统 / 第三方南向适配 | 归属对应微服务 `app/client/*` 或 `{project}-adapter` 适配服务 + 时序图（对接边界见画像 §四） |
| **异步消息 / 事件契约** | 按画像 §5.4 **E-2 / E-4** 选型设计（未定则步骤 4 阻断） |
| **跨服务写一致性** | 单操作涉及 ≥2 个微服务写库 → 按画像 §5.4 **E-3** 选型设计（Outbox/Saga/对账/Seata，未定则步骤 4 阻断），严禁本地 `@Transactional` 跨服务 |
| **定时任务** | 超时取消、对账、批处理；多实例默认必防重，方案按画像 §5.4 **E-6**（未定则阻断）；见 [scheduled-task-guide.md](../../reference/scheduled-task-guide.md) |
| **大文件 IO** | 上传/导入/导出/ZIP；见 [memory-safe-io-guide.md](../../reference/memory-safe-io-guide.md) + `rules/memory-safe-io.md` |

指南缺失 → 通用知识 + `[AI推断]` + 汇总建议补充。

### 步骤 7：数据模型设计（schema + DDL）

按 [schema-conventions.md](references/schema-conventions.md) 与画像 §5.4 **P-3（ORM 选型）**落盘；**每张表须字段说明表 + 可执行 DDL**，禁止仅写字段表。

1. **数据归属红线**：每张表只归属一个领域微服务写入（对齐画像 §二）；**严禁跨服务 SQL JOIN、严禁跨服务建外键**。
2. 表结构：业务字段 + **标准列**（权威见 [schema-conventions.md](references/schema-conventions.md) **§1.2**，主键与软删策略对齐画像 §5.4 P-3）。
3. **命名**：表名 snake_case；DO/Entity 在本服务 `infrastructure/dataobject/`（或对应 ORM 目录）。
4. **DDL**（`docs/schema/{服务标识}/schema.md` 每张表必写）：
   - 新表 → 完整 `CREATE TABLE`（含标准列、索引、`COMMENT`、`ENGINE=InnoDB`）
   - 增量 → `ALTER TABLE` + 变更摘要表
   - 索引说明表与 DDL 内 `KEY`/`UNIQUE KEY` 一致
5. **数据访问**（详设 §6.2 必写，按画像 §5.4 P-3 选型）：
   - 若选用 MyBatis：遵守 `rules/mybatis-conventions.md`（主键 CRUD、XML 软删、条件查询 XML only 默认 `AND deleted = 0`）；
   - 若选用其他 ORM（JPA/jOOQ 等）：按接入时替换的持久化 Rule 写明 Repository/Query 方法签名。
6. 增量：变更字段/索引 + 存量数据影响说明
7. 产出「请求/DTO 字段 → 表字段」映射
8. 验收种子数据（若有）单独一节 `INSERT`，**不能替代** `CREATE TABLE`
9. **本服务独立数据库迁移脚本**（涉及建表/改表，见 schema-conventions **§1.4**）：
   - `docs/schema/{服务标识}/ddl/V{n}__STORY-{迭代}-{序号}-{slug}.sql` 与**本服务** `{service}-impl/src/main/resources/db/migration/` 内容一致、服务内序号递增
   - 已合并的迁移脚本**禁止修改**；增量只能新增更高序号
10. **持久化测试 schema 同步**：
   - 若本服务持久化单测使用独立 `src/test/resources/schema.sql`，须与本服务 Flyway 迁移结果逐表同构（见 schema-conventions §1.4）

落盘：`docs/schema/{服务标识}/schema.md` + `ddl/V{n}__STORY-{迭代}-{序号}-{slug}.sql`（增量追加）；运行时迁移脚本可在 detail-design 或 feature-coding 落盘到本服务 `db/migration/`（须在 §6.1 注明）。落盘前过 schema-conventions §7 自检清单。

### 步骤 8：时序 / 交互设计

满足任一须 Mermaid 时序图（详设 §7）：

- 多步骤串行、跨域（BFF → `{domain-a}` → `{domain-b}`）
- 外部回调 / 异步通知
- 第三方南向适配器调用
- 事务 / 补偿 / 资源释放

简单单表 BFF CRUD 可省略。标注正常路径 + `alt` 异常路径。  
**BFF 泳道**仅含守卫与 `{Domain}Api` 调用，领域算法只在域泳道出现一次（见 bff-domain-boundary-guide §5）。

### 步骤 9：Java 代码骨架设计

按 [code-skeleton-guide.md](references/code-skeleton-guide.md) 与 [bff-domain-boundary-guide.md](references/bff-domain-boundary-guide.md) 将契约**具名到类与方法**（详设 §8，**feature-coding 权威来源**）。

1. §1.2 / §8.1 填写服务/模块与依赖方向
2. **推导新建类**（按分层，调用协议与 ORM 对齐画像 §5.4 P-2 / P-3）：
   - BFF：`*Controller` + Request/Response `{Entity}VO` + 远程客户端封装
   - 领域服务契约：`*-api` 远程客户端/接口 + `{Entity}DTO` + `{Domain}ErrorCode`（及按 E-4 的事件对象）
   - 领域服务实现：`*-impl` 内部远程入口（HTTP 内部 Controller 或 RPC Provider）→ `{Entity}Facade` → `{Entity}QueryService` / `{Entity}CommandService`
   - 跨服务调用：`app/client/*Client` 封装下游服务的远程契约（按 P-2）+ 请求头透传（按 P-5）
   - 外部系统：`{External}Client`、`{External}Gateway` 等适配类
   - 持久化：`{Entity}DO` + 持久化访问层（`{Entity}Mapper` / Repository，按 P-3）
3. **§8.4 增量修改清单**（增量**必填**）：关联 AC，禁止模糊「改 Service」
4. **§8.2 AC→代码追溯表**：每条后端 AC 至少一个落点；纯前端 AC 标 N/A
5. **§9 测试策略**：表格列「测试层 | 测试类/关注点 | 覆盖 AC | Mock 边界」；单服务 `*IT` 须写明下游微服务模拟方式（按 P-2）；跨服务主链路标明归部署后 `api-blackbox-test`（或 E-5 契约测试）
6. **落盘前**：过 bff-domain-boundary-guide §6 与 schema-conventions §7 自检清单
7. **事务边界与跨服务一致性硬约束**（写路径必过）：
   - **单服务单库本地事务**：`{Entity}Facade` / `{Entity}CommandService` 方法涉及**本服务内多步本地写**（本服务状态迁移 + 本服务关联表）→ §8.3 方法签名**必须显式标注 `@Transactional`**（或注明为何不用）；**严禁将跨服务远程调用或外部系统/第三方接口调用包进本地长事务**
   - **跨服务写一致性**：单条业务链路需修改 ≥2 个微服务数据库时，必须按画像 §5.4 **E-3** 选定的方案（Outbox/MQ 最终一致、Saga 补偿、对账兜底或 Seata）设计补偿/幂等与失败兜底（若 E-3 为 `[TBD]` 则步骤 4 已阻断）；**严禁假设存在跨域同库本地事务**
   - §1.3 ADR **必须有「事务与一致性边界」行**：写明本服务本地事务范围、跨服务/外部调用与事务的隔离及失败兜底机制
   - §7 时序图用 `Note` 标注各服务本地事务开启/提交与补偿/异步边界
   - 禁止仅在职责列写「事务编排」而不在签名具名到注解——`feature-coding` 不据此推断

**禁止**：方法体、私有方法、测试函数实现；跨服务依赖对方 `*-impl`；在本地 `@Transactional` 内包裹跨服务远程写假设；**BFF 与领域服务各设计一份同职责工具类**。

### 步骤 10：组装设计文档与落盘

1. 按 `design-template.md` 组装；按复杂度裁剪章节
2. **§4.3 可读性** + **§4.4 领域厚度**（含状态/写操作时 **必过** [domain-model-guide.md](references/domain-model-guide.md)）：
   - §4.3 主标题白话；技术信息在 `> **技术**：…`
   - §4.4 填 **代码落点（§8）** + **薄/中/厚**；写操作 §6.2 用条件 `UPDATE`，非默认全量 save
3. **迭代标识**：用户指令 > Story 目录名 > `config/current-sprint` > 询问
4. **路径**：`docs/design/{迭代}/DD-STORY-{迭代}-{序号}-{slug}.md`
5. **OpenAPI**：diff 摘要 → **用户确认** → 合并到 `docs/api/{服务标识}/openapi.yaml`
6. **同名 DD**：不静默覆盖，提示覆盖/重命名
7. **安全边界**：仅写详设、OpenAPI、schema 约定路径
8. **送审**：按 [rules/artifact-review.md](../../rules/artifact-review.md) §二 的 DD 三项必查派独立审查人，报告落 `docs/reviews/{迭代}/REVIEW-DD-{slug}.md`，通过后状态改「已确认」

### 步骤 11：产出汇总（对话输出，默认不落盘）

```markdown
## 详设汇总 — STORY-{迭代}-{序号}

### 1. 产出文件清单
### 2. AC → API / {Domain}Api 映射表
### 3. AC → 代码骨架追溯摘要
### 4. [AI推断] 清单
### 5. 阻断问题清单（若有）
### 6. 轻量 ADR（§1.3，若有）
### 7. 降级提示（缺失资产）
### 8. OpenAPI diff 摘要（若有）
### 9. 建议后续 → feature-coding
```

---

## AC→API 推导规则（摘要）

完整规则见 [ac-to-contract-guide.md](references/ac-to-contract-guide.md)。

| 步骤 | 动作 |
|------|------|
| 1 | 定 BFF：C 端 `{project}-bff-app`；B 端 `{project}-bff-admin` |
| 2 | AC 名词 → REST 资源（复数） |
| 3 | 创建 POST；查询 GET；更新 PATCH/PUT；动作 `POST .../动词` |
| 4 | Given→path/query；When→body；Then→`{Result<T>}.data`；异常→业务码 |
| 5 | 建 §3 总表 + §5.1 映射表；path 以 `/api/v1/{project}/app/` 或 `/api/v1/{project}/admin/` 开头 |

**业务判断**：嵌套 vs 扁平、分页 vs 全量、搜索 GET vs POST — 见 ac-to-contract-guide。

---

## 微服务契约分层（本仓库）

```text
读 system-landscape §三（含 §3.6 / §3.7）与 §5.4（P-2 / P-4 / P-5）
  → 对外入口：API 网关 → BFF（对外 HTTP + OpenAPI）
  → 领域微服务：每服务独立启动与独立 DB，按 P-2 暴露内部远程接口（HTTP 内部 OpenAPI 或 RPC 契约）
  → 跨服务 AC 必画跨服务时序图（标注本地事务与失败/一致性边界）
```

---

## 缺口评估判定

| 阻断 | 可补充 `[AI推断]` |
|------|-------------------|
| 服务归属、鉴权、状态机、事务与跨服务一致性边界、AC 歧义、画像 §5.4 未拍板的 `[TBD]` 命中项 | 字段类型、分页默认、非关键阈值 |

---

## 降级策略

| 缺失资产 | 处理 | 严重度 |
|----------|------|--------|
| `design-template.md` | **阻断** | 致命 |
| `ac-to-contract-guide` / `code-skeleton-guide` | **阻断** | 高 |
| `schema-conventions.md`（含持久化） | **阻断** | 高 |
| 系统画像 | 提问 + §1.3 ADR | 高 |
| 词表 | 跳过，汇总提示 | 中 |
| 存量 OpenAPI/schema | 视为首次设计 | 中 |
| Golden / HLD | 降级继续 | 低 |
| `reference/*` 专项指南 | 通用知识 + `[AI推断]` | 中 |

---

## 契约偏差

| 情形 | 处理 |
|------|------|
| Story AC vs 技术不可行 | 列开放问题，建议改 Story，不静默删 AC |
| 与 HLD 冲突 | 标注偏差，建议更新 HLD 或 Story |
| 仅 URL 不合规 | 详设/OpenAPI 直接按 `rules/java-project.md` 整改 |

---

## 与 Rule 的协作

| 步骤 | 引导 |
|------|------|
| 步骤 5 接口 | `rules/java-project.md` URL；`rules/exception-and-result.md` `{Result<T>}`/错误码 |
| 步骤 5 OpenAPI | `openapi-conventions.md` |
| 步骤 7 持久化 | `rules/mybatis-conventions.md`；[schema-conventions.md](references/schema-conventions.md) §1.2（雪花 / 软删） |
| 步骤 9 骨架 | `rules/java-project.md`、`rules/bff-domain-boundary.md` 分层、依赖方向 |
| 步骤 6 大文件 IO | `rules/memory-safe-io.md`；[memory-safe-io-guide.md](../../reference/memory-safe-io-guide.md) |
| 步骤 9 测试策略 | `rules/tdd-project-conventions.md`（编码阶段执行） |

冲突时：**规范听 Rule，流程听 Skill**。

---

## 授权边界

| 路径 | 默认 |
|------|------|
| `docs/design/{迭代}/DD-*.md` | ✅ |
| `docs/api/**/openapi.yaml`（当前 Story operation） | ✅ 增量合并 |
| `docs/schema/**/schema.md` | ✅ |
| `docs/requirements/**`、`_golden/`、`rules/`、`system-landscape.md` | ❌ |

---

## 依赖的项目资产

| 资产 | 路径 |
|------|------|
| 详设模板 | `templates/design-template.md` |
| AC→契约 | `references/ac-to-contract-guide.md` |
| schema / DDL | `references/schema-conventions.md` |
| BFF / 域边界 | `references/bff-domain-boundary-guide.md` |
| 代码骨架 | `references/code-skeleton-guide.md` |
| OpenAPI 约定 | `references/openapi-conventions.md` |
| 专项场景 | `references/special-scenarios.md` |
| 内存安全 IO | `reference/memory-safe-io-guide.md` |
| Golden | `docs/design/_golden/` |
| 系统画像 | `architecture/system-landscape.md` |
| 词表 | `glossary/domain-glossary.md` |
| 迭代 | `config/current-sprint` |

---

## 延伸阅读

- [docs/methodology/detail-design.md](../../docs/methodology/detail-design.md)
- [README.md](README.md)
- [hld-dd-boundary-guide.md](../high-level-design/references/hld-dd-boundary-guide.md)
