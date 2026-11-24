# MIGRATION：前端线接入指南（纯模板版）

本文件为**前端线**接入指南；后端见 [backend/MIGRATION.md](../backend/MIGRATION.md)。

> **零全局替换设计**：本线 `skills/` 与通用 `rules/` 均已抽象化，契约文件名、URL 前缀、错误码与迭代号统一从 `architecture/system-landscape.md`、`config/current-sprint` 与 `docs/handoff/` 读取，接入时**无需对 `skills/` 做全局字符串替换**。
> 本线面向微信小程序原生（`wx.*`、`pages/`、分包）；换 Vue / React / uni-app 需自行重写 `rules/` 与 Skill 正文的栈相关步骤，不在本接入流程内。
> 本指南由 AI 引导执行：AI 按步骤推进，在人工介入点停下问人。

## 快速导航

| 阶段 | 内容 |
|------|------|
| [§一.1](#1-获取-handoff-包与初始化迭代号) | 获取 handoff 包与初始化迭代号 |
| [§一.2](#2-填写前端画像) | 填写前端画像 |
| [§一.3](#3-重写-golden建议) | 重写 Golden（建议） |
| [§一.4](#4-分发到-agent-与工作流裁剪) | 分发到 Agent 与工作流裁剪 |
| [§一.5](#5-接入审查ai-自动) | 接入审查（AI 自动） |
| [§二](#二接入后验收) | 接入后验收 |

---

## 一、接入步骤

### 1. 获取 handoff 包与初始化迭代号

前端不定义契约——画像 §四（契约文件 / 鉴权 / 错误码对齐）依赖后端发布的 handoff 包：

1. 把 `config/current-sprint` 设为与后端一致的首个迭代号（一行，如 `2026-S03`）。
2. 向后端团队索取 OpenAPI 快照 + 版本 pin（tag 或 commit SHA），放入 `docs/handoff/openapi/{后端服务标识}.yaml` 与 `docs/handoff/VERSION`（机制见 [docs/handoff/README.md](docs/handoff/README.md)）。
3. **前端永远不直接改契约**——契约变更只能由后端 OpenAPI 先行、再同步快照。

**handoff 缺失时向用户提问**，两个合法选择：

- **① 现在去后端团队拿**（推荐——画像 §四 才能填准）。
- **② 先后补**：继续接入，画像 §四 标注「handoff 待补」；`docs/handoff/VERSION` 写 `TBD` 作为待补标记。使用期 `frontend-story-splitting` 会阻断直到补齐（**纯 UI 卡豁免**：无接口交互时无需契约，见该 SKILL 前置表）。

**handoff 到达后**：放入文件 → 补填画像 §四（契约文件名、baseUrl、鉴权与错误码规则，号段对齐后端画像 §3.7）→ 跑通 §二 第 3 条。

> AI 不猜契约内容——缺失时不编造路径、字段或错误码。

---

### 2. 填写前端画像

`architecture/system-landscape.md` 是前端线唯一必须逐节填写的项目事实文件，重点两节：§四（契约文件 / baseUrl / 鉴权 / 成功判据与错误码对齐）与 §六（与后端流水线的协作机制）；词表 `glossary/domain-glossary.md` 与后端仓对齐。

| 项目形态 | 填法 |
|----------|------|
| 已有前端工程 | AI 扫代码仓起草：`pages/` → 页面结构、`app.json` → 分包/tabBar/页面注册、`package.json` → 依赖与版本、`api/http.js` → 请求层与鉴权、handoff 包 → 契约对齐；人审补漏后定稿（**人工介入点 1**） |
| 从 0 开始 | 页面结构/分包/UI 库是设计决策：AI 按模板**逐节访谈**（每节人当场拍板），决策汇总为画像定稿（**人工介入点 1**） |

---

### 3. 重写 Golden（建议）

- 从画像与 handoff 契约选真实页面需求，保持文件名模式与结构，重写线根（`AI-Native/frontend/`）`docs/**/_golden/` 的 STORY-FE / DD-FE 样例（重写后视为项目资产，模板升级不覆盖）。
- 提交时随附「3 处关键改动 + 建议抽查 1 份」。
- 画像与契约不足、构造不出可信场景时，可先跳过并在完成首个真实前端 Story 后补写。

---

### 4. 分发到 Agent 与工作流裁剪

1. **分发到 Agent**：同后端模式——AI 探测运行环境确定所用 Agent 与目标目录，按该 Agent 的技能 / 规则目录约定完成分发与格式适配（前端线 = `skills/` + `rules/` + `templates/`，不依赖 `backend/` 路径；不用 symlink），跑 `bash AI-Native/frontend/scripts/validate-skills.sh --quiet-tick` 验证。
2. **工作流裁剪**：模板未含 e2e 与 frontend-test-spec-alignment（规划中）；如需精简按实际删 Skill 并清引用、重跑校验器。换 Vue / React / uni-app 需自行重写 `rules/` 与 Skill 正文的栈相关步骤。

---

### 5. 接入审查（AI 自动）

自验（校验器 PASSED）通过后，**自动**派独立审查人（subagent / 新会话），无需人发起。审查聚焦脚本查不出的**显性一致性**：

1. **画像完整与自洽**：页面结构 / 分包 / 技术栈无未填占位符残留；契约文件路径、baseUrl、成功判据与 handoff 包一致（handoff 缺失时显式标「handoff 待补」与 `VERSION=TBD`）。
2. **迭代号与配置一致**：`config/current-sprint` 与后端线一致；分发后的规则与 `AGENTS.md` 链接可达。
3. **Golden 抽样（若已重写）**：抽 2 份（STORY-FE / DD-FE），页面场景来自本项目画像而非模板搬运。

**闭环**（审查人只读，不修文件；finding 打标签）：

- **`[机械]`**（占位残留、命名、路径断裂）：P0/P1 由主流程 AI 修复 → 审查人确认消除 → 重跑校验器。
- **`[映射]`**（页面结构 / 契约对齐的语义决策）：**不自动修**——回 §一.2 画像人审定稿 或 §一.1 handoff；改后回本节复审。
- P2 记录；P3 不报；报告由主流程落 `docs/reviews/{迭代}/REVIEW-ONBOARD-{日期}.md`；连续 2 轮不通过交人裁定。

> 前端线无 Story 门禁；画像小节编号检查（§N.N）仅在**后端线**校验器执行——前端文档引用后端画像编号（如 §3.7 号段）时跨线不校验。

---

## 二、接入后验收

1. 本线校验器 **PASSED**：`bash AI-Native/frontend/scripts/validate-skills.sh --quiet-tick`。
2. 接入审查报告存在且结论为通过：`docs/reviews/{迭代}/REVIEW-ONBOARD-*.md`（§一.5）。
3. 拿到真实 handoff 包走通三段：`frontend-story-splitting → frontend-detail-design → frontend-feature-coding`（handoff 待补时本条延后至补齐后执行）。
