# {项目名} — 系统画像与 AI 协作者入口

> 完整服务边界、服务清单、调用矩阵、技术选型（含两档 13 项占位）见 **`AI-Native/backend/architecture/system-landscape.md`**（项目事实唯一来源）。
> 领域术语见 **`AI-Native/backend/glossary/domain-glossary.md`**；工程方法论见 **`AI-Native/backend/docs/methodology/readme.md`**。
> 本文件是目标项目的 AI 入口，不是模板仓自身的 `AGENTS.md`。

---

## 一句话

**{项目名}**（`{仓库名}`）— {一句话说明业务形态与微服务架构形态，例如：支撑 XX 业务的微服务后端，采用 API 网关 + 双 BFF + 多领域微服务，每服务独立启动与独立数据库}。

---

## 做什么

| 范围 | 内容 |
|------|------|
| **C 端 / 用户侧** | {入口 → 网关 → App BFF → 领域微服务} |
| **B 端 / 管理侧** | {入口 → 网关 → Admin BFF → 领域微服务} |
| **核心领域服务** | {各领域微服务清单与职责} |
| **仓库与部署形态** | {按画像 §5.4 P-1：单仓库多服务 / 一服务一独立仓库；每服务独立启动与独立 DB} |
| **技术栈** | {语言、框架、同步调用协议（P-2）、ORM（P-3）、注册中心/MQ（按画像 §5.4）} |

---

## 不做什么（当前阶段）

- ❌ {明确排除项 1}
- ❌ {明确排除项 2}
- ❌ {明确排除项 3}

---

## 服务与分层

```text
统一入口与对外 HTTP
  {gateway}                →  统一路由、清理外部伪造请求头、拦截内部路径
  {bff-app} / {bff-admin}  →  独立启动；对外 Controller + 鉴权 + VO 组装

领域微服务（每服务独立启动、独立数据库）
  {domain}-api   →  远程契约接口 / 客户端 + DTO + 域错误码（无业务实现）
  {domain}-impl  →  独立启动类 + 内部远程入口 → facade → service → infrastructure + 独立迁移脚本
```

| 服务 | 职责与数据归属 |
|------|----------------|
| `{gateway}` | {路由与入口防护} |
| `{bff-app}` / `{bff-admin}` | {对外 HTTP 聚合，无业务库} |
| `{domain-1}` | {职责与独占表} |
| `{domain-2}` | {职责与独占表} |
| `{common}` | 通用横切工具（严格遵循画像 §5.4 P-6，禁放业务 DTO/DO） |

> 完整服务表（含仓库/路径、服务标识、端口、数据归属与通信矩阵）以 `AI-Native/backend/architecture/system-landscape.md` §二、§3.6 为准；本表只做摘要，不重复维护。

**跨服务调用**：BFF 与领域服务、领域服务之间按画像 §5.4 P-2 选定的远程协议通过 `*-api` 契约互调，经 `client/` 封装；严禁直接依赖其他服务的 `*-impl` 内部类。

---

## 外部集成

| 系统 | 归属微服务 | 说明 |
|------|------------|------|
| {外部系统 1} | `{service}`（`{client 接口}`） | {职责与边界} |
| {外部系统 2} | `{service}`（`{gateway 接口}`） | {职责与边界} |

> 完整集成矩阵见 `AI-Native/backend/architecture/system-landscape.md` §四。

---

## 编码约束

1. **对外 HTTP 只在 BFF**：业务入口经网关路由到 BFF；禁止在 BFF 写核心领域状态机或跨服务复杂写编排。
2. **契约与实现分离（`*-api` / `*-impl`）**：`*-api` 只放远程契约接口、DTO 与域错误码；严禁跨服务依赖对方 `*-impl`。
3. **跨服务调用协议**：严格按画像 §5.4 P-2（如 OpenFeign / Dubbo / gRPC 等）落地；禁止假设服务同进程直调。
4. **每服务独立数据库**：严禁跨服务 SQL JOIN、跨服务外键、把跨服务调用包进本地 `@Transactional`；跨服务写一致性按画像 §5.4 E-3 执行（画像为 `[TBD]` 时先阻断拍板）。
5. **内部接口防外泄**：严禁直信来自公网客户端的身份/内部请求头；隔离与鉴权细则按画像 §5.4 P-5 执行。
6. **响应格式与错误码**：按画像 §3.7（§5.4 P-4）约定执行；错误码按微服务号段归口定义，禁止硬编码 magic number 或重复造公共库轮子。
7. **数据访问（ORM）**：按画像 §5.4 P-3 选型执行（选 MyBatis 时遵守 `rules/mybatis-conventions.md`；选其他 ORM 按接入时替换的规则执行）。
8. **公共库边界**：严格遵守画像 §5.4 P-6，禁止向 `{common}` 塞入业务 DTO/DO 或业务代码。
9. **文档中文，代码标识符英文**；保持 diff 小。

---

## AI Native 流水线

```text
业务原始需求 → JSD → Epic/PRD → HLD → Story → DD + 接口契约 + schema → TS → feature-coding
                                                        ↓
                                          代码审查 → integration-test-design（单服务 *IT，下游模拟）
                                                        ↓
                              QA / 跨服务验证：AC-STORY → api-blackbox-test（跨服务主链路）/ test-data-design
                                                        ↓
                     交付：api-handoff（前端 handoff 包）→ frontend 3 环（若接前端）
```

| Skill | 用途 |
|-------|------|
| `journey-scenario-design` | 原始需求 → JSD |
| `high-level-design` | Epic/PRD → HLD（含微服务边界、通信矩阵、数据归属） |
| `story-splitting` | HLD/Epic → Story（AC/BR + 跨服务依赖波次） |
| `detail-design` | Story → DD + 对外/内部接口契约 + schema + 骨架 |
| `test-spec-alignment` | Story + DD §9 → TS |
| `feature-coding` | TDD 实现（单服务范围） |
| `integration-test-design` | 单服务白盒集成测试 `*IT`（独立容器 DB，下游微服务模拟隔离） |
| `qa-acceptance-case-design` / `api-blackbox-test` / `test-data-design` | QA 验收与部署后跨服务主链路验证 |
| `api-handoff` | OpenAPI 契约 → 前端 handoff 包（快照 + VERSION + 索引；前端开工前、operation 语义变更后） |
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
| 系统边界、服务清单与 13 项选型 | `AI-Native/backend/architecture/system-landscape.md` |
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
| {YYYY-MM-DD} | 初版（由 AI-Native 微服务模板生成） |
