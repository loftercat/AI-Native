# {项目名} — 系统画像与 AI 协作者入口

> 完整系统边界、模块清单、集成关系、技术栈见 **`AI-Native/backend/architecture/system-landscape.md`**（项目事实唯一来源）。
> 领域术语见 **`AI-Native/backend/glossary/domain-glossary.md`**；工程方法论见 **`AI-Native/backend/docs/methodology/readme.md`**。
> 本文件是目标项目的 AI 入口，不是模板仓自身的 `AGENTS.md`。

---

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

## 编码约束

1. **HTTP 只在 BFF**：禁止在 BFF 写核心状态机；域逻辑在 `*-impl`。
2. **api/impl 分离**：`*-api` 只放契约与 DTO，业务实现在 `*-impl`。
3. **域间调用**：V1 同 JVM 直调 `XxxApi`，经 `app/client` 封装；不引入 OpenFeign/Nacos（除非架构变更）。
4. **统一响应**：`{Result 类型全限定名}`；业务成败看 `code === {成功码}`。
5. **错误码号段**：{填写各域号段}；域错误码放 `*-api`，BFF 守卫错误码放 `common`。
6. **禁止造轮子**：不得自定义 `Result` / `BizException` / `ErrorCode` / `GlobalExceptionHandler` / `PageResult` / `PageQuery` / 雪花 ID 生成器；一律复用项目公共库。
7. **数据访问**：ORM 为 `{MyBatis}`；主键查询可用 `{MyBatis Plus}`，其余 SQL 只写在 XML。
8. **文档中文，代码标识符英文**；保持 diff 小。

---

## AI Native 流水线

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

## 审查与门禁

- **代码审查**：`AI-Native/backend/rules/code-review.md`（L0–L3；P0–P3 按档位闭环；审查通过前禁止 commit/push）。
- **Story 审查**：`AI-Native/backend/rules/story-review.md`（拆卡后、进详设前；「已确认」须有通过报告）。
- **阶段工件审查**：`AI-Native/backend/rules/artifact-review.md`（JSD / HLD / DD / TS 进入下一环前）。
- **自动门禁**：`mvn test`（或等价）、`bash AI-Native/backend/scripts/validate-skills.sh --quiet-tick`、相对链接 0 断链。

---

## 文档地图

| 想了解… | 读这份 |
|---------|--------|
| 系统边界与集成 | `AI-Native/backend/architecture/system-landscape.md` |
| 领域术语 | `AI-Native/backend/glossary/domain-glossary.md` |
| 开发环境 | `docs/dev-setup.md`（项目自建） |
| 方法论 | `AI-Native/backend/docs/methodology/readme.md` |
| Golden 约定 | `AI-Native/backend/docs/methodology/golden.md` |
| 迁移与接入 | `AI-Native/backend/MIGRATION.md` |
| Skill 治理 | `AI-Native/backend/docs/methodology/skill-governance.md` |
| 前端线 | `AI-Native/frontend/README.md`（消费 `AI-Native/frontend/docs/handoff/`） |

---

## 变更记录

| 日期 | 变更 |
|------|------|
| {YYYY-MM-DD} | 初版（由 AI-Native 模板生成） |
