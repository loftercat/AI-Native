# AI Native 架构说明

> 本文描述**本仓库**（已落地源项目）的 AI Native 工程方法论：Skill 流水线、文档资产、Java 代码分层。  
> 产品域系统画像见 [`architecture/system-landscape.md`](../../architecture/system-landscape.md)。

---

## 1. 定位：两条主线

| 主线 | 目的 | 主要目录 |
|------|------|----------|
| **方法论流水线** | 用 Agent Skill + Rule + 文档契约，把「需求 → 设计 → 代码 → 测试」做成可重复、可审计的流程 | `skills/`（模板平铺，无镜像）、`docs/*/_golden/`、`docs/agile/` |
| **可运行后端** | Java 微服务实现预订编排：API 网关 + 独立 BFF + 独立领域微服务 + 南向适配服务 | `booking-*/`（规划）、`docs/api/`、`docs/schema/` |

**本仓库不是 Python/FastAPI Demo**；Skill 与 Rule 已按 **Java 21 + Spring Boot 3.2 + Maven 多模块** 特化。方法论精华可迁移到其他 Java 业务仓库；`architecture/system-landscape.md` 为**本项目独有**，勿被其它产品线覆盖。

---

## 2. 方法论总体架构

```text
                    ┌─────────────────────────────────────┐
                    │         横切 Rule（rules/）    │
                    │  java-project / TDD / AC / 命名      │
                    └─────────────────┬───────────────────┘
                                      │ 约束所有 Skill 产出
    业务原始需求 ──► journey-scenario-design ──► JSD（用户旅程 + 业务场景）
                                    │
                                    ▼
        EPIC 卡（Epic/PRD 先行则直接建；JSD 先行则缺失时由 JSD 起草，人确认）
                                    │
                                    ▼
                       high-level-design ──► HLD（边界/集成/建议 Story）
                         │
                         ▼
              story-splitting ──► Story（AC/BR）
                         │
                         ▼
              detail-design ──► 详设 + OpenAPI + schema + Java 骨架
                         │
                         ▼
              test-spec-alignment ──► TS（用例级测试规格 + AC 覆盖校验）
                         │
                         ▼
              feature-coding ──► TDD 实现（mvn test）
                         │
                         ▼
              代码审查 ──► REVIEW-CODE-IMPL-*
                         │
                         ▼
              integration-test-design ──► *IT / *ScenarioIT
                         │
                         ├── QA 专线：qa-acceptance-case-design → api-blackbox-test / test-data-design
                         └── 旁路：bugfix / legacy-test-migration
```

### 2.1 四层资产模型

| 层级 | 路径 | 职责 |
|------|------|------|
| **执行层** | `skills/*/SKILL.md`（模板平铺于 skills/） | Agent 运行时步骤：加载什么、写什么、何时阻断 |
| **横切层** | `rules/*.md` | 编码与文档规范；Skill 引用 Rule，不重复全文 |
| **配套层** | `skills/{skill}/{templates,references}/` | 模板、粒度指引、边界说明；Skill **点名加载**（自包含） |
| **样例层** | `docs/requirements/_golden/`、`docs/design/_golden/` | Few-shot；与真实迭代 Story 分离，**不随 Skill 迁移** |

> Skill 自包含：复制 `skills/{skill}/` 即完成迁移；完整性校验 `bash scripts/validate-skills.sh`。

### 2.2 配置与敏捷底座

| 资产 | 路径 | 作用 |
|------|------|------|
| 当前迭代 |`config/current-sprint`（模板约定路径） | 单一事实源（如 `2026-S01`） |
| 卡片命名 | `docs/agile/card-naming-conventions.md` | Story / DD / HLD 编号与目录 |
| 领域词表 | `glossary/domain-glossary.md` | Story / 详设术语一致 |
| 系统画像 | `architecture/system-landscape.md` | 模块边界、集成、URL、技术栈（**权威**） |

---

## 3. 主线 7 环职责与边界

> 完整 12 个后端 Skill（含 QA 专线 3 环与旁路 2 环）的触发时机、输入/产出、栈依赖见 [Skill清单与栈依赖.md](../../Skill清单与栈依赖.md)；本节只保留主线前 7 环的边界。

| Skill | 输入 | 产出 | 不做 |
|-------|------|------|------|
| **journey-scenario-design** | 业务原始需求（PRD 草稿/口头/原型） | `docs/requirements/epics/JSD-EPIC-*.md`（Persona、旅程图、场景矩阵） | HLD/Story/AC/代码 |
| **high-level-design** | Epic / PRD + 系统画像（+ JSD 建议必读） | `docs/design/epics/HLD-EPIC-*.md`、建议 Story 列表 | Story AC、全字段 OpenAPI、Java 代码 |
| **story-splitting** | Epic / PRD / HLD（+ JSD 场景为 AC 完备性源头） | `docs/requirements/{迭代}/STORY-*.md` | 详设、代码 |
| **detail-design** | Story | `DD-*.md`、OpenAPI、schema、类骨架 | 改 Story 卡、写实现 |
| **test-spec-alignment** | Story + 详设 §9 | `docs/test-spec/{迭代}/TS-*.md`（AC→用例追溯、分层矩阵、Fixture、缺口阻断） | 写 Java 测试/实现、改 Story/详设正文 |
| **integration-test-design** | 已实现业务 Story + 详设（+ 可选 TS） | 各微服务 `src/test/java/` 下单服务 `*IT`/`*ScenarioIT`（继承本服务 `AbstractIntegrationTest`，下游微服务模拟隔离） | 单元/入口 MockMvc 测试（归 feature-coding）、多服务真实联调（归 `api-blackbox-test`）、改业务实现、改 Story/详设正文 |
| **feature-coding** | Story + 详设（+ TS） | `*-api`/`*-impl`/BFF Java、`mvn test` | 无变更记录时偷偷改 AC |

> QA 专线（`qa-acceptance-case-design` → `api-blackbox-test` / `test-data-design`）与旁路（`bugfix` / `legacy-test-migration`）不占主线；触发与产出见清单表。

### 3.1 需求变更

1. **Story**：更新正文 + 「变更记录」
2. **detail-design**：增量详设，合并 OpenAPI / schema
3. **feature-coding**：读变更记录 → 删/改废弃测试 → 红绿重构

接口/字段/错误码变更**必须先详设**，再编码。

---

## 4. 应用代码架构（微服务版）

与 `rules/java-project.md`、`system-landscape.md` §三 / §5.4 一致：

```text
API 网关（可选）→ 路由转发、清理外部伪造请求头、拦截内部路径
    ↓
booking-bff-app / booking-bff-admin（独立启动；对外 Controller，无业务库）
    ↓ 远程契约调用（协议见画像 §5.4 P-2：OpenFeign / Dubbo / gRPC 等）
{domain}-impl（独立启动、独立数据库）
    ├── 内部远程入口（内部 Controller 或 RPC Provider，安全隔离见画像 P-5）
    ├── app/facade → app/service → infrastructure（持久化访问层，ORM 见画像 P-3）
    └── app/client → 下游微服务 *-api（远程契约）或外部系统 Client
```

| 层 | 职责 | 典型位置 |
|----|------|----------|
| API 网关 | 入口路由、外部头清理、禁止转发内部路径 | `booking-gateway/`（可选） |
| BFF | 独立启动；对外 HTTP、鉴权、VO 组装（无业务库） | `booking-bff-*/controller/` |
| `*-api` | 服务远程契约（客户端/接口、DTO、域错误码） | `*-api/` |
| 内部入口 | 暴露供服务间互调的内部 HTTP 或 RPC 入口 | `*-impl/interfaces/` 或 `app/provider/` |
| facade / service | 单服务编排、本地事务与领域规则 | `*-impl/app/facade/`、`app/service/` |
| client | 下游微服务与外部系统防腐层 | `*-impl/app/client/` |
| infrastructure | DO/Entity、持久化访问层、独立 DB 迁移脚本 | `*-impl/infrastructure/`、`resources/db/migration/` |

**硬约束**：

- 对外 HTTP **仅** BFF；领域服务内部入口须按画像 §5.4 P-5 防外泄，严禁直接暴露到公网网关
- 每服务独立启动与独立数据库；**严禁跨服务 SQL JOIN、跨服务外键、跨服务依赖 `*-impl`、把跨服务调用包进本地 `@Transactional`**
- 仓库模式（P-1）、同步调用协议（P-2）、ORM（P-3）、响应与错误码（P-4）、内部鉴权（P-5）、公共库边界（P-6）以及异步/一致性/调度/契约测试/追踪（E-1~E-7）统一由 `architecture/system-landscape.md` §5.4 占位驱动，接入时由 AI 引导补全，未定则阻断

技术栈基线：**Java 21、Spring Boot / Spring Cloud、JUnit 5、Mockito、Testcontainers、Maven**（具体中间件与 ORM 见画像 §5.4）。

---

## 5. 文档工件与路径契约

迭代标识：`{年}-S{两位序号}`（如 `2026-S01`）。

| 工件 | 路径模式（相对项目根 `docs/`；模板内仅存 `_golden` 样例） |
|------|----------|
| Epic | `docs/requirements/epics/EPIC-{slug}.md` |
| 旅程场景（JSD） | `docs/requirements/epics/JSD-EPIC-{slug}.md` |
| 概设（HLD） | `docs/design/epics/HLD-EPIC-{slug}.md` |
| Story | `docs/requirements/{迭代}/STORY-{迭代}-{序号}-{slug}.md` |
| 详设 | `docs/design/{迭代}/DD-STORY-{迭代}-{序号}-{slug}.md` |
| 测试规格（TS） | `docs/test-spec/{迭代}/TS-STORY-{迭代}-{序号}-{slug}.md` |
| OpenAPI | `docs/api/{服务标识}/openapi.yaml` |
| schema | `docs/schema/{服务标识}/schema.md` |

**本仓库 OpenAPI 服务标识**（与模块对应）：

- `booking-bff-app`、`booking-bff-admin`
- `booking-order`、`booking-inventory`、`booking-parking-adapter`（内部服务间契约按画像 §5.4 P-2：HTTP 写内部 `openapi.yaml`，RPC 写 `*-api`/`.proto`）

**URL 前缀**（对外 HTTP，见 system-landscape §六）：

- App：`/api/v1/booking/app/...`
- Admin：`/api/v1/booking/admin/...`

Golden（方法论范本，相对线根 `AI-Native/backend/`；重写后归项目、不随模板覆盖）：

- `docs/requirements/_golden/`
- `docs/design/_golden/`
- `docs/test-spec/_golden/`（TS 范本，由 test-spec-alignment 生成）

---

## 6. 与 Python Demo 方法论的区别

| 维度 | 原 AI Native Demo（Python） | 本仓库（Java） |
|------|------------------------------|----------------|
| 运行时 | FastAPI `app/modules/` | Spring Boot `*-api`/`*-impl` + 双 BFF |
| 分层 Rule | `architecture`（公司级 Rule，未随附） | `rules/java-project.md` |
| 测试 | pytest | JUnit 5 + Mockito + `mvn test` |
| 测试规格 Skill | test-spec-alignment（**已落地**）；integration-test-design（**已落地**）；test-quality-audit 未落地；bugfix **已落地**（旁路） | 编码前生成 TS（`docs/test-spec/`）；单服务 `*IT`（各服务独立）+ 部署后 `api-blackbox-test`（跨服务主链路） |
| 跨服务调用 | 同进程 import | 按画像 §5.4 P-2 选定远程协议（OpenFeign / Dubbo / gRPC 等） |
| 系统画像实例 | `ai-native-org-project` | `源项目后端仓` / 源项目产品 |

---

## 7. 延伸阅读

| 主题 | 文档 |
|------|------|
| 旅程与场景设计 | [skills/journey-scenario-design/](../../skills/journey-scenario-design/)（SKILL、JSD 模板、场景分支清单） |
| AI 入口 | [AGENTS.md](../../../AGENTS.md) |
| 系统画像（实例） | [architecture/system-landscape.md](../../architecture/system-landscape.md) |
| 系统画像（写法） | [system-landscape.md](./system-landscape.md) |
| Story 拆解思想 | [story-splitting.md](./story-splitting.md) |
| 功能编码思想 | [feature-coding.md](./feature-coding.md) |
| 详设思想 | [detail-design.md](./detail-design.md) |
| 测试规格 | [skills/test-spec-alignment/](../../skills/test-spec-alignment/)（SKILL、模板、ac-to-case-guide） |
| 集成测试 | [skills/integration-test-design/](../../skills/integration-test-design/)（SKILL、指南、Mock/种子策略） |
| TDD | `rules/tdd-project-conventions.md` |
| 迁移说明 | 迁移指引（见 [MIGRATION.md](../../MIGRATION.md)） |

---

## 变更记录

| 日期 | 变更 |
|------|------|
| 2026-07-26 | 从 Python Demo 方法论迁移；对齐源项目 Java 单体 + 双 BFF 画像 |
| 2026-08-14 | 流水线加入 test-spec-alignment 节点；§5 补 TS 路径与 Golden；§6 状态改「已落地」 |
| 2026-08-29 | integration-test-design 落地：§3 加 Skill 行、§6 状态改「已落地」、§7 加链接（STORY-2026-S01-005） |
| 2026-10-17 | journey-scenario-design 落地：流水线加最上游节点（原始需求→JSD）；§2 图、§3 表、§5 路径、§7 链接；story-splitting/high-level-design 挂接 JSD 输入（STORY-2026-S02-083） |
