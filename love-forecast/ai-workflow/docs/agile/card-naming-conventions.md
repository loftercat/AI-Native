# 敏捷卡片命名约定

迭代标识：`{年}-S{两位序号}`（例 `2026-S01`）。

## 文档路径

| 工件 | 路径 |
|------|------|
| Epic 需求 | `docs/requirements/epics/EPIC-{slug}.md` |
| 旅程场景（JSD） | `docs/requirements/epics/JSD-EPIC-{slug}.md` |
| 概设（HLD） | `docs/design/epics/HLD-EPIC-{slug}.md` |
| Story | `docs/requirements/{迭代}/STORY-{迭代}-{序号}-{slug}.md` |
| 详设 | `docs/design/{迭代}/DD-STORY-{迭代}-{序号}-{slug}.md` |
| 测试规格 | `docs/test-spec/{迭代}/TS-STORY-{迭代}-{序号}-{slug}.md` |
| 审查报告 | `docs/reviews/{迭代}/REVIEW-STORY-{迭代}-{序号}-{slug}.md` |

## 命名规则

- **序号**：迭代内从 `001` 递增
- **slug**：小写英文连字符，如 `checkpoint-middleware`、`health-api`
- **Golden**（方法论样例）：放在 `docs/requirements/_golden/`、`docs/design/_golden/HLD-EPIC-GOLDEN-*` 等 `_golden` 目录，不用真实迭代号

## 当前迭代

单一事实源：`config/current-sprint`（仅一行迭代 ID）。

迭代日历（可选）：`docs/agile/sprint-registry.yaml`
