# Java 代码骨架推导指引

> 配套 `detail-design` Skill 步骤 9。产出写入详设 **§8**；`feature-coding` 按 §8 精确落地，不得擅自改名或越界改文件。

## 目标

把「做什么」落到「哪些 Maven 模块、哪些类/方法做」，减少下游编码 Agent 的分层与命名漂移。

---

## 五步推导法

### 1. 定模块与服务

从 Story「服务/模块」+ §1.2 架构上下文确定：

| Story 字段示例 | Maven 模块 |
|----------------|--------------|
| `love-app` | `love-app/` |
| `love-profile` | `love-profile/profile-api` + `profile-impl` |
| `love-advice` | `love-advice/advice-api` + `advice-impl` |
| `love-common` | `love-common/` |

跨模块编排 → Facade 或 `app/client`，**禁止** BFF 直调 `*-impl` 内部 Service。

### 2. AC → 层映射

| AC 特征 | 落点 |
|---------|------|
| 对外 HTTP | BFF `*Controller` + VO；OpenAPI 同 path；实现时补中文 JavaDoc + `@Tag`/`@Operation`/`@Schema`（见 feature-coding layer-guides §5.1） |
| HTTP **守卫**（空参、格式、未登录） | BFF `*Controller` 内 guard → `LoveErrorCode`；鉴权 Filter → `ErrorCode`（love-common） |
| 域能力（无 HTTP） | `*-api` `XxxApi` 方法 + DTO |
| 域规则 / 状态机 / 匹配算法 | `*-impl` `*Service`、可选 `domain/model/*`（贫血）、`*Validator`、`util/*` |
| 状态迁移落库 | `*Mapper` + XML **条件 `UPDATE`**（非聚合 save）；见 domain-model-guide |
| 新建实体落库 | `*CommandService`：注入 `SnowflakeIdGenerator` → `setId` → Mapper `insert` |
| 业务删除实体 | `*CommandService` → Mapper XML 软删（`UPDATE deleted=1`）；不用 `deleteById` |
| 编排多域 | `*Facade` 或 `XxxApiImpl` 薄委托 |
| 跨域调用 | `*-impl/app/client/*Client` → `@Autowired` 其它 `XxxApi` |
| 外部支付 | `advice-impl/app/client/PaymentClient` |
| 车场南向 | `adapter-api` `ParkingLotGateway`；实现在 `adapter-impl` |
| 落库 | `*DO` + `*Mapper` 接口 + XML `id`；DO 含 `deleted`/`deletedAt` |
| 前端-only | §8.2 追溯表标 **N/A** |

**主键生成**：`com.loveforecast.common.core.util.SnowflakeIdGenerator`（`common-core`，版本 `${love-common.version}` = love-common 根 POM `<version>`）。**禁止** BFF 生成业务主键；**禁止** DDL `AUTO_INCREMENT`。

**AC 影响层含 BFF + domain**：端到端验收；guard 落 BFF、算法落 domain，**禁止**两层各建同名工具类。见 [bff-domain-boundary-guide.md](./bff-domain-boundary-guide.md)。

### 3. 命名对齐

#### 3.1 域 Service：统一 `{实体}QueryService` / `{实体}CommandService`

全仓库域内业务 Service **仅**使用两种后缀；**具体动作写在方法名**，不用 `*LockService`、`*AllocateService` 等能力类名。

| 后缀 | 含义 | 典型方法 |
|------|------|----------|
| `*QueryService` | **无副作用**读（含只读推荐/统计） | `getActiveReservation`、`queryAvailable`、`allocateNearest` |
| `*CommandService` | **改库**写（INSERT、条件 UPDATE、软删） | `createPendingOrder`、`lockSpace`、`softDeleteLot` |

**决策树**（详设 §8 命名须与此一致）：

```text
该方法是否会改库（INSERT / UPDATE / 软删）？
├─ 否 → {实体}QueryService
└─ 是 → {实体}CommandService

是否跨域或多步事务编排？
├─ 是 → *Facade（如 BookingOrderCreateFacade）
└─ 否 → 留在本域 Query/Command

是否仅为纯规则、无 Mapper 编排？
└─ 是 → *Validator / *Calculator / *Generator，不单独建 *Service
```

**本仓库示例**：

| 模块 | QueryService | CommandService |
|------|--------------|----------------|
| order | `BookingOrderQueryService` | `BookingOrderCommandService` |
| inventory（车场） | `ParkingLotQueryService` | —（主数据 CRUD Story 再建） |
| inventory（车位） | `ParkingSpaceQueryService`（含 `allocateNearest`） | `ParkingSpaceCommandService`（含 `lockSpace`） |

| 类型 | 约定 | 示例 |
|------|------|------|
| BFF Controller | `App*` / `Admin*` + 资源 + `Controller` | `AppParkingLotController` |
| BFF Converter | `*Converter`（MapStruct，DTO↔VO） | `ActiveReservationBffConverter` |
| 域 API | `XxxApi` | `SpaceInventoryApi` |
| Provider | `XxxApiImpl` | `SpaceInventoryApiImpl` |
| Facade | `{用例}Facade` | `BookingOrderCreateFacade` |
| QueryService | `{实体}QueryService` | `ParkingSpaceQueryService` |
| CommandService | `{实体}CommandService` | `ParkingSpaceCommandService` |
| Domain（可选，贫血） | `domain/model/*` | `BookingOrder`（仅复杂 Story） |
| 域 Converter | `*Converter`（MapStruct，DO↔DTO） | `ActiveReservationConverter` |
| DTO | `*DTO`、`*Request`、`*Response` | `SpaceAllocateRequestDTO` |
| DO | `*DO` | `ParkingSpaceDO` |
| Mapper | `*Mapper` | `ParkingSpaceMapper` |
| 错误码 | 域：`*-api` `*ErrorCode`；BFF 守卫：`love-common` `LoveErrorCode` |
| Client | `*Client` | `PaymentClient`、`InventoryClient` |

包路径遵循 `rules/java-project.md` 与 system-landscape §3.2。

### 4. 增量扫描

已有模块时 **§8.4 修改清单必填**：

- 扫描 `*-api`、`*-impl`、BFF 已有类
- 只列将**新建**或**新增/修改方法**的类
- 每条关联 AC；禁止「修改 service 逻辑」等模糊描述

### 5. 追溯闭环

§8.2 每条**后端** AC 至少映射：

- 一个类/方法（或 Mapper XML `id`）
- 可选：建议测试类名（`ParkingSpaceQueryServiceTest`、`AppParkingLotControllerTest`）

---

## 列与不列

| 列 | 不列 |
|----|------|
| 模块路径、类名、公开方法签名 | 方法体、私有方法 |
| §8.4 修改清单（文件 + 变更点） | import 列表 |
| Mapper 方法名 ↔ XML `id` | 测试函数实现 |
| 新建 vs 修改 操作列 | Spring 配置细节（除非 Story 要求） |

---

## 分层依赖（§8.1 固定写法）

```text
love-app  →  *-api（XxxApi）、common-web
*-impl  →  *-api、common-core（SnowflakeIdGenerator / BizException 等）、love-common（按需）
love-app  →  聚合 BFF + *-impl（脚手架阶段）
```

写操作骨架示意（详设 §8.3 可照此列依赖字段）：

```text
BookingOrderCommandService
  - SnowflakeIdGenerator idGenerator
  - createPendingOrder(...)   // setId(idGenerator.nextId()) → mapper.insert

ParkingSpaceCommandService
  - lockSpace(...)            // mapper.updateStatusIfAvailable（条件 UPDATE，无雪花）
```

**禁止**：

- `*-impl` 写 `@RestController`
- BFF 写核心状态机
- BFF 与 `*-impl` 各设计**同职责**工具类（如双份 `KeywordNormalizer`）
- 详设 §8 写「各一份或 common」而不选定模块
- V1 详设出现 OpenFeign 接口（可记 V2+ ADR）

---

## 与 feature-coding 衔接

| 优先级 | 编码阶段模块终判来源 |
|--------|------------------------|
| 1 | 详设 §8.2 / §8.3 / §8.4 |
| 2 | Story「服务/模块」 |
| 3 | OpenAPI operation + 画像 |

编码 Agent 应按 §8 创建/修改类与方法；OpenAPI 业务语义以 paths/components 为准。
