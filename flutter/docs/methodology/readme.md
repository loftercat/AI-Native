# AI Native 架构说明（Flutter Android / iOS）

接入步骤与两个确认点见 [MIGRATION.md](../../MIGRATION.md)。本线沿用前端三段 Skill、阶段工件和独立代码审查，不增设 Story/DD 审查阶段。项目事实记录在[系统画像](../../architecture/system-landscape.md)。

## 1. 定位：两条主线

| 主线 | 目的 | 主要目录 |
|------|------|----------|
| **方法论流水线** | 用 Agent Skill + Rule + 文档契约，把「需求 → 设计 → 代码 → 测试」做成可重复、可审计的流程 | `skills/`、`rules/`、`docs/` |
| **可运行应用** | 在接入项目实现 Android / iOS 功能 | `lib/`、`android/`、`ios/`、`test/` |

## 2. 方法论总体架构

```text
                    ┌─────────────────────────────────────┐
                    │         横切 Rule（rules/）    │
                    │  flutter-project / performance  │
                    │  api-client / error-display         │
                    └─────────────────┬───────────────────┘
                                      │ 约束所有 Skill 产出
    Epic/PRD/原型 + 后端 OpenAPI handoff
                         │
                         ▼
              flutter-story-splitting ──► STORY-Flutter-*.md（AC + operationId 范围）
                         │
                         ▼
              flutter-detail-design  ──► DD-Flutter-*.md（页面状态机、组件树、AC→operationId）
                         │
                         ▼
              flutter-feature-coding ──► 页面/组件 + 测试
                         │
                         ▼
              独立代码审查 ──► REVIEW-CODE-Flutter-*（联调/提测前）
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
| 卡片命名 | 本文 §5 的路径模式 | 与前端同结构，使用 `STORY-Flutter-*` / `DD-Flutter-*` |
| 领域词表 | `glossary/domain-glossary.md` | 与后端术语一致 |
| 系统画像 | `architecture/system-landscape.md` | 模块边界、集成、URL、技术栈（**权威**） |

---

## 3. Skill 职责与边界

| Skill | 输入 | 产出 | 不做 |
|-------|------|------|------|
| **flutter-story-splitting** | Epic/PRD/原型 + 适用的后端交接包 + 可选 Story 摘要 | `STORY-Flutter-*.md`（AC/BR + 本卡 operationId 范围） | 改 OpenAPI、写后端代码 |
| **flutter-detail-design** | STORY-Flutter + OpenAPI + 设计稿 | `DD-Flutter-*.md`（页面状态机、组件树、AC→operationId 映射） | 重新定义 API 契约 |
| **flutter-feature-coding** | STORY-Flutter + 详设 | 页面/组件 + 测试 | 直连 order/inventory 域、改 OpenAPI |

### 3.1 需求变更

1. **后端 OpenAPI 变更** → 后端重新发布 → Flutter 整包同步到 `docs/handoff/`
2. **客户端 Story**：更新正文 + 「变更记录」
3. **flutter-detail-design**：增量详设，更新 AC→operationId 映射
4. **flutter-feature-coding**：读变更记录 → 改失败测试 → 改页面/组件 → 验证与独立代码审查

接口/字段/错误码变更 **必须先改后端 OpenAPI**，再更新本仓库。

---

无后端调用的卡以本地交互/存储或原生 SDK 约定作为输入，契约填 `N/A`；含网络 AC 的卡不因本地部分可做而跳过 handoff。模板没有随附真实契约，待补行为见 [handoff](../handoff/README.md)。

## 4. 应用代码架构（接入项目）

按[工程规则](../../rules/flutter-project.md)组织代码，以画像记录的真实目录为准。

| 层 | 职责 | 目录示例 |
|---|---|---|
| 页面与 Widget | 渲染状态并提交用户操作 | lib/features/{feature}/presentation |
| ViewModel | 处理操作、异步状态及副作用 | presentation/view_models |
| Repository / Service | 组织数据，调用本地存储或远端契约 | lib/features/{feature}/data |
| HTTP 客户端 | 鉴权、取消、错误转换 | lib/core/network |
| 原生适配 | 将类型化 Dart 接口映射到 Android / iOS SDK | Android / iOS 插件或宿主目录 |

网络 AC 只使用本卡 operationId，纯本地 AC 引用交互及持久化约定。SDK 类 AC 在同一张 DD 记录双端契约及验证方式。

## 5. 文档工件与路径契约

迭代标识：`{年}-S{两位序号}`（如 `2026-S01`）。

| 工件 | 路径模式（Story、详设与审查报告相对应用根，其余相对线根） |
|------|----------|
| 客户端 Story | `docs/requirements/{迭代}/STORY-Flutter-{迭代}-{序号}-{slug}.md` |
| 客户端详设 | `docs/design/{迭代}/DD-Flutter-{迭代}-{序号}-{slug}.md` |
| 审查报告 | `docs/reviews/{迭代}/` |
| 后端 OpenAPI（handoff 副本） | `docs/handoff/openapi/booking-bff-app.yaml` |
| 契约版本 | `docs/handoff/VERSION` |
| 词表 | `glossary/domain-glossary.md` |

---

## 6. 与后端方法论的差异

| 维度 | 后端仓（Java） | Flutter 客户端 |
|------|----------------|------------------|
| 运行时 | Spring Boot 单体 | Flutter 引擎、Android/iOS 宿主 |
| 分层 Rule | `rules/java-project.md` | `rules/flutter-project.md` |
| 测试 | JUnit 5 + `mvn test` | flutter test、Widget / 集成测试与真机验证 |
| 契约来源 | 自产 OpenAPI | **消费**后端 handoff OpenAPI |
| 跨域 | `@Autowired XxxApi` | 仅 HTTP 调 BFF |
| 性能关注 | JVM | 帧耗时、内存、启动与包体积 |

---

## 7. 延伸阅读

| 主题 | 文档 |
|------|------|
| AI 入口 | [flutter/README.md](../../README.md) |
| 系统画像 | [architecture/system-landscape.md](../../architecture/system-landscape.md) |
| 目录与命名 | [rules/flutter-project.md](../../rules/flutter-project.md) |
| 性能与内存 | [rules/flutter-performance.md](../../rules/flutter-performance.md) |
| 请求层 | [rules/api-client-conventions.md](../../rules/api-client-conventions.md) |
| 后端方法论 | 后端仓 `docs/methodology/readme.md` |

---

## 变更记录

| 日期 | 变更 |
|------|------|
| 2026-11-17 | 与前端阶段顺序、设计稿追溯及独立审查对齐。 |
