---
name: feature-coding
description: >-
  将 Story + 详设 + OpenAPI 落地为可运行 Java 代码：按 TDD 分层编写 *-impl/BFF 测试与实现，
  支持全新实现、增量补全、需求变更后同步。用于功能编码、Story 实现、TDD 开发、
  按详设编码、按 AC 写测试与实现、增量补全模块等场景。
---

> **模板版说明**：本 Skill 自已落地的源项目抽取为通用模板。文中项目专属值（模块名 `booking-*`、包名 `com.hema`、错误码号段、具体路径与 Story 号）均为**示例**，接入项目时按 [MIGRATION.md](../../../MIGRATION.md) 清单替换；「本仓库」指接入后的目标项目。


# 功能编码（Story + 详设 → Java + mvn test）

以 Story + 详设 + OpenAPI 为输入，在 Story 范围内**一体化 TDD**（先写/补测试，再写/修 Java），
产出分层架构代码与 `*/src/test/java/` 单元/API 测试，Story 范围 `mvn test` 全绿后交付。

本 Skill 继承**公司级通用流程**（八步、缺口三分法、契约偏差），按本仓库 **Java 21 + Spring Boot 3.2 + Maven 多模块** 特化。见 [README.md](../../../README.md)、[java-project.md](../../rules/java-project.md)。

## 定位与边界

- **做什么**：Story 范围内 `*-api`/`*-impl`/BFF + 测试一体化 TDD；URL 整改时同步**当前 Story** 详设/OpenAPI
- **不做**：需求拆解（`story-splitting`）、详设/OpenAPI 从零编写（`detail-design`）
- **不做**：全库存量测试审计（本仓库无 `test-quality-audit` Skill）、禅道 Bug 单（无 `bug-fix` Skill，见下文区分）
- **不做**：`booking-app` 关键链路集成/场景测试（`*IT`/`*ScenarioIT`，归 `integration-test-design` Skill）；本 Skill 仅写单元 / BFF API / Mapper 测试
- **不做**：独立「需求变更」Skill；默认不改 Story 卡
- **不做**：改 Rule、`docs/*/_golden/`；改**非当前 Story** 的详设/OpenAPI operation 业务定义
- **条件允许**：**当前 Story** 详设/OpenAPI 的 URL/路径同步

**与存量测试治理**：本仓库无独立 `test-quality-audit` Skill；本 Skill 负责新 Story TDD，存量治理按需人工或后续 Skill。

## 输入方式

- **必备**：Story 需求卡（用户 `@` 或按编号自动查找）
- **强烈推荐**：详设 `DD-STORY-{迭代}-{序号}-*.md`（用户 `@` 或自动查找）
- **必备（含 HTTP 层时）**：OpenAPI（`docs/api/{服务标识}/openapi.yaml`）
- **可选**：实现范围（全 Story / 指定层 / 指定 AC）；`@` schema、词表

### 触发示例

```text
/feature-coding 实现 STORY-2026-S01-001
@docs/requirements/2026-S01/STORY-2026-S01-001-query-allocate-space.md
@docs/design/_golden/DD-STORY-GOLDEN-001-*.md

按变更记录重新实现 STORY-xxx
只实现 inventory-impl 的 Service 层
```

---

## 流程

### 步骤 1：加载上下文资产

按顺序读取（Selection：只加载与当前 Story 相关的内容）：

1. `references/implementation-checklist.md`（**缺失则阻断**）
1b. `../detail-design/references/bff-domain-boundary-guide.md`（详设含 BFF + 域时 **必读**）
1c. `hema-common` 核心 API 已内联进 `rules/exception-and-result.md`（下方第 2 步自动注入，**无需额外 Read**）；完整说明见 [rules/exception-and-result.md](../../rules/exception-and-result.md)（按需延伸阅读）
2. **显式读取** Rule：
   - `rules/java-project.md`
   - `rules/bff-domain-boundary.md`（改 BFF 或 `*-impl` 时）
   - `rules/tdd-project-conventions.md`
   - `rules/exception-and-result.md`（含 HTTP 或域错误码时）
   - `rules/mybatis-conventions.md`（含持久化时）
   - `rules/memory-safe-io.md`（详设命中上传/导出/ZIP 时）；[memory-safe-io-guide.md](../../reference/memory-safe-io-guide.md)
3. `references/test-quality.md`（单元测试质量，对应公司级 `unit-test-quality`）
4. `docs/design/_golden/DD-STORY-GOLDEN-001-*.md` §9 测试策略（缺失则读同模块已有 `*Test.java`，汇总注明）
5. [README.md](../../../README.md)、`architecture/system-landscape.md`：模块边界、URL、V1 单体（缺失 URL → 降级并标注）
6. `glossary/domain-glossary.md`（按需；缺失则跳过）
7. `config/current-sprint`（迭代标识备用）
8. 详设 §9 测试策略、§8 代码骨架（**编码权威来源**）
9. **测试规格 TS（若存在）**：`glob docs/test-spec/{迭代}/TS-{Story编号}-*.md`（无迭代则 `glob docs/test-spec/**/TS-{Story编号}-*.md`）。TS 存在时，**用例来源与 Mock 边界以 TS 为准**（步骤 4 缺口清单、步骤 6 测试写法直接消费；见 [test-spec-alignment SKILL](../test-spec-alignment/SKILL.md)）

进入步骤 6 前还须阅读：同模块已有 `*Test.java`、详设 §8 列出的类（增量场景）。

**进入对应编码层前**按需读取 [layer-guides.md](references/layer-guides.md) 对应章节（Mapper / Service / BFF / Client）及 [bff-domain-boundary-guide.md](../detail-design/references/bff-domain-boundary-guide.md)。

### 步骤 2：加载 Story + 初步解析

**Story 自动查找**（用户 `@` 优先）：

```text
1. 用户 @ 的 Story 路径 → 直接使用
2. 指令含 STORY-YYYY-Snn-nnn → glob docs/requirements/**/STORY-{编号}*.md
3. 仅关键词 → docs/requirements/ 标题模糊匹配（多命中则 AskQuestion）
4. 均未命中 → 阻断，请用户 @ Story 或给出编号
```

**迭代标识**（与 detail-design 对齐）：`用户指令 > Story 所在目录名 > config/current-sprint > 询问用户`

从 Story 提取：Story 编号、AC/BR 列表、变更记录、**服务/模块**字段、前端-only AC 线索、跨 Story BR 引用（`STORY-xxx`、`STORY-xxx.BRn`）。

**模块预判**（终判在步骤 4）：用 Story「服务/模块」字段；不臆测。

**执行模式判定**（可组合，汇总须全部列出）：

| 模式 | 判定 |
|------|------|
| 全新 | 目标 `*-impl`/BFF 目录几乎为空 |
| 增量 | 详设 §8 类已存在或同模块已有测试 |
| 变更后 | Story 含「变更记录」 |
| 单层限定 | 用户指定只实现某层（下层须已存在且满足 AC） |

### 步骤 3：自动查找详设 / OpenAPI / schema

1. 读系统画像 → V1 单体 + 双 BFF；**服务标识**：详设「服务/模块」> Story 服务/模块 > 画像
2. **详设**（用户 `@` 优先）：
   - `docs/design/{迭代}/DD-{Story编号}-*.md`
   - 无迭代：`glob docs/design/**/DD-{Story编号}-*.md`（多命中则 AskQuestion）
3. **OpenAPI**（实现范围**含 BFF HTTP** 时必备；仅域 Service 可跳过并注明）：
   - `docs/api/{服务标识}/openapi.yaml`（C 端）
   - `docs/api/{服务标识}/openapi.yaml`（B 端）
   - 从详设 §5 AC→API 映射定位**当前 Story** 的 operation
4. **schema**：`docs/schema/{服务标识}/schema.md`（推荐，缺失可降级）

**跨 Story BR**：按编号 glob 加载被引用 Story 的 BR 段落。

### 步骤 4：确认模块 + 扫描存量 + 缺口评估

#### 模块终判（两阶段：步骤 2 预判 → 此处终判）

| 优先级 | 来源 |
|--------|------|
| 1 | 详设 §8 代码骨架 / AC→追溯表 |
| 2 | Story「服务/模块」 |
| 3 | 当前 Story OpenAPI operation + 画像 |
| 4 | 用户指令 |

无法终判 → **阻断类提问**。预判与终判不一致时以终判为准，汇总说明。

#### 路径映射（本仓库）

| 类型 | 路径 |
|------|------|
| 域契约 | `booking-*-service/*-api/src/main/java/` — `XxxApi`、DTO、错误码枚举 |
| 域实现 | `booking-*-service/*-impl/` — `app/provider`、`facade`、`service`、`client` |
| 持久化 | `*-impl/infrastructure/` — DO、Mapper 接口 + XML |
| App BFF | `booking-bff-app/` — Controller、Filter |
| Admin BFF | `booking-bff-admin/` — Controller、Filter |
| 启动 | `booking-app/` — 仅全局配置、聚合依赖（Story 明确要求时） |
| 域单元测试 | `*-impl/src/test/java/` |
| BFF API 测试 | `booking-bff-*/src/test/java/` — `@WebMvcTest` |
| 集成测试 | `booking-app/src/test/java/`（`*IT`/`*ScenarioIT`，归 `integration-test-design` Skill） |

扫描现有 Java 与测试，对照 AC 产出**缺口清单**。

#### 缺口三分法

| 类型 | 动作 |
|------|------|
| **阻断** | 错误码未定义；AC 与 OpenAPI 业务语义冲突；详设与 OpenAPI 字段/错误码不一致；权限不明；无 schema 且无 §8 Mapper 设计；含 HTTP 但 OpenAPI 缺失 → 提问或建议 detail-design；**详设 §8 在 BFF 与 impl 重复同职责工具类** → 回溯 detail-design；**AI 试图在本仓库新建 `Result`/`BizException`/`ErrorCode`/`BizErrorCode`/`GlobalExceptionHandler`/`PageResult`/`PageQuery`/`SnowflakeIdGenerator`** → 阻断，改用 `import com.hema.common.*`（公司级公共库内联速查，接入项目替换为本项目公共库文档）；**不写实现代码** |
| **整改** | URL 不合规 → 列入增量计划，不阻断，步骤 6 同步改 |
| **可补充** | Demo 鉴权、测试 Fixture → `[AI推断]` 并实现 |

**阻断未解除前不得写实现**；对已明确 AC **允许**先写失败测试（红）。

**TS 为权威时**（步骤 1 命中 TS）：缺口清单以 TS §6「缺口与阻断项」为准，AC 覆盖对照 TS §2 追溯表；TS §2 未覆盖的 AC 补用例到 TS 或标 N/A（先经用户确认，勿静默改 TS）。

缺口清单模板：

```markdown
## 缺口清单 — {Story编号}
| 类别 | 项 | 动作 |
|------|-----|------|
| AC 覆盖 | AC-03 无测试 | 新增 ParkingLotQueryServiceTest + AppParkingLotControllerTest |
| URL | path 与 OpenAPI 不一致 | 整改 Controller @RequestMapping |
| 阻断 | OpenAPI 缺 1604 错误示例 | 须先 detail-design |
```

### 步骤 5：增量计划

输出将**新建 / 修改 / 跳过**的文件列表（以详设 §8.4 为底稿）。

**默认策略**：展示计划后**继续执行**步骤 6，不等待用户逐条批准；用户明确反对或叫停时再停。

大范围改动（多模块、删大量测试）须在计划中突出标注。

### 步骤 6：分层 TDD 实现

**实现顺序**（自下而上；用户限定单层时只执行对应层）：

```text
1. DO + Mapper 接口 + XML（详设 §6 要求新表/查询时）
   - 新/改表：Flyway 落盘 `booking-app/.../db/migration/V{n}__{Story}.sql` 后，
     若涉及 order/inventory Mapper 测试表 → 执行 `scripts/sync-mapper-schema-from-flyway.sh`（源项目脚本，未随模板）（见 schema-conventions §1.4）
2. *-api：DTO、XxxApi 接口、域错误码枚举
3. Service（域规则、状态机）
4. Facade + XxxApiImpl（Provider）
5. BFF Controller + Request/Response VO
6. booking-app pom / 配置（脚手架或 Story 明确要求时）
```

每层：**先测试（按缺口）→ 实现 → mvn test 子集**。

**Mapper 未就绪快捷路径**：可先写 Service 测试（Mock Mapper/`XxxApi`），不得 Service 测直连 DB。

**各层要点**：

| 层 | 测试位置 | 禁止 |
|----|----------|------|
| Service | `*-impl/src/test/java/*ServiceTest` | 真实 HTTP、真实 DB |
| XxxApiImpl | 通常由 Service 测试覆盖；复杂编排可单测 Facade | 在 impl 写 Controller |
| BFF API | `booking-bff-*/src/test/java/*ControllerTest` — `@WebMvcTest` + Mock `XxxApi` | 断言 Mapper 内部 |
| 集成 | `booking-app/src/test/java/`（`*IT`/`*ScenarioIT`） | 依赖真实支付/车场（Mock 外部）；**归 `integration-test-design` Skill，不在本 Skill 编写** |

**增量 TDD 分支**——对每条后端 AC：

1. 已有测试且绿、符合当前 AC → 保留（可补 `@DisplayName` 或注释 `STORY-xxx AC-n`）
2. 已有测试失败 + AC 未变 → 修实现（测不动）；仅 URL 不合规 → 改路由与 MockMvc path
3. 已有测试失败 + AC 已变 → 确认 Story 已更新 → 改测 → 改实现
4. 无测试覆盖 → 先写失败测试 → 再实现
5. 有实现无追溯 → 补 DisplayName/注释，不重写逻辑
6. 变更记录废弃的 AC → 删/改用例，**禁止长期 `@Disabled`**

**前端-only AC**：后端不测不写；测试类文件头注释 N/A 及 AC 编号。

**新增错误码**：域模块 `*ErrorCode` 枚举 + OpenAPI `BusinessErrorBody` examples；OpenAPI 未声明则先补当前 Story operation 或标阻断。

按 `implementation-checklist.md` 每层完成后自检。

### 步骤 7：Story 范围 mvn test 验收

工作目录：仓库根（含根 `{项目}/pom.xml`）。

```bash
# 单模块（推荐）
mvn test -pl booking-inventory-service/inventory-impl -am
mvn test -pl booking-bff-app -am

# 多模块 Story
mvn test -pl booking-bff-app,booking-inventory-service/inventory-impl -am
```

**验收标准**：Story 关联测试**全部通过**。

可选全库快照（**不阻塞**交付）：

```bash
mvn test
```

**禁止** `@Disabled` / 删测 / 注释断言使 Story 范围变绿。

失败处理：

| 情形 | 动作 |
|------|------|
| 新测红、实现未写 | TDD 预期，继续实现 |
| AC 未变、原绿测变红 | 修实现 |
| AC 已变、测未更新 | 先改测试 |
| 环境问题 | 汇总注明 |

### 步骤 8：实现汇总（仅对话输出）

**默认**：在对话末尾输出结构化汇总，**不自动落盘**；用户明确要求时可写入 `docs/design/summaries/`。

```markdown
## 实现汇总 — {Story编号}

### 1. 元信息
- 模块：{booking-bff-app / inventory-impl / ...}
- 模式：全新 / 增量 / 变更后（可组合）
- 输入：Story、详设、OpenAPI 路径

### 2. 修改文件清单

### 3. AC → 测试 → 实现 追溯表
| AC | 测试类/方法 | 实现位置 | 备注 |

### 4. 前端-only / N/A
### 5. [AI推断] 清单
### 6. URL 变更对照（若有）
### 7. mvn test 结果
- Story 范围：passed/failed
- 全库（可选）：...

### 8. 共享 OpenAPI 遗留项（若有）
### 9. 建议后续
- detail-design 补 {缺口}
```

---

## URL 合规规则

完整路径（本仓库 V1）：

```text
/api/v1/booking/app/{resource}     # C 端 booking-bff-app
/api/v1/booking/admin/{resource}   # B 端 booking-bff-admin
```

| 段 | 来源 |
|----|------|
| 前缀 | `rules/java-project.md` / system-landscape §六 |
| resource | OpenAPI paths 末段（与详设 §5 一致） |

**整改须同步**：BFF `*Controller`、`@WebMvcTest` 请求 path、**当前 Story** 详设与 OpenAPI。

**共享 OpenAPI**：仅改当前 Story 的 paths 及**仅服务当前 operation** 的 components；`servers`/`security` 全局变更须在汇总列同文件未整改 path；共享 components 影响其他 operation → **阻断**，须 detail-design 或用户确认。

---

## 契约偏差

| 情形 | 处理 |
|------|------|
| 详设 vs OpenAPI 业务字段/错误码不一致 | **以 OpenAPI 为准**；暂停 API 实现，提示统一或回溯 detail-design |
| AC 技术无法满足 | 列偏差，建议更新 Story/详设，不静默改需求 |
| 仅 URL 不合规 | 整改类，步骤 6 同步 |

授权中「契约同步」**仅指 URL/路径**；业务语义变更须先 detail-design。

---

## 需求变更

不单独建需求变更 Skill。上游须先完成：

| 变更 | 上游 |
|------|------|
| AC/BR/范围 | story-splitting 或人工改 Story + 变更记录 |
| 接口/字段/错误码 | detail-design 增量详设 + OpenAPI |
| 仅 URL | 可在本 Skill 内同步详设/OpenAPI |

执行顺序：读变更记录 → 废弃 AC 删/改测 → 新 AC 改/增测（红）→ 改实现（绿）→ mvn test。

Story 未更新但用户要求改实现 → **拒绝**，提示先更新 Story。

**与 bug-fix 区分**：AC 未变、生产/联调行为与 AC 不符 → 按 Bug 修实现（本仓库无独立 `bug-fix` Skill，仍走本 Skill 但**不改 AC**）；AC 或变更记录已更新 → 本 Skill 需求变更流程。

---

## 授权边界

| 路径 | 默认 |
|------|------|
| `booking-*-service/*-api/`、`*-impl/`、`booking-bff-*/`、`booking-common/` | ✅ |
| `*/src/test/java/` | ✅ |
| `booking-app/`（配置、pom） | ✅（Story 需要时） |
| 当前 Story `DD-*.md`、`docs/api/**/openapi.yaml`（URL/路径同步） | ✅ |
| `docs/requirements/**`、`_golden/`、`rules/` | ❌ |
| 其他模块实现、非当前 Story 详设/OpenAPI 业务定义 | ❌（须用户显式授权） |

---

## 降级策略

| 缺失资产 | 处理 |
|----------|------|
| `implementation-checklist.md` | **阻断** |
| 详设 | Story + OpenAPI + §8 推断；`[AI推断]`；建议补详设 |
| OpenAPI | 含 BFF HTTP → 阻断；仅域 Service → 跳过 API 层 |
| schema | 从详设 §6 / OpenAPI 推断 |
| 测试样板 | 读同模块已有 `*Test.java` |
| 系统画像 URL | 用 `rules/java-project.md` 默认前缀并标注 |

---

## 与 Rule 的协作

本 Skill 管流程与 TDD 顺序；Rule 与配套文档管质量标准。步骤 1 显式读取 Rule；可执行项见 `implementation-checklist.md`。

| 步骤 | 引导 |
|------|------|
| 步骤 6 分层/依赖 | `rules/java-project.md`、`rules/bff-domain-boundary.md`、[layer-guides.md](references/layer-guides.md) |
| 步骤 6 测试 | `rules/tdd-project-conventions.md`、[test-quality.md](references/test-quality.md) |
| 步骤 6 响应/异常 | `rules/exception-and-result.md` |
| 步骤 6 持久化 | `rules/mybatis-conventions.md`、[schema-conventions.md](../detail-design/references/schema-conventions.md) §1.4（Flyway + `sync-mapper-schema-from-flyway.sh`（源项目脚本，未随模板）） |
| 步骤 6 大文件 IO | `rules/memory-safe-io.md`、[memory-safe-io-guide.md](../../reference/memory-safe-io-guide.md) |
| 步骤 6 BFF API | layer-guides §5 / **§5.1**（中文 JavaDoc + `@Tag`/`@Operation`/`@Schema`）、[openapi-conventions.md](../detail-design/references/openapi-conventions.md) §6 |
| 步骤 6 Client | layer-guides §6、详设时序图 |

冲突时：**规范听 Rule，流程听 Skill**。

---

## 依赖的项目资产

| 资产 | 路径 |
|------|------|
| hema-common API 速查 | `rules/exception-and-result.md` |
| 实现检查清单 | `references/implementation-checklist.md` |
| 分层编码指引 | `references/layer-guides.md` |
| 测试质量 | `references/test-quality.md` |
| 内存安全 IO | `reference/memory-safe-io-guide.md` |
| Golden 测试参考 | `docs/design/_golden/DD-STORY-GOLDEN-001-*.md` §9 |
| Story | `docs/requirements/{迭代}/STORY-*.md` |
| 详设 | `docs/design/{迭代}/DD-*.md` |
| OpenAPI | `docs/api/{服务标识}/`、`docs/api/{服务标识}/`、`docs/api/{域}/` |
| schema | `docs/schema/{服务标识}/schema.md` |
| 系统画像 | `architecture/system-landscape.md` |
| 迭代配置 | `config/current-sprint` |
| 实现汇总（可选落盘） | `docs/design/summaries/` |

---

## 延伸阅读

- [docs/methodology/feature-coding.md](../../docs/methodology/feature-coding.md)
- [README.md](README.md)
