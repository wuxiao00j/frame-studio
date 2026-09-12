import Foundation

enum FlutterExporter {
    static func write(_ p:DesignProject,to root:URL)throws {
        try DesignExporter.copyTemplate("Flutter",to:root)
        try DesignExporter.writeText(try String(contentsOf:DesignExporter.resources.appendingPathComponent("flutter_runtime.dart"),encoding:.utf8),at:root,path:"lib/design_runtime.dart")
        try DesignExporter.writeAssets(p,at:root,path:"assets")
        try DesignExporter.writeText("""
        name: designed_app
        description: Native Flutter UI exported by Frame Studio.
        publish_to: 'none'
        version: 1.0.0+1
        environment:
          sdk: '>=3.8.0 <4.0.0'
        dependencies:
          flutter:
            sdk: flutter
        dev_dependencies:
          flutter_test:
            sdk: flutter
        flutter:
          uses-material-design: true
          assets:
            - assets/
        """,at:root,path:"pubspec.yaml")
        for page in p.pages {
            let nodes=page.nodes.filter{!$0.hidden}
            let json=try JSONSerialization.data(withJSONObject:nodes.map{try DesignExporter.data($0,device:p.device,page:page)},options:[.prettyPrinted,.sortedKeys,.withoutEscapingSlashes])
            let specs=String(data:json,encoding:.utf8)!.replacingOccurrences(of:"$",with:"\\$")
            let custom=nodes.filter{$0.kind == .custom && !($0.flutterCode ?? "").trimmingCharacters(in:.whitespacesAndNewlines).isEmpty}.map{"\(DesignExporter.literal($0.id)): (context) => \($0.flutterCode!),"}.joined(separator:"\n")
            let name=DesignExporter.pageName(page)
            let source="""
            import 'package:flutter/material.dart';
            import '../design_runtime.dart';
            // \(page.name.replacingOccurrences(of:"\n",with:" ").replacingOccurrences(of:"\r",with:" "))
            class \(name) extends StatelessWidget {
              final int variant;
              final ValueChanged<String> navigate;
              final VoidCallback openSidebar;
              const \(name)({super.key, required this.variant, required this.navigate, required this.openSidebar});
              @override
              Widget build(BuildContext context) => DesignCanvas(
                pageID: \(DesignExporter.literal(page.id)), variant: variant,
                background: designColor(\(DesignExporter.literal(page.background))),
                navigate: navigate, openSidebar: openSidebar,
                scrollable: \(page.isScrollable), heights: [\(Variant.allCases.map{SwiftExporter.number(page.contentHeight($0,device:p.device))}.joined(separator:", "))],
                customBuilders: {\(custom)},
                specs: \(specs),
              );
            }
            """
            try DesignExporter.writeText(source,at:root,path:"lib/pages/\(name.lowercased()).dart")
        }
        let imports=p.pages.map{"import 'pages/\(DesignExporter.pageName($0).lowercased()).dart';"}.joined(separator:"\n")
        let cases=p.pages.map{"case \(DesignExporter.literal($0.id)): return \(DesignExporter.pageName($0))(variant: variant, navigate: go, openSidebar: () => setState(() => sidebar = !sidebar));"}.joined(separator:"\n")
        let routes=p.pages.map{"ListTile(title: Text(\(DesignExporter.literal($0.name))), leading: const Icon(Icons.description_outlined), selected: selected == \(DesignExporter.literal($0.id)), onTap: () => go(\(DesignExporter.literal($0.id)))),"}.joined(separator:"\n")
        try DesignExporter.writeText("""
        import 'package:flutter/material.dart';
        \(imports)
        void main() => runApp(const DesignedApp());
        class DesignedApp extends StatelessWidget {
          const DesignedApp({super.key});
          @override
          Widget build(BuildContext context) => MaterialApp(debugShowCheckedModeBanner: false, title: \(DesignExporter.literal(p.name)), theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF7560D4)), home: const DesignedHome());
        }
        class DesignedHome extends StatefulWidget {
          const DesignedHome({super.key});
          @override
          State<DesignedHome> createState() => _DesignedHomeState();
        }
        class _DesignedHomeState extends State<DesignedHome> {
          String selected = \(DesignExporter.literal(p.pages[0].id));
          bool sidebar = false;
          final List<String> history = [];
          void go(String page) { if (page.isEmpty) return; setState(() { if (page == "__back") { if (history.isNotEmpty) selected = history.removeLast(); } else if (page != selected) { history.add(selected); selected = page; } sidebar = false; }); }
          Widget page(int variant) { switch(selected) {
            \(cases)
            default: return \(DesignExporter.pageName(p.pages[0]))(variant: variant, navigate: go, openSidebar: () => setState(() => sidebar = !sidebar));
          } }
          @override
          Widget build(BuildContext context) => Scaffold(resizeToAvoidBottomInset: false, body: LayoutBuilder(builder: (context, bounds) {
            final landscape = bounds.maxWidth > bounds.maxHeight;
            final variant = \(p.wideMode ? "((bounds.biggest.shortestSide < \(SwiftExporter.number((p.device.outer.width+p.device.inner.width)/2))) ? 2 : 4) + (landscape ? 1 : 0)" : "landscape ? 1 : 0");
            return Stack(children: [Positioned.fill(child: page(variant)), if(sidebar) ...[
              Positioned.fill(child: GestureDetector(onTap: () => setState(() => sidebar = false), child: Container(color: Colors.black26))),
              Positioned(top: 0, bottom: 0, left: 0, width: (bounds.maxWidth * 0.8).clamp(0.0, 280.0), child: Material(color: Colors.white, child: SafeArea(child: ListView(children: [
                ListTile(title: const Text('工作空间'), trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => sidebar = false))), \(routes)
              ])))),
            ]]);
          }));
        }
        """,at:root,path:"lib/main.dart")
        try DesignExporter.writeText("""
        # \(p.name) · Flutter 导出

        UI 源码工程：lib/main.dart、每页 Dart 文件、Widget 组件、assets 以及用于后续集成的 Android / iOS 项目配置。
        UI source scaffold: Dart pages, widgets, assets and platform configuration for integration. No APK, AAB or IPA is generated. Production features still need implementation.
        已使用 Flutter 3.38.9 模板生成，Dart >= 3.8；没有第三方运行时依赖。

        ```sh
        flutter pub get
        flutter analyze
        ```

        Android Studio / VS Code 可打开此目录继续开发。先接入业务状态、服务、真实导航和异常处理，再在你自己的开发流程中完成测试、签名与发布。
        Open this directory in Android Studio or VS Code. Implement production state, services, navigation and error handling before your own testing, signing and distribution workflow.
        系统图标已映射为 Material Icons；图片作为真实 PNG 文件输出。
        自定义 Flutter View 表达式来自 flutterCode 字段，未提供时输出 TODO 占位；详见 EXPORT_REPORT.md。
        """,at:root,path:"README.md")
        try FileManager.default.setAttributes([.posixPermissions:0o755],ofItemAtPath:root.appendingPathComponent("android/gradlew").path)
    }
}
