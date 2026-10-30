# 功能编码 Skill（feature-coding）核心思想

> **可执行正文**：`skills/feature-coding/SKILL.md`  
> **实现检查清单**：`skills/feature-coding/references/implementation-checklist.md`  
> **分层指引 / 测试质量**：`layer-guides.md`、`test-quality.md`  
> **格式规范**：`rules/java-project.md`、`rules/tdd-project-conventions.md`、`rules/exception-and-result.md`

---

## 1. 一句话定位

**把 Story + 详设 + OpenAPI 在 Story 范围内用 TDD 落地为可运行 Java 代码，并以 `mvn test` 验收。**

本 Skill 继承公司级 **八步流程**（加载 → 解析 → 查找契约 → 缺口 → 计划 → 分层实现 → 测试验收 → 汇总），按本仓库 **Java 21 + Spring Boot 3.2 + Maven 多模块 + 双 BFF** 特化。

---

## 2. 核心思想（六条）

### 2.1 详设 §8 是编码权威

- 类名、包路径、AC→代码追溯以详设 **§8 代码骨架** 为准
- OpenAPI 管 BFF HTTP 契约；`XxxApi` 管域边界
- 编码阶段**不发明**详设未列的公共 API

### 2.2 一体化 TDD

```text
红（失败测试）→ 绿（最小实现）→ 重构（小 diff）
```

- 阻断未解除前可先写红测，不得写实现
- 增量场景：已有绿测保留；AC 变更先改测再改实现

### 2.3 分层实现顺序（自下而上）

```text
DO + Mapper/XML → *-api → Service → Facade/ApiImpl → BFF Controller → booking-app 聚合
```

用户限定单层时只执行该层，但下层须已满足 AC。

### 2.4 测试落点

| 层 | 路径 | 工具 |
|----|------|------|
| 域 Service | `*-impl/src/test/java/` | JUnit 5 + Mockito |
| BFF HTTP | `booking-bff-*/src/test/java/` | `@WebMvcTest` + MockMvc |
| 集成 | `booking-app/src/test/java/` | `@SpringBootTest`（按需） |

Controller 测试在 **BFF**，不在 `*-impl`。

### 2.5 缺口三分法

| 类型 | 动作 |
|------|------|
| **阻断** | 错误码/字段/OpenAPI 冲突、权限不明 → 不写实现 |
| **整改** | URL 不合规 → 步骤 6 同步 Controller + OpenAPI + 详设 |
| **可补充** | `[AI推断]` 标注后实现 |

### 2.6 契约偏差

- 详设 vs OpenAPI **业务语义**冲突 → **以 OpenAPI 为准**，暂停并回溯 detail-design
- 仅 URL/路径 → 本 Skill 可同步整改
- AC 无法满足 → 列偏差，建议改 Story，不静默改需求

---

## 3. 标准流程（八步摘要）

```text
 1. 加载清单、Rule、画像、详设 §8/§9
 2. 解析 Story（AC、模块、执行模式）
 3. 查找详设、OpenAPI、schema
 4. 模块终判 + 缺口清单
 5. 增量计划（默认继续执行）
 6. 分层 TDD 实现
 7. Story 范围 mvn test
 8. 对话输出实现汇总
```

---

## 4. Skill 与 Rule 分工

| 谁 | 管什么 |
|----|--------|
| **feature-coding Skill** | 八步流程、缺口、增量 TDD、授权边界 |
| **rules/java-project.md** | 双 BFF、api/impl、依赖方向、URL 前缀 |
| **rules/tdd-project-conventions.md** | JUnit 5、测试分层、断言约定 |
| **rules/exception-and-result.md** | `Result`、`BizException`、错误码号段 |
| **rules/mybatis-conventions.md** | Mapper/XML、MyBatis Plus 范围 |
| **implementation-checklist.md** | 每层可勾选自检项 |

冲突时：**规范听 Rule，流程听 Skill**。

---

## 5. 边界：本 Skill 不做

- Epic → Story（story-splitting）
- 详设/OpenAPI 从零编写（detail-design）
- 无变更记录时修改 Story AC
- 改 Rule、`_golden/`、非当前 Story 的业务契约

---

## 6. 与上下游衔接

```text
detail-design ──► feature-coding ──► mvn test 绿
  详设§8/OpenAPI      TDD 实现         实现汇总
```

| 上游 | 消费 |
|------|------|
| Story | AC/BR、变更记录、服务/模块 |
| 详设 | §4 领域模型、§5 API、§6 持久化、§8 骨架、§9 测试策略 |
| OpenAPI | BFF path、请求/响应、错误 examples |

---

## 7. 需求变更

1. **Story**：更新 AC + §7 变更记录（story-splitting 或人工）
2. **detail-design**：增量详设 + OpenAPI
3. **feature-coding**：读变更记录 → 删/改废弃测试 → 红绿 → mvn test

Story 未更新但要求改实现 → **拒绝**。

---

## 8. 与公司级 Python Demo 的差异

| 维度 | 公司级 Demo | 本仓库 |
|------|-------------|--------|
| 代码根 | `app/modules/` | `*-api`/`*-impl`、BFF |
| 测试 | `pytest tests/unit/` | `mvn test` + `src/test/java` |
| 配置 | `config/current-sprint`（模板约定路径）| `config/current-sprint` |
| 测试样板 | `tests/_golden/` | Golden DD §9 + 同模块 `*Test.java` |
| URL | `/{product}/api/v1/{module}/` | `/api/v1/booking/app|admin/` |
| 单元测试质量 Rule | `unit-test-quality.md` | [test-quality.md](../../skills/feature-coding/references/test-quality.md) |
| 分层 Rule | `api-layer` 等 | [layer-guides.md](../../skills/feature-coding/references/layer-guides.md) |
| 架构 Rule | `architecture.md` | `rules/java-project.md` |
| 其它 Skill | `test-quality-audit` / `bug-fix` | 未落地；边界见主 Skill |

---

## 9. 延伸阅读

| 文档 | 说明 |
|------|------|
| [implementation-checklist.md](../../skills/feature-coding/references/implementation-checklist.md) | 分层自检清单 |
| [layer-guides.md](../../skills/feature-coding/references/layer-guides.md) | Mapper/Service/BFF/Client 编码 |
| [bff-domain-boundary-guide.md](../../skills/detail-design/references/bff-domain-boundary-guide.md) | BFF guard vs 域规则；§8 重复时阻断 |
| [test-quality.md](../../skills/feature-coding/references/test-quality.md) | 单元测试质量 |
| [README.md](../../skills/feature-coding/README.md) | 配套与公司级映射 |
| [detail-design.md](./detail-design.md) | 上游详设思想 |
| [memory-safe-io-guide.md](../../reference/memory-safe-io-guide.md) | 上传/导出流式 IO（命中时） |
| [story-splitting.md](./story-splitting.md) | 上游 Story 思想 |
| [AGENTS.md](../../../AGENTS.md) | 系统画像入口 |
