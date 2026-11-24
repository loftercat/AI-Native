# AI Native 架构说明（前端线）

> 本文描述前端仓的 AI Native 工程方法论：Skill 流水线、文档资产、小程序代码分层。
> 系统画像见 [`architecture/system-landscape.md`](../../architecture/system-landscape.md)。
> 方法论与后端微服务线衔接，按微信小程序原生技术栈特化。

---

## 1. 定位：两条主线

| 主线 | 目的 | 主要目录 |
|------|------|----------|
| **方法论流水线** | 用 Agent Skill + Rule + 文档契约，把「需求 → 设计 → 代码 → 测试」做成可重复、可审计的流程 | `skills/`、`rules/`、`docs/` |
| **可运行小程序** | 微信小程序原生工程实现业务 UI | `pages/`、`components/`、`api/`、`app.*` |

Skill 与 Rule 按 **微信小程序原生（wxml/wxss/js + 微信开发者工具）** 特化；所有项目专属值（契约文件名、baseUrl、成功判据与错误码）集中定义在 `architecture/system-landscape.md`。

---

## 2. 方法论总体架构

```text
                    ┌─────────────────────────────────────┐
                    │         横切 Rule（rules/）         │
                    │  miniprogram-project / performance  │
                    │  api-client / error-display         │
                    └─────────────────┬───────────────────┘
                                      │ 约束所有 Skill 产出
    Epic/PRD/原型 + 后端 OpenAPI handoff
                         │
                         ▼
              frontend-story-splitting ──► STORY-FE-*.md（AC + operationId 范围）
                         │
                         ▼
              frontend-detail-design  ──► DD-FE-*.md（页面状态机、组件树、AC→operationId）
                         │
                         ▼
              frontend-feature-coding ──► 页面/组件 + 测试
```

### 2.1 四层资产模型

| 层级 | 路径 | 职责 |
|------|------|------|
| **执行层** | `skills/*/SKILL.md` | Agent 运行时步骤：加载什么、写什么、何时阻断 |
| **横切层** | `rules/*.md` | 编码与文档规范；Skill 引用 Rule，不重复全文 |
| **配套层** | `skills/{skill}/`（自包含，按需补配套层） | 模板、粒度指引 |
| **样例层** | `docs/{requirements,design}/_golden/` | Few-shot（接入时按本项目重写） |

### 2.2 配置与敏捷底座

| 资产 | 路径 | 作用 |
|------|------|------|
| 当前迭代 | `config/current-sprint` | 单一事实源（`{YYYY-Snn}`） |
| 卡片命名 | 后端 `docs/agile/card-naming-conventions.md` | 前端用 `STORY-FE-*` / `DD-FE-*` |
| 领域词表 | `glossary/domain-glossary.md` | 与后端术语一致 |
| 系统画像 | `architecture/system-landscape.md` | 路由边界、契约文件、baseUrl、鉴权与技术栈（**权威**） |

---

## 3. Skill 职责与边界

| Skill | 输入 | 产出 | 不做 |
|-------|------|------|------|
| **frontend-story-splitting** | Epic/PRD/原型 + 后端 OpenAPI + 后端 Story 摘要 | `STORY-FE-*.md`（AC/BR + 本卡 operationId 范围） | 改 OpenAPI、写后端代码 |
| **frontend-detail-design** | STORY-FE + OpenAPI + 设计稿 | `DD-FE-*.md`（页面状态机、组件树、AC→operationId 映射） | 重新定义 API 契约 |
| **frontend-feature-coding** | STORY-FE + 详设 | 页面/组件 + 测试 | 直连后端领域微服务、改 OpenAPI |

### 3.1 需求变更

1. **后端 OpenAPI 变更** → 同步 `docs/handoff/` → 更新 `VERSION`
2. **前端 Story**：更新正文 + 「变更记录」
3. **frontend-detail-design**：增量详设，更新 AC→operationId 映射
4. **frontend-feature-coding**：读变更记录 → 改页面/组件/测试

接口/字段/错误码变更 **必须先改后端 OpenAPI**，再更新本仓库。

---

## 4. 应用代码架构

与 `rules/miniprogram-project.md`、`system-landscape.md` §三 一致：

```text
pages/             页面（四同名文件：js/wxml/wxss/json）
  └─ 调 services/ → api/http.js → wx.request → {后端BFF服务}
components/         自定义组件（跨页复用）
services/           业务逻辑封装（按业务域目录划分：`{domain}/`）
api/
  ├─ http.js        统一 wx.request 封装（成功判据/401/baseUrl 拦截）
  └─ generated/     OpenAPI 生成 client（可选）
utils/             工具函数
config/            环境配置
styles/            公共样式 / Less 变量
images/            静态资源
```

**硬约束**：

- 页面 **只调** `services/` 或 `api/`；**不**在页面直接 `wx.request`
- **只调 BFF**（`baseUrl` 以画像 §四 为准）；禁止直连后端领域微服务
- 业务成败判据以画像 §四 为准（对齐后端画像 §3.7）
- 性能：setData 合并/低频；`onUnload` 解绑事件/清定时器（见 `rules/miniprogram-performance.md`）

---

## 5. 文档工件与路径契约

迭代标识：`{年}-S{两位序号}`（如 `{YYYY-Snn}`）。

| 工件 | 路径模式（前端 Story/详设/审查报告相对前端工程根 `docs/`；handoff 快照与词表相对线根 `AI-Native/frontend/`） |
|------|----------|
| 前端 Story | `docs/requirements/{迭代}/STORY-FE-{迭代}-{序号}-{slug}.md` |
| 前端详设 | `docs/design/{迭代}/DD-FE-{迭代}-{序号}-{slug}.md` |
| 后端 OpenAPI（handoff 副本） | `docs/handoff/openapi/{后端BFF服务标识}.yaml` |
| 契约版本 | `docs/handoff/VERSION` |
| 词表 | `glossary/domain-glossary.md` |

---

## 6. 与后端方法论的差异

| 维度 | 后端线（Java 微服务） | 前端线（小程序） |
|------|-----------------------|------------------|
| 运行时 | Spring Boot / Spring Cloud 微服务群 | 微信小程序运行时 |
| 分层 Rule | `rules/java-project.md` | `rules/miniprogram-project.md` |
| 测试 | JUnit 5 + Mockito + Testcontainers + `mvn test` | jest（utils/services）+ 开发者工具预览（页面） |
| 契约来源 | 自产对外/对内接口契约 | **消费**后端 handoff OpenAPI |
| 跨服务调用 | 远程协议（画像 P-2） | 仅 HTTP 调 BFF（经 API 网关） |
| 性能关注 | JVM / DB / 远程调用 | setData / 内存 / 分包 |

---

## 7. 延伸阅读

| 主题 | 文档 |
|------|------|
| AI 入口 | [frontend/README.md](../../README.md) |
| 系统画像 | [architecture/system-landscape.md](../../architecture/system-landscape.md) |
| 目录与命名 | [rules/miniprogram-project.md](../../rules/miniprogram-project.md) |
| 性能与内存 | [rules/miniprogram-performance.md](../../rules/miniprogram-performance.md) |
| 请求层 | [rules/api-client-conventions.md](../../rules/api-client-conventions.md) |
| 后端方法论 | 后端仓 `docs/methodology/readme.md` |
