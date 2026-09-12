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

## Long pages and screen modes

With no layer selected, **长页面滚动 / Page scrolling** lets you enable vertical scrolling and set content height. Content beyond one screen expands the canvas automatically. Scroll with the pointer inside the phone.

Navigation and Tab bars are pinned by default; any component can be pinned or allowed to scroll. Choose Standard or Wide mode at the top. Wide mode shows inner and outer screens side by side. Both modes support portrait and landscape. Content is shared while the six layout variants store independent positions. Dimensions are editable design units, not official device specifications.

## Component properties and icons

- Switches, standalone switches, checkboxes and radio controls support leading / trailing placement and optional labels / leading icons.
- Progress supports linear, circular and stepped styles, percentage or current / total labels, thickness and colors.
- Profile rows can hide QR / chevron icons or use uploaded replacements.
- Consecutive list rows join automatically, removing internal corner radii while keeping outer corners. Auto-joining can be disabled in page properties.
- Uploaded local images are stored in the design and exported as PNG assets. System-symbol selection remains available.
- Each Tab item has default and selected icons, both supporting system symbols or uploaded images. Icons synchronize to other Tab bars targeting the same page by default; synchronization can be disabled.
- Back buttons and navigation-bar back actions use prototype page history.

## Create composite components

Shift-select primitive layers, click **创建组合 / Create composite** above the library, and save a name. Click the saved component later to insert another instance.

Supported profile, list, card, navigation, switch and button presets can be decomposed into primitive layers. Ungroup them to adjust text, icons, backgrounds and controls individually, then save a new composite. Custom code components can provide separate SwiftUI, Compose and Flutter expressions; the editor does not execute this code.

## Import existing UI

**导入旧 UI 项目 / Import existing UI** accepts SwiftUI, Flutter, Compose, JSX / HTML files or directories. The report separates preset matches, unmatched components and import notes.

Static recognition produces an editable draft. Complex dynamic layouts, state and navigation still require a developer or agent to inspect the source. Unmatched controls retain their names and source locations as explicit placeholders. Use the report to request additional presets.

## Hand UI source to developers

Choose **导出代码 / Export code**, select SwiftUI, Android Compose or Flutter, and choose a directory. Each export creates a new folder.

Exports contain source pages, assets, project configuration, `Design.framestudio`, `UI_HANDOFF.md` and `export-manifest.json`. **No mobile installation package is produced.** Scaffolds help integration; prototype interactions are not production features. Developers must implement real state, services, authentication, payments, persistence, error handling and distribution.

Integrate SwiftUI using the local package or source files, Compose using Kotlin pages and assets, or Flutter using Dart files and assets. Read the handoff and platform-difference notes first.

[Agent / MCP installation and usage](MCP.en.md) · [中文](USER-GUIDE.zh-CN.md)
