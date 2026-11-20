# 工程结构、依赖与导航

## 1. 工程入口

在 pubspec 声明依赖与资源，从应用入口装配环境、路由与依赖。Android 和 iOS 保留各自宿主及构建配置。

## 2. 页面与组件

以[系统画像](../architecture/system-landscape.md)记录的目录、SDK、路由和状态方案为准。新业务按 feature 收拢。共享代码有第二个明确使用者或独立的平台边界时再抽取。

## 3. MVVM 分层约定

按业务模块组织 View 和 ViewModel，Repository 和 Service 属于 Model 层。已有页面 Controller 承担相同职责时，可沿用其名称。

| 边界 | 工作内容 |
|---|---|
| View / Widget | 渲染不可变状态，将点击、输入交给 ViewModel。build 可以重复调用，把 I/O、导航、弹窗移出 build。 |
| ViewModel（既有工程可命名为 Controller） | 协调用户操作、恢复和状态转换。构造函数或项目容器注入 Repository，保持可替换。 |
| Repository | 合并服务端、本地和缓存，暴露领域模型。数据源负责 HTTP、SQL 或平台通信。DTO 在边界解析。 |
| Service | 封装 HTTP、数据库或原生接口等单一数据源，供 Repository 调用。 |
| 原生适配 | 通过类型化 Dart 接口调用 Android/iOS，测试可替换实现。业务 UI 不处理通道字符串。 |

## 4. 目录归属

按模块组织 lib/features，共用网络、存储和平台适配归入工程约定的公共层。单元/Widget 测试放 test，跨页面和平台场景放 integration_test。

## 5. 命名规范

Dart 文件用 lower_snake_case，类型用 UpperCamelCase。页面、Widget 和 Controller 名称与项目词表一致。

### 工作流文档命名

所有生成的工作流文档统一使用完整名称 `Flutter`。文件名、标题、编号、正文、表格和交叉引用中的端标识均采用这一写法。

| 对象 | 命名约定 |
|------|----------|
| 需求卡 | `STORY-Flutter-{迭代}-{序号}-{slug}.md` |
| 详细设计 | `DD-Flutter-{迭代}-{序号}-{slug}.md` |
| 代码审查报告 | `REVIEW-CODE-Flutter-{Story编号}-{slug}.md` |
| 业务规则编号 | `BR-Flutter-{序号}` |
| 卡片简略引用 | `Flutter-{序号}`，如 `Flutter-003` |

生成项目入口、系统画像、handoff 说明及其他文档时同样使用完整名称。文档路径和引用须与实际文件名一致。

### 中文业务注释写法

开发时结合 Story、详设和后端接口文档编写中文说明。优先解释读代码难以判断的业务含义，例如组件回调何时触发、工具函数按哪个时区换算、两个相似的费用字段分别用于哪里。Dart 声明旁可使用 `///`。

接口、请求和响应字段以当前 handoff 版本的 OpenAPI 描述、枚举和约束为依据，业务用词参考领域词表。单位、空值或状态含义未定义时只描述已知事实。生成模型的说明宜放在可维护的源模型或适配层，方便随契约更新。

以下为预约样例中的响应模型片段，字段含义与后端契约一起维护。

```dart
/// 车场详情页展示的收费说明。
class LotFeeInfo {
  const LotFeeInfo({required this.parkingFeeDescription});

  /// 车场停车费用的说明文案，供用户在选择预约时段前查看。
  final String parkingFeeDescription;
}
```

## 6. 路由与宿主配置

路由注册在应用入口，参数校验 ID 与类型，资源由 Repository 加载。处理未登录、资源失效、外部深链、重复跳转。记录登录后的返回目标。底部 Tab 定义各自返回栈，检查 Android 系统返回键和 iOS 返回手势。服务端执行资源授权。

## 7. Dart 与依赖管理

公共 API 明确可空性，区分缺失值、空集合和业务默认值。依赖在 pubspec 声明，应用提交 pubspec.lock。生成文件按项目约定再生成。原生插件变更同时核对两端最低系统版本、权限、许可证及锁文件。

**数据模型与契约兼容。** 请求/响应 DTO 使用不可变字段，集合避免向外暴露可变引用。按接口实际方向实现 JSON 编码或解码，显式映射字段名与类型。用契约样本验证缺失、null、未知枚举、时间和金额精度；对会改变业务结果的异常值给出可识别的解析错误。变更字段时一并检查调用方和样本测试。

## 8. UI 组件与主题

优先使用项目的公共组件与 ThemeData。按 Story 登记的设计稿映射 Widget 和交互状态，遵循[设计规则](ui-design.md)。

### 8.1 列表刷新与分页

在一个分页列表组件中封装下拉刷新和上拉加载更多。优先复用画像 §3.2 登记的组件。页面将两个回调绑定到 ViewModel，组件接收列表及加载状态并渲染。

- **下拉刷新**。默认使用 `RefreshIndicator`，Cupertino sliver 布局可用 `CupertinoSliverRefreshControl`。刷新回调返回刷新任务的 Future。纵向短列表或空列表需要支持下拉时，保留可滚动容器并使用 `AlwaysScrollableScrollPhysics`。首屏刷新成功后替换列表和分页位置，失败时保留已展示的数据。
- **上拉加载更多**。使用 `ListView.builder` 或 `SliverList` 按需构建列表，通过 `ScrollController` 在布局完成且接近底部（`extentAfter` 低于阈值）时通知 ViewModel 加载下一页。由 View 持有并释放滚动控制器。底部状态 Widget 渲染加载中、失败重试和到底状态，失败时保留已加载列表与待重试页。
- **请求状态**。ViewModel 对重复分页请求去重，刷新期间暂停追加，刷新或切换筛选后丢弃旧查询的结果。下一页和末页以契约或本地数据源的约定为准。测试覆盖短列表刷新、到达末页、分页失败重试，以及刷新与旧分页结果乱序。

## 9. 反模式

检查散落的路由字符串、直接访问数据库的 Widget、长期持有 BuildContext 的 Repository，以及绕过项目主题的硬编码样式。
