# 卡片命名

迭代：`{年}-S{两位序号}`（格式 `{YYYY-Snn}`，取自 `config/current-sprint`）

| 类型 | 模式 | 格式示意 |
|------|------|----------|
| Epic 需求 | `EPIC-{slug}.md` | `EPIC-{feature-slug}.md` |
| 旅程场景（JSD） | `JSD-EPIC-{slug}.md` | `JSD-EPIC-{feature-slug}.md` |
| 概设（HLD） | `HLD-EPIC-{slug}.md` | `HLD-EPIC-{feature-slug}.md` |
| Story | `STORY-{迭代}-{序号}-{slug}.md` | `STORY-{YYYY-Snn}-001-{slug}.md` |
| 详设 | `DD-STORY-{迭代}-{序号}-{slug}.md` | `DD-STORY-{YYYY-Snn}-001-{slug}.md` |
| 测试规格 | `TS-STORY-{迭代}-{序号}-{slug}.md` | `TS-STORY-{YYYY-Snn}-001-{slug}.md` |
| 验收用例 | `AC-STORY-{迭代}-{序号}-{slug}.md` | `AC-STORY-{YYYY-Snn}-001-{slug}.md` |
| 提测追溯表 | `tc-traceability{-{迭代}}.csv` | `tc-traceability-{YYYY-Snn}.csv` |
| 黑盒 manifest | `smoke-manifest{-{迭代}}.yaml` | `smoke-manifest-{YYYY-Snn}.yaml` |
| 黑盒 pytest | `test_{type}_{service}_{slug}.py` | `test_smoke_{service}_{slug}.py` |

- `slug`：小写英文连字符，简短表意
- 序号：三位或两位数字，迭代内递增
- Golden 范本：`docs/requirements/_golden/` 等（非真实迭代）

详见 [docs/agile/card-naming-conventions.md](../docs/agile/card-naming-conventions.md)
