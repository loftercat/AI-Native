# MIGRATION：后端线接入指南（微服务纯模板版）

本文件为**后端线（微服务工作流）**接入指南；前端见 [frontend/MIGRATION.md](../frontend/MIGRATION.md)。

> **零全局替换设计**：本模板的 `skills/` 与通用 `rules/` 均已彻底抽象化，项目专属事实统一收拢在 `architecture/system-landscape.md`、`config/current-sprint`、项目根 `AGENTS.md` 与 `hooks/` 配置中。接入时**无需对 `skills/` 做全局锚点搜索替换**，后续模板母版升级可直接覆盖通用层。
> 本指南由 AI 引导执行：AI 按步骤推进，在人工介入点停下问人。可以直接对 AI 说「帮我接入这套工作流」进入引导。

## 快速导航

| 阶段 | 内容 |
|------|------|
| [§一.1](#1-初始化迭代号与入口) | 初始化迭代号与项目根 `AGENTS.md` |
| [§一.2](#2-填写项目画像含两档选型拍板与公共库登记) | 填写项目画像（含两档 13 项选型与公共库登记） |
| [§一.3](#3-轻量项目配置条件-rule-与-hook) | 轻量项目配置（按选型适配条件 Rule + Hook 路径） |
| [§一.4](#4-重写-golden建议) | 重写 Golden（建议） |
| [§一.5](#5-分发裁剪与接入审查) | 分发到 Agent、裁剪与接入审查（AI 自动） |
| [§二](#二接入后验收) | 接入后验收 |

---

## 一、接入步骤

### 1. 初始化迭代号与入口

1. 把 `config/current-sprint` 设为接入后的第一个迭代（一行，如 `2026-S03`）。所有 Skill 的工件路径都从这里取迭代号。
2. 用 [templates/AGENTS.template.md](../templates/AGENTS.template.md) 生成项目根 `AGENTS.md`（填完基本摘要与链接前缀）；存量项目已有 `AGENTS.md` 时进行整合。不在 `AGENTS.md` 复制画像正文。

**验收**：`config/current-sprint` 仅有一行且为目标首个迭代号；项目根 `AGENTS.md` 指向 `AI-Native/backend/architecture/system-landscape.md`。

---

### 2. 填写项目画像（含两档选型拍板与公共库登记）

`architecture/system-landscape.md` 是本模板唯一必须逐节填写的核心事实文件——12 个 Skill 的项目层判断（服务清单、数据归属、仓库模式、调用协议、ORM、响应/错误码、内部鉴权、测试账号、外部系统 Mock 边界）全部直接读取它。必须保留被 Skill 与校验器引用的小节编号（`§3.7` / `§4.3.4` / `§4.7` / `§5.4`）。

| 项目形态 | 填法 |
|----------|------|
| 现有项目接入（已有代码） | AI 扫代码仓起草：构建文件→服务清单与技术栈（ORM/调用协议/公共库）、网关与入口→URL 前缀与内部路由、错误码枚举→号段表、client/config→服务间通信矩阵与外部集成；人审补漏后定稿（**人工介入点 1**） |
| 从 0 开始的新项目 | 无代码可扫，服务切分与技术选型是**架构决策**：AI 按画像模板逐节提问访谈或基于 PRD 出提案，每节人拍板（**人工介入点 1**）。先填服务清单、基本架构与下方第一档 6 项必选；跑完 `high-level-design` 后把定稿的服务边界与通信矩阵回写画像 §二 / §3.6 |

#### 微服务两档技术选型引导（画像 §5.4，AI 必执行）

1. **第一档：开工前必选（P-1 ~ P-6，共 6 项）**——接入期应拍板定稿（未拍板在首次 `detail-design` / `feature-coding` 会阻断）：
   - **P-1 仓库组织模式**：单仓库多服务 vs 一服务一独立仓库 vs 按业务域分仓。
     - **若选一服务一独立仓库（多仓）**，AI 必须追加确认 **3 件事** 写入画像 §5.4 P-1：① 跨服务文档（EPIC/JSD/HLD/迭代索引）总仓位置；② `*-api` 契约包或接口文档跨仓发布与同步方式；③ 各服务仓复用校验脚本方式。
   - **P-2 服务间同步调用协议**：OpenFeign（HTTP）/ Dubbo / gRPC / RestClient / 混合。同步明确领域服务入口形态、内部契约载体与单服务 `*IT` 下游模拟方式。
   - **P-3 数据库访问框架（ORM）**：MyBatis + XML / MyBatis-Plus / JPA / jOOQ 等（含主键策略，以及删除策略：软删 / 状态作废）。
   - **P-4 响应格式与跨服务错误码规则**：对外/对内返回结构、跨服务报错透传或映射策略、公共基础库坐标与微服务号段（同步填进画像 §3.7；公共库登记细则见 [common-foundation-migration.md](docs/methodology/common-foundation-migration.md)）。
   - **P-5 内部接口防外泄与服务间鉴权**：防外泄方式、内部鉴权机制、外部伪造头清理与透传头约定。
   - **P-6 公共库边界（`*-common`）**：允许放哪些通用工具、严禁放业务 DTO/DO。
2. **第二档：用到再定（E-1 ~ E-7，共 7 项）**——AI 做一次快速确认：「服务注册配置、异步 MQ、跨服务一致性、事件契约、自动化契约测试、多实例定时任务、链路追踪这 7 项里，哪些现在已定型？」已定即填入，未定显式保留 `[TBD]`（首次业务需求命中时再由 Skill 阻断补全）。

`glossary/domain-glossary.md` 按业务域重建词表（缺失时 Skill 降级运行，不阻断）。

**画像变更后的同步**：项目推进中完善画像（HLD 回写、§5.4 `[TBD]` 拍板、服务调整）后，按 [rules/system-landscape-change.md](rules/system-landscape-change.md) 同步条件规则。

---

### 3. 轻量项目配置（条件 Rule 与 Hook）

通用 `skills/` 与通用 `rules/` **无需批量替换**，仅处理以下 3 处与目标项目选型强相关的配置落点（**人工介入点 2**，无换栈项时合并确认）：

1. **ORM 条件规则（按画像 P-3）**：
   - 选 MyBatis / MyBatis-Plus → 保留 `rules/mybatis-conventions.md`，把文首「项目实现」的主键、删除两格写成画像 P-3 的结论（应用侧 ID 或数据库自增；软删或状态作废）。介入点 2 给人看这两格。
   - 选 JPA / jOOQ 等其他 ORM → 删除 `rules/mybatis-conventions.md`，按目标 ORM 编写一份持久化 Rule，文首同样写明主键与删除方式，并在 `AGENTS.md` / 相关指引登记。
2. **公共基础库 API 速查（按画像 P-4 / §3.7）**：
   - 按 [common-foundation-migration.md](docs/methodology/common-foundation-migration.md) 把本项目实际公共基础库（或自建封装）的坐标、响应体、异常与分页 API 登记到 `rules/exception-and-result.md`「项目实现速查」节。
3. **Hook 保护路径（若启用 `hooks/`）**：
   - 修改 `hooks/bugfix-protect-common.sh` 顶部 `PROTECTED` 数组为本项目真实公共库与 `*-api` 路径，并试触一次确认拦截生效（详见 [hooks/README.md](hooks/README.md)）。

---

### 4. 重写 Golden（建议）

- 从画像 §二 服务清单与词表选取真实业务场景，保持文件名模式与结构，把线根（`AI-Native/backend/`）`docs/**/_golden/` 下样例用本项目业务重写一遍（重写后视为项目资产，模板升级不覆盖）。
- 提交人验收时随附「3 处关键改动 + 建议抽查 1 份」。
- 画像与词表仍不足、构造不出可信场景时，可先跳过并在完成首个真实 Story 后补写。

> Golden 的价值是「标准长什么样」，不是「别人的业务长什么样」。

---

### 5. 分发、裁剪与接入审查

#### 5a. 分发到 Agent

探测当前环境确定所用 Agent 与目标目录，按该 Agent 的技能 / 规则目录约定完成分发与格式适配（打包为一次收尾提问，不逐项问）。

> 部分 Agent 的技能目录在**会话启动时扫描**——分发的技能当次会话不可见属预期，用新会话验证，或当前会话按路径直呼 `SKILL.md`。

1. **分发资产（按线）**：后端线 = `skills/` + `rules/` + `templates/`（至少含 `code-review-report.md`、`stage-review-report.md`、`artifact-review-report.md`）+ 可选 `hooks/`。
2. **格式适配**：技能放技能目录、规则放规则目录；如 Cursor 需转 `.mdc` 并补 frontmatter（description + globs/alwaysApply），纯 markdown 可直接读的 Agent 原样落位。
3. **不变约束**：不用 symlink 做多 Agent 镜像（Windows 检出会物化失效，多 Agent 用复制/CI 同步）；代码审查不绑定具体 Agent。
4. **验证**：分发后按目标布局调整 `AGENTS.md` 相对链接，跑 `bash scripts/validate-skills.sh --quiet-tick`。

#### 5b. 工作流裁剪

- **无 QA 团队**：`qa-acceptance-case-design` 与 `test-data-design` 可按需裁剪；**微服务架构下建议保留 `api-blackbox-test`**，用于部署后跨服务主链路验证（见 [docs/methodology/test-line.md](docs/methodology/test-line.md)）。
- **无独立前端仓**：忽略前端协作章节。
- **legacy-test-migration**：仅当存量项目有历史用例时保留，否则删除。
- 裁剪后必须重跑 `bash scripts/validate-skills.sh --quiet-tick`，清掉对被裁资产的引用。

#### 5c. 接入审查（AI 自动）

自验（校验器 PASSED）通过后，**自动**派独立审查人（subagent / 新会话），无需人发起。审查聚焦脚本查不出的**显性一致性**：

1. **画像完整与自洽**：服务清单无未填占位符 `{项目名}` / `{project}` / `{service}` / `{domain-*}` 残留（`§5.4` 显式 `[TBD]` 除外）；`-api`/`-impl` 配对完整；外部系统表与依据材料一致；
   - **画像 §5.4 第一档 6 项（P-1 ~ P-6）均已定稿**（或有书面豁免理由）；若 P-1 选多仓模式，3 项多仓配套约定均已填实；
   - **画像 §5.4 第二档 7 项（E-1 ~ E-7）** 已定项与规则一致，未定项均显式标注 `[TBD]`。
2. **配置落点一致**：`config/current-sprint`、项目根 `AGENTS.md`、条件 Rule（ORM / 公共库速查）与 Hook `PROTECTED` 路径均与画像一致且无 `{project}` / `{company}` 等字面量占位残留。选 MyBatis 时，`rules/mybatis-conventions.md`「项目实现」的主键与删除方式必须与画像 §5.4 P-3 为同一结论，两格都不得仍为 `[TBD]`。选 JPA / jOOQ 等时，替换后的持久化 Rule 文首必须写明与画像 P-3 相同的主键与删除方式，未写明或与画像不一致即不通过。两种情况下，必守条款都不得覆盖画像（画像为状态作废时，不得再把 `deleted = 0` 写成必守）。
3. **Golden 抽样（若已重写）**：抽 2 份，业务场景来自本项目画像而非模板搬运。

**闭环**（审查人只读，不修文件；每条 finding 打标签）：

- **`[机械]`**（占位残留、链接、命名、配对断裂）：P0/P1 由**主流程 AI** 修复 → 审查人确认消除 → 重跑校验器。
- **`[映射]`**（涉及服务切分、§5.4 选型拍板或画像事实的语义决策）：**不自动修**——回 §一.2 人审定稿；改后回本节复审。
- P2 记录；P3 不报；报告复用 [templates/artifact-review-report.md](templates/artifact-review-report.md)，由主流程落 `docs/reviews/{迭代}/REVIEW-ONBOARD-{日期}.md`；连续 2 轮不通过交人裁定。

---

## 二、接入后验收

1. 本线校验器 **PASSED**：`bash scripts/validate-skills.sh --quiet-tick`（前端线见 [frontend/MIGRATION.md](../frontend/MIGRATION.md)）。
2. 接入审查报告存在且结论为通过：`docs/reviews/{迭代}/REVIEW-ONBOARD-*.md`（§一.5c）。
3. 用一张真实小需求走通 `story-splitting → detail-design → test-spec-alignment → feature-coding`；产出路径/命名符合线根 `docs/agile/card-naming-conventions.md`，工件落在**项目根** `docs/{requirements,design,...}/{迭代}/`，并至少有一份代码审查报告落盘。
4. 在干净目录/新克隆中确认不依赖本机缓存、未提交文件或旧镜像。
