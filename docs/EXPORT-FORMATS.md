# UI 源码导出 / UI source exports

| 格式 / Format | 输出 / Output |
| --- | --- |
| SwiftUI | Swift 页面、支持代码、图片资源、Xcode / Swift Package 配置 / Swift pages, support code, assets and project configuration |
| Android Compose | Kotlin UI 页面、组件、资源、Manifest、Gradle 配置 / Kotlin UI, components, assets, manifest and Gradle configuration |
| Flutter | Dart 页面、Widget、assets、pubspec 与平台配置 / Dart pages, widgets, assets, pubspec and platform configuration |

## 中文

三种格式均只生成 UI 源码交付目录，不执行手机打包，不输出 APK、AAB、IPA 或可安装手机 App。目录中的项目配置用于继续开发和集成；Gradle Wrapper 是构建工具，不是手机应用。

每次导出都包含 `Design.framestudio`、`UI_HANDOFF.md` 和 `export-manifest.json`。清单明确标记 `exportKind=ui-source-only`、`includesMobileBinary=false`、`businessLogicImplemented=false`。

页面跳转、返回、开关和表单状态属于原型交互。业务服务、登录、支付、数据存储、异常处理以及正式测试 / 签名 / 发布由后续项目开发完成。

系统图标会按平台映射；上传图片作为实际资源保存。自定义组件需提供目标平台表达式，未提供的控件会留下占位与报告。旧 UI 导入属于静态分类草稿。

## English

All three formats produce UI source handoff folders only. Export does not package mobile apps or output APK, AAB, IPA or installable mobile applications. Project configuration supports further development and integration; the Gradle Wrapper is a build tool, not a mobile app.

Each export includes `Design.framestudio`, `UI_HANDOFF.md` and `export-manifest.json`. The manifest declares `exportKind=ui-source-only`, `includesMobileBinary=false` and `businessLogicImplemented=false`.

Navigation, back actions, switches and form state are prototype interactions. Production services, authentication, payments, persistence, error handling, testing, signing and distribution remain subsequent development work.

System icons are mapped between platforms; uploaded images are preserved as assets. Custom components require a target-platform expression, otherwise placeholders and reports identify the gap. Existing-UI import is a static classification draft.
