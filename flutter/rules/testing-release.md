# 测试、环境与发布

- 单测覆盖模型解析、Repository、状态转换与并发；Widget 测试通过 fake Repository 驱动输入、错误、重试和导航。集成测试走真实入口覆盖关键流程，平台插件另用设备验证。
- 应用 CI 按画像锁定 SDK 执行 pub get、所需代码生成、格式检查、flutter analyze、flutter test。集成测试指定目标设备，例如 flutter test integration_test/app_test.dart -d DEVICE_ID（替换为实际测试及设备）。记录 AC、命令、结果、平台与未验证项。
- 应用 PR 的基础检查依次运行 `dart format --output=none --set-exit-if-changed lib test`（按实际 Dart 源目录增补）、`flutter analyze`、`flutter test`，任一失败即报告失败。使用代码生成的模块在测试前按锁定版本重新生成；若项目提交生成文件，检查再生成后无意外差异。
- dev/staging/prod 用项目的 flavor、Xcode scheme 和环境配置隔离标识、接口、推送及统计。可读构建参数仅放公开配置，签名和服务端密钥在凭据系统维护。
- Android 校验目标变体的发布 AAB/APK、签名和混淆配置；iOS 在配置好 Xcode 的 macOS 上校验归档、签名和能力。模拟器无签名构建仅证明该目标能编译。
- 发布前两端核对最低支持版本与代表性真机，覆盖升级、旧库迁移、冷启动、断网、拒绝权限。保存构建号、提交、Dart 符号、Android 映射与 iOS dSYM（按实际构建产生）。崩溃及业务指标脱敏并按版本区分。
- 分阶段发布观察崩溃、启动和核心业务成功率，明确停止扩量、关闭功能或发布修复的条件。旧客户端仍可能在线，后端继续兼容其契约。
