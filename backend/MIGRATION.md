# MIGRATION：后端线接入指南

本文件为**后端线**接入指南；前端见 [frontend/MIGRATION.md](../frontend/MIGRATION.md)。

> 本指南由 AI 引导执行：AI 按步骤推进，在人工介入点停下问人。可以直接对 AI 说「帮我接入这套工作流」进入引导。

## 快速导航

| 阶段 | 内容 |
|------|------|
| [§一.1](#1-初始化迭代号) | 初始化迭代号 |
| [§一.2](#2-填写项目画像) | 填写项目画像 |
| [§一.3a](#3a-通用项目锚点) | 通用项目锚点 |
| [§一.3b](#3b-公共基础库替换) | 公共基础库替换 |
| [§一.4](#4-重写-golden) | 重写 Golden |
| [§一.5](#5-分发到-agent) | 分发到 Agent |
| [§一.6](#6-工作流裁剪) | 工作流裁剪 |
| [§一.7](#7-接入审查ai-自动) | 接入审查（AI 自动） |
| [§二](#二接入后验收) | 接入后验收 |

---

## 一、接入步骤

### 1. 初始化迭代号

把 `config/current-sprint` 设为接入后的第一个迭代（一行，如 `2026-S03`）。所有 Skill 的工件路径都从这里取迭代号；不要保留模板示例 `2026-S01` / `2026-S02`。

**验收**：文件只有一行，值为目标首个迭代；后续锚点替换后再确认一次，避免被模板值覆盖。

---

### 2. 填写项目画像

`architecture/system-landscape.md` 是模板中唯一必须逐节填写的文件——12 个 Skill 的项目层判断（模块归属、号段路由、测试账号、外部系统 Mock 边界）全部读它。两条路径均以人审定稿收口——画像是项目层事实唯一定义处，错了全链路漂；且须保留被 Skill 引用的小节编号（§3.7 / §4.3.4 / §4.7）。

项目根 `AGENTS.md` 用 [templates/AGENTS.template.md](../templates/AGENTS.template.md) 生成（见根 [README.md](../README.md) 快速开始）；本线画像只写 `architecture/system-landscape.md`，不在 AGENTS.md 复制项目事实。

| 项目形态 | 填法 |
|----------|------|
| 现有项目接入（已有代码） | AI 扫代码仓起草：构建文件→模块与技术栈、Controller→URL 前缀、错误码枚举→号段表、client/config→外部集成；人审补漏后定稿 |
| 从 0 开始的新项目 | 无代码可扫，模块切分/技术栈/部署形态是**架构决策**：AI 按画像模板逐节提问访谈（模板注释即提纲）或基于 PRD 出提案，每节人拍板。**不必一次填满**——先填最小可用（产品定位、技术栈、部署形态、初始模块），跑完 high-level-design 后把定稿的模块边界与集成矩阵回写画像 §二/§四 |

`glossary/domain-glossary.md` 按业务域重建词表（缺失时 Skill 降级运行，不阻断）。

**画像变更后的回刷**：画像会在项目推进中完善（HLD 定稿回写、推断项确认、模块调整）。变更后须按回刷约束处理派生项，否则 `skills/`、`rules/` 与画像不一致且无任何报错——对照表与验证方式见 [rules/system-landscape-change.md](rules/system-landscape-change.md)。

---

### 3. 全局替换项目锚点

本步分两部分：通用锚点替换与公共基础库替换。

#### 3a. 通用项目锚点

把模板里的源项目锚点替换为目标项目事实。人确认映射与验收。

**人工介入点**

1. **映射确认**：AI 提交「源值 → 目标值」表（含裁剪/合并建议），人裁定。
2. **换栈确认**：仅当技术栈变化时，人审重写后的 Rule；同栈接入跳过。
3. **验收确认**：AI 提交残留清单与命令输出，人确认清零或登记豁免。

**AI 任务**

1. **提映射** → 人工介入点 1
   - 先 grep 扫源值：模块、包名、公共库、号段、URL、迭代号。
   - 读画像 §二 / §3.7，按职责映射。
   - 模块与其 `*-api` / `*-impl`、错误码枚举、包名成对映射。
   - 域无对应就裁掉，不硬凑；BFF 合并/拆分别只做机械替换。
2. **替换**
   - 按映射批量替换，长前缀先替换；同步 `config/current-sprint`。
   - 技术栈 / 测试基建是规则重写，不是字符串替换；换栈时 → 人工介入点 2。
   - Windows Git Bash 用 `find -exec` 调 `perl`，避免 `grep | xargs` 的路径转义问题。
3. **验收** → 人工介入点 3
   - 用映射表中**未被目标选用**的旧值构造 grep，排除 `_golden/`。
   - 跑校验器；表外形态逐条报告。
   - 重点抽查：重复模块名、只换 `-api` 未换 `-impl`、URL 前缀与 path 不一致、包名与模块名不一致。

**源值类别**（具体值以当前模板为准，AI 从画像/目录扫描补全）：

| 类别 | 处理 |
|------|------|
| 模块 / 包名 | 模块按职责语义映射；包名机械替换；域无对应就裁剪 |
| 公共库 | 见 §3b |
| 错误码号段 | 按目标域重排，写入画像 §3.7 |
| URL / 迭代号 | 替换前缀；同步 `config/current-sprint` |
| 技术栈 / 测试基建 | 换栈时重写对应 Rule；同栈只确认 |

**替换边界**：删了 Skill 不能执行的（模块、包名、公共库、号段、URL、测试账号、构建命令）必须换；只是举例的（业务示例、Golden 文件名、模板说明）保留。

**验收**：

- `bash scripts/validate-skills.sh --quiet-tick` PASSED
- 映射表中未被目标选用的旧值 grep 为 0（`_golden/` 豁免）
- 表外形态逐条有结论

#### 3b. 公共基础库替换

仅当目标公共库与模板不同（坐标/包根/API 形状变化）时执行；完整 AI 任务书（数据来源、映射表、四个人工介入点、验证命令）见 [common-foundation-migration.md](docs/methodology/common-foundation-migration.md)。

---

### 4. 重写 Golden

- 从画像 §二 域清单与词表选取真实业务域，构造「查询-分配」同族用例（源项目为 query-allocate-space 一族）。
- 保持文件名模式与结构，把线根（`AI-Native/backend/`）`docs/**/_golden/` 下 12 个样例用本项目业务重写一遍（重写后视为项目资产，模板升级不覆盖）。
- 提交人验收时随附「3 处关键改动 + 建议抽查 1 份」。
- 画像与词表仍为占位、构造不出可信场景时，降级为人工指定场景后再重写。

> Golden 的价值是「标准长什么样」，不是「别人的业务长什么样」。

---

### 5. 分发到 Agent

探测当前环境确定所用 Agent 与目标目录（如存在 `.zcode/` 即 ZCode），按该 Agent 的技能 / 规则目录约定完成分发与格式适配，跑校验器验证。仅用户提出多 Agent 需求时才询问。

> 部分 Agent 的技能目录在**会话启动时扫描**（如 ZCode）——分发的技能当次会话不可见属预期，用新会话验证，或当前会话按路径直呼 SKILL.md。

**AI 任务**：

1. **分发资产（按线）**：后端线 = `skills/` + `rules/` + `templates/`（至少含 `code-review-report.md`、`stage-review-report.md`、`artifact-review-report.md`）+ 可选 `hooks/`；前端线 = `skills/` + `rules/` + `templates/`，不依赖 `backend/` 路径。
2. **格式适配（按所用 Agent 的约定）**：技能放技能目录、规则放规则目录；Agent 对规则有格式要求时适配——如 Cursor 需转 `.mdc` 并加回 frontmatter（description + globs/alwaysApply），纯 markdown 可直接读的 Agent 原样落位。拿不准该 Agent 的目录约定时问人，不猜。
3. **不变约束**：
   - 不用 symlink 做多 Agent 镜像——Windows 无特权检出时 symlink 物化成路径文本文件，镜像静默失效（源项目实测教训）；多 Agent 用 CI 拷贝同步。
   - 代码审查不绑定 Agent——审查人可为独立 AI 会话、专用审查 agent、人或 CI 工具，统一使用 `rules/code-review.md` §三 的任务书。
   - hooks 按 [hooks/README.md](hooks/README.md) 注册，`PROTECTED` 先改保护路径；前端线复用同机制、路径改前端公共组件目录。
4. **验证**：分发后按目标布局调整 `AGENTS.md` 与规则内的相对链接，跑 `bash <线>/scripts/validate-skills.sh`；模板仓库里的 `backend/...` 链接只是示例布局。

---

### 6. 工作流裁剪

- **无 QA 团队**：删 qa-acceptance-case-design / api-blackbox-test / test-data-design 三个 skill——黑盒冒烟由集成测试取代（见 [docs/methodology/test-line.md](docs/methodology/test-line.md) §4.2）。
- **无独立前端仓**：忽略前端协作章节。
- **legacy-test-migration**：仅当存量项目有历史用例时保留，否则删除。
- 裁剪后跑对应线 `bash scripts/validate-skills.sh`，清掉对被裁 skill 的引用。

### 7. 接入审查（AI 自动）

自验（校验器 + §3 残留 grep）通过后，**自动**派独立审查人（subagent / 新会话），无需人发起。审查只做脚本查不出的**显性一致性**：

1. **画像残留与自洽**：模块清单无源项目模块名残留；`-api`/`-impl` 配对完整；外部系统表与依据材料一致（存量项目=扫码产出，新项目=访谈/PRD 结论；无法取证时标「依据材料待确认」，不臆断）
2. **锚点语义**：替换结果自洽——无 `{项目}-app` 重复、子模块映射不断裂（`order-api` 类遗漏）、URL 与模块对应
3. **Golden 抽样**：抽 2 份（不审全部），业务场景来自本项目画像而非源项目搬运

**闭环**（审查人只读，不修文件；每条 finding 由审查人打标签）：

- **`[机械]`**（残留、命名、配对断裂等可确定性修复）：P0/P1 由**主流程 AI** 修复 → 审查人确认 finding 已消除（P0/P1 必须确认）→ 重跑校验器与 §3 残留 grep。
- **`[映射]`**（涉及模块映射或画像事实的语义决策）：**不自动修**——模块映射回 §3a 介入点 1，画像事实回 §一.2 人审定稿；改后重跑 §3a 验收，再回本节复审。
- P2 记录；P3 不报（与 artifact-review 一致）。
- 报告格式复用 [templates/artifact-review-report.md](templates/artifact-review-report.md)（审查对象 / 依据材料 / findings ≤5 / 结论 + Blocker 数），由**主流程（实现者）落盘**（审查人只读），落 `docs/reviews/{迭代}/REVIEW-ONBOARD-{日期}.md`；交人一行结论 + 「修了什么」摘要（3–5 行），无需逐项核对。
- 复审：`[机械]` 修复后由审查人确认即可（不重跑全审）；连续 2 轮不通过 → 交人裁定（与 artifact-review 一致）。

> **能力边界**：审查人捕捉显性不一致（残留、命名、搬运）；业务合理性（模块该不该这么切、画像是否符合实际业务）由 §一.2 人审定稿与 §3a 介入点 1 拍板，AI 不做业务判断。

---

## 二、接入后验收

1. 本线校验器 **PASSED**：`bash scripts/validate-skills.sh --quiet-tick`（前端线见 [frontend/MIGRATION.md](../frontend/MIGRATION.md)）。
2. 接入审查报告存在且结论为通过：`docs/reviews/{迭代}/REVIEW-ONBOARD-*.md`（§一.7）。
3. 用一张真实小需求走通 `story-splitting → detail-design → test-spec-alignment → feature-coding`；产出路径/命名符合线根 `docs/agile/card-naming-conventions.md`，工件落在**项目根** `docs/{requirements,design,...}/{迭代}/`，并至少有一份代码审查报告落盘。
4. 在干净目录/新克隆中重跑接入，确认不依赖本机缓存、未提交文件或旧镜像。
