import Foundation
import AppKit

extension SwiftImportLayout {
    func children(_ nodes:[SwiftImportElement],group:String="")->[(SwiftImportElement,String)] {
        nodes.flatMap {node in node.type=="Group" ? children(node.children,group:group.isEmpty ? node.group:group):[(node,group)]}
    }
    func fixedWidth(_ e:SwiftImportElement)->Double? {
        if e.type==".frame",let w=number(e.args["width"]){return w}
        if e.type.hasPrefix("."),let child=e.children.first{return fixedWidth(child)}
        return nil
    }
    func expands(_ e:SwiftImportElement)->Bool {
        if e.type=="Spacer"{return true}
        if e.type==".frame" {if number(e.args["width"]) != nil{return false};if SwiftSourceSyntax.text(e.args["maxWidth"] ?? []).contains("infinity"){return true}}
        if (e.type.hasPrefix(".") || e.type=="Group"),let first=e.children.first{return expands(first)}
        return false
    }
    func idealWidth(_ e:SwiftImportElement,style:SwiftImportStyle)->Double {
        var style=style
        if e.type==".font"{font(e.args["$0"] ?? [],&style)}
        if e.type==".frame",let w=number(e.args["width"]){return w}
        if e.type.hasPrefix("."),let child=e.children.first {
            var w=idealWidth(child,style:style)
            if e.type==".padding" {
                let edge=SwiftSourceSyntax.text(e.args["$0"] ?? []),amount=number(e.args["$1"]) ?? number(e.args["$0"]) ?? 16
                if edge.isEmpty || number(e.args["$0"]) != nil || edge.contains("horizontal") || edge==".all"{w+=amount*2}
                else if edge.contains("leading") || edge.contains("trailing"){w+=amount}
            };return w
        }
        if !e.children.isEmpty {
            let widths=children(e.children).map{idealWidth($0.0,style:style)}
            if ["HStack","LazyHStack"].contains(e.type){return widths.reduce(0,+)+(number(e.args["spacing"]) ?? 8)*Double(max(0,widths.count-1))}
            return widths.max() ?? 0
        }
        if e.type=="Spacer"{return number(e.args["minLength"]) ?? 0}
        if e.type=="Image",e.args["systemName"] != nil{return style.font}
        if ["Text","Button"].contains(e.type){return (text(e.args["$0"]) as NSString).size(withAttributes:[.font:NSFont.systemFont(ofSize:style.font)]).width+(e.type=="Button" ? 16:0)}
        return 10
    }
}
