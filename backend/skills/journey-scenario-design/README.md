# 旅程与场景设计配套（journey-scenario-design）

| 文档 | 用途 |
|------|------|
| [jsd-template.md](templates/jsd-template.md) | JSD 落盘模板（Persona + 旅程图 + 场景矩阵） |
| [concepts-guide.md](references/concepts-guide.md) | 概念定义与划分标准（官方权威出处；旅程/场景分几条的判定标准） |
| [scenario-branch-checklist.md](references/scenario-branch-checklist.md) | 场景分支挖掘清单（24 维度逐场景扫描） |

执行 Skill：`skills/journey-scenario-design/SKILL.md`

## 定位

流水线**最上游**：输入业务原始需求（PRD 草稿 / 口头需求 / 原型），产出 `docs/requirements/epics/JSD-EPIC-{slug}.md`。

```text
原始需求 ──► journey-scenario-design ──► high-level-design ──► story-splitting ──► detail-design ──► ...
              JSD（旅程+场景）            HLD                    Story（AC 源于场景）
```

- **旅程管广度**（路径不缺环）→ HLD §5 关键流程、Story 波次划分的依据
- **场景管深度**（每步不缺分支）→ Story AC 的直接前身；`story-splitting` 的 AC 完备性检查以场景清单为源头
- 角色与端须对齐 [system-landscape.md](../../architecture/system-landscape.md)（画像为权威，不在此复述系统清单）

需求卡：STORY-2026-S02-083（源项目需求卡）；详设卡：DD-STORY-2026-S02-083（源项目详设卡）。（本仓库审计链接，跨项目迁移时删除）
