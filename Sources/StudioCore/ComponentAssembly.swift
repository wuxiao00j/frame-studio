import Foundation

public enum ComponentAssembly {
    public static func instantiate(_ template:ComponentTemplate,origin:Rect,variant:Variant,device:DeviceProfile,pages:Set<String>)->[DesignNode] {
        let group=UUID().uuidString
        var nodes=template.nodes
        let rowGroups=Dictionary(uniqueKeysWithValues:Set(nodes.compactMap(\.rowGroupID)).map{($0,UUID().uuidString)})
        for v in Variant.allCases {
            let frames=nodes.map{$0.frame(v,device:device)}
            let visible=nodes.indices.filter{nodes[$0].isVisible(in:v)}
            let x=visible.map{frames[$0].x}.min() ?? 0,y=visible.map{frames[$0].y}.min() ?? 0
            for i in nodes.indices {var r=frames[i];r.x += origin.x-x;r.y += (v==variant ? origin.y : 120)-y;nodes[i].frames[v.rawValue]=r}
        }
        for i in nodes.indices {
            nodes[i].id=UUID().uuidString;nodes[i].groupID=group
            nodes[i].rowGroupID=nodes[i].rowGroupID.flatMap{rowGroups[$0]}
            if !pages.contains(nodes[i].targetPageID){nodes[i].targetPageID=""}
            nodes[i].items=nodes[i].items.map{var item=$0;item.id=UUID().uuidString;if !pages.contains(item.pageID){item.pageID=""};return item}
        }
        return nodes
    }
    public static func decompose(_ source:DesignNode,device:DeviceProfile)->[DesignNode] {
        guard source.kind.decomposable else{return [source]}
        var result:[DesignNode]=[]
        func add(_ kind:ComponentKind,_ name:String,_ text:String="",_ symbol:String="",font:Double?=nil,asset:String?=nil,action:String="",layout:(Rect)->Rect) {
            var node=DesignNode(kind:kind);node.name=name;node.text=text;node.symbol=symbol;node.fill="FFFFFF00";node.foreground=source.foreground;node.accent=source.accent;node.fontSize=font ?? source.fontSize;node.fontWeight=source.fontWeight;node.cornerRadius=0;node.padding=0;node.iconSize=source.iconSize;node.opacity=source.opacity;node.blurRadius=source.blurRadius;node.visibleVariants=source.visibleVariants;node.backgroundLayer=source.backgroundLayer;node.rotation=source.rotation;node.fixedToViewport=source.isFixed;node.targetPageID=action.isEmpty ? source.targetPageID:action;node.iconData=asset
            if kind == .rectangle {node.fill=source.fill;node.gradient=source.gradient;node.material=source.material;node.shadowColor=source.shadowColor;node.shadowX=source.shadowX;node.shadowY=source.shadowY;node.borderColor=source.borderColor;node.borderWidth=source.borderWidth;node.cornerRadius=source.cornerRadius;node.shadow=source.shadow;node.rowGroupID=source.rowGroupID}
            if kind == .avatar {node.imageData=source.imageData;node.avatarSize=source.avatarSize;node.cornerRadius=source.avatarSize/3;node.fill=source.accent+"22"}
            if kind == .switchControl {node.isOn=source.isOn;node.showLabel=false}
            for variant in Variant.allCases {
                let r=source.frame(variant,device:device),local=layout(r),angle=source.rotation * .pi/180
                let dx=local.midX-r.width/2,dy=local.midY-r.height/2
                let cx=r.midX+dx*cos(angle)-dy*sin(angle),cy=r.midY+dx*sin(angle)+dy*cos(angle)
                node.frames[variant.rawValue]=Rect(cx-local.width/2,cy-local.height/2,local.width,local.height)
            }
            if source.clipMasks != nil {
                node.clipMasks=[:]
                for variant in Variant.allCases {
                    let r=source.frame(variant,device:device),local=layout(r)
                    node.clipMasks?[variant.rawValue]=source.masks(in:variant).map{m in
                        DesignClipMask(shape:m.shape,rect:Rect((m.rect.x*r.width-local.x)/local.width,(m.rect.y*r.height-local.y)/local.height,m.rect.width*r.width/local.width,m.rect.height*r.height/local.height),radius:m.radius*min(r.width,r.height)/min(local.width,local.height))
                    }
                }
            }
            result.append(node)
        }
        add(.rectangle,source.name+" · 背景"){Rect(0,0,$0.width,$0.height)}
        let pad=source.padding,gap=source.spacing,icon=source.iconSize
        switch source.kind {
        case .profileRow:
            let avatar=source.avatarSize
            add(.avatar,"头像","",source.symbol){Rect(pad,($0.height-avatar)/2,avatar,avatar)}
            let end=(source.hasQRCode ? 24.0+gap:0)+(source.hasChevron ? 16.0+gap:0)
            add(.text,"昵称",source.text,font:source.fontSize){Rect(pad+avatar+gap,$0.height/2-24,max(1,$0.width-pad*2-avatar-gap-end),24)}
            add(.text,"账号 / 副标题",source.subtitle,font:max(10,source.fontSize-3)){Rect(pad+avatar+gap,$0.height/2+5,max(1,$0.width-pad*2-avatar-gap-end),22)}
            if source.hasQRCode {add(.qrCode,"二维码","","qrcode",asset:source.qrIconData){Rect($0.width-pad-(source.hasChevron ? 16+gap:0)-24,($0.height-24)/2,24,24)}}
            if source.hasChevron {add(.chevron,"右箭头","","chevron.right",asset:source.chevronIconData,action:source.targetPageID){Rect($0.width-pad-16,($0.height-24)/2,16,24)}}
        case .listRow,.alertBanner,.iconLabel:
            let left=pad+(source.hasIcon ? icon+gap:0),end=source.hasChevron && source.kind == .listRow ? 16+gap:0
            if source.hasIcon {add(.icon,"前置图标","",source.symbol,asset:source.iconData){Rect(pad,($0.height-icon)/2,icon,icon)}}
            add(.text,"标题",source.text){Rect(left,source.subtitle.isEmpty ? ($0.height-26)/2 : $0.height/2-23,max(1,$0.width-left-pad-end),26)}
            if !source.subtitle.isEmpty {add(.text,"副标题",source.subtitle,font:max(10,source.fontSize-4)){Rect(left,$0.height/2+5,max(1,$0.width-left-pad-end),22)}}
            if end>0 {add(.chevron,"右箭头","","chevron.right",asset:source.chevronIconData,action:source.targetPageID){Rect($0.width-pad-16,($0.height-24)/2,16,24)}}
        case .toggle:
            let leading=source.position=="leading"
            add(.switchControl,"开关"){Rect(leading ? pad : $0.width-pad-54,($0.height-32)/2,54,32)}
            let left=leading ? pad+54+gap : pad
            if source.hasIcon {add(.icon,"前置图标","",source.symbol,asset:source.iconData){Rect(left,($0.height-icon)/2,icon,icon)}}
            if source.hasLabel {add(.text,"开关文字",source.text){Rect(left+(source.hasIcon ? icon+gap:0),($0.height-28)/2,max(1,$0.width-pad*2-54-gap-(source.hasIcon ? icon+gap:0)),28)}}
        case .button,.outlinedButton,.textButton:
            // Retain the action on a text-only button; the icon remains separately editable.
            add(.textButton,"按钮文字",source.text,action:source.targetPageID){Rect(pad,0,max(1,$0.width-pad*2),$0.height)}
            if source.hasIcon {add(.icon,"按钮图标","",source.symbol,asset:source.iconData){Rect(pad,($0.height-icon)/2,icon,icon)}}
        case .navigationBar:
            add(source.navigationAction=="back" ? .backButton:.iconButton,"左侧按钮","",source.symbol,asset:source.iconData){Rect(pad,0,44,$0.height)}
            add(.text,"页面标题",source.text){Rect(pad+44,0,max(1,$0.width-pad*2-88),$0.height)}
            add(.icon,"右侧图标","",source.trailingSymbol ?? "square.and.pencil",asset:source.trailingIconData,action:source.targetPageID){Rect($0.width-pad-44,0,44,$0.height)}
        case .tabBar,.sidebar:
            for (index,item) in source.items.enumerated() {
                if source.kind == .tabBar {
                    add(.icon,item.title+" · 图标","",item.symbol,asset:item.iconData,action:item.pageID){r in let width=r.width/Double(max(1,source.items.count));return Rect(Double(index)*width+(width-icon)/2,8,icon,icon)}
                    add(.textButton,item.title,item.title,action:item.pageID){r in let width=r.width/Double(max(1,source.items.count));return Rect(Double(index)*width,icon+12,width,max(12,r.height-icon-12))}
                }else {
                    add(.iconLabel,item.title,item.title,item.symbol,asset:item.iconData,action:item.pageID){Rect(pad,54+Double(index)*52,max(1,$0.width-pad*2),44)}
                }
            }
        case .card,.statistic:
            if source.hasIcon {add(.icon,"图标","",source.symbol,asset:source.iconData){_ in Rect(pad,pad,icon+6,icon+6)}}
            add(.text,"标题",source.text,font:source.kind == .statistic ? 13:source.fontSize){Rect(pad,$0.height-64,max(1,$0.width-pad*2),28)}
            add(.text,"副标题 / 数值",source.subtitle,font:source.kind == .statistic ? source.fontSize:max(11,source.fontSize-5)){Rect(pad,$0.height-34,max(1,$0.width-pad*2),28)}
        default:break
        }
        return result
    }
}
