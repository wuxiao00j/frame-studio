import SwiftUI
import StudioCore

@MainActor struct LayerOrderControls:View {
    let session:EditorSession
    var body:some View {
        VStack(spacing:8) {
            HStack{Button("上一层"){session.reorder(.forward)}.disabled(!session.canReorder(.forward));Button("下一层"){session.reorder(.backward)}.disabled(!session.canReorder(.backward))}
            HStack{Button("置顶"){session.reorder(.front)}.disabled(!session.canReorder(.front));Button("置底"){session.reorder(.back)}.disabled(!session.canReorder(.back))}
        }.font(.system(size:10))
    }
}
@MainActor struct GroupInspector:View {
    @Bindable var session:EditorSession
    let group:GroupSelection
    func binding(_ key:WritableKeyPath<Rect,Double>)->Binding<Double> {
        Binding(get:{session.selectionGroup(in:session.variant)?.bounds[keyPath:key] ?? group.bounds[keyPath:key]},set:{value in
            guard var rect=session.selectionGroup(in:session.variant)?.bounds else{return};rect[keyPath:key]=value;session.setGroupBounds(rect)
        })
    }
    var body:some View {
        InspectorSection(title:"合并组件") {
            Text("\(group.ids.count) 个内部图层 · 一个整体外框").font(.system(size:11))
            Text("从图层列表选择成员，可单独修改文字、图标和颜色；也可拆分后继续编辑。").font(.system(size:10)).foregroundStyle(studioMuted)
            Button("拆分组合",action:session.ungroup)
        }
        InspectorSection(title:"整体位置与尺寸") {
            HStack{NumberField(label:"X",value:binding(\.x));NumberField(label:"Y",value:binding(\.y))}
            HStack{NumberField(label:"W",value:binding(\.width));NumberField(label:"H",value:binding(\.height))}
            if !group.canTransform{Text("包含锁定成员，请先解锁。").font(.system(size:10)).foregroundStyle(studioMuted)}
        }.disabled(!group.canTransform)
        InspectorSection(title:"整体对齐") {
            HStack{align("左","left");align("居中","centerX");align("右","right")}
            HStack{align("顶","top");align("垂直居中","centerY");align("底","bottom")}
        }.font(.system(size:10)).disabled(!group.canTransform)
        InspectorSection(title:"图层操作") {
            LayerOrderControls(session:session)
            Button("复制合并组件",action:session.duplicate)
            Button("保存为复用组件…",action:session.saveTemplate)
            Button("删除选中组件",role:.destructive,action:session.deleteSelection)
        }.font(.system(size:10))
    }
    func align(_ title:String,_ mode:String)->some View {Button(title){
        guard var r=session.selectionGroup(in:session.variant)?.bounds else{return};let size=session.project.device.size(session.variant)
        switch mode{case "left":r.x=0;case "right":r.x=size.width-r.width;case "centerX":r.x=(size.width-r.width)/2;case "top":r.y=0;case "bottom":r.y=size.height-r.height;default:r.y=(size.height-r.height)/2}
        session.setGroupBounds(r)
    }}
}
