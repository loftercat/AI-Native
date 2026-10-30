# AI Native 架构说明（C 端小程序）

> 本文描述已落地的源项目前端仓的 AI Native 工程方法论：Skill 流水线、文档资产、小程序代码分层。  
> 系统画像见 [`architecture/system-landscape.md`](../../architecture/system-landscape.md)。  
> 方法论原型来自已落地的源项目后端仓（`docs/methodology/readme.md`），按微信小程序原生技术栈特化。

---

## 1. 定位：两条主线

| 主线 | 目的 | 主要目录 |
|------|------|----------|
| **方法论流水线** | 用 Agent Skill + Rule + 文档契约，把「需求 → 设计 → 代码 → 测试」做成可重复、可审计的流程 | `skills/`、`rules/`、`docs/` |
| **可运行小程序** | 微信小程序原生工程实现车主端预约 UI | `pages/`、`components/`、`api/`、`app.*` |

方法论精华迁移自后端 Java 仓；Skill 与 Rule 已按 **微信小程序原生（wxml/wxss/wxss + 微信开发者工具）** 特化。

---

## 2. 方法论总体架构

```text
                    ┌─────────────────────────────────────┐
                    │         横切 Rule（rules/）    │
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
| **样例层** | `docs/requirements/_golden/`（按需补） | Few-shot |

### 2.2 配置与敏捷底座

| 资产 | 路径 | 作用 |
|------|------|------|
| 当前迭代 | `config/current-sprint` | 单一事实源（如 `2026-S01`） |
| 卡片命名 | 见后端 `docs/agile/card-naming-conventions.md`；前端用 `STORY-FE-*` / `DD-FE-*` |
| 领域词表 | `glossary/domain-glossary.md` | 与后端术语一致 |
| 系统画像 | `architecture/system-landscape.md` | 模块边界、集成、URL、技术栈（**权威**） |

---

## 3. Skill 职责与边界

| Skill | 输入 | 产出 | 不做 |
|-------|------|------|------|
| **frontend-story-splitting** | Epic/PRD/原型 + 后端 OpenAPI + 后端 Story 摘要 | `STORY-FE-*.md`（AC/BR + 本卡 operationId 范围） | 改 OpenAPI、写后端代码 |
| **frontend-detail-design** | STORY-FE + OpenAPI + 原型 | `DD-FE-*.md`（页面状态机、组件树、AC→operationId 映射） | 重新定义 API 契约 |
| **frontend-feature-coding** | STORY-FE + 详设 | 页面/组件 + 测试 | 直连 order/inventory 域、改 OpenAPI |

### 3.1 需求变更

1. **后端 OpenAPI 变更** → 同步 `docs/handoff/` → 更新 `VERSION`
2. **前端 Story**：更新正文 + 「变更记录」
3. **frontend-detail-design**：增量详设，更新 AC→operationId 映射
4. **frontend-feature-coding**：读变更记录 → 改页面/组件/测试

接口/字段/错误码变更 **必须先改后端 OpenAPI**，再更新本仓库。

---

## 4. 应用代码架构（本仓库）

与 `rules/miniprogram-project.md`、`system-landscape.md` §三 一致：

```text
pages/             页面（四同名文件：js/wxml/wxss/json）
  └─ 调 services/ → api/http.js → wx.request → booking-bff-app
components/         自定义组件（跨页复用）
services/           业务逻辑封装（按域：booking/order/payment/nav）
api/
  ├─ http.js        统一 wx.request 封装（code/401/baseUrl 拦截）
  └─ generated/     OpenAPI 生成 client（可选）
utils/             工具函数
config/            环境配置
styles/            公共样式 / Less 变量
images/            静态资源
```

| 层 | 职责 | 典型目录 |
|----|------|----------|
| 页面 | 路由页、交互、状态 | `pages/` |
| 组件 | 跨页复用 UI | `components/` |
| 业务封装 | 按域聚合调用 | `services/` |
| 请求层 | `wx.request` 封装、`code`/401/baseUrl | `api/http.js` |
| OpenAPI client | 强类型 client（可选） | `api/generated/` |

**硬约束**：

- 页面 **只调** `services/` 或 `api/`；**不**在页面直接 `wx.request`
- **只调 BFF**（`/api/v1/booking/app/`）；禁止直连后端域
- 业务成败看 `body.code === 200`
- 性能：setData 合并/低频；`onUnload` 解绑事件/清定时器（见 `rules/miniprogram-performance.md`）

---

## 5. 文档工件与路径契约

迭代标识：`{年}-S{两位序号}`（如 `2026-S01`）。

| 工件 | 路径模式 |
|------|----------|
| 前端 Story | `docs/requirements/{迭代}/STORY-FE-{迭代}-{序号}-{slug}.md` |
| 前端详设 | `docs/design/{迭代}/DD-FE-{迭代}-{序号}-{slug}.md` |
| 后端 OpenAPI（handoff 副本） | `docs/handoff/openapi/booking-bff-app.yaml` |
| 契约版本 | `docs/handoff/VERSION` |
| 词表 | `glossary/domain-glossary.md` |

---

## 6. 与后端方法论的差异

| 维度 | 后端仓（Java） | 本仓库（小程序） |
|------|----------------|------------------|
| 运行时 | Spring Boot 单体 | 微信小程序运行时 |
| 分层 Rule | `rules/java-project.md` | `rules/miniprogram-project.md` |
| 测试 | JUnit 5 + `mvn test` | jest（utils/services）+ 开发者工具预览（页面） |
| 契约来源 | 自产 OpenAPI | **消费**后端 handoff OpenAPI |
| 跨域 | `@Autowired XxxApi` | 仅 HTTP 调 BFF |
| 性能关注 | JVM | setData / 内存 / 分包 |

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

---

## 变更记录

| 日期 | 变更 |
|------|------|
| 2026-08-01 | 初版：从后端 AI Native 方法论迁移；按微信小程序原生技术栈特化 |
