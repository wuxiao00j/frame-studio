import Foundation

public enum LayerMove:String,CaseIterable,Sendable {
    case forward,backward,front,back
}
public extension LayoutEngine {
    static func reordered(_ nodes:[DesignNode],ids:Set<String>,move:LayerMove,variant:Variant)->[DesignNode] {
        var result=nodes
        let selected=Set(nodes.filter{ids.contains($0.id) && !$0.locked}.map(\.id))
        func plane(_ n:DesignNode)->Int{n.isFixed ? (n.backgroundLayer==true ? 0:2):1}
        for layer in 0...2 {
            let slots=nodes.indices.filter{plane(nodes[$0])==layer && (nodes[$0].visibleVariants?.contains(variant.rawValue) ?? true)}
            var ordered=slots.map{nodes[$0]}
            guard ordered.count>1 else{continue}
            switch move {
            case .front:ordered=ordered.filter{!selected.contains($0.id)}+ordered.filter{selected.contains($0.id)}
            case .back:ordered=ordered.filter{selected.contains($0.id)}+ordered.filter{!selected.contains($0.id)}
            case .forward:
                for i in stride(from:ordered.count-2,through:0,by:-1) where selected.contains(ordered[i].id) && !selected.contains(ordered[i+1].id){ordered.swapAt(i,i+1)}
            case .backward:
                for i in 1..<ordered.count where selected.contains(ordered[i].id) && !selected.contains(ordered[i-1].id){ordered.swapAt(i,i-1)}
            }
            for (slot,node) in zip(slots,ordered){result[slot]=node}
        }
        return result
    }
}
