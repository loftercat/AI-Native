---
name: story-splitting
description: 将 Epic/PRD/HLD 拆为带 AC 的 Story 卡。用于新需求、迭代规划、写 docs/requirements 时。
---

> **模板版说明**：本 Skill 自已落地的源项目抽取为通用模板。文中项目专属值（模块名 `booking-*`、包名 `com.hema`、错误码号段、具体路径与 Story 号）均为**示例**，接入项目时按 [MIGRATION.md](../../../MIGRATION.md) 清单替换；「本仓库」指接入后的目标项目。


# Story 拆分（story-splitting）

## 1. 定位

**把 Epic / 粗需求拆成可独立验收的 Story（AC/BR），落盘到迭代目录——只做需求语义，不做详设、接口和代码。**

本仓库 Story 须标注 **服务/模块**（对齐 [system-landscape.md](../../architecture/system-landscape.md)），避免把 B 端能力写到 App BFF、或把 UI 需求写进本仓库。

---

## 2. 何时触发

- 新 Epic / 迭代规划 / 从 PRD 或 HLD 拆卡
- 用户要求写 `docs/requirements/{迭代}/STORY-*.md`

**不触发**：详设、Java 实现、OpenAPI 设计。

---

## 3. 前置加载（按序）

| # | 资产 | 路径 | 缺失时 |
|---|------|------|--------|
| 1 | 迭代 | `config/current-sprint` | 询问用户 |
| 2 | 系统画像 | `architecture/system-landscape.md` | **阻断**边界冲突 |
| 3 | AGENTS.md | 做什么 / 不做什么 | 必须读 |
| 4 | 输出模板 | `templates/story-template.md` | **阻断** |
| 5 | 粒度指引 | `references/granularity-guide.md` | **阻断** |
| 5b | AC 完备性清单 | `references/ac-completeness-checklist.md` | **阻断** |
| 5c | 迭代索引模板 | `templates/sprint-index-template.md` | Epic 级拆卡 **阻断** |
| 6 | JSD（建议） | `docs/requirements/epics/JSD-EPIC-*.md`（旅程+场景） | 降级；有则 **场景清单为 AC 完备性源头**（§5.5） |
| 6b | HLD（可选） | `docs/design/epics/HLD-EPIC-*.md` | 降级 |
| 7 | 词表 | `glossary/domain-glossary.md` | 降级 |
| 8 | 原型（若有） | Epic 来源路径；Axure 导出 HTML（如 `目的地.html`） | 降级；C 端旅程 **建议必读** |
| 9 | Rule | `rules/story-ac-conventions.md`、`rules/card-naming-conventions.md` | 必须读 |
| 10 | Golden Story | `docs/requirements/_golden/STORY-GOLDEN-001-query-allocate-space.md` | 降级 |

---

## 4. 模块归属（写 Story 时）

| 模块字段值 | 典型 Story 内容 |
|------------|----------------|
| `booking-bff-app` | C 端查询/下单/支付入口 HTTP |
| `booking-bff-admin` | 运营查询/配置/报表 HTTP |
| `booking-order` | 预约单状态机、支付编排、取消退款 |
| `booking-inventory` | 车位锁定、占用、释放 |
| `booking-parking-adapter` | 厂商开闸、计费、核销适配 |
| `booking-common` | 跨域公共组件（少单独 Story） |
| `集成` | 支付系统 / iam-server / 外部车场联调 |

**不属于本仓库**（Story 非目标或另仓）：C 端小程序 UI、B 端运营后台前端页面、支付渠道实现、B 端登录页。

---

## 5. 核心思想

### 5.1 粒度公式

```text
一张 Story = 一个角色 × 一个完整业务意图 × 一个风险域
```

管道型 Epic（预约提交→支付→占库存）默认可 2 张卡：准备 + 提交（含结果）。

### 5.2 AC / BR

- **BR**：可编号业务规则；跨 Story 在最上游定义，其它引用 `STORY-xxx.BRn`
- **AC**：GWT；失败类须写**具体用户可见文案**
- **BR→AC**：含失败语义（「否则不可」「须」「仅当」等）的 BR，本 Story 须至少有 **1 条对应失败 AC**；成功语义须有成功 AC 或引用上游 AC
- **§2.3 校验职责**：BFF/领域写的校验须在 AC 或 BR 可验收，禁止只写职责表
- **产品 BR / 实现 BR**（见 `rules/story-ac-conventions.md`）：
  - **用户可见结果**（能否搜到、失败文案）→ **AC** 写死
  - **匹配/排序/格式化算法** → 默认 `[AI推断]` 记入 §8；详设可写默认方案，**PO 未确认前不得**在 BR 正文写成无标注的定稿规则
- 格式听 **rules/story-ac-conventions.md**，流程听本 Skill

### 5.3 缺口三分法

| 类型 | 处理 |
|------|------|
| **阻断** | 与 system-landscape 冲突、金额/权限/状态机不明 |
| **可补充** | `[AI推断]`（排序规则、次要字段默认值等**不改变**用户可见成败的项） |
| **提醒** | 缺原型但涉及表单；**原型标注与 Story 未对齐**（见 §5.4）；并发/性能写 §6 测试关注点 |

### 5.4 原型对齐检查（有 Axure/HTML 时必做）

对 **本 Story 对应的原型页**（及同页产品标注、说明矩形）逐条过一遍，每条标为下表四类之一，**禁止静默忽略**：

| 标注 | 含义 | 落盘要求 |
|------|------|----------|
| **本 Story AC** | 本仓库后端须在本迭代验收 | 写入 AC/BR 或 §2.1；API 须返回的字段写进 Then |
| **后续 Story** | 同旅程但另一张卡 | §5 依赖与追溯写 `后续 Story STORY-xxx`；§2.2 可简述边界 |
| **前端另仓** | 纯 UI/地图/控件，本仓库只提供 API 或不涉及 | §2.2 非目标或 §2.3 校验职责「前端」 |
| **显式非目标** | 明确不做（含 V2+、另系统） | §2.2 非目标一行写清 |

**检查顺序**（建议）：

1. Story「来源」写清 **原型工程名 + 主 HTML 路径**（绝对或仓库内相对路径）
2. 打开主 HTML，收集 **页面标题、流程标注、说明文字**（含同页多状态）
3. 区分 **展示字段** vs **交互能力** vs **纯视觉**：
   - 展示字段（名称、地址、**收费标准**、可售数等）→ 后端 Story 须有 AC 或标「后续 Story」
   - 纯 UI（默认地图、控件样式）→ **前端另仓**
4. 管道型「准备」卡：对照 Epic 准备阶段，确认 **选车场后展示的信息**（含费率预览）未漏标
5. 汇总表写入 Story **§5 依赖与追溯** 或 **§8 AI 推断项**（defer 须写依据）

**常见漏标**（提醒，非阻断）：原型有「收费详情」但 AC 只返回名称地址；配置类能力在 HLD 另 Story（如服务费配置）但 C 端读取未链依赖。

### 5.5 AC 完备性检查（落盘前必做）

在原型对齐（§5.4）之后、落盘之前，按 [ac-completeness-checklist.md](references/ac-completeness-checklist.md) 过一遍：

> **源头追溯**：若已加载 JSD（前置 #6），本 Story 涉及的**场景编号**（`SC-J*-*`）须逐条映射到 AC 或写入 §2.2 / §5 / §8 写明去向，**禁止静默丢弃场景**；JSD 无对应场景的对外能力，按本节清单补 AC。

1. **主路径 + 失败路径**：每个对外 API/能力 ≥1 成功 AC；业务失败、参数非法、资源不存在/不可用分文案覆盖
2. **查询/搜索类**（含关键词、列表）：须覆盖 **无匹配**、**关键词非法**（空/纯空白）、**含多余空格仍可匹配**（AC 举 `华润  大厦`）；**匹配算法**标 `[AI推断]` 写 §8，详设给默认实现
3. **BR 映射**：逐条核对 §3 BR 表；含失败语义的 BR 无对应 AC 则补 AC 或标阻断问用户；**实现类 BR 备注列须有 `[AI推断]`**
4. **可合并**：同类参数校验可合并为一条 AC（When 列举多种输入），不可因「详设再写」省略
5. **汇总**：未覆盖项写入 §2.2 / §5 / §8 并写明 defer 依据；产出汇总（§6 步骤 9）列出 **AC 完备性缺口**

**不再默认 defer 到详设**：必填校验、BR 失败语义、用户可见匹配结果（AC）——Story 层能判定对错的，必须在 Story 落盘；**具体匹配/排序算法** 可详设默认实现，但须 §8 `[AI推断]`。

### 5.6 依赖拓扑与编号顺序（Epic / 批量原型拆卡时必做）

> **拆分优先级**（granularity-guide §1）管「怎么切卡」；本节管「卡号谁先谁后」。二者不可混用。

#### 5.6.1 两类依赖

| 类型 | 含义 | 对序号的要求 |
|------|------|--------------|
| **阻塞依赖** | 无此前置则**无法独立验收**本 Story（缺主数据、缺鉴权、缺上游 API 契约等） | 上游序号 **必须小于** 下游 |
| **消费方 / 后续 Story** | 本 Story 产出被下游使用，或同旅程下一步 | 本 Story 序号 **小于** 消费方；**禁止**把消费方写成本卡的阻塞依赖 |

示例：可售查询(007) **阻塞依赖** 主数据(004)；创建预约(008) **阻塞依赖** 可售查询(007)。**禁止**写「007 依赖 008」。

#### 5.6.2 实现波次（Wave）

拆卡前先按旅程归类（**已加载 JSD 则直接复用其旅程编号 J*／场景编号 SC-J*-*，勿重新发明归类**），再划波次（Foundation 永远最早）：

| 波次 | 典型内容 | 编号段建议 |
|------|----------|------------|
| **W0 Foundation** | 工程骨架、鉴权 Filter、数据隔离、主数据 CRUD、南向 Mock | 001 起连续占号 |
| **W1 主链路** | 管道「准备」+「提交」、核心状态机、支付闭环 | 紧接 W0 |
| **W2 扩展** | 扫码/代客/报表/运营工具等同迭代次要旅程 | 紧接 W1 |
| **W3 低耦合** | 可穿插的查询、指标、风控（仅契约依赖 W0/W1） | 最后 |

同波次内可并行，但 **Story 序号仍按拓扑序连续分配**。

#### 5.6.3 编号规则（阻断）

1. **序号 = 阻塞依赖拓扑序**：对每条阻塞依赖 `A → B`，须 `序号(A) < 序号(B)`。
2. **禁止**单独按以下维度编号：原型 HTML 页码/文件名、PRD 章节号、HLD `S-xx` 序号、模块字母序。
3. **批量原型**：先产出 **旅程地图 + 全局 DAG**（步骤 3.5），再赋序号；**禁止**「一页一卡顺编号」。
4. 拓扑校验失败（成环、Foundation 晚于消费方）→ **阻断落盘**，合并 Story 或 AskQuestion。
5. Epic 级拆卡须产出 [`sprint-index-template.md`](templates/sprint-index-template.md) 落盘为 `docs/requirements/{迭代}/README-{迭代}-迭代交付计划.md`。

**范本**：`docs/requirements/{迭代}/README-{迭代}-迭代交付计划.md`（人力排期可后补；**拓扑与序号映射**须在拆卡时就有）。

#### 5.6.4 批量原型：旅程索引（步骤 2 延伸）

在逐页拆卡前，先列 **原型页 → 旅程阶段 → 预计 Story** 表（写入迭代交付计划 §二）：

1. 收集全部原型页标题与流程标注（不按页码顺序拆卡）。
2. 标 **横切 Foundation**（主数据、规则配置、鉴权）——通常不在 C 端首页原型里，但须先于 C 端业务卡。
3. 管道型旅程内：**准备卡序号 < 提交卡序号**。
4. 配置类 Admin 页 → 通常 W0/W1；C 端只读展示字段 → 在消费方 Story AC 中引用配置 Story 或标契约依赖。

---

## 6. 标准流程

1. 加载模板、粒度指引、AC 完备性清单、**迭代索引模板**、Golden、词表、current-sprint、**JSD（若有，场景清单作 AC 源头）**  
2. 理解输入；识别管道型 Epic；**批量原型时列旅程地图**（§5.6.4）  
3. 缺口评估  
3.5. **依赖拓扑**：Foundation 识别 → 阻塞 DAG → 波次划分 → **拓扑序赋序号草案**（§5.6）  
4. 按波次拆 Story + 模块标注 + INVEST 自检 → **用户确认概览（必须按波次/Wave 排序展示，禁止按原型页码排序）**  
4.5. **拓扑校验**：每条阻塞依赖检查上游序号更小；无环（§5.6.3）  
5. **原型对齐检查**（§5.4）：有 HTML 则逐条标注四类落点  
6. **AC 完备性检查**（§5.5）：按 ac-completeness-checklist 补异常/边界 AC  
7. 生成完整需求卡（元数据含 **实现波次**；§5 含阻塞依赖与消费方）  
8. 落盘 `docs/requirements/{迭代}/STORY-*.md`（不静默覆盖）  
8.5. 落盘 `docs/requirements/{迭代}/README-{迭代}-迭代交付计划.md`（Epic 级拆卡 **阻断**；单卡增量可跳过）  
9. 产出汇总（含 **拓扑校验结果**、AC 完备性缺口、推断项、原型未映射项）→ 提示对每张 Story 运行 `detail-design`

---

## 7. 边界

- 不写详设、OpenAPI、schema、Java  
- 不写测试规格（本仓库无独立 test-spec Skill）  
- 需求小变更：改 Story + 变更记录 → 增量详设 → feature-coding

---

## 8. 延伸阅读

- [docs/methodology/story-splitting.md](../../docs/methodology/story-splitting.md)
- [granularity-guide.md](references/granularity-guide.md)
- [ac-completeness-checklist.md](references/ac-completeness-checklist.md)
- [sprint-index-template.md](templates/sprint-index-template.md)
