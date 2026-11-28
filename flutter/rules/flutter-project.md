# 工程结构、依赖与导航

## 1. 工程入口

在 pubspec 声明依赖与资源，从应用入口装配环境、路由与依赖。Android 和 iOS 保留各自宿主及构建配置。

## 2. 页面与组件

以[系统画像](../architecture/system-landscape.md)记录的目录、SDK、路由和状态方案为准。新业务按 feature 收拢。共享代码有第二个明确使用者或独立的平台边界时再抽取。

## 3. MVVM 分层约定

按业务模块组织 View 和 ViewModel，Repository 和 Service 属于 Model 层。

| 边界 | 工作内容 |
|---|---|
| View / Widget | 渲染不可变状态，将点击、输入交给 ViewModel。build 可以重复调用，把 I/O、导航、弹窗移出 build。 |
| ViewModel | 协调用户操作、恢复和状态转换。构造函数或项目容器注入 Repository，保持可替换。 |
| Repository | 合并服务端、本地和缓存，暴露领域模型。数据源负责 HTTP、SQL 或平台通信。DTO 在边界解析。 |
| Service | 封装 HTTP、数据库或原生接口等单一数据源，供 Repository 调用。 |
| 原生适配 | 通过类型化 Dart 接口调用 Android/iOS，测试可替换实现。业务 UI 不处理通道字符串。 |

## 4. 目录归属

以应用根为基准，在 `lib/features/{feature}/` 下按业务职责建目录。一个模块可包含多个页面，只为实际用到的层创建文件。下面以四个业务模块为例：

```text
lib/
  features/
    login/                      登录、退出与会话恢复
    pay/                        支付发起、结果与重试
    orders/                     订单列表和详情共用订单模块
      presentation/
        orders_page.dart
        utils/order_display.dart
        view_models/orders_view_model.dart
        widgets/                订单模块的 UI 组件
      data/
        order_detail_bean.dart
      request/
        orders_repository.dart
        orders_service.dart
    dispatch/                   调度任务与分派
  core/network/                 多个模块共用的请求层
    api_client.dart             HTTP 客户端创建与配置
  common_widgets/               多个业务模块共用的 UI 组件
  utils/                        多个业务模块共用的工具
test/features/orders/           订单模块的单元与 Widget 测试
integration_test/               跨模块或平台的端到端场景
```

模块内部按 §3 分工。跨模块只使用对方公开的入口或接口，路由与依赖在应用入口装配。例如，从订单详情发起支付时，订单页把订单标识交给支付入口；支付模块负责调用支付 SDK，返回订单页后由订单模块刷新订单状态。这样两个页面可以各自演进，也避免彼此引用内部 ViewModel。

**何时建独立 package。** 同一 App 内的业务模块默认共用应用的 `pubspec.yaml`。当一项能力需要供多个 App 复用，或已有明确的独立维护和测试需求时，可提取为带自己 `pubspec.yaml`、公开库入口和测试的 Dart/Flutter package。应用在自身 pubspec 中声明依赖；仓内本地包的 `path` 相对该 pubspec 所在目录填写。包的实际位置和使用方登记在画像 §3.2。

### 数据与请求目录

`lib/features/{feature}/data/` 只存放数据 Bean 及其配套文件，例如模型使用的枚举、序列化代码和字段解析。Repository、Service 及其业务请求辅助代码统一放在 `lib/features/{feature}/request/`，与 `data/` 同级。Repository 和 Service 文件分别使用 `xxx_repository.dart` 和 `xxx_service.dart` 命名。

### 展示层目录

`lib/features/{feature}/presentation/` 的直接子文件只放页面和页面级 UI 容器。ViewModel 及页面状态放在 `presentation/view_models/`，模块内的展示格式化和转换工具放在 `presentation/utils/`，例如用于显示订单金额的 `order_display.dart`。

### UI 组件归属

单个页面拆出的组件和同一业务模块内复用的组件放在 `lib/features/{feature}/presentation/widgets/`。有两个或更多业务模块需要复用的公共 UI 组件统一抽取到 `lib/common_widgets/`，与 `lib/core/` 同级。

### 跨模块工具归属

有两个或更多业务模块需要复用的工具类和工具函数统一抽取到 `lib/utils/`，与 `lib/core/`、`lib/common_widgets/` 同级。

## 5. 命名规范

业务模块目录优先使用团队日常称呼该功能的简短英文词，多词用下划线连接。同一业务在目录、详设和画像中使用同一个名称。

Dart 文件用 lower_snake_case，类型用 UpperCamelCase。页面、Widget 和 ViewModel 名称与项目词表一致。承载业务页面状态与操作的类统一命名为 `XxxViewModel`，对应文件命名为 `xxx_view_model.dart`，例如 `OrdersViewModel` 放在 `orders_view_model.dart`。`ScrollController`、`TextEditingController` 等框架控件类沿用 SDK 类型名。

### 数据 Bean 命名

`data/` 下的数据 Bean（如请求与响应 DTO、业务数据模型和本地数据模型）统一使用 `XxxBean` 类名，声明文件使用对应的 `xxx_bean.dart` 文件名。例如，`OrderDetailBean` 放在 `order_detail_bean.dart`。Bean 使用的枚举沿用枚举命名约定。序列化字段名和 OpenAPI schema 名称以契约为准。

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

新增或修改下表中的手写 Dart 声明时，在声明上方用 `///` 写中文文档注释。修改已有行为时，同步补齐受影响声明的注释。业务名称沿用 Story、详设和页面上的中文用词。

| 对象 | 注释要回答的问题 | 注释示例 |
|---|---|---|
| UI 页面 | 用户从哪里进入？对应哪个中文页面，能在这里完成什么操作？有稿时写 Story 或 DD 登记的稿名及面板或 Frame，无稿时按已确认的路由、Tab 或交互说明定位。 | 我的订单页，对应《页面设计图》面板 2「我的订单」。会员可下拉刷新列表，点击订单查看详情。 |
| 自定义 Widget（含私有组件） | 属于哪一页的哪个可见区域？展示什么、响应什么操作？为业务入参和回调注明用途、触发时机。共用组件写明复用场景。 | 我的订单页列表中的单笔订单卡片，展示商品摘要、总额和收货状态。点击卡片时触发 `onTap`，由页面打开订单详情。 |
| 模块和公共 utils | 每个工具函数或工具方法说明解决的问题、输入和返回值。涉及单位、格式、时区、空值、失败或副作用时，写清实际约定。 | 将整数分换算成订单金额展示文本，固定保留两位小数。例如输入 105，返回「¥1.05」。 |
| ViewModel 与页面状态类 | 类注释说明负责哪个页面或流程。每个字段（含私有字段）及派生 getter 逐项写明用途。状态字段说明何时改变、影响哪处 UI；请求、订阅等内部字段说明其持有或释放时机。公开操作说明触发来源和状态变化。 | `isRefreshing`：已有列表结果时，下拉刷新进入此状态，页面继续显示上次结果。`_pending`：保存当前加载任务，连续触发刷新时共用该任务，完成后清空。 |

实现内部遇到需要解释的分支，可在分支上方用 `//` 说明原因，例如会话切换后丢弃旧请求结果，以免显示上一位会员的订单。常规布局和简单赋值无需逐行翻译。

请求与响应 Bean 的字段逐项对齐当前 handoff 版本的 OpenAPI，并按[请求层规则](api-client-conventions.md#接口定义与中文注释)编写中文注释。业务用词参考领域词表。生成模型的字段注释通过契约描述、生成配置或模板保留，随契约重新生成。

以下为预约样例中的响应模型片段，字段含义与后端契约一起维护。

```dart
/// 车场详情页展示的收费说明。
class LotFeeInfoBean {
  const LotFeeInfoBean({required this.parkingFeeDescription});

  /// 车场停车费用的说明文案，供用户在选择预约时段前查看。
  final String parkingFeeDescription;
}
```

## 6. 路由与宿主配置

命名路由的路径常量和带参数的路径模板统一声明在应用根的 `lib/core/routing/app_routes.dart`，通过 `AppRoutes` 暴露。路由注册、页面跳转和重定向都引用对应的 `AppRoutes` 常量，例如 `Get.toNamed(AppRoutes.orders)`。

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
