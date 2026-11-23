# Flutter Android / iOS 项目画像

接入后，第 3.1 节记录本项目确定的技术基线。依据工程和项目决策补充版本、路径和构建配置。项目事实在本文件维护，Story / DD 引用具体版本与范围。

## 一、产品全景

填写产品、用户、从入口到完成的旅程、客户端负责的校验与服务端负责的授权和业务判断。首期交付 Android 和 iOS，鸿蒙安排见[适配待办](../config/tech-stack.md#鸿蒙适配待办)。

## 二、系统边界

填写后端 handoff 发布位置、集成环境、设计系统/Figma 文件与快照归档方式。记录 Flutter 主题和公共组件的实际目录。记录地图、支付、IM 所用 SDK、版本、负责人、Android/iOS 支持与测试账号取得方式。敏感值存于凭据系统。

## 三、技术栈与目录结构

### 3.1 技术栈

接入时按[画像接入规则](../MIGRATION.md#2-填写-flutter-画像)填写本项目的技术选型、实现约定和落地状态。项目统一采用 MVVM、Riverpod 和[技术栈配置](../config/tech-stack.md)中的鸿蒙兼容 SDK 基线。其余选型沿用配置中的默认值，并合入项目明确指定的选型。

接入时记录 Flutter/Dart 版本、Android 的 JDK/Gradle/Kotlin 与 minSdk/targetSdk、iOS 的 Xcode/Swift 与 deployment target，以及设备矩阵、推送供应商、性能预算、构建命令和发布负责人。

### 3.2 目录结构

登记应用根相对项目根的路径（单应用通常为 `.`，多包仓示例为 `apps/mobile/`），以该应用的 `pubspec.yaml` 核实。迭代工件（Story、DD、审查报告）、下列业务路径及 Flutter 命令以应用根为基准。填写当前工程入口、业务模块、路由、公共组件和数据源目录，以及 Android/iOS 插件和集成测试的落点。

按[工程规则 §4](../rules/flutter-project.md#4-目录归属)记录本项目的业务模块。每项填「模块名、业务职责、目录或独立包路径、供其他模块使用的入口」，计划中的模块标为待实现。在多包仓中，应用根外的包路径注明相对基准。

接入时登记已实现的公共组件和业务工具，供 DD 按名称定位。每项填写「用途、类名、工程路径、支持的状态或输入边界」。优先登记按钮、表单输入、加载/空/错误态、支持下拉刷新与上拉加载更多的分页列表组件，以及已有的日期、金额等业务工具。尚无实现的项注明待实现，避免把示例类名当成现成组件。

### 3.3 构建变体与包体预算

填写 Android flavor、iOS scheme、资源与原生 SDK 的包体预算，并指明对应环境。

## 四、集成与契约

接入时按 [MIGRATION.md](../MIGRATION.md) 处理：涉及后端但未交接时标「handoff 待补」，VERSION 为 `TBD`；纯本地项目本节标 `N/A` 并说明边界，不把示例当真实协议。

### 4.1 API 契约（唯一真相）

| 项 | 值 |
|----|-----|
| 契约文件 | `docs/handoff/openapi/{后端服务标识}.yaml`（从后端同步，**客户端不修改**） |
| 契约版本 | `docs/handoff/VERSION`（tag 或 commit SHA） |
| baseUrl | （示例）`/api/v1/{项目}/app`（与 OpenAPI `servers` 一致） |
| 成功判据 | 按契约填写；预约样例为 HTTP 成功且业务 code == 200 |
| 鉴权 | （示例）`Authorization: Bearer <token>` |

**当前后端已发布 operation**（随 handoff 更新；拆卡时只选本页相关项）：

| operationId | Method | Path（相对 baseUrl） | 后端 Story |
|-------------|--------|---------------------|------------|
| （示例）`searchLots` | GET | `/lots` | S-001 |

### 4.2 鉴权流程

填写实际登录方式、允许主机、安全存储、并发刷新、认证失效信号和退出时的账号清理。

### 4.3 错误码分层（与后端对齐）

| 层级 | 来源 | 客户端处理 |
|------|------|----------|
| （示例）系统层 | 后端公共库 `ErrorCode`（401 等） | 重新登录 / 通用提示 |
| （示例）BFF 守卫层 | 400 段 | 字段提示或 SnackBar |
| （示例）域业务层 | 按号段路由（见后端画像 §3.7） | 按 Story AC 展示 `message` |

错误展示和会话恢复遵循[错误展示规则](../rules/error-display-conventions.md)。

---

## 五、AI Native 工程资产

| 层级 | 路径 | 职责 |
|------|------|------|
| 执行层 | `skills/flutter-*/SKILL.md` | Agent 运行时步骤 |
| 横切层 | `rules/*.md` | 编码与文档规范 |
| 样例层 | 线根 `docs/**/_golden/` | Few-shot 标准样例 |
| 配置 | `config/current-sprint` | 当前迭代 |
| 模板默认配置 | [config/tech-stack.md](../config/tech-stack.md) | 新项目画像的默认技术选型 |
| 词表 | `glossary/domain-glossary.md` | 术语一致 |

## 六、与后端流水线的协作

```text
后端：story-splitting → detail-design → OpenAPI 定稿 → tag
              ↓
        发布 handoff 包（OpenAPI + VERSION + Story 摘要/stories-index）
              ↓
客户端：同步 docs/handoff/ → flutter-story-splitting → flutter-detail-design → flutter-feature-coding
              ↓
        联调（同一 OpenAPI tag 与后端环境一致）
```

**原则**：涉及后端调用的卡先定稿 OpenAPI，再跑相关详设；接口/字段/错误码变更**必须先改后端 OpenAPI**，再同步本仓——客户端仓永远不直接改契约。

---

## 变更记录

| 日期 | 变更 |
|------|------|
| （示例）2026-08-01 | 初版画像 |
