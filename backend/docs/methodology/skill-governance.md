# Skill 治理：共性与跨 Agent 分发

> 解决两个工程问题：① 多项目间 Skill 的共性/差异如何维护；② 同一套 Skill 如何进入 Cursor / Claude Code / Codex / 国产 Agent。
> 本文是方法论文档；目录布局见 [project-layout.md](../../rules/project-layout.md)，接入步骤见 [MIGRATION.md](../../MIGRATION.md)。

---

## 一、共性 Skill 如何维护与跨项目同步

### 1. 核心结论：三层拆分，不是两层

| 层 | 内容 | 归属 | 换一个同垂直项目是否要改 |
|----|------|------|--------------------------|
| **Core** | 流水线方法、AC/Story 规范、TDD 约束、Skill 骨架 | 模板通用层 | 不改 |
| **Variant** | Java / Spring / MyBatis / Testcontainers 相关 Skill 与 Rule | 模板技术栈层 | 同栈不改；异栈按目标栈重写 |
| **Wrapper** | 路径、模块名、BFF 名、错误码号段、OpenAPI 路径、Golden | 项目层 | 必须改 |

判据：**换一个同垂直项目，这段内容还要不要改？** 不用改 → Core/Variant；一定要改 → Wrapper。

### 2. 为什么不能只拆「通用 Skill + 项目 Skill」两层

- 只有两层时，共性里的技术栈差异只能靠「超级 Skill + if 分叉」或 fork 两份；前者让上下文膨胀、两边都容易做错，后者必然 drift。
- Core/Variant/Wrapper 让「方法」与「技术栈」解耦：同栈项目直接复用 Variant，异栈只重写 Variant，项目事实留在 Wrapper/画像。

### 3. 同步机制（按成熟度递进）

1. **当前：模板整目录复制**。项目把 `AI-Native/` 放进仓库根；升级时只对比替换方法目录（`skills/`、`rules/`、`templates/`、`reference/`、`scripts/`、`docs/methodology`），项目工件、画像、词表、`config/` 不动。
2. **下一步：独立 core 仓 + semver**。Core/Variant 独立发版，项目用 `.ai-native.lock` pin 版本与 exclude 列表。
3. **成熟后：Registry / 网关下发**。公司级 Skill Registry 或 MCP 分发，项目侧只保留 Wrapper。

### 4. 判断标准

| 内容 | 放哪里 |
|------|--------|
| 「双 BFF、禁止自造 Result」 | `AGENTS.md` 摘要 + `rules/java-project.md` 全文 |
| 「详设流程、前置加载表」 | `SKILL.md`（按需加载，省 context） |
| 「MyBatis 只写 XML」 | `rules/mybatis-conventions.md` + Skill 引用 |
| 项目模块名、错误码号段、OpenAPI 路径 | `architecture/system-landscape.md`（唯一来源） |

---

## 二、Skill 如何进不同编程 Agent

### 1. 两个互补标准

| 层次 | 标准 | 作用 | 加载方式 |
|------|------|------|----------|
| 持久项目上下文 | `AGENTS.md` | 每 Session 常驻：架构、命令、约束 | Always-on，多工具共读 |
| 按需流程能力 | `SKILL.md` | 特定任务操作规程 | Task-matched 激活 |
| IDE 特化 | `.cursor/rules/*.mdc` | Cursor 的 globs / alwaysApply | Cursor 专有 |

`AGENTS.md` 与 `SKILL.md` 由开放标准推动；Codex、Cursor 2.4+、Claude Code、Copilot、Gemini CLI 等已支持 `SKILL.md`。

### 2. 各 Agent 的路径差异

| Agent | Skill 路径 | 项目上下文 |
|-------|-----------|-----------|
| Codex / 开放生态 | `.agents/skills/{name}/SKILL.md` 或 Agent 指定目录 | `AGENTS.md` |
| Claude Code | `.claude/skills/{name}/SKILL.md` | `CLAUDE.md`（可 `@import AGENTS.md`） |
| Cursor | `.cursor/skills/{name}/SKILL.md` | `AGENTS.md` + `.cursor/rules/*.mdc` |
| GitHub Copilot | `.github/skills/` 或 `.agents/skills/` | `AGENTS.md` |
| 国产 Agent | 多数兼容 `AGENTS.md`；Skill 支持参差 | 需逐个验证 |

> 本模板的 canonical 是 `AI-Native/backend/skills/` 与 `AI-Native/backend/rules/`；上表是**分发目标**，不是模板内的存放位置。

### 3. 分发原则（模板版）

- **不把 symlink 作为多 Agent 镜像**：Windows 无特权检出时 symlink 会物化成路径文本文件，镜像会静默失效（源项目实测）；用复制或 CI 同步。
- **Rule 保持纯 Markdown**：`AI-Native/backend/rules/*.md` 是唯一来源；Cursor 需要时在分发阶段转 `.mdc` 并补 `description` / `globs` / `alwaysApply`，不要把流程逻辑锁进 `.mdc`。
- **Skill 自包含**：`SKILL.md` + `templates/` + `references/` 同目录；分发到目标 Agent 时整目录复制。
- **项目上下文只写一份**：`AGENTS.md` 常驻摘要；项目事实（模块、集成、号段、URL）只写 `architecture/system-landscape.md`，Skill/Rule 引用不复制。
- **迭代号单一来源**：`AI-Native/backend/config/current-sprint`；不要在各 Skill 里散落硬编码迭代号。

### 4. 三种分发通道

| 通道 | 适合 | 说明 |
|------|------|------|
| **A. Repo 内复制 / CI 同步**（推荐主路径） | 零依赖、Git 可审计、离线可用 | 当前模板采用 |
| **B. Git submodule / npm-style 包** | 严格版本 pin、多团队 | 需要额外工具链 |
| **C. MCP Skills 远程分发** | 公司级 Registry、跨 IDE 统一下发 | 标准化成熟后再用 |

### 5. 国产 Agent 策略

1. `AGENTS.md` 作最低公分母——几乎所有工具都能读一个 Markdown。
2. Skill 正文保持纯 Markdown + YAML frontmatter，避免 Cursor 专有语法。
3. `.mdc` 只放 Cursor 增强（globs / alwaysApply），不把流程逻辑锁在 mdc。
4. 不支持的 Agent：CI 生成 flatten 版 `AGENTS.md`（Skill 摘要 inline，控制在 200 行内）。

### 6. 第二条路径：大模型网关注入

编程 Agent（Cursor / Claude Code）不会因为仓库里有 Skill 目录就自动在 API 请求里带 `skills` 字段——那通常是 IDE 本地读文件。网关注入要生效，需满足其一：

1. **流量走公司网关**（Cursor Base URL 指向 LiteLLM 等），网关按路由 / API Key / 用户角色 prepend Skill；
2. Harness 显式支持传 `container.skills` 等字段。

直连个人 Key、流量不过网关时，仍以 Repo 内复制/CI 分发为准。

---

## 三、落地优先级（模板）

### P0（当前）

1. `AI-Native/backend/skills/` + `rules/` 作为 canonical，Skill 自包含。
2. 两条线 `scripts/validate-skills.sh` 接入 CI：硬链失败、frontmatter 缺失、Story 审查门禁。
3. 分发用复制/CI，不用 symlink；Cursor 的 `.mdc` 在分发阶段生成。

### P1（1–2 月）

4. 独立 core 仓 + semver；项目 `.ai-native.lock` pin 版本与 exclude。
5. 各 Skill 补中性 `examples/`（领域无关样例），与项目 Golden 解耦。
6. 内部 `ai-native sync` CLI，减少手工复制。

### P2（3–6 月）

7. Core/Variant 注册到 LiteLLM `/skills` 或内部网关 DB。
8. MCP Skills 分发（标准成熟后）。
9. 新增 Agent 时更新本文路径表，不单独维护适配矩阵。

---

## 一句话

**方法留在 Core，技术栈差异留在 Variant，项目事实留在 Wrapper；分发靠复制/CI，不靠 symlink。**
