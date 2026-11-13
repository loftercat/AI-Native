# 数据画像 Golden 范本（`docs/qa/data-profiles/_golden/`）

> **模板说明**：本目录是方法论样例（Golden），正文中的文件链接指向源项目历史工件，在本模板中不可达属预期；接入项目重写 Golden 时用本项目真实路径。

> **勿将本目录当作真实迭代落盘位置。** 真实 Story 产出落在 `docs/qa/data-profiles/{迭代}/DP-STORY-{迭代}-{序号}-{slug}.yaml`。

| 文件 | 用途 |
|------|------|
| DP-STORY-GOLDEN-001-space-query.yaml | 演示 DP 结构与粒度；输入同源 AC-STORY-GOLDEN-001 中 `execution=blackbox` 行（AC-01、AC-03） |

## `seed_key` 前缀（Golden Story）

与 seed-channel-guide §2.4 一致，Golden 使用：

```text
g001-{profile_id}
```

| 片段 | 含义 |
|------|------|
| `g001` | `STORY-GOLDEN-001` 的缩写前缀（与真实迭代 `s02-007-…` 区分，避免同库撞 key） |
| `{profile_id}` | DP 内画像 ID，如 `smoke-main` |

**本目录仅含 DP 范本**，不附带 `tests/data/seed_*.py`；真实试点造数脚本见 tests/data/README.md 追溯表。

## 与真实试点对照

| 维度 | Golden 范本 | 真实试点（S02-007） |
|------|-------------|---------------------|
| DP | `docs/qa/data-profiles/_golden/DP-STORY-GOLDEN-001-space-query.yaml` | `docs/qa/data-profiles/2026-S02/DP-STORY-2026-S02-007-space-query.yaml` |
| seed | —（结构示范） | `tests/data/seed_s02_007_space_query.py` |
| blackbox | `tests/blackbox/test_smoke_golden_space_query.py` | `tests/blackbox/test_smoke_2026_s02_007_space_query.py`（若已生成） |
