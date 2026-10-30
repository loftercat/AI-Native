---
name: high-level-design
description: >-
  从 Epic/PRD 产出概要设计（HLD）：模块/服务边界、集成矩阵、粗 API、关键 ADR、建议 Story 列表。
  Epic 已明确后、story-splitting 之前使用。不写 Story AC、不写全字段 OpenAPI、不改 Java 业务代码。
---

> **模板版说明**：本 Skill 自已落地的源项目抽取为通用模板。文中项目专属值（模块名 `booking-*`、包名 `com.hema`、错误码号段、具体路径与 Story 号）均为**示例**，接入项目时按 [MIGRATION.md](../../../MIGRATION.md) 清单替换；「本仓库」指接入后的目标项目。


# 概设（high-level-design）

## 1. 定位

**把 Epic / PRD 转成可评审、可拆 Story 的概要设计（HLD）**，汇总为 `HLD-EPIC-*.md`。

本 Skill 是流水线**上游**；下游 `story-splitting`。  
**本仓库**：Java **V1 单体**（`booking-app` 单 jar + 双 BFF + `*-api`/`*-impl`），边界以 [system-landscape.md](../../architecture/system-landscape.md) 为准。

---

## 2. 何时触发

- 新 Epic / 能力域立项，拆 Story 之前
- 跨模块改造（order ↔ inventory ↔ adapter ↔ 双 BFF）
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
| 1 | Epic/PRD | `docs/requirements/epics/EPIC-*.md` | **阻断** |
| 1b | JSD（建议） | `docs/requirements/epics/JSD-EPIC-*.md`（旅程+场景） | 降级；有则 HLD §5 关键流程与 §10 建议 Story **引用其旅程编号 J*／场景编号**，勿重复展开 |
| 2 | HLD 模板 | `templates/hld-template.md` | **阻断** |
| 3 | 边界指引 | `references/hld-dd-boundary-guide.md` | **阻断** |
| 4 | 系统画像 | `architecture/system-landscape.md` | 提问 + `[AI推断]` |
| 5 | 领域词表 | `glossary/domain-glossary.md` | 降级 |
| 6 | Golden HLD | `docs/design/_golden/HLD-EPIC-*.md` | 降级 |
| 7 | 存量 HLD | `docs/design/epics/` | 增量；同名不覆盖 |
| 8 | AGENTS.md | 做什么 / 不做什么 | 必须读 |

---

## 5. 本仓库模块语境（写 HLD 时必对齐）

| 模块 | 概设中如何描述 |
|------|----------------|
| `booking-bff-app` | C 端 HTTP；`/api/v1/booking/app/` |
| `booking-bff-admin` | B 端 HTTP；`/api/v1/booking/admin/`；Token 来自 iam-server |
| `booking-order` | 预约单、支付编排、取消/退款状态机 |
| `booking-inventory` | 车位可售、锁定、占用 |
| `booking-parking-adapter` | 南向：新伯乐、德立云等 |
| 外部：支付系统 | order 编排，不实现渠道 |
| 外部：iam-server | 仅 admin BFF 校验 |
| 外部：B 端运营后台前端 | 另仓，不在本仓库 |

**V1 约束**：单体单 jar；域间 sync 调用，不用 MQ 做核心事务（Spring Event 仅进程内）；**不写** Nacos/OpenFeign 为当前方案。

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

- **概设**：`POST /api/v1/booking/app/reservations` 级 + 集成方向
- **详设**：OpenAPI 全字段、错误码、幂等键、Java 骨架

### 6.4 建议 Story 列表

只写序号 + 标题 + 一句话意图 + **建议模块**（bff-app / order / inventory 等）；**不写 AC 正文**。

---

## 7. 标准流程（十步）

1. 加载资产  
2. 解析 Epic  
3. 对齐 system-landscape 模块与外部系统  
4. 缺口评估（阻断 / `[AI推断]` / 提醒）  
5. 系统/模块边界 + 数据写归属  
6. 集成矩阵 + 粗 API  
7. 1～3 条主旅程 Mermaid  
8. 数据主权 + NFR + ADR  
9. 建议 Story 列表 + 落盘  
10. 产出汇总 → 提示 `story-splitting`

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
