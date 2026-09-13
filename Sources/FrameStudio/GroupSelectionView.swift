import SwiftUI
import StudioCore

@MainActor struct GroupSelectionView:View {
    @Bindable var session:EditorSession
    let group:GroupSelection
    let offset:Double
    @State private var resizing=false
    var body:some View {
        Rectangle().fill(Color.clear).contentShape(Rectangle())
            .overlay{Rectangle().stroke(studioAccent,lineWidth:1.5/session.zoom).allowsHitTesting(false)}
            .overlay(alignment:.topLeading){Text("合并组件 · \(Int(group.bounds.width)) × \(Int(group.bounds.height))").font(.system(size:9/session.zoom)).padding(3/session.zoom).background(studioAccent).foregroundStyle(.white).offset(y:-20/session.zoom).allowsHitTesting(false)}
            .overlay(alignment:.bottomTrailing) {
                if group.canTransform {
                    Image(systemName:"arrow.up.left.and.arrow.down.right").font(.system(size:11/session.zoom,weight:.bold)).foregroundStyle(.white)
                        .frame(width:22/session.zoom,height:22/session.zoom).background(studioAccent,in:RoundedRectangle(cornerRadius:5/session.zoom)).padding(2/session.zoom)
                        .accessibilityLabel("调整合并组件大小")
                        .highPriorityGesture(DragGesture(minimumDistance:0,coordinateSpace:.global).onChanged{g in
                            if !resizing{resizing=true;session.beginGroupTransform(resizing:true,offset:offset)}
                            session.transformGroup(translation:g.translation,keepAspect:NSEvent.modifierFlags.contains(.shift))
                        }.onEnded{_ in session.finishDrag();resizing=false})
                }
            }
            .onTapGesture{}
            .gesture(DragGesture(minimumDistance:4,coordinateSpace:.global).onChanged{g in
                guard group.canTransform,!resizing,!session.isResizing else{return}
                if !session.dragging{session.beginGroupTransform(resizing:false,offset:offset)}
                session.transformGroup(translation:g.translation)
            }.onEnded{_ in if !resizing{session.finishDrag()}})
            .contextMenu{Button("拆分组合",action:session.ungroup);Button("保存为复用组件…",action:session.saveTemplate);Divider();Button("上一层"){session.reorder(.forward)}.disabled(!session.canReorder(.forward));Button("下一层"){session.reorder(.backward)}.disabled(!session.canReorder(.backward))}
            .accessibilityElement(children:.contain).accessibilityLabel("合并组件整体外框")
            .frame(width:CGFloat(group.bounds.width),height:CGFloat(group.bounds.height))
            .position(x:CGFloat(group.bounds.midX),y:CGFloat(group.bounds.midY))
    }
}
