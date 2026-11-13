---
name: detail-design
description: >-
  将 Story 需求卡（AC + BR）转化为详细设计：OpenAPI、schema、Java 代码骨架、
  时序图与 DD 文档。支持增量与全新设计，产出可被 feature-coding 直接消费。
  用于详细设计、接口设计、API 设计、数据模型设计、表结构设计、详设等场景。
---

> **模板版说明**：本 Skill 自已落地的源项目抽取为通用模板。文中项目专属值（模块名 `booking-*`、包名 `com.loveforecast`、错误码号段、具体路径与 Story 号）均为**示例**，接入项目时按 [MIGRATION.md](../../../MIGRATION.md) 清单替换；「本仓库」指接入后的目标项目。


# 详细设计（Story → OpenAPI + schema + Java 骨架 + 时序图 + DD）

把 Story 中的 AC/BR 转化为可直接指导编码与测试的**技术契约**：OpenAPI、领域模型、schema、
Java 类/方法骨架、关键时序图，汇总为 `DD-STORY-*.md`。

本 Skill 继承**公司级十一步流程**，按本仓库 **Java 21 + Spring Boot 3.2 + Maven 多模块 + 双 BFF** 特化。权威边界：[system-landscape.md](../../architecture/system-landscape.md)、[java-project.md](../../rules/java-project.md)。

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
/detail-design STORY-2026-S01-001
@docs/requirements/2026-S01/STORY-2026-S01-001-query-allocate-space.md

增量详设：为 STORY-xxx 补 OpenAPI 错误示例
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
| 11 | Rule | `rules/java-project.md`、`rules/bff-domain-boundary.md`、`rules/exception-and-result.md`、`rules/mybatis-conventions.md` | 含 BFF+域时必读 boundary |

**Selection 阈值**：Golden ≤ 3 个全量；词表按 Story 关键词子集。

> 产品背景：本仓库以 `system-landscape.md` + Epic/HLD 替代独立 `product-overview（公司级示例）。

### 步骤 2：输入处理与 AC/BR 分析

**Story 自动查找**（用户 `@` 优先）：

```text
1. 用户 @ 的 Story 路径 → 直接使用
2. 指令含 STORY-YYYY-Snn-nnn → glob docs/requirements/**/STORY-{编号}*.md
3. 仅关键词 → 标题模糊匹配（多命中则 AskQuestion）
4. 均未命中 → 阻断
```

从每条 **AC** 提取：资源、动作、Given/When/Then、异常、**影响层**（BFF / inventory 等）。  
从每条 **BR** 提取：唯一性、数值/格式、状态流转、跨实体引用。  
从 Story §2、§5 提取：非目标、依赖 Story、原型对齐表。  
从 Story **§2.3 校验职责** 提取守卫 vs 领域规则，产出「校验职责落点表」（见 [bff-domain-boundary-guide.md](references/bff-domain-boundary-guide.md) §2）。

### 步骤 3：架构上下文确定

1. **服务归属**：Story「服务/模块」+ 画像 → `love-app` / `love-advice` / `love-profile`；无法匹配 → 提问，记 §1.3
2. **双层 API（本仓库固定）**：
   - **BFF 层**：对外 HTTP，`/api/v1/love/app|admin/...`，OpenAPI 写 BFF
   - **域层**：`*-api` `XxxApi` + DTO，V1 同 JVM 注入，**无 HTTP**
   - 跨 BFF → order → inventory / adapter 的 AC **须** Mermaid 时序图
3. **增量契约自动查找**：
   - `docs/api/{服务标识}/openapi.yaml`、`docs/api/{服务标识}/openapi.yaml`
   - `docs/api/{域服务}/`（若有）
   - `docs/schema/{服务标识}/schema.md`
4. **存量代码扫描**（增量场景）：
   - `love-app/`
   - `love-{domain}/{domain}-api/`、`*-impl/`
   - 提取已有 `XxxApi`、Controller、Service、Mapper，供 §8.4 修改清单对齐

### 步骤 4：信息缺口评估与提问

**若 AI 补充错误会导致下游（feature-coding / 测试）实质缺陷 → 阻断，必须问。**

| 类型 | 示例 |
|------|------|
| **阻断** | 模块归属无依据、鉴权方式不明、状态机关键转换未定义、AC/BR 歧义、详设与 OpenAPI 业务字段冲突、**同一 BR 在 BFF 与 impl 重复实现且无分工** |
| **可补充** | 常规 DTO 类型、审计字段、分页默认值、`[AI推断]` 标注 |

存在阻断 → 集中提问；仅可补充 → 标注后继续。

### 步骤 5：接口设计（AC→API + OpenAPI）

按 [ac-to-contract-guide.md](references/ac-to-contract-guide.md) **五步推导法**逐条 AC 推导 BFF API；域能力写 `XxxApi` 方法（不进 OpenAPI paths）。

**OpenAPI 质量**（HTTP Story **必守** [openapi-conventions.md](references/openapi-conventions.md)）：

1. `info.description` 写明 **`code === 200` 业务成功**
2. `servers` + `securitySchemes.bearerAuth`
3. `BusinessErrorBody` + 每 operation 成功/失败 `examples`
4. 每条失败类 AC ↔ §5.3 错误码表 ↔ OpenAPI `examples` 可追溯
5. `operationId` / `summary` / 请求响应 `example` 完整

**双层模式**：OpenAPI 仅 BFF paths；域接口写在详设 §5 与 §8，时序图标 BFF → `XxxApi`。

### 步骤 6：专项设计场景识别

按 [special-scenarios.md](references/special-scenarios.md) 扫描 AC/BR 关键词；命中则加载对应指南或 Rule：

| 场景 | 本仓库落点 |
|------|------------|
| 幂等 / 回调 / 重试 | 支付回调、占库存；见 `reference/exception-and-result.md` + 专项表 |
| 外部支付 | `advice-impl` `PaymentClient` + 时序图 |
| LLM 调用 | `ChatClient` + `advice-impl` |
| 进程内事件 | V1 Spring Event（`advice-impl/app/event`） |
| **定时任务** | 超时取消、对账、批处理；见 [scheduled-task-guide.md](../../reference/scheduled-task-guide.md) |
| **大文件 IO** | 上传/导入/导出/ZIP；见 [memory-safe-io-guide.md](../../reference/memory-safe-io-guide.md) + `rules/memory-safe-io.md` |

指南缺失 → 通用知识 + `[AI推断]` + 汇总建议补充。

### 步骤 7：数据模型设计（schema + DDL）

按 [schema-conventions.md](references/schema-conventions.md) 落盘；**每张表须字段说明表 + 可执行 DDL**，禁止仅写字段表。

1. 从 AC/BR 识别实体 → 独立表 / 字段 / 枚举
2. 表结构：业务字段 + **标准列**（权威见 [schema-conventions.md](references/schema-conventions.md) **§1.2**）：
   - `id`：雪花 `BIGINT`，**禁止** `AUTO_INCREMENT`；写路径用 `SnowflakeIdGenerator`
   - `created_at` / `updated_at`；`deleted` / `deleted_at`（业务软删）
3. **命名**：表名 snake_case；DO 在 `infrastructure/dataobject/`
4. **DDL**（`docs/schema/{服务}/schema.md` 每张表必写）：
   - 新表 → 完整 `CREATE TABLE`（含标准列、索引、`COMMENT`、`ENGINE=InnoDB`）
   - 增量 → `ALTER TABLE` + 变更摘要表
   - 索引说明表与 DDL 内 `KEY`/`UNIQUE KEY` 一致
5. **数据访问**（详设 §6.2 必写）：
   - 新建写入 → `*CommandService` 注入 `SnowflakeIdGenerator`，`INSERT` 前 `setId`
   - 业务删除 → Mapper XML 软删（`UPDATE deleted=1`），**不用** `deleteById`
   - 主键查询 → MyBatis Plus `BaseMapper`（排除已删行须在 §6.2 写明）
   - 条件/联表/分页 → Mapper 接口 + **XML only**，默认 `AND deleted = 0`
6. 增量：变更字段/索引 + 存量数据影响说明
7. 产出「请求/DTO 字段 → 表字段」映射
8. 验收种子数据（若有）单独一节 `INSERT`，**不能替代** `CREATE TABLE`
9. **Flyway 迁移**（涉及建表/改表，见 schema-conventions **§1.4**）：
   - `docs/schema/{服务}/ddl/V{n}__{Story}.sql` 与 `love-app/src/main/resources/db/migration/` 内容一致、序号对齐
   - 已合并的 Flyway 脚本**禁止修改**；增量只能新增更高序号
10. **Mapper 测试 schema**（涉及 `advice-impl` / `profile-impl` 表时）：
   - 在 **feature-coding** 落盘 Flyway 后，执行 `scripts/sync-mapper-schema-from-flyway.sh order|inventory|all`（推荐；见 schema-conventions §1.4）
   - 或手工维护 `*-impl/src/test/resources/schema.sql`（本模块表子集，与 Flyway 结果逐表同构）

落盘：`docs/schema/{服务标识}/schema.md` + `ddl/V{n}__{Story}.sql`（增量追加）；Flyway 迁移可在 detail-design 或 feature-coding 落盘（须在 §6.1 注明）。落盘前过 schema-conventions §7 自检清单（含 Flyway、Mapper schema 同步、雪花主键、软删除、`common-core` 版本对齐）。

### 步骤 8：时序 / 交互设计

满足任一须 Mermaid 时序图（详设 §7）：

- 多步骤串行、跨域（BFF → order → inventory）
- 支付回调 / 异步通知
- LLM ChatClient 调用
- 事务 / 补偿 / 释放库存

简单单表 BFF CRUD 可省略。标注正常路径 + `alt` 异常路径。  
**BFF 泳道**仅含守卫与 `XxxApi` 调用，领域算法只在域泳道出现一次（见 bff-domain-boundary-guide §5）。

### 步骤 9：Java 代码骨架设计

按 [code-skeleton-guide.md](references/code-skeleton-guide.md) 与 [bff-domain-boundary-guide.md](references/bff-domain-boundary-guide.md) 将契约**具名到类与方法**（详设 §8，**feature-coding 权威来源**）。

1. §1.2 / §8.1 填写服务/模块与依赖方向
2. **推导新建类**（按分层）：
   - BFF：`*Controller` + Request/Response VO
   - 域：`*-api` `XxxApi` + DTO + `*ErrorCode`
   - 域：`*-impl` `XxxApiImpl` → Facade → Service
   - 跨域：`app/client/*Client` 注入其它 `XxxApi`
   - 外部：`ChatClient` 实现类、邮件 Client
   - 持久化：`*DO` + Mapper 接口 + XML `id`
3. **§8.4 增量修改清单**（增量**必填**）：关联 AC，禁止模糊「改 Service」
4. **§8.2 AC→代码追溯表**：每条后端 AC 至少一个落点；纯前端 AC 标 N/A
5. **§9 测试策略**：`ServiceTest`、`@WebMvcTest`、可选 Newman  
6. **落盘前**：过 bff-domain-boundary-guide §6 与 schema-conventions §7 自检清单
7. **事务边界硬约束**（写路径必过）：
   - Facade / CommandService 方法涉及**多步本地写**（状态迁移 + 关联表 + 跨域同 DataSource 释放/锁定）→ §8.3 方法签名**必须显式标注 `@Transactional`**（或注明为何不用，如纯外部调用编排）
   - §1.3 ADR **必须有「事务边界」行**：写明事务覆盖范围、外部调用（LLM/邮件）与事务的关系（纳入/事务外靠顺序保证/回调兜底）
   - §7 时序图用 `Note` 标注事务开启/提交边界
   - 禁止仅在职责列写「事务编排」而不在签名具名到注解——feature-coding 不据此推断

**禁止**：方法体、私有方法、测试函数实现；在 `*-impl` 设计 Controller；V1 设计 OpenFeign；**BFF 与 impl 各设计一份同职责工具类**。

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

### 步骤 11：产出汇总（对话输出，默认不落盘）

```markdown
## 详设汇总 — {Story编号}

### 1. 产出文件清单
### 2. AC → API / XxxApi 映射表
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
| 1 | 定 BFF：C 端 `love-app` |
| 2 | AC 名词 → REST 资源（复数） |
| 3 | 创建 POST；查询 GET；更新 PATCH/PUT；动作 `POST .../动词` |
| 4 | Given→path/query；When→body；Then→`Result.data`；异常→业务码 |
| 5 | 建 §3 总表 + §5.1 映射表；path 以 `/api/v1/love/app|admin/` 开头 |

**业务判断**：嵌套 vs 扁平、分页 vs 全量、搜索 GET vs POST — 见 ac-to-contract-guide。

---

## 双层 API（本仓库）

```text
读 system-landscape §三
  → 固定双层：BFF（HTTP + OpenAPI）+ 域 XxxApi（无 HTTP，V1 同 JVM）
  → 跨域 AC 必画 BFF → XxxApi 时序图
```

---

## 缺口评估判定

| 阻断 | 可补充 `[AI推断]` |
|------|-------------------|
| 模块/服务归属、鉴权、状态机、事务边界、AC 歧义 | 字段类型、分页默认、非关键阈值 |

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
| 步骤 5 接口 | `rules/java-project.md` URL；`rules/exception-and-result.md` `Result`/错误码 |
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
