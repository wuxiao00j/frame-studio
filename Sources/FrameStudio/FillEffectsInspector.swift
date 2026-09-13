import SwiftUI
import StudioCore

@MainActor struct FillEffectsInspector:View {
    let session:EditorSession
    let node:DesignNode
    var current:DesignNode {session.page.nodes.first{$0.id==node.id} ?? node}
    func change(_ edit:(inout DesignGradient)->Void){session.updateNode(node.id){n in if var g=n.gradient{edit(&g);n.gradient=g}}}
    func numeric(_ key:WritableKeyPath<DesignNode,Double?>,_ fallback:Double=0)->Binding<Double> {Binding(get:{current[keyPath:key] ?? fallback},set:{value in session.updateNode(node.id){$0[keyPath:key]=value}})}
    var body:some View {
        InspectorSection(title:"渐变与柔化") {
            Picker("背景材质",selection:Binding(get:{current.material ?? "none"},set:{v in session.updateNode(node.id){$0.material=v=="none" ? nil:v;if v != "none"{$0.gradient=nil}}})) {
                Text("普通填充").tag("none");Text("极薄磨砂").tag("ultraThin");Text("薄磨砂").tag("thin");Text("标准磨砂").tag("regular");Text("厚磨砂").tag("thick");Text("极厚磨砂").tag("ultraThick")
            }
            if current.material != nil {Text("系统材质随背景变化；Android 导出使用半透明底色。").foregroundStyle(studioMuted)}
            Toggle("作为底层固定背景",isOn:Binding(get:{current.backgroundLayer==true},set:{value in session.updateNode(node.id){$0.backgroundLayer=value;if value{$0.fixedToViewport=true}}}))
            Toggle("使用渐变填充",isOn:Binding(get:{current.gradient != nil},set:{enabled in session.updateNode(node.id){n in n.gradient=enabled ? DesignGradient(stops:[.init(color:n.fill,location:0),.init(color:n.accent,location:1)]):nil;if enabled{n.material=nil}}}))
            if let g=current.gradient {
                Picker("渐变类型",selection:Binding(get:{current.gradient?.kind ?? "linear"},set:{kind in change{$0.kind=kind}})){Text("线性").tag("linear");Text("径向").tag("radial")}
                ForEach(g.stops.indices,id:\.self){i in
                    ColorProperty(label:"颜色 \(i+1)",value:Binding(get:{current.gradient?.stops[safe:i]?.color ?? "FFFFFF"},set:{color in change{if $0.stops.indices.contains(i){$0.stops[i].color=color}}}))
                }
                if g.kind=="linear" {HStack{Button("上下"){change{$0.startX=0.5;$0.startY=0;$0.endX=0.5;$0.endY=1}};Button("左右"){change{$0.startX=0;$0.startY=0.5;$0.endX=1;$0.endY=0.5}};Button("对角"){change{$0.startX=0;$0.startY=0;$0.endX=1;$0.endY=1}}}}
                else{NumberField(label:"半径",value:Binding(get:{current.gradient?.endRadius ?? 200},set:{r in change{$0.endRadius=max($0.startRadius+1,min(5000,r))}}))}
            }
            NumberField(label:"模糊",value:numeric(\.blurRadius))
            HStack{NumberField(label:"阴影 X",value:numeric(\.shadowX));NumberField(label:"阴影 Y",value:numeric(\.shadowY,node.shadow/3))}
            ColorProperty(label:"阴影色",value:Binding(get:{current.shadowColor ?? "00000017"},set:{color in session.updateNode(node.id){$0.shadowColor=color}}))
        }.font(.system(size:10))
    }
}
private extension Array {subscript(safe index:Int)->Element? {indices.contains(index) ? self[index]:nil}}
