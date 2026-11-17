---
name: flutter-detail-design
description: >-
  将客户端 Story（STORY-FL-*）+ OpenAPI 落地为页面详设：页面状态机、组件树、
  AC→operationId 映射、路由、错误展示。产出 DD-FL-*.md，供 feature-coding 直接消费。
  不改 OpenAPI、不写页面代码。
---

> **模板版说明**　示例业务与客户端工作流共用。接入 Flutter 项目时按[使用手册](../../USAGE.md)填写[系统画像](../../architecture/system-landscape.md)，以本工程的组件、路由和契约替换示例值。


# Flutter 详设（flutter-detail-design）

## 1. 定位

**把 STORY-FL + 适用的契约 转成页面详设：路由、组件树、状态机、AC→operationId 映射、错误展示。不改 Story 卡、不写页面代码。**

## 2. 何时触发

- STORY-FL 已定稿，需出页面详设
- 用户要求写 `docs/design/{迭代}/DD-FL-*.md`

**不触发**：Story 拆解（`flutter-story-splitting`）、页面代码（`flutter-feature-coding`）。

## 3. 前置加载

| # | 资产 | 路径 |
|---|------|------|
| 1 | STORY-FL | `docs/requirements/{迭代}/STORY-FL-*.md` |
| 2 | OpenAPI（网络 AC） | `docs/handoff/openapi/{后端服务标识}.yaml` + `VERSION` |
| 3 | 系统画像 | `architecture/system-landscape.md` |
| 4 | 设计稿 | 按 STORY-FL「设计稿」节登记的位置（`docs/prototype/`）或 handoff |
| 5 | Rule | `rules/flutter-project.md`、`rules/api-client-conventions.md`、`rules/error-display-conventions.md`、`rules/flutter-performance.md` |

## 4. 详设必含

### 4.1 路由与页面

- 页面路由、入参、模块及底部 Tab 归属。
- 页面跳转、登录恢复、深链与返回栈。按本卡目标验证 Android 系统返回或 iOS 返回手势。

### 4.2 Widget 树与组件参数

- 先查画像 §3.1 的技术选型与 §3.2 的组件目录，区分复用与新增。说明新增组件、回调和工具在本卡承担的业务职责。
- 列出 Widget、输入、回调、主题与跨页复用位置。需要平台视图时注明 Android/iOS 的适配边界。

### 4.3 页面状态机

- 给出加载 / 空 / 错 / 成功状态及触发条件，说明刷新、重复提交、切后台的转换。
- 按[状态、存储与事件规则](../../rules/state-storage-events.md)指定所有者、读写范围、缓存失效和订阅释放点。

### 4.4 AC → operationId 映射表

| AC | operationId | Method | Path | 成功展示 | 失败展示 |
|----|-------------|--------|------|----------|----------|

- 每条 API 相关 AC 必须映射到具体 `operationId`
- 成功/失败分支引用 OpenAPI `examples`。对本卡新增或变更的请求、响应模型，引用 schema 和版本，说明影响实现的单位、枚举或空值语义。契约有歧义时记录待确认项。

本地 AC 填 N/A 并写数据或交互来源。原生 AC 依据[桥接规则](../../rules/platform-bridge.md)列出 SDK 方法、事件、取消及两端结果。

### 4.5 错误展示

- 按契约区分 HTTP、业务失败与平台错误。会话层处理鉴权失效，页面结束加载，按 AC 展示字段提示、SnackBar、Dialog 或重试入口。

### 4.6 性能关注

- 列表分页与按需构建，倒计时按截止时间计算。标出局部重建、资源释放和应用恢复后的刷新策略。

### 4.7 设计稿追溯

- 沿用 STORY-FL「设计稿」节的登记（稿件位置 + 状态），逐条核对一致；位置、状态或版本不一致时，暂停该项设计并请用户确认采用哪份稿件，保留原 Story 登记
- 条目为 `无 → UI: TBD` 的按无稿处理；STORY-FL 未登记的：有稿列 `docs/prototype/` 文件名并注明「详设补登」；无稿标 `UI: TBD`

- [设计规则](../../rules/ui-design.md)用于将 Frame、主题、素材及状态映射到 Widget，列出设备、基准尺寸与截图验收点。

## 5. 不做

- 改 Story 卡正文
- 写页面/组件代码（`flutter-feature-coding`）
- 重新定义 API 字段/错误码
- 改 OpenAPI

## 6. 输出路径

`docs/design/{迭代}/DD-FL-{迭代}-{序号}-{slug}.md`

## 7. 反模式

- 详设里重新定义 API 字段（应认 OpenAPI）
- 无 AC→operationId 映射表
- 未考虑 Widget 重建和资源释放
- 把后端域逻辑写进 Flutter 详设
