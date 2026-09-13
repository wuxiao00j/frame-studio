# 原境 · Frame Studio v1.2.0-beta.6

## 中文 · Beta 测试版

公开 Beta 更新（包含之前版本功能）：原生 SwiftUI Mac UI 设计器，支持 43 种组件、长页面、标准 / 阔屏布局、图标上传、Tab 双态图标、自定义组合，以及旧 UI 源码分类导入。

本次继续改进导入还原：保留线性 / 径向渐变、模糊和阴影，修正卡片正文遮挡、标题操作缺失、横向宽度分配、元组标签与固定背景顺序。不同屏幕的 ViewThatFits 分支分别保留；可提供画布尺寸和安全区作为对照。渐变等属性可在编辑器修改并随三平台源码导出。复杂自定义裁剪、系统玻璃材质及未提供的运行状态仍可能与原 App 不同。

**导出只包含 UI 源码、资源、项目配置和设计文件，不生成 APK、AAB、IPA 或可安装手机 App。** 原型导航、开关和表单不代表业务功能已完成，后续仍需开发真实业务逻辑。

- 下载 `FrameStudio-v1.2.0-beta.6-macOS-arm64.zip`，解压并将应用放到“应用程序”。
- 需要 Apple Silicon 与 macOS 14+；Beta 使用临时签名，尚未公证。
- Agent 可使用内置的 27 个本地 MCP 工具，安装与配置见 [中文 MCP 指南](https://github.com/wuxiao00j/frame-studio/blob/main/docs/MCP.zh-CN.md)。
- [中文使用指南](https://github.com/wuxiao00j/frame-studio/blob/main/docs/USER-GUIDE.zh-CN.md)。
- 项目将持续维护，不定期更新组件、导入 / 导出和 MCP。欢迎在 Issues 反馈问题、提出组件需求，关注 Releases 获取更新。

安装包中的 `.app` 是 Mac 设计编辑器，不是导出的手机 App。个人设计、上传图片、测试数据和手机安装包不包含在发布资源中。

## English · Beta preview

An update to the public Beta of a native SwiftUI Mac UI designer, with 43 components, long pages, standard / wide layouts, uploaded icons, two-state Tab icons, reusable composites and source-based UI import classification.

This update preserves linear/radial gradients, blur and shadows, and fixes obscured card content, missing header actions, row sizing, tuple labels and pinned background order. ViewThatFits alternatives are retained per screen variant, with optional reference canvas dimensions and top inset. Effects are editable and included in all three source exports. Complex custom clipping, system glass materials and unspecified runtime states can still differ from the original app.

**Exports contain UI source, assets, project configuration and design files only. They do not produce APK, AAB, IPA or installable mobile applications.** Prototype navigation, switches and forms are not completed business features. Production application logic remains development work.

- Download `FrameStudio-v1.2.0-beta.6-macOS-arm64.zip`, unzip it and move the application into Applications.
- Requires Apple Silicon and macOS 14+. The Beta is ad-hoc signed and not notarized.
- Agents can use the 27 bundled local MCP tools. See the [English MCP guide](https://github.com/wuxiao00j/frame-studio/blob/main/docs/MCP.en.md).
- [English user guide](https://github.com/wuxiao00j/frame-studio/blob/main/docs/USER-GUIDE.en.md).
- The project will continue to be maintained, with component, import/export and MCP updates released as needed. Report issues and component requests through Issues, and follow Releases for updates.

The packaged `.app` is the Mac design editor, not an exported mobile app. Release assets do not include personal designs, uploaded images, local test data or mobile installation packages.
