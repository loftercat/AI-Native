---
name: flutter-story-splitting
description: >-
  将 Epic/PRD/原型及适用的后端 OpenAPI handoff 拆为带 AC 的 Flutter Story 卡（STORY-FL-*）。
  用于 Flutter 需求拆解、迭代规划、写 docs/requirements 时。不改 OpenAPI、不写后端代码。
---

> **模板版说明**　示例业务与客户端工作流共用。接入 Flutter 项目时按[使用手册](../../USAGE.md)填写[系统画像](../../architecture/system-landscape.md)，以本工程的组件、路由和契约替换示例值。


# Flutter Story 拆分（flutter-story-splitting）

## 1. 定位

**把 Epic/PRD/原型及适用的后端 OpenAPI 拆成可独立验收的 Flutter Story（AC/BR + 本卡 operationId 范围），落盘到迭代目录——写明双端可验收行为，不做详设、页面代码。**

## 2. 何时触发

- 新 Epic / 迭代规划 / 从 PRD 或后端 Story 拆客户端卡
- 用户要求写 `docs/requirements/{迭代}/STORY-FL-*.md`

**不触发**：页面详设、组件代码、OpenAPI 设计。

## 3. 前置加载（按序）

| # | 资产 | 路径 | 缺失时 |
|---|------|------|--------|
| 1 | 迭代 | `config/current-sprint` | 询问用户 |
| 2 | 系统画像 | `architecture/system-landscape.md` | **阻断** |
| 3 | AGENTS.md | 做什么 / 不做什么 | 必须读 |
| 4 | 后端 OpenAPI | `docs/handoff/openapi/{后端服务标识}.yaml` | **阻断**（调用后端 API 时必备；纯 UI、本地或仅原生 SDK 的卡填 N/A） |
| 5 | 契约版本 | `docs/handoff/VERSION` | **阻断**（同第 4 项） |
| 6 | Epic/PRD/原型 | Epic 来源路径 | 必须有（至少其一） |
| 7 | 后端 Story 摘要 | §1 用户故事 + §2.3 客户端职责 + 相关 AC/BR | 强烈推荐 |
| 8 | 词表 | `glossary/domain-glossary.md` | 降级 |
| 9 | Rule | `rules/flutter-project.md`、`rules/api-client-conventions.md` | 必须读 |

## 4. 拆卡步骤

```text
1. 读 Epic/PRD/原型 → 划定 Android/iOS 验收范围、页面和用户价值 → 候选 STORY-FL
2. 对网络 AC，在 openapi.yaml 检索本页 paths → 列出 operationId 清单
3. 读每个 operation 的 examples → 把分支写成可验收 AC（Given/When/Then）
4. 视觉项在「设计稿」节登记稿件位置与状态（§6）；无稿的项标 `UI: TBD`；不调 API 的 Story 可不绑 operationId
5. 产出 STORY-FL-*.md，每条 API 相关 AC 附追溯（§7 格式）
6. 更新 docs/handoff/stories-index.md（Story ↔ operationId，可选）
```

## 5. 与后端 Story 的分工

- **后端 Story**：域规则、BFF/order 职责、「客户端另仓」行为线索
- **OpenAPI**：字段名、枚举、错误码、examples——**接口语义只认 YAML**
- **Flutter Story**：页面路由、交互、状态机、错误展示；**不得**重新定义 API 字段

## 6. Flutter Story 必含节

```markdown
## 契约
| 项 | 值 |
|----|-----|
| OpenAPI 文件 | docs/handoff/openapi/booking-bff-app.yaml |
| 契约版本 | tag `2026-S01-rc1` |
| baseUrl | /api/v1/booking/app |

## 本卡 API 范围
| AC | operationId | Method | Path | 说明 |
|----|-------------|--------|------|------|

## 设计稿
| 页面/组件 | 稿件位置 | 状态 |
|-----------|---------|------|
| 首页-框架 | docs/prototype/home-frame.png | 已定稿 |
| 首页-弹窗 | docs/prototype/home-dialog.png | 草稿，像素待定 |

- 有稿登记位置与状态；无稿写 `无 → UI: TBD`；纯 UI 卡本节是主要验收依据

## 不在本卡范围
- 列出其它 operationId，防止编码越界
```

稿件位置可填 Figma Frame/node 与版本、蓝湖页面或快照文件。按[设计规则](../../rules/ui-design.md)记录双端差异。网络 AC 引用 operationId；纯本地 AC 写交互及数据保留范围；原生 AC 写目标平台、SDK 能力和授权/取消的可见结果。

## 7. AC 追溯格式

```markdown
- **后端 Story**：STORY-2026-S01-002（摘要：§1 + §2.3 + 相关 AC/BR；完整文件见后端仓）
- **OpenAPI**：operationId `getActiveReservation`（GET `/api/v1/booking/app/reservations/active`）
- **契约版本**：booking-bff-app @ tag `2026-S01-rc1`
- **Given/When/Then**：…（视觉项引用 §设计稿 锚点；无稿才标 `UI: TBD`）
```

## 8. 不做

- 改 OpenAPI、写后端 Java
- 页面详设（组件树、状态机）→ `flutter-detail-design`
- 页面/组件代码 → `flutter-feature-coding`
- 重新定义 API 字段或错误码

## 9. 反模式

- 只丢整份 openapi.yaml、不在 Story 点名本卡 operationId
- 只写接口 path、不提供 OpenAPI 文件或版本
- 客户端 AC 重新定义后端字段名
- 视觉 AC 一律标 `UI: TBD`、不登记设计稿位置（验收标准实际为空）
