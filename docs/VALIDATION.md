# Beta 验证范围 / Beta validation scope

本次发布验证 UI 编辑器、MCP 和源码交付约定，不生成手机安装包。 / This release validates the editor, MCP and UI-source handoff contract without packaging mobile applications.

- Core Swift tests / Swift 核心测试。
- Actual STDIO MCP handshake and tool calls / 真实 STDIO MCP 握手与工具操作。
- Three-platform source export contents and `export-manifest.json` / 三平台源码导出内容与机器可读清单。
- Flutter static analysis and widget interaction tests / Flutter 静态分析和 Widget 交互测试。
- Kotlin compilation and SwiftUI type-checking / Kotlin 编译与 SwiftUI 类型检查。
- Public source / release archive audit and checksums / 公开源码、发布包检查与校验值。

APK / AAB / IPA / mobile app bundles are excluded from exports and release assets. The separately packaged `.app` is the **macOS design editor**. / 手机安装包不进入导出目录或发布资源；单独打包的 `.app` 是 **macOS 设计编辑器本身**。

Local logs and fixtures are not published. Tests do not establish that arbitrary imported projects or custom expressions are production-ready. / 本机测试日志和数据不公开；测试通过不代表任意导入工程或自定义代码已经达到正式业务发布状态。

Beta.3 adds regression coverage for complete cross-page Tab sharing, layout variants, legacy loading, new Tab inheritance, revision conflicts, undo/redo snapshots, top-left back buttons and automatic ungrouping. Local source verification passed 37 Swift tests and 31 Flutter widget/unit tests, plus Kotlin compilation and SwiftUI type-checking. The isolated Mac demo was used to confirm cross-page radius updates and individual selection after decomposition. / Beta.3 新增共用 Tab、屏幕布局、旧文件读取、新 Tab 继承、版本冲突、撤销重做快照、左上角返回键和自动解组回归检查。本机通过 37 项 Swift 测试与 31 项 Flutter 测试，以及 Kotlin 编译和 SwiftUI 类型检查；使用隔离 Mac 示例确认跨页圆角更新和拆分后的独立选择。
