<!-- 生成说明（生成目标 AGENTS.md 后删除本注释）：
按实际接入线（backend / frontend / flutter，可组合）生成，保留项目已有约束。
替换 {主线} 为已接入的主线。只接 Flutter 时为 flutter，入口指向 AI-Native/flutter/AGENTS.md。
删除未接入线的整段内容、表格行及链接；不要把后端 Java 分层/审查要求带入客户端项目。
“一句话、做什么、不做什么、模块、集成”从已确认画像提炼，不把示例当项目事实。
后端专用的分层示例和约束仅在接后端时保留；客户端按对应画像/Rule填写，不自动改造现有工程。
-->

# {项目名} — 系统画像与 AI 协作者入口

> 完整系统边界、模块清单、集成关系、技术栈见 **`AI-Native/{主线}/architecture/system-landscape.md`**（对应线项目事实唯一来源）。
> 领域术语见 **`AI-Native/{主线}/glossary/domain-glossary.md`**；工程方法论见 **`AI-Native/{主线}/docs/methodology/readme.md`**。
> 本文件是目标项目的 AI 入口，不是模板仓自身的 `AGENTS.md`。

---

## 工作流入口（仅保留已接入行）

| 线 | 开始工作 | 项目事实 |
|----|----------|----------|
| 后端 | `AI-Native/backend/USAGE.md` | `AI-Native/backend/architecture/system-landscape.md` |
| 前端 | `AI-Native/frontend/USAGE.md` | `AI-Native/frontend/architecture/system-landscape.md` |
| Flutter | 先读 `AI-Native/flutter/AGENTS.md`，再按 `AI-Native/flutter/USAGE.md` 选择 Skill | `AI-Native/flutter/architecture/system-landscape.md` |

工作流文档的 `docs/`、`skills/`、`rules/`、`templates/`、`config/` 等路径以对应 `AI-Native/{线}/` 为基准；Markdown 链接按所在文件解析。业务代码和测试使用各线画像登记的工程根，Flutter 应用根见画像 §3.2。

## 一句话

**{项目名}**（`{仓库名}`）— {一句话说明业务形态与技术形态，例如：支撑 XX 业务的 Java 单体后端，BFF 服务 C 端，域模块同 JVM}。

---

## 做什么

| 范围 | 内容 |
|------|------|
| **C 端 / 用户侧** | {入口 → BFF → 核心能力} |
| **B 端 / 管理侧** | {入口 → BFF → 管理能力} |
| **核心域** | {域模块清单与职责} |
| **服务形态** | {单体 / 多模块 / 部署单元} |
| **技术栈** | {语言、框架、ORM、缓存、消息、测试框架} |

---

## 不做什么（当前阶段）

- ❌ {明确排除项 1}
- ❌ {明确排除项 2}
- ❌ {明确排除项 3}

---

## 模块与分层

> 下列为后端示例；仅接客户端时以对应画像的模块/组件/数据层摘要替换整节。

```text
对外 HTTP（仅 BFF）
  {bff-app} / {bff-admin}  →  Controller + 鉴权 Filter

域边界（契约 + 实现）
  {domain}-api   →  XxxApi + DTO（无业务实现、无 Controller）
  {domain}-impl  →  app/provider → facade → service → infrastructure

启动
  {app-module} → @SpringBootApplication，唯一 main，聚合上述模块
```

| 模块 | 职责 |
|------|------|
| `{module-1}` | {职责} |
| `{module-2}` | {职责} |
| `{common}` | 横向抽象与错误码 |

> 完整模块表（含路径、服务标识、部署形态）以 `AI-Native/backend/architecture/system-landscape.md` §二为准；本表只做摘要，不重复维护。

**跨域调用**：BFF 与其它域之间 `@Autowired XxxApi`，经 `*-impl/app/client` 封装；禁止 BFF 或其它域直接依赖 `*-impl` 内部 Service/Mapper。

---

## 外部集成

| 系统 | 本仓库侧 | 说明 |
|------|----------|------|
| {外部系统 1} | `{client 接口}` | {职责与边界} |
| {外部系统 2} | `{gateway 接口}` | {职责与边界} |

> 完整集成矩阵见 `AI-Native/backend/architecture/system-landscape.md` §四。

---

## 后端编码约束（仅接 backend 时保留）

1. **HTTP 只在 BFF**：禁止在 BFF 写核心状态机；域逻辑在 `*-impl`。
2. **api/impl 分离**：`*-api` 只放契约与 DTO，业务实现在 `*-impl`。
3. **域间调用**：V1 同 JVM 直调 `XxxApi`，经 `app/client` 封装；不引入 OpenFeign/Nacos（除非架构变更）。
4. **统一响应**：以 `AI-Native/backend/architecture/system-landscape.md` §3.7「公共基础库锚点」为准；业务成败看 `code === 成功码`。
5. **错误码号段**：以画像 §3.7 号段表为准；域错误码放 `*-api`，BFF 守卫错误码放 `common`。
6. **禁止造轮子**：不得自定义 `Result` / `BizException` / `ErrorCode` / `GlobalExceptionHandler` / `PageResult` / `PageQuery` / 雪花 ID 生成器；一律复用项目公共库。
7. **数据访问**：ORM 为 `{MyBatis}`；主键查询可用 `{MyBatis Plus}`，其余 SQL 只写在 XML。
8. **文档中文，代码标识符英文**；保持 diff 小。

---

## 客户端编码约束（仅接对应线时保留）

- 前端按 `AI-Native/frontend/rules/miniprogram-project.md` 组织页面和请求层。
- Flutter 按 `AI-Native/flutter/architecture/system-landscape.md` §3.1 与 `AI-Native/flutter/rules/flutter-project.md` 实现；业务代码、测试和 Flutter 命令使用 §3.2 的应用根。
- 接口只认对应线 handoff 快照与 VERSION；只用本卡 operationId，不直接修改 OpenAPI。网络卡遇到缺失或 `TBD`，先补齐后端契约；无后端依赖的卡按该线 Skill 豁免。
- 设计稿、平台差异和测试依据沿用 Story / DD 登记；规范听 Rule，流程听 Skill。

## AI Native 流水线

### 后端（仅接 backend 时保留）

```text
业务原始需求 → JSD → Epic/PRD → HLD → Story → DD + OpenAPI + schema → TS → feature-coding
                                                        ↓
                                          代码审查 → integration-test-design（*IT）
                                                        ↓
                              QA：AC-STORY → api-blackbox-test / test-data-design
```

| Skill | 用途 |
|-------|------|
| `journey-scenario-design` | 原始需求 → JSD |
| `high-level-design` | Epic/PRD → HLD |
| `story-splitting` | HLD/Epic → Story（AC/BR） |
| `detail-design` | Story → DD + OpenAPI + schema + 骨架 |
| `test-spec-alignment` | Story + DD §9 → TS |
| `feature-coding` | TDD 实现 |
| `integration-test-design` | 白盒集成/场景测试 |
| `qa-acceptance-case-design` / `api-blackbox-test` / `test-data-design` | QA 专线（可选） |
| `legacy-test-migration` / `bugfix` | 按需触发 |

> 完整 Skill 清单与栈依赖见 `AI-Native/backend/Skill清单与栈依赖.md`；本表只做入口摘要，不维护完整清单。

---

### 前端（仅接 frontend 时保留）

`frontend-story-splitting` → STORY-FE → `frontend-detail-design` → DD-FE → `frontend-feature-coding` → 代码 + 测试 → 独立代码审查。

### Flutter（仅接 flutter 时保留）

`flutter-story-splitting` → STORY-Flutter → `flutter-detail-design` → DD-Flutter → `flutter-feature-coding` → Widget / Controller / Repository + 测试 → 独立代码审查。

生成文档的端标识统一使用完整名称 `Flutter`；文件名、标题、编号、正文和交叉引用遵循 `AI-Native/flutter/rules/flutter-project.md` 的文档命名约定。

客户端线消费后端 handoff；Flutter 无后端调用的纯 UI、本地或仅原生 SDK 卡填 `N/A`。单元、Widget、集成与设备验证在编码阶段完成，不额外增加流程阶段。

## 审查与门禁

### 后端（仅接 backend 时保留）

- **代码审查**：`AI-Native/backend/rules/code-review.md`（L0–L3；P0–P3 按档位闭环；审查通过前禁止 commit/push）。
- **Story 审查**：`AI-Native/backend/rules/story-review.md`（拆卡后、进详设前；「已确认」须有通过报告）。
- **阶段工件审查**：`AI-Native/backend/rules/artifact-review.md`（JSD / HLD / DD / TS 进入下一环前）。
- **自动门禁**：`mvn test`（或等价）、`bash AI-Native/backend/scripts/validate-skills.sh --quiet-tick`、相对链接 0 断链。

---

### 前端（仅接 frontend 时保留）

- 代码审查：`AI-Native/frontend/rules/code-review.md`；报告模板：`AI-Native/frontend/templates/code-review-report.md`；报告落 `AI-Native/frontend/docs/reviews/{迭代}/REVIEW-CODE-FE-*`。
- 自动门禁：项目画像约定的前端测试、`bash AI-Native/frontend/scripts/validate-skills.sh --quiet-tick`；测试通过后、联调/提测前独立审查，不套用后端 Story/DD 审查。
- L0 自动门禁即可；L1–L3 按规则闭环，审查通过前禁止 commit/push。

### Flutter（仅接 flutter 时保留）

- 代码审查：`AI-Native/flutter/rules/code-review.md`；报告模板：`AI-Native/flutter/templates/code-review-report.md`；报告落 `AI-Native/flutter/docs/reviews/{迭代}/REVIEW-CODE-Flutter-*`。
- 自动门禁：在画像登记的应用根运行格式检查、`flutter analyze`、`flutter test` 及适用的集成测试；项目根运行 `bash AI-Native/flutter/scripts/validate-skills.sh --quiet-tick`。设备证据与未验证项如实记录。
- 编码验证后、联调/提测前独立审查，不套用后端 Story/DD 审查。L0 自动门禁即可；L1–L3 按规则闭环，审查通过前禁止 commit/push。

## 文档地图（仅保留已接入线）

| 想了解… | 读这份 |
|---------|--------|
| 系统边界与集成 | `AI-Native/{主线}/architecture/system-landscape.md` |
| 领域术语 | `AI-Native/{主线}/glossary/domain-glossary.md` |
| 开发环境 | `docs/dev-setup.md`（项目自建） |
| 方法论 | `AI-Native/{主线}/docs/methodology/readme.md` |
| 后端 Golden 约定 | `AI-Native/backend/docs/methodology/golden.md` |
| 迁移与接入 | `AI-Native/{主线}/MIGRATION.md` |
| 后端 Skill 治理 | `AI-Native/backend/docs/methodology/skill-governance.md` |
| 前端线 | `AI-Native/frontend/README.md`（消费 `AI-Native/frontend/docs/handoff/`） |
| Flutter 线 | `AI-Native/flutter/README.md`（消费 `AI-Native/flutter/docs/handoff/`） |

---

## 变更记录

| 日期 | 变更 |
|------|------|
| {YYYY-MM-DD} | 初版（由 AI-Native 模板生成） |
