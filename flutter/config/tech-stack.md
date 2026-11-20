# Flutter 新项目默认技术栈

此处维护新项目统一采用的架构和可复用的技术选型。按[接入指南](../MIGRATION.md#2-填写-flutter-画像)生成画像时，将下表写入项目画像 §3.1。MVVM 是固定架构，其余条目以项目明确指定的方案为先，缺省时使用表中方案。画像记录各项实施状态，开发时按功能需要引入依赖。

| 领域 | 约定方案 | 实现要求 |
|---|---|---|
| 项目架构（固定） | 按业务模块组织的 MVVM（Model–View–ViewModel） | 职责划分和业务 ViewModel 命名见[Flutter 工程规则](../rules/flutter-project.md)。 |
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
| 依赖注入 | Riverpod Provider + 构造函数注入 | Provider 组装 Service、Repository 和 ViewModel。类通过构造函数声明依赖，测试可传入替身。 |
| 测试 | 单元测试、Widget 测试、集成测试 | 按 AC 和风险选择层级，原生能力按目标设备补验。 |
| 质量检查 | Dart formatter、Flutter analyzer、CI | 应用 PR 自动执行格式、静态分析和测试。命令见[测试规则](../rules/testing-release.md)。 |
