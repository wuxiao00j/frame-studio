import Foundation

enum SwiftStructuredImporter {
    struct Tab {var view:String;var title:String;var symbol:String}
    static func inspect(files:[URL],assets:[URL],options:SwiftImportOptions)->ImportReport {
        let index=SwiftViewIndex(files:files),builder=SwiftViewBuilder(index:index,options:options),layout=SwiftImportLayout(builder:builder,assets:assets)
        var tabs:[Tab]=[],tabOwners=Set<String>()
        var tabTint:String?
        for definition in index.views.values.sorted(by:{$0.name<$1.name}) {
            for member in definition.members.values {
                let tokens=member.body
                for start in tokens.indices where tokens[start].text=="TabView" {
                    var cursor=start
                    guard let root=builder.call(tokens,&cursor),let content=root.closures["$body"] else{continue}
                    var after=cursor
                    while after<tokens.count {
                        while after<tokens.count && tokens[after].text=="\n"{after+=1}
                        guard after<tokens.count,tokens[after].text=="." else{break};after+=1
                        guard let modifier=builder.call(tokens,&after) else{break}
                        if modifier.name=="tint",let value=modifier.args["$0"] {tabTint=layout.color(builder.resolve(value,SwiftImportContext(owner:definition.name,values:builder.defaults(definition))))}
                    }
                    tabOwners.insert(definition.name);var i=0
                    while i<content.count {
                        let before=i
                        guard let child=builder.call(content,&i) else{i+=1;continue}
                        var title=child.name,symbol="square",hasTabItem=false
                        while i<content.count {
                            while i<content.count && content[i].text=="\n"{i+=1}
                            guard i<content.count,content[i].text=="." else{break};i+=1
                            guard let modifier=builder.call(content,&i) else{break}
                            if modifier.name=="tabItem",let label=modifier.closures["$body"] {
                                hasTabItem=true
                                if let position=label.firstIndex(where:{$0.text=="Label" || $0.text=="Text"}) {
                                    var at=position
                                    if let call=builder.call(label,&at){title=layout.text(call.args["$0"]);if let icon=call.args["systemImage"]{symbol=layout.text(icon)}}
                                }
                            }
                        }
                        if hasTabItem,index.views[child.name] != nil,!tabs.contains(where:{$0.view==child.name}) {tabs.append(Tab(view:child.name,title:title,symbol:symbol))}
                        if i<=before{i=before+1}
                    }
                }
            }
        }
        let helpers=["HeaderView","CardView","RowView","BackgroundView","ToastView"]
        var screenNames=index.views.keys.filter{name in
            !tabOwners.contains(name) && (tabs.contains{$0.view==name} || ((name.hasSuffix("View") || name.hasSuffix("Sheet")) && !helpers.contains(where:{name.hasSuffix($0)})))
        }.sorted()
        if screenNames.isEmpty {screenNames=index.views.keys.filter{!tabOwners.contains($0)}.sorted()}
        screenNames=tabs.map(\.view)+screenNames.filter{name in !tabs.contains{$0.view==name}}
        screenNames=Array(screenNames.prefix(150))
        var report=ImportReport(pages:[],warnings:[],files:index.files)
        var pages=screenNames.map{name in DesignPage(name:tabs.first{$0.view==name}?.title ?? name)}
        let pageIDs=Dictionary(uniqueKeysWithValues:zip(screenNames,pages.map(\.id)))
        var counts:[String:Int]=[:]
        var device=DeviceProfile();if let size=options.canvas{device.standard=size};report.device=device
        let topInset=options.topInset ?? 52
        func render(_ name:String)->[DesignNode] {
            builder.created=0
            let tree=builder.build(name);var nodes:[DesignNode]=[]
            func containsScroll(_ e:SwiftImportElement)->Bool {e.type=="ScrollView" && !SwiftSourceSyntax.text(e.args["$0"] ?? []).contains("horizontal") || e.children.contains(where:containsScroll)}
            func pin(_ e:SwiftImportElement){e.pinned=true;for child in e.children{pin(child)}}
            func markBackdrop(_ e:SwiftImportElement) {
                if e.type=="ZStack",e.children.contains(where:containsScroll){for child in e.children where !containsScroll(child){pin(child)};return}
                if e.children.count==1{markBackdrop(e.children[0])}
            }
            markBackdrop(tree)
            for variant in Variant.allCases {
                var box=layout.layout(tree,width:device.size(variant).width,height:device.size(variant).height-topInset)
                box.move(0,topInset)
                for i in box.nodes.indices where box.nodes[i].isFixed {
                    var r=layout.rect(box.nodes[i]);r.y-=topInset
                    if r.width>=device.size(variant).width-1 && r.height>=device.size(variant).height-topInset-1{r.height+=topInset}
                    box.nodes[i].frames[Variant.standardPortrait.rawValue]=r
                }
                let valid=box.nodes.filter {n in let r=layout.rect(n);return r.x.isFinite && r.y.isFinite && r.y<39000 && r.width.isFinite && r.height.isFinite}
                for node in valid where !nodes.contains(where:{$0.id==node.id}) {var node=node;node.frames=[:];node.clipMasks=nil;node.visibleVariants=[];nodes.append(node)}
                let frames=Dictionary(valid.map{($0.id,layout.rect($0))},uniquingKeysWith:{first,_ in first})
                for i in nodes.indices {if let frame=frames[nodes[i].id]{nodes[i].frames[variant.rawValue]=frame;nodes[i].visibleVariants?.append(variant.rawValue);if let masks=valid.first(where:{$0.id==nodes[i].id})?.clipMasks?[Variant.standardPortrait.rawValue]{if nodes[i].clipMasks==nil{nodes[i].clipMasks=[:]};nodes[i].clipMasks?[variant.rawValue]=masks}}}
            }
            // A reused local expression must have separate editable identities per occurrence.
            var seen=Set<String>()
            for i in nodes.indices {if nodes[i].visibleVariants?.count==Variant.allCases.count{nodes[i].visibleVariants=nil};if !seen.insert(nodes[i].id).inserted{nodes[i].id=UUID().uuidString}}
            return nodes
        }
        for (i,name) in screenNames.enumerated() {
            pages[i].nodes=render(name);pages[i].scrollEnabled=true;pages[i].background=pages[i].nodes.first(where:{$0.isFixed && $0.kind == .rectangle})?.fill ?? "FFFFFF"
            if tabs.contains(where:{$0.view==name}) {
                var tab=DesignNode(kind:.tabBar);tab.cornerRadius=0;tab.shadow=0
                if let tabTint{tab.accent=tabTint}
                tab.items=tabs.map{NavigationItem(title:$0.title,symbol:$0.symbol,pageID:pageIDs[$0.view] ?? "")}
                for variant in Variant.allCases {let size=device.size(variant);tab.frames[variant.rawValue]=Rect(0,size.height-80,size.width,64)}
                pages[i].nodes.append(tab)
            }
            for node in pages[i].nodes {let source=node.sourceReference.components(separatedBy:" · ").last ?? "SwiftUI";counts[source+"|"+node.kind.rawValue,default:0]+=1}
            report.warnings.append("已导入视图：\(name) → \(pages[i].nodes.count) 个可编辑图层；保留六套布局。")
        }
        report.pages=pages
        let templateNames=index.views.keys.filter{!screenNames.contains($0) && !tabOwners.contains($0)}.sorted()
        for name in templateNames.prefix(120) {
            let nodes=render(name)
            if !nodes.isEmpty {report.templates.append(ComponentTemplate(name:name,nodes:nodes))}
        }
        report.classifications=counts.keys.sorted().map{let parts=$0.components(separatedBy:"|");return ImportClassification(sourceType:parts[0],componentKind:parts[1],count:counts[$0]!)}
        for row in report.classifications {report.warnings.append("分类：\(row.sourceType) → \(ComponentKind(rawValue:row.componentKind)?.title ?? row.componentKind) × \(row.count)")}
        var seen=Set<String>()
        report.unmatched=builder.unmatched.filter{seen.insert($0.typeName+"|"+$0.sourceReference).inserted}
        for unknown in report.unmatched {report.warnings.append("未匹配预设：\(unknown.typeName)（\(unknown.sourceReference)）。只在视图结构中发现，需补充映射或源码。")}
        report.warnings += builder.warnings.sorted()
        for name in builder.expanded.sorted(){report.warnings.append("展开复用：\(name) 已从源码定义展开，内部图层按现有组件分类。")}
        let skipped=index.files.filter{file in !index.views.values.contains{$0.file==file}}
        report.warnings.insert("结构化导入：\(pages.count) 个页面，\(report.templates.count) 个复用组件；排除 \(skipped.count) 个非 View 文件。状态、模型和事件处理代码不生成组件。",at:0)
        report.warnings.insert("导入边界：静态读取源码，不运行原 App。动态数据、条件、复杂自定义布局、渐变与主题可能需要补充；详细限制单独列出，不等同于缺少预设组件。",at:1)
        if !options.values.isEmpty || !options.colors.isEmpty {report.warnings.insert("运行对照：采用 Agent 提供的 \(options.values.count) 个显示状态值和 \(options.colors.count) 个颜色值；这些参数用于静态重建，不会执行为源码。",at:2)}
        return report
    }
}
