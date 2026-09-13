# 原境 · Frame Studio v1.2.0-beta.9

## 中文 · Beta 测试版

公开 Beta 更新（包含之前版本功能）：原生 SwiftUI Mac UI 设计器，支持 43 种组件、长页面、标准 / 阔屏布局、图标上传、Tab 双态图标、自定义组合，以及旧 UI 源码分类导入。

图层新增“上一层 / 下一层”，可多选，保留选中图层之间的顺序；支持撤销，边界按钮自动置灰。固定背景、滚动内容和固定前景各自在所属区域内排序。快捷键为 ⌘] / ⌘[。

“合并组件”（⌘G）后只显示一个整体外框和一个右下角手柄。可整体移动、调整当前布局的宽高，Shift 保持比例；右侧提供整体坐标、尺寸与对齐。文字、图标、颜色等仍可在图层列表选成员编辑。“拆分组合”（⇧⌘G）恢复独立编辑。含锁定成员的整组不能整体变换。复制和保存完整组合会保留其他布局的成员。

本次完善组件复用：新增 7 个通用内置组合，涵盖手机表单文本行、日期行、选择行、多行备注、提醒双选项、分组卡片和弹窗导航。它们使用通用示例内容，可在所有项目中插入，不包含个人项目数据。

组件库按分类展示内置组合、个人组件和项目组件，支持搜索名称与分类。保存组合时可填写分类，并勾选保存到个人组件库；以后新建或打开其他项目即可复用。已有项目模板可右键保存到个人库或更改分类。相同模板再次保存到个人库会更新其副本。

个人库保存在本机，保留六套布局、图标、渐变、裁剪和表单属性；插入时生成独立图层，并清理目标项目中不存在的页面链接。库写入有版本冲突检查与原子保存。MCP 共 28 个工具，新增分类和内置模板元数据。旧模板没有分类字段时自动显示建议分类。导出仍只生成 UI 源码。

**导出只包含 UI 源码、资源、项目配置和设计文件，不生成 APK、AAB、IPA 或可安装手机 App。** 原型导航、开关和表单不代表业务功能已完成，后续仍需开发真实业务逻辑。

- 下载 `FrameStudio-v1.2.0-beta.9-macOS-arm64.zip`，解压并将应用放到“应用程序”。
- 需要 Apple Silicon 与 macOS 14+；Beta 使用临时签名，尚未公证。
- Agent 可使用内置的 28 个本地 MCP 工具，安装与配置见 [中文 MCP 指南](https://github.com/wuxiao00j/frame-studio/blob/main/docs/MCP.zh-CN.md)。
- [中文使用指南](https://github.com/wuxiao00j/frame-studio/blob/main/docs/USER-GUIDE.zh-CN.md)。
- 项目将持续维护，不定期更新组件、导入 / 导出和 MCP。欢迎在 Issues 反馈问题、提出组件需求，关注 Releases 获取更新。

安装包中的 `.app` 是 Mac 设计编辑器，不是导出的手机 App。个人设计、上传图片、测试数据和手机安装包不包含在发布资源中。

## English · Beta preview

An update to the public Beta of a native SwiftUI Mac UI designer, with 43 components, long pages, standard / wide layouts, uploaded icons, two-state Tab icons, reusable composites and source-based UI import classification.

Layer controls now include Bring Forward / Send Backward for single or multiple selections, preserving selected-layer order and supporting undo. Boundary actions are disabled. Pinned backgrounds, scrolling content and pinned foregrounds remain in their own drawing planes. Shortcuts are Command-] / Command-[.

Merge Components (Command-G) shows one outer selection frame and one lower-right resize handle. Move the group or resize its layout bounds; Shift preserves the aspect ratio. The inspector offers group coordinates, dimensions and alignment. Select members in the layer list to edit text, icons and colors, or Split Group (Shift-Command-G) to edit independently. A group with locked members cannot be transformed as a whole. Copying or saving a complete group retains members from other layout variants.

This update improves component reuse with seven generic bundled composites: mobile form text, date and choice rows, multiline notes, paired reminder options, grouped cards and modal navigation. They are available across projects and contain generic example content, not personal project data.

The library groups bundled, personal and project templates by category and searches names and categories. When saving a composite, enter a category and optionally save it to the personal library for reuse in other projects. Existing project templates can be copied to the personal library or recategorized through their context menu. Saving the same template again updates its personal copy.

The local personal library retains all six layouts, icons, gradients, masks and form attributes. Insertion creates independent layers and clears links to pages absent from the destination project. Library writes use revision checks and atomic saves. MCP provides 28 tools with added category and bundled-template metadata. Legacy templates without a category display a suggested category. Exports remain UI source only.

**Exports contain UI source, assets, project configuration and design files only. They do not produce APK, AAB, IPA or installable mobile applications.** Prototype navigation, switches and forms are not completed business features. Production application logic remains development work.

- Download `FrameStudio-v1.2.0-beta.9-macOS-arm64.zip`, unzip it and move the application into Applications.
- Requires Apple Silicon and macOS 14+. The Beta is ad-hoc signed and not notarized.
- Agents can use the 28 bundled local MCP tools. See the [English MCP guide](https://github.com/wuxiao00j/frame-studio/blob/main/docs/MCP.en.md).
- [English user guide](https://github.com/wuxiao00j/frame-studio/blob/main/docs/USER-GUIDE.en.md).
- The project will continue to be maintained, with component, import/export and MCP updates released as needed. Report issues and component requests through Issues, and follow Releases for updates.

The packaged `.app` is the Mac design editor, not an exported mobile app. Release assets do not include personal designs, uploaded images, local test data or mobile installation packages.
