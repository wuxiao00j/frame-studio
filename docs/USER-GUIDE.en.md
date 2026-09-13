# Frame Studio Beta user guide

## Install and save

Download the macOS-arm64 ZIP from the GitHub Beta release, unzip it, and move `原境 Frame Studio.app` into Applications. The binary requires Apple Silicon and macOS 14+. It is ad-hoc signed and not Developer ID notarized. You can also open Package.swift in Xcode or use the build script.

First launch creates a generic demo. The default document is `~/Library/Application Support/FrameStudio/Workspace.framestudio`. Changes save automatically; the project menu provides New, Open and Save As. Keep a separate copy of important designs before updating. Installing the editor does not replace design documents.

## Edit screens

1. Add pages using the left-hand plus button; use the page context menu to duplicate or delete.
2. Click or drag a component onto the phone canvas. Select it to edit properties. Select Tab / sidebar containers through **图层 / Layers** when you want to edit them without navigating.
3. Drag to move. Use the purple bottom-right handle to resize; hold Shift to preserve aspect ratio.
4. Shift-click for multi-selection. Align left, center, right, top, middle or bottom; distribute three or more components evenly. Dragging displays snapping guides.
5. Edit text, icons, colors, borders, shadows, spacing and radius in the inspector. Radius has a slider and numeric entry. Press Return after entering HEX colors.
6. ⌘Z undo, ⇧⌘Z redo, ⌘D duplicate, ⌘⌫ delete selection.

Beta.4 fixes the crash when focusing coordinate fields after selecting a component. Edit X, Y, W or H and press Return or move focus to commit; invalid sizes are rolled back and ⌘Z undoes an edit.

## Long pages and screen modes

With no layer selected, **长页面滚动 / Page scrolling** lets you enable vertical scrolling and set content height. Content beyond one screen expands the canvas automatically. Scroll with the pointer inside the phone.

Navigation and Tab bars are pinned by default; any component can be pinned or allowed to scroll. Choose Standard or Wide mode at the top. Wide mode shows inner and outer screens side by side. Both modes support portrait and landscape. Content is shared while the six layout variants store independent positions. Dimensions are editable design units, not official device specifications.

## Component properties and icons

- Switches, standalone switches, checkboxes and radio controls support leading / trailing placement and optional labels / leading icons.
- Progress supports linear, circular and stepped styles, percentage or current / total labels, thickness and colors.
- Profile rows can hide QR / chevron icons or use uploaded replacements.
- Consecutive list rows join automatically, removing internal corner radii while keeping outer corners. Auto-joining can be disabled in page properties.
- Uploaded local images are stored in the design and exported as PNG assets. System-symbol selection remains available.
- Each Tab item supports default and selected system symbols or uploaded icons, plus Move up / Move down ordering. All existing Tab bars share the complete configuration: item additions/removals, titles, destinations, icons, colors, radius, typography, spacing, visibility, locking and layout frames. Edit any Tab to update the others. Pages without a Tab are left unchanged, and newly added Tabs inherit the existing configuration. Each page still highlights its own destination.
- Clicking to add a back button places it at the top left (X=16, Y=52 below the status bar), pinned by default. You can still drag it or allow scrolling. Back buttons decomposed from a navigation bar retain their original position. Back actions use prototype page history.

When opening an older design with divergent Tabs, the first Tab in page order supplies the shared configuration. Reading alone does not rewrite the file; the next saved edit persists the unified result. The six screen variants remain independent, with each variant shared across pages.

Use **渐变与柔化 / Gradient and effects** to enable gradients, edit stop colors, choose a linear direction or radial radius, and adjust blur and shadow color/offsets. Pinned background layers stay behind content. When ViewThatFits selects different branches by width, the canvas shows only the current variant's layers.

## Create composite components

Shift-select primitive layers, click **创建组合 / Create composite** above the library, and save a name. Click the saved component later to insert another instance.

Supported profile, list, card, navigation, switch and button presets can be decomposed into primitive layers. Decomposition automatically ungroups the layers and preserves their positions and sizes. Click individual layers to edit them, then Shift-select and use **组合选中 / Group selection** or ⌘G to regroup. Use **解除组合 / Ungroup** or ⇧⌘G to separate them again. These actions also appear in the context menu. Save a named template when you want to reuse a composite. Custom code components can provide separate SwiftUI, Compose and Flutter expressions; the editor does not execute this code.

## Import existing UI

**导入旧 UI 项目 / Import existing UI** accepts a source file or directory. For SwiftUI, select the directory containing the Views, theme and assets so reusable components can resolve across files. After analysis, save a new `.framestudio` document. The current design is preserved and shared Tabs from different projects stay separate.

SwiftUI import reads View declarations. Stores, property wrappers, models and event handlers do not become pages. Source-defined components are expanded where supported; common VStack / HStack / ZStack layouts, padding, frames, fonts, colors, radii, linear/radial gradients and blur retain their scopes. Tab destinations and sheets become pages; other reusable components go into the library. Flutter, Compose and JSX / HTML retain basic classification.

The report separates component/reuse mappings, unmatched Views, reconstruction limitations and general notes. **Zero unmatched Views does not mean exact visual fidelity.** Dynamic text, authentication state, server data, computed themes, custom layouts, system materials and unsupported modifiers may still need agent-assisted reconstruction against source or a running reference. Lists can use a single sample or a declared default order. Unknown colors and images use explicit neutral placeholders.

Import never runs or modifies original code or reads the original app's authentication data. Compare against the intended theme and state, then address the reconstruction report.

## Hand UI source to developers

Choose **导出代码 / Export code**, select SwiftUI, Android Compose or Flutter, and choose a directory. Each export creates a new folder.

Exports contain source pages, assets, project configuration, `Design.framestudio`, `UI_HANDOFF.md` and `export-manifest.json`. **No mobile installation package is produced.** Scaffolds help integration; prototype interactions are not production features. Developers must implement real state, services, authentication, payments, persistence, error handling and distribution.

Integrate SwiftUI using the local package or source files, Compose using Kotlin pages and assets, or Flutter using Dart files and assets. Read the handoff and platform-difference notes first.

[Agent / MCP installation and usage](MCP.en.md) · [中文](USER-GUIDE.zh-CN.md)


## Clipping, text, images and materials

Beta.7 retains nested rectangle, rounded-rectangle, circle / ellipse and capsule masks separately for each orientation. Masks move and scale with decomposed layers. Select a layer and use “导入的容器裁剪” to remove its retained masks; Undo restores them. Arbitrary custom Paths, gradient alpha masks and group compositing still need manual reconstruction.

Text layers now expose line limits, line spacing and minimum font scale in “文字排版”. Image layers offer fill, fit and stretch in “图片显示”. Import expands supported Text / View extension modifier chains, retains these rules, and fixes conditional theme paints and multiline Chinese text measurement.

“背景材质” within “渐变与柔化” offers five frosted-material levels. Mac previews and SwiftUI exports use system Material; Flutter uses backdrop blur; Android Compose uses a translucent fill, disclosed in the export report. These do not reproduce full system Liquid Glass refraction or interactive animations, and static PNGs cannot fully capture live materials. System text-size preferences, unspecified runtime states and complex layouts still require target-device comparison.


The layer list supports selecting individual group members, Shift multi-selection and text summaries without ungrouping.


## Beta.8 forms and options

This update improves SwiftUI form import: it expands allCases, raw values and static labels from enums without associated values, reads State(initialValue:) defaults, and resolves common Boolean combinations and nil fallbacks. This fixes variable names shown as options, lost initial selection and incorrectly included conditional hints.

Common Form / Section groups retain cards, headings, insets and row separators. Navigation titles and leading/trailing toolbar buttons become editable layers. Vertical text fields become multiline inputs. Added mobile form-row styling, initial selection and enabled-state properties; date values can come from agent-supplied runtime references. A simple dismiss() becomes prototype back navigation; save handlers and other business logic are neither executed nor implemented.

Added properties work in Mac previews, SwiftUI, Compose and Flutter source exports, and MCP. Complex custom forms, unspecified dates or runtime states, platform font metrics and system glass effects still require visual comparison.


## Beta.9 categories and cross-project reuse

This update improves component reuse with seven generic bundled composites: mobile form text, date and choice rows, multiline notes, paired reminder options, grouped cards and modal navigation. They are available across projects and contain generic example content, not personal project data.

The library groups bundled, personal and project templates by category and searches names and categories. When saving a composite, enter a category and optionally save it to the personal library for reuse in other projects. Existing project templates can be copied to the personal library or recategorized through their context menu. Saving the same template again updates its personal copy.

The local personal library retains all six layouts, icons, gradients, masks and form attributes. Insertion creates independent layers and clears links to pages absent from the destination project. Library writes use revision checks and atomic saves. MCP provides 28 tools with added category and bundled-template metadata. Legacy templates without a category display a suggested category. Exports remain UI source only.

`~/Library/Application Support/FrameStudio/PersonalComponents.framestudio`


Layer controls now include Bring Forward / Send Backward for single or multiple selections, preserving selected-layer order and supporting undo. Boundary actions are disabled. Pinned backgrounds, scrolling content and pinned foregrounds remain in their own drawing planes. Shortcuts are Command-] / Command-[.

Merge Components (Command-G) shows one outer selection frame and one lower-right resize handle. Move the group or resize its layout bounds; Shift preserves the aspect ratio. The inspector offers group coordinates, dimensions and alignment. Select members in the layer list to edit text, icons and colors, or Split Group (Shift-Command-G) to edit independently. A group with locked members cannot be transformed as a whole. Copying or saving a complete group retains members from other layout variants.
