# MIGRATION：前端线接入指南

本文件为**前端线**接入指南；后端见 [backend/MIGRATION.md](../backend/MIGRATION.md)。

> 本线绑定微信小程序原生（`wx.*`、`pages/`、分包）；换 Vue / React / uni-app 需自行重写 `rules/` 与 Skill 正文的栈相关步骤，不在本接入流程内。
> 本指南由 AI 引导执行：AI 按步骤推进，在人工介入点停下问人。

## 快速导航

| 阶段 | 内容 |
|------|------|
| [§一.1](#1-获取-handoff-包) | 获取 handoff 包 |
| [§一.2](#2-填写前端画像) | 填写前端画像 |
| [§一.3](#3-全局替换前端锚点) | 全局替换前端锚点 |
| [§一.4](#4-重写-golden) | 重写 Golden |
| [§一.5](#5-分发到-agent) | 分发到 Agent |
| [§一.6](#6-工作流裁剪) | 工作流裁剪 |
| [§一.7](#7-接入审查ai-自动) | 接入审查（AI 自动） |
| [§二](#二接入后验收) | 接入后验收 |

---

## 一、接入步骤

### 1. 获取 handoff 包

前端不定义契约——画像 §四（契约文件 / 鉴权 / 错误码对齐）与锚点替换的契约路径都依赖后端发布的 handoff 包（由后端 `api-handoff` Skill 打包，三件套见下）：

1. 向后端团队索取 OpenAPI 快照 + 版本 pin（tag 或 commit SHA）。
2. 放入 `docs/=/openapi/{后端服务标识}.yaml` 与 `docs/handoff/VERSION`（机制见 [docs/handoff/README.md](docs/handoff/README.md)）。
3. **前端永远不直接改契约**——契约变更只能由后端 OpenAPI 先行、再同步快照。

**缺失时向用户提问**，两个合法选择：

- **① 现在去后端团队拿**（推荐——画像 §四 才能填准）。
- **② 先后补**：继续接入，画像 §四 标注「handoff 待补」；**契约相关替换组**（契约文件 + URL 前缀 + 公共库/错误码号段）整体列入**待补项**，跳过替换。使用期 `frontend-story-splitting` 会阻断直到补齐（**纯 UI 卡豁免**：无集成层时无需契约，见该 SKILL 前置表）；`docs/handoff/VERSION` 写 `TBD` 作为待补标记。

**handoff 到达后**：按本节 1–2 步放入文件 → 填画像 §四（公共库与号段引用后端画像 §3.7）→ 补执行契约相关替换组 → 重跑 §3 验收命令与 §二 第 3 条（三段走通）。

> AI 不猜契约内容——缺失时不编造路径、字段或错误码。

---

### 2. 填写前端画像

`architecture/system-landscape.md` 重点两节：§四（契约文件 / 鉴权 / 错误码对齐）与 §六（与后端流水线的协作机制）；词表 `glossary/` 与后端仓对齐。

| 项目形态 | 填法 |
|----------|------|
| 已有前端工程 | AI 扫代码仓起草：`pages/` → 页面结构、`app.json` → 分包/tabBar/页面注册、`package.json` → 依赖与版本、`api/http.js` → 请求层与鉴权、handoff 包 → 契约对齐；人审补漏后定稿 |
| 从 0 开始 | 页面结构/分包/UI 库是设计决策：AI 按模板**逐节访谈**（每节人当场拍板），决策汇总为画像草案 |

**确认方式**：逐节访谈当场拍板的内容不再单独确认；画像草案与 §3 的锚点映射表**合并为一次确认**（§3 人工介入点 1），避免同一套决策答两遍。

---

### 3. 全局替换前端锚点

**人工介入点**

| # | 介入时机 | AI 随附的简要结果 | 人做什么 |
|---|----------|------------------|----------|
| 1 | 画像草案 + 锚点映射表就绪后（合并提交） | 画像草案（页面结构/分包/UI 库/契约对齐）+ 锚点映射表 | 一次拍板：页面结构是否准确、契约对齐是否正确、映射表是否认可 |
| 2 | 验收报告后 | 校验器输出 + 残留清单 + **待补项清单（契约相关替换组）** + 表外形态 | 确认残留清零，或仅剩已声明的待补项 |

到达人工介入点自报进度（「第 X/N 个确认点」）。

**AI 任务书**（按序执行；标注「→ 人工介入点 N」处停下。替换范围：本线 `skills/` 与 `rules/`）：

1. **画像 + 映射提案**：读 handoff 包与（存量项目的）代码仓，产出画像草案与「源值 → 目标值」映射表。**→ 人工介入点 1**
2. **批量替换**（提案确认后）：长前缀先替换；`config/current-sprint` 与后端线一致。Windows Git Bash 批替换用 `find ... -exec perl -pi -e '...' {} +`。handoff 待补时跳过「契约文件」行并记入待补项。
3. **验收**：跑下方验收命令与校验器；按判定不变式做**语义扫描**（凡具体文件名、系统名、路径、号段即项目层），表外形态单独报告并逐条处理。**→ 人工介入点 2**

**源值清单**：

| 类别 | 源项目原值（搜索用） | 操作（AI 步骤） | 替换为 |
|------|---------------------|------------------|--------|
| 契约文件 | `docs/handoff/openapi/booking-bff-app.yaml` | 机械替换（步骤 2）；handoff 未到时列待补项 | 后端服务标识.yaml（与 handoff 包一致） |
| URL 前缀 / baseUrl | `/api/v1/booking/app`（`rules/api-client-conventions.md`、`rules/miniprogram-project.md`） | 机械替换（步骤 2）；handoff 未到时列待补项 | 后端实际前缀（画像 §四） |
| 公共库 / 错误码号段 | `hema-common`、`booking-common`、order 1500–1599 / inventory 1600–1699 / adapter 1700–1799（`rules/error-display-conventions.md`） | 机械替换（步骤 2）；handoff 未到时列待补项 | 本项目公共库与分域号段（画像 §四；号段引用后端画像 §3.7） |
| 迭代号 | `2026-S01`、`2026-S02` | 机械替换（步骤 2） | 与后端线一致的迭代约定（`config/current-sprint`） |

**替换边界**（防过度替换）：判断标准是「删掉这条锚点，Skill 还能不能执行」。

| 必须替换（删了不能执行） | 保留（删了仍能执行，只是少了例子） |
|--------------------------|-----------------------------------|
| 契约文件路径、URL 前缀、公共库与错误码号段、迭代号 | 页面/组件/service 示例名（`pages/order-detail/`、`components/reservation-card/`、`services/{booking,order,payment,nav}/`）、Skill 正文的业务示例（目的地搜索、车位等）、Golden 样例文件名、「模板版说明」元描述 |

**验收命令**（在项目根执行）：

```bash
# 未映射形态黑名单：按映射提案取**未被目标选用**的源值构造 grep。
# 号段用 .* 通配兼容 en dash（1500–1599）。
grep -rn "booking-bff-app\|/api/v1/booking\|hema-common\|booking-common\|1500.*1599\|1600.*1699\|1700.*1799" AI-Native/frontend/skills/ AI-Native/frontend/rules/ | grep -v "_golden"
# 预期：无输出；有输出即残留，逐条处理。
# handoff 待补时：契约相关替换组属已声明待补项，单独列出，不计入残留。

# 迭代号单独核对（不并入上方黑名单）：模板正文含 2026-S 示例，目标复用 {年}-S{序号} 约定时会误报；
# 逐条看——SKILL 正文示例保留，config/current-sprint 与工件路径应为目标值。
grep -rn "2026-S" AI-Native/frontend/config/ AI-Native/frontend/skills/ AI-Native/frontend/rules/ | grep -v "_golden"

bash AI-Native/frontend/scripts/validate-skills.sh
```

---

### 4. 重写 Golden

- 从画像与 handoff 契约选真实页面需求，保持文件名模式与结构，重写线根（`AI-Native/frontend/`）`docs/**/_golden/` 的 STORY-FE / DD-FE 样例（源项目为 destination-search-allocate 一族；重写后视为项目资产，模板升级不覆盖）。
- 提交时随附「3 处关键改动 + 建议抽查 1 份」。
- 画像与契约不足、构造不出可信场景时，降级为人工指定。

---

### 5. 分发到 Agent

同后端模式：AI 探测运行环境确定所用 Agent 与目标目录，按该 Agent 的技能 / 规则目录约定完成分发与格式适配，跑校验器验证。仅用户提出多 Agent 需求时才询问。

- **分发资产**：前端线 = `skills/` + `rules/` + `templates/`，不依赖 `backend/` 路径。
- **跨会话扫描**：部分 Agent 的技能目录在会话启动时扫描（如 ZCode）——当次会话不可见属预期，用新会话验证。
- **hooks**：前端线无 hooks；如需复用后端机制，`PROTECTED` 改为前端公共组件目录。

---

### 6. 工作流裁剪

- 模板未含 e2e 与 frontend-test-spec-alignment（规划中，无需裁剪）。
- 如需精简：按项目实际用到的 Skill 删除，跑 `bash AI-Native/frontend/scripts/validate-skills.sh` 并清掉对被裁资产的引用。
- 换 Vue / React / uni-app 不在本流程内——需自行重写 `rules/`（含 error-display 的 `wx.showToast/showModal`）与 Skill 正文的栈相关步骤（pages/ 四同名文件、setData、`wx.on*`、微信开发者工具）。

### 7. 接入审查（AI 自动）

自验（校验器 + §一.3 残留 grep）通过后，**自动**派独立审查人（subagent / 新会话），无需人发起。审查只做脚本查不出的**显性一致性**：

1. **画像残留与自洽**：页面结构 / 分包 / 技术栈无源项目残留；契约文件路径与 handoff 包一致；外部系统（后端服务）与 handoff 实际一致（依据=handoff 包，缺失时标「依据材料待确认」）
2. **锚点语义**：契约路径、页面名、迭代号与画像一致；无 `{项目}-app` 类重复
3. **Golden 抽样**：抽 2 份（STORY-FE / DD-FE），页面场景来自本项目画像而非源项目搬运

**闭环**（审查人只读，不修文件；finding 打标签）：

- **`[机械]`**（残留、命名、路径断裂）：P0/P1 由主流程 AI 修复 → 审查人确认消除 → 重跑校验器与残留 grep
- **`[映射]`**（页面结构 / 契约对齐的语义决策）：**不自动修**——回 §一.2 画像人审定稿 或 §一.1 handoff；改后重跑 §一.3 验收，再回本节复审
- P2 记录；P3 不报
- 报告格式（审查对象 / 依据材料 / findings ≤5 / 结论 + Blocker 数）由**主流程（实现者）落盘**（审查人只读），落 `docs/reviews/{迭代}/REVIEW-ONBOARD-{日期}.md`；交人一行结论 + 「修了什么」摘要（3–5 行）
- 复审：`[机械]` 修复后由审查人确认即可（不重跑全审）；连续 2 轮不通过 → 交人裁定

> 前端线无 Story 门禁；画像小节编号检查（§N.N）仅在**后端线**校验器执行——前端文档常引用后端画像编号（如 §3.7 号段），跨线不校验。

---

## 二、接入后验收

1. 本线校验器 **PASSED**：`bash AI-Native/frontend/scripts/validate-skills.sh --quiet-tick`。
2. 接入审查报告存在且结论为通过：`docs/reviews/{迭代}/REVIEW-ONBOARD-*.md`（§一.7）。
3. 拿到真实 handoff 包走通三段：frontend-story-splitting → frontend-detail-design → frontend-feature-coding（handoff 待补时本条延后至补齐后执行）。
