import SwiftUI
import StudioCore

@MainActor struct LibrarySidebar:View {
    @Bindable var session:EditorSession
    var kinds:[ComponentKind] {ComponentKind.allCases.filter{session.search.isEmpty || $0.title.localizedCaseInsensitiveContains(session.search) || $0.rawValue.localizedCaseInsensitiveContains(session.search)}}
    var body:some View {
        VStack(spacing:0){
            HStack(spacing:10){Image(systemName:"square.stack.3d.up.fill").font(.system(size:20)).foregroundStyle(studioAccent);VStack(alignment:.leading,spacing:3){Text("原境").font(.system(size:18,weight:.bold));Text("FRAME STUDIO").font(.system(size:8,weight:.semibold)).tracking(1.8).foregroundStyle(studioMuted)};Spacer();Text("1.2 Beta").font(.system(size:9)).foregroundStyle(studioMuted).padding(5).background(Color(hex:"F3F1F8"),in:RoundedRectangle(cornerRadius:5))}.padding(20)
            HStack{Text("页面").font(.system(size:11,weight:.semibold)).foregroundStyle(studioMuted);Spacer();Button(action:session.addPage){Image(systemName:"plus")}.buttonStyle(.plain).help("添加页面")}.padding(.horizontal,20).padding(.top,8)
            ScrollView{VStack(spacing:4){ForEach(session.project.pages){page in PageRow(session:session,page:page)}}.padding(.horizontal,12).padding(.vertical,10)}.frame(maxHeight:170)
            Divider().overlay(studioLine)
            Picker("资源",selection:$session.libraryTab){Text("组件").tag(0);Text("图层").tag(1)}.pickerStyle(.segmented).labelsHidden().padding(14)
            if session.libraryTab==0{
                HStack{Text("\(ComponentKind.allCases.count) 种组件").foregroundStyle(studioMuted);Spacer();Button("创建组合…"){session.saveTemplate()}.disabled(session.selection.isEmpty).help("Shift 多选图层后，创建自己的组合组件")}.font(.system(size:10)).padding(.horizontal,16).padding(.bottom,10)
                HStack{Image(systemName:"magnifyingglass").foregroundStyle(studioMuted);TextField("搜索组件",text:$session.search).textFieldStyle(.plain)}.font(.system(size:11)).padding(9).background(Color(hex:"F6F4F9"),in:RoundedRectangle(cornerRadius:8)).padding(.horizontal,16).padding(.bottom,14)
                ScrollView{VStack(alignment:.leading,spacing:18){
                    ForEach(ComponentKind.categories,id:\.self){category in
                        let list=kinds.filter{$0.category==category}
                        if !list.isEmpty{VStack(alignment:.leading,spacing:9){Text(category).font(.system(size:10,weight:.semibold)).foregroundStyle(studioMuted);LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible())],spacing:8){ForEach(list){kind in ComponentTile(session:session,kind:kind){session.add(kind)}}}}}
                    }
                    VStack(alignment:.leading,spacing:10){HStack{Text("我的组合组件").font(.system(size:10,weight:.semibold)).foregroundStyle(studioMuted);Spacer();Text("\(session.project.templates.count)").font(.system(size:10)).foregroundStyle(studioMuted)}
                        if session.project.templates.isEmpty{Text("多选模块 → 存为组合组件\n组合好的设计，可以重复使用。").font(.system(size:10)).lineSpacing(5).foregroundStyle(studioMuted).padding(12).frame(maxWidth:.infinity,alignment:.leading).background(Color(hex:"F8F7FA"),in:RoundedRectangle(cornerRadius:8))}
                        ForEach(session.project.templates){template in Button{session.insertTemplate(template)}label:{Label(template.name,systemImage:"square.stack.3d.up").font(.system(size:11)).frame(maxWidth:.infinity,alignment:.leading).padding(10)}.buttonStyle(.plain).background(Color(hex:"F4F1FC"),in:RoundedRectangle(cornerRadius:8)).contextMenu{Button("删除模板",role:.destructive){session.change{$0.templates.removeAll{$0.id==template.id}}}}}
                    }
                }.padding(.horizontal,16).padding(.bottom,20)}
            }else{
                ScrollView{VStack(spacing:3){ForEach(session.page.nodes.filter{$0.visibleVariants?.contains(session.variant.rawValue) ?? true}.reversed()){node in LayerRow(session:session,node:node)}}.padding(.horizontal,10)}
            }
            Divider()
            Button{session.showMCP=true}label:{HStack(spacing:10){Image(systemName:"point.3.connected.trianglepath.dotted").foregroundStyle(studioAccent);VStack(alignment:.leading,spacing:4){Text("与 Agent 一起设计").font(.system(size:11,weight:.medium));Text("MCP 本地连接").font(.system(size:9)).foregroundStyle(studioMuted)};Spacer();Circle().fill(Color(hex:"79A990")).frame(width:5,height:5)}}.buttonStyle(.plain).padding(16)
        }.frame(width:244).background(.white)
    }
}
@MainActor struct ComponentTile:View {
    @Bindable var session:EditorSession
    let kind:ComponentKind
    let action:()->Void
    @State private var hovering=false
    var body:some View {Button(action:action){VStack(spacing:10){Image(systemName:kind.symbol).font(.system(size:20,weight:.light)).foregroundStyle(hovering ? studioAccent : Color(hex:"777086"));Text(kind.title).font(.system(size:10)).foregroundStyle(studioInk)}.frame(maxWidth:.infinity).frame(height:74).background(hovering ? Color(hex:"F0EBFC") : Color(hex:"FCFBFE"),in:RoundedRectangle(cornerRadius:9)).overlay(RoundedRectangle(cornerRadius:9).stroke(hovering ? studioAccent.opacity(0.4) : studioLine,lineWidth:1))}.buttonStyle(.plain).onHover{hovering=$0}.simultaneousGesture(DragGesture(minimumDistance:5,coordinateSpace:.global).onChanged { gesture in session.paletteKind=kind;session.paletteLocation=gesture.location }.onEnded { gesture in session.dropPalette(kind,at:gesture.location) }).help("拖入画布或点击添加\(kind.title)")}
}
@MainActor struct PageRow:View {
    @Bindable var session:EditorSession
    let page:DesignPage
    var body:some View {HStack(spacing:10){Image(systemName:session.pageID==page.id ? "doc.fill" : "doc").font(.system(size:12));Text(page.name).font(.system(size:11));Spacer();Text(String(format:"%02d",(session.project.pages.firstIndex{$0.id==page.id} ?? 0)+1)).font(.system(size:9)).opacity(0.5)}.foregroundStyle(session.pageID==page.id ? studioAccent : studioInk).padding(.horizontal,12).frame(height:34).background(session.pageID==page.id ? Color(hex:"F0EBFC") : .clear,in:RoundedRectangle(cornerRadius:7)).contentShape(Rectangle()).onTapGesture{session.selectPage(page.id)}.contextMenu{Button("复制页面"){session.selectPage(page.id);session.duplicatePage()};Button("删除页面",role:.destructive){session.selectPage(page.id);session.deletePage()}.disabled(session.project.pages.count==1)}}
}
@MainActor struct LayerRow:View {
    @Bindable var session:EditorSession
    let node:DesignNode
    var body:some View {
        HStack(spacing:7) {
            Image(systemName:node.kind.symbol).frame(width:20)
            VStack(alignment:.leading,spacing:3) {
                Text(node.name).lineLimit(1)
                if !node.text.isEmpty && node.text != node.name {Text(node.text).font(.system(size:9)).foregroundStyle(studioMuted).lineLimit(1)}
            }
            Spacer(minLength:0)
            Button{session.updateNode(node.id){$0.hidden.toggle()}}label:{Image(systemName:node.hidden ? "eye.slash" : "eye")}
            Button{session.updateNode(node.id){$0.locked.toggle()}}label:{Image(systemName:node.locked ? "lock.fill" : "lock.open")}
        }.font(.system(size:10)).buttonStyle(.plain).foregroundStyle(node.hidden ? studioMuted : studioInk).padding(9)
            .background(session.selection.contains(node.id) ? Color(hex:"F0EBFC") : .clear,in:RoundedRectangle(cornerRadius:6))
            .contentShape(Rectangle()).help("选择单个图层；Shift 多选，不会解除原有组合")
            .onTapGesture{session.select(node,additive:NSEvent.modifierFlags.contains(.shift),includingGroup:false)}
    }
}
