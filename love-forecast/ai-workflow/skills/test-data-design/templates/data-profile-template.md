# 数据画像（DP）模板

> 配套 `test-data-design` Skill。把 AC-STORY 中 `execution=blackbox` 行的 Given 翻译为可执行的实体清单 + 状态 + 清理键。

## 文件命名

`docs/qa/data-profiles/{迭代}/DP-STORY-{迭代}-{序号}-{slug}.yaml`

## YAML 结构

```yaml
# DP-STORY-{迭代}-{序号}-{slug}.yaml
story_id: STORY-{迭代}-{序号}
slug: {slug}

profiles:
  - profile_id: {唯一 ID，如 smoke-main}        # 必填
    ac_ids: [AC-1, AC-6]                        # 必填，对应 AC
    description: {画像说明}                      # 必填
    extends: {父 profile_id}                     # 可选，复用父画像实体（BR-5）
    entities:                                   # 必填，按依赖顺序
      - table: {表名}                            # 必填，业务表名（按 DDL）
        seed_key: {seed_key}                    # 必填，命名见 seed-channel-guide §2.4，如 s02-007-smoke-main
        rows:                                   # 必填，行清单
          - {字段1}: {值1}                       # 字段名严格按 DDL
            {字段2}: {值2}
            ...
    cleanup_order: [{表3}, {表2}, {表1}]        # 必填，反序删除（依赖倒序）
    env_vars:                                   # 必填，blackbox pytest 经环境变量读
      BLACKBOX_SEARCH_KEYWORD: {关键词}
      BLACKBOX_DATA_PROFILE: {profile_id}
    # 身份列（partner_id/created_by/owner_id 等）按 system-landscape §4.3.4 测试账号约定表写死
    # 黑盒按 AC 挑对应 Token 环境变量（ADMIN_TOKEN_PARTNER / APP_TOKEN 等）
    # 本节不在 DP 里展开 identity 契约；约定见 system-landscape §4.3.4

  - profile_id: smoke-empty                    # 不造数画像
    ac_ids: [AC-2, AC-7]
    description: 校验 skip 行为，不造数
    entities: []
    cleanup_order: []
    env_vars: {}
```

## 字段说明

| 字段 | 必填 | 说明 |
|------|------|------|
| `story_id` | 是 | Story 编号 |
| `slug` | 是 | Story slug |
| `profiles[].profile_id` | 是 | 画像唯一 ID |
| `profiles[].ac_ids` | 是 | 对应的 AC 编号列表 |
| `profiles[].description` | 是 | 画像说明 |
| `profiles[].extends` | 否 | 复用父画像实体（仅追加差异行） |
| `profiles[].entities` | 是 | 实体清单（`smoke-empty` 时为 `[]`） |
| `profiles[].entities[].table` | 是 | 业务表名（按 DDL） |
| `profiles[].entities[].seed_key` | 是 | 清理键，命名见 [seed-channel-guide §2.4](../references/seed-channel-guide.md#24-seed_key-命名约定br-04)，如 `s02-007-smoke-main` |
| `profiles[].entities[].rows` | 是 | 行清单（字段名按 DDL；身份列如 `partner_id`/`created_by`/`owner_id` 按 [system-landscape §4.3.4](../../../architecture/system-landscape.md#434-测试账号约定供-test-data-design-skill-消费) 测试账号约定表写死） |
| `profiles[].cleanup_order` | 是 | 反序删除顺序（依赖倒序） |
| `profiles[].env_vars` | 是 | blackbox pytest 读的环境变量 |

## 字段名核对

**必须**按业务表 DDL（`docs/schema/{服务}/ddl/*.sql`），常见易错：

| 易错写法 | 正确（DDL） |
|----------|-------------|
| `has_charger` | `support_charge`（TINYINT 0/1） |
| `parking_lot.latitude/longitude` | `project.latitude/longitude`（V5 起，`parking_lot` 已移除） |
| `elevator.id` | `elevator.id`（PK） |

## 示例

| 类型 | 路径 |
|------|------|
| Golden 范本（结构/粒度） | `docs/qa/data-profiles/_golden/DP-STORY-GOLDEN-001-space-query.yaml` |
| 真实试点（S02-007） | `docs/qa/data-profiles/2026-S02/DP-STORY-2026-S02-007-space-query.yaml` |

说明见 `docs/qa/data-profiles/_golden/README.md`。
