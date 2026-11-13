# 系统画像：恋爱预见（love-forecast）

> **AI Skill 上下文资产**（`architecture/system-landscape.md`）。全部 Skill 的项目层事实唯一定义处——凡「具体文件名、系统名、路径、号段、账号」都只写在这里，Skill 与 Rule 引用不复制。
> 写法指南：[docs/methodology/system-landscape.md](../docs/methodology/system-landscape.md)

---

## 一、产品全景

### 需求是什么

**恋爱预见**是一个 Web 端亲密关系沟通辅助工具。用户不知道怎么回复另一半时，描述当前情境（发生了什么、对方最后说了什么、想达到什么），系统给出三档可执行的回复建议；用户也可以导入历史聊天记录，让系统积累可复算的沟通行为观察，使后续建议更贴合这个具体的人。

产品不做人格判断、不做心理诊断、不代发消息。所有结论以「可观察行为 + 证据强度 + 不可推断声明」的形式给出，详细约束见 `docs/requirements/epics/persona-analysis-standard.md`。

| 端 | 做什么 |
|----|--------|
| **C 端 Web**（用户） | 建关系档案 → 描述情境 → 看三档建议 → 可选演练 → 标记采纳与真实反应 |
| **本仓库**（后端） | 提供 HTTP API、情境解析编排、观察检索、建议生成与越界校验、数据存储与隔离 |
| **无 B 端** | MVP 不建运营后台；内容安全靠规则 + 模型双层校验，不靠人工审核台 |

### 系统边界

| 系统 | 一句话定位 | 与本仓库关系 |
|------|-----------|-------------|
| **love-forecast 后端**（本仓库） | 业务 API + LLM 编排 + 数据存储 | 对外只暴露 HTTP；不含前端 UI |
| **Web 前端**（另仓） | 页面与交互 | 消费本仓库 OpenAPI；不直接调模型 |
| **LLM 供应商**（TBD） | 对话生成、校验判定 | 经 Spring AI 抽象层调用；供应商可替换 |
| **邮件服务** | 登录验证码 | HTTPS / SMTP；MVP 只发验证码 |

**核心关系图**：

```text
Web 前端（另仓）
   │  HTTPS / JSON
   ▼
love-app（BFF：Controller + 鉴权 + 响应封装）
   │  同 JVM 直调
   ├── love-profile（档案 / 观察集 / 导入 / 记忆）
   ├── love-advice（情境解析 / 策略合成 / 话术生成 / 校验）
   │        │
   │        ▼
   │   Spring AI 抽象层 ──► LLM 供应商（外部）
   │
   └── love-common（统一响应 / 异常 / 错误码基类 / ID 生成）
        │
        ▼
      MySQL 8（业务数据）+ 向量存储（观察检索，MVP 可先不启用）
```

> 领域术语见 [domain-glossary.md](../glossary/domain-glossary.md)。

---

## 二、模块清单（本仓库规划）

**部署形态**：单体单 jar。MVP 不引入注册中心、不做服务拆分；V2 若引入实时模拟流式推送，再评估是否拆出独立推理服务。

**模块聚合**：两个业务域按 `{域}/` 聚合 POM + 内层 `{域}-api` / `{域}-impl`；外层保留项目前缀，内层去前缀。

| 模块 | artifactId | 路径 | 说明 |
|------|-----------|------|------|
| 公共库 | `love-common` | `love-common/` | 统一响应 `Result` / `PageResult`、`BizException`、`ErrorCode` 基类、雪花 ID |
| 档案域（聚合） | `love-profile` | `love-profile/` | packaging=pom，仅聚合 |
| ├ 档案契约 | `profile-api` | `love-profile/profile-api/` | DTO、枚举、`ProfileErrorCode` |
| └ 档案实现 | `profile-impl` | `love-profile/profile-impl/` | 档案、观察集、导入、记忆 |
| 建议域（聚合） | `love-advice` | `love-advice/` | packaging=pom，仅聚合 |
| ├ 建议契约 | `advice-api` | `love-advice/advice-api/` | DTO、三档枚举、`AdviceErrorCode` |
| └ 建议实现 | `advice-impl` | `love-advice/advice-impl/` | 情境解析、策略合成、话术生成、校验、模拟对话 |
| 启动与 BFF | `love-app` | `love-app/` | 唯一 `@SpringBootApplication`；Controller；Flyway；集成测试基类 |

**依赖方向**：`love-app → {域}-impl → {域}-api → love-common`。BFF 只依赖 `*-api`，禁止直接依赖 `*-impl` 内部类。

> **Skill 结论**：OpenAPI 契约路径 `docs/api/love-app/openapi.yaml`；schema 按域分目录 `docs/schema/{profile,advice}/`。

---

## 三、架构与分层规范

### 3.1 架构约束

| 约束 | 说明 |
|------|------|
| 部署 | 单体单 jar；不引入注册中心、消息队列 |
| 对外 HTTP | 仅 `love-app` 含 Controller；域逻辑在 `*-impl` |
| 跨域调用 | 同 JVM 直调 `*-api` 接口，禁止注入其他域的 `*Impl` |
| LLM 调用 | 只在 `advice-impl` 内；`profile-impl` 不得直接调模型 |
| 数据隔离 | 所有查询强制带 `user_id` 条件；不做「查完再过滤」 |
| 原文边界 | 解释层与建议层只接收派生量 JSON 与按条回读的原句切片，不接收整段聊天记录 |

### 3.2 模块与包结构

```text
com.loveforecast
├── common/                    # love-common
│   ├── result/                # Result / PageResult / PageQuery
│   ├── exception/             # BizException / ErrorCode
│   └── id/                    # SnowflakeIdGenerator
├── profile/                   # love-profile
│   ├── api/                   # profile-api：ProfileApi / DTO / ProfileErrorCode
│   └── impl/
│       ├── provider/          # ProfileApiImpl
│       ├── facade/            # 跨域门面
│       ├── service/           # 业务编排
│       └── infrastructure/    # DO / Mapper / 外部适配
├── advice/                    # love-advice
│   ├── api/                   # advice-api：AdviceApi / DTO / 策略枚举
│   └── impl/
│       ├── provider/          # AdviceApiImpl
│       ├── service/           # 情境解析 / 策略合成 / 话术生成
│       ├── guard/             # 越界校验（规则层 + 模型层）
│       └── infrastructure/    # Spring AI 适配 / DO / Mapper
└── app/                       # love-app：Application / Controller / config
```

### 3.3 命名规范

| 类型 | 命名 | 示例 | 所在包 |
|------|------|------|--------|
| API 接口 | `XxxApi` | `ProfileApi` | `*-api/` |
| 实现类 | `XxxApiImpl` | — | `app/provider/` |
| 数据库实体 | `XxxDO` | `ProfileDO` | `infrastructure/dataobject/` |
| 领域服务 | `XxxService` | `SuggestionService` | `service/` |
| 校验器 | `XxxGuard` | `BoundaryGuard` | `guard/` |

### 3.4 依赖方向

```text
Controller (love-app)
    ↓
ProfileApi / AdviceApi (接口)
    ↓
XxxApiImpl (provider)
    ↓
Service
    ↓
Mapper / Client (infrastructure)
```

禁止反向依赖；`guard` 只能被 `service` 调用，不得被 `infrastructure` 调用。

### 3.5 部署形态

| 阶段 | 形态 | 缓存 | 消息 | 域间调用 |
|------|------|------|------|----------|
| MVP | 单体单 jar | 本地 Caffeine（建议结果缓存） | 无 | 同 JVM 直调 |
| V1 | 单体单 jar | Redis（多实例共享） | 无 | 同 JVM 直调 |
| V2 | 待评估 | — | — | 若引入流式推理，再评估拆分 |

### 3.6 跨域调用

MVP 全部同 JVM 直调。约定：

- `love-advice` 需要档案与观察集时，调 `ProfileApi`，不直接读 `profile` 的表。
- `love-profile` 不得反向调 `AdviceApi`（避免环）。
- 两域共用的枚举（如诉求类型）放 `love-common` 或各自 `*-api`，不跨域引用实现类。

### 3.7 异常与统一响应

统一响应与异常来自本仓库 `love-common`（无公司级公共库）。业务是否成功只看 `code === 200`。

| 区间 | 用途 | 定义位置 |
|------|------|----------|
| 200 / 400~503 | 通用与 HTTP 层 | `love-common` → `ErrorCode` |
| 1100~1199 | 档案域 | `profile-api` → `ProfileErrorCode` |
| 1200~1299 | 建议域 | `advice-api` → `AdviceErrorCode` |
| 1300~1399 | LLM 调用与校验 | `advice-impl` 内部，对外映射为 1200 段 |
| 1900~1999 | 通用业务（限流、鉴权、参数） | `love-common` |

**号段与 bugfix 责任域对应**：1100 → `love-profile`；1200/1300 → `love-advice`；1900 → `love-app` 或 `love-common`。

### 3.8 消息与缓存

MVP 无消息中间件。建议结果缓存用 Caffeine，键为 `profileId + 情境指纹 + promptVersion`，TTL 24h，**缓存键不含用户正文**。

---

## 四、外部系统集成

| 系统 | 职责 | 集成方式 | 调用方 | MVP |
|------|------|----------|--------|-----|
| LLM 供应商 | 对话生成、意图判定 | Spring AI `ChatClient` | `advice-impl` | P0 |
| 邮件服务 | 登录验证码 | SMTP / HTTP API | `love-app`（登录） | P0 |

### 4.1 LLM 供应商

**职责边界**：对方负责模型推理与内容生成；本仓库负责 prompt 组装、结构化输出校验、越界拦截、成本控制。

- **抽象方式**：Spring AI `ChatModel` / `ChatClient`，供应商通过配置切换，业务代码不出现供应商 SDK。
- **两条链路**：
  - 主链路（解释 + 建议）：需强生成能力，使用主模型。
  - 校验链路（越界判定、像不像本人）：判定任务，使用轻量模型。
- **结构化输出**：`BeanOutputConverter` + 固定枚举；`basis` / `precondition` / `risk` / `failsWhen` 全部 required，缺字段即反序列化失败并打回。
- **不落库**：prompt 与原始响应仅用于当次请求与排障日志（脱敏），不写入业务表。
- **供应商待定**：需满足境内备案要求；切换供应商只改配置与 `ChatModel` Bean，不改业务代码。

### 4.2 邮件服务

**职责边界**：对方负责投递；本仓库负责验证码生成、频控、有效期（5 分钟）。

- MVP 可用 SMTP（如企业邮箱）或第三方 API。
- 频控：同一邮箱 60 秒 1 次、每日 10 次。
- 验证码不落明文，存哈希。

### 4.3 鉴权

MVP 无独立 IAM：登录后签发 JWT（HS256），`love-app` 的过滤器解析 `userId` 写入上下文。

- 所有业务接口要求 `Authorization: Bearer <token>`。
- 401 表示未登录/凭证失效；403 表示已登录但越权（正常业务应返回 404 隐藏资源存在性，403 只用于账号状态异常）。

#### 4.3.4 测试账号约定（供 `test-data-design` Skill 消费）

| 角色 / 场景 | userId | 数据范围 | 环境变量 | seed 写什么 |
|-------------|--------|----------|----------|-------------|
| 主测试用户 | `u-demo-1` | 自己的档案与会话 | `APP_TOKEN` | 1 个档案 + 20 轮样本 |
| 越权测试用户 | `u-demo-2` | 自己的档案 | `APP_TOKEN_DENIED` | 1 个空档案，用于验证访问他人资源返回 404 |
| 无档案新用户 | `u-demo-3` | 无 | `APP_TOKEN_NEW` | 不造数，验证首次使用路径 |

**造数对齐规则**：功能权限不靠造数靠挑 Token；数据归属按 `user_id` 与 Token 对齐。Token 由测试环境准备并写入环境变量，**不进 Git**。

### 4.7 端到端调用链与 bugfix 责任域定位

```text
Web → love-app（鉴权 / 参数校验 / 响应封装）
        ├─→ ProfileApi → ProfileApiImpl → ProfileService → Mapper
        └─→ AdviceApi  → AdviceApiImpl  → SuggestionService
                                              ├─→ ProfileApi（取观察集）
                                              ├─→ ChatClient（主模型）
                                              └─→ BoundaryGuard（规则 + 轻量模型）
```

**责任域速查**：1100 段 → `love-profile`；1200 段 → `love-advice`；1300 段在对外响应中被映射为 1200 段，但日志保留原始码；1900 段 → `love-app` / `love-common`。

---

## 五、技术基线

### 5.1 核心栈

| 分类 | 技术 | 版本 | 说明 |
|------|------|------|------|
| 开发语言 | Java | 21 | |
| 核心框架 | Spring Boot | 3.2.x | 单体启动 |
| AI 框架 | Spring AI | 1.0.x | `ChatClient` / `ChatMemory` / `Advisor` |
| 数据库 | MySQL | 8.0 | 必选 |
| 迁移 | Flyway | — | 按域分目录 |
| ORM | MyBatis | — | XML 映射 |
| 缓存 | Caffeine | — | MVP 本地缓存 |
| 测试 | JUnit 5 / Mockito / Testcontainers | — | IT 用真实 MySQL |
| 前端 | 不在本仓库 | — | 另仓，消费 OpenAPI |

集成测试基建（Testcontainers）的决策记录写在 `rules/integration-test-conventions.md`，此处只列结论。

### 5.2 启动与打包

```bash
# 构建
mvn -DskipTests install

# 启动（localhost:8080）
mvn -pl love-app spring-boot:run

# 全量测试
mvn test
```

默认端口 `8080`；健康检查 `GET /api/v1/love/app/health`。

---

## 六、URL 前缀（对外 API）

| 前缀 | 模块 | 调用方 |
|------|------|--------|
| `/api/v1/love/app/` | `love-app` | C 端 Web |

> OpenAPI：`docs/api/love-app/openapi.yaml`。业务是否成功只看响应 `code === 200`，不能只看 HTTP 状态码。

---

## 七、Harness / AI Runtime

- AI 入口：仓库根 `AGENTS.md`
- Skill 资产：`skills/`（12 个后端 Skill）
- Rule：`rules/`（14 条）
- 校验：`bash scripts/validate-skills.sh`（frontmatter + 引用可达 + 坏链）
- 当前迭代：`config/current-sprint`（`2026-S01`）

> 本目录是**独立项目根**，与 `new-ai-workflow-template/backend/` 无引用关系；模板升级时按需比对，不自动同步。

---

## 变更记录

| 日期 | 关键决策（当前有效） | 详见 |
|------|----------------------|------|
| 2026-11-13 | 项目初始化：模块聚合、单体单 jar、无商业化、用户单方授权 | §二 / §三 |
