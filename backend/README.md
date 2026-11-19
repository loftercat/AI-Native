# backend：后端 AI 原生工作流模板

从已落地的源项目后端仓抽取。包含 **12 个 Skill、16 条 Rule、项目画像、QA 专线、旁路（bugfix / 存量迁移）**。

## 快速导航

| 我想… | 看 |
|--------|----|
| 日常使用 | [USAGE.md](USAGE.md) |
| 接入新项目 | [MIGRATION.md](MIGRATION.md) |
| 替换公共基础库 | [common-foundation-migration.md](docs/methodology/common-foundation-migration.md) |
| 查 Skill 与栈依赖 | [Skill清单与栈依赖.md](Skill清单与栈依赖.md) |
| 看 Golden 约定 | [docs/methodology/golden.md](docs/methodology/golden.md) |
| 看 Skill 治理 | [docs/methodology/skill-governance.md](docs/methodology/skill-governance.md) |
| 看整体流水线 | 根 [README.md](../README.md) |
| 看前端线 | [frontend/README.md](../frontend/README.md) |

---

## 质量门禁

| 对象 | 规则 | 执行要求 |
|------|------|----------|
| 文档工件（JSD / HLD / DD / TS） | [rules/artifact-review.md](rules/artifact-review.md) | 进入下一环前独立审查；P0/P1 必修 |
| Story（拆卡后、进详设前） | [rules/story-review.md](rules/story-review.md) | 报告模板 [templates/stage-review-report.md](templates/stage-review-report.md)；「已确认」= 有通过报告，校验器强制 |
| 代码（编码后 / 合并前） | [rules/code-review.md](rules/code-review.md) | 报告模板 [templates/code-review-report.md](templates/code-review-report.md)；L1/L2/L3 闭环 P0–P3 |

**自动校验**：`bash scripts/validate-skills.sh`（扫本线 skills/rules/templates/reference/architecture/glossary/docs-methodology + Story 审查门禁）。
