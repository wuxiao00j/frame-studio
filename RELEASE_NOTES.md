# 原境 · Frame Studio v1.2.0-beta.10

## 中文 · Beta 测试版

基础组件增至 48 种：新增胶囊、椭圆、键值行、菜单按钮和空状态。菜单支持编辑项目文字、系统或上传图标及目标页面；空状态支持说明、图标和可选操作。键值行与空状态可以拆为基础图层，修改后合并并分类保存到项目或个人组件库。Mac 预览及三平台 UI 源码导出同步支持这些组件。

SwiftUI 导入新增 Menu、LabeledContent、ContentUnavailableView 分类，直接数据列表和 Section 标题 / 页脚；复杂空状态保留为基础图层组合。补充可确定的可选值、条件、局部函数、闭包 / 键路径文案及父页面参数解析。不同调用点参数不一致、循环动态数据等仍保留待补充标记。

导入窗口可选择语言，支持输入语言代码，如 zh-Hans 或 en；“自动”使用源码字符串目录的默认语言。读取普通 xcstrings 翻译、InfoPlist.strings，以及源码 Info.plist / Xcode 中可确定的应用名称和版本。Text 的字符串变量与 verbatim 内容保持原语义；不执行源码、构建脚本或业务闭包。

本阶段主要完善有源码的 SwiftUI 项目。Flutter、Compose 和 Web 源码仍是基础分类与 Agent 辅助还原；不支持把任意已安装 App 或安装包直接转成等价可编辑设计。运行数据、复杂自定义布局、动画、材质和未支持的修饰器仍需对照原 App 补全。“无未匹配组件”不代表视觉还原已完成。

**导出只包含 UI 源码、资源、项目配置和设计文件，不生成 APK、AAB、IPA 或可安装手机 App。** 原型交互仍需要开发者继续实现业务功能。

- 下载 `FrameStudio-v1.2.0-beta.10-macOS-arm64.zip`，解压并将应用放到“应用程序”。需要 Apple Silicon 和 macOS 14+；Beta 临时签名，尚未公证。
- [中文使用指南](https://github.com/wuxiao00j/frame-studio/blob/main/docs/USER-GUIDE.zh-CN.md) · [Agent / MCP 安装与使用](https://github.com/wuxiao00j/frame-studio/blob/main/docs/MCP.zh-CN.md)。MCP 已内置，提供 28 个本地工具。
- 项目将持续维护，按反馈不定期更新。欢迎通过 Issues 反馈并关注 Releases。

发布包仅包含 Mac 编辑器、源码与通用示例，不包含个人设计、上传资源或测试数据。

## English · Beta preview

The component catalog now has 48 types, adding capsule, ellipse, key-value row, menu button and empty state. Menus expose item text, system or uploaded icons and page destinations; empty states expose a description, icon and optional action. Key-value rows and empty states can be decomposed, edited, merged and saved under a category in the project or personal library. Mac previews and all three UI source exports support the new types.

SwiftUI import now classifies Menu, LabeledContent and ContentUnavailableView, supports direct data lists and Section headers / footers, and preserves complex empty states as editable primitive groups. Added resolution for known optional values, conditions, local functions, closure / key-path labels and parent-page inputs. Conflicting call-site inputs and dynamic loop data remain marked for completion.

The import dialog offers language selection and accepts language codes such as zh-Hans or en. Automatic selection uses the source catalog's default language. The importer reads ordinary xcstrings translations, InfoPlist.strings and unambiguous application names / versions from source Info.plist files and Xcode settings. Text string variables and verbatim text preserve their original semantics. Source code, build scripts and business closures are never executed.

This phase focuses on SwiftUI projects with source code. Flutter, Compose and Web source retain basic classification with agent-assisted reconstruction. Arbitrary installed applications or installation packages cannot be directly converted into equivalent editable designs. Runtime data, complex layouts, animations, materials and unsupported modifiers still require comparison with the original app. Having no unmatched components does not establish visual fidelity.

**Exports contain UI source, assets, integration configuration and the design document only. No APK, AAB, IPA or installable mobile app is generated.** Prototype interactions still need production business logic.

- Download `FrameStudio-v1.2.0-beta.10-macOS-arm64.zip`, unzip it and move the application into Applications. Requires Apple Silicon and macOS 14+. This Beta is ad-hoc signed and not notarized.
- [English user guide](https://github.com/wuxiao00j/frame-studio/blob/main/docs/USER-GUIDE.en.md) · [Agent / MCP setup and usage](https://github.com/wuxiao00j/frame-studio/blob/main/docs/MCP.en.md). The bundled MCP server provides 28 local tools.
- The project will continue to be maintained, with updates released as needed. Report feedback through Issues and follow Releases.

Release assets contain the Mac editor, source and generic examples, with no personal designs, uploaded assets or test data.
