# TS-LEGACY-{module}

> 遗留测试规格（存量用例迁移）。配套 [legacy-test-migration SKILL](../SKILL.md)。
> 与 `test-spec-alignment` 的 TS **结构对齐**（用例追溯），差异：面向**存量**（有 `legacy_tc_id`/`gate`/`下游`）。

| 字段 | 值 |
|------|-----|
| 模块 | {module} |
| 来源用例文件 | {export.csv} |
| 生成日期 | {date} |
| 矩阵 | `docs/qa/legacy/{project}/tc-classification.csv` |

## 1. 汇总

| 维度 | 计数 |
|------|------|
| 总用例 | {N} |
| `gate=ok` 可自动化 | {n1} |
| `G1` 需修订 | {n2} |
| `G2` 手工 | {n3} |
| `G3` 废弃候选 | {n4} |
| `G4` 阻塞 | {n5} |
| `merged` 合并 | {n6} |

| layer | 条数 | 下游 |
|-------|------|------|
| W1 | {n} | feature-coding |
| W2 | {n} | feature-coding |
| W3 | {n} | integration-test-design |
| W4 | {n} | integration-test-design |
| W5 | {n} | feature-coding |
| B1 | {n} | api-blackbox-test |
| B3 | {n} | api-blackbox-test |
| B5 | {n} | integration-test-design + test-data-design |

## 2. 用例明细

### TC-0001 — {标题}

| 字段 | 值 |
|------|-----|
| gate | ok |
| layer | W2 |
| strategy | smoke |
| status | automated |
| coverage | `SpaceQueryController#query` |
| merged_into | — |
| blocker | — |
| 下游 | feature-coding |

- **Given** ...
- **When** ...
- **Then** ...

### TC-0008 — {标题}（需修订）

| 字段 | 值 |
|------|-----|
| gate | G1 |
| layer | — |
| status | needs_revision |
| blocker | 缺预期结果 |
| 下游 | 待人工补齐后重分类 |

- **Given** ...
- **When** ...
- **Then** （缺失）

## 3. 待人工确认清单

| legacy_tc_id | 类型 | 待确认内容 |
|--------------|------|------------|
| TC-0006 | G2 | 是否需保留手工 / 是否可构造自动化 |
| TC-0007 | G3 | 功能是否确已下线（产品/QA 签字） |
| TC-0008 | G1 | 补预期结果 |
| TC-0009 | G4 | 是否提供代码仓访问 |

## 4. 下游交接

| layer | 下游 Skill | 交接物 |
|-------|-----------|--------|
| W1/W2/W5 | feature-coding | 本文件 §2 对应用例段 + 矩阵行 |
| W3/W4 | integration-test-design | 同左 + 入口类 |
| B1/B3 | api-blackbox-test | 同左 + OpenAPI 路径 |
| B5 | integration-test-design + test-data-design | 同左 + Given |
