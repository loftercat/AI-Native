# 功能编码配套

执行 Skill：`skills/feature-coding/SKILL.md`  
核心思想：[docs/methodology/feature-coding.md](../../docs/methodology/feature-coding.md)

## 文档清单

| 文档 | 用途 | 缺失时 |
|------|------|--------|
| [implementation-checklist.md](references/implementation-checklist.md) | 分层实现自检 | **阻断** |
| [../detail-design/bff-domain-boundary-guide.md](../detail-design/references/bff-domain-boundary-guide.md) | BFF guard vs 域规则 | 含 BFF + 域 **必读** |
| [layer-guides.md](references/layer-guides.md) | Mapper/Service/BFF/Client 编码指引 | 降级 |
| [test-quality.md](references/test-quality.md) | 单元测试质量（对应公司级 unit-test-quality） | 降级 |
| [rules/code-review.md](../../rules/code-review.md) | 代码审查规则（步骤 8） | 步骤 8 前必读 |
| [code-review-report.md](../../templates/code-review-report.md) | 代码审查报告模板 | 步骤 8 前必读 |
| [docs/design/summaries/](../../docs/design/summaries/) | 实现汇总可选落盘目录 | — |

## 本仓库要点（微服务架构）

- **服务独立**：API 网关 + 独立 BFF（对外 HTTP）+ 独立领域微服务（每服务独立启动与独立数据库）
- **契约与实现分离**：`*-api` 远程契约 + `*-impl`（内部远程入口 → Facade → Service → 持久化）；默认 **贫血 + 条件 UPDATE**，见 [layer-guides.md](references/layer-guides.md) 与 [domain-model-guide.md](../detail-design/references/domain-model-guide.md)
- **跨服务调用与技术选型**：同步调用协议（P-2）、ORM（P-3）、响应/错误码（P-4）、内部防护（P-5）等一律读 `architecture/system-landscape.md` §5.4，未拍板则阻断
- **验证**：单仓库多服务用 `mvn test -pl {service-module} -am`；独立仓库直接 `mvn test`
- **异常与响应**：通用异常纪律见 `rules/exception-and-result.md`，具体封装以画像 §3.7（P-4）为准

## 前置加载（按序）

| # | 资产 | 路径 |
|---|------|------|
| 1 | 实现检查清单 | [implementation-checklist.md](references/implementation-checklist.md)（**阻断**） |
| 2 | Rule | `rules/java-project.md`、`rules/tdd-project-conventions.md`、`rules/exception-and-result.md`、`rules/mybatis-conventions.md` |
| 3 | 测试质量 | [test-quality.md](references/test-quality.md) |
| 4 | Golden 测试参考 | `docs/design/_golden/DD-STORY-GOLDEN-001-*.md` §9 |
| 5 | Story + 详设 | `docs/requirements/{迭代}/STORY-*.md`、`docs/design/{迭代}/DD-*.md` |
| 6 | OpenAPI | `docs/api/{服务标识}/`、`docs/api/booking-bff-admin/` |
| 7 | schema | `docs/schema/{服务}/schema.md` |
| 8 | 系统画像 | `architecture/system-landscape.md` |
| 9 | 代码审查 | [rules/code-review.md](../../rules/code-review.md)、[code-review-report.md](../../templates/code-review-report.md) |

## 九步流程摘要

```text
1. 加载上下文（清单 + Rule + layer-guides + 画像）
2. 解析 Story（编号、AC、模块、执行模式）
3. 查找详设 / OpenAPI / schema
4. 模块终判 + 缺口清单
5. 增量计划（默认继续执行）
6. 分层 TDD（Mapper → api → Service → BFF）
7. mvn test 验收
8. 独立代码审查（commit / IT 前）
9. 对话输出实现汇总（可选落盘 `docs/design/summaries/`）
```

## 与公司级 Skill 的映射

| 公司级（Python Demo） | 本仓库（Java） |
|----------------------|----------------|
| `app/modules/{module}/` | `*-api`/`*-impl`、`booking-bff-*` |
| `tests/unit/{module}/` | `*/src/test/java/` |
| `pytest` | `mvn test` |
|  `rules` | `rules/` |
| 公司级 rules/unit-test-quality | [test-quality.md](references/test-quality.md) |
| `api-layer` / `service-layer` 等 Rule | [layer-guides.md](references/layer-guides.md) |
| `tests/_golden/` | `docs/design/_golden/` §9 + 同模块 `*Test.java` |
| `/{product}/api/v1/{module}/` | `/api/v1/booking/app|admin/` |
| `test-quality-audit` / `bugfix` | `test-quality-audit` 未落地；`bugfix` 已落地（旁路） |

## 边界

- 不做 story-splitting、detail-design 职责
- 不改 Story 卡（无变更记录时拒绝改 AC）
- 不改 `_golden/`、Rule
