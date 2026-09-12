import SwiftUI
import StudioCore

@main @MainActor struct FrameStudioApp:App {
    @State private var session=EditorSession()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body:some Scene {
        WindowGroup("原境 · Frame Studio") {EditorRoot(session:session).frame(minWidth:1180,minHeight:740).preferredColorScheme(.light)}
            .defaultSize(width:1440,height:930)
            .windowStyle(.hiddenTitleBar)
            .commands{
                CommandGroup(replacing:.newItem){Button("新建设计项目",action:session.newProject).keyboardShortcut("n");Button("打开设计项目…",action:session.openProject).keyboardShortcut("o");Button("导入旧 UI 项目…",action:session.importSwift)}
                CommandGroup(replacing:.saveItem){Button("保存项目"){session.status="已自动保存到 \(session.url.lastPathComponent)"}.keyboardShortcut("s");Button("另存为…",action:session.saveAs).keyboardShortcut("s",modifiers:[.command,.shift]);Menu("导出页面工程"){ForEach(ExportFormat.allCases){format in Button(format.detail){session.performExport(format)}}};Button("再次导出 \(session.exportFormat.title)…",action:session.export).keyboardShortcut("e",modifiers:[.command,.shift])}
                CommandGroup(replacing:.undoRedo){Button("撤销",action:session.undo).keyboardShortcut("z").disabled(!session.canUndo);Button("重做",action:session.redo).keyboardShortcut("z",modifiers:[.command,.shift]).disabled(!session.canRedo)}
                CommandMenu("设计"){Button("复制组件",action:session.duplicate).keyboardShortcut("d").disabled(session.selection.isEmpty);Button("删除组件",action:session.deleteSelection).keyboardShortcut(.delete,modifiers:[.command]).disabled(session.selection.isEmpty);Button("组合",action:session.group).keyboardShortcut("g").disabled(session.selection.count<2);Button("取消组合",action:session.ungroup).keyboardShortcut("g",modifiers:[.command,.shift]);Button("切换横竖屏",action:session.rotate).keyboardShortcut("r",modifiers:[.command,.shift]);Button("预览交互"){session.preview.toggle()}.keyboardShortcut("p",modifiers:[.command,.shift])}
            }
    }
}
final class AppDelegate:NSObject,NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification:Notification){NSApp.setActivationPolicy(.regular);NSApp.activate(ignoringOtherApps:true)}
    func application(_ sender:NSApplication, openFiles filenames:[String]) {
        if let path=filenames.first { NotificationCenter.default.post(name:Notification.Name("OpenFrameStudioProject"),object:path) };sender.reply(toOpenOrPrint:.success)
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender:NSApplication)->Bool{true}
}
@MainActor struct EditorRoot:View {
    @Bindable var session:EditorSession
    var body:some View {
        VStack(spacing:0){EditorToolbar(session:session);Divider();HStack(spacing:0){LibrarySidebar(session:session);Divider();CanvasWorkspace(session:session);Divider();InspectorView(session:session)}}
            .overlay(alignment:.topLeading) {if let kind=session.paletteKind {Label(kind.title,systemImage:kind.symbol).font(.system(size:12)).padding(12).background(.white,in:RoundedRectangle(cornerRadius:10)).shadow(radius:8).position(session.paletteLocation).allowsHitTesting(false)}}
            .onReceive(NotificationCenter.default.publisher(for:Notification.Name("OpenFrameStudioProject"))) { note in
                if let path=note.object as? String {do {let url=URL(fileURLWithPath:path);session.adopt(try ProjectStore.load(url),url:url)}catch{session.error=error.localizedDescription}}
            }
            .tint(studioAccent)
            .foregroundStyle(studioInk)
            .background(.white)
            .task{while !Task.isCancelled{try? await Task.sleep(for:.seconds(1));session.refresh()}}
            .sheet(isPresented:$session.showTemplateComposer){TemplateComposer(session:session)}
            .sheet(isPresented:$session.showDevices){DeviceSettings(session:session)}
            .sheet(isPresented:$session.showMCP){MCPInfo(session:session)}
            .sheet(isPresented:$session.showImportReport){ImportReportView(session:session)}
            .alert("操作未完成",isPresented:Binding(get:{session.error != nil},set:{if !$0{session.error=nil}})){Button("好"){session.error=nil}}message:{Text(session.error ?? "")}
    }
}
@MainActor struct EditorToolbar:View {
    @Bindable var session:EditorSession
    var body:some View {
        HStack(spacing:14){
            Color.clear.frame(width:66)
            Menu{Button("新建项目",action:session.newProject);Button("打开项目…",action:session.openProject);Button("另存为…",action:session.saveAs);Divider();Button("导入旧 UI 项目…",action:session.importSwift)}label:{HStack(spacing:7){Image(systemName:"folder").foregroundStyle(studioMuted);Text(session.project.name).font(.system(size:12,weight:.medium))}}.menuStyle(.borderlessButton).fixedSize()
            Divider().frame(height:18)
            Button(action:session.undo){Image(systemName:"arrow.uturn.backward")}.disabled(!session.canUndo).help("撤销 ⌘Z")
            Button(action:session.redo){Image(systemName:"arrow.uturn.forward")}.disabled(!session.canRedo).help("重做 ⇧⌘Z")
            Spacer(minLength:8)
            Picker("屏幕形态",selection:Binding(get:{session.project.wideMode},set:{session.setWide($0)})){Text("标准屏").tag(false);Text("阔屏").tag(true)}.pickerStyle(.segmented).labelsHidden().frame(width:140)
            Button(action:session.rotate){Image(systemName:"rotate.right")}.help("切换横竖屏")
            Button{session.showDevices=true}label:{Image(systemName:"slider.horizontal.3")}.help("画布尺寸")
            Divider().frame(height:18)
            Button{session.showGrid.toggle()}label:{Image(systemName:"circle.grid.3x3.fill").foregroundStyle(session.showGrid ? studioAccent : studioMuted)}.help("显示网格")
            Button{session.snapping.toggle()}label:{Image(systemName:"align.horizontal.center").foregroundStyle(session.snapping ? studioAccent : studioMuted)}.help("智能对齐吸附")
            Menu{ForEach([0.4,0.5,0.65,0.75,1.0,1.25,1.5],id:\.self){v in Button("\(Int(v*100))%"){session.zoom=v}}}label:{Text("\(Int(session.zoom*100))%").font(.system(size:11)).monospacedDigit()}.menuStyle(.borderlessButton).frame(width:58)
            Spacer(minLength:8)
            Button{session.preview.toggle()}label:{Label(session.preview ? "返回编辑" : "预览",systemImage:session.preview ? "pencil" : "play")}.font(.system(size:11)).padding(.horizontal,12).padding(.vertical,8).background(Color(hex:"F4F1F9"),in:RoundedRectangle(cornerRadius:7))
            Menu{ForEach(ExportFormat.allCases){format in Button(format.detail){session.performExport(format)}}}label:{Label("导出代码",systemImage:"square.and.arrow.up").font(.system(size:11,weight:.semibold)).foregroundStyle(.white).padding(.horizontal,15).padding(.vertical,9).background(studioAccent,in:RoundedRectangle(cornerRadius:7))}.menuStyle(.borderlessButton).fixedSize()
        }.buttonStyle(.plain).padding(.trailing,20).frame(height:64)
    }
}
@MainActor struct DeviceSettings:View {
    @Bindable var session:EditorSession
    @Environment(\.dismiss) var dismiss
    @State private var device=DeviceProfile()
    var body:some View {
        VStack(alignment:.leading,spacing:20){HStack{Text("画布尺寸").font(.title2.bold());Spacer();Text("逻辑尺寸 · pt").font(.caption).foregroundStyle(studioMuted)}
            Text("统一使用标准屏和阔屏两种形态。横屏自动交换宽高，内外屏布局各自保存。").font(.system(size:12)).foregroundStyle(studioMuted)
            dimensionRow("标准屏",width:$device.standard.width,height:$device.standard.height)
            dimensionRow("阔屏 · 外屏",width:$device.outer.width,height:$device.outer.height)
            dimensionRow("阔屏 · 内屏",width:$device.inner.width,height:$device.inner.height)
            Text("阔屏默认约 1 : 1.4。这里是可调整的设计尺寸，不是特定机型的硬件像素或官方 pt。\n修改基础尺寸后，已独立编辑的画布坐标会保留。").font(.system(size:11)).lineSpacing(5).foregroundStyle(studioMuted)
            HStack{Button("恢复默认"){device=DeviceProfile()};Spacer();Button("取消"){dismiss()};Button("应用"){session.change{$0.device=device};dismiss()}.keyboardShortcut(.defaultAction)}
        }.padding(28).frame(width:480).onAppear{device=session.project.device}
    }
    func dimensionRow(_ name:String,width:Binding<Double>,height:Binding<Double>)->some View {HStack{Text(name).font(.system(size:12)).frame(width:95,alignment:.leading);NumberField(label:"宽",value:width);Text("×").foregroundStyle(studioMuted);NumberField(label:"高",value:height)}}
}
@MainActor struct MCPInfo:View {
    @Bindable var session:EditorSession
    @Environment(\.dismiss) var dismiss
    var executable:String {Bundle.main.bundleURL.appendingPathComponent("Contents/MacOS/frame-studio-mcp").path}
    var config:String {"[mcp_servers.frame_studio]\ncommand = \(quoted(executable))\nargs = [\"--project\", \(quoted(session.url.path))]"}
    func quoted(_ s:String)->String {String(data:try! JSONEncoder().encode(s),encoding:.utf8)!}
    var body:some View {VStack(alignment:.leading,spacing:18){HStack{Label("Agent 连接",systemImage:"point.3.connected.trianglepath.dotted").font(.title2.bold());Spacer();Button("完成"){dismiss()}.keyboardShortcut(.defaultAction)};Text("通过本地 MCP 操作当前设计项目。Agent 可以读取页面、增删组件、调整属性、导入旧项目、对齐布局并导出 SwiftUI、Android 或 Flutter 文件。").font(.system(size:12)).lineSpacing(5);Text("当前项目").font(.caption).foregroundStyle(studioMuted);Text(session.url.path).font(.system(size:10,design:.monospaced)).textSelection(.enabled);Text("Codex MCP 配置").font(.caption).foregroundStyle(studioMuted);Text(config).font(.system(size:10,design:.monospaced)).textSelection(.enabled).padding(14).frame(maxWidth:.infinity,alignment:.leading).background(Color(hex:"F4F1F9"),in:RoundedRectangle(cornerRadius:8));HStack{Button("复制连接配置"){NSPasteboard.general.clearContents();NSPasteboard.general.setString(config,forType:.string)};Button("显示项目文件"){NSWorkspace.shared.activateFileViewerSelecting([session.url])}};Text("连接配置仅用于设置 Agent。页面导出始终直接生成文件。应用每秒同步磁盘更改，发生版本冲突时会保留已有文件。").font(.system(size:10)).foregroundStyle(studioMuted).lineSpacing(4)}.padding(28).frame(width:600)}
}
@MainActor struct ImportReportView:View {
    let session:EditorSession
    @Environment(\.dismiss) var dismiss
    @State private var category=0
    var lines:[String] {session.project.importNotes.filter{note in switch category {case 0:return note.hasPrefix("分类：");case 1:return note.hasPrefix("未匹配预设：");default:return !note.hasPrefix("分类：") && !note.hasPrefix("未匹配预设：")}}}
    var body:some View {
        VStack(alignment:.leading,spacing:16) {
            HStack{Text("旧 UI 项目 · 组件分类").font(.title2.bold());Spacer();Button("完成"){dismiss()}.keyboardShortcut(.defaultAction)}
            Text("已识别控件对应现有预设；未匹配控件保留名称和源码位置，可继续补充预设。布局为可编辑草稿。").font(.system(size:12)).foregroundStyle(studioMuted)
            Picker("报告分类",selection:$category){Text("组件分类").tag(0);Text("未匹配预设").tag(1);Text("导入说明").tag(2)}.pickerStyle(.segmented).labelsHidden()
            ScrollView{VStack(alignment:.leading,spacing:12){if lines.isEmpty{Text(category==1 ? "没有未匹配的控件。":"当前没有此类记录。").foregroundStyle(studioMuted).padding(.top,24)};ForEach(Array(lines.enumerated()),id:\.offset){_,note in Text(note).font(.system(size:12)).textSelection(.enabled).frame(maxWidth:.infinity,alignment:.leading).padding(12).background(Color(hex:"F7F5FB"),in:RoundedRectangle(cornerRadius:8))}}}
        }.padding(24).frame(width:700,height:500).tint(studioAccent)
    }
}
