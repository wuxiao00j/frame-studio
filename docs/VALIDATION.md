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

Beta.4 reproduced the reported exclusive-access abort through the actual X binding before the fix. After the fix, 43 Swift tests pass, including six editor tests for X/Y/W/H, six variants, no-op focus writeback, gesture commits, undo/redo, progress/layout changes, invalid-value rollback and stale Agent writes. / Beta.4 在修复前通过实际 X 属性绑定复现报告中的内存访问冲突；修复后 43 项 Swift 测试通过，其中新增 6 项编辑器测试覆盖坐标宽高、六种布局、焦点回写、手势提交、撤销重做、进度与布局修改、无效值回滚及过期 Agent 写入。

The Beta.4 release build also passes all 43 Swift tests. In an isolated native window, X, Y, W and H were clicked and changed to 42, 480, 300 and 60; the canvas and saved document matched, with no abort. / Beta.4 发布构建同样通过全部 43 项 Swift 测试；在隔离原生窗口中逐项点击并将 X、Y、W、H 改为 42、480、300、60，画布与保存文件一致，未再崩溃。

Beta.5 adds parser coverage for declaration boundaries, comment/string handling, custom View and ViewBuilder expansion, source modifiers, scoped layouts, real Picker/Toggle content, Tab destinations, static lists, incomplete source, and observed state/color overrides. Original-app simulator builds, when explicitly requested, are separate from the source-only export checks and never enter release archives. / Beta.5 新增声明边界、注释字符串、自定义 View / ViewBuilder、修饰器、布局作用域、选择器与开关内容、Tab 目标、静态列表、不完整源码及运行状态/颜色参数检查。用户明确要求的原 App 模拟器构建与源码导出检查分开处理，不进入发布包。

Beta.5 validation includes 60 Swift tests and real MCP import/export calls. A private source project was separately launched in an iPhone Simulator on user request; its observed local, logged-out state and source-verified light palette were supplied to the non-executing importer. The generated draft remains an approximation for complex layout, effects and uncaptured states. / Beta.5 验证包括 60 项 Swift 测试与真实 MCP 导入/导出。按用户要求另外运行了原项目的 iPhone 模拟器，将观察到的未登录本地状态与经源码核对的浅色配色提供给静态导入器；复杂布局、效果和未观察状态仍需继续校对。

Beta.6 adds regression cases for gradient color/alpha, radial source exports, tuple maps, flexible sizing, child radii, adaptive branches, multiline locals, transparent overlays and header slots. Native PNG renders are inspected alongside the original simulator UI. Android/Flutter/SwiftUI validation remains source-only. / Beta.6 新增渐变透明度、径向渐变导出、元组映射、弹性尺寸、子图层圆角、自适应分支、多行变量、透明叠加层与标题插槽回归检查，并将原生 PNG 渲染与模拟器原界面对照；三平台验证仍仅针对源码。

Beta.6 local checks passed 68 Swift tests, actual MCP acceptance, Flutter analysis/widget tests, Kotlin compilation and generated SwiftUI type checks. Linear/radial gradients, blur and shadow properties are included in the export fixture. / Beta.6 本机通过 68 项 Swift 测试、真实 MCP 验收、Flutter 分析与 Widget 测试、Kotlin 编译和生成 SwiftUI 类型检查；三平台样例包含线性/径向渐变、模糊与阴影属性。


Beta.7 adds coverage for nested ancestor masks in six variants, mask rebasing during decomposition, actual native mask pixels, Chinese paragraph sizing, Text-extension modifier chains, conditional theme paints, material classification, image fitting, invalid rendering fields and MCP null/reset writes. Source fixtures include these properties; Flutter checks also inspect mask intersections, minimum text scale, BackdropFilter and BoxFit. / Beta.7 新增六套布局嵌套裁剪、拆分后裁剪坐标转换、原生裁剪像素、中文段落尺寸、Text 扩展修饰器链、主题条件颜色、材质分类、图片适应、无效参数以及 MCP 清空属性检查；三平台样例包含新增属性，Flutter 另检验裁剪交集、文字缩放下限、背景模糊和图片适应。

Beta.7 local validation passed 78 Swift tests, 34 Flutter widget/unit checks, actual MCP acceptance (including rejected invalid writes and null resets), Kotlin compilation and generated SwiftUI type checking. The private imported draft was separately exported to all three UI source formats and its SwiftUI source type-checked. / Beta.7 本机通过 78 项 Swift 测试、34 项 Flutter 检查、真实 MCP 验收（包括无效写入拒绝与 null 清空）、Kotlin 编译及 SwiftUI 类型检查；私有导入草稿另外完成三平台源码导出与 SwiftUI 类型检查。

Layer-list regression coverage verifies individual and Shift selection without changing group membership or the saved design. / 图层列表回归检查确认单选与 Shift 多选不会改变原有组合或保存文件。


Beta.8 adds isolated regression fixtures for enum choices, ambiguous case names, initial selection, State initializers, false conditional hints, comparison text as data, form grouping, toolbar placement and disabled save actions. The native rendered form is compared with an explicitly opened original-app simulator form. Cross-platform checks include form-row controls, initial selection and disabled prototype navigation. / Beta.8 使用隔离样例检查枚举选项、重名枚举值、默认选中项、State 初始化、错误条件提示、比较符号文本、表单分组、工具栏位置与禁用保存按钮，并将原生渲染表单与按用户要求打开的模拟器表单对照；三平台检查包含表单行、初始选项和禁用的原型导航。

Beta.8 local checks passed 82 Swift tests and 36 Flutter widget/unit checks, actual MCP acceptance, Kotlin compilation and SwiftUI source type checking. The private 37-page draft also passed three source exports and a SwiftUI type check. Hidden navigation and nil optional-date initialization have dedicated regression coverage. / Beta.8 本机通过 82 项 Swift 测试、36 项 Flutter 检查、真实 MCP 验收、Kotlin 编译及 SwiftUI 类型检查；37 页私有草稿另行通过三平台源码导出与 SwiftUI 类型检查，并覆盖隐藏导航和空值日期初始化。


Beta.9 adds checks for all seven bundled templates, independent insertion IDs, category compatibility, preserved rendering properties, personal-library reloads, stale/invalid-write rejection and reuse from a new editor project. Actual MCP acceptance exercises categorized template creation and bundled template insertion. / Beta.9 新增 7 个内置模板、独立插入 ID、旧分类兼容、渲染属性保留、个人库重新加载、过期或无效写入拒绝，以及新项目复用检查；真实 MCP 验收覆盖分类保存和内置模板插入。

Beta.9 local verification passed 86 Swift tests, 36 Flutter checks, actual MCP acceptance, Kotlin compilation and SwiftUI source type checking. / Beta.9 本机通过 86 项 Swift 测试、36 项 Flutter 检查、真实 MCP 验收、Kotlin 编译与 SwiftUI 类型检查。
