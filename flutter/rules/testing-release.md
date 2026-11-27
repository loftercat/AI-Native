# 测试、环境与发布

- 单测覆盖模型解析、Repository、状态转换与并发；Widget 测试通过 fake Repository 驱动输入、错误、重试和导航。集成测试走真实入口覆盖关键流程，平台插件另用设备验证。
- 应用 CI 按画像锁定 SDK 执行 pub get、所需代码生成、格式检查、flutter analyze、flutter test。集成测试指定目标设备，例如 flutter test integration_test/app_test.dart -d DEVICE_ID（替换为实际测试及设备）。记录 AC、命令、结果、平台与未验证项。
- 应用 PR 的基础检查依次运行 `dart format --output=none --set-exit-if-changed lib test`（按实际 Dart 源目录增补）、`flutter analyze`、`flutter test`，任一失败即报告失败。使用代码生成的模块在测试前按锁定版本重新生成；若项目提交生成文件，检查再生成后无意外差异。
- Android 校验目标变体的发布 AAB/APK、签名和混淆配置；iOS 在配置好 Xcode 的 macOS 上校验归档、签名和能力。模拟器无签名构建仅证明该目标能编译。
- 发布前两端核对最低支持版本与代表性真机，覆盖升级、旧库迁移、冷启动、断网、拒绝权限。保存构建号、提交、Dart 符号、Android 映射与 iOS dSYM（按实际构建产生）。正式环境的崩溃及业务指标脱敏并按版本区分。
- 分阶段发布观察崩溃、启动和核心业务成功率，明确停止扩量、关闭功能或发布修复的条件。旧客户端仍可能在线，后端继续兼容其契约。

## 打包配置

### 环境与构建模式

Android 使用 `dev`、`prod` 两个 product flavor，iOS 使用同名共享 Xcode scheme，并配置 `Debug-dev`、`Release-dev`、`Debug-prod`、`Release-prod`。在 `pubspec.yaml` 中将默认 flavor 设为 `dev`，普通 Flutter 运行使用 `devDebug`。flavor 决定连接环境，构建模式决定日志和混淆。

| 构建变体 | 服务地址 | 日志与混淆 |
|---|---|---|
| `devDebug` | `APP_BASE_TEST_URL` | 开启完整 Talker 网络日志和查看入口，关闭混淆 |
| `prodDebug` | `APP_BASE_RELEASE_URL` | 开启完整 Talker 网络日志和查看入口，关闭混淆 |
| `devRelease` | `APP_BASE_TEST_URL` | 关闭网络日志、调试输出及查看入口，自动启用 Dart 混淆 |
| `prodRelease` | `APP_BASE_RELEASE_URL` | 关闭网络日志、调试输出及查看入口，自动启用 Dart 混淆 |

Flutter 的 Profile 模式可用于性能分析，按所选 flavor 连接环境，关闭网络日志和查看入口。使用 `kDebugMode` 控制网络日志及路由。Android 两个 Release 变体均启用 R8 和资源压缩。

### 客户端配置与签名

客户端公开配置集中在 `lib/core/config/app_config.dart`，通过 `AppConfig` 提供给请求层和已接入的 SDK。统一定义 `APP_BASE_TEST_URL`、`APP_BASE_RELEASE_URL`，按接入范围登记 `WECHAT_APP_ID`、`WECHAT_KF_ID`、`WECHAT_KF_URL` 和 `MAP_APP_KEY` 等公开配置。用 `const String.fromEnvironment` 读取构建参数，可在 `defaultValue` 填写公开默认值。同名 `--dart-define` 可覆盖默认值，也可用 `--dart-define-from-file` 按环境批量传入。

安装包中使用到的配置值按可读取处理。微信 App ID 和公开客服入口可以随包发布。移动端地图 SDK Key 在厂商后台绑定实际应用标识及所需的签名指纹。微信 AppSecret、服务端 API 密钥和共享签名密钥保存在服务端。签名私钥和密码由本地未跟踪的配置或 CI 凭据提供，Android 可使用 `android/key.properties`，iOS 使用 Xcode 签名配置。

### 构建与验收

从应用根构建，通过 `--flavor dev` 或 `--flavor prod` 选择环境。Profile 和 Release 使用 HTTPS。需要配置地址时，填写项目中的公开默认值或传入对应 URL 参数。

```bash
flutter run
flutter build apk --flavor dev --debug
flutter build apk --flavor dev --release
flutter build apk --flavor prod --release
flutter build appbundle --flavor prod --release
flutter build ipa --flavor prod --release
```

Release 的项目打包入口自动应用 Dart 混淆并输出符号，例如使用 Flutter 的 `--obfuscate` 与 `--split-debug-info` 设置或等效原生构建配置。符号按平台和 flavor 输出，例如 `build/symbols/<platform>/<flavor>/`。归档时同时保存对应版本号、构建号、提交、Android R8 映射及 iOS dSYM。

验收四种构建变体的实际 API 地址、日志开关和对应签名。Release 需检查产出的 Dart 符号，Android 同时检查 R8 映射和资源压缩。正式分发使用 `prodRelease` 及对应发布签名。

## 分环境日志

### Debug 网络日志

`devDebug` 和 `prodDebug` 都使用统一 Dio 客户端接入 Talker。控制台和 TalkerScreen 记录每次请求的完整 URL、参数、请求与响应头和正文、状态、耗时及关联 ID，并记录失败时的响应、异常和堆栈。完整 JSON 保留原值。长报文按序号分段打印，二进制内容用可还原的编码分段。真机日志页和本地导出保留相同内容，网络明细仅用于本地诊断。Profile 和两个 Release 变体关闭该拦截器的明细记录及查看路由。

### 日志 Tag

统一 Dio 的请求、响应和异常使用 `DioRequest`。Android 写入 Logcat 的原生 Tag，使用 `tag:DioRequest` 筛选；其他平台控制台以 `[DioRequest]` 标记。长报文的所有分段使用同一 Tag，保留请求、响应、异常的事件类型和关联 ID。

其他功能或 SDK 以对应功能名称设置固定 Tag，例如高德地图用 `GaodeMap`。同一功能的初始化、回调和错误沿用同一个 Tag。

### 其他诊断日志

| 用途 | 记录内容 |
|---|---|
| 开发调试 | 按时间记录推送的注册、到达、点击和路由结果，按消息标识串联。SDK 初始化记录名称、版本、开始、成功或失败、耗时和错误码。 |
| 专项调试 | 用已知测试数据验证推送与 SDK。按需记录注册、接收、点击、路由结果、完整回调和错误详情。 |
| 正式监控 | 按事件白名单记录 SDK 关键生命周期、应用未捕获异常和导致核心流程中断的失败。摘要包含版本、平台、阶段、错误码及脱敏关联 ID。异常可附清理后的堆栈。Release 停止控制台调试打印。 |

开发和正式环境的其他诊断日志在进入日志系统前移除或遮盖凭据与真实个人数据，包括推送载荷和异常文本里的令牌、验证码、密码及推送设备令牌。控制台、内存历史、导出报告和崩溃事件沿用这一边界。专项调试使用已知测试数据保留原始回调和错误详情。

接入远程日志 SDK 时，从正式关键事件白名单生成结构化上传记录。上传使用短期授权，隔离环境，异步发送并限制队列大小与重试次数。排除上传 SDK 自身的网络请求和重试日志，避免递归上报。上传失败时业务照常执行。

验收时用已知数据覆盖网络成功与失败，核对头、正文、异常和耗时，并重组长 JSON 及二进制分段确认完整性。两个 Debug 变体均验证控制台输出与 TalkerScreen。两个 Release 变体验证查看入口关闭，控制台无请求及响应正文。涉及推送或 SDK 时，另用已知测试数据核对推送点击和 SDK 初始化失败，正式监控保留定位关键失败所需的脱敏摘要。
