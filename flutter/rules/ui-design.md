# 设计交接与界面验收

Story 的「设计稿」节按页面/组件登记稿件位置与状态，视觉 AC 引用对应行。Figma 稿件另记 Frame/node 与版本或快照。接到 Figma 链接时读取指定节点和截图；无法取得时登记已有交付截图或标注。无稿项标「无 → UI: TBD」并向用户要稿或确认样式。已确认采用工程主题时，将决定记入对应条目。

DD 将节点映射到 ThemeData、ColorScheme、TextTheme、公共按钮/输入框和资源文件，写明字号行高、间距、裁剪、亮暗主题、禁用/焦点/加载/错误态。区分设计基准尺寸与布局伸缩规则。使用 SafeArea、可滚动布局和键盘 inset；验证文字放大、长翻译和小屏。交互控件具有语义名称与合理触控区域，错误反馈不只靠颜色。

编码时核对设计版本，在基准尺寸截实现图，与设计图核对素材、布局和交互状态。记录设备、窗口、字体倍率、版本、偏差及处置。安卓和 iOS 上分别验证本卡的平台差异；Golden 图适合稳定组件，真机检查键盘、安全区、辅助功能及手势。

## Figma 图片导出

开发者提供 Figma 链接，AI 在编码时按 DD 登记的节点和版本导出本卡用到的图片。先查现有资源，复用相同素材；从图标、插画或切片节点导出，页面上的文字和交互控件用 Flutter 实现。核对导出文件的实际像素、透明边距与设计尺寸。节点无法读取或导出时，说明缺少的节点或权限，标记受影响的素材待补。整页预览截图仅供视觉比对。

- **业务位图**统一放在应用根的 `assets/image/`。文件名用业务含义区分，如 `pay_success.png`。每张图默认仅导入设计所需的最高有效倍率，通常为 4x。例如设计尺寸 24 × 24，导出 96 × 96 到 `assets/image/4.0x/pay_success.png`。对于嵌入的位图，先核对原图分辨率；放大导出不能增加细节。
- **额外倍率**按实际需要补。比如低倍率设备上大图解码内存仍超预算，或设计提供了针对小尺寸单独绘制的版本，同名文件可分别放到 `assets/image/3.0x/` 和 `assets/image/4.0x/`。各版本保持相同逻辑尺寸；大图按实际展示尺寸和设备像素比控制解码大小。
- **打包和调用**均使用省略倍率目录的逻辑路径。仅有 4x 文件时，在应用 pubspec 中逐图显式登记逻辑路径；页面按设计尺寸展示。构建后通过该路径加载图片，核对显示尺寸和清晰度。[Flutter 倍率资源说明](https://docs.flutter.dev/ui/assets/assets-and-images#bundling-of-resolution-aware-image-assets)

```yaml
flutter:
  assets:
    - assets/image/pay_success.png
```

```dart
Image.asset('assets/image/pay_success.png', width: 24, height: 24)
```

## 宿主原生图片

桌面图标、原生启动画面和原生 SDK 指定的图片，按实际使用方导入宿主工程。仅宿主使用的资源在宿主维护，Flutter 页面需要同一设计时再登记 Flutter 资源。

- Android 核对目标变体 Manifest 引用的资源，在相应 source set 的 res 目录配置。桌面自适应图标按设计提供前景、背景，按目标覆盖补单色层及旧版 launcher 所需的 mipmap 资源。[Android 自适应图标](https://developer.android.com/develop/ui/compose/system/icon_design_adaptive)
- iOS 先检查当前 target 选中的 Asset Catalog 和 AppIcon 配置。Single Size 可交付一张 1024 × 1024 母图由 Xcode 生成所需尺寸；All Sizes 按现有槽位导入，独立设计的外观按需补齐。启动图按当前 Launch Screen 实际引用配置。[Apple 图标配置](https://developer.apple.com/documentation/xcode/configuring-your-app-icon)
- 验收时分别查看对应构建的桌面图标、冷启动首屏或原生 SDK 界面。鸿蒙宿主资源在该平台实际接入时按其宿主配置验证。

## 全局静态文案

Flutter 界面使用一个全局中文文案源 `lib/l10n/app_zh.arb`，由 Flutter gen-l10n 生成类型安全的 AppLocalizations。按钮、标题、提示、应用自定义的错误文案和无障碍标签通过键引用；优先复用含义相同的键，业务专用键带简明前缀，如 loginTitle、paySuccess。含变量的句子使用 ARB 占位符，界面传入参数。服务端业务数据、协议值和环境配置按各自来源维护。

在应用 pubspec 加入 SDK 的 flutter_localizations 和该 SDK 兼容的 intl，开启 flutter.generate。应用根 l10n.yaml 设置如下：

```yaml
arb-dir: lib/l10n
template-arb-file: app_zh.arb
output-localization-file: app_localizations.dart
nullable-getter: false
```

```json
{
  "@@locale": "zh",
  "loginTitle": "登录",
  "paySuccess": "支付成功"
}
```

运行 `flutter gen-l10n`，在应用根 Widget 注册 AppLocalizations.localizationsDelegates 和 AppLocalizations.supportedLocales。页面导入生成的库后直接使用 `Text(AppLocalizations.of(context).paySuccess)`。修改文案只编辑 ARB 源文件；将来增加语言时按语言补对应 ARB。[Flutter 文案资源说明](https://docs.flutter.dev/ui/internationalization)
