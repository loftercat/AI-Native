# BFF 与域服务职责边界指引

> 配套 `detail-design` 步骤 2、5、8、9 与 `feature-coding` 分层实现。  
> **横切 Rule**：`rules/bff-domain-boundary.md`（精简必守）；本文档为完整流程与自检清单。  
> 冲突时：Story §2.3 校验职责 > Rule / 本指引 > 通用推断。

## 1. 两类职责

| 类型 | 定义 | 典型落点 | 示例 |
|------|------|----------|------|
| **守卫（guard）** | HTTP 入参是否允许进入域层；失败直接返回，**不调** `XxxApi` | BFF `*Controller` | 关键词空/仅空白（AC-10）、`endTime <= startTime`（AC-07）、未登录 |
| **领域规则（domain rule）** | 业务语义判断、算法、状态机、匹配策略 | `*-impl` `*Service` / `*Validator` | 关键词 normalize + 分词匹配（AC-11）、推荐算法（BR-02）、时间窗（BR-04） |

**原则**：BFF **薄**——鉴权、守卫、`Result` 包装、DTO↔VO（**MapStruct converter，禁止 Controller 内联字段映射**）；**禁止**在 BFF 重复实现域内算法或工具类。

## 2. Story §2.3 → 详设落点（必做）

步骤 2 须读取 Story **§2.3 校验职责**，在详设产出 **§1.2 或 §2 末**「校验职责落点表」：

| Story §2.3 行 | 守卫 / 领域 | 详设 §8 类/方法 | 测试 |
|---------------|-------------|-----------------|------|
| BFF：关键词非空 | **守卫** | `AppParkingLotController.searchLots` — `isBlank(keyword)` | `@WebMvcTest` AC-10 |
| inventory：匹配算法 | **领域** | `ParkingLotQueryService` + `KeywordNormalizer` | `ServiceTest` AC-11 |

每条 §2.3 职责**有且仅有一处**实现落点；AC 影响层含多层时，须拆行说明 guard vs domain。

## 3. AC 影响层双写时的拆分

AC 标注「影响层：BFF、inventory」表示**端到端验收**，不表示两层各实现一遍算法。

| 场景 | BFF | 域 Service |
|------|-----|------------|
| AC-10 关键词非法 | `isBlank` → 400，不调域 | — |
| AC-11 多余空格可匹配 | 透传原始 `keyword` 调 `XxxApi` | `KeywordNormalizer` + Mapper 分词 AND |
| AC-07 时段非法 | `endTime <= startTime` → 400 | — |
| AC-12 时间窗外 | 透传时段 | `BookingWindowValidator` |

## 4. 工具类单点归属

| 规则 | 说明 |
|------|------|
| **单点** | 同一 BR/算法在仓库内**仅一处**实现类（或 `love-common` 一处） |
| **禁止** | BFF 与 `*-impl` 各建同名同职责类（如双份 `KeywordNormalizer`） |
| **禁止** | 详设写「各一份或 common」而不选定模块 |
| **共享** | 多域复用 → `love-common`；单域 → `*-impl` 内 `util/` 或 `service/` 包 |

§8.2 追溯表：guard 与 domain 须**不同行**；domain 工具类只列**一个**模块路径。

## 5. 时序图约定

- **BFF 泳道**：鉴权、`isBlank`/格式 guard、调用 `XxxApi`、包装 `Result`
- **域泳道**：normalize、匹配、状态机、Mapper
- **禁止**：BFF 泳道出现 `KeywordNormalizer.normalize`、分词、SQL 策略等与域重复的步骤

## 6. §8 骨架自检（落盘前必过）

- [ ] Story §2.3 每行在 §8.2 有唯一实现落点
- [ ] 无「各一份或 common」未决表述
- [ ] 同一 BR 实现类仅一处（§8.3 不重复列 BFF + impl 同名工具）
- [ ] 时序图 BFF 泳道无领域算法步骤
- [ ] AC-10 类 guard 在 Controller 追溯行注明 `isBlank`，非独立 Normalizer 类

## 7. feature-coding 衔接

编码阶段发现详设 §8 在 BFF 与 impl 重复同一工具类 → **阻断**，提示回溯 `detail-design` 修正 §8，不得擅自双份实现。
