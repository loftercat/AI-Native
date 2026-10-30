# 需求拆解 Skill（story-splitting）核心思想

> **可执行正文**：`skills/story-splitting/SKILL.md`  
> **粒度细则**：`skills/story-splitting/references/granularity-guide.md`  
> **格式规范**：`rules/story-ac-conventions.md`（Skill 管流程，Rule 管格式）  
> **范本**：`docs/requirements/_golden/`

---

## 1. 一句话定位

**把 Epic / 粗需求拆成可独立验收的用户故事（Story），用 AC（Given-When-Then）和 BR 写成需求契约，落盘到迭代目录——只做需求语义，不做详设、接口和代码。**

它是 AI Native 流水线的**源头**：下游详设、测试规格、TDD 编码都以 Story 为输入。

---

## 2. 核心思想（五条）

### 2.1 Story 管「验什么」，Task 管「怎么做」

```text
Epic → Story（本 Skill）→ 详设 → Task / 编码（feature-coding）
```

- **Story**：PO 可评审的业务能力切片；一张卡应能回答「用户得到什么价值、怎样算验收通过」。
- **Task**：接口、页面、测试实现等技术单元，在详设之后由 AI 批量完成。

**AI 提速的是实现层，不是 Story 层。** 不因「AI 写代码快」把整模块 CRUD 揉成一张 Epic 级大卡；也不按「一个 HTTP 接口一张 Story」过细拆分。

### 2.2 一张 Story 的粒度公式

```text
一张 Story = 一个角色（或同质角色组）× 一个完整业务意图 × 一个风险域
```

- **角色**：权限模型、可操作范围不同 → 优先拆。
- **业务意图**：能用一句「作为…我想…以便…」说清。
- **风险域**：资金、权限、合规、状态机、第三方依赖等是否同质。

**拆分优先级**（多维度冲突时）：**风险/权限 → 角色/场景 → 流程步骤 → CRUD**（仅简单管理类）。  
**交付/编号优先级**（另见 Skill §5.6）：**Foundation（骨架/鉴权/主数据）→ 管道准备 → 管道提交 → 扩展旅程**；Story 序号 = 阻塞依赖拓扑序，**禁止**按原型页码或 HLD `S-xx` 单独编号。

**禁止**作为拆分维度：HTTP 方法、DAO/Service 层、把正常流与异常流拆成两张 Story（异常写进 AC）、PRD 步骤号 1:1 映射成 Story。

### 2.3 管道型 Epic：少卡、整旅程

同一角色、同一意图、一次确认后的「保存 → 打包 → 调外部 → 展示结果」属于**一条用户旅程**，默认 **2 张 Story**：

| 卡 | 内容 |
|----|------|
| 准备 | 入口、权限、表单、前置校验 |
| 提交（含结果） | 确认后的连续动作 + **同次流程内的结果展示/状态查询** |

**禁止**把 submit 与 show-result、换 token、调接口拆成多张独立 Story（除非结果是独立入口的「发布历史」等第三旅程）。

与「账号模块按风险域拆（注册 / 改密 / 查询）」不矛盾：管道型看**旅程**，账号型看**风险域**。

### 2.4 AC / BR 分工：可测契约，不写实现

| 概念 | 职责 |
|------|------|
| **BR** | 可复用、可编号的业务规则（金额、权限、状态、时间、风控等） |
| **AC** | 可执行的验收清单；引用 BR，用 GWT 写清 Given / When / Then |
| **测试关注点** | QA 风险提醒，不必每条对应 AC；简单 Story 可省略 |

**AC 必须可判定通过/不通过**：失败类须写具体用户可见文案（`页面提示「…」`），禁止「提示格式错误」等泛化句。

**BR→AC 映射**：含失败语义的 BR 须有对应失败 AC；§2.3 校验职责须在 AC/BR 可验收。落盘前按 `ac-completeness-checklist.md` 补异常/边界 AC。**产品 BR**（用户可见规则）与 **实现 BR**（算法/格式，须 `[AI推断]` + §8）须区分，见 `rules/story-ac-conventions.md`。

**BR 跨 Story**：在依赖链最上游 Story 定义；其他 Story 用 `STORY-xxx.BRn` 引用，不重复正文。

复杂度裁剪字段集：**简单**（故事+范围+AC）→ **中等**（+BR+依赖+校验职责）→ **高复杂**（+业务价值、20 维清单、DoD、测试关注点等）。**先看风险再看功能大小**——涉及资金/权限/合规一律按高风险处理。

### 2.5 缺口三分法：错会伤下游就必须问

| 类型 | 原则 | 示例 |
|------|------|------|
| **阻断** | AI 猜错会导致测试/开发实质性错误 | 金额、权限、合规、状态机、PRD 未写的新增交互、多来源冲突 |
| **可补充** | 标注 `[AI推断]` 后继续 | 排序规则、次要字段默认值、无原型时的展示格式 |
| **提醒** | 不阻断，提示后继续 | 缺 UI 原型但涉及表单/列表；**原型标注未映射**；并发/性能写 §6 测试关注点 |

### 2.6 原型对齐检查（有 HTML 时）

对主原型页逐条标注，标为：**本 Story AC** / **后续 Story** / **前端另仓** / **显式非目标**（详见 Skill §5.4）。

- **展示类字段**（含收费说明）须有 AC 或写明后续 Story，不可因「准备卡只做查询」而静默省略  
- **纯 UI**（地图、样式）标前端另仓  
- Story「来源」须写 **原型主 HTML 路径**

**需求变更**时也可由本 Skill（模式 B 修订）或人工改 Story 并追加「变更记录」——仍属同一流水线源头，不另建「变更 Skill」。

---

## 3. 标准流程（摘要）

```text
1. 加载模板、粒度指引、AC 完备性清单、迭代索引模板、Golden、词表、current-sprint
2. 理解输入；识别管道型 Epic；批量原型时列旅程地图
3. 缺口评估
3.5 依赖拓扑：Foundation → 阻塞 DAG → 波次 → 拓扑序赋序号草案
4. 按波次拆 Story + INVEST + 粒度自检 + 概览确认（AskQuestion，按 Wave 排序）
4.5 拓扑校验：阻塞依赖上游序号更小、无环
5. 原型对齐检查（有 HTML：四类落点）
6. AC 完备性检查
7. 生成完整需求卡（含实现波次、阻塞依赖/消费方）
8. 落盘 STORY-*.md
8.5 落盘 README-{迭代}-迭代交付计划.md（Epic 级拆卡阻断）
9. 产出汇总（含拓扑校验、AC 缺口、推断项、原型未映射项）
```

**人机协作点**：步骤 4 拆解概览须用户确认，且**按实现波次展示**；落盘前 PO 评审卡点；Skill **不**做工时估算、不 sync 外部系统。

---

## 4. Skill 与 Rule 的分工

| 谁 | 管什么 |
|----|--------|
| **story-splitting Skill** | 步骤顺序、何时提问、何时合并/再拆、交互方式、落盘流程 |
| **story-ac-conventions Rule** | AC/BR 结构、`[AI推断]` 格式、命名与目录、数据要求与校验职责 |

冲突时：**规范听 Rule，流程听 Skill**。

---

## 5. 依赖资产（重建 Skill 时最少要带）

| 资产 | 路径 | 缺失时 |
|------|------|--------|
| 输出模板 | `skills/story-splitting/templates/story-template.md` | **阻断** |
| 粒度指引 | `skills/story-splitting/references/granularity-guide.md` | **阻断** |
| AC 完备性清单 | `skills/story-splitting/references/ac-completeness-checklist.md` | **阻断** |
| 迭代索引模板 | `skills/story-splitting/templates/sprint-index-template.md` | Epic 级拆卡 **阻断** |
| Golden Story | `docs/requirements/_golden/STORY-GOLDEN-001-query-allocate-space.md` | 降级继续 |
| 领域词表 | `docs/glossary/domain-glossary.md` | 降级继续 |
| 迭代 |`config/current-sprint`（模板约定路径） | 询问用户 |

Golden **只对齐写法与粒度**，不得把样例里的业务阈值（如 BR-02 步行距离）当成未经 PO 确认的真实约束。

---

## 6. 粒度快查表

| 信号 | 动作 |
|------|------|
| 不同权限/风险域、独立状态机、AC>10 且场景异质、一句用户故事说不清 | **继续拆** |
| 严格串行且无法单独演示价值、保存/打包/调接口管道步骤、像 Task（AC≤2 仅技术动作）、单旅程却 ≥4 张 | **必须合并** |
| 同角色同流程、共享 BR、无独立高风险、合并后 AC≤6 可一次验收 | **可以合并**（须全部满足） |

INVEST 的 **Small**：一个迭代内可**独立验收**的业务切片，不是「几天写完的代码量」。

---

## 7. 边界：本 Skill 不做

- 架构设计、接口/OpenAPI、数据库设计  
- 测试用例编写（本仓库由 **feature-coding** + TDD Rule 承担，无独立 test-spec Skill）  
- Story → 开发 Task 拆解（详设后实现层）  
- 修改已上线逻辑的实现代码  

**需求小变更**：在原 Story 上改 AC/BR +「变更记录」，或新开 Story 引用旧卡；然后走增量详设与 feature-coding。

---

## 8. 延伸阅读

| 文档 | 说明 |
|------|------|
| ai-native-architecture（源项目方法论文档，未随附） | 流水线总览与 Skill 边界 |
| system-landscape 写法指南（[methodology/system-landscape.md](system-landscape.md)） | 系统画像（拆解一般不读，但跨系统 Story 依赖集成事实） |
| `skills/story-splitting/SKILL.md` | 操作说明 |
| `docs/agile/card-naming-conventions.md` | 卡片编号与文件名 |