# 详设配套

执行 Skill：`skills/detail-design/SKILL.md`  
核心思想：[docs/methodology/detail-design.md](../../docs/methodology/detail-design.md)

## 文档清单

| 文档 | 用途 | 缺失时 |
|------|------|--------|
| [design-template.md](templates/design-template.md) | DD 落盘模板 | **阻断** |
| [ac-to-contract-guide.md](references/ac-to-contract-guide.md) | AC → OpenAPI / `XxxApi` | **阻断** |
| [code-skeleton-guide.md](references/code-skeleton-guide.md) | §8 Java 类/方法推导 | **阻断** |
| [domain-model-guide.md](references/domain-model-guide.md) | §4 领域模型；务实领域（贫血 + SQL 条件更新）；§4.4 代码落点 | **阻断** |
| [schema-conventions.md](references/schema-conventions.md) | `docs/schema/{服务}/schema.md` 字段表 + DDL；**§1.2** 雪花主键 / 软删除 | 含持久化 **阻断** |
| [bff-domain-boundary-guide.md](references/bff-domain-boundary-guide.md) | BFF guard vs 域规则、§8 单点归属 | 含 BFF + 域 **阻断** |
| [openapi-conventions.md](references/openapi-conventions.md) | OpenAPI / Swagger / 自动化测试 | 含 HTTP **阻断** |
| [special-scenarios.md](references/special-scenarios.md) | LLM/邮件/定时任务/大文件 IO |
| [../../reference/memory-safe-io-guide.md](../../reference/memory-safe-io-guide.md) | 上传/导出/ZIP 流式 IO | 命中大文件 IO 时加载 |
| [../../reference/idempotency-guide.md](../../reference/idempotency-guide.md) | 幂等性详设 |
| [../../reference/scheduled-task-guide.md](../../reference/scheduled-task-guide.md) | 定时任务详设 | 降级 |
| [../high-level-design/hld-dd-boundary-guide.md](../high-level-design/references/hld-dd-boundary-guide.md) | 概设 vs 详设 | 降级 |
| [../../design/_golden/DD-STORY-GOLDEN-001-booking-order-create.md](../../docs/design/_golden/DD-STORY-GOLDEN-001-booking-order-create.md) | DD 范本 | 降级 |

## 十一步流程摘要

```text
 1. 加载模板、指南、Golden、画像、Rule
 2. 解析 Story（AC/BR、自动查找）
 3. 架构上下文（双 BFF + 域模块、存量契约/代码）
 4. 缺口评估（阻断 / 可补充）
 5. 接口设计 + OpenAPI（BFF paths）
 6. 专项场景识别
 7. schema + MyBatis 分工 §6.2
 8. 时序图 §7
 9. Java 代码骨架 §8
10. 落盘（OpenAPI diff 须确认）
11. 对话汇总 → 提示 feature-coding
```

## 六类产出

| 产出 | 路径 |
|------|------|
| 详设 | `docs/design/{迭代}/DD-STORY-{迭代}-{序号}-{slug}.md` |
| 领域模型 | 详设 §4 |
| OpenAPI | `docs/api/{服务标识}/`、`love-app/` 等 |
| schema | `docs/schema/{服务标识}/schema.md`（字段表 + **DDL**） |
| 时序图 | 详设 §7 |
| Java 骨架 | 详设 §8 |

## 与公司级 Skill 的映射

| 公司级（Python Demo） | 本仓库（Java） |
|----------------------|----------------|
| `app/modules/{module}/` | `*-api`/`*-impl`、`love-app` |
| `api.py（公司级示例）` / Schema | BFF Controller + `*-api` DTO |
| `app/core/db/{module}/` | `*-impl/infrastructure/` DO + Mapper |
| 公司级 rules/architecture | `rules/java-project.md` |
| 公司级 rules/database-model | `rules/mybatis-conventions.md` + [schema-conventions.md](references/schema-conventions.md) |
| 公司级 rules/exception-handling | `rules/exception-and-result.md` |
| `product-overview（公司级示例） | `architecture/system-landscape.md` + Epic/HLD |
| `docs/api/openapi.yaml`（单体） | `docs/api/{服务标识}/openapi.yaml` 等 |
| `tests/_golden/` | `docs/design/_golden/` DD 范本 |

## 边界

- 不做 story-splitting、feature-coding
- 不改 Story、Rule、system-landscape
- OpenAPI 业务变更须用户确认 diff 后合并
