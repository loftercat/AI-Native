# Golden 约定

> 本文件约定 `_golden/` 的定位、路径与验收标准；样例目录见 `docs/**/_golden/`。
> 模板仓中的 Golden 是源项目样例，接入时必须用本项目真实工件重写（见 [MIGRATION.md](../../MIGRATION.md) §一.3）。

Golden 是**格式与粒度范本**，不是可复用的业务资产。接入新项目时：

1. **不要直接沿用模板仓的 Golden**（域不同、术语不同，会误导下游 Skill）。
2. 用新项目的**第一个真实 Story** 走完整条流水线（Story → DD → TS → 代码/测试 → 验收）。
3. 把该 Story 的产出复制为 `_golden`，原始迭代文件保持不动。

## 路径

| 工件 | 真实路径 | Golden 路径 |
|------|----------|-------------|
| Story | `docs/requirements/{迭代}/STORY-...` | `docs/requirements/_golden/` |
| HLD / DD | `docs/design/{迭代}/...` | `docs/design/_golden/` |
| TS | `docs/test-spec/{迭代}/TS-...` | `docs/test-spec/_golden/` |
| 验收用例 | `docs/qa/{迭代}/AC-STORY-...` | `docs/qa/_golden/` |
| 数据画像 | `docs/qa/data-profiles/{迭代}/DP-...` | `docs/qa/data-profiles/_golden/` |
| 遗留用例 | `docs/qa/legacy/...` | `docs/qa/legacy/_golden/` |

## 重写方式

按 [MIGRATION.md](../../MIGRATION.md) §一.3 执行：AI 从画像与词表选取真实业务域，保持文件名模式与结构重写；提交时随附「3 处关键改动 + 建议抽查 1 份」，不让人面对整套样例逐份终审。

## Golden 的验收标准

- Story 含完整 AC/BR 编号与「变更记录」；
- DD 含 §9 测试策略，且 §9 的每个测试类/关注点标注其覆盖的 AC（不要求方法名）；
- TS 的每条 AC 都能追溯到测试类/方法，失败路径断言具体 `code`/`message`；
- 至少覆盖一个失败路径与一个边界值；
- 与真实迭代文件同结构，不做「精简版」。

> 范本仅作结构参考，勿把 `_golden` 当作真实迭代目录。
