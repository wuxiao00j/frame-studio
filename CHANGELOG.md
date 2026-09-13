# Changelog / 更新日志

## 1.2.0-beta.9 — 2026-09-13

本次完善组件复用：新增 7 个通用内置组合，涵盖手机表单文本行、日期行、选择行、多行备注、提醒双选项、分组卡片和弹窗导航。它们使用通用示例内容，可在所有项目中插入，不包含个人项目数据。

组件库按分类展示内置组合、个人组件和项目组件，支持搜索名称与分类。保存组合时可填写分类，并勾选保存到个人组件库；以后新建或打开其他项目即可复用。已有项目模板可右键保存到个人库或更改分类。相同模板再次保存到个人库会更新其副本。

个人库保存在本机，保留六套布局、图标、渐变、裁剪和表单属性；插入时生成独立图层，并清理目标项目中不存在的页面链接。库写入有版本冲突检查与原子保存。MCP 保持 27 个工具，新增分类和内置模板元数据。旧模板没有分类字段时自动显示建议分类。导出仍只生成 UI 源码。

This update improves component reuse with seven generic bundled composites: mobile form text, date and choice rows, multiline notes, paired reminder options, grouped cards and modal navigation. They are available across projects and contain generic example content, not personal project data.

The library groups bundled, personal and project templates by category and searches names and categories. When saving a composite, enter a category and optionally save it to the personal library for reuse in other projects. Existing project templates can be copied to the personal library or recategorized through their context menu. Saving the same template again updates its personal copy.

The local personal library retains all six layouts, icons, gradients, masks and form attributes. Insertion creates independent layers and clears links to pages absent from the destination project. Library writes use revision checks and atomic saves. MCP retains 27 tools with added category and bundled-template metadata. Legacy templates without a category display a suggested category. Exports remain UI source only.

## 1.2.0-beta.8 — 2026-09-13

本次补齐 SwiftUI 表单导入：识别无关联值枚举的 allCases、rawValue 与静态标签，读取 State(initialValue:) 默认状态，解析常见布尔组合和空值回退。修正选项显示变量名、选中状态丢失、错误展示条件提示的问题。

Form / Section 保留常见分组卡片、标题、内边距和行分隔线；顶部导航标题与左右工具栏按钮转换成可编辑图层。多行输入按 axis 转换，新增“手机表单行”样式、默认选项与“启用交互”属性；日期值可使用 Agent 提供的运行对照值。简单 dismiss() 转换为原型返回，保存等业务处理不会执行或自动实现。

新增属性同步至 Mac 预览、SwiftUI、Compose、Flutter 源码和 MCP。复杂自定义表单、未提供的日期或运行状态、平台字体与系统玻璃效果仍需对照调整。

This update improves SwiftUI form import: it expands allCases, raw values and static labels from enums without associated values, reads State(initialValue:) defaults, and resolves common Boolean combinations and nil fallbacks. This fixes variable names shown as options, lost initial selection and incorrectly included conditional hints.

Common Form / Section groups retain cards, headings, insets and row separators. Navigation titles and leading/trailing toolbar buttons become editable layers. Vertical text fields become multiline inputs. Added mobile form-row styling, initial selection and enabled-state properties; date values can come from agent-supplied runtime references. A simple dismiss() becomes prototype back navigation; save handlers and other business logic are neither executed nor implemented.

Added properties work in Mac previews, SwiftUI, Compose and Flutter source exports, and MCP. Complex custom forms, unspecified dates or runtime states, platform font metrics and system glass effects still require visual comparison.

## 1.2.0-beta.7 — 2026-09-13

图层列表支持单独选择组合成员、Shift 多选，并显示文字摘要；不必先解除整个组合。

Beta.7 保留矩形、圆角矩形、圆形 / 椭圆和胶囊的嵌套裁剪，横竖屏独立存储。裁剪边界随拆分图层移动、缩放；选择图层后可在“导入的容器裁剪”中解除，并用撤销恢复。任意自定义 Path、渐变透明度蒙版和组合级混合效果仍需人工还原。

文字组件新增“文字排版”：限制行数、行间距和最小字号比例。图片组件新增“图片显示”：填满裁剪、完整显示或拉伸。导入器展开支持的 Text / View 扩展修饰器链，保留这些规则，并修正主题条件颜色与中文多行测量。

“渐变与柔化”的“背景材质”提供五档磨砂。Mac 预览和 SwiftUI 源码使用系统 Material，Flutter 使用背景模糊；Android Compose 使用半透明底色替代，导出报告会说明差异。它们不等同于完整的系统 Liquid Glass 折射与交互动画，静态 PNG 也不能完整反映实时材质。系统字号偏好、未提供的运行状态和复杂布局仍需对照目标设备。

The layer list supports selecting individual group members, Shift multi-selection and text summaries without ungrouping.

Beta.7 retains nested rectangle, rounded-rectangle, circle / ellipse and capsule masks separately for each orientation. Masks move and scale with decomposed layers. Select a layer and use “导入的容器裁剪” to remove its retained masks; Undo restores them. Arbitrary custom Paths, gradient alpha masks and group compositing still need manual reconstruction.

Text layers now expose line limits, line spacing and minimum font scale in “文字排版”. Image layers offer fill, fit and stretch in “图片显示”. Import expands supported Text / View extension modifier chains, retains these rules, and fixes conditional theme paints and multiline Chinese text measurement.

“背景材质” within “渐变与柔化” offers five frosted-material levels. Mac previews and SwiftUI exports use system Material; Flutter uses backdrop blur; Android Compose uses a translucent fill, disclosed in the export report. These do not reproduce full system Liquid Glass refraction or interactive animations, and static PNGs cannot fully capture live materials. System text-size preferences, unspecified runtime states and complex layouts still require target-device comparison.

## 1.2.0-beta.6 — 2026-09-13

补充 `.framestudio` 文件类型注册，并兼容旧工程文件的系统类型标记。 / Register the `.framestudio` document type and accept legacy document type metadata.

新增可编辑的线性 / 径向渐变、色标、模糊及阴影色 / 偏移，覆盖 Mac 预览与三平台源码导出。修正透明叠加层遮挡正文、多行局部变量被当成图层、卡片标题操作插槽误判、固定背景层顺序和父圆角影响子图层的问题。

SwiftUI 导入支持更多只读主题函数、命名元组 map、可伸缩横向布局、流式布局与 ViewThatFits 的分屏幕布局；Agent 可提供参考画布尺寸与顶部安全区。新增可重复运行的原生 PNG 预览命令。Android 的模糊与精细阴影在 Android 12+ 生效，较早系统保留原生阴影回退。

Added editable linear/radial gradients and stops, blur, shadow color and offsets across Mac previews and all three UI source exports. Fixed opaque overlays covering content, multiline locals becoming layers, header-action slot misclassification, pinned background order and parent radii leaking into child shapes.

SwiftUI import now resolves more read-only theme functions and named-tuple maps, allocates flexible rows, wraps flow content and preserves per-variant ViewThatFits branches. Agents can supply reference canvas dimensions and top inset. Added repeatable native PNG preview rendering. Android blur and detailed shadows apply on Android 12+; older systems retain native shadow fallback.

## 1.2.0-beta.5 — 2026-09-12

新增 Agent 导入状态与颜色参数，可根据实际运行界面选择分支、还原简单插值和主题颜色。 / Added agent-supplied import state and color parameters for branch selection, simple interpolation and verified theme colors.

SwiftUI 导入改为读取 View 声明与视图结构：排除状态、数据模型和事件处理代码；展开源码中的自定义 View、计算属性、ViewBuilder 内容与支持的 ViewModifier；保留常见横纵布局、局部样式和六套尺寸布局。Tab 目标页与复用组件分开整理，弹窗单独作为页面。界面导入默认另存为独立设计，避免混入当前项目的共用 Tab。

动态数据、分支、主题、自定义 Layout 与不支持的修饰器独立列为“待还原”，不再全部误报为缺少组件预设。该流程仍是静态、可编辑草稿，不能保证任意项目与运行画面像素一致；源码不会被运行或修改。

SwiftUI import now reads View declarations and structure, excluding state, model constructors and event handlers. It expands source-defined Views, computed view members, ViewBuilder content and supported ViewModifiers, retaining common stacks, scoped styles and six layouts. Tab destinations, modal pages and reusable templates are separated. Desktop imports save as independent designs to avoid mixing shared Tabs with the current project.

Dynamic data, branches, themes, custom Layouts and unsupported modifiers are listed as reconstruction limitations instead of missing component presets. Import remains a static editable draft, not a promise of pixel-exact runtime reconstruction. Original source is neither executed nor modified.

## 1.2.0-beta.4 — 2026-09-12

修复选择组件后点击或编辑 X / Y / W / H 输入框时的闪退。属性修改改为在独立草稿上完成再提交，避免修改项目时重叠读取同一份数据；同时修复进度样式切换与布局复制的同类访问冲突。坐标输入始终读取最新值，继续支持 Tab 同步、自动保存和撤销重做。新增 6 项编辑器层回归测试，覆盖焦点回写、六套布局、手势提交、无效值回滚和 Agent 版本冲突。

Fix a crash when focusing or editing X / Y / W / H after selecting a component. Inspector mutations now edit a local draft before committing, avoiding overlapping access to the observed project. This also fixes the same conflict in progress-style changes and layout copying. Coordinate bindings read live values while preserving shared Tabs, autosave and undo/redo. Six new editor regression tests cover focus writeback, six variants, gesture commits, invalid-value rollback and Agent revision conflicts.

## 1.2.0-beta.3 — 2026-09-12

项目内已有 Tab 栏共用全部配置：修改任意页面的项目、排序、图标、样式和对应屏幕的布局会自动同步。新 Tab 继承现有配置，旧设计读取时统一；六种布局独立，页面高亮按当前目标显示。编辑器、MCP、撤销重做和三平台源码导出使用同一规则。

返回按钮默认固定在左上角。拆分预置组件后自动解组，保留布局；可逐项编辑、Shift 多选重新组合或解组，属性面板与右键菜单提供直接入口。新增 Tab 排序按钮与回归验证。

Existing Tab bars now share their complete configuration across the project, including items, order, icons, styling and corresponding screen layouts. New Tabs inherit the configuration; legacy designs normalize on read. Six variants remain independent and each page highlights its current destination. Editor, MCP, undo/redo and all three source exporters follow the same rule.

Back buttons default to a pinned top-left position. Decomposing presets automatically ungroups their layers while preserving layout. Edit layers individually, Shift-select to regroup or ungroup, and use the inspector or context-menu actions. Added Tab reordering and regression coverage.

## 1.2.0-beta.2 — 2026-09-12

修复旧版 Xcode 构建时的 SwiftUI 主线程隔离声明和尺寸类型推断问题。UI 源码导出约定及 Beta.1 功能保持一致。

Fix explicit main-actor isolation and dimension type inference for source builds with older Xcode versions. The UI-source-only export contract and Beta.1 features are unchanged.

## 1.2.0-beta.1 — 2026-09-12

### 中文

首个公开 Beta：原生 macOS 编辑器、43 种组件、长页面与标准 / 阔屏布局、对齐和圆角调整、上传图标、Tab 双态图标、自定义组合、旧 UI 分类导入，以及 27 个 MCP 工具。

本次公开交付明确采用 UI 源码导出：只生成源码、资源、项目配置和设计文件；不生成 APK、AAB、IPA 或手机安装包。新增 `UI_HANDOFF.md`、机器可读导出清单及源码导出检查。验证流程采用测试、分析和编译检查，不进行手机打包。

新增中英双语使用指南、Agent / MCP 安装与操作指南、配置助手、持续维护说明，以及可下载的 Mac 编辑器 Beta 包。

### English

First public Beta: a native macOS editor, 43 component types, long pages and standard / wide layouts, alignment and radius editing, uploaded icons, two-state Tab icons, reusable composites, source-based UI classification, and 27 MCP tools.

Public exports are explicitly UI-source-only: source files, assets, project configuration and design documents, without APK, AAB, IPA or mobile installation packages. Added `UI_HANDOFF.md`, a machine-readable export manifest and source-only checks. Validation uses tests, analysis and compilation without mobile packaging.

Added bilingual user and Agent / MCP guides, configuration helpers, a maintenance statement and a downloadable Mac editor Beta package.
