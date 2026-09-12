import SwiftUI
import StudioCore
import UniformTypeIdentifiers

@MainActor struct CanvasWorkspace:View {
    @Bindable var session:EditorSession
    var body:some View {
        VStack(spacing:0){
            HStack(spacing:10){Text(session.page.name).font(.system(size:14,weight:.semibold));Image(systemName:"chevron.right").font(.system(size:9)).foregroundStyle(studioMuted);Text(session.project.wideMode ? "阔屏 · 双画布" : "标准屏").foregroundStyle(studioMuted);Spacer();if session.preview{Label("预览中 · 点击导航可切页",systemImage:"play.fill").foregroundStyle(studioAccent)}else{Text("拖入组件，开始设计").foregroundStyle(studioMuted)}}.font(.system(size:11)).padding(.horizontal,28).frame(height:52)
            ScrollView([.horizontal,.vertical]){
                HStack(alignment:.top,spacing:44){ForEach(session.visibleVariants){variant in ArtboardView(session:session,variant:variant)}}
                    .padding(44).frame(minWidth:session.canvasViewportWidth,minHeight:680,alignment:.top)
            }.id(session.visibleVariants)
            HStack(spacing:12){Label(session.status,systemImage:"checkmark.circle.fill").foregroundStyle(studioMuted);Spacer();Text("\(session.page.nodes.count) 个图层");Text("·");Text("Shift 多选");Text("·");Text("⌘Z 撤销")}.font(.system(size:10)).foregroundStyle(studioMuted).padding(.horizontal,24).frame(height:34).background(.white.opacity(0.7))
        }
        .background(GeometryReader { proxy in Color.clear.onAppear{session.canvasViewportWidth=proxy.size.width}.onChange(of:proxy.size.width){_,width in session.canvasViewportWidth=width} })
        .background {
            Color(hex:"F1EFF6")
            if session.showGrid {
                Canvas { context, size in
                    for x in stride(from:0.0,to:size.width,by:20) {
                        for y in stride(from:0.0,to:size.height,by:20) {
                            context.fill(Path(ellipseIn:CGRect(x:x,y:y,width:1.5,height:1.5)),with:.color(Color(hex:"D9D4E5")))
                        }
                    }
                }.allowsHitTesting(false)
            }
        }

    }
}
@MainActor struct ArtboardView:View {
    @Bindable var session:EditorSession
    let variant:Variant
    var size:Dimensions {session.project.device.size(variant)}
    var zoom:Double {session.zoom}
    var body:some View {
        VStack(alignment:.leading,spacing:14){
            HStack(spacing:8){Circle().fill(session.variant==variant ? studioAccent : studioMuted.opacity(0.5)).frame(width:6,height:6);Text(variant.title).fontWeight(.medium);Spacer();Text("\(Int(size.width)) × \(Int(size.height)) · 内容 \(Int(session.page.contentHeight(variant,device:session.project.device)))").monospacedDigit().foregroundStyle(studioMuted)}.font(.system(size:11)).frame(width:size.width*zoom)
            ZStack(alignment:.topLeading){
                Color(hex:session.page.background).onTapGesture{session.selection=[];session.variant=variant}
                ScrollView(.vertical,showsIndicators:session.page.isScrollable) {
                    ZStack(alignment:.topLeading) {
                        Color.clear.contentShape(Rectangle()).onTapGesture{session.selection=[];session.variant=variant}
                        ForEach(session.page.nodes.filter{!$0.hidden && !$0.isFixed}){node in CanvasNode(session:session,node:node,variant:variant)}
                    }.frame(width:size.width,height:session.page.contentHeight(variant,device:session.project.device))
                        .background(GeometryReader{proxy in Color.clear.preference(key:ArtboardScrollKey.self,value:-proxy.frame(in:.named(variant.rawValue)).minY)})
                }.coordinateSpace(name:variant.rawValue).scrollDisabled(!session.page.isScrollable)
                    .onPreferenceChange(ArtboardScrollKey.self){offset in session.scrollOffsets[variant]=max(0,offset)}
                    .id(session.pageID+variant.rawValue)
                ForEach(session.page.nodes.filter{!$0.hidden && $0.isFixed}){node in CanvasNode(session:session,node:node,variant:variant)}
                if session.sidebarOpen {SidebarOverlay(session:session,size:size)}
                HStack{Text("9:41").fontWeight(.semibold);Spacer();Image(systemName:"cellularbars");Image(systemName:"wifi");Image(systemName:"battery.100percent")}.font(.system(size:12)).foregroundStyle(Color(hex:"252336")).padding(.horizontal,26).frame(width:size.width,height:44).background(Color(hex:session.page.background)).allowsHitTesting(false)
                if session.variant==variant,let x=session.guideX{Path{p in p.move(to:CGPoint(x:x,y:0));p.addLine(to:CGPoint(x:x,y:size.height))}.stroke(Color.pink,lineWidth:1/zoom).allowsHitTesting(false)}
                if session.variant==variant,let y=session.guideY{Path{p in p.move(to:CGPoint(x:0,y:y));p.addLine(to:CGPoint(x:size.width,y:y))}.stroke(Color.pink,lineWidth:1/zoom).allowsHitTesting(false)}
                RoundedRectangle(cornerRadius:4).fill(Color(hex:"252336").opacity(0.8)).frame(width:108,height:4).position(x:size.width/2,y:size.height-11).allowsHitTesting(false)
            }
            .frame(width:size.width,height:size.height)
            .clipShape(RoundedRectangle(cornerRadius:28))
            .overlay(RoundedRectangle(cornerRadius:28).stroke(.white,lineWidth:5))
            .overlay(RoundedRectangle(cornerRadius:28).stroke(session.variant==variant ? studioAccent.opacity(0.25) : studioLine,lineWidth:1))
            .shadow(color:Color(hex:"38304F").opacity(0.09),radius:25,y:12)
            .scaleEffect(zoom,anchor:.topLeading)
            .frame(width:size.width*zoom,height:size.height*zoom,alignment:.topLeading)
            .background(GeometryReader { proxy in Color.clear.onAppear {session.boardFrames[variant]=proxy.frame(in:.global)}.onChange(of:proxy.frame(in:.global)) {_,frame in session.boardFrames[variant]=frame} })
            .onDrop(of:[UTType.text],delegate:CanvasDropDelegate(session:session,variant:variant,canEdit:!session.preview))
        }
        .onTapGesture{session.variant=variant}
    }
}
@MainActor struct CanvasNode:View {
    @Bindable var session:EditorSession
    let node:DesignNode
    let variant:Variant
    @State private var resizeStart:Rect?
    var rect:Rect {node.frame(variant,device:session.project.device)}
    var selected:Bool {session.selection.contains(node.id) && session.variant==variant && !session.preview}
    var body:some View {
        ComponentPreview(node:node,corners:session.page.corners(node,variant:variant,device:session.project.device),activePage:session.pageID,interactive:session.preview,navigate:session.selectPage,openSidebar:{session.sidebarOpen.toggle()})
            .allowsHitTesting(session.preview || node.kind == .tabBar || node.kind == .sidebar)
            .frame(width:rect.width,height:rect.height)
            .overlay{if !session.preview && node.kind != .tabBar && node.kind != .sidebar {Color.clear.contentShape(Rectangle())}}
            .overlay{if selected{Rectangle().stroke(studioAccent,lineWidth:1.5/session.zoom).allowsHitTesting(false)}}
            .overlay(alignment:.bottomTrailing) {
                if selected && !node.locked {
                    Image(systemName:"arrow.up.left.and.arrow.down.right")
                        .font(.system(size:11/session.zoom,weight:.bold)).foregroundStyle(.white)
                        .frame(width:22/session.zoom,height:22/session.zoom)
                        .background(studioAccent,in:RoundedRectangle(cornerRadius:5/session.zoom))
                        .overlay(RoundedRectangle(cornerRadius:5/session.zoom).stroke(.white,lineWidth:1.5/session.zoom))
                        .padding(2/session.zoom).contentShape(Rectangle())
                        .help("拖动右下角调整宽高；Shift 保持比例")
                        .accessibilityLabel("右下角拖动缩放")
                        .highPriorityGesture(DragGesture(minimumDistance:0,coordinateSpace:.global)
                            .onChanged { gesture in
                                if resizeStart==nil {resizeStart=rect;session.beginResize(node,variant:variant)}
                                if let start=resizeStart {session.resize(node.id,start:start,translation:gesture.translation)}
                            }.onEnded { _ in session.finishDrag();resizeStart=nil })
                }
            }

            .overlay(alignment:.topLeading){if selected{Text("\(Int(rect.width)) × \(Int(rect.height))").font(.system(size:9/session.zoom)).padding(3/session.zoom).background(studioAccent).foregroundStyle(.white).offset(y:-20/session.zoom).allowsHitTesting(false)}}
            .contentShape(Rectangle())
            .simultaneousGesture(TapGesture().onEnded { if !session.preview && node.kind != .tabBar && node.kind != .sidebar {session.variant=variant;session.select(node,additive:NSEvent.modifierFlags.contains(.shift))} })
            .simultaneousGesture(DragGesture(minimumDistance:4,coordinateSpace:.global).onChanged{g in guard !session.preview,!node.locked,!session.isResizing,resizeStart==nil else{return};if !session.dragging{session.beginDrag(node,variant:variant)};session.drag(node,translation:g.translation)}.onEnded{_ in session.finishDrag()})
            .contextMenu{Button("选择组件"){session.variant=variant;session.selection=[node.id]};Button("复制"){session.selection=[node.id];session.duplicate()};Button("存为组合组件"){session.selection=[node.id];session.saveTemplate()};if node.kind.decomposable{Button("拆分为基础组件"){session.decompose(node.id)}};Button(node.locked ? "解锁" : "锁定"){session.updateNode(node.id){$0.locked.toggle()}};Divider();Button("删除",role:.destructive){session.selection=[node.id];session.deleteSelection()}}
            .position(x:rect.midX,y:rect.midY)
    }
}
@MainActor struct SidebarOverlay:View {
    let session:EditorSession
    let size:Dimensions
    var body:some View {
        ZStack(alignment:.leading){Color.black.opacity(0.15).onTapGesture{session.sidebarOpen=false};VStack(alignment:.leading,spacing:24){HStack{Text("工作空间").font(.headline);Spacer();Button{session.sidebarOpen=false}label:{Image(systemName:"xmark")}.buttonStyle(.plain)};ForEach(session.project.pages){page in Button{session.selectPage(page.id)}label:{Label(page.name,systemImage:page.id==session.pageID ? "square.fill" : "square").frame(maxWidth:.infinity,alignment:.leading)}.buttonStyle(.plain)};Spacer()}.padding(24).frame(width:min(270,size.width*0.8),height:size.height).background(.white)}.frame(width:size.width,height:size.height)
    }
}

struct CanvasDropDelegate:DropDelegate {
    let session:EditorSession
    let variant:Variant
    let canEdit:Bool
    func validateDrop(info:DropInfo)->Bool { canEdit && info.hasItemsConforming(to:[UTType.text]) }
    func performDrop(info:DropInfo)->Bool {
        guard canEdit,let provider=info.itemProviders(for:[UTType.text]).first else {return false}
        let location=info.location
        provider.loadObject(ofClass:NSString.self) { object, _ in
            guard let raw=object as? String, let kind=ComponentKind(rawValue:raw) else{return}
            Task { @MainActor in guard !session.preview else{return};session.add(kind,at:CGPoint(x:location.x/session.zoom,y:location.y/session.zoom),in:variant) }
        }
        return true
    }
}

struct ArtboardScrollKey:PreferenceKey {static var defaultValue:CGFloat=0;static func reduce(value:inout CGFloat,nextValue:()->CGFloat){value=nextValue()}}
