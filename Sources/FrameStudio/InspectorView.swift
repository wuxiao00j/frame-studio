import SwiftUI
import StudioCore

@MainActor struct InspectorView:View {
    @Bindable var session:EditorSession
    var body:some View {
        VStack(spacing:0){HStack{Text("设计属性").font(.system(size:12,weight:.semibold));Spacer();Text(session.selection.isEmpty ? "页面" : "\(session.selection.count) 个选中").font(.system(size:10)).foregroundStyle(studioMuted)}.padding(20);Divider();ScrollView{VStack(alignment:.leading,spacing:20){if let node=session.selected{NodeInspector(session:session,node:node)}else{PageInspector(session:session)}}.padding(18)}}.frame(width:276).background(.white)
    }
}
@MainActor struct InspectorSection<Content:View>:View {
    let title:String
    @ViewBuilder let content:()->Content
    var body:some View {VStack(alignment:.leading,spacing:12){Text(title).font(.system(size:10,weight:.semibold)).foregroundStyle(studioMuted);content()}.frame(maxWidth:.infinity,alignment:.leading)}
}
@MainActor struct PageInspector:View {
    @Bindable var session:EditorSession
    var body:some View {
        if !session.project.importNotes.isEmpty{Button("查看导入分类 / 未匹配组件"){session.showImportReport=true}.font(.system(size:11))}
        InspectorSection(title:"页面信息"){
            TextField("页面名称",text:Binding(get:{session.page.name},set:{name in session.change{p in if let i=p.pages.firstIndex(where:{$0.id==session.pageID}){p.pages[i].name=name}}})).textFieldStyle(.roundedBorder)
            ColorPicker("背景颜色",selection:Binding(get:{Color(hex:session.page.background)},set:{color in session.change{p in if let i=p.pages.firstIndex(where:{$0.id==session.pageID}){p.pages[i].background=color.hex}}})).font(.system(size:11))
        }
        Divider()
        InspectorSection(title:"长页面滚动") {
            Toggle("允许上下滚动",isOn:Binding(get:{session.page.isScrollable},set:{enabled in session.change{p in if let i=p.pages.firstIndex(where:{$0.id==session.pageID}){p.pages[i].scrollEnabled=enabled}}})).font(.system(size:11))
            NumberField(label:"内容高度",value:Binding(get:{session.page.contentHeight(session.variant,device:session.project.device)},set:{height in session.change{p in if let i=p.pages.firstIndex(where:{$0.id==session.pageID}){var heights=p.pages[i].contentHeights ?? [:];heights[session.variant.rawValue]=height;p.pages[i].contentHeights=heights}}}))
            Text("滚轮在手机内部上下滚动。超出一屏的内容自动扩展，导航栏和 Tab 默认固定。").font(.system(size:10)).foregroundStyle(studioMuted)
            Toggle("新列表行自动紧贴已有列表",isOn:Binding(get:{session.page.autoJoinRows ?? true},set:{enabled in session.change{p in if let i=p.pages.firstIndex(where:{$0.id==session.pageID}){p.pages[i].autoJoinRows=enabled}}})).font(.system(size:10))
        }
        InspectorSection(title:"画布"){
            HStack{Text(session.variant.title);Spacer();Image(systemName:session.landscape ? "iphone.gen3.landscape" : "iphone.gen3")}.font(.system(size:11))
            let size=session.project.device.size(session.variant)
            Text("\(Int(size.width)) × \(Int(size.height)) pt").font(.system(size:24,weight:.light)).monospacedDigit()
            Button("调整画布尺寸"){session.showDevices=true}.font(.system(size:11))
            if session.project.wideMode {Button("当前布局同步到另一屏",action:session.copyLayout).font(.system(size:11));Text("内容共享，布局独立保存。\n点选画布后，编辑它自己的布局。").font(.system(size:10)).foregroundStyle(studioMuted).lineSpacing(5)}
        }
        Divider()
        InspectorSection(title:"开始创造"){
            Image(systemName:"cursorarrow.and.square.on.square.dashed").font(.system(size:35,weight:.ultraLight)).foregroundStyle(studioAccent).padding(.vertical,12)
            Text("从左侧拖入一个组件，\n或点击画布中的模块。")
                .font(.system(size:12)).lineSpacing(6).foregroundStyle(studioMuted)
            Text("⌘D 复制  ·  ⌘⌫ 删除\nShift 点击多选  ·  ⌘G 组合\n拖动右下角调整大小 · Shift 保持比例")
                .font(.system(size:10)).lineSpacing(7).foregroundStyle(studioMuted).padding(.top,10)
        }
    }
}
@MainActor struct NodeInspector:View {
    @Bindable var session:EditorSession
    let node:DesignNode
    @State private var symbolPicker=false
    func binding<T>(_ key:WritableKeyPath<DesignNode,T>)->Binding<T>{Binding(get:{session.page.nodes.first{$0.id==node.id}?[keyPath:key] ?? node[keyPath:key]},set:{value in session.updateNode(node.id){$0[keyPath:key]=value}})}
    func rectBinding(_ key:WritableKeyPath<Rect,Double>)->Binding<Double>{Binding(get:{(session.page.nodes.first{$0.id==node.id} ?? node).frame(session.variant,device:session.project.device)[keyPath:key]},set:{value in session.updateNode(node.id){var r=$0.frame(session.variant,device:session.project.device);r[keyPath:key]=value;$0.frames[session.variant.rawValue]=r}})}
    var body:some View {
        InspectorSection(title:node.kind.title){TextField("图层名称",text:binding(\.name)).textFieldStyle(.roundedBorder)}
        InspectorSection(title:"组合与拆分") {
            HStack {
                Button("组合选中",action:session.group).disabled(session.selection.count<2)
                Button("解除组合",action:session.ungroup).disabled(!session.page.nodes.contains{session.selection.contains($0.id) && !$0.groupID.isEmpty})
            }
            if node.kind.decomposable {Button("拆分为基础组件"){session.decompose(node.id)}}
            Text("Shift 点击多选 · ⌘G 组合 · ⇧⌘G 解组\n拆分后可直接逐项编辑，再多选重新组合。").foregroundStyle(studioMuted)
        }.font(.system(size:10))
        if node.kind == .tabBar {
            Text("项目共用 Tab 栏：所有已有 Tab 的页面同步项目、图标、样式和对应屏幕的位置尺寸。当前页面的选中高亮独立显示。")
                .font(.system(size:10)).foregroundStyle(studioAccent)
        }
        InspectorSection(title:"对齐与分布"){
            HStack(spacing:0){alignButton("left","align.horizontal.left");alignButton("centerX","align.horizontal.center");alignButton("right","align.horizontal.right");alignButton("top","align.vertical.top");alignButton("centerY","align.vertical.center");alignButton("bottom","align.vertical.bottom")}
            HStack{Button("水平等距"){session.align("distributeX")};Button("垂直等距"){session.align("distributeY")}}.font(.system(size:10)).disabled(session.selection.count<3)
        }
        InspectorSection(title:"位置与尺寸 · \(session.variant.title)"){
            HStack{NumberField(label:"X",value:rectBinding(\.x));NumberField(label:"Y",value:rectBinding(\.y))}
            HStack{NumberField(label:"W",value:rectBinding(\.width));NumberField(label:"H",value:rectBinding(\.height))}
            HStack{NumberField(label:"旋转",value:binding(\.rotation));NumberField(label:"圆角",value:binding(\.cornerRadius))}
            HStack{Text("圆角").font(.system(size:10)).foregroundStyle(studioMuted);Slider(value:binding(\.cornerRadius),in:0...max(100,node.cornerRadius,min(node.frame(session.variant,device:session.project.device).width,node.frame(session.variant,device:session.project.device).height)/2),onEditingChanged:{active in if active{session.beginPropertyGesture()}else{session.finishDrag()}}).help("拖动实时调整圆角")}
            Picker("适配锚点",selection:binding(\.anchor)){Text("左上").tag(Anchor.topLeft);Text("右上").tag(Anchor.topRight);Text("左下").tag(Anchor.bottomLeft);Text("右下").tag(Anchor.bottomRight);Text("居中").tag(Anchor.center);Text("横向拉伸").tag(Anchor.stretch)}.font(.system(size:10))
        }
        Divider()
        BehaviorInspector(session:session,node:node)
        InspectorSection(title:"内容"){
            TextField("标题 / 文本",text:binding(\.text),axis:.vertical).lineLimit(1...5).textFieldStyle(.roundedBorder)
            if [.profileRow,.listRow,.card].contains(node.kind){TextField("副标题",text:binding(\.subtitle),axis:.vertical).lineLimit(1...3).textFieldStyle(.roundedBorder)}
            HStack{Image(systemName:node.symbol).font(.system(size:20)).frame(width:30);TextField("SF Symbol 名称",text:binding(\.symbol)).textFieldStyle(.roundedBorder);Button{symbolPicker=true}label:{Image(systemName:"square.grid.2x2")}.help("替换图标")}
            if [.image,.avatar,.profileRow,.icon,.iconButton].contains(node.kind){HStack{Button("替换图片 / 头像"){session.chooseImage(node.id)};if !node.imageData.isEmpty{Button("移除"){session.updateNode(node.id){$0.imageData=""}}}}.font(.system(size:10))}
            HStack{NumberField(label:"字号",value:binding(\.fontSize));NumberField(label:"图标",value:binding(\.iconSize))}
            Picker("字重",selection:binding(\.fontWeight)){Text("常规").tag("regular");Text("中等").tag("medium");Text("半粗").tag("semibold");Text("粗体").tag("bold")}.font(.system(size:10))
            Picker("文字对齐",selection:binding(\.textAlignment)){Image(systemName:"text.alignleft").tag("leading");Image(systemName:"text.aligncenter").tag("center");Image(systemName:"text.alignright").tag("trailing")}.pickerStyle(.segmented)
        }
        InspectorSection(title:"外观"){
            ColorProperty(label:"填充",value:binding(\.fill));ColorProperty(label:"文字与图标",value:binding(\.foreground));ColorProperty(label:"强调色",value:binding(\.accent));ColorProperty(label:"边框",value:binding(\.borderColor))
            HStack{NumberField(label:"描边",value:binding(\.borderWidth));NumberField(label:"阴影",value:binding(\.shadow))}
            HStack{NumberField(label:"内边距",value:binding(\.padding));NumberField(label:"间距",value:binding(\.spacing))}
            if node.kind == .profileRow || node.kind == .avatar{NumberField(label:"头像尺寸",value:binding(\.avatarSize))}
            HStack{Text("透明度").font(.system(size:10));Slider(value:binding(\.opacity),in:0...1);Text("\(Int(node.opacity*100))%").font(.system(size:10)).monospacedDigit()}
        }
        FillEffectsInspector(session:session,node:node)
        if node.kind == .slider {InspectorSection(title:"滑块初始值"){Slider(value:binding(\.value),in:0...1)}}
        if [.tabBar,.sidebar,.segmented,.selectField].contains(node.kind){NavigationItemsInspector(session:session,node:node)}
        InspectorSection(title:"交互"){
            Picker("点击跳转",selection:binding(\.targetPageID)){Text("无").tag("");ForEach(session.project.pages){Text($0.name).tag($0.id)}}.font(.system(size:10))
            if node.kind == .iconButton || node.kind == .navigationBar{Text("侧栏图标在预览时展开页面导航。").font(.system(size:10)).foregroundStyle(studioMuted)}
        }
        if node.kind == .custom {InspectorSection(title:"SwiftUI 视图表达式") {TextEditor(text:binding(\.customCode)).font(.system(size:10,design:.monospaced)).frame(height:130).border(studioLine);Text("Flutter Widget 表达式").font(.caption);TextEditor(text:Binding(get:{node.flutterCode ?? ""},set:{v in session.updateNode(node.id){$0.flutterCode=v}})).font(.system(size:10,design:.monospaced)).frame(height:90).border(studioLine);Text("Android Compose 内容").font(.caption);TextEditor(text:Binding(get:{node.composeCode ?? ""},set:{v in session.updateNode(node.id){$0.composeCode=v}})).font(.system(size:10,design:.monospaced)).frame(height:90).border(studioLine);Text("仅输入 View 表达式。编辑器不执行代码，导出后由 Xcode 编译。").font(.system(size:9)).foregroundStyle(studioMuted)}}
        InspectorSection(title:"图层操作"){
            HStack{Button("置顶"){session.reorder(front:true)};Button("置底"){session.reorder(front:false)};Button("复制",action:session.duplicate)}
            Button("创建组合组件…",action:session.saveTemplate)
            HStack{Toggle("锁定",isOn:binding(\.locked));Toggle("隐藏",isOn:binding(\.hidden))}
            Button("删除选中组件",role:.destructive,action:session.deleteSelection)
        }.font(.system(size:10))
        if !node.sourceReference.isEmpty {Text(node.sourceReference).font(.system(size:9)).foregroundStyle(studioMuted).textSelection(.enabled)}
        Color.clear.frame(height:0).sheet(isPresented:$symbolPicker){SymbolPicker(symbol:binding(\.symbol))}
    }
    func alignButton(_ key:String,_ symbol:String)->some View {Button{session.align(key)}label:{Image(systemName:symbol).frame(maxWidth:.infinity).frame(height:29)}.buttonStyle(.plain).background(Color(hex:"F5F3F9")).help(key).disabled(node.locked)}
}
@MainActor struct NumberField:View {
    let label:String
    @Binding var value:Double
    var body:some View {HStack(spacing:4){Text(label).foregroundStyle(studioMuted);TextField("",value:$value,format:.number.precision(.fractionLength(0...1))).textFieldStyle(.plain).multilineTextAlignment(.trailing).accessibilityLabel(label)}.font(.system(size:10)).padding(8).background(Color(hex:"F6F4F9"),in:RoundedRectangle(cornerRadius:6))}
}
@MainActor struct ColorProperty:View {
    let label:String
    @Binding var value:String
    @State private var draft=""
    var body:some View {
        HStack {
            ColorPicker(label,selection:Binding(get:{Color(hex:value)},set:{value=$0.hex})).font(.system(size:10))
            TextField("HEX",text:$draft).font(.system(size:10,design:.monospaced)).textFieldStyle(.roundedBorder).frame(width:83)
                .onSubmit { let clean=draft.replacingOccurrences(of:"#",with:"");if [6,8].contains(clean.count),UInt64(clean,radix:16) != nil {value=clean.uppercased()}else{draft=value} }
        }.onAppear{draft=value}.onChange(of:value){_,new in draft=new}
    }
}

@MainActor struct NavigationItemsInspector:View {
    @Bindable var session:EditorSession
    let node:DesignNode
    @State private var target:ItemIconTarget?
    func binding<T>(_ id:String,_ key:WritableKeyPath<NavigationItem,T>)->Binding<T>{Binding(get:{session.page.nodes.first{$0.id==node.id}?.items.first{$0.id==id}?[keyPath:key] ?? node.items.first{$0.id==id}![keyPath:key]},set:{v in session.updateNode(node.id){n in if let i=n.items.firstIndex(where:{$0.id==id}){n.items[i][keyPath:key]=v}}})}
    var body:some View {
        InspectorSection(title:"导航 / 选项项目") {
            if node.kind == .tabBar {Text("修改任意 Tab 项，自动同步到所有已有 Tab 栏的页面。").foregroundStyle(studioMuted)}
            ForEach(node.items){item in
                VStack(spacing:8) {
                    HStack{TextField("名称",text:binding(item.id,\.title)).textFieldStyle(.roundedBorder);Button{session.updateNode(node.id){$0.items.removeAll{$0.id==item.id}}}label:{Image(systemName:"minus.circle")}.buttonStyle(.plain)}
                    itemIcon(item,selected:false)
                    if node.kind == .tabBar {itemIcon(item,selected:true)}
                    Picker("对应页面",selection:binding(item.id,\.pageID)){Text("未绑定").tag("");ForEach(session.project.pages){Text($0.name).tag($0.id)}}
                    HStack {
                        Button("上移"){move(item.id,by:-1)}.disabled(node.items.first?.id==item.id)
                        Button("下移"){move(item.id,by:1)}.disabled(node.items.last?.id==item.id)
                        Spacer()
                    }
                }.font(.system(size:10)).padding(9).background(Color(hex:"F8F7FB"),in:RoundedRectangle(cornerRadius:8))
            }
            Button("添加导航项目"){session.updateNode(node.id){$0.items.append(NavigationItem(title:"新项目",symbol:"star"))}}
        }.font(.system(size:10))
        .sheet(item:$target){t in SymbolPicker(symbol:Binding(get:{let item=session.page.nodes.first{$0.id==node.id}?.items.first{$0.id==t.itemID};return t.selected ? (item?.selectedSymbol ?? item?.symbol ?? "star") : (item?.symbol ?? "star")},set:{symbol in session.updateNode(node.id){n in if let i=n.items.firstIndex(where:{$0.id==t.itemID}){if t.selected{n.items[i].selectedSymbol=symbol;n.items[i].selectedIconData=nil}else{n.items[i].symbol=symbol;n.items[i].iconData=nil}}}}))}
    }
    func move(_ id:String,by offset:Int) {
        session.updateNode(node.id){n in
            guard let index=n.items.firstIndex(where:{$0.id==id}),n.items.indices.contains(index+offset) else{return}
            n.items.swapAt(index,index+offset)
        }
    }
    func itemIcon(_ item:NavigationItem,selected:Bool)->some View {
        HStack(spacing:6) {
            Button{target=ItemIconTarget(itemID:item.id,selected:selected)}label:{UploadedIcon(data:selected ? item.activeIconData:item.iconData,symbol:selected ? item.activeSymbol:item.symbol,size:20).frame(width:30,height:30).background(.white,in:RoundedRectangle(cornerRadius:5))}.buttonStyle(.plain).help(selected ? "替换选中图标":"替换默认图标")
            VStack(alignment:.leading,spacing:5) {
                Text(selected ? "选中图标":"默认图标").foregroundStyle(studioMuted)
                HStack{Button("选择图标"){target=ItemIconTarget(itemID:item.id,selected:selected)};Button("上传"){session.uploadItemIcon(node.id,itemID:item.id,selected:selected)}}
            }
            Spacer(minLength:0)
            if selected {Button("重置"){session.updateNode(node.id){n in if let i=n.items.firstIndex(where:{$0.id==item.id}){n.items[i].selectedSymbol=nil;n.items[i].selectedIconData=nil}}}.help("选中图标跟随默认图标")}
            else if item.iconData != nil {Button("移除"){session.updateNode(node.id){n in if let i=n.items.firstIndex(where:{$0.id==item.id}){n.items[i].iconData=nil}}}}
        }.font(.system(size:9))
    }
}
struct ItemIconTarget:Identifiable {let itemID:String;let selected:Bool;var id:String {itemID+String(selected)}}

@MainActor struct SymbolPicker:View {
    @Environment(\.dismiss) var dismiss
    @Binding var symbol:String
    @State private var search=""
    let symbols=["sidebar.left","line.3.horizontal","square.and.pencil","plus","xmark","house","house.fill","square.grid.2x2","square.grid.2x2.fill","bubble.left","bubble.left.and.bubble.right","bubble.left.and.text.bubble.right","person","person.fill","person.crop.circle","person.crop.circle.fill","gearshape","gearshape.fill","bell","bell.fill","bookmark","bookmark.fill","star","star.fill","heart","heart.fill","sparkles","photo","photo.on.rectangle.angled","camera","magnifyingglass","folder","folder.fill","tray","arrow.up","arrow.down","arrow.left","arrow.right","chevron.right","chevron.left","ellipsis","ellipsis.circle","paperplane","paperplane.fill","mic","mic.fill","globe","link","doc","doc.text","checkmark","checkmark.circle.fill","qrcode","creditcard","wallet.pass","bag","cart","calendar","clock","location","map","moon","sun.max","play.circle","music.note","wifi","lock","eye","hand.thumbsup","phone","envelope","video","pencil","paintpalette","rectangle.stack","square.stack.3d.up","rectangle.portrait","app.badge","slider.horizontal.3","textformat"]
    var body:some View{VStack(alignment:.leading,spacing:18){HStack{Text("替换图标").font(.title3.bold());Spacer();Button("完成"){dismiss()}.keyboardShortcut(.defaultAction)};TextField("搜索 SF Symbols，或直接输入名称",text:$search).textFieldStyle(.roundedBorder);ScrollView{LazyVGrid(columns:Array(repeating:GridItem(.flexible()),count:7),spacing:12){ForEach(symbols.filter{search.isEmpty || $0.contains(search)},id:\.self){name in Button{symbol=name;dismiss()}label:{Image(systemName:name).font(.system(size:22)).frame(width:48,height:48).background(symbol==name ? studioAccent.opacity(0.15) : .gray.opacity(0.04),in:RoundedRectangle(cornerRadius:8))}.buttonStyle(.plain).help(name)}}};TextField("自定义 SF Symbol 名称",text:$symbol).textFieldStyle(.roundedBorder)}.padding(24).frame(width:470,height:470)}
}
