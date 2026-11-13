# backend：后端 AI 原生工作流模板

自已落地的源项目后端仓抽取。12 个 Skill + 15 条 Rule + 项目画像 + QA 专线 + 旁路（bugfix / 存量迁移）。

- **怎么用**：[USAGE.md](USAGE.md)（前置条件、入口选择、迭代走法、人工介入点）
- **怎么接入**：根 [MIGRATION.md](../MIGRATION.md) §一（画像必填 + 锚点替换清单）§二（与源项目差异）
- **质量门禁**：文档工件审查（[rules/artifact-review.md](rules/artifact-review.md)；JSD / HLD / DD / TS 进下一环前送独立审查，P0/P1 必修）；Story 审查最小闭环（[rules/story-review.md](rules/story-review.md) + [templates/stage-review-report.md](templates/stage-review-report.md)；「已确认」= 有通过报告，校验器强制）；代码审查（[rules/code-review.md](rules/code-review.md) + [templates/code-review-report.md](templates/code-review-report.md)；编码后/合并前，按 L1/L2/L3 闭环 P0–P3）
- **校验**：`bash scripts/validate-skills.sh`（扫本线 skills/rules/templates/reference/architecture/glossary/docs-methodology + Story 审查门禁）
- **流水线全景与 Skill 一览**：根 [README.md](../README.md)

前端线（消费后端 OpenAPI handoff 契约）见 [../frontend/README.md](../frontend/README.md)。
