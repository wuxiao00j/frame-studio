import SwiftUI
import StudioCore

@MainActor struct TextImageInspector:View {
    let session:EditorSession
    let node:DesignNode
    var current:DesignNode {session.page.nodes.first{$0.id==node.id} ?? node}
    var body:some View {
        if node.kind == .text {
            InspectorSection(title:"文字排版") {
                Toggle("限制行数",isOn:Binding(get:{current.lineLimit != nil},set:{enabled in session.updateNode(node.id){$0.lineLimit=enabled ? 2:nil}}))
                if current.lineLimit != nil {NumberField(label:"最多行",value:Binding(get:{Double(current.lineLimit ?? 2)},set:{v in session.updateNode(node.id){$0.lineLimit=Int(max(1,min(1000,v)))}}))}
                NumberField(label:"行间距",value:Binding(get:{current.lineSpacing ?? 0},set:{v in session.updateNode(node.id){$0.lineSpacing=max(0,min(500,v))}}))
                HStack{Text("最小字号比例");Spacer();Text("\(Int((current.minimumScaleFactor ?? 1)*100))%").monospacedDigit()}
                Slider(value:Binding(get:{current.minimumScaleFactor ?? 1},set:{v in session.updateNode(node.id){$0.minimumScaleFactor=v}}),in:0.1...1,step:0.01)
            }.font(.system(size:10))
        }
        if node.kind == .image {
            InspectorSection(title:"图片显示") {
                Picker("适应方式",selection:Binding(get:{current.imageFit ?? "fill"},set:{v in session.updateNode(node.id){$0.imageFit=v}})) {
                    Text("填满裁剪").tag("fill");Text("完整显示").tag("fit");Text("拉伸").tag("stretch")
                }
            }.font(.system(size:10))
        }
        if current.clipMasks?.values.contains(where:{!$0.isEmpty})==true {
            InspectorSection(title:"导入的容器裁剪") {
                Text("保留原容器边界，随此图层移动和缩放。解除后可自由编辑超出部分。").foregroundStyle(studioMuted)
                Text("当前布局：\(current.masks(in:session.variant).count) 层裁剪")
                Button("解除此组件的导入裁剪"){session.updateNode(node.id){$0.clipMasks=nil}}
            }.font(.system(size:10))
        }
    }
}
