# Flutter Android / iOS 项目画像

第 3.1 节是本工作流的技术基线。接入负责人用实际仓库补充版本、路径和构建配置。项目事实在本文件维护，Story / DD 引用具体版本与范围。

## 一、产品全景

填写产品、用户、从入口到完成的旅程、客户端负责的校验与服务端负责的授权和业务判断。本线当前交付 Android、iOS；鸿蒙列为后续规划，按独立 Story 确定基线。

## 二、系统边界

填写后端 handoff 发布位置、集成环境、设计系统/Figma 文件与快照归档方式。记录 Flutter 主题和公共组件的实际目录。记录地图、支付、IM 所用 SDK、版本、负责人、Android/iOS 支持与测试账号取得方式。敏感值存于凭据系统。

## 三、技术栈与目录结构

### 3.1 技术栈

按本卡涉及的能力选用下表方案。已有工程采用不同方案时，在本节记录实际选型、适用模块及原因，供详设与审查共同引用。依赖版本以业务工程的 SDK 约束、pubspec.yaml 和 pubspec.lock 为准。

| 领域 | 约定方案 | 实现要求 |
|---|---|---|
| 项目架构 | 按业务模块组织的 MVVM（Model–View–ViewModel） | View（Widget）渲染状态和转发交互，ViewModel 管理页面状态与操作，Model 层由领域模型、Repository 和 Service 组成。已有 Controller 承担相同职责时可沿用其名称。见[分层约定](../rules/flutter-project.md)。 |
| 网络请求 | Dio | 按信任域配置客户端，统一超时、鉴权、取消、错误转换。 |
| 状态共享 | Riverpod（flutter_riverpod） | 页面和会话状态按生命周期提供，切换账号时隔离状态。 |
| 页面局部状态 | setState、ValueNotifier | 展开、显隐和输入交互由 Widget 就近管理。创建 ValueNotifier 的对象负责释放它。 |
| 分页列表（下拉刷新 + 上拉加载更多） | 复用项目的分页列表组件，或用 Flutter SDK 组合实现 | 页面通过同一个列表组件绑定刷新和加载下一页，触发条件、底部状态及请求处理见[列表刷新与分页](../rules/flutter-project.md#81-列表刷新与分页)。 |
| 路由 | go_router | 集中声明路由、登录重定向、深链解析与恢复目标。 |
| 轻量配置 | shared_preferences | 保存主题、语言和引导页标记。 |
| 敏感信息 | flutter_secure_storage | 保存需要持久化的少量凭据，随会话失效清理。 |
| 结构化存储 | Drift / SQLite | 离线记录、查询与事务使用数据库，升级时验证旧库迁移。 |
| 应用内事件 | 类型化 Stream，按需封装事件分发 | 声明事件类型、作用域和所有者，取消订阅；需要重放的业务事实另行保存。 |
| 数据模型 | 不可变对象 + JSON 序列化 | 明确线上字段与 Dart 属性映射，按契约解析。领域模型与传输 DTO 在数据边界转换。 |
| 依赖注入 | Riverpod Provider + 构造函数注入 | Provider 组装 Service、Repository 和 Controller；类通过构造函数声明依赖，测试可传入替身。 |
| 测试 | 单元测试、Widget 测试、集成测试 | 按 AC 和风险选择层级，原生能力按目标设备补验。 |
| 质量检查 | Dart formatter、Flutter analyzer、CI | 应用 PR 自动执行格式、静态分析和测试。命令见[测试规则](../rules/testing-release.md)。 |

接入时记录 Flutter/Dart 版本、Android 的 JDK/Gradle/Kotlin 与 minSdk/targetSdk、iOS 的 Xcode/Swift 与 deployment target，以及设备矩阵、推送供应商、性能预算、构建命令和发布负责人。

### 3.2 目录结构

登记应用根相对项目根的路径（单应用通常为 `.`，多包仓示例为 `apps/mobile/`），以该应用的 `pubspec.yaml` 核实。下列业务路径及 Flutter 命令以应用根为基准。填写当前工程入口、业务模块、路由、公共组件和数据源目录，以及 Android/iOS 插件和集成测试的落点。

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
| 样例层 | `docs/**/_golden/` | Few-shot 标准样例 |
| 配置 | `config/current-sprint` | 当前迭代 |
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
