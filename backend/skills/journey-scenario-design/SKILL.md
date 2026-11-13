---
name: journey-scenario-design
description: >-
  从业务原始需求（PRD 草稿/口头需求/原型）产出用户旅程与业务场景文档（JSD）：Persona、旅程图、场景矩阵（主/备选/异常）。
  流水线最上游，high-level-design 与 story-splitting 之前使用。不做模块边界设计、不拆 Story、不写 AC 正文、不写代码。
---

> **模板版说明**：本 Skill 自已落地的源项目抽取为通用模板。文中项目专属值（模块名 `booking-*`、包名 `com.hema`、错误码号段、具体路径与 Story 号）均为**示例**，接入项目时按 [MIGRATION.md](../../../MIGRATION.md) 清单替换；「本仓库」指接入后的目标项目。


# 旅程与场景设计（journey-scenario-design）

## 1. 定位

**把业务原始需求转成结构化的「用户旅程 + 业务场景清单」（JSD）**，落盘为 `docs/requirements/epics/JSD-EPIC-{slug}.md`。

本 Skill 是流水线**最上游**；下游 `high-level-design`（HLD 引用 JSD 旅程）、`story-splitting`（AC 源于 JSD 场景）。

两阶段分工：

| 阶段 | 管什么 | 产物 |
|------|--------|------|
| **一：用户旅程** | **广度**——角色路径上不缺环 | Persona 表 + Journey Map（阶段编号 J*.*） |
| **二：业务场景** | **深度**——每环节不缺分支 | 场景矩阵（编号 SC-J*-*，类型主/备选/异常） |

**语境对齐**：角色须区分端；「系统响应」列须对齐 [system-landscape.md](../../architecture/system-landscape.md) 的模块与外部系统——**引用画像为权威，不在本 Skill 复述系统清单**（防口径漂移；画像未接入则阻断，见前置加载 #4）。

---

## 2. 何时触发

- 新需求立项且输入还是**原始形态**（口头需求、PRD 草稿、原型链接），尚未成 Epic 卡
- 已有 Epic 但旅程只有轻量文字描述（`epic-input-template.md` §4），需系统化展开
- 用户要求产出/更新 `docs/requirements/epics/JSD-*.md`

**不触发**：模块/边界设计（`high-level-design`）、拆 Story 与 AC 正文（`story-splitting`）、详设与代码。

---

## 3. Skill 与 Rule 分工

| 谁 | 管什么 |
|----|--------|
| **本 Skill** | 两阶段流程、原始需求→JSD、场景分支扫描 |
| **rules/card-naming-conventions.md** | JSD 命名与路径 |
| **system-landscape.md** | 角色/端、模块、外部集成语境（只读） |
| **rules/story-ac-conventions.md** | 下游消费时的 AC 格式（本 Skill 只产场景，不产 AC） |

---

## 4. 前置加载（按序）

| # | 资产 | 路径 | 缺失时 |
|---|------|------|--------|
| 1 | 原始需求 | 用户消息 / PRD 链接 / 原型路径 | **阻断**（无输入无产出） |
| 2 | JSD 模板 | `templates/jsd-template.md` | **阻断** |
| 3 | 分支清单 | `references/scenario-branch-checklist.md` | **阻断** |
| 3b | 概念与划分标准 | `references/concepts-guide.md` | 降级；旅程/场景**分几条、数量拿不准时先读** |
| 4 | 系统画像 | `architecture/system-landscape.md` | **阻断**（未填 / 仍是模板示例）。画像未接入就产 JSD，系统响应列会写成产品文案，下游模块归属全部错位 |
| 5 | 领域词表 | `glossary/domain-glossary.md` | 降级 |
| 6 | 存量 Epic/JSD | `docs/requirements/epics/` | 增量；同名不覆盖 |
| 7 | 原型（若有） | Axure 导出 HTML | 降级；有则逐页走旅程 |
| 8 | AGENTS.md | 做什么 / 不做什么 | 必须读 |

---

## 5. 核心思想

### 5.1 旅程先于场景，场景先于 Story

- 旅程漏了环节，场景再多也白搭（广度优先）；
- 场景只写主路径，旅程画得再漂亮也是空中楼阁（深度兜底）；
- 下游 AC 的完备性**源头在本 Skill**：`story-splitting` 的 AC 完备性检查以场景清单为追溯起点。

### 5.2 场景可判定化

每条场景 = 前置条件 + 触发 + **用户可见的**预期结果；异常场景预期结果须含具体失败表现（文案/状态/去向），写不出则进 §6 开放问题，**禁止静默跳过**。

### 5.3 缺口三分法（同 story-splitting）

| 类型 | 处理 |
|------|------|
| **阻断** | 角色不明、业务成败语义不明、与 system-landscape 冲突、**画像未接入** |
| **可补充** | `[AI推断]`（次要默认行为，不改变用户可见成败） |
| **提醒** | 缺原型但涉及表单；并发/外部失败写备注列 |

### 5.4 范围守卫

- 前端 UI 细节（另仓）：旅程「触点」列可写，系统响应列标「前端另仓」；
- **外部系统的内部实现**（本仓库示例：支付渠道实现、iam 账号管理）：系统响应列标「外部系统」，本仓库只描述交互边界。

### 5.5 数量与粒度标准（概念与判定）

两个概念的官方定义、以及「分几条旅程、几个阶段、几个场景」的判定标准，见 [concepts-guide.md](references/concepts-guide.md)。速查：

- **旅程**：1 角色 × 1 目标 = 1 条（主旅程 1 + 次要 ≤3；每条 4～8 个阶段）；
- **场景**：每阶段主场景 ≥1（通常 1 条）；异常场景每个对外能力 ≥1；每阶段合计 3～10；每条 3～5 步；
- **数量越界是粒度信号**：阶段 >10 优先怀疑该并阶段或拆旅程；场景 >10 优先怀疑阶段太粗——先调划分，不硬写下去。

---

## 6. 标准流程（八步）

1. 加载资产（模板、分支清单、画像、词表、原型）
2. **解析原始需求**：识别角色/端、业务意图、显式与隐含的成败语义；slug 命名 → `JSD-EPIC-{slug}.md`；**缺口三分法**在此生效（阻断项问用户，产出前不得继续）
3. **阶段一·用户旅程**：Persona 表 → 主旅程 Journey Map（阶段编号 J1.1…）；有原型则逐页归入阶段；识别断点/机会点（→ JSD §4）
4. **阶段二·业务场景**：逐阶段展开场景矩阵；主场景每阶段 ≥1；按 [scenario-branch-checklist.md](references/scenario-branch-checklist.md) 逐维度扫描补异常/备选场景（C 端/B 端按清单「使用约定」取必扫维度集）；业务存在角色/对象/情境变化维度时，按模板 §3.0 做**因子组合**派生场景（差异驱动，防组合爆炸；C 端简单旅程可省略）
5. **场景覆盖度自检**（模板 §3.2）：每个对外能力 ≥1 异常场景；清单逐维度过一遍；因子表非空时核对取值覆盖；**缺口未补齐 → 汇总列出，不静默落盘**
6. 非目标 + 开放问题 + `[AI推断]` 汇总
7. 落盘 `docs/requirements/epics/JSD-EPIC-{slug}.md`（**同名不覆盖**；更新走 §7 变更记录并列明受影响场景编号）
8. 产出汇总（角色数、旅程数、场景数及分型、覆盖度缺口、开放问题）→ **送审**：按 [rules/artifact-review.md](../../rules/artifact-review.md) §二 的 JSD 三项必查派独立审查人，报告落 `docs/reviews/{迭代}/REVIEW-JSD-{slug}.md`，通过后状态改「已确认」→ **提示下游**：
   - 若 Epic 卡未建：建议以 JSD 为输入建卡（Epic 卡 §4 旅程引用 JSD，勿重复）
   - 下一步运行 `high-level-design`（HLD §5 关键流程引用 JSD 旅程编号）

---

## 7. 边界：本 Skill 不做

- 模块/服务边界、集成矩阵、粗 API（`high-level-design`）
- Story 拆分与 AC/BR 正文（`story-splitting`；场景≠AC，格式转换归下游）
- 全字段 OpenAPI / Java 代码（`detail-design` / `feature-coding`）
- 修改 system-landscape、Epic 正文、Rule

---

## 8. 上下游

```text
原始需求 ──► journey-scenario-design ──► high-level-design ──► story-splitting ──► detail-design ──► feature-coding
              JSD：旅程+场景            HLD（§5 引用旅程）      Story（AC 源于场景）
```

JSD 更新（需求变更）：改 JSD + §7 变更记录 → 提示 `high-level-design` / `story-splitting` 消费方同步。

---

## 9. 延伸阅读

- [jsd-template.md](templates/jsd-template.md)
- [concepts-guide.md](references/concepts-guide.md)（概念定义与划分标准·知识普及）
- [scenario-branch-checklist.md](references/scenario-branch-checklist.md)
- [docs/methodology/readme.md](../../docs/methodology/readme.md)

---

## 10. 迁移指引（跨项目复用）

本 Skill 分两层：**通用层**（八步流程、§5 判定标准、`J*.*`/`SC-J*-*` 编号规则、模板结构）跨项目不变；**项目层**为下表锚点，迁移时逐项替换——未替换而直接运行，产出仍成立但语境会错位。

| # | 锚点 | 本仓库取值 | 迁移动作 |
|---|------|-----------|----------|
| 1 | 系统画像 | `architecture/system-landscape.md` | 换成目标项目画像（角色/端/模块/外部系统的权威） |
| 2 | 领域词表 | `glossary/domain-glossary.md` | 换/建；无则降级（前置 #5 本就降级） |
| 3 | JSD 落盘路径与命名 | `docs/requirements/epics/JSD-EPIC-{slug}.md`（`rules/card-naming-conventions.md`） | 按目标项目文档约定调整路径/命名模式 |
| 4 | Epic 输入模板 | `epic-input-template.md` §4 | 目标项目无此约定 → 删除 §2 触发条件第 2 条的措辞 |
| 5 | 仓库入口文档 | `AGENTS.md`（前置 #8） | 换成目标项目的 AI 入口等价物；无则降级 |
| 6 | 分支清单项目层 | checklist 括注「本仓库示例」与 §4「本仓库实例」列 | 按目标项目画像替换；无对应依赖则删行（清单使用约定 #6） |
| 7 | 流水线邻居 | `high-level-design` / `story-splitting` 等 Skill 名 | 目标项目无此流水线 → §1/§7/§8 的上下游引用改为对应环节或删除 |

判定不变式：**凡「追问怎么问、分几条、何时阻断」都是通用层；凡出现具体文件名、系统名、路径的引用都是项目层。**
