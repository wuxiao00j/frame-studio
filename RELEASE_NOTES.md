# 原境 · Frame Studio v1.2.0-beta.3

## 中文 · Beta 测试版

公开 Beta 更新（包含之前版本功能）：原生 SwiftUI Mac UI 设计器，支持 43 种组件、长页面、标准 / 阔屏布局、图标上传、Tab 双态图标、自定义组合，以及旧 UI 源码分类导入。

本次更新：所有已有 Tab 栏共用全部配置，修改项目、排序、图标、样式、位置尺寸自动同步；各屏幕形态保留独立布局。旧设计按第一个 Tab 栏统一，新 Tab 继承配置。返回键默认左上角；拆分为基础组件后自动解组，编辑后可多选组合或解组。

**导出只包含 UI 源码、资源、项目配置和设计文件，不生成 APK、AAB、IPA 或可安装手机 App。** 原型导航、开关和表单不代表业务功能已完成，后续仍需开发真实业务逻辑。

- 下载 `FrameStudio-v1.2.0-beta.3-macOS-arm64.zip`，解压并将应用放到“应用程序”。
- 需要 Apple Silicon 与 macOS 14+；Beta 使用临时签名，尚未公证。
- Agent 可使用内置的 27 个本地 MCP 工具，安装与配置见 [中文 MCP 指南](https://github.com/wuxiao00j/frame-studio/blob/main/docs/MCP.zh-CN.md)。
- [中文使用指南](https://github.com/wuxiao00j/frame-studio/blob/main/docs/USER-GUIDE.zh-CN.md)。
- 项目将持续维护，不定期更新组件、导入 / 导出和 MCP。欢迎在 Issues 反馈问题、提出组件需求，关注 Releases 获取更新。

安装包中的 `.app` 是 Mac 设计编辑器，不是导出的手机 App。个人设计、上传图片、测试数据和手机安装包不包含在发布资源中。

## English · Beta preview

An update to the public Beta of a native SwiftUI Mac UI designer, with 43 components, long pages, standard / wide layouts, uploaded icons, two-state Tab icons, reusable composites and source-based UI import classification.

This update shares the complete configuration across all existing Tab bars, including items, order, icons, styling and layout frames. Screen variants remain independent. Legacy designs use the first Tab as the shared configuration; new Tabs inherit it. Back buttons default to the top left. Decomposition automatically ungroups layers for individual editing and multi-selection regrouping.

**Exports contain UI source, assets, project configuration and design files only. They do not produce APK, AAB, IPA or installable mobile applications.** Prototype navigation, switches and forms are not completed business features. Production application logic remains development work.

- Download `FrameStudio-v1.2.0-beta.3-macOS-arm64.zip`, unzip it and move the application into Applications.
- Requires Apple Silicon and macOS 14+. The Beta is ad-hoc signed and not notarized.
- Agents can use the 27 bundled local MCP tools. See the [English MCP guide](https://github.com/wuxiao00j/frame-studio/blob/main/docs/MCP.en.md).
- [English user guide](https://github.com/wuxiao00j/frame-studio/blob/main/docs/USER-GUIDE.en.md).
- The project will continue to be maintained, with component, import/export and MCP updates released as needed. Report issues and component requests through Issues, and follow Releases for updates.

The packaged `.app` is the Mac design editor, not an exported mobile app. Release assets do not include personal designs, uploaded images, local test data or mobile installation packages.
