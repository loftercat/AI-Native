# 卡片命名

迭代：`{年}-S{两位序号}`（例 `2026-S01`）

| 类型 | 模式 | 示例 |
|------|------|------|
| Epic 需求 | `EPIC-{slug}.md` | `EPIC-order-checkout.md` |
| 旅程场景（JSD） | `JSD-EPIC-{slug}.md` | `JSD-EPIC-order-checkout.md` |
| 概设（HLD） | `HLD-EPIC-{slug}.md` | `HLD-EPIC-order-checkout.md` |
| Story | `STORY-{迭代}-{序号}-{slug}.md` | `STORY-2026-S01-001-deep-research-trace.md` |
| 详设 | `DD-STORY-{迭代}-{序号}-{slug}.md` | `DD-STORY-2026-S01-001-deep-research-trace.md` |
| 测试规格 | `TS-STORY-{迭代}-{序号}-{slug}.md` | `TS-STORY-2026-S01-001-deep-research-trace.md` |
| 验收用例 | `AC-STORY-{迭代}-{序号}-{slug}.md` | `AC-STORY-2026-S01-001-query-allocate-space.md` |
| 提测追溯表 | `tc-traceability{-{迭代}}.csv` | `tc-traceability-2026-S01.csv` |
| 黑盒 manifest | `smoke-manifest{-{迭代}}.yaml` | `smoke-manifest-2026-S01.yaml` |
| 黑盒 pytest | `test_{type}_{域}_{slug}.py` | `test_smoke_golden_space_query.py` |

- `slug`：小写英文连字符，简短表意
- 序号：三位或两位数字，迭代内递增
- Golden 范本：`docs/requirements/_golden/` 等（非真实迭代）

详见 [docs/agile/card-naming-conventions.md](../docs/agile/card-naming-conventions.md)
