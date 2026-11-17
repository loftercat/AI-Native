# MIGRATION：把本模板接入你的项目

本文件为后端接入指南；前端请阅读 [frontend/README.md](frontend/README.md)，模板结构抽取自落地项目，落地项目技术和架构：Java 21 + Spring Boot 3.2 + Maven 多模块 + 双 BFF。

## 一、接入步骤

### 1. 填写项目画像（必做，AI 起草，人审定稿）

`backend/architecture/system-landscape.md` 是模板中唯一必须逐节填写的文件——12 个 Skill 的项目层判断（模块归属、号段路由、测试账号、外部系统 Mock 边界）全部读它。两条路径均以人审定稿收口——画像是项目层事实唯一定义处，错了全链路漂；且须保留被 Skill 引用的小节编号（§3.7 / §4.3.4 / §4.7）。

| 项目形态 | 填法 |
|----------|------|
| 现有项目接入（已有代码） | AI 扫代码仓起草：构建文件→模块与技术栈、Controller→URL 前缀、错误码枚举→号段表、client/config→外部集成；人审补漏后定稿 |
| 从 0 开始的新项目 | 无代码可扫，模块切分/技术栈/部署形态是**架构决策**：AI 按画像模板逐节提问访谈（模板注释即提纲）或基于 PRD 出提案，每节人拍板。**不必一次填满**——先填最小可用（产品定位、技术栈、部署形态、初始模块），跑完 high-level-design 后把定稿的模块边界与集成矩阵回写画像 §二/§四 |

`backend/glossary/domain-glossary.md` 按业务域重建词表（缺失时 Skill 降级运行，不阻断）。

### 2. 全局替换项目锚点（AI 执行，人只确认映射）

本步由 AI 执行，人工辅助验收。全流程：**AI 映射提案 → 人确认 → AI 批量替换 + 规则重写 → 人审重写 → AI 验收 → 人收报告**。

**人工介入点**

AI 在每个介入点停下时，随附该步的简要修改结果供人审查。

| # | 介入时机 | AI 随附的简要结果 | 人做什么 |
|---|----------|------------------|----------|
| 1 | AI 提交映射提案后 | 映射提案表：源值→目标值、理由、裁剪与合并建议 | 裁定语义映射与结构变化：模块对应关系（域不一定对应，无对应域的裁掉，不硬凑）、BFF 合并/拆分方向 |
| 2 | AI 完成规则重写后 | 规则改动摘要：改了哪些 rule、关键差异 | 审按目标栈重写的规则文件（技术栈、测试基建两行） |
| 3 | AI 提交验收报告后 | 验收报告：命令输出、残留清单、表外形态处理记录 | 确认残留清零、表外形态已逐条处理 |

**AI 任务书**
（按序执行；标注「→ 介入点 N」处停下，随附该介入点的简要修改结果待人审查。替换范围：backend 的 `skills/` 与 `rules/`）：
1. **映射提案**：读 `backend/architecture/system-landscape.md`（§二 模块清单、§3.7 号段表），对源值清单逐项产出「源值 → 目标值」提案。语义映射按职责推测并成对映射（`booking-order → love-advice` 时，`order-api` / `order-impl` / `OrderErrorCode` 同时映射），无对应域的列裁剪建议；BFF 合并/拆分给出方向建议（机械替换会把「App 端 → X，Admin 端 → Y」变成 `love-app / love-app`）。**→ 介入点 1**
2. **批量替换**（提案确认后）：长前缀先替换（`booking-bff-app` 先于 `booking-app`，否则得到 `{项目}-bff-<新前缀>-app`）；源值清单中 `booking-{order,payment,...}` 的花括号是简写，实际搜索用 `booking-` 前缀；`backend/config/current-sprint` 同步改。Windows Git Bash 批替换用 `find ... -exec perl -pi -e '...' {} +`（`grep -rl | xargs` 传反斜杠路径，perl 打不开）。
3. **规则重写**：技术栈、测试基建两行不是字符串替换——按目标栈重写源值清单「替换为」列点名的规则文件。**→ 介入点 2**
4. **验收**：跑下方验收命令与 `bash backend/scripts/validate-skills.sh`；按判定不变式做**语义扫描**（凡具体文件名、系统名、路径、号段即项目层），表外形态单独报告并逐条处理，不静默放过；重点抽查 `love-app.*love-app`（重复）、`order-api`（子模块漏映射）、`/api/v1/`（前缀换了路径没换）。**→ 介入点 3**

**源值清单**（左列是源项目真实值，不是可保留的占位符——AI 按此表替换，验收也按此表查残留）：

| 类别 | 源项目原值（搜索用） | 操作（AI 步骤） | 替换为 |
|------|---------------------|------------------|--------|
| 模块名 | `booking-app`、`booking-bff-app`、`booking-bff-admin`、`booking-{order,payment,inventory,push,iot}`、`booking-common`、`booking-parking-adapter` | 语义映射（步骤 1）——域不一定对应，按职责重命名 | 目标模块清单（须与画像 §二 一致） |
| 包名 | `com.hema.booking.*` | 机械替换（步骤 2） | 目标项目 groupId 路径 |
| 公共库 | `hema-common`（`Result`/`BizException`/`ErrorCode`） | 机械替换（步骤 2）；**若无公司级公共库**，先在 `backend/rules/exception-and-result.md` 定义本项目统一响应与异常 | 本项目公共库 |
| 错误码号段 | 1500-1549 order / 1550-1599 payment / 1600-1699 inventory / 1700-1799 adapter / 1800-1899 push / 1900-1999 iot | 重新分配（步骤 1 人确认）——按目标项目域数重排 | 目标项目分域号段表（画像 §3.7 + bugfix 责任域定位依赖） |
| URL 前缀 | `/api/v1/booking/app\|admin/` | 机械替换（步骤 2）；BFF 数量变化走步骤 1 | 目标项目前缀 |
| 迭代号 | `2026-S01`、`2026-S02`（`{年}-S{序号}`） | 机械替换（步骤 2） | 目标迭代约定（`backend/config/current-sprint` 同步改） |
| 技术栈 | Java 21 / Spring Boot 3.2 / Maven / MyBatis / MySQL / Redis | 重写（步骤 3）——换栈时改 rule，不是替换字符串 | 目标栈；对应 `rules/java-project.md`、`mybatis-conventions.md`、`tdd-project-conventions.md`、`integration-test-conventions.md` 须重写 |
| 测试基建 | `booking-app` 下 `*IT`、Testcontainers MySQL、`mvn -pl <module> test` | 重写（步骤 3）——落点与命令随模块结构变 | 目标项目集成测试落点与命令 |

**替换边界**（防过度替换，对 AI 同样生效）：判断标准是「删掉这条锚点，Skill 还能不能执行」。

| 必须替换（删了不能执行） | 保留（删了仍能执行，只是少了例子） |
|--------------------------|-----------------------------------|
| 模块清单、包名、公共库、错误码号段、URL 前缀、测试账号、构建命令 | Skill 正文的业务示例（车位、订单、支付）、Golden 样例文件名、「模板版说明」元描述 |

把业务示例一起换掉，会得到「新前缀 + 旧业务路径」的混搭（`/api/v1/love/app/pay/callback`），比不替换更难排查。

**验收命令**（流程 4）：

```bash
# 在模板根目录执行（范围含 .sh/.py，排除 _golden 样例目录）
grep -rn --include="*.md" --include="*.sh" --include="*.py" "停车预订\|parking-booking\|华智\|河玛" backend/ frontend/ | grep -v "_golden"
# 预期：无输出（golden 样例保留源项目业务名，属豁免）

grep -rn "booking\|hema\|2026-S" backend/skills/ backend/rules/
# 预期：输出应全部是上表已声明的示例值；出现表外形态才需处理。
# 注意 "schema" 含 "hema" 子串属误报，可加 grep -v schema 排除。
```

### 3. 重写 Golden

本步由 AI 执行：AI 从画像（§二 域清单）与词表选取真实业务域，构造「查询-分配」同族用例（源项目为 query-allocate-space 一族），保持文件名模式与结构，把 `docs/**/_golden/` 下 12 个样例用本项目业务重写一遍，提交人验收——Golden 的价值是「标准长什么样」，不是「别人的业务长什么样」。画像与词表仍为占位、构造不出可信场景时，降级为人工指定场景后再重写。

### 4. 分发到 Agent（AI 执行，人告知所用 Agent）

本步由 AI 执行：人告知所用 Agent 与目标目录，AI 按该 Agent 的技能/规则目录约定完成分发与格式适配，跑校验器验证。

**AI 任务**：

1. **分发资产（按线）**：后端线 = `skills/` + `rules/` + `templates/`（至少含 `code-review-report.md`、`stage-review-report.md`）+ 可选 `hooks/`；前端线 = `skills/` + `rules/` + `templates/`，不依赖 `backend/` 路径。
2. **格式适配（按所用 Agent 的约定）**：技能放技能目录、规则放规则目录；Agent 对规则有格式要求时适配——如 Cursor 需转 `.mdc` 并加回 frontmatter（description + globs/alwaysApply），纯 markdown 可直接读的 Agent 原样落位。拿不准该 Agent 的目录约定时问人，不猜。
3. **不变约束**：① 不用 symlink 做多 Agent 镜像——Windows 无特权检出时 symlink 物化成路径文本文件，镜像静默失效（源项目实测教训），多 Agent 用 CI 拷贝同步；② 代码审查不绑定 Agent——审查人可为独立 AI 会话、专用审查 agent、人或 CI 工具，统一使用 `rules/code-review.md` §三 的任务书；③ hooks 按 [backend/hooks/README.md](backend/hooks/README.md) 注册，`PROTECTED` 先改保护路径，前端线复用同机制、路径改前端公共组件目录。
4. **验证**：分发后按目标布局调整 `AGENTS.md` 与规则内的相对链接，跑 `bash <线>/scripts/validate-skills.sh`；模板仓库里的 `backend/...` 链接只是示例布局。

### 5. 工作流裁剪（按需）

- **无 QA 团队**：可去掉 QA 专线 4 个 skill（qa-acceptance-case-design / api-blackbox-test / test-data-design / legacy-test-migration 的黑盒部分）——黑盒冒烟由集成测试取代（见 [backend/docs/methodology/test-line.md](backend/docs/methodology/test-line.md) §4.2）。
- **无独立前端仓**：忽略前端协作章节。
- **存量项目无历史用例**：去掉 legacy-test-migration。
- 裁剪后跑对应线 `bash scripts/validate-skills.sh`，清掉对被裁 skill 的引用。

## 二、接入后验收

1. 两个校验器均 **PASSED**：`bash backend/scripts/validate-skills.sh`、`bash frontend/scripts/validate-skills.sh`（WARN 逐条确认是「提及目标项目文件」而非真断链）。
2. 后端线挑一个真实小需求走通：journey-scenario-design（或直接 story-splitting）→ detail-design → feature-coding，产出路径与命名符合 `backend/docs/agile/card-naming-conventions.md`。
3. 后端画像 §4.3.4 测试账号表填写后，test-data-design 造一次数验证对齐规则可执行。
4. 跑一张真实卡，确认代码审查报告落盘且结论通过（至少 `REVIEW-CODE-IMPL-*`；含 IT/前端/黑盒/造数时对应 `IT/FE/BB/SEED` 阶段）。
