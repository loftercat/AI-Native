---
name: frontend-story-splitting
description: >-
  将 Epic/PRD/原型 + 后端 OpenAPI handoff 拆为带 AC 的前端 Story 卡（STORY-FE-*）。
  用于前端需求拆解、迭代规划、写 docs/requirements 时。不改 OpenAPI、不写后端代码。
---

> **模板版说明**：本 Skill 自源项目（C 端微信小程序）抽取为通用模板。文中项目专属值（`docs/handoff/openapi/{后端服务标识}.yaml`、页面/组件名、Story 号）均为**示例**，接入时按根 [MIGRATION.md](../../../MIGRATION.md) 清单替换；「本仓库」指接入后的前端项目。


# 前端 Story 拆分（frontend-story-splitting）

## 1. 定位

**把 Epic/PRD/原型 + 后端 OpenAPI 拆成可独立验收的前端 Story（AC/BR + 本卡 operationId 范围），落盘到迭代目录——只做需求语义，不做详设、页面代码。**

## 2. 何时触发

- 新 Epic / 迭代规划 / 从 PRD 或后端 Story 拆前端卡
- 用户要求写 `docs/requirements/{迭代}/STORY-FE-*.md`

**不触发**：页面详设、组件代码、OpenAPI 设计。

## 3. 前置加载（按序）

| # | 资产 | 路径 | 缺失时 |
|---|------|------|--------|
| 1 | 迭代 | `config/current-sprint` | 询问用户 |
| 2 | 系统画像 | `architecture/system-landscape.md` | **阻断** |
| 3 | AGENTS.md | 做什么 / 不做什么 | 必须读 |
| 4 | 后端 OpenAPI | `docs/handoff/openapi/{后端服务标识}.yaml` | **阻断**（集成层必须） |
| 5 | 契约版本 | `docs/handoff/VERSION` | **阻断** |
| 6 | Epic/PRD/原型 | Epic 来源路径 | 必须有（至少其一） |
| 7 | 后端 Story 摘要 | §1 用户故事 + §2.3 前端职责 + 相关 AC/BR | 强烈推荐 |
| 8 | 词表 | `glossary/domain-glossary.md` | 降级 |
| 9 | Rule | `rules/miniprogram-project.md`、`rules/api-client-conventions.md` | 必须读 |

## 4. 拆卡步骤

```text
1. 读 Epic/PRD/原型 → 划定页面/用户价值 → 候选 STORY-FE
2. 在 openapi.yaml 检索本页 paths → 列出 operationId 清单
3. 读每个 operation 的 examples → 把分支写成可验收 AC（Given/When/Then）
4. 纯 UI（Tab、像素）标 UI: TBD；不调 API 的 Story 可不绑 operationId
5. 产出 STORY-FE-*.md，每条 API 相关 AC 附追溯（§4.1 格式）
6. 更新 docs/handoff/stories-index.md（Story ↔ operationId，可选）
```

## 5. 与后端 Story 的分工

- **后端 Story**：域规则、BFF/order 职责、「前端另仓」行为线索
- **OpenAPI**：字段名、枚举、错误码、examples——**接口语义只认 YAML**
- **前端 Story**：页面路由、交互、状态机、错误展示；**不得**重新定义 API 字段

## 6. 前端 Story 必含节

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

## 不在本卡范围
- 列出其它 operationId，防止编码越界
```

## 7. AC 追溯格式

```markdown
- **后端 Story**：STORY-2026-S01-002（摘要：§1 + §2.3 + 相关 AC/BR；完整文件见后端仓）
- **OpenAPI**：operationId `getActiveReservation`（GET `/api/v1/booking/app/reservations/active`）
- **契约版本**：booking-bff-app @ tag `2026-S01-rc1`
- **Given/When/Then**：…（UI 样式可 TBD）
```

## 8. 不做

- 改 OpenAPI、写后端 Java
- 页面详设（组件树、状态机）→ `frontend-detail-design`
- 页面/组件代码 → `frontend-feature-coding`
- 重新定义 API 字段或错误码

## 9. 反模式

- 只丢整份 openapi.yaml、不在 Story 点名本卡 operationId
- 只写接口 path、不提供 OpenAPI 文件或版本
- 前端 AC 重新定义后端字段名
