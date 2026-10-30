# STORY-{迭代}-{序号}-{slug}

| 字段 | 值 |
|------|-----|
| 迭代 | {迭代} |
| 状态 | 草稿 / 评审中 / 已确认（= 已通过审查，须有 `docs/reviews/{迭代}/REVIEW-*` 报告，见 [rules/story-review.md](../../../rules/story-review.md)） |
| 实现波次 | W0 Foundation / W1 主链路 / W2 扩展 / W3 低耦合 |
| 来源 | {Epic / PRD} · {HLD 建议 Story 若有} · 原型「{工程名}」`{主 HTML 路径}`（如 `目的地.html`） |
| 复杂度 | 简单 / 中等 / 高复杂 |
| 服务/模块 | booking-bff-app / booking-bff-admin / booking-order / booking-inventory / booking-parking-adapter / booking-common / 集成 |

## 1. 用户故事

作为 **{角色}**，我想 **{意图}**，以便 **{价值}**。

## 2. 范围

### 2.1 目标

- 

### 2.2 非目标

- 

## 3. 业务规则（BR）

> 简单 Story 可省略；跨 Story 共享 BR 在依赖链最上游定义，其他 Story 用 `STORY-xxx.BRn` 引用。

| 编号 | 规则 | 备注 |
|------|------|------|
| BR-01 | | |

## 4. 验收标准（AC）

> 格式见 `rules/story-ac-conventions.md`。失败类须写具体用户可见文案。  
> 落盘前按 [ac-completeness-checklist.md](../references/ac-completeness-checklist.md) 补全异常/边界 AC（主路径、BR 失败语义、参数校验、查询类输入规范化等）。

### AC-01：{标题}

- **Given** 
- **When** 
- **Then** 

## 5. 依赖与追溯

> 阻塞依赖与消费方须区分（见 story-splitting §5.6）。**阻塞依赖的上游 Story 序号必须小于本卡。**

| 类型 | 引用 |
|------|------|
| 原型页 | `{主 HTML}` — 对齐检查见 story-splitting §5.4 |
| **阻塞依赖 Story** | `STORY-{迭代}-{序号}-{slug}`（无此前置不可验收本卡） |
| **消费方 Story** | `STORY-{迭代}-{序号}-{slug}`（本卡产出被其使用；本卡序号更小） |
| 后续 Story（同旅程） | |
| 引用 BR | `STORY-xxx.BRn` |
| 迭代交付计划 | [README-{迭代}-迭代交付计划.md](../README-{迭代}-迭代交付计划.md) |
| 系统画像 | [system-landscape.md](../../../architecture/system-landscape.md) |

## 6. 测试关注点（可选）

> QA 风险提醒，不必每条对应 AC。简单 Story 可省略。

- 

## 7. 变更记录

| 日期 | 变更 | 作者 |
|------|------|------|
| | | |

## 8. AI 推断项（若有）

| 项 | 推断内容 | 依据 |
|----|----------|------|
| | `[AI推断]` | |
