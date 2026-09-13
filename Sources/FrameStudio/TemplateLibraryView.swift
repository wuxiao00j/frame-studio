import SwiftUI
import StudioCore

@MainActor struct TemplateLibraryView:View {
    @Bindable var session:EditorSession
    @State private var expanded:Set<String>=["builtin:表单与选择","personal:表单与选择","personal:导航与页头"]
    var body:some View {
        VStack(alignment:.leading,spacing:18) {
            collection("内置组合",templates:TemplateCatalog.bundled,scope:"builtin")
            HStack{Text("个人组件 · 所有项目").fontWeight(.semibold);Spacer();Button{session.reloadPersonalLibrary()}label:{Image(systemName:"arrow.clockwise")}.buttonStyle(.plain).help("刷新个人组件库")}.font(.system(size:10))
            if session.personalLibrary?.templates.isEmpty != false {Text("保存组合时勾选“个人组件库”，以后新建项目也可复用。").font(.system(size:10)).foregroundStyle(studioMuted)}
            groups(session.personalLibrary?.templates ?? [],scope:"personal")
            collection("项目组件",templates:session.project.templates,scope:"project")
        }
    }
    func matches(_ t:ComponentTemplate)->Bool {session.search.isEmpty || t.name.localizedCaseInsensitiveContains(session.search) || t.categoryTitle.localizedCaseInsensitiveContains(session.search)}
    @ViewBuilder func collection(_ title:String,templates:[ComponentTemplate],scope:String)->some View {
        VStack(alignment:.leading,spacing:10){HStack{Text(title).fontWeight(.semibold);Spacer();Text("\(templates.count)")}.font(.system(size:10)).foregroundStyle(studioMuted);groups(templates,scope:scope)}
    }
    @ViewBuilder func groups(_ templates:[ComponentTemplate],scope:String)->some View {
        let visible=templates.filter(matches)
        let categories=Set(visible.map(\.categoryTitle)).sorted{a,b in
            let x=TemplateCatalog.categories.firstIndex(of:a) ?? 100,y=TemplateCatalog.categories.firstIndex(of:b) ?? 100
            return x==y ? a.localizedStandardCompare(b) == .orderedAscending:x<y
        }
        ForEach(categories,id:\.self){category in
            DisclosureGroup(isExpanded:Binding(get:{!session.search.isEmpty || expanded.contains(scope+":"+category)},set:{value in if value{expanded.insert(scope+":"+category)}else{expanded.remove(scope+":"+category)}})) {
                ForEach(visible.filter{$0.categoryTitle==category}){template in
                    Button{session.insertTemplate(template)}label:{Label(template.name,systemImage:"square.stack.3d.up").font(.system(size:11)).frame(maxWidth:.infinity,alignment:.leading).padding(.vertical,7)}.buttonStyle(.plain)
                        .contextMenu {
                            if scope != "personal" {Button("保存到个人组件库"){session.copyToPersonal(template)}}
                            if scope != "builtin" {Menu("移动到分类"){ForEach(TemplateCatalog.categories,id:\.self){name in Button(name){session.setTemplateCategory(template.id,category:name,personal:scope=="personal")}}}}
                            if scope=="project" {Button("删除项目模板",role:.destructive){session.change{$0.templates.removeAll{$0.id==template.id}}}}
                        }
                }
            } label:{Text("\(category) · \(visible.filter{$0.categoryTitle==category}.count)").font(.system(size:10,weight:.medium))}
        }
    }
}
