# AI Native 使用手册：前端线

> 本手册说明在接入前端工作流模板后，如何用三个 AI Skill 完成 **需求拆解 → 详细设计 → 编码** 全流程，并给出可直接复制的提示词模板。所有项目专属值（契约文件、baseUrl、成功判据、错误码号段）均以 `architecture/system-landscape.md` §四 为准。
>
> 配套：[frontend/README.md](README.md) · [docs/methodology/readme.md](docs/methodology/readme.md) · [architecture/system-landscape.md](architecture/system-landscape.md)

---

## 快速导航

| 我想… | 看 |
|--------|----|
| 看总览 | [总览](#总览) |
| 确认开工前提 | [前置准备](#前置准备) |
| 看需求拆解 | [需求拆解](#需求拆解) |
| 看详细设计 | [详细设计](#详细设计) |
| 看编码 | [编码](#编码) |
| 看端到端流程示例 | [端到端流程示例](#端到端流程示例) |
| 查提示词通用模板 | [提示词通用模板](#提示词通用模板) |
| 看反模式 | [常见反模式](#常见反模式) |
| 查文件落点 | [文件落点速查](#文件落点速查) |
| 延伸阅读 | [延伸阅读](#延伸阅读) |

---

## 总览

```text
Epic/PRD/原型 + 后端 OpenAPI handoff
        ↓
frontend-story-splitting   →  STORY-FE-*.md（AC + 本卡 operationId 范围）
        ↓
frontend-detail-design      →  DD-FE-*.md（页面状态机、组件树、AC→operationId 映射）
        ↓
frontend-feature-coding     →  pages/ components/ services/ + 测试
        ↓
代码审查（rules/code-review.md）→ REVIEW-CODE-FE-*（联调/提测前）
```

| Skill | 做什么 | 产出 | 不做什么 |
|-------|--------|------|----------|
| `frontend-story-splitting` | 把需求拆成可验收的前端 Story | `docs/requirements/{迭代}/STORY-FE-*.md` | 详设、代码、改 OpenAPI |
| `frontend-detail-design` | 把 Story 转成页面详设 | `docs/design/{迭代}/DD-FE-*.md` | 改 Story、写代码 |
| `frontend-feature-coding` | TDD 实现页面/组件 | `pages/`/`components/`/`services/` + 测试 | 拆卡、详设、改 OpenAPI |

**核心原则**：

1. **接口语义只认 OpenAPI**（`docs/handoff/openapi/{后端BFF服务标识}.yaml`）；前端不得发明字段/错误码
2. **每张前端 Story 必须点名本卡 `operationId`**，不能只丢整份 YAML
3. **只调 BFF**（`baseUrl` 与成功判据以画像 §四 为准）；严禁直连后端领域微服务
4. **性能**：setData 合并低频、`onUnload` 解绑监听/清定时器（见 `rules/miniprogram-performance.md`）
5. **设计稿登记**：视觉项在 STORY-FE「设计稿」节登记稿件位置与状态；无稿才标 `UI: TBD`，不允许整卡视觉项全留空

### 三段输入一览

| Skill | 关键输入 | 产出 |
|-------|----------|------|
| story-splitting | 后端 OpenAPI + 契约版本 + Epic/PRD/原型 + **后端 Story 摘要** | STORY-FE-*.md（含「设计稿」节） |
| detail-design | 前端 Story + 后端 OpenAPI + 设计稿（按卡登记） + Rule | DD-FE-*.md |
| feature-coding | 前端 Story + 前端详设 + 后端 OpenAPI + Rule | pages/components/services + 测试 |

> 详设输入 = 上一段产出 + OpenAPI；编码输入 = 上两段产出 + OpenAPI。OpenAPI 贯穿三段。

---

## 前置准备

```text
1. 当前迭代：config/current-sprint（如 {YYYY-Snn}）
2. 后端契约：docs/handoff/openapi/{后端BFF服务标识}.yaml
3. 契约版本：docs/handoff/VERSION（tag 或 commit SHA）
4. 原型/设计稿：docs/prototype/（或 handoff 登记位置）
```

若 `docs/handoff/VERSION` 为 `TBD`，先从后端同步 OpenAPI 再开工（纯 UI 卡除外——无接口集成时无需等待 OpenAPI 与契约版本）。

---

## 需求拆解

> Skill：`frontend-story-splitting`

### 何时用

- 新 Epic / 迭代规划 / 从 PRD 或后端 Story 拆前端卡
- 需要写 `docs/requirements/{迭代}/STORY-FE-*.md`

### 输入

| 输入 | 必须？ | 来源 | 说明 |
|------|--------|------|------|
| **后端 OpenAPI** | ✅ 必须 | `docs/handoff/openapi/{后端BFF服务标识}.yaml` | 接口字段/错误码/examples 唯一真相；拆卡时检索本页 `operationId` |
| **契约版本** | ✅ 必须 | `docs/handoff/VERSION` | tag 或 commit SHA；联调对齐 |
| **Epic / PRD / 原型** | ✅ 必须有（至少其一） | `docs/requirements/epics/`、`docs/prototype/` | 用户价值与页面范围 |
| **后端 Story 摘要** | ⭐ 强烈推荐 | 后端 `STORY-*` 的 §1 用户故事 + §2.3 前端职责 + 相关 AC/BR | 范围、职责边界、业务规则；**默认只读摘要，整卡作链接** |
| **完整后端详设（DD）** | ◯ 可选 | 后端 `DD-STORY-*` §5 摘录 | OpenAPI 不足时只发 §5；**不必默认发整卡** |
| **领域词表** | ◯ 降级 | `glossary/domain-glossary.md` | 术语一致 |
| **Rule** | ✅ 必读 | `rules/miniprogram-project.md`、`rules/api-client-conventions.md` | 目录/命名/请求层约束 |

### 产出格式

每张 `STORY-FE-*` 必含四节：

```markdown
## 契约
| 项 | 值 |
|----|-----|
| OpenAPI 文件 | docs/handoff/openapi/{后端BFF服务标识}.yaml |
| 契约版本 | {tag 或 commit SHA} |
| baseUrl | {见画像 §四} |

## 本卡 API 范围
| AC | operationId | Method | Path | 说明 |
|----|-------------|--------|------|------|

## 设计稿
| 页面/组件 | 稿件位置 | 状态 |
|-----------|---------|------|
| {页面-区域} | docs/prototype/{稿件文件} | 已定稿 / 草稿 |

- 有稿登记位置与状态；无稿写 `无 → UI: TBD`；纯 UI 卡本节是主要验收依据

## 不在本卡范围
- 列出其它 operationId，防止编码越界
```

### 提示词示例

#### 从后端 Story 拆前端卡

```text
/frontend-story-splitting

后端 Story：STORY-{YYYY-Snn}-{序号}（{功能名称}）
后端 Story 摘要：
- §1 用户故事：{角色与目标}
- §2.3 前端职责：{页面分支、跳转与交互}
- 相关 AC：{AC 列表}

契约：docs/handoff/openapi/{后端BFF服务标识}.yaml @ {VERSION}
本卡涉及的 operationId：{operationIdA}（{METHOD} /{path}）

请拆出前端 Story STORY-FE-{YYYY-Snn}-{序号}，AC 用 Given/When/Then，字段认 OpenAPI examples。
视觉项在「设计稿」节登记稿件位置；无稿才标 UI: TBD。
```

#### 从 PRD + 原型拆卡

```text
/frontend-story-splitting

输入：
- Epic：EPIC-{slug}
- 原型（交互稿）：docs/prototype/{原型文件}
- 契约：docs/handoff/openapi/{后端BFF服务标识}.yaml @ {VERSION}

请拆「{页面能力}」前端 Story，在 openapi.yaml 中检索相关 operation，列出本卡 operationId 范围。
设计稿已定稿的登记到「设计稿」节；后端 Story 尚未拆时标注「后端Story: TBD」。
```

---

## 详细设计

> Skill：`frontend-detail-design`

### 何时用

- `STORY-FE-*` 已定稿，需出页面详设
- 需要写 `docs/design/{迭代}/DD-FE-*.md`

### 输入

| 输入 | 必须？ | 来源 | 说明 |
|------|--------|------|------|
| **前端 Story** | ✅ 必须 | `docs/requirements/{迭代}/STORY-FE-*.md` | 含本卡 operationId 范围 |
| **后端 OpenAPI** | ✅ 必须 | `docs/handoff/openapi/{后端BFF服务标识}.yaml` | 读 schema/examples 设计状态机与字段展示 |
| **契约版本** | ✅ 必须 | `docs/handoff/VERSION` | 与 Story 一致 |
| **设计稿** | ◯ 按 Story 卡登记 | `docs/prototype/{稿件}` | 视觉参考；卡上 `UI: TBD` 项不可猜样式 |
| **系统画像** | ✅ 必读 | `architecture/system-landscape.md` | 路由/分包/集成边界/成功判据 |
| **领域词表** | ◯ 降级 | `glossary/domain-glossary.md` | 术语一致 |
| **Rule** | ✅ 必读 | `rules/miniprogram-project.md`、`rules/api-client-conventions.md`、`rules/error-display-conventions.md`、`rules/miniprogram-performance.md` | 分层/请求/错误/性能约束 |

### 产出必含

1. 路由与页面（路径、分包、tabBar、跳转关系）
2. 组件树与 props（用到的 `components/`）
3. 页面状态机（加载/空/错/成功 + setData 关系）
4. **AC → operationId 映射表**（核心）
5. 错误展示（失败分支的 Toast/Modal/跳转，对齐画像 §四）
6. 性能关注（倒计时/长列表/分包）
7. 设计稿追溯（沿用 Story 卡「设计稿」节登记并逐条核对）

### 提示词示例

```text
/frontend-detail-design

Story：@docs/requirements/{迭代}/STORY-FE-{迭代}-{序号}-{slug}.md
契约：docs/handoff/openapi/{后端BFF服务标识}.yaml @ {VERSION}
设计稿：@docs/prototype/{稿件文件}（按 STORY-FE「设计稿」节登记）

请出 DD-FE-{迭代}-{序号}，含：
- 页面状态机（loading / empty / error / success）
- AC→operationId 映射表（{operationIdA}）
- 错误展示（鉴权失败由 http.js 统一处理；其余业务失败按画像 §四 展示）
- 性能关注（setData 合并低频；含倒计时/监听时明确 onUnload 清理）
- 组件拆分（跨页复用抽入 components/{comp}/）
```

---

## 编码

> Skill：`frontend-feature-coding`

### 何时用

- Story + 详设就绪，开始写代码
- 需求变更后同步实现

### 输入

| 输入 | 必须？ | 来源 | 说明 |
|------|--------|------|------|
| **前端 Story** | ✅ 必须 | `docs/requirements/{迭代}/STORY-FE-*.md` | AC + 本卡 operationId 范围 |
| **前端详设** | ✅ 必须 | `docs/design/{迭代}/DD-FE-*.md` | 页面状态机、组件树、AC→operationId 映射 |
| **后端 OpenAPI** | ✅ 必须 | `docs/handoff/openapi/{后端BFF服务标识}.yaml` | 字段/错误码/examples；**不发明字段** |
| **契约版本** | ✅ 必须 | `docs/handoff/VERSION` | 与 Story/详设一致 |
| **系统画像** | ✅ 必读 | `architecture/system-landscape.md` | 分层/集成边界/成功判据 |
| **Rule** | ✅ 必读 | `rules/miniprogram-project.md`、`rules/miniprogram-performance.md`、`rules/api-client-conventions.md`、`rules/error-display-conventions.md` | 目录/性能/请求/错误 |
| **代码审查规则** | ✅ 必读 | `rules/code-review.md` | 步骤 7 的档位/分级/报告 |
| **实现范围** | ◯ 可选 | 提示词指定 | 全 Story / 指定页 / 指定层 / 指定 AC |
| **领域词表** | ◯ 降级 | `glossary/domain-glossary.md` | 术语一致 |

### 流程

```text
1. 加载 STORY-FE + DD-FE + OpenAPI + 画像 + Rule；按 Story「设计稿」节对照稿件（`UI: TBD` 项向用户要稿，不猜样式）
2. 契约对齐：确认本卡 operationId，读 schema/examples
3. TDD：先写 services/utils 单测，再写页面/组件
4. 实现：pages 调 services，不直接 wx.request
5. 性能自检：setData 合并、onUnload 清理
6. 验证：npm test 全绿 + 开发者工具预览 + AC 逐条对照
7. 代码审查：按 rules/code-review.md 审 diff + STORY-FE/DD-FE/OpenAPI（含设计稿还原）；报告 docs/reviews/{迭代}/REVIEW-CODE-FE-*；L0 跳过并说明
```

---

## 端到端流程示例

### 第 1 段：拆卡

```text
/frontend-story-splitting
后端 Story：STORY-{迭代}-{序号}（摘要：{业务意图与前端职责}）
契约：docs/handoff/openapi/{后端BFF服务标识}.yaml @ {VERSION}
operationId：{operationIdA}
拆 STORY-FE-{迭代}-{序号}，AC 用 Given/When/Then，字段认 OpenAPI examples。
```

### 第 2 段：详设

```text
/frontend-detail-design
Story：@docs/requirements/{迭代}/STORY-FE-{迭代}-{序号}-{slug}.md
契约：docs/handoff/openapi/{后端BFF服务标识}.yaml @ {VERSION}
设计稿：@docs/prototype/{稿件文件}
出 DD-FE-{迭代}-{序号}，含页面状态机 + AC→operationId 映射表 + 错误展示 + 性能关注。
```

### 第 3 段：编码

```text
/frontend-feature-coding 实现 STORY-FE-{迭代}-{序号}
@docs/requirements/{迭代}/STORY-FE-{迭代}-{序号}-{slug}.md
@docs/design/{迭代}/DD-FE-{迭代}-{序号}-{slug}.md
契约：docs/handoff/openapi/{后端BFF服务标识}.yaml @ {VERSION}
仅实现本卡 operationId：{operationIdA}；不引入其它 operationId。
```

---

## 提示词通用模板

```text
{skill 名} {动作} {Story 编号}

@{Story 路径}
@{详设路径}            ← 编码段必填
契约：docs/handoff/openapi/{后端BFF服务标识}.yaml @ {版本}

本卡 operationId：{列出}
设计稿：@{稿件路径}（无稿写 `无 → UI: TBD`）
{特殊约束：性能/范围限制}
不要实现：{排除的 operationId}
```

---

## 常见反模式

| 反模式 | 正确做法 |
|--------|----------|
| 只丢整份 openapi.yaml、不点名 operationId | Story/提示词里明确本卡 operationId |
| 前端 AC 重新定义后端字段名 | 字段只认 OpenAPI schema |
| 页面直接 `wx.request` | 经 `api/http.js` 或 `services/` |
| `setInterval` 倒计时 + 每秒 `setData` | `setTimeout` 递归 + 时间差 |
| `onUnload` 不解绑 `wx.on*`/不清定时器 | onUnload 清理清单 |
| 跨段越界（编码时改 Story/OpenAPI） | 先回 story-splitting/detail-design |
| 401 在页面处理 | 401 统一在 `http.js` |
| 视觉 AC 一律标 `UI: TBD`、不登记设计稿 | 有稿登记 STORY-FE「设计稿」节；无稿才标 TBD |

---

## 文件落点速查

| 工件 | 路径 |
|------|------|
| 前端 Story | `docs/requirements/{迭代}/STORY-FE-{迭代}-{序号}-{slug}.md` |
| 前端详设 | `docs/design/{迭代}/DD-FE-{迭代}-{序号}-{slug}.md` |
| 后端 OpenAPI 副本 | `docs/handoff/openapi/{后端BFF服务标识}.yaml` |
| 契约版本 | `docs/handoff/VERSION` |
| 设计稿 | `docs/prototype/…`（位置登记在 STORY-FE「设计稿」节） |
| 代码审查报告 | `docs/reviews/{迭代}/REVIEW-CODE-FE-STORY-FE-{迭代}-{序号}-{slug}.md` |
| 页面代码 | `pages/{page}/{page}.{js,wxml,wxss,json}` |
| 组件代码 | `components/{comp}/{comp}.{js,wxml,wxss,json}` |
| 业务封装 | `services/{domain}.js` |
| 请求层 | `api/http.js` |
| 单测 | `{file}.test.js`（同目录或 `__tests__/`） |

---

## 延伸阅读

| 主题 | 文档 |
|------|------|
| AI 入口 | [frontend/README.md](README.md) |
| 方法论总览 | [docs/methodology/readme.md](docs/methodology/readme.md) |
| 系统画像 | [architecture/system-landscape.md](architecture/system-landscape.md) |
| 目录与命名 | [rules/miniprogram-project.md](./rules/miniprogram-project.md) |
| 性能与内存 | [rules/miniprogram-performance.md](./rules/miniprogram-performance.md) |
| 请求层 | [rules/api-client-conventions.md](./rules/api-client-conventions.md) |
| 错误展示 | [rules/error-display-conventions.md](./rules/error-display-conventions.md) |
| Skill：拆卡 | [skills/frontend-story-splitting/SKILL.md](./skills/frontend-story-splitting/SKILL.md) |
| Skill：详设 | [skills/frontend-detail-design/SKILL.md](./skills/frontend-detail-design/SKILL.md) |
| Skill：编码 | [skills/frontend-feature-coding/SKILL.md](./skills/frontend-feature-coding/SKILL.md) |
