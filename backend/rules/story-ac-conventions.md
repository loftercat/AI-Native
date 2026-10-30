# Story / AC 规范

格式由本 Rule 约束；拆分流程见 `skills/story-splitting/SKILL.md`。

## 路径

- Story：`docs/requirements/{迭代}/STORY-{迭代}-{序号}-{slug}.md`
- 详设：`docs/design/{迭代}/DD-STORY-{迭代}-{序号}-{slug}.md`
- 迭代 ID：`config/current-sprint`
- 模板：`skills/story-splitting/templates/story-template.md`

## Story 结构（按复杂度裁剪）

| 复杂度 | 必填 |
|--------|------|
| 简单 | 用户故事、范围、AC |
| 中等 | + BR、依赖、校验职责 |
| 高复杂 | + 测试关注点、DoD、风险 |

章节顺序以 `story-template.md` 为准。

## AC 格式

- 编号：`AC-01`、`AC-02`…
- 推荐 **Given / When / Then**；或明确 checklist
- 一条 AC 一个可判定行为；禁止「适当、尽量、等」
- **失败类**须写具体可见结果（如 `输出包含「…」`、`HTTP 404`），禁止「提示错误」
- **BR 映射**：含失败语义的 BR 须有对应失败 AC；流程见 `story-splitting` Skill §5.5 与 `ac-completeness-checklist.md`
- Story 标明影响层：**BFF / API / Service / Domain / Mapper / MQ / 集成**

## BR 格式

- 编号：`BR-01`…；可复用业务规则
- 跨 Story 共享：在最上游 Story 定义；其他 Story 引用 `STORY-{编号}.BRn`，不重复正文
- **产品 BR vs 实现 BR**：
  - **产品 BR**：原型/Epic/PO 可确认的**用户可见规则**（可否、须返回什么、失败语义）— 正文不写 `[AI推断]`
  - **实现 BR**：仅为满足 AC 而选的**算法/格式/阈值**（如匹配策略、排序、trim 规则）— **备注列须** `[AI推断]`，并同步写入 §8；**禁止**把实现细节写成已定稿产品规则

## [AI推断]

- 格式：`[AI推断]` 前缀 + 简短依据（写在 BR **备注列**、AC Then、或 §8 表）
- **凡实现 BR、排序规则、默认阈值、匹配算法** 必须标 `[AI推断]` 并汇总 §8
- 汇总在 Story §8 AI 推断项

## 变更

- 有变更时更新 §7 变更记录；废弃 AC 标「已废弃」及替代编号
- 不静默删除 AC

## Skill 边界

- `story-splitting` 只写 Story
- `detail-design` 不改 Story 正文
