import SwiftUI
import AppKit
import Observation
import UniformTypeIdentifiers
import StudioCore

@MainActor @Observable final class EditorSession {
    var project: DesignProject
    var url: URL
    var pageID: String
    var selection: Set<String> = []
    var variant: Variant = .standardPortrait
    var landscape=false
    var zoom: Double=0.75
    var canvasViewportWidth:Double=920
    var showGrid=true
    var snapping=true
    var preview=false
    var sidebarOpen=false
    var libraryTab=0
    var search=""
    var status="所有更改已保存"
    var error: String?
    var showDevices=false
    var showMCP=false
    var showTemplateComposer=false
    var templateName=""
    var templateCategory="其他组合"
    var saveTemplatePersonally=true
    var personalLibrary:DesignProject?
    let personalLibraryURL:URL
    var pageHistory:[String]=[]
    var propertyGesture=false
    @ObservationIgnored var scrollOffsets:[Variant:CGFloat]=[:]
    var exportFormat:ExportFormat = .swiftui
    var isResizing=false
    var showImportReport=false
    var undoStack:[DesignProject]=[]
    var redoStack:[DesignProject]=[]
    var guideX: Double?
    var guideY: Double?
    @ObservationIgnored var boardFrames:[Variant:CGRect]=[:]
    var paletteKind:ComponentKind?
    var paletteLocation=CGPoint.zero
    var dragging=false
    var dragFrames:[String:Rect]=[:]
    var dragSnapshot:DesignProject?
    var revisionOnDisk:Int
    var canUndo:Bool { !undoStack.isEmpty }
    var canRedo:Bool { !redoStack.isEmpty }
    var page:DesignPage { project.pages.first{$0.id==pageID} ?? project.pages[0] }
    var selected:DesignNode? { page.nodes.first{selection.contains($0.id)} }
    var visibleVariants:[Variant] { project.wideMode ? (landscape ? [.outerLandscape,.innerLandscape] : [.outerPortrait,.innerPortrait]) : (landscape ? [.standardLandscape] : [.standardPortrait]) }
    init(projectURL:URL?=nil,libraryURL:URL?=nil) {
        let args=CommandLine.arguments
        let arg=args.firstIndex(of:"--project").flatMap{$0+1<args.count ? args[$0+1] : nil}
        var fileURL=projectURL ?? arg.map{URL(fileURLWithPath:$0)} ?? ProjectStore.defaultURL
        var initialError:String?
        var p:DesignProject
        do {
            if FileManager.default.fileExists(atPath:fileURL.path) { p=try ProjectStore.load(fileURL) }
            else { p=try ProjectStore.save(.demo(),to:fileURL,expectedRevision:nil) }
        } catch { p = .demo(); initialError=error.localizedDescription; fileURL=ProjectStore.defaultURL.deletingLastPathComponent().appendingPathComponent("Recovered-\(UUID().uuidString.prefix(6)).framestudio") }
        url=fileURL; project=p; pageID=p.pages[0].id; revisionOnDisk=p.revision; error=initialError
        variant=p.wideMode ? .outerPortrait : .standardPortrait
        personalLibraryURL=libraryURL ?? (projectURL.map{$0.deletingLastPathComponent().appendingPathComponent("PersonalComponents.framestudio")} ?? PersonalComponentLibrary.defaultURL)
        personalLibrary=try? PersonalComponentLibrary.load(personalLibraryURL)
    }
    func change(_ body:(inout DesignProject)->Void) {
        let before=project
        // Inspector bindings may read session.project while editing a node. Mutate a local
        // draft so the callback never overlaps an exclusive write to the observed property.
        var draft=before
        body(&draft)
        SharedTabBar.reconcile(&draft,before:before)
        guard before != draft else { return }
        if propertyGesture{project=draft;return}
        do {
            project=try ProjectStore.save(draft,to:url,expectedRevision:revisionOnDisk); revisionOnDisk=project.revision
            undoStack.append(before); if undoStack.count>80 {undoStack.removeFirst()}; redoStack=[]; status="已自动保存"
        } catch { project=before; self.error=error.localizedDescription; refresh() }
    }
    func refresh() {
        guard !dragging else {return}
        do { let fresh=try ProjectStore.load(url); if fresh.revision != revisionOnDisk {project=fresh; revisionOnDisk=fresh.revision; undoStack=[]; redoStack=[]; selection=[]; if !fresh.pages.contains(where:{$0.id==pageID}) {pageID=fresh.pages[0].id}; variant=visibleVariants.contains(variant) ? variant : visibleVariants[0]; status="已同步 Agent 的更改"} } catch { status="读取失败：\(error.localizedDescription)" }
    }
    func persistHistory(_ target:DesignProject) {
        var p=target; p.revision=revisionOnDisk
        do {project=try ProjectStore.save(p,to:url,expectedRevision:revisionOnDisk);revisionOnDisk=project.revision;selection=[];status="已保存"} catch {self.error=error.localizedDescription;refresh()}
    }
    func undo() {guard let p=undoStack.popLast() else{return};redoStack.append(project);persistHistory(p)}
    func redo() {guard let p=redoStack.popLast() else{return};undoStack.append(project);persistHistory(p)}
    func selectPage(_ id:String) {
        if id=="__back" {if let previous=pageHistory.popLast(){pageID=previous;selection=[];sidebarOpen=false};return}
        guard project.pages.contains(where:{$0.id==id}) else{return}
        if pageID != id{pageHistory.append(pageID)}
        pageID=id;selection=[];sidebarOpen=false;scrollOffsets=[:]
    }
    func select(_ node:DesignNode,additive:Bool=false,includingGroup:Bool=true) {
        if additive {if selection.contains(node.id){selection.remove(node.id)}else{selection.insert(node.id)}} else {selection=[node.id]}
        if includingGroup && !node.groupID.isEmpty && !additive {selection=Set(page.nodes.filter{$0.groupID==node.groupID && ($0.visibleVariants?.contains(variant.rawValue) ?? true)}.map(\.id))}
    }
    func updateNode(_ id:String,body:(inout DesignNode)->Void) {
        change { p in guard let pi=p.pages.firstIndex(where:{$0.id==pageID}),let ni=p.pages[pi].nodes.firstIndex(where:{$0.id==id}) else{return};body(&p.pages[pi].nodes[ni]) }
    }
    func add(_ kind:ComponentKind,at location:CGPoint?=nil,in target:Variant?=nil) {
        let v=target ?? variant; variant=v
        var n=DesignNode(kind:kind)
        if kind == .tabBar || kind == .sidebar {n.items=project.pages.map{NavigationItem(title:$0.name,symbol:$0.id==project.pages[0].id ? "house" : "square",pageID:$0.id)}}
        var r=n.frame(v,device:project.device)
        if let location {r.x=location.x; r.y=location.y} else if !n.isFixed{r.y=max(48,min(140+Double(page.nodes.count%6)*48,project.device.size(v).height-r.height-24))+(scrollOffsets[v] ?? 0)}
        n.frames[v.rawValue]=r
        let node=n
        change{p in if let i=p.pages.firstIndex(where:{$0.id==pageID}){p.pages[i].appendComponent(node,device:p.device,preferredRowID:selection.first)}}
        selection=[n.id];status="已添加\(kind.title)"
    }
    func addPage() {let p=DesignPage(name:"页面 \(project.pages.count+1)");change{$0.pages.append(p)};selectPage(p.id)}
    func duplicatePage() {
        var copy=page;copy.id=UUID().uuidString;copy.name += " 副本"
        copy.nodes=copy.nodes.map{var n=$0;n.id=UUID().uuidString;n.groupID="";return n}
        change{$0.pages.append(copy)};selectPage(copy.id)
    }
    func deletePage() {
        guard project.pages.count>1 else{return};let id=pageID
        change{p in p.pages.removeAll{$0.id==id};for pi in p.pages.indices { for ni in p.pages[pi].nodes.indices {if p.pages[pi].nodes[ni].targetPageID==id{p.pages[pi].nodes[ni].targetPageID=""};p.pages[pi].nodes[ni].items.removeAll{$0.pageID==id}}}}
        selectPage(project.pages[0].id)
    }
    func deleteSelection() {change{p in if let i=p.pages.firstIndex(where:{$0.id==pageID}){p.pages[i].nodes.removeAll{selection.contains($0.id) && !$0.locked}}};selection=[]}
    func duplicate() {
        var copies=page.nodes.filter{selection.contains($0.id)}
        for i in copies.indices {copies[i].id=UUID().uuidString;copies[i].groupID="";copies[i].name += " 副本";var r=copies[i].frame(variant,device:project.device);r.x += 16;r.y += 16;copies[i].frames[variant.rawValue]=r}
        change{p in if let i=p.pages.firstIndex(where:{$0.id==pageID}){p.pages[i].nodes += copies}};selection=Set(copies.map(\.id))
    }
    func align(_ mode:String) {change{p in if let i=p.pages.firstIndex(where:{$0.id==pageID}){LayoutEngine.align(&p.pages[i].nodes,ids:selection,variant:variant,device:p.device,alignment:mode)}}}
    func reorder(front:Bool) {change{p in guard let i=p.pages.firstIndex(where:{$0.id==pageID}) else{return};let picked=p.pages[i].nodes.filter{selection.contains($0.id)};p.pages[i].nodes.removeAll{selection.contains($0.id)};if front{p.pages[i].nodes += picked}else{p.pages[i].nodes.insert(contentsOf:picked,at:0)}}}
    func group() {guard selection.count>1 else{return};let id=UUID().uuidString;change{p in guard let i=p.pages.firstIndex(where:{$0.id==pageID}) else{return};for j in p.pages[i].nodes.indices where selection.contains(p.pages[i].nodes[j].id){p.pages[i].nodes[j].groupID=id}}}
    func ungroup() {change{p in guard let i=p.pages.firstIndex(where:{$0.id==pageID}) else{return};for j in p.pages[i].nodes.indices where selection.contains(p.pages[i].nodes[j].id){p.pages[i].nodes[j].groupID=""}};selection=[];status="已解除组合，可逐项编辑"}
    func saveTemplate() {guard !selection.isEmpty else{return};templateName=selection.count==1 ? selected?.name ?? "我的组件" : "我的组合组件";templateCategory=TemplateCatalog.suggested(name:templateName,nodes:page.nodes.filter{selection.contains($0.id)});showTemplateComposer=true}
    func confirmTemplate() {
        let nodes=page.nodes.filter{selection.contains($0.id)};guard !nodes.isEmpty else{return}
        let name=templateName.trimmingCharacters(in:.whitespacesAndNewlines)
        let template=TemplateCatalog.portable(ComponentTemplate(name:name.isEmpty ? "我的组合组件":name,nodes:nodes,category:templateCategory),device:project.device)
        change{$0.templates.append(template)}
        guard project.templates.contains(where:{$0.id==template.id}) else{return}
        showTemplateComposer=false
        if saveTemplatePersonally{copyToPersonal(template)}else{status="已保存项目组件"}
    }
    func insertTemplate(_ template:ComponentTemplate) {
        let nodes=ComponentAssembly.instantiate(template,origin:Rect(24,120.0+Double(scrollOffsets[variant] ?? 0)),variant:variant,device:project.device,pages:Set(project.pages.map(\.id)))
        change{p in if let i=p.pages.firstIndex(where:{$0.id==pageID}){p.pages[i].nodes += nodes}};selection=Set(nodes.map(\.id))
    }
    func reloadPersonalLibrary() {do{personalLibrary=try PersonalComponentLibrary.load(personalLibraryURL)}catch{self.error="个人组件库："+error.localizedDescription}}
    func copyToPersonal(_ template:ComponentTemplate) {
        do {
            let saved=TemplateCatalog.portable(template,device:project.device)
            personalLibrary=try PersonalComponentLibrary.update(personalLibraryURL,expectedRevision:personalLibrary?.revision ?? 0){templates in
                if let i=templates.firstIndex(where:{$0.id==saved.id}){templates[i]=saved}else{templates.append(saved)}
            };status="已保存到个人组件库，其他项目可复用"
        }catch{self.error=error.localizedDescription;reloadPersonalLibrary()}
    }
    func setTemplateCategory(_ id:String,category:String,personal:Bool) {
        if personal {
            do {personalLibrary=try PersonalComponentLibrary.update(personalLibraryURL,expectedRevision:personalLibrary?.revision ?? 0){templates in if let i=templates.firstIndex(where:{$0.id==id}){templates[i].category=category}}}
            catch{self.error=error.localizedDescription;reloadPersonalLibrary()}
        }else{change{p in if let i=p.templates.firstIndex(where:{$0.id==id}){p.templates[i].category=category}}}
    }
    func decompose(_ id:String) {
        guard let node=page.nodes.first(where:{$0.id==id}),node.kind.decomposable else{return}
        let parts=ComponentAssembly.decompose(node,device:project.device)
        change{p in if let pi=p.pages.firstIndex(where:{$0.id==pageID}),let ni=p.pages[pi].nodes.firstIndex(where:{$0.id==id}){p.pages[pi].nodes.remove(at:ni);p.pages[pi].nodes.insert(contentsOf:parts,at:ni)}}
        selection=[];status="已拆分并解除组合，点击逐项编辑；Shift 多选后可重新组合"
    }
    func beginPropertyGesture(){guard !dragging else{return};dragging=true;propertyGesture=true;dragSnapshot=project}
    func loadImageData()->String? {
        let panel=NSOpenPanel();panel.allowedContentTypes=[.image,.pdf];panel.message="上传图标或图片，将转换为可随工程导出的 PNG"
        guard panel.runModal() == .OK,let file=panel.url else{return nil}
        guard let image=NSImage(contentsOf:file),let tiff=image.tiffRepresentation,let bitmap=NSBitmapImageRep(data:tiff),let png=bitmap.representation(using:.png,properties:[:]),png.count<20_000_000 else{error="无法读取图片，或图片超过 20 MB。请使用 PNG、JPEG 或系统支持的图片格式。";return nil}
        return png.base64EncodedString()
    }
    func uploadIcon(_ id:String,slot:WritableKeyPath<DesignNode,String?>) {if let data=loadImageData(){updateNode(id){$0[keyPath:slot]=data;$0.showIcon=true}}}
    func uploadItemIcon(_ nodeID:String,itemID:String,selected:Bool=false) {if let data=loadImageData(){updateNode(nodeID){n in if let i=n.items.firstIndex(where:{$0.id==itemID}){if selected{n.items[i].selectedIconData=data}else{n.items[i].iconData=data}}}}}
    func dropPalette(_ kind:ComponentKind,at point:CGPoint) {
        defer {paletteKind=nil}
        guard !preview,let hit=visibleVariants.first(where:{boardFrames[$0]?.contains(point)==true}),let frame=boardFrames[hit] else{return}
        add(kind,at:CGPoint(x:(point.x-frame.minX)/zoom,y:(point.y-frame.minY)/zoom+(DesignNode(kind:kind).isFixed ? 0:(scrollOffsets[hit] ?? 0))),in:hit)
    }
    func beginDrag(_ node:DesignNode,variant v:Variant) {
        guard !node.locked else{return};variant=v;if !selection.contains(node.id){select(node,additive:NSEvent.modifierFlags.contains(.shift))};dragging=true;dragSnapshot=project
        dragFrames=Dictionary(uniqueKeysWithValues:page.nodes.filter{selection.contains($0.id) && !$0.locked}.map{($0.id,$0.frame(v,device:project.device))})
    }
    func drag(_ node:DesignNode,translation:CGSize) {
        guard let base=dragFrames[node.id],let pi=project.pages.firstIndex(where:{$0.id==pageID}) else{return}
        let before=project
        var r=base;r.x += translation.width/zoom;r.y += translation.height/zoom
        let others=page.nodes.filter{!selection.contains($0.id) && !$0.hidden}.map{$0.frame(variant,device:project.device)}
        if snapping {let snap=LayoutEngine.snap(r,others:others,size:project.device.size(variant),threshold:5/zoom,grid:showGrid);r=snap.frame;guideX=snap.vertical;guideY=snap.horizontal}
        for i in project.pages[pi].nodes.indices {let id=project.pages[pi].nodes[i].id;if var original=dragFrames[id]{original.x += r.x-base.x;original.y += r.y-base.y;project.pages[pi].nodes[i].frames[variant.rawValue]=original}}
        SharedTabBar.reconcile(&project,before:before)
    }
    func finishDrag() {guard dragging else{return};dragging=false;isResizing=false;propertyGesture=false;guideX=nil;guideY=nil;guard let before=dragSnapshot else{return};let after=project;project=before;dragSnapshot=nil;dragFrames=[:];change{$0=after}}
    func beginResize(_ node:DesignNode,variant v:Variant) {
        guard !node.locked else{return}
        variant=v;selection=[node.id];dragging=true;isResizing=true;dragSnapshot=project
    }
    func resize(_ id:String,start:Rect,translation:CGSize) {
        guard isResizing,let pi=project.pages.firstIndex(where:{$0.id==pageID}),let i=project.pages[pi].nodes.firstIndex(where:{$0.id==id}),!project.pages[pi].nodes[i].locked else{return}
        let before=project
        project.pages[pi].nodes[i].frames[variant.rawValue]=LayoutEngine.resized(start,dx:translation.width/zoom,dy:translation.height/zoom,keepAspect:NSEvent.modifierFlags.contains(.shift))
        SharedTabBar.reconcile(&project,before:before)
    }

    func setWide(_ wide:Bool) {change{$0.wideMode=wide};variant=visibleVariants[0];fitCanvases()}
    func rotate() {landscape.toggle();variant=visibleVariants[0];selection=Set(page.nodes.filter{selection.contains($0.id) && $0.isVisible(in:variant)}.map(\.id));fitCanvases()}
    func fitCanvases() {let total=visibleVariants.reduce(0.0){$0+project.device.size($1).width};let padding=88.0+Double(visibleVariants.count-1)*44;zoom=max(0.25,min(0.75,(canvasViewportWidth-padding)/total))}
    func copyLayout() {let from=variant;change{p in guard let i=p.pages.firstIndex(where:{$0.id==pageID}) else{return};for j in p.pages[i].nodes.indices {let r=p.pages[i].nodes[j].frame(from,device:p.device),source=p.device.size(from);for v in visibleVariants where v != from {let target=p.device.size(v);p.pages[i].nodes[j].frames[v.rawValue]=Rect(r.x/source.width*target.width,r.y/source.height*target.height,r.width/source.width*target.width,r.height/source.height*target.height)}}};status="已将当前布局同步到另一块屏幕"}
    func newProject() {let panel=NSSavePanel();panel.nameFieldStringValue="未命名.framestudio";if panel.runModal() == .OK,let dest=panel.url {do{let p=try ProjectStore.save(.demo(),to:dest,expectedRevision:nil);adopt(p,url:dest)}catch{self.error=error.localizedDescription}}}
    func adopt(_ p:DesignProject,url:URL) {project=p;self.url=url;revisionOnDisk=p.revision;pageID=p.pages[0].id;selection=[];undoStack=[];redoStack=[];variant=visibleVariants[0];status="已打开 \(url.lastPathComponent)"}
    func openProject() {let panel=NSOpenPanel();panel.allowedContentTypes=[.json,.data];panel.allowsOtherFileTypes=true;if panel.runModal() == .OK,let file=panel.url {do{adopt(try ProjectStore.load(file),url:file)}catch{self.error=error.localizedDescription}}}
    func saveAs() {let panel=NSSavePanel();panel.nameFieldStringValue=project.name+".framestudio";if panel.runModal() == .OK,let dest=panel.url{do{let p=try ProjectStore.save(project,to:dest,expectedRevision:nil);adopt(p,url:dest)}catch{self.error=error.localizedDescription}}}
    func importSwift() {
        let panel=NSOpenPanel();panel.canChooseDirectories=true;panel.canChooseFiles=true
        panel.message="选择旧 UI 源码；将另存为独立设计，避免与当前项目的页面和 Tab 混合"
        guard panel.runModal() == .OK,let file=panel.url else{return}
        status="正在读取 View 结构与复用组件…"
        Task {
            do {
                let report=try await Task.detached {try SwiftImporter.inspect(file)}.value
                guard !report.pages.isEmpty else{throw StudioError.invalid("未找到可导入的 View 页面。请查看源目录或通过 Agent 读取源码。")}
                let save=NSSavePanel();save.nameFieldStringValue=file.deletingPathExtension().lastPathComponent+".framestudio"
                save.message="保存为新的设计项目；原项目与当前设计均保留"
                guard save.runModal() == .OK,let destination=save.url else{status="已取消导入";return}
                let p=try ProjectStore.save(report.project(named:file.deletingPathExtension().lastPathComponent),to:destination,expectedRevision:nil)
                adopt(p,url:destination);showImportReport=true
            }catch{self.error=error.localizedDescription;status="导入未完成"}
        }
    }

    func chooseImage(_ id:String) {if let data=loadImageData(){updateNode(id){$0.imageData=data}}}
    func export() {performExport(exportFormat)}
    func performExport(_ format:ExportFormat) {
        exportFormat=format
        let panel=NSOpenPanel();panel.canChooseDirectories=true;panel.canChooseFiles=false;panel.canCreateDirectories=true
        panel.prompt="导出到这里";panel.message="导出 \(format.title) UI 源码、资源和项目配置，不生成手机安装包；业务功能需后续开发"
        if panel.runModal() == .OK,let directory=panel.url {
            do {let result=try DesignExporter.export(project,format:format,to:directory);status="已导出 \(format.title) · \(result.lastPathComponent)";NSWorkspace.shared.activateFileViewerSelecting([result])}
            catch{self.error=error.localizedDescription}
        }
    }
}
