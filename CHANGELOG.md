# Changelog / 更新日志

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
