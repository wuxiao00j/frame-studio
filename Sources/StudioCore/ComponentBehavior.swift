import Foundation

public struct CornerRadii:Codable,Equatable,Sendable {
    public var tl:Double;public var tr:Double;public var bl:Double;public var br:Double
    public init(_ radius:Double){tl=radius;tr=radius;bl=radius;br=radius}
}
public extension DesignNode {
    static let optionalFieldKeys:Set<String> = ["actionTitle","controlStyle","selectedIndex","isEnabled","material","clipMasks","lineLimit","lineSpacing","minimumScaleFactor","imageFit","visibleVariants","backgroundLayer","gradient","blurRadius","shadowColor","shadowX","shadowY","flutterCode","composeCode","showIcon","showLabel","showQRCode","showChevron","controlPosition","navigationAction","syncTabIcons","iconData","qrIconData","chevronIconData","trailingSymbol","trailingIconData","progressStyle","progressLabel","progressCurrent","progressTotal","progressThickness","progressSteps","trackColor","numberValue","minimumValue","maximumValue","stepValue","dateValue","fixedToViewport","rowGroupID"]
    var isFixed:Bool {fixedToViewport ?? [.navigationBar,.tabBar].contains(kind)}
    func isVisible(in variant:Variant)->Bool {!hidden && (visibleVariants?.contains(variant.rawValue) ?? true)}
    var hasIcon:Bool {showIcon ?? ![.toggle,.checkbox,.radio,.switchControl,.text,.textField,.textButton,.outlinedButton,.textArea,.selectField].contains(kind)}
    var hasLabel:Bool {showLabel ?? (kind != .switchControl)}
    var hasQRCode:Bool {showQRCode ?? true}
    var hasChevron:Bool {showChevron ?? true}
    var position:String {controlPosition ?? "trailing"}
    var progressMode:String {progressStyle ?? (kind == .ringProgress ? "circular" : "linear")}
    var progressLabelMode:String {progressLabel ?? (kind == .ringProgress ? "percent" : "none")}
    var total:Double {max(0.0001,progressTotal ?? 100)}
    var current:Double {progressCurrent ?? value*total}
    var fraction:Double {min(1,max(0,current/total))}
    var progressText:String {
        switch progressLabelMode {case "percent":return "\(Int((fraction*100).rounded()))%";case "fraction":return "\(Self.displayNumber(current))/\(Self.displayNumber(total))";default:return ""}
    }
    var number:Double {numberValue ?? (kind == .rating ? 3 : 1)}
    var minimum:Double {minimumValue ?? 0}
    var maximum:Double {maximumValue ?? (kind == .rating ? 5 : 99)}
    var step:Double {stepValue ?? 1}
    static func displayNumber(_ n:Double)->String {if n.rounded()==n{return String(format:"%.0f",locale:Locale(identifier:"en_US_POSIX"),n)};return String(format:"%.2f",locale:Locale(identifier:"en_US_POSIX"),n).replacingOccurrences(of:#"\.?0+$"#,with:"",options:.regularExpression)}
}
public extension DesignPage {
    var isScrollable:Bool {scrollEnabled ?? true}
    func contentHeight(_ variant:Variant,device:DeviceProfile)->Double {
        let viewport=device.size(variant)
        guard isScrollable else{return viewport.height}
        let end=nodes.filter{$0.isVisible(in:variant) && !$0.isFixed}.map{n in let r=n.frame(variant,device:device);return r.y+r.height}.max() ?? 0
        let footer=nodes.filter{!$0.hidden && $0.isFixed && $0.kind == .tabBar}.map{max(0,viewport.height-$0.frame(variant,device:device).y)}.max() ?? 8
        return max(viewport.height,contentHeights?[variant.rawValue] ?? 0,end+footer+16)
    }
    func corners(_ node:DesignNode,variant:Variant,device:DeviceProfile)->CornerRadii {
        var corners=CornerRadii(node.cornerRadius)
        guard let group=node.rowGroupID,!group.isEmpty else{return corners}
        let r=node.frame(variant,device:device)
        for other in nodes where other.id != node.id && !other.hidden && other.rowGroupID==group {
            let o=other.frame(variant,device:device)
            guard abs(o.x-r.x)<0.5,abs(o.width-r.width)<0.5 else{continue}
            if abs(o.y+o.height-r.y)<0.5 {corners.tl=0;corners.tr=0}
            if abs(r.y+r.height-o.y)<0.5 {corners.bl=0;corners.br=0}
        }
        return corners
    }
    mutating func appendComponent(_ node:DesignNode,device:DeviceProfile,preferredRowID:String?=nil,joinRows:Bool=true) {
        var n=node
        if n.kind == .listRow && joinRows && autoJoinRows != false {
            let preferred=nodes.first{$0.id==preferredRowID && $0.kind == .listRow && !$0.hidden}
            if let anchor=preferred ?? nodes.last(where:{$0.kind == .listRow && !$0.hidden}) {
                let group=anchor.rowGroupID ?? UUID().uuidString
                if let index=nodes.firstIndex(where:{$0.id==anchor.id}){nodes[index].rowGroupID=group}
                n.rowGroupID=group
                for v in Variant.allCases {
                    let previous=nodes.filter{$0.rowGroupID==group && !$0.hidden}.map{$0.frame(v,device:device)}.max{($0.y+$0.height)<($1.y+$1.height)} ?? anchor.frame(v,device:device)
                    n.frames[v.rawValue]=Rect(previous.x,previous.y+previous.height,previous.width,previous.height)
                }
            }
        }
        nodes.append(n)
    }
}
