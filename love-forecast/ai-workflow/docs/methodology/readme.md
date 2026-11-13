# AI Native 架构说明

> 本文描述**本仓库**（已落地源项目）的 AI Native 工程方法论：Skill 流水线、文档资产、Java 代码分层。  
> 产品域系统画像见 [`docs/architecture/system-landscape.md`](../../architecture/system-landscape.md)。

---

## 1. 定位：两条主线

| 主线 | 目的 | 主要目录 |
|------|------|----------|
| **方法论流水线** | 用 Agent Skill + Rule + 文档契约，把「需求 → 设计 → 代码 → 测试」做成可重复、可审计的流程 | `skills/`（模板平铺，无镜像）、`docs/*/_golden/`、`docs/agile/` |
| **可运行后端** | Java 单体（V1）实现预订编排：双 BFF + 域模块 + 南向适配器 | `booking-*/`（规划）、`docs/api/`、`docs/schema/` |

**本仓库不是 Python/FastAPI Demo**；Skill 与 Rule 已按 **Java 21 + Spring Boot 3.2 + Maven 多模块** 特化。方法论精华可迁移到其他 Java 业务仓库；`docs/architecture/system-landscape.md` 为**本项目独有**，勿被其它产品线覆盖。

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
    Epic/PRD ──► high-level-design ──► HLD（边界/集成/建议 Story）
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
| 领域词表 | `docs/glossary/domain-glossary.md` | Story / 详设术语一致 |
| 系统画像 | `docs/architecture/system-landscape.md` | 模块边界、集成、URL、技术栈（**权威**） |

---

## 3. Skill 职责与边界

| Skill | 输入 | 产出 | 不做 |
|-------|------|------|------|
| **journey-scenario-design** | 业务原始需求（PRD 草稿/口头/原型） | `docs/requirements/epics/JSD-EPIC-*.md`（Persona、旅程图、场景矩阵） | HLD/Story/AC/代码 |
| **high-level-design** | Epic / PRD + 系统画像（+ JSD 建议必读） | `docs/design/epics/HLD-EPIC-*.md`、建议 Story 列表 | Story AC、全字段 OpenAPI、Java 代码 |
| **story-splitting** | Epic / PRD / HLD（+ JSD 场景为 AC 完备性源头） | `docs/requirements/{迭代}/STORY-*.md` | 详设、代码 |
| **detail-design** | Story | `DD-*.md`、OpenAPI、schema、类骨架 | 改 Story 卡、写实现 |
| **test-spec-alignment** | Story + 详设 §9 | `docs/test-spec/{迭代}/TS-*.md`（AC→用例追溯、分层矩阵、Fixture、缺口阻断） | 写 Java 测试/实现、改 Story/详设正文 |
| **integration-test-design** | 已实现业务 Story + 详设（+ 可选 TS） | `booking-app/src/test/java/` 下 `*IT`/`*ScenarioIT`（继承 `AbstractIntegrationTest`） | 单元/BFF API 测试（归 feature-coding）、改业务实现、改 Story/详设正文 |
| **feature-coding** | Story + 详设（+ TS） | `*-api`/`*-impl`/BFF Java、`mvn test` | 无变更记录时偷偷改 AC |

### 3.1 需求变更

1. **Story**：更新正文 + 「变更记录」
2. **detail-design**：增量详设，合并 OpenAPI / schema
3. **feature-coding**：读变更记录 → 删/改废弃测试 → 红绿重构

接口/字段/错误码变更**必须先详设**，再编码。

---

## 4. 应用代码架构（本仓库 V1）

与 `rules/java-project.md`、`system-landscape.md` §三 一致：

```text
booking-bff-app / booking-bff-admin（Controller，无 main）
    ↓ @Autowired XxxApi
{domain}-impl / app/provider（XxxApiImpl）
    ↓
app/facade → app/service → infrastructure（Mapper / Repository）
    ↓
app/client → 其它域 *-api 或 外部 PaymentClient / ParkingLotGateway

booking-app（@SpringBootApplication）聚合全部 impl + 双 BFF
```

| 层 | 职责 | 典型包 |
|----|------|--------|
| BFF | 对外 HTTP、鉴权、`Result` 包装 | `booking-bff-*/controller/` |
| api | 域契约：`XxxApi` + DTO | `*-api/` |
| provider | 实现 `XxxApi`，域边界入口 | `*-impl/.../app/provider/` |
| facade | 用例编排、事务、跨域 | `*-impl/.../app/facade/` |
| service | 域内业务 | `*-impl/.../app/service/` |
| client | 跨域/外部防腐层 | `*-impl/.../app/client/` |
| infrastructure | DO、Mapper、Repository | `*-impl/.../infrastructure/` |

**硬约束**：

- 对外 HTTP **仅** BFF；`*-impl` **无** Controller
- Service 不跨域直调 Mapper 以外的域；跨域走 `app/client` → `XxxApi`
- SQL：ORM 为 MyBatis；主键查询允许 MyBatis Plus，其余仅 MyBatis XML（见 `rules/mybatis-conventions.md`）
- V1 不用 OpenFeign / Nacos

技术栈：**Java 21、Spring Boot 3.2.x、MyBatis、Redis（分布式缓存/锁/序列）、Spring Event、JUnit 5、Maven**。

---

## 5. 文档工件与路径契约

迭代标识：`{年}-S{两位序号}`（如 `2026-S01`）。

| 工件 | 路径模式 |
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
- `booking-order`、`booking-inventory`、`booking-parking-adapter`（若 Story 仅域内、无 HTTP 可省略 OpenAPI）

**URL 前缀**（对外 HTTP，见 system-landscape §六）：

- App：`/api/v1/booking/app/...`
- Admin：`/api/v1/booking/admin/...`

Golden（方法论范本）：

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
| 测试规格 Skill | test-spec-alignment（**已落地**）；integration-test-design（**已落地**）；test-quality-audit / bug-fix 未落地 | 编码前生成 TS（`docs/test-spec/`）；关键链路 `*IT`（`booking-app`） |
| 跨域调用 | 同进程 import | V1 `@Autowired XxxApi`；V2+ OpenFeign |
| 系统画像实例 | `ai-native-org-project` | `源项目后端仓` / 源项目产品 |

---

## 7. 延伸阅读

| 主题 | 文档 |
|------|------|
| 旅程与场景设计 | [skills/journey-scenario-design/](../../skills/journey-scenario-design/)（SKILL、JSD 模板、场景分支清单） |
| AI 入口 | [AGENTS.md](../../../AGENTS.md) |
| 系统画像（实例） | [docs/architecture/system-landscape.md](../../architecture/system-landscape.md) |
| 系统画像（写法） | [system-landscape.md](./system-landscape.md) |
| Story 拆解思想 | [story-splitting.md](./story-splitting.md) |
| 功能编码思想 | [feature-coding.md](./feature-coding.md) |
| 详设思想 | [detail-design.md](./detail-design.md) |
| 测试规格 | [skills/test-spec-alignment/](../../skills/test-spec-alignment/)（SKILL、模板、ac-to-case-guide） |
| 集成测试 | [skills/integration-test-design/](../../skills/integration-test-design/)（SKILL、指南、Mock/种子策略） |
| TDD | `rules/tdd-project-conventions.md` |
| 迁移说明 | 迁移指引（见模板根 MIGRATION.md） |

---

## 变更记录

| 日期 | 变更 |
|------|------|
| 2026-07-26 | 从 Python Demo 方法论迁移；对齐源项目 Java 单体 + 双 BFF 画像 |
| 2026-08-14 | 流水线加入 test-spec-alignment 节点；§5 补 TS 路径与 Golden；§6 状态改「已落地」 |
| 2026-08-29 | integration-test-design 落地：§3 加 Skill 行、§6 状态改「已落地」、§7 加链接（STORY-2026-S01-005） |
| 2026-10-17 | journey-scenario-design 落地：流水线加最上游节点（原始需求→JSD）；§2 图、§3 表、§5 路径、§7 链接；story-splitting/high-level-design 挂接 JSD 输入（STORY-2026-S02-083） |
