# Changelog / 更新日志

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
