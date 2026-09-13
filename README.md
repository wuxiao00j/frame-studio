# 原境 · Frame Studio — Beta

**Native macOS UI designer · 原生 macOS 手机 UI 设计工具**

[下载 Beta / Download Beta](https://github.com/wuxiao00j/frame-studio/releases/tag/v1.2.0-beta.7) · [中文使用指南](docs/USER-GUIDE.zh-CN.md) · [English guide](docs/USER-GUIDE.en.md) · [MCP 中文](docs/MCP.zh-CN.md) · [MCP English](docs/MCP.en.md)

## 中文

原境是一款使用 SwiftUI 编写的 Mac 应用，用来拖拽搭建手机 App 页面，并通过本地 MCP 与 Agent 协作。

**当前版本：v1.2.0-beta.7（测试版）。导出仅包含 UI 源码、图片资源、项目配置和设计文件，不生成 APK、AAB、IPA 或可安装手机 App。** 项目骨架和页面交互是原型；业务功能、网络、登录、支付、数据存储、异常处理及正式发布仍需开发。

### 功能

- 43 种细分组件，自由拖拽、缩放、多选、对齐、吸附和圆角滑块。
- 长页面滚动、固定导航 / Tab，标准屏与阔屏内外屏横竖布局。
- 开关左右排列、条形 / 环形 / 分段进度、百分比与当前值 / 总量。
- 列表自动紧贴、外侧圆角；头像栏二维码与箭头可隐藏。
- 渐变填充、模糊、阴影颜色与偏移；上传图标、Tab 默认 / 选中图标；已有 Tab 栏的页面共用全部配置，支持项目排序。
- 保留导入容器的嵌套裁剪；文字行数、行间距与最小字号比例可调，图片支持填满 / 适应 / 拉伸，新增磨砂材质。
- 返回键默认左上角；预置组合拆分后自动解组，多选可重新组合、解组或保存复用。
- SwiftUI、Jetpack Compose、Flutter **UI 源码导出**。
- SwiftUI 按 View 结构导入、展开复用组件；动态内容与未匹配视图分别说明，保存为独立草稿。
- 27 个本地 MCP 工具，供 Agent 读取和修改设计、导入图标与导出源码。

### 开始使用

1. 下载 Release 中的 `FrameStudio-v1.2.0-beta.7-macOS-arm64.zip`。
2. 解压，将 `原境 Frame Studio.app` 放到“应用程序”，然后打开。
3. 从左侧拖入组件，在右侧编辑属性。选择“导出代码”并指定平台和文件夹。
4. 需要 Agent 协作时，点击左下角“与 Agent 一起设计”，按 [MCP 指南](docs/MCP.zh-CN.md) 配置本地服务。

发布包适用于 **Apple Silicon、macOS 14+**。这是临时签名、尚未公证的 Beta；也可以使用 Xcode 从源码构建。现有设计保存在你的本机，不随安装包上传。

**项目将持续维护，并根据反馈不定期更新组件、导入识别、导出和 MCP 能力。** 请通过 [Issues](https://github.com/wuxiao00j/frame-studio/issues) 反馈，关注 Releases 获取更新。详见 [维护计划](docs/MAINTENANCE.md)。

## English

Frame Studio is a native SwiftUI macOS application for composing mobile UI screens and collaborating with agents through a local MCP server.

**Current version: v1.2.0-beta.7. Exports contain UI source code, assets, project configuration and the design document only. They do not generate APK, AAB, IPA or installable mobile applications.** Scaffolds and local interactions are prototypes. Production features, networking, authentication, payments, persistence, error handling and distribution remain development work.

### Features

- 43 component types with drag, resize, multi-selection, alignment, snapping and corner-radius sliders.
- Scrollable pages, pinned navigation / tabs, standard and wide inner / outer layouts in both orientations.
- Leading / trailing switches and linear, circular or stepped progress with percentage or current / total labels.
- Joined list rows with outer corners; optional profile QR and chevron icons.
- Gradient fills, blur, shadow color/offsets, uploaded icons, default / selected Tab icons and item reordering; all existing Tab bars share their complete configuration.
- Retained nested import masks; editable text line limits, spacing and minimum scale; fill / fit / stretch image modes and frosted materials.
- Top-left back buttons; decomposition automatically ungroups layers for editing, regrouping and reusable templates.
- **UI source exports** for SwiftUI, Jetpack Compose and Flutter.
- Structured SwiftUI import with reusable component expansion, independent drafts and separate dynamic-content / unmatched-view reports.
- 27 local MCP tools for inspecting and editing designs, importing icons and exporting source.

### Quick start

1. Download `FrameStudio-v1.2.0-beta.7-macOS-arm64.zip` from the Beta release.
2. Unzip it, move `原境 Frame Studio.app` into Applications, and open it.
3. Drag components onto the canvas, edit properties, and choose **导出代码 / Export code** to select a platform and destination.
4. To collaborate with an agent, open the lower-left Agent panel and follow the [MCP guide](docs/MCP.en.md).

The Beta interface is currently Chinese; English documentation is included.

The downloadable binary requires **Apple Silicon and macOS 14+**. This Beta is ad-hoc signed and not notarized; source builds with Xcode are available. Your design documents remain on your machine and are not included in releases.

**The project will continue to be maintained, with component, import, export and MCP updates released as needed.** Report issues through [GitHub Issues](https://github.com/wuxiao00j/frame-studio/issues), and follow Releases for updates. See the [maintenance plan](docs/MAINTENANCE.md).

## Development / 开发

Requires macOS and Xcode 15.4+ / 需要 macOS 与 Xcode 15.4+。

```sh
swift build
swift test
python3 scripts/test-mcp.py
python3 scripts/test-platform-exports.py
python3 scripts/test-rich-design.py
python3 scripts/test-shared-tabs.py
```

Source-only platform checks / 不打包手机 App 的平台检查：

```sh
python3 scripts/verify-generated-platforms.py
```

Build the **Mac editor**, not the designed mobile app / 构建 **Mac 编辑器本身**：

```sh
scripts/build-app.sh
```

[Export contract / 导出约定](docs/EXPORT-FORMATS.md) · [Changelog / 更新日志](CHANGELOG.md) · [Third-party notices / 第三方声明](THIRD_PARTY_NOTICES.md)
