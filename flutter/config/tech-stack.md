# Flutter 新项目默认技术栈

此处维护新项目的架构、SDK 基线和可复用的技术选型。按[接入指南](../MIGRATION.md#2-填写-flutter-画像)生成画像时，将下表写入项目画像 §3.1。项目统一使用 MVVM 和鸿蒙兼容的 Flutter SDK，共享状态与依赖注入固定采用 Riverpod。其余条目以项目明确指定的方案为先，缺省时使用表中方案。画像记录各项实施状态，开发时按功能需要引入依赖。

引入表中第三方包时，默认在 `pubspec.yaml` 声明对应的精确版本，并提交由项目锁定的 Flutter / Dart SDK 解析生成的 `pubspec.lock`。调整依赖版本时，在同一 SDK 基线下重新执行 `flutter pub get` 和相关测试。

| 领域 | 约定方案 | 实现要求 |
|---|---|---|
| Flutter / Dart SDK | [CPF-Flutter 鸿蒙适配版](https://gitcode.com/CPF-Flutter/flutter_flutter)，Flutter `3.41.10-ohos-1.0.1`，Dart `3.11.5` | Flutter tag 为 `3.41.10-ohos-1.0.1`，框架修订为 `adaf911c35c9136a7d18fc424d714c9ec7724e60`。创建脚手架、本地开发和 CI 使用项目锁定的同一 SDK，Dart 随 SDK。升级时选择经过验证的鸿蒙适配版本，同步更新项目画像与工具链配置。 |
| 项目架构（固定） | 按业务模块组织的 MVVM（Model–View–ViewModel） | 职责划分和业务 ViewModel 命名见[Flutter 工程规则](../rules/flutter-project.md)。 |
| 业务模块与分包 | 默认在同一 App 的 `lib/features/{feature}/` 下按业务建目录，例如登录用 `login`，支付用 `pay` | 每个模块就近维护自己的页面、ViewModel 和数据层。跨应用复用时可提取独立 Dart/Flutter package。目录示例和跨模块调用见[工程规则 §4](../rules/flutter-project.md#4-目录归属)，项目实际模块登记在[画像 §3.2](../architecture/system-landscape.md#32-目录结构)。 |
| 网络请求 | Dio（`dio: 5.11.1`） | 按信任域配置客户端，统一超时、鉴权、取消、错误转换。 |
| 应用日志 | [Talker](https://pub.dev/packages/talker_flutter)（`talker_flutter: 5.2.0`），测试包网络日志使用 `talker_dio_logger: 5.2.0` | 在应用入口创建共享实例，供请求层、推送和 SDK 适配层记录事件。按[分环境日志规则](../rules/testing-release.md#分环境日志)输出日志：测试包全量打印原文并提供 TalkerScreen，正式包只记录关键事件。阿里云远程日志 SDK 为后续接入项。 |
| 状态共享（固定） | Riverpod（`flutter_riverpod: 3.3.2`） | Widget 用 `ref.watch` 订阅共享状态。页面和会话状态按生命周期提供，切换账号时隔离状态。 |
| 页面局部状态 | setState、ValueNotifier | 展开、显隐和输入交互由 Widget 就近管理。创建 ValueNotifier 的对象负责释放它。 |
| UI 主题 | Flutter SDK 的 `ThemeData`、`ColorScheme`、`TextTheme` | 在应用入口统一加载主题。品牌色、字体和明暗主题范围按项目设计稿确定，参照 [UI 设计规则](../rules/ui-design.md)。 |
| 基础 UI 组件 | 优先复用项目公共组件，以 Flutter SDK 控件为基础 | 按实际场景沉淀按钮、表单输入、加载态、空态、错误重试和确认弹窗。通用组件接收状态与回调，业务页面状态和操作由 ViewModel 管理。已实现的组件登记到[项目画像 §3.2](../architecture/system-landscape.md#32-目录结构)。 |
| 分页列表（下拉刷新 + 上拉加载更多） | 复用项目的分页列表组件，或用 Flutter SDK 组合实现 | 页面通过同一个列表组件绑定刷新和加载下一页，触发条件、底部状态及请求处理见[列表刷新与分页](../rules/flutter-project.md#81-列表刷新与分页)。 |
| 路由 | `go_router: 17.5.0` | 集中声明路由、登录重定向、深链解析与恢复目标。所有普通页面复用路由层的水平转场。入栈时，当前页向左滑出，新页同时从右侧滑入；出栈时，当前页向右滑出，上一页同时从左侧滑入。入栈与出栈各用 250 ms。Tab 切换、弹窗和底部面板沿用各自的交互约定。 |
| 轻量配置 | `shared_preferences: 2.5.6` | 使用 `SharedPreferencesAsync` 保存主题、语言和引导页标记。 |
| 敏感信息 | `flutter_secure_storage: 11.2.0` | 保存需要持久化的少量凭据，随会话失效清理。 |
| 结构化存储 | Drift / SQLite（`drift: 2.35.4`） | 离线记录、查询与事务使用数据库，升级时验证旧库迁移。Drift 的传递依赖 `sqlite3` 在这套基线下解析为 `3.5.2`，由项目的 `pubspec.lock` 记录。 |
| 应用内事件 | 类型化 Stream，按需封装事件分发 | 声明事件类型、作用域和所有者，取消订阅；需要重放的业务事实另行保存。 |
| 数据模型 | 不可变对象 + JSON 序列化 | 明确线上字段与 Dart 属性映射，按契约解析。领域模型与传输 DTO 在数据边界转换。 |
| 依赖注入（固定） | Riverpod Provider + 构造函数注入 | Provider 组装 Service 和 Repository，数据层依赖通过构造函数传入。普通 Dart ViewModel 由 Provider 构造并注入 Repository。采用 `Notifier` 或 `AsyncNotifier` 的 ViewModel 通过 `ref` 获取 Repository provider，测试时可覆盖该 provider 以注入替身。 |
| 测试 | 单元测试、Widget 测试、集成测试 | 按 AC 和风险选择层级，原生能力按目标设备补验。 |
| 质量检查 | Dart formatter、Flutter analyzer、CI | 应用 PR 自动执行格式、静态分析和测试。命令见[测试规则](../rules/testing-release.md)。 |

## 鸿蒙适配待办

- [ ] Android 和 iOS 均上线后，再评估是否启动鸿蒙版本适配。确认范围后另立 Story，核对所用插件的鸿蒙实现、版本和来源，并登记真机验收结果。
