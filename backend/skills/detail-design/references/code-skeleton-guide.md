# Java 代码骨架推导指引

> 配套 `detail-design` Skill 步骤 9。产出写入详设 **§8**；`feature-coding` 按 §8 精确落地，不得擅自改名或越界改文件。

## 目标

把「做什么」落到「哪些 Maven 模块、哪些类/方法做」，减少下游编码 Agent 的分层与命名漂移。

---

## 五步推导法

### 1. 定模块与服务

从 Story「服务/模块」+ §1.2 架构上下文（对齐画像 §二）确定：

| Story 字段示例 | Maven 模块 |
|----------------|------------|
| `{project}-bff-app` | `{project}-bff-app/` |
| `{project}-bff-admin` | `{project}-bff-admin/` |
| `{project}-{domain-a}` | `{project}-{domain-a}/{domain-a}-api` + `{domain-a}-impl` |
| `{project}-{domain-b}` | `{project}-{domain-b}/{domain-b}-api` + `{domain-b}-impl` |
| `{project}-adapter` | `{project}-adapter/adapter-api` + `adapter-impl` |

跨模块编排 → `{Entity}Facade` 或 `app/client`，**禁止** BFF 直调 `*-impl` 内部 Service。

### 2. AC → 层映射

| AC 特征 | 落点 |
|---------|------|
| 对外 HTTP | BFF `*Controller` + `{Entity}VO`；OpenAPI 同 path；实现时补中文 JavaDoc + `@Tag`/`@Operation`/`@Schema`（见 feature-coding layer-guides §5.1） |
| HTTP **守卫**（空参、格式、未登录） | BFF `*Controller` 内 guard → `{GuardErrorCode}`；鉴权 Filter → 公共错误码（`{company-common}`） |
| 域内部远程接口 | 按画像 §5.4 P-2：`*-api` 远程客户端/接口 + `{Entity}DTO`（HTTP 协议同步维护内部 OpenAPI；RPC 协议维护接口/`.proto`），`*-impl` 提供内部远程入口（内部 Controller 或 RPC Provider） |
| 域规则 / 状态机 / 匹配算法 | `*-impl` `{Entity}QueryService`/`{Entity}CommandService`、可选 `domain/model/{Entity}`（贫血）、`*Validator`、`util/*` |
| 状态迁移落库 | 按画像 §5.4 P-3（ORM）：条件更新（非查聚合全量覆盖）；见 domain-model-guide |
| 新建实体落库 | `{Entity}CommandService`：按画像 P-3 主键策略赋值后写入 |
| 业务删除实体 | `{Entity}CommandService` → 软删（`UPDATE deleted=1`）；禁止业务路径物理删 |
| 编排多服务 | `{Entity}Facade`（不跨服务包本地事务；跨服务写一致性按画像 §5.4 E-3） |
| 跨服务调用 | `*-impl/app/client/*Client` → 封装下游服务的远程客户端（按画像 §5.4 P-2 与 §3.6）+ 请求头透传（按 P-5） |
| 外部系统对接 | `{domain-a}-impl/app/client/{External}Client` |
| 第三方南向适配 | `adapter-api` `{External}Gateway`；实现在 `adapter-impl` |
| 落库 | `{Entity}DO` + `{Entity}Mapper` 接口 + XML `id`；DO 含 `deleted`/`deletedAt` |
| 前端-only | §8.2 追溯表标 **N/A** |

**主键生成**：按画像 §5.4 P-3 执行（示例：`{basePackage}.common.core.util.{IdGenerator}`，来自 `{groupId}:{common-core}`，版本与 `{company-common}` 根 POM 对齐）。**禁止** BFF 生成业务主键；选用应用侧 ID 生成器时**禁止** DDL `AUTO_INCREMENT`。

**AC 影响层含 BFF + domain**：端到端验收；guard 落 BFF、算法落 domain，**禁止**两层各建同名工具类。见 [bff-domain-boundary-guide.md](./bff-domain-boundary-guide.md)。

### 3. 命名对齐

#### 3.1 域 Service：统一 `{Entity}QueryService` / `{Entity}CommandService`

全仓库域内业务 Service **仅**使用两种后缀；**具体动作写在方法名**，不用 `*LockService`、`*AllocateService` 等能力类名。

| 后缀 | 含义 | 典型方法 |
|------|------|----------|
| `{Entity}QueryService` | **无副作用**读（含只读推荐/统计） | `getActive{Entity}`、`queryAvailable`、`findBestCandidate` |
| `{Entity}CommandService` | **改库**写（INSERT、条件 UPDATE、软删） | `createPending{Entity}`、`lockResource`、`softDelete{Entity}` |

**决策树**（详设 §8 命名须与此一致）：

```text
该方法是否会改库（INSERT / UPDATE / 软删）？
├─ 否 → {Entity}QueryService
└─ 是 → {Entity}CommandService

是否跨域或多步事务编排？
├─ 是 → {Entity}Facade（如 {Entity}CreateFacade）
└─ 否 → 留在本域 Query/Command

是否仅为纯规则、无 Mapper 编排？
└─ 是 → *Validator / *Calculator / *Generator / *Normalizer，不单独建 *Service
```

**命名示例**：

| 服务 / 域 | QueryService | CommandService |
|-----------|--------------|----------------|
| `{domain-a}` | `{EntityA}QueryService` | `{EntityA}CommandService` |
| `{domain-b}`（主实体） | `{EntityB}QueryService` | —（主数据 CRUD Story 再建） |
| `{domain-b}`（子资源） | `{Resource}QueryService`（含 `findBestCandidate`） | `{Resource}CommandService`（含 `lockResource`） |

| 类型 | 约定 | 示例 |
|------|------|------|
| BFF Controller | `App*` / `Admin*` + 资源 + `Controller` | `App{Entity}Controller` |
| BFF Converter | `*Converter`（MapStruct，DTO↔VO） | `{Entity}BffConverter` |
| 域 API | `{Domain}Api` | `{DomainB}Api` |
| Provider | `{Domain}ApiImpl` | `{DomainB}ApiImpl` |
| Facade | `{Entity}Facade` / `{用例}Facade` | `{Entity}CreateFacade` |
| QueryService | `{Entity}QueryService` | `{Entity}QueryService` |
| CommandService | `{Entity}CommandService` | `{Entity}CommandService` |
| Domain（可选，贫血） | `domain/model/*` | `{Entity}`（仅复杂 Story） |
| 域 Converter | `*Converter`（MapStruct，DO↔DTO） | `{Entity}Converter` |
| DTO | `{Entity}DTO`、`*Request`、`*Response` | `{Entity}AllocateRequestDTO` |
| DO | `{Entity}DO` | `{Entity}DO` |
| Mapper | `{Entity}Mapper` | `{Entity}Mapper` |
| 错误码 | 域：`*-api` `{Domain}ErrorCode`；BFF 守卫：`{project}-common` `{GuardErrorCode}` | `{Domain}ErrorCode` / `{GuardErrorCode}` |
| Client | `*Client` | `{External}Client`、`{DomainB}Client` |

包路径遵循 `rules/java-project.md` 与 system-landscape §3.2（根包 `{basePackage}`）。

### 4. 增量扫描

已有模块时 **§8.4 修改清单必填**：

- 扫描 `*-api`、`*-impl`、BFF 已有类
- 只列将**新建**或**新增/修改方法**的类
- 每条关联 AC；禁止「修改 service 逻辑」等模糊描述

### 5. 追溯闭环

§8.2 每条**后端** AC 至少映射：

- 一个类/方法（或 `{Entity}Mapper` XML `id`）
- 可选：建议测试类名（`{Entity}QueryServiceTest`、`App{Entity}ControllerTest`）

---

## 列与不列

| 列 | 不列 |
|----|------|
| 模块路径、类名、公开方法签名 | 方法体、私有方法 |
| §8.4 修改清单（文件 + 变更点） | import 列表 |
| Mapper 方法名 ↔ XML `id` | 测试函数实现 |
| 新建 vs 修改 操作列 | Spring 配置细节（除非 Story 要求） |

---

## 分层依赖（§8.1 微服务写法）

```text
{project}-gateway（可选）              →  路由转发至 BFF、清理外部伪造请求头、拦截内部路径
{project}-bff-app / {project}-bff-admin  →  各领域服务 *-api（远程契约）、通用公共库（无业务库）
*-impl（独立启动微服务）                 →  本服务 *-api + 下游 *-api（远程契约）+ 通用公共库
```

写操作骨架示意（详设 §8.3 可照此列依赖字段，主键与持久化按画像 §5.4 P-3）：

```text
{EntityA}CommandService
  - createPending{EntityA}(...)   // 按 P-3 主键策略生成 ID → 写入本服务独立库

{EntityB}CommandService
  - lockResource(...)             // 条件 UPDATE（本服务独立库）
```

**禁止**：

- 跨服务依赖对方 `*-impl` 或绕过契约直连他服务数据库
- BFF 写核心状态机或跨服务复杂写编排
- BFF 与领域微服务各设计**同职责**工具类（如双份 `{Domain}Normalizer`）
- 详设 §8 写「各一份或 common」而不选定服务（或违反画像 §5.4 P-6 公共库边界）
- 在画像 §5.4 P-2（调用协议）/ P-3（ORM）/ P-4（响应错误码）/ P-5（内部鉴权）仍为 `[TBD]` 时擅自编造具体框架骨架

---

## 与 feature-coding 衔接

| 优先级 | 编码阶段模块终判来源 |
|--------|------------------------|
| 1 | 详设 §8.2 / §8.3 / §8.4 |
| 2 | Story「服务/模块」 |
| 3 | OpenAPI operation + 画像 |

编码 Agent 应按 §8 创建/修改类与方法；OpenAPI 业务语义以 paths/components 为准。
