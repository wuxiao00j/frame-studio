# 原境 · Frame Studio v1.2.0-beta.8

## 中文 · Beta 测试版

公开 Beta 更新（包含之前版本功能）：原生 SwiftUI Mac UI 设计器，支持 43 种组件、长页面、标准 / 阔屏布局、图标上传、Tab 双态图标、自定义组合，以及旧 UI 源码分类导入。

本次补齐 SwiftUI 表单导入：识别无关联值枚举的 allCases、rawValue 与静态标签，读取 State(initialValue:) 默认状态，解析常见布尔组合和空值回退。修正选项显示变量名、选中状态丢失、错误展示条件提示的问题。

Form / Section 保留常见分组卡片、标题、内边距和行分隔线；顶部导航标题与左右工具栏按钮转换成可编辑图层。多行输入按 axis 转换，新增“手机表单行”样式、默认选项与“启用交互”属性；日期值可使用 Agent 提供的运行对照值。简单 dismiss() 转换为原型返回，保存等业务处理不会执行或自动实现。

新增属性同步至 Mac 预览、SwiftUI、Compose、Flutter 源码和 MCP。复杂自定义表单、未提供的日期或运行状态、平台字体与系统玻璃效果仍需对照调整。

**导出只包含 UI 源码、资源、项目配置和设计文件，不生成 APK、AAB、IPA 或可安装手机 App。** 原型导航、开关和表单不代表业务功能已完成，后续仍需开发真实业务逻辑。

- 下载 `FrameStudio-v1.2.0-beta.8-macOS-arm64.zip`，解压并将应用放到“应用程序”。
- 需要 Apple Silicon 与 macOS 14+；Beta 使用临时签名，尚未公证。
- Agent 可使用内置的 27 个本地 MCP 工具，安装与配置见 [中文 MCP 指南](https://github.com/wuxiao00j/frame-studio/blob/main/docs/MCP.zh-CN.md)。
- [中文使用指南](https://github.com/wuxiao00j/frame-studio/blob/main/docs/USER-GUIDE.zh-CN.md)。
- 项目将持续维护，不定期更新组件、导入 / 导出和 MCP。欢迎在 Issues 反馈问题、提出组件需求，关注 Releases 获取更新。

安装包中的 `.app` 是 Mac 设计编辑器，不是导出的手机 App。个人设计、上传图片、测试数据和手机安装包不包含在发布资源中。

## English · Beta preview

An update to the public Beta of a native SwiftUI Mac UI designer, with 43 components, long pages, standard / wide layouts, uploaded icons, two-state Tab icons, reusable composites and source-based UI import classification.

This update improves SwiftUI form import: it expands allCases, raw values and static labels from enums without associated values, reads State(initialValue:) defaults, and resolves common Boolean combinations and nil fallbacks. This fixes variable names shown as options, lost initial selection and incorrectly included conditional hints.

Common Form / Section groups retain cards, headings, insets and row separators. Navigation titles and leading/trailing toolbar buttons become editable layers. Vertical text fields become multiline inputs. Added mobile form-row styling, initial selection and enabled-state properties; date values can come from agent-supplied runtime references. A simple dismiss() becomes prototype back navigation; save handlers and other business logic are neither executed nor implemented.

Added properties work in Mac previews, SwiftUI, Compose and Flutter source exports, and MCP. Complex custom forms, unspecified dates or runtime states, platform font metrics and system glass effects still require visual comparison.

**Exports contain UI source, assets, project configuration and design files only. They do not produce APK, AAB, IPA or installable mobile applications.** Prototype navigation, switches and forms are not completed business features. Production application logic remains development work.

- Download `FrameStudio-v1.2.0-beta.8-macOS-arm64.zip`, unzip it and move the application into Applications.
- Requires Apple Silicon and macOS 14+. The Beta is ad-hoc signed and not notarized.
- Agents can use the 27 bundled local MCP tools. See the [English MCP guide](https://github.com/wuxiao00j/frame-studio/blob/main/docs/MCP.en.md).
- [English user guide](https://github.com/wuxiao00j/frame-studio/blob/main/docs/USER-GUIDE.en.md).
- The project will continue to be maintained, with component, import/export and MCP updates released as needed. Report issues and component requests through Issues, and follow Releases for updates.

The packaged `.app` is the Mac design editor, not an exported mobile app. Release assets do not include personal designs, uploaded images, local test data or mobile installation packages.
