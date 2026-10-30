---
name: frontend-detail-design
description: >-
  将前端 Story（STORY-FE-*）+ OpenAPI 落地为页面详设：页面状态机、组件树、
  AC→operationId 映射、路由、错误展示。产出 DD-FE-*.md，供 feature-coding 直接消费。
  不改 OpenAPI、不写页面代码。
---

> **模板版说明**：本 Skill 自源项目（C 端微信小程序）抽取为通用模板。文中项目专属值（`docs/handoff/openapi/{后端服务标识}.yaml`、页面/组件名、Story 号）均为**示例**，接入时按根 [MIGRATION.md](../../../MIGRATION.md) 清单替换；「本仓库」指接入后的前端项目。


# 前端详设（frontend-detail-design）

## 1. 定位

**把 STORY-FE + OpenAPI 转成页面详设：路由、组件树、状态机、AC→operationId 映射、错误展示。不改 Story 卡、不写页面代码。**

## 2. 何时触发

- STORY-FE 已定稿，需出页面详设
- 用户要求写 `docs/design/{迭代}/DD-FE-*.md`

**不触发**：Story 拆解（`frontend-story-splitting`）、页面代码（`frontend-feature-coding`）。

## 3. 前置加载

| # | 资产 | 路径 |
|---|------|------|
| 1 | STORY-FE | `docs/requirements/{迭代}/STORY-FE-*.md` |
| 2 | OpenAPI | `docs/handoff/openapi/{后端服务标识}.yaml` + `VERSION` |
| 3 | 系统画像 | `architecture/system-landscape.md` |
| 4 | 原型 | `docs/prototype/`（后端仓）或 handoff |
| 5 | Rule | `rules/miniprogram-project.md`、`rules/api-client-conventions.md`、`rules/error-display-conventions.md`、`rules/miniprogram-performance.md` |

## 4. 详设必含

### 4.1 路由与页面

- 页面路径（`pages/xxx`）
- 是否分包、分包路径
- tabBar 归属
- 页面间跳转关系

### 4.2 组件树与 props

- 页面用到的自定义组件（`components/`）
- 组件 props / 触发事件
- 跨页复用标注

### 4.3 页面状态机

- 加载 / 空 / 错 / 成功
- 各状态触发条件与展示
- 与 `setData` 的关系（合并、低频）

### 4.4 AC → operationId 映射表

| AC | operationId | Method | Path | 成功展示 | 失败展示 |
|----|-------------|--------|------|----------|----------|

- 每条 API 相关 AC 必须映射到具体 `operationId`
- 成功/失败分支引用 OpenAPI `examples`

### 4.5 错误展示

- `code !== 200` 的 Toast / Modal / 跳转
- 401 统一由 `http.js` 处理（页面不感知）
- 域业务码按 Story AC 展示 `message`

### 4.6 性能关注

- 倒计时/动画实现方式（避免高频 setData）
- 长列表（虚拟列表 / 分页）
- 分包加载点

### 4.7 原型追溯

- `docs/prototype/` 文件名（有则写，无则 `TBD`）

## 5. 不做

- 改 Story 卡正文
- 写页面/组件代码（`frontend-feature-coding`）
- 重新定义 API 字段/错误码
- 改 OpenAPI

## 6. 输出路径

`docs/design/{迭代}/DD-FE-{迭代}-{序号}-{slug}.md`

## 7. 反模式

- 详设里重新定义 API 字段（应认 OpenAPI）
- 无 AC→operationId 映射表
- 未考虑 setData 性能
- 把后端域逻辑写进前端详设
