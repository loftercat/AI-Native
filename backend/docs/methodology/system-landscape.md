# 系统画像：应写什么、给谁用

> **约定路径**：各业务仓库维护 `docs/architecture/system-landscape.md`（文件名固定）。  
> **本文性质**：方法论——说明系统画像**必须体现的内容**与 Skill 消费关系。  
> **本仓库实例**：[`docs/architecture/system-landscape.md`](../../architecture/system-landscape.md)（源项目）。

---

## 1. 系统画像是什么

系统画像是 **项目级上下文资产**：描述产品由哪些模块/系统组成、如何集成、技术栈与 API 路径，供 **high-level-design**、**detail-design**、**feature-coding** 在拆 Story、画时序图、写 URL、选模块时自动读取。

| 属性 | 说明 |
|------|------|
| 层级 | **项目叠加**（每个仓库一份），不随方法论包整体复制 |
| 维护者 | 架构师 / TL |
| 与 glossary 区别 | 词表管**术语**；画像管**系统边界、集成、技术栈、URL** |
| 缺失时 | Skill **降级**：反复提问模块归属；详设中记**轻量 ADR** |

---

## 2. Skill 消费哪些内容

| 画像章节 | 主要消费者 | 用途 |
|----------|------------|------|
| 产品全景 / 系统边界 | high-level-design、story-splitting | Epic 范围、非目标 |
| 模块清单 | 全部 Skill | Story「服务/模块」、详设服务标识 |
| 架构与分层 | detail-design、feature-coding | BFF vs 域、`*-api`/`*-impl`、依赖方向 |
| 外部集成 | HLD、详设 | Client、时序图、Mock 边界 |
| 技术栈 / 部署形态 | feature-coding | V1 单体 vs V2+ 微服务约束 |
| URL 前缀 | detail-design、feature-coding | OpenAPI path、Controller `@RequestMapping` |
| 错误码号段 | detail-design | 业务码分段 |

---

## 3. 推荐章节结构

### 3.1 文档头（必备）

- 声明：AI Skill 上下文资产、约定路径、维护者。
- 本文件描述的范围（如「源项目 V1 单体后端」）。

### 3.2 产品全景（建议）

- 用户可见端（C 端小程序、B 端运营后台前端等）。
- **本仓库职责**与**不做什么**（另仓前端、外部支付/鉴权等）。

### 3.3 模块清单（必备）

| 子节 | 必备字段 |
|------|----------|
| **本仓库模块** | 模块名、路径、职责、对外 URL（若 BFF） |
| **外部系统** | 系统名、集成方式、本仓库调用方 |

**服务标识**与 OpenAPI 目录 `docs/api/{服务标识}/` 一致（如 `booking-bff-app`、`booking-order`）。

### 3.4 架构与分层（必备）

**体现什么**

- V1 部署形态（本仓库：**单体单 jar + 双 BFF 子模块**）。
- `*-api`（契约）与 `*-impl`（实现）分工。
- 对外 HTTP 是否仅 BFF；域间 V1 如何调用（同 JVM `XxxApi`）。

**Skill 结论（强烈建议写死一句）**，例如本仓库：

> 对外 HTTP 仅 `booking-bff-app` / `booking-bff-admin`；域逻辑在 `*-impl`；V1 跨域 `@Autowired XxxApi`，不用 OpenFeign。

### 3.5 集成关系（必备，可渐进）

- 关系示意图 + 集成表（方向、协议、鉴权、MVP 优先级）。

### 3.6 技术栈基线（必备）

| 维度 | 本仓库示例 |
|------|-----------|
| 语言 | Java 21 |
| 框架 | Spring Boot 3.2.x |
| ORM | MyBatis + MyBatis Plus（仅主键 CRUD）；其余 SQL 在 XML |
| 缓存 / 消息（V1） | Redis（分布式缓存/锁/序列）/ Spring Event |
| 测试 | JUnit 5、Mockito、Maven |
| 构建 | Maven 多模块 |

### 3.7 URL 基线（Web/API 项目必备）

本仓库对外前缀：

```text
/api/v1/booking/app/...      → booking-bff-app
/api/v1/booking/admin/...    → booking-bff-admin
```

BFF 统一返回 `com.hema.common.core.result.Result<T>`（`hema-common`）；业务成败看 `code === 200`。

---

## 4. OpenAPI / schema 路径规则

```text
读 system-landscape 模块清单
  → OpenAPI: docs/api/{服务标识}/openapi.yaml
  → schema:  docs/schema/{服务标识}/schema.md
```

本仓库典型服务标识：`booking-bff-app`、`booking-bff-admin`、`booking-order`、`booking-inventory`、`booking-parking-adapter`。

---

## 5. 与其他文档的分工

| 文档 | 分工 |
|------|------|
| `domain-glossary.md` | 领域术语 |
| `system-landscape.md` | 模块边界、集成、技术栈、URL |
| Story / HLD / DD | 单次需求与 Epic 级设计 |
| `docs/api/{服务标识}/openapi.yaml` | 机器可读 HTTP 契约（详设产出） |
| `openapi-conventions.md` | OpenAPI / Swagger / 自动化测试写法（HTTP Story **必守**） |

详设 Skill **只读**系统画像；发现与事实不符时，提示人更新画像后再设计。

---

## 6. 新建 / 迁移检查清单

- [ ] 已创建 `docs/architecture/system-landscape.md`
- [ ] 模块清单含 Maven 路径与服务标识
- [ ] **分层**节明确 BFF / api / impl 与 V1 调用方式
- [ ] 外部系统与 MVP 优先级
- [ ] URL 前缀与至少一条完整 path 示例
- [ ] 从方法论包同步时：**不覆盖**目标仓库已有画像

---

## 7. 延伸阅读

| 文档 | 说明 |
|------|------|
| [readme.md](./readme.md) | 本仓库 AI Native 总览 |
| [AGENTS.md](../../../AGENTS.md) | AI 协作者入口 |
| [system-landscape.md](../../architecture/system-landscape.md) | 本仓库完整画像 |
