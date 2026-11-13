---
name: api-blackbox-test
description: >-
  从 090 产出的 execution=blackbox 行 + OpenAPI 生成部署后 API 黑盒 pytest 脚本，
  在已部署测试环境执行冒烟/回归，验证部署态可用性。用于黑盒自动化、发版冒烟、
  提测回归等场景。
---

> **模板版说明**：本 Skill 自已落地的源项目抽取为通用模板。文中项目专属值（模块名 `booking-*`、包名 `com.hema`、错误码号段、具体路径与 Story 号）均为**示例**，接入项目时按 [MIGRATION.md](../../../MIGRATION.md) 清单替换；「本仓库」指接入后的目标项目。


# API 黑盒自动化（execution=blackbox → pytest 部署后脚本）

以 090 产出 `AC-STORY-*.md` 中 `execution=blackbox` 行 + OpenAPI 为输入，
生成 pytest 脚本 + 冒烟 manifest，在已部署测试环境执行。

本 Skill 对齐 [test-line.md](../../docs/methodology/test-line.md) §4.2~§4.3，是 QA 专线部署后执行层。
**产出为 pytest 脚本 + manifest**，**不写** Java 测试、**不改** Story/TS/OpenAPI。

## 定位与边界

- **做什么**：从 blackbox 行 + OpenAPI 生成 pytest（conftest + test_*.py）+ smoke-manifest；
  标 `@pytest.mark.story/ac/legacy_tc`；断言粗粒度（HTTP 200 + result.code==200 + 关键字段）
- **不做**：写 Java 测试（归 `feature-coding` / `integration-test-design`）
- **不做**：替代 IT（IT 守 PR 进程内逻辑；本 Skill 守部署态）
- **不做**：生成验收 GWT 正文（归 `qa-acceptance-case-design`）
- **不做**：改 Story/TS/OpenAPI/Rule 正文
- **不做**：定义 GitLab CI job（仅 README 描述衔接；CI 另 Story）
- **不做**：接生产环境；仅测试/预发 base URL

## 何时触发

- 部署到测试环境后（提测/发版流水线）；**不在** MR 默认 `mvn test`
- 090 产出 `AC-STORY-*.md` 含 `execution=blackbox` 行时
- 需求变更时：先增量更新 pytest + manifest，废弃 AC 标 `obsolete`

## 前置加载（按序点名）

| # | 资产 | 路径 | 缺失时 |
|---|------|------|--------|
| 1 | 黑盒范围指引 | `references/blackbox-scope-guide.md` | **阻断** |
| 2 | 冒烟 manifest 模板 | `templates/smoke-manifest-template.yaml` | **阻断** |
| 3 | Golden pytest 范本 | `tests/blackbox/test_smoke_golden_*.py` | 降级 |
| 4 | 验收清单（090 产出） | `docs/qa/{迭代}/AC-STORY-{迭代}-{序号}-*.md`（按 Story 号自动查找） | 阻断见步骤 2 |
| 5 | OpenAPI | 从 AC-STORY「来源」字段解析（可多个 `docs/api/{服务标识}/openapi.yaml`） | 阻断见步骤 2 |
| 6 | IT Skill（去重参照） | `../integration-test-design/SKILL.md` | 降级 |
| 7 | TS（可选去重参考） | `docs/test-spec/{迭代}/TS-STORY-*.md` | 跳过 |
| 8 | 系统画像 | `architecture/system-landscape.md` | 降级 |
| 9 | 迭代 | `config/current-sprint` | — |
| 10 | 代码审查规则 | `rules/code-review.md` | **阻断**（步骤 7） |
| 11 | 代码审查报告模板 | `templates/code-review-report.md` | **阻断**（步骤 7） |

> **缺失阻断提示**：「缺黑盒范围指引/manifest 模板，无法确定去重规则与选集结构」

## 输入

- **必备**：Story 编号（`STORY-{迭代}-{序号}`）；按编号自动查找 `AC-STORY-{迭代}-{序号}-*.md`，OpenAPI 路径从其「来源」字段解析
- **可选**：TS（去重参考）、conftest 既有环境配置；显式 `@` AC-STORY / OpenAPI 可覆盖自动查找结果

### 触发示例

```text
/api-blackbox-test STORY-2026-S01-001

增量：为 STORY-xxx 补 execution=blackbox 行的 pytest
```

## 输出

- `tests/blackbox/test_*.py`（pytest 脚本，含 `@pytest.mark.story/ac/legacy_tc`）
- `tests/blackbox/smoke-manifest.yaml`（或独立 manifest，按 Story/迭代组织）
- 代码审查报告（步骤 7）：`docs/reviews/{迭代}/REVIEW-CODE-BB-{Story编号}-{slug}.md`
- **不产生** Java 代码；**不改** Story/TS/OpenAPI/Rule

## 标准流程

### 步骤 1：加载资产清单

按 §前置加载点名；guide/manifest 模板缺失 → **阻断**。

### 步骤 2：核对输入

- 按 Story 编号 `STORY-{迭代}-{序号}` 在 `docs/qa/{迭代}/` 下 glob `AC-STORY-{迭代}-{序号}-*.md` 自动加载
- 无 `AC-STORY-*.md` → **阻断**，提示提供 090 产出
- 解析 AC-STORY「来源」字段取 OpenAPI 路径并加载；「来源」缺 OpenAPI 路径 → **阻断**（BR-01），message 含「AC-STORY 来源字段缺 OpenAPI 路径，请回 090 补全」
- `AC-STORY-*.md` 无 `execution=blackbox` 行 → 输出「本 Story 无黑盒候选，跳过」
- `execution=ci_covered` 行 → **跳过 pytest 生成**（090 BR-05 双条件已判定：TS 全覆盖 **且** 无部署态独有验证点）；不复制等价 pytest 步骤
- `execution=manual` / `frontend_only` / `obsolete` 行 → **跳过**（非黑盒）
- blackbox 行缺 `blackbox_rationale` → 记录进汇总 §5 [AI推断] / §7 建议后续，不猜

### 步骤 3：去重判定（按 guide §去重）

按 [blackbox-scope-guide.md](references/blackbox-scope-guide.md)：

1. 读 TS/IT 对该 AC 的覆盖标记
2. TS/IT 已做 DB+错误码断言 → **不生成**细粒度失败分支（BR-03）
3. 仅允许该业务域 1 条主路径 `code=200` + 关键字段存在性

### 步骤 4：生成 pytest

- 每条 blackbox 行 → 1 个 test 函数
- import 仅 `requests`/`httpx`；**禁止** Spring Test / Java 进程内启动（AC-04）
- 断言粗粒度：HTTP 200、`result.code==200`、少量关键字段（BR-04）
- `@pytest.mark.story("STORY-xxx")` + `@pytest.mark.ac("AC-xx")`（BR-08）
- legacy_tc 用 `@pytest.mark.legacy_tc("TC-xxx")`
- 失败输出含 URL + status（BR-07）

### 步骤 5：更新 manifest

- 按 `domain` 分组；标 `type=smoke|regression|health|auth_probe`
- smoke = 各域 1 主路径 + 横切 health/auth_probe（BR-05）
- regression = 其余 blackbox 候选，按影响面选集
- 边缘场景默认不进 manifest（BR-06）；例外注理由

### 步骤 6：落盘 + 产出汇总

- 路径：`tests/blackbox/test_*.py` + `tests/blackbox/smoke-manifest.yaml`
- 产出汇总（对话输出，默认不落盘）：

```markdown
## 黑盒自动化汇总 — {Story编号}
### 1. 产出文件清单
### 2. blackbox 行 → pytest 映射表
### 3. 去重跳过清单（TS/IT 已覆盖）
### 4. manifest 变更摘要
### 5. [AI推断] 清单
### 6. 阻断问题清单（若有）
### 7. 建议后续 → 部署后执行 pytest
### 8. 代码审查
- 报告：docs/reviews/{迭代}/REVIEW-CODE-BB-{Story编号}-{slug}.md
- 档位/结论：{L1/L2/L3} / {通过/不通过}
```

### 步骤 7：独立代码审查（合入前）

按 [code-review.md](../../rules/code-review.md) §二 定档（通常 L1/L2；>8 文件/diff >400 行或含业务代码/跨模块 → L3），按 §三 给全输入（档位、Story/AC、diff + 本次新增脚本、AC-STORY/OpenAPI、pytest 结果、关注点）；审查人只读，实现者落盘 `docs/reviews/{迭代}/REVIEW-CODE-BB-{Story编号}-{slug}.md`；按 §五 档位闭环。重点：Token/URL 不硬编码、不接生产、断言粗粒度、去重、失败输出可定位。L0 例外：纯注释/格式化/重命名/日志文案不送审，回复说明跳过原因；审查完成后回填步骤 6 汇总的「代码审查」节，再输出最终汇总。

## 降级策略

| 缺失 | 处理 |
|------|------|
| Golden pytest 范本 | 按 guide + manifest 模板硬写，标 `[AI推断]` |
| IT Skill（去重参照） | 仅按 TS 去重；无 TS 则不跳过（可能重复，汇总提示） |
| TS | 跳过去重；仅按 `AC-STORY` blackbox 行生成 |
| 系统画像 | 按 OpenAPI `servers` 推断 base URL |
| 代码审查规则/模板 | 步骤 7 **阻断**，不能跳过审查 |

## 边界

- **不改**：Story/详设/OpenAPI/TS/Rule/Java 业务代码
- **不写**：Java 测试（`*Test`/`*IT`）
- **不生成**：验收 GWT（归 090）
- **不定义**：GitLab CI job（仅 README 描述）
- **不接**：生产环境
- **不造数**：造数属 `test-data-design`

## 延伸阅读

- [test-line.md](../../docs/methodology/test-line.md) §4.2~§4.3
- [qa-acceptance-case-design SKILL](../qa-acceptance-case-design/SKILL.md)（上游）
- [integration-test-design SKILL](../integration-test-design/SKILL.md)（去重参照）
- [blackbox-scope-guide.md](references/blackbox-scope-guide.md)
- [smoke-manifest-template.yaml](templates/smoke-manifest-template.yaml)
