---
name: flutter-feature-coding
description: >-
  将 STORY-Flutter + 详设 + 适用契约实现 Android/iOS Flutter 代码：按 TDD 编写页面、Widget 和 Repository
  与测试，支持全新实现、增量补全、需求变更后同步。用于 Flutter 功能编码、Story 实现、
  按详设编码、按 AC 写测试与实现等场景。不改 OpenAPI、不直连后端域。
---

> **模板版说明**　示例业务与客户端工作流共用。接入 Flutter 项目时按[接入指南](../../MIGRATION.md)填写[系统画像](../../architecture/system-landscape.md)，以本工程的组件、路由和契约替换示例值。

接入项目后，先读项目根 AGENTS.md 和[本线入口](../../AGENTS.md)，按入口约定定位工作流文档和应用代码。

# Flutter 功能编码（Story + 详设 → Flutter 应用 + 测试）

以 STORY-Flutter + 详设及本卡适用的契约为输入，在 Story 范围内**一体化 TDD**（先写/补测试，再写/修页面/组件），
产出 `lib/` 及需要的 Android/iOS 桥接代码与测试，Story 范围内测试全绿后交付。

## 1. 定位与边界

- **做什么**：Story 范围内页面、Widget 和 Repository + 测试一体化 TDD
- **不做**：需求拆解（`flutter-story-splitting`）、详设从零编写（`flutter-detail-design`）
- **不做**：改 OpenAPI、改 Story 卡、直连后端域、改 Rule
- **不做**：改**非当前 Story** 的详设

## 2. 输入

- **必备**：STORY-Flutter 需求卡
- **必备**：详设 `DD-Flutter-*.md`
- **网络 AC 必备**：OpenAPI（`docs/handoff/openapi/{后端服务标识}.yaml` + `VERSION`）
- **可选**：实现范围（全 Story / 指定页 / 指定 AC）

### 触发示例

```text
/flutter-feature-coding 实现 STORY-Flutter-2026-S01-002
@AI-Native/flutter/docs/requirements/2026-S01/STORY-Flutter-2026-S01-002-*.md
@AI-Native/flutter/docs/design/2026-S01/DD-Flutter-2026-S01-002-*.md
```

## 3. 流程

### 步骤 1：加载上下文

- 读 STORY-Flutter、DD-Flutter、适用的契约和本卡范围。先核对 DD 中本次 AC 的状态、失败分支与平台验收依据，待确认项只阻断受影响的范围。按系统画像 §3.1 选用对应组件，通过 §3.2 定位已有公共组件或工具。
- 按 STORY-Flutter「设计稿」节加载稿件对照；标 `UI: TBD` 的项不猜样式，向用户要稿或确认
- Rule：`rules/flutter-project.md`、`rules/flutter-performance.md`、`rules/api-client-conventions.md`、`rules/error-display-conventions.md`

### 步骤 2：契约对齐

- 确认本卡 `operationId` 范围（来自 Story §本卡 API 范围）
- 对网络 AC 核对 Story、DD、快照与 `docs/handoff/VERSION` 一致；版本缺失、为空、`TBD` 或所需 operationId 缺失时阻断相关实现，回上游补齐。纯本地/仅原生且无后端调用的卡沿用 `N/A`。
- 对网络 AC 读 OpenAPI schema / examples，确认字段名、错误码
- 核对 DTO 和项目的 HTTP 客户端。纯本地 AC 核对数据与交互约定；涉及原生能力时核对两个目标平台的[桥接契约](../../rules/platform-bridge.md)。

### 步骤 3：TDD（先测试）

- 先写可复现当前 AC 的失败测试。Repository/Controller 用 fake 或可控时钟覆盖失败、取消和乱序。
- Widget 测试覆盖可见状态、点击与导航。测试存入 `test/`，以 `_test.dart` 结尾。真实 SDK 回调在步骤 6 通过设备验证。

### 步骤 4：实现

按 DD 和[工程规则](../../rules/flutter-project.md)落文件。以下是典型目录，具体以画像为准。

```text
lib/features/{feature}/presentation/   页面、Widget、Controller
lib/features/{feature}/data/           Repository、服务与模型
lib/core/network/                      HTTP、鉴权、错误转换
android/、ios/                         本卡涉及的原生适配
test/、integration_test/               单元、Widget、集成用例
```

View 绑定状态，Repository 协调数据源；按[状态与事件规则](../../rules/state-storage-events.md)实现共享、存储与订阅。视觉实现引用 Story 登记的稿件与 DD 中的组件映射。

实现 UI 组件、工具、接口和模型时，结合业务场景及后端文档为难以从命名判断的行为和字段补充中文说明。示例见[工程规范](../../rules/flutter-project.md)。

### 步骤 5：性能自检（`rules/flutter-performance.md`）

- 检查重建范围、长列表与图片解码尺寸。退出页面时释放 Controller、Timer、订阅与原生视图，丢弃过期的异步结果。
- 验证倒计时在后台恢复后仍按截止时间计算，原生监听重连后只保留一个订阅。

### 步骤 6：验证

- 按[测试规则](../../rules/testing-release.md)及画像运行格式检查、`flutter analyze`、`flutter test` 和相关集成测试。
- 逐条对照 Story AC。视觉项按[设计规则](../../rules/ui-design.md)对比设计与运行截图，原生能力按本卡目标平台记录设备、系统和结果。缺少的设备证据标为待验。

### 步骤 7：独立代码审查（联调/提测前）

- **触发**：步骤 6 验证通过后、联调/提测前；审查通过前禁止 commit/push。
- **规则**：[code-review.md](../../rules/code-review.md)（客户端线专用）；报告模板 [code-review-report.md](../../templates/code-review-report.md)。
- **动作**：按规则 §三 给全输入（档位、STORY-Flutter/AC、diff + 本次相关新增文件、DD-Flutter/OpenAPI/VERSION、Flutter 测试与设备验证结果、关注点）；独立审查人（新会话 / 审查 agent / 人）只读审查；实现者（主流程）落盘。
- **闭环**：L1=P0/P1；L2=P0/P1 + 正确性/安全 P2；L3=P0–P2；不默认复审，连续 2 轮交还人工。
- **审查重点**：operationId 范围、字段只认 OpenAPI、页面不直接发请求、请求层/错误码、页面状态机、错误展示、Widget 重建、资源释放、SDK 回调、设计稿还原（对照 STORY-Flutter「设计稿」节；纯 UI 卡为重点项）。
- **报告**：`docs/reviews/{迭代}/REVIEW-CODE-Flutter-{Story编号}-{slug}.md`；结论「通过」才可联调/提测。
- **L0 例外**：文档/路径/重命名/机械移动不送审，回复说明自动门禁结果。

## 4. 验收

- Story 范围 AC 全绿
- 未引入非本卡 `operationId`
- 未发明 API 字段
- 页面和会话持有的资源已释放
- diff 小，未改非本 Story 文件
- 代码审查报告存在且结论通过（`REVIEW-CODE-Flutter-*`；L0 除外，需说明跳过原因）

## 5. 需求变更

1. 后端 OpenAPI 变更 → 同步 `docs/handoff/` + `VERSION`
2. 先由拆卡/详设阶段同步受影响的 Story 和 DD，再读变更记录 → 改测试 → 改实现
3. 接口/字段变更 **必须先确认 OpenAPI 已更新**

## 6. 反模式

- Widget 直接调用 HTTP 客户端
- 自行定义后端字段名
- 页面退出后仍持有原生监听或 Timer
- 每次计时回调重建整页，恢复前台后继续使用旧时间
- 引入非本卡 `operationId`
- 改 OpenAPI / Story 卡 / Rule
