---
name: frontend-feature-coding
description: >-
  将 STORY-FE + 详设 + OpenAPI 落地为可运行微信小程序代码：按 TDD 编写页面/组件/services
  与测试，支持全新实现、增量补全、需求变更后同步。用于前端功能编码、Story 实现、
  按详设编码、按 AC 写测试与实现等场景。不改 OpenAPI、不直连后端域。
---

> **模板版说明**：本 Skill 自源项目（C 端微信小程序）抽取为通用模板。文中项目专属值（`docs/handoff/openapi/{后端服务标识}.yaml`、页面/组件名、Story 号）均为**示例**，接入时按根 [MIGRATION.md](../../../MIGRATION.md) 清单替换；「本仓库」指接入后的前端项目。


# 前端功能编码（Story + 详设 → 小程序 + 测试）

以 STORY-FE + 详设 + OpenAPI 为输入，在 Story 范围内**一体化 TDD**（先写/补测试，再写/修页面/组件），
产出 `pages/`/`components/`/`services/`/`api/` 代码与测试，Story 范围内测试全绿后交付。

## 1. 定位与边界

- **做什么**：Story 范围内页面/组件/services/api + 测试一体化 TDD
- **不做**：需求拆解（`frontend-story-splitting`）、详设从零编写（`frontend-detail-design`）
- **不做**：改 OpenAPI、改 Story 卡、直连后端域、改 Rule
- **不做**：改**非当前 Story** 的详设

## 2. 输入

- **必备**：STORY-FE 需求卡
- **必备**：详设 `DD-FE-*.md`
- **必备**：OpenAPI（`docs/handoff/openapi/{后端服务标识}.yaml` + `VERSION`）
- **可选**：实现范围（全 Story / 指定页 / 指定 AC）

### 触发示例

```text
/frontend-feature-coding 实现 STORY-FE-2026-S01-002
@docs/requirements/2026-S01/STORY-FE-2026-S01-002-*.md
@docs/design/2026-S01/DD-FE-2026-S01-002-*.md
```

## 3. 流程

### 步骤 1：加载上下文

- STORY-FE、DD-FE、OpenAPI、系统画像
- Rule：`rules/miniprogram-project.md`、`rules/miniprogram-performance.md`、`rules/api-client-conventions.md`、`rules/error-display-conventions.md`

### 步骤 2：契约对齐

- 确认本卡 `operationId` 范围（来自 Story §本卡 API 范围）
- 读 OpenAPI schema / examples，确认字段名、错误码
- **不**发明字段；与 `api/generated/` 或 `api/http.js` 对齐

### 步骤 3：TDD（先测试）

- `services/`、`utils/`、纯逻辑：jest 单测（优先）
- 页面/组件：开发者工具预览 + 关键交互手测；复杂状态可用组件测试
- 测试命名：`{file}.test.js`，与被测同目录或 `__tests__/`

### 步骤 4：实现

按详设分层：

```text
pages/{page}/        页面四同名文件（js/wxml/wxss/json）
  └─ 调 services/ 或 api/，不直接 wx.request
components/{comp}/   自定义组件
services/{domain}/   业务封装（调 api/generated 或 api/http.js）
api/http.js          统一请求层（code/401/baseUrl）
api/generated/       OpenAPI client（可选）
```

### 步骤 5：性能自检（`rules/miniprogram-performance.md`）

- setData 合并、低频、单次 < 256KB
- `onUnload` 解绑 `wx.on*`、清定时器、清全局引用
- 长列表分页/虚拟列表
- 倒计时不用 `setInterval` + 高频 setData

### 步骤 6：验证

- `npm test`（jest）全绿
- 微信开发者工具预览，关键 AC 手测
- Story 范围内 AC 逐条对照

## 4. 验收

- Story 范围 AC 全绿
- 未引入非本卡 `operationId`
- 未发明 API 字段
- `onUnload` 清理完整
- diff 小，未改非本 Story 文件

## 5. 需求变更

1. 后端 OpenAPI 变更 → 同步 `docs/handoff/` + `VERSION`
2. 读 Story 变更记录 → 改测试 → 改实现
3. 接口/字段变更 **必须先确认 OpenAPI 已更新**

## 6. 反模式

- 页面直接 `wx.request`
- 自行定义后端字段名
- `onUnload` 不解绑监听/不清定时器（内存泄漏）
- `setInterval` 倒计时 + 每秒 `setData`
- 引入非本卡 `operationId`
- 改 OpenAPI / Story 卡 / Rule
