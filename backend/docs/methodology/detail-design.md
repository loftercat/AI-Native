# 详细设计 Skill（detail-design）核心思想

> **可执行正文**：`skills/detail-design/SKILL.md`  
> **详设骨架**：`skills/detail-design/templates/design-template.md`  
> **范本**：`docs/design/_golden/`

---

## 1. 一句话定位

**把 Story 里的 AC/BR 转成可编码、可测的技术契约：领域模型、OpenAPI、schema、Java 类骨架、时序图，并汇总为详设文档。**

本 Skill 继承公司级 **十一步流程**（加载 → 解析 → 架构 → 缺口 → 接口 → 专项 → schema → 时序 → 骨架 → 落盘 → 汇总），按 **Java 21 + Spring Boot 3.2 单体（V1）+ 双 BFF + `*-api`/`*-impl`** 特化。

---

## 2. 核心思想（七条）

### 2.1 AC 是设计输入

从 AC 拆资源/动作/异常；从 BR 拆不变量、状态机。每条后端 AC 须在 **§3 总表**、**§5 接口** 与 **§8 追溯表** 有落点或 N/A。

### 2.2 六类契约

| 产出 | 路径 |
|------|------|
| 详设 | `docs/design/{迭代}/DD-STORY-*.md` |
| 领域模型 | 详设 §4 |
| OpenAPI | `docs/api/{服务标识}/openapi.yaml` |
| schema | `docs/schema/{服务标识}/schema.md`（字段表 + `CREATE TABLE` DDL） |
| 时序图 | 详设 §7 |
| Java 骨架 | 详设 §8（签名 + 修改清单，无方法体） |

### 2.3 双层 API（本仓库固定）

| 层 | 模块 | HTTP |
|----|------|------|
| 对外 | `booking-bff-app` / `booking-bff-admin` | `/api/v1/booking/app|admin/...` |
| 域边界 | `*-api` 的 `XxxApi` | 无 HTTP（V1 同 JVM 注入） |

含 HTTP 的 Story：**OpenAPI 写 BFF**；域能力写 `XxxApi` + Service 骨架。跨 BFF→order→inventory 的 AC **须画时序图**。

### 2.4 AC→API 五步推导

1. 定 BFF（App / Admin）  
2. 名词 → REST 资源  
3. HTTP Method 映射  
4. Given/When/Then → 参数/体/响应/错误码  
5. §3 + §5.1 映射表，无遗漏  

详见 [ac-to-contract-guide.md](../../skills/detail-design/references/ac-to-contract-guide.md)。

### 2.5 Java 骨架五步推导

1. 定 Maven 模块  
2. AC → 层映射（Controller / XxxApi / Service / Mapper）  
3. 命名对齐 Rule  
4. 增量扫描 → §8.4 修改清单  
5. §8.2 追溯闭环  

详见 [code-skeleton-guide.md](../../skills/detail-design/references/code-skeleton-guide.md)。

### 2.6 增量设计

自动查找 `docs/api/**`、`docs/schema/**`、存量 `*-api`/`*-impl`/BFF。

OpenAPI：**diff 摘要 → 用户确认 → 合并**；同名 DD 不静默覆盖。

### 2.7 缺口三分法

猜错会导致 feature-coding/测试错误 → **阻断**（模块归属、鉴权、状态机、事务）。可补充标 `[AI推断]`。

---

## 3. 标准流程（十一步摘要）

```text
 1. 加载模板、指南、Golden、画像、Rule
 2. 解析 Story（AC/BR、自动查找）
 3. 架构上下文（双 BFF、存量契约/代码扫描）
 4. 缺口评估（阻断集中提问）
 5. 接口 §5 + OpenAPI（openapi-conventions 自检）
 6. 专项场景（支付/库存/车场/大文件 IO，见 special-scenarios.md）
 7. 持久化 §6 + schema（字段表 + CREATE TABLE DDL）
 8. 时序图 §7
 9. Java 骨架 §8 + §9 测试策略
10. 落盘 + OpenAPI/schema 增量
11. 对话汇总 → 提示 feature-coding
```

---

## 4. Skill 与 Rule 分工

| 谁 | 管什么 |
|----|--------|
| **detail-design Skill** | 十一步流程、AC→契约、时序图、增量、汇总 |
| **rules/java-project.md** | 双 BFF、api/impl、URL、依赖方向 |
| **rules/exception-and-result.md** | `Result`、`BizException`、错误码号段 |
| **rules/mybatis-conventions.md** | Mapper/XML、MyBatis Plus 范围 |
| **schema-conventions.md** | `schema.md` 字段表 + DDL |
| **rules/bff-domain-boundary.md** | BFF guard vs 域规则；工具类单点 |
| **bff-domain-boundary-guide.md** | 详设/编码完整流程与自检 |
| **openapi-conventions.md** | examples、security、自动化测试 |
| **ac-to-contract-guide / code-skeleton-guide** | 推导方法论 |

冲突时：**规范听 Rule，流程听 Skill**。

---

## 5. 边界：本 Skill 不做

- Epic → Story（story-splitting）
- 写 Java 实现、`mvn test`（feature-coding）
- 修改 Story、system-landscape、Rule、`_golden/`

---

## 6. 与上下游衔接

```text
story-splitting ──► detail-design ──► feature-coding
     Story+AC/BR        六类契约          TDD + mvn test
```

| 下游 | 消费 |
|------|------|
| feature-coding | §4、§6、§8、§9、OpenAPI、schema；见 [feature-coding.md](./feature-coding.md) |

---

## 7. 与公司级 Python Demo 的差异

| 维度 | 公司级 Demo | 本仓库 |
|------|-------------|--------|
| 代码骨架 | `api.py`、Schema、Repository | BFF Controller、`XxxApi`、Service、Mapper |
| 数据模型 Rule | `database-model.md` | `rules/mybatis-conventions.md` + schema.md |
| 架构 Rule | `architecture.md` | `rules/java-project.md` |
| 产品背景 | `product-overview.md` | system-landscape + Epic/HLD |
| OpenAPI 路径 | `docs/api/openapi.yaml` | `docs/api/booking-bff-app/openapi.yaml` 等 |
| 专项指南 | `docs/reference/idempotency-guide.md` 等 | [special-scenarios.md](../../skills/detail-design/references/special-scenarios.md) + 已落地 reference |

---

## 8. 延伸阅读

| 文档 | 说明 |
|------|------|
| [README.md](../../skills/detail-design/README.md) | 配套清单与公司级映射 |
| [ac-to-contract-guide.md](../../skills/detail-design/references/ac-to-contract-guide.md) | AC→API / XxxApi |
| [code-skeleton-guide.md](../../skills/detail-design/references/code-skeleton-guide.md) | §8 骨架推导 |
| [special-scenarios.md](../../skills/detail-design/references/special-scenarios.md) | 支付/库存/车场/定时任务/大文件 IO 专项 |
| [scheduled-task-guide.md](../../reference/scheduled-task-guide.md) | 定时任务高可靠设计 |
| [memory-safe-io-guide.md](../../reference/memory-safe-io-guide.md) | 上传/导出流式 IO（Java） |
| [openapi-conventions.md](../../skills/detail-design/references/openapi-conventions.md) | OpenAPI 质量 |
| [hld-dd-boundary-guide.md](../../skills/high-level-design/references/hld-dd-boundary-guide.md) | 概设 vs 详设 |
| [DD-STORY-GOLDEN-001-booking-order-create.md](../design/_golden/DD-STORY-GOLDEN-001-booking-order-create.md) | 详设范本 |
