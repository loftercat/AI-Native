---
name: high-level-design
description: >-
  从 Epic/PRD 产出概要设计（HLD）：模块/服务边界、集成矩阵、粗 API、关键 ADR、建议 Story 列表。
  Epic 已明确后、story-splitting 之前使用。不写 Story AC、不写全字段 OpenAPI、不改 Java 业务代码。
---

# 概设（high-level-design）

## 1. 定位

**把 Epic / PRD 转成可评审、可拆 Story 的概要设计（HLD）**，汇总为 `HLD-EPIC-*.md`。

本 Skill 是流水线**上游**；下游 `story-splitting`。  
**本仓库**：**微服务架构**（API 网关 + 独立 BFF + 独立领域微服务，每服务独立启动与独立数据库），服务边界、通信矩阵与两档技术选型以 [system-landscape.md](../../architecture/system-landscape.md)（§二、§3.6、§5.4）为准。

---

## 2. 何时触发

- 新 Epic / 能力域立项，拆 Story 之前
- 跨模块改造（`{project}-{domain-a}` ↔ `{project}-{domain-b}` ↔ `{project}-adapter` ↔ 双 BFF）
- 用户要求产出/更新 `docs/design/epics/`

**不触发**：拆 Story、单 Story 详设、写 Java 实现。

---

## 3. Skill 与 Rule 分工

| 谁 | 管什么 |
|----|--------|
| **本 Skill** | 十步流程、Epic→HLD、粗契约、建议 Story 列表 |
| **rules/card-naming-conventions.md** | Epic / HLD 命名与路径 |
| **system-landscape.md** | 模块清单、集成、URL（只读，概设不修改） |

---

## 4. 前置加载（按序）

| # | 资产 | 路径 | 缺失时 |
|---|------|------|--------|
| 1 | Epic/PRD | `docs/requirements/epics/EPIC-*.md` | **阻断**。Epic 来源：PRD 提炼，或 JSD 先行时由 journey-scenario-design 起草；旅程仅轻量文字时建议先跑 JSD 展开 |
| 1b | JSD（建议） | `docs/requirements/epics/JSD-EPIC-*.md`（旅程+场景） | 降级；有则 HLD §5 关键流程与 §10 建议 Story **引用其旅程编号 J*／场景编号**，勿重复展开 |
| 2 | HLD 模板 | `templates/hld-template.md` | **阻断** |
| 3 | 边界指引 | `references/hld-dd-boundary-guide.md` | **阻断** |
| 4 | 系统画像 | `architecture/system-landscape.md` | **阻断**（未填 / 仍是模板示例）。模块边界直接读画像 §二，画像未接入时 HLD 会凭空发明模块 |
| 5 | 领域词表 | `glossary/domain-glossary.md` | 降级 |
| 6 | Golden HLD | `docs/design/_golden/HLD-EPIC-*.md` | 降级 |
| 7 | 存量 HLD | `docs/design/epics/` | 增量；同名不覆盖 |
| 8 | AGENTS.md | 做什么 / 不做什么 | 必须读 |

---

## 5. 本仓库微服务语境（写 HLD 时必对齐）

> 下表为标准微服务拓扑抽象模板，实际服务清单与职责以 [system-landscape.md](../../architecture/system-landscape.md) §二 为准。

| 服务 / 外部系统 | 概设中如何描述 |
|------|----------------|
| `{project}-gateway`（可选） | 统一入口路由、剥离外部伪造请求头、拦截内部路径 |
| `{project}-bff-app` | C 端独立 BFF；`/api/v1/{project}/app/...`（无业务库） |
| `{project}-bff-admin` | B 端独立 BFF；`/api/v1/{project}/admin/...`；Token 来自 `{外部认证服务}` |
| `{project}-{domain-a}` | 核心领域微服务 A：承载 `{Entity}` 生命周期、`{StateA}`→`{StateB}` 状态机与编排（独占业务库） |
| `{project}-{domain-b}` | 核心领域微服务 B：承载 `{Resource}` 可用性、占用/释放等核心能力（独占业务库） |
| `{project}-adapter` | 南向适配微服务：对接 `{南向第三方系统}`，隔离外部协议差异 |
| 外部：`{外部系统A}` | 领域服务编排调用，本仓库不实现其内部逻辑 |
| 外部：`{外部认证服务}` | 仅 `{project}-bff-admin` / 网关校验 |
| 外部：独立前端仓（C 端 / B 端） | 另仓维护，不在本仓库 |

**微服务架构约束（读画像 §5.4）**：
- **数据归属唯一**：每张表只能归属一个微服务写入，禁止跨服务连表 JOIN、跨服务外键与跨域本地 `@Transactional`。
- **服务间同步调用**：按画像 §5.4 **P-2** 选定的远程协议（如 OpenFeign / Dubbo / gRPC）描述集成矩阵，不假设进程内直调。
- **未定选型阻断**：当本 Epic 涉及**服务注册发现（E-1）**、**异步消息队列（E-2）**或**单操作跨 ≥2 个微服务写库（E-3 跨服务一致性）**，而画像 §5.4 对应项仍为 `[TBD]` 时，**严禁 AI 自行猜测选型**——必须在步骤 4 缺口评估中**阻断**并请用户拍板回写画像后再定稿 HLD。
- **回写画像**：HLD 定稿后，新增或调整的服务边界与跨服务通信矩阵须同步回写画像 §二 / §3.6（参见 [rules/system-landscape-change.md](../../rules/system-landscape-change.md)）。

---

## 6. 核心思想

### 6.1 Epic 是设计输入

从 Epic 拆：业务能力、核心实体、用户旅程、非目标、NFR。**禁止**以 Sprint Story 集合代替 Epic（BR-01）。已加载 JSD（前置 #1b）时：旅程/场景直接引用 JSD 编号，**勿重复展开**；JSD 未覆盖的关键流程才补画。

### 6.2 概设产出

| 产出 | 路径 |
|------|------|
| HLD | `docs/design/epics/HLD-EPIC-{slug}.md` |
| 集成矩阵 | HLD §4 |
| 粗 API/事件 | HLD §7（资源 + 操作，无全字段 schema） |
| 建议 Story | HLD §10 |
| ADR | HLD §9 |

### 6.3 粗契约原则

- **概设**：对外 BFF 粗路径（如 `POST /api/v1/{project}/app/{resources}`）+ 内部服务间同步/异步调用方向与一致性模式
- **详设**：对外/对内完整接口契约（按画像 §5.4 P-2 / E-4）、全字段、错误码、幂等键与代码骨架

### 6.4 建议 Story 列表

只写序号 + 标题 + 一句话意图 + **主责微服务与协同服务**（`{project}-bff-app` / `{project}-{domain-a}` / `{project}-{domain-b}` 等）；**不写 AC 正文**。

---

## 7. 标准流程（十一步）

1. 加载资产  
2. 解析 Epic  
3. 对齐 system-landscape 模块与外部系统  
4. 缺口评估（阻断 / `[AI推断]` / 提醒）  
5. 系统/模块边界 + 数据写归属  
6. 集成矩阵 + 粗 API  
7. 1～3 条主旅程 Mermaid  
8. 数据主权 + NFR + ADR  
9. 建议 Story 列表 + 落盘  
10. **送审**：按 [rules/artifact-review.md](../../rules/artifact-review.md) §二 的 HLD 三项必查派独立审查人，报告落 `docs/reviews/{迭代}/REVIEW-HLD-{slug}.md`；通过后状态改「已确认」  
11. 产出汇总 → 提示 `story-splitting`

---

## 8. 边界：本 Skill 不做

- Story AC/BR（`story-splitting`）
- 全字段 OpenAPI / Java 代码（`detail-design` / `feature-coding`）
- 修改 system-landscape、Story、Rule

---

## 9. 上下游

```text
原始需求 ──► journey-scenario-design ──► Epic ──► high-level-design ──► story-splitting ──► detail-design ──► feature-coding
              JSD（旅程+场景）                        HLD + 建议 Story      Story+AC/BR          六类契约          mvn test
```

---

## 10. 延伸阅读

- [hld-template.md](templates/hld-template.md)
- [hld-dd-boundary-guide.md](references/hld-dd-boundary-guide.md)
- [docs/methodology/readme.md](../../docs/methodology/readme.md)
