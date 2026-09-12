import SwiftUI
import StudioCore

@MainActor struct BehaviorInspector:View {
    @Bindable var session:EditorSession
    let node:DesignNode
    func binding<T>(_ key:WritableKeyPath<DesignNode,T?>,_ fallback:T)->Binding<T>{Binding(get:{session.page.nodes.first{$0.id==node.id}?[keyPath:key] ?? fallback},set:{value in session.updateNode(node.id){$0[keyPath:key]=value}})}
    var body:some View {
        InspectorSection(title:"页面中的行为") {Toggle("固定在屏幕上（不随页面滚动）",isOn:binding(\.fixedToViewport,node.isFixed)).font(.system(size:10))}
        if [.toggle,.switchControl,.checkbox,.radio].contains(node.kind) {
            InspectorSection(title:"控件排布") {
                Picker("按钮位置",selection:binding(\.controlPosition,node.position)){Text("靠左").tag("leading");Text("靠右").tag("trailing")}.pickerStyle(.segmented)
                Toggle("显示文字",isOn:binding(\.showLabel,node.hasLabel))
                Toggle("文字前显示图标",isOn:binding(\.showIcon,node.hasIcon))
            }.font(.system(size:11))
        }
        if [.button,.textButton,.outlinedButton,.iconLabel,.listRow,.card,.alertBanner,.statistic].contains(node.kind) {Toggle("显示前置图标",isOn:binding(\.showIcon,node.hasIcon)).font(.system(size:11))}
        if [.icon,.iconButton,.button,.backButton,.iconLabel,.textButton,.outlinedButton,.checkbox,.radio,.toggle,.listRow,.card,.alertBanner,.statistic,.qrCode,.chevron,.navigationBar,.secureField,.searchField].contains(node.kind) {
            InspectorSection(title:"自定义图标") {iconSlot("上传 / 替换图标",key:\.iconData)}
        }
        if node.kind == .profileRow {
            InspectorSection(title:"资料栏附件") {
                Toggle("显示二维码",isOn:binding(\.showQRCode,node.hasQRCode))
                if node.hasQRCode{iconSlot("替换二维码图标",key:\.qrIconData)}
                Toggle("显示右箭头",isOn:binding(\.showChevron,node.hasChevron))
                if node.hasChevron{iconSlot("替换箭头图标",key:\.chevronIconData)}
            }.font(.system(size:11))
        }
        if node.kind == .listRow {
            InspectorSection(title:"连续列表") {
                Toggle("显示右箭头",isOn:binding(\.showChevron,node.hasChevron))
                if node.hasChevron{iconSlot("替换右箭头",key:\.chevronIconData)}
                if node.rowGroupID != nil {Text("已连接列表：相邻行之间自动取消圆角。").font(.system(size:10)).foregroundStyle(studioMuted);Button("脱离连续列表"){session.updateNode(node.id){$0.rowGroupID=nil}}}
            }
        }
        if node.kind == .navigationBar {
            InspectorSection(title:"导航栏按钮") {
                Picker("左侧动作",selection:binding(\.navigationAction,node.navigationAction ?? "sidebar")){Text("打开侧栏").tag("sidebar");Text("返回上一页").tag("back")}
                TextField("右侧系统图标",text:binding(\.trailingSymbol,node.trailingSymbol ?? "square.and.pencil")).textFieldStyle(.roundedBorder)
                iconSlot("上传右侧图标",key:\.trailingIconData)
            }.font(.system(size:11))
        }
        if [.toggle,.switchControl,.checkbox,.radio].contains(node.kind) {Toggle("默认开启 / 选中",isOn:Binding(get:{node.isOn},set:{value in session.updateNode(node.id){$0.isOn=value}})).font(.system(size:11))}
        if [.progress,.ringProgress].contains(node.kind) {ProgressInspector(session:session,node:node)}
        if [.stepper,.rating].contains(node.kind) {
            InspectorSection(title:"数值设置") {
                NumberField(label:"当前值",value:binding(\.numberValue,node.number))
                HStack{NumberField(label:"最小",value:binding(\.minimumValue,node.minimum));NumberField(label:"最大",value:binding(\.maximumValue,node.maximum))}
                if node.kind == .stepper{NumberField(label:"步长",value:binding(\.stepValue,node.step))}
            }
        }
        if node.kind == .dateField {TextField("日期 yyyy-MM-dd",text:binding(\.dateValue,node.dateValue ?? "2026-01-01")).textFieldStyle(.roundedBorder)}
        if node.kind.decomposable {
            InspectorSection(title:"拆分组合") {Button("拆分为基础组件"){session.decompose(node.id)};Text("分成文字、图标、背景和控件，之后可以逐个调整或保存成自己的组合。").font(.system(size:10)).foregroundStyle(studioMuted)}
        }
    }
    @ViewBuilder func iconSlot(_ title:String,key:WritableKeyPath<DesignNode,String?>)->some View {
        HStack{if let data=node[keyPath:key]{UploadedIcon(data:data,symbol:"photo",size:24)};Button(title){session.uploadIcon(node.id,slot:key)};if node[keyPath:key] != nil{Button("移除"){session.updateNode(node.id){$0[keyPath:key]=nil}}}}.font(.system(size:10))
    }
}
@MainActor struct ProgressInspector:View {
    @Bindable var session:EditorSession
    let node:DesignNode
    func binding<T>(_ key:WritableKeyPath<DesignNode,T?>,_ fallback:T)->Binding<T>{Binding(get:{node[keyPath:key] ?? fallback},set:{v in session.updateNode(node.id){$0[keyPath:key]=v}})}
    var body:some View {
        InspectorSection(title:"进度样式与数值") {
            Picker("样式",selection:Binding(get:{node.progressMode},set:changeStyle)){Text("条形").tag("linear");Text("环形").tag("circular");Text("分段").tag("steps")}.pickerStyle(.segmented)
            Picker("数值显示",selection:binding(\.progressLabel,node.progressLabelMode)){Text("不显示").tag("none");Text("百分比").tag("percent");Text("当前 / 总量").tag("fraction")}
            HStack{NumberField(label:"当前",value:binding(\.progressCurrent,node.current));NumberField(label:"总量",value:binding(\.progressTotal,node.total))}
            Slider(value:Binding(get:{node.fraction},set:{v in session.updateNode(node.id){$0.progressCurrent=v*$0.total}}),in:0...1,onEditingChanged:{active in if active{session.beginPropertyGesture()}else{session.finishDrag()}})
            NumberField(label:"线条粗细",value:binding(\.progressThickness,node.progressThickness ?? 6))
            if node.progressMode=="steps" {Stepper("分段数：\(node.progressSteps ?? 5)",value:binding(\.progressSteps,node.progressSteps ?? 5),in:1...50)}
            ColorProperty(label:"轨道颜色",value:binding(\.trackColor,node.trackColor ?? "E5E2ED"))
        }.font(.system(size:10))
    }
    func changeStyle(_ style:String) {session.updateNode(node.id){n in n.progressStyle=style;if n.progressLabel==nil{n.progressLabel="percent"};var r=n.frame(session.variant,device:session.project.device);if style=="circular"{r.width=100;r.height=100}else{r.width=300;r.height=44};n.frames[session.variant.rawValue]=r}}
}
@MainActor struct TemplateComposer:View {
    @Bindable var session:EditorSession
    @Environment(\.dismiss) var dismiss
    var body:some View {
        VStack(alignment:.leading,spacing:18){Text("创建组合组件").font(.title2.bold());Text("把选中的 \(session.selection.count) 个图层保存为可重复使用的组件。").font(.system(size:12)).foregroundStyle(studioMuted);TextField("组合组件名称",text:$session.templateName).textFieldStyle(.roundedBorder);Text("插入后可以整体拖动，也能取消组合后逐个修改。所有布局和上传图片都会保留。").font(.system(size:11)).foregroundStyle(studioMuted);HStack{Button("取消"){dismiss()};Spacer();Button("保存组件"){session.confirmTemplate()}.buttonStyle(.borderedProminent).keyboardShortcut(.defaultAction)}}.padding(26).frame(width:430)
    }
}
