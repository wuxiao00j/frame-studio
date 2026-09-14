import Foundation

extension SwiftViewBuilder {
    func nativeControl(_ call:SwiftImportCall,args:[String:[SwiftToken]],context:SwiftImportContext)->SwiftImportElement? {
        let ref=reference(context,call.line),name=call.name.replacingOccurrences(of:"SwiftUI.",with:"")
        if name=="Menu" {
            let label=SwiftImportElement("MenuLabel",children:sequence(call.closures["label"] ?? [],context:context),reference:ref)
            return SwiftImportElement(name,args:args,children:[label]+sequence(call.closures["$body"] ?? [],context:context),reference:ref)
        }
        if name=="LabeledContent" {
            var args=args
            if args["value"]==nil {
                let value=sequence(call.closures["$body"] ?? [],context:context),label=sequence(call.closures["label"] ?? [],context:context)
                if value.count==1,value[0].type=="Text",label.isEmpty || (label.count==1 && label[0].type=="Text") {
                    args["value"]=value[0].args["$0"] ?? value[0].args["verbatim"]
                    if let title=label.first?.args["$0"]{args["$0"]=title;args["_localizeTitle"]=label.first?.args["_localizeTitle"]}
                }else {
                    let leading=label.isEmpty ? [SwiftImportElement("Text",args:["$0":args["$0"] ?? []],reference:ref)]:label
                    return SwiftImportElement("HStack",children:leading+[SwiftImportElement("Spacer")]+value,reference:ref)
                }
            }
            return SwiftImportElement(name,args:args,reference:ref)
        }
        if name=="ContentUnavailableView" {
            var args=args
            let header=sequence(call.closures["$body"] ?? [],context:context)
            let description=sequence(call.closures["description"] ?? [],context:context)
            let actions=sequence(call.closures["actions"] ?? [],context:context)
            if let first=header.first,["Label","Text"].contains(first.type),header.count==1 {
                args["$0"]=first.args["$0"];args["systemImage"]=first.args["systemImage"];args["_localizeTitle"]=first.args["_localizeTitle"]
            }
            if description.count==1,description[0].type=="Text"{args["description"]=description[0].args["$0"] ?? description[0].args["verbatim"];args["_localizeDescription"]=description[0].args["_localizeTitle"]}
            if actions.count==1,actions[0].type=="Button"{args["_actionTitle"]=actions[0].args["$0"];args["_localizeAction"]=actions[0].args["_localizeTitle"]}
            if header.count>1 || (header.first.map{!["Text","Label"].contains($0.type)} ?? false) || description.count>1 || (description.first.map{$0.type != "Text"} ?? false) || actions.count>1 || (actions.first.map{$0.type != "Button"} ?? false) {
                warn("复杂空状态内容保留为基础图层组合",ref)
                return SwiftImportElement("VStack",children:header+description+actions,reference:ref)
            }
            return SwiftImportElement(name,args:args,reference:ref)
        }
        return nil
    }
}
extension SwiftImportLayout {
    func nativeControlLayout(_ e:SwiftImportElement,width:Double,height:Double?,style:SwiftImportStyle)->SwiftImportBox? {
        if e.type=="LabeledContent" {
            var n=node(e,kind:.keyValueRow,style:style,width:width,height:height ?? 44)
            n.text=text(e.args["$0"],reference:e.reference,localize:e.args["_localizeTitle"] != nil);n.subtitle=text(e.args["value"],reference:e.reference);n.showChevron=false;n.showIcon=false
            return SwiftImportBox(width:width,height:height ?? 44,nodes:[n])
        }
        if e.type=="ContentUnavailableView" {
            var n=node(e,kind:.emptyState,style:style,width:width,height:height ?? 210)
            n.text=text(e.args["$0"],reference:e.reference,localize:e.args["_localizeTitle"] != nil);n.subtitle=text(e.args["description"],reference:e.reference,localize:e.args["_localizeDescription"] != nil)
            n.symbol=text(e.args["systemImage"],reference:e.reference);n.showIcon = !n.symbol.isEmpty;n.actionTitle=text(e.args["_actionTitle"],reference:e.reference,localize:e.args["_localizeAction"] != nil);n.iconSize=44;n.fontSize=max(20,style.font)
            return SwiftImportBox(width:width,height:height ?? 210,nodes:[n])
        }
        guard e.type=="Menu" else{return nil}
        let label=e.children.first?.children ?? []
        let labelBox=layout(SwiftImportElement("HStack",children:label),width:width,height:height,style:style)
        let title=text(e.args["$0"],reference:e.reference,localize:e.args["_localizeTitle"] != nil)
        let labelNode=labelBox.nodes.first{[.text,.iconLabel].contains($0.kind)}
        let icon=labelBox.nodes.first{[.icon,.iconLabel,.image].contains($0.kind)}
        let w=min(width,max(44,title.isEmpty ? labelBox.width:Double(title.count)*style.font+24)),h=height ?? max(32,labelBox.height)
        var n=node(e,kind:.menuButton,style:style,width:w,height:h)
        n.text=title.isEmpty ? labelNode?.text ?? "":title
        n.symbol=e.args["systemImage"].map{text($0,reference:e.reference)} ?? icon?.symbol ?? "ellipsis"
        n.iconData=icon?.imageData.isEmpty==false ? icon?.imageData:nil;n.iconSize=icon?.iconSize ?? style.font
        n.showIcon=icon != nil || e.args["systemImage"] != nil || n.text.isEmpty;n.showLabel = !n.text.isEmpty
        var items:[NavigationItem]=[]
        func visit(_ item:SwiftImportElement) {
            if item.type=="Button" || item.args["_buttonLabel"] != nil {
                let box=layout(item,width:width,style:style)
                let value=box.nodes.first{[.text,.button,.textButton,.iconLabel].contains($0.kind)}
                if let value,!value.text.isEmpty {let icon=box.nodes.first{[.icon,.iconLabel,.image].contains($0.kind)};var entry=NavigationItem(title:value.text,symbol:icon?.symbol ?? "");entry.iconData=icon?.iconData ?? (icon?.imageData.isEmpty==false ? icon?.imageData:nil);items.append(entry)}
                return
            }
            if item.type=="Menu"{builder.warn("嵌套菜单暂按平级项目导入",item.reference)}
            for child in item.children{visit(child)}
        }
        for item in e.children.dropFirst(){visit(item)}
        n.items=items
        if items.isEmpty{builder.warn("菜单项目来自运行时数据，需补充",e.reference)}
        return SwiftImportBox(width:w,height:h,nodes:[n])
    }
}
