import Foundation
import AppKit

struct SwiftImportStyle {
    var font:Double=17
    var weight="regular"
    var foreground="222222"
    var accent="007AFF"
    var alignment="leading"
    var lineSpacing:Double=0
    var lineLimit:Int?
    var minimumScaleFactor:Double=1
}
struct SwiftImportBox {
    var width:Double
    var height:Double
    var nodes:[DesignNode]=[]
    mutating func move(_ x:Double,_ y:Double) {
        for i in nodes.indices {var r=nodes[i].frames[Variant.standardPortrait.rawValue]!;r.x+=x;r.y+=y;nodes[i].frames[Variant.standardPortrait.rawValue]=r}
    }
}
final class SwiftImportLayout {
    let builder:SwiftViewBuilder
    let assets:[URL]
    var imageCache:[String:String]=[:]
    init(builder:SwiftViewBuilder,assets:[URL]){self.builder=builder;self.assets=assets}
    func resolved(_ tokens:[SwiftToken],depth:Int=0)->[SwiftToken] {
        let t=SwiftSourceSyntax.compact(tokens),key=SwiftSourceSyntax.text(tokens)
        if let color=builder.options.colors[key]{return SwiftSourceSyntax.tokens("Color(hex:\"\(color)\")")}
        if depth<12,let value=builder.index.constants[key],SwiftSourceSyntax.text(value) != key{return resolved(value,depth:depth+1)}
        return t
    }
    func number(_ tokens:[SwiftToken]?)->Double? {
        guard let tokens else{return nil}
        let t=resolved(tokens)
        if let n=Double(SwiftSourceSyntax.text(t)),n.isFinite{return n}
        return nil
    }
    func text(_ tokens:[SwiftToken]?,reference:String="")->String {
        guard let tokens,!tokens.isEmpty else{return ""}
        let t=resolved(tokens)
        if let string=t.first(where:{$0.string}),let value=SwiftSourceSyntax.literal(string) {
            if t.contains(where:{$0.text=="?"}) || value.contains("…"){builder.warn("动态文案使用静态样例",reference)}
            return value
        }
        let key=SwiftSourceSyntax.text(t)
        if key=="nil"{return ""}
        if !reference.isEmpty{builder.warn("运行时文案待补充：\(String(key.prefix(60)))",reference)}
        return "〈\(String(key.prefix(32)))〉"
    }
    func arguments(_ t:[SwiftToken])->[String:[SwiftToken]] {
        guard let open=t.firstIndex(where:{$0.text=="("}) else{return [:]}
        return SwiftSourceSyntax.arguments(Array(t[(open+1)..<SwiftSourceSyntax.end(t,open)]))
    }
    func color(_ tokens:[SwiftToken]?,depth:Int=0)->String? {
        guard let tokens,depth<12 else{return nil}
        let t=resolved(tokens),key=SwiftSourceSyntax.text(t)
        if let i=t.indices.last(where:{t[$0].text=="opacity"}),i>0,i+1<t.count {
            let base=Array(t.prefix(i-1)),args=arguments(Array(t.dropFirst(i)))
            if let rgb=color(base,depth:depth+1),let opacity=number(args["$0"]){return String(rgb.prefix(6))+String(format:"%02X",Int(max(0,min(1,opacity))*Double(rgb.count==8 ? (Int(rgb.suffix(2),radix:16) ?? 255):255)))}
            return nil
        }
        let named=["clear":"FFFFFF00","white":"FFFFFF","black":"000000","red":"FF3B30","orange":"FF9500","yellow":"FFCC00","green":"34C759","blue":"007AFF","purple":"AF52DE","pink":"FF2D55","gray":"8E8E93","primary":"222222","secondary":"777777","label":"222222","secondaryLabel":"777777","systemBackground":"FFFFFF","secondarySystemBackground":"F2F2F7"]
        if key.hasPrefix("Color(") || key.hasPrefix("AnyShapeStyle(") {
            let a=arguments(t)
            if let r=number(a["red"]),let g=number(a["green"]),let b=number(a["blue"]) {return [r,g,b].map{String(format:"%02X",Int(max(0,min(1,$0))*255))}.joined()}
            if let hex=a["hex"],let raw=hex.first.flatMap(SwiftSourceSyntax.literal),[6,8].contains(raw.replacingOccurrences(of:"#",with:"").count){return raw.replacingOccurrences(of:"#",with:"")}
            return color(a["uiColor"] ?? a["nsColor"] ?? a["$0"] ?? [],depth:depth+1)
        }
        if let name=key.split(separator:".").last,let c=named[String(name)],key.hasPrefix(".") || key.hasPrefix("Color."){return c}
        return nil
    }
    func font(_ t:[SwiftToken],_ style:inout SwiftImportStyle) {
        let key=SwiftSourceSyntax.text(t),a=arguments(t)
        if let size=number(a["size"]){style.font=max(1,min(300,size))}
        else {
            let sizes=["largeTitle":34.0,"title":28,"title2":22,"title3":20,"headline":17,"body":17,"callout":16,"subheadline":15,"footnote":13,"caption":12,"caption2":11]
            for (name,size) in sizes where key=="."+name || key.hasPrefix("."+name+"."){style.font=size}
        }
        if key.contains("semibold"){style.weight="semibold"}else if key.contains("bold"){style.weight="bold"}else if key.contains("medium"){style.weight="medium"}
    }
    func rect(_ node:DesignNode)->Rect{node.frames[Variant.standardPortrait.rawValue]!}
    func node(_ element:SwiftImportElement,kind:ComponentKind,style:SwiftImportStyle,width:Double,height:Double)->DesignNode {
        var n=DesignNode(kind:kind,frame:Rect(0,0,max(1,width),max(1,height)))
        n.id=element.id;n.name=kind.title+" · "+element.type;n.sourceReference=element.reference+" · "+element.type
        n.fontSize=style.font;n.fontWeight=style.weight;n.foreground=style.foreground;n.accent=style.accent
        n.textAlignment=style.alignment;n.padding=0;n.cornerRadius=0;n.fill="FFFFFF00";n.fixedToViewport=element.pinned;n.backgroundLayer=element.pinned
        if kind == .text {n.lineLimit=style.lineLimit;n.lineSpacing=style.lineSpacing;n.minimumScaleFactor=style.minimumScaleFactor}
        return n
    }
    func layout(_ e:SwiftImportElement,width:Double,height:Double?=nil,style:SwiftImportStyle=SwiftImportStyle())->SwiftImportBox {
        let width=max(1,min(3000,width)),args=e.args
        var style=style
        if e.type.hasPrefix(".") {
            guard let child=e.children.first else{return SwiftImportBox(width:0,height:0)}
            switch e.type {
            case ".font":font(args["$0"] ?? [],&style);return layout(child,width:width,height:height,style:style)
            case ".fontWeight":style.weight=SwiftSourceSyntax.text(args["$0"] ?? []).replacingOccurrences(of:".",with:"");return layout(child,width:width,height:height,style:style)
            case ".bold":style.weight="bold";return layout(child,width:width,height:height,style:style)
            case ".foregroundStyle",".foregroundColor",".tint":
                if let c=color(args["$0"]) {if e.type==".tint"{style.accent=c}else{style.foreground=c}}
                else{builder.warn("动态颜色未确定，保留可编辑默认色",e.reference)}
                return layout(child,width:width,height:height,style:style)
            case ".multilineTextAlignment":style.alignment=SwiftSourceSyntax.text(args["$0"] ?? []).replacingOccurrences(of:".",with:"");return layout(child,width:width,height:height,style:style)
            case ".padding":
                let first=SwiftSourceSyntax.text(args["$0"] ?? []),amount=max(0,min(500,number(args["$1"]) ?? number(args["$0"]) ?? 16))
                let all=first.isEmpty || number(args["$0"]) != nil || first==".all"
                let left=all || first.contains("horizontal") || first.contains("leading") ? amount:0
                let right=all || first.contains("horizontal") || first.contains("trailing") ? amount:0
                let top=all || first.contains("vertical") || first.contains("top") ? amount:0
                let bottom=all || first.contains("vertical") || first.contains("bottom") ? amount:0
                var box=layout(child,width:max(1,width-left-right),height:height.map{max(1,$0-top-bottom)},style:style);box.move(left,top);box.width+=left+right;box.height+=top+bottom;return box
            case ".frame":
                let fixedW=number(args["width"]),fixedH=number(args["height"])
                var box=layout(child,width:fixedW ?? width,height:fixedH ?? height,style:style)
                let w=max(number(args["minWidth"]) ?? 0,fixedW ?? (SwiftSourceSyntax.text(args["maxWidth"] ?? []).contains("infinity") ? width:box.width))
                let h=max(number(args["minHeight"]) ?? 0,fixedH ?? box.height)
                let a=SwiftSourceSyntax.text(args["alignment"] ?? [])
                box.move(a.contains("leading") || a.contains("Leading") ? 0 : a.contains("trailing") || a.contains("Trailing") ? w-box.width:(w-box.width)/2,a.contains("top") ? 0:a.contains("bottom") ? h-box.height:(h-box.height)/2)
                box.width=w;box.height=h;return box
            case ".offset",".position":
                var box=layout(child,width:width,height:height,style:style)
                let sizeArgs=arguments(args["$0"] ?? [])
                box.move((number(args["x"]) ?? number(sizeArgs["width"]) ?? 0)-(e.type==".position" ? box.width/2:0),(number(args["y"]) ?? number(sizeArgs["height"]) ?? 0)-(e.type==".position" ? box.height/2:0));return box
            case ".background",".overlay":
                var box=layout(child,width:width,height:height,style:style)
                var decoration:[DesignNode]=[]
                if let value=args["$0"] {
                    var background=node(e,kind:.rectangle,style:style,width:box.width,height:box.height)
                    paint(value,on:&background,reference:e.reference);background.name="背景";decoration=[background]
                }
                for element in e.children.dropFirst() {
                    var drawn=layout(element,width:max(1,box.width),height:box.height,style:style)
                    if drawn.nodes.count==1,let n=drawn.nodes.first,[.rectangle,.circle].contains(n.kind) {drawn.nodes[0].frames[Variant.standardPortrait.rawValue]=Rect(0,0,max(1,box.width),max(1,box.height))}
                    decoration+=drawn.nodes
                }
                box.nodes=e.type==".background" ? decoration+box.nodes:box.nodes+decoration;return box
            case ".clipShape",".cornerRadius",".clipped":
                var box=layout(child,width:width,height:height,style:style)
                let shape=args["$0"] ?? [],name=SwiftSourceSyntax.text(shape)
                guard e.type != ".clipShape" || ["Rectangle(","RoundedRectangle(","Circle(","Ellipse(","Capsule("].contains(where:{name.hasPrefix($0)}) else{builder.warn("自定义裁剪形状需要对照原界面调整",e.reference);return box}
                let radius=number(args["$0"]) ?? number(arguments(shape)["cornerRadius"]) ?? (name.contains("Capsule") ? min(box.width,box.height)/2:0)
                var bounds=Rect(0,0,max(1,box.width),max(1,box.height))
                if name.hasPrefix("Circle("){let d=min(bounds.width,bounds.height);bounds=Rect((bounds.width-d)/2,(bounds.height-d)/2,d,d)}
                let maskShape=name.hasPrefix("Circle(") || name.hasPrefix("Ellipse(") ? "ellipse":radius>0 ? "roundedRectangle":"rectangle"
                for i in box.nodes.indices {
                    let r=rect(box.nodes[i])
                    let mask=DesignClipMask(shape:maskShape,rect:Rect((bounds.x-r.x)/r.width,(bounds.y-r.y)/r.height,bounds.width/r.width,bounds.height/r.height),radius:radius/min(r.width,r.height))
                    var masks=box.nodes[i].clipMasks?[Variant.standardPortrait.rawValue] ?? []
                    if masks.count<32{masks.append(mask)}else{builder.warn("裁剪嵌套超过 32 层，需人工简化",e.reference)}
                    box.nodes[i].clipMasks=[Variant.standardPortrait.rawValue:masks]
                    if maskShape != "ellipse",[.rectangle,.circle,.image,.avatar,.button].contains(box.nodes[i].kind),abs(r.width-box.width)<1,abs(r.height-box.height)<1,abs(r.x)<1,abs(r.y)<1{box.nodes[i].cornerRadius=max(0,min(500,radius))}
                };return box
            case ".fill",".stroke",".strokeBorder":
                var box=layout(child,width:width,height:height,style:style)
                let c=color(args["$0"]) ?? (args["$0"]==nil ? style.foreground:"F2F2F7")
                if args["$0"] != nil && color(args["$0"])==nil && gradient(args["$0"])==nil && material(args["$0"])==nil{builder.warn("动态填充色未确定，使用中性占位色",e.reference)}
                for i in box.nodes.indices {
                    if e.type==".fill" {paint(args["$0"],on:&box.nodes[i],reference:e.reference)}else{box.nodes[i].fill="FFFFFF00";box.nodes[i].gradient=nil;box.nodes[i].material=nil;box.nodes[i].borderColor=c;box.nodes[i].borderWidth=max(0,min(100,number(args["lineWidth"]) ?? 1))}
                };return box
            case ".opacity":var box=layout(child,width:width,height:height,style:style);for i in box.nodes.indices{box.nodes[i].opacity*=max(0,min(1,number(args["$0"]) ?? 1))};return box
            case ".shadow":
                var box=layout(child,width:width,height:height,style:style)
                if !box.nodes.isEmpty{box.nodes[0].shadow=max(0,min(100,number(args["radius"]) ?? 0));box.nodes[0].shadowColor=color(args["color"]);box.nodes[0].shadowX=number(args["x"]) ?? 0;box.nodes[0].shadowY=number(args["y"]) ?? 0};return box
            case ".blur":var box=layout(child,width:width,height:height,style:style);for i in box.nodes.indices{box.nodes[i].blurRadius=max(0,min(500,number(args["radius"]) ?? 0))};return box
            case ".lineSpacing":style.lineSpacing=max(0,min(500,number(args["$0"]) ?? 0));return layout(child,width:width,height:height,style:style)
            case ".lineLimit":style.lineLimit=number(args["$0"]).map{Int(max(1,min(1000,$0)))};return layout(child,width:width,height:height,style:style)
            case ".minimumScaleFactor":style.minimumScaleFactor=max(0.1,min(1,number(args["$0"]) ?? 1));return layout(child,width:width,height:height,style:style)
            case ".scaledToFit",".scaledToFill",".resizable",".aspectRatio":
                var box=layout(child,width:width,height:height,style:style)
                let mode=SwiftSourceSyntax.text(args["contentMode"] ?? [])
                let fit=e.type==".scaledToFit" || mode==".fit" ? "fit":e.type==".resizable" ? "stretch":"fill"
                for i in box.nodes.indices where box.nodes[i].kind == .image {box.nodes[i].imageFit=fit;if let height{var r=rect(box.nodes[i]);r.width=width;r.height=height;box.nodes[i].frames[Variant.standardPortrait.rawValue]=r;box.width=width;box.height=height}}
                return box
            case ".fixedSize", ".layoutPriority":return layout(child,width:width,height:height,style:style)
            case ".buttonStyle":
                var box=layout(child,width:width,height:height,style:style)
                let key=SwiftSourceSyntax.text(args["$0"] ?? [])
                if key.contains("bordered") {
                    for i in box.nodes.indices where box.nodes[i].kind == .button {
                        box.nodes[i].cornerRadius=8
                        box.nodes[i].fill=key.contains("Prominent") ? style.accent:"EEEEEE"
                        box.nodes[i].foreground=key.contains("Prominent") ? "FFFFFF":style.accent
                    }
                }else if key != ".plain" && key != ".automatic"{builder.warn("按钮样式需要对照原界面调整",e.reference)}
                return box
            default:return layout(child,width:width,height:height,style:style)
            }
        }
        if e.type=="FlowLayout" {
            let spacing=number(args["spacing"]) ?? 8,rowSpacing=number(args["rowSpacing"]) ?? spacing
            var x=0.0,y=0.0,rowHeight=0.0,nodes:[DesignNode]=[]
            for entry in children(e.children) {
                var box=layout(entry.0,width:width,style:style)
                if !entry.1.isEmpty{for i in box.nodes.indices{box.nodes[i].groupID=entry.1}}
                if x>0 && x+box.width>width {x=0;y+=rowHeight+rowSpacing;rowHeight=0}
                box.move(x,y);nodes+=box.nodes;x+=box.width+spacing;rowHeight=max(rowHeight,box.height)
            }
            return SwiftImportBox(width:width,height:y+rowHeight,nodes:nodes)
        }
        if e.type=="ViewThatFits" {
            let selected=e.children.first{idealWidth($0,style:style)<=width} ?? e.children.last
            return selected.map{layout($0,width:width,height:height,style:style)} ?? SwiftImportBox(width:0,height:0)
        }
        let vertical:Set<String>=["VStack","LazyVStack","ScrollView","ScrollViewReader","List","Form","Section","NavigationStack","NavigationView","GeometryReader","Group"]
        if vertical.contains(e.type) || ["HStack","LazyHStack","ZStack"].contains(e.type) {
            let horizontal=["HStack","LazyHStack"].contains(e.type),overlay=e.type=="ZStack"
            let transparent=["Group","NavigationStack","NavigationView","ScrollViewReader","GeometryReader"].contains(e.type)
            let entries=children(e.children)
            let spacing=max(0,min(500,number(args["spacing"]) ?? (transparent || e.type=="ScrollView" || overlay ? 0:8)))
            let gaps=spacing*Double(max(0,entries.count-1))
            var boxes=entries.map{layout($0.0,width:width,height:(transparent || overlay) ? height:nil,style:style)}
            if horizontal {
                let flexible=entries.indices.filter{expands(entries[$0].0)}
                let fixed=boxes.indices.filter{!flexible.contains($0)}.reduce(0.0){$0+boxes[$1].width}
                if !flexible.isEmpty {
                    let offered=max(1,(width-gaps-fixed)/Double(flexible.count))
                    for i in flexible {boxes[i]=entries[i].0.type=="Spacer" ? SwiftImportBox(width:offered,height:0):layout(entries[i].0,width:offered,style:style)}
                }else if boxes.reduce(0,{$0+$1.width})+gaps>width {
                    let share=max(1,(width-gaps)/Double(max(1,entries.count)))
                    let soft=entries.indices.filter{fixedWidth(entries[$0].0)==nil && idealWidth(entries[$0].0,style:style)>share}
                    let hard=boxes.indices.filter{!soft.contains($0)}.reduce(0.0){$0+boxes[$1].width}
                    let offered=max(1,(width-gaps-hard)/Double(max(1,soft.count)))
                    for i in soft{boxes[i]=layout(entries[i].0,width:offered,style:style)}
                }
            }
            let w=horizontal ? boxes.reduce(0){$0+$1.width}+gaps:(overlay ? width:boxes.map(\.width).max() ?? 0)
            let naturalH=horizontal || overlay ? boxes.map(\.height).max() ?? 0:boxes.reduce(0){$0+$1.height}+gaps
            let h=overlay ? (height ?? naturalH):e.type=="ScrollView" ? (height ?? naturalH):naturalH
            if overlay {boxes=entries.map{layout($0.0,width:w,height:h,style:style)}}
            let align=SwiftSourceSyntax.text(args["alignment"] ?? []);var cursor=0.0,nodes:[DesignNode]=[]
            for (i,measured) in boxes.enumerated() {
                var box=measured
                let x=horizontal ? cursor:(align.contains("leading") || align.contains("Leading") || transparent ? 0:align.contains("trailing") || align.contains("Trailing") ? w-box.width:(w-box.width)/2)
                let y=horizontal || overlay ? (align.contains("top") || align.contains("Top") ? 0:align.contains("bottom") || align.contains("Bottom") ? h-box.height:(h-box.height)/2):cursor
                box.move(x,y)
                if !entries[i].1.isEmpty {for j in box.nodes.indices{box.nodes[j].groupID=entries[i].1}}
                nodes+=box.nodes;cursor+=(horizontal ? box.width:box.height)+spacing
            }
            if !e.group.isEmpty {for i in nodes.indices{nodes[i].groupID=e.group}}
            return SwiftImportBox(width:w,height:h,nodes:nodes)
        }
        if e.type=="Spacer" {return SwiftImportBox(width:max(0,number(args["minLength"]) ?? 0),height:max(0,number(args["minLength"]) ?? 0))}
        let title=["Color","Rectangle","RoundedRectangle","Circle","Capsule","LinearGradient","RadialGradient"].contains(e.type) ? "":text(args["$0"] ?? args["title"],reference:e.reference)
        var kind=SwiftImporter.mappings[e.type] ?? .rectangle
        if e.type=="Image",args["systemName"] != nil {kind = .icon}
        if e.type=="ProgressView",args["value"]==nil {kind = .loading}
        if e.type=="Unresolved"{kind = .custom}
        var w=min(width,345),h=44.0
        if kind == .text {
            let f=NSFont.systemFont(ofSize:style.font,weight:style.weight=="bold" ? .bold:style.weight=="semibold" ? .semibold:style.weight=="medium" ? .medium:.regular)
            let paragraph=NSMutableParagraphStyle();paragraph.lineSpacing=style.lineSpacing;paragraph.lineBreakMode = .byWordWrapping
            let attributes:[NSAttributedString.Key:Any]=[.font:f,.paragraphStyle:paragraph]
            let natural=(title as NSString).size(withAttributes:attributes)
            w=max(1,min(width,ceil(natural.width)))
            // Include paragraph spacing in font measurement. A small leading
            // allowance avoids SwiftUI compressing a two-line fallback-font run.
            let measured=ceil((title as NSString).boundingRect(with:CGSize(width:w,height:10000),options:[.usesLineFragmentOrigin,.usesFontLeading],attributes:attributes).height)
            h=max(style.font*1.3,measured+max(2,ceil(measured/(style.font*1.25+style.lineSpacing))))
            if let limit=style.lineLimit{h=min(h,Double(limit)*(style.font*1.3+style.lineSpacing)+2)}
        }else if kind == .button {w=min(width,max(24,(title as NSString).size(withAttributes:[.font:NSFont.systemFont(ofSize:style.font)]).width+16));h=max(30,style.font*1.4)}
        else if kind == .icon {w=max(1,style.font);h=w}
        else if kind == .divider {h=1}
        else if kind == .circle {w=height.map{min(width,$0)} ?? min(width,60);h=w}
        else if kind == .rectangle {w=width;h=height ?? 60}
        else if kind == .image {h=160}
        else if kind == .custom {h=54}
        var n=node(e,kind:kind,style:style,width:w,height:h);n.text=title
        if kind == .button {n.showIcon=false;n.foreground=style.foreground=="222222" ? style.accent:style.foreground}
        if kind == .icon {n.symbol=text(args["systemName"],reference:e.reference);n.iconSize=max(1,min(500,style.font))}
        if kind == .iconLabel {n.text=text(args["$0"],reference:e.reference);n.symbol=text(args["systemImage"],reference:e.reference);n.iconSize=style.font}
        if [.icon,.iconLabel].contains(kind),NSImage(systemSymbolName:n.symbol,accessibilityDescription:nil)==nil {builder.warn("动态图标或当前系统未提供的符号：\(n.symbol)",e.reference);n.symbol="square.dashed"}
        if [.rectangle,.circle].contains(kind) {
            if e.type=="Color" {
                if let r=number(args["red"]),let g=number(args["green"]),let b=number(args["blue"]) {n.fill=[r,g,b].map{String(format:"%02X",Int(max(0,min(1,$0))*255))}.joined()}
                else {n.fill=color(args["$0"]) ?? "F7F7F7";if color(args["$0"])==nil{builder.warn("动态背景色未确定，使用中性占位色",e.reference)}}
            }else{n.fill=style.foreground}
            n.cornerRadius=number(args["cornerRadius"]) ?? (kind == .circle || e.type=="Capsule" ? min(w,h)/2:0)
            if e.type.contains("Gradient") {
                var source=SwiftSourceSyntax.tokens(e.type+"(")
                for (i,key) in args.keys.sorted().enumerated(){if i>0{source+=SwiftSourceSyntax.tokens(",")};source+=SwiftSourceSyntax.tokens(key+":");source+=args[key]!};source+=SwiftSourceSyntax.tokens(")")
                paint(source,on:&n,reference:e.reference)
            }
        }
        if kind == .custom {n.name="未匹配 · "+title;n.text="待还原："+title;n.customCode="Text(\(SwiftExporter.literal(n.text)))";n.borderWidth=1;n.borderColor="D8C99B";n.fill="FFF8E5"}
        if kind == .image {
            if let cached=imageCache[title]{n.imageData=cached}
            else if let asset=assets.first(where:{$0.deletingPathExtension().lastPathComponent==title || $0.deletingLastPathComponent().lastPathComponent==title+".imageset"}),let data=try? LocalImageAsset.readPNG(asset){n.imageData=data;imageCache[title]=data}
            if n.imageData.isEmpty{builder.warn("图片依赖运行时数据或未找到同名资源，保留图片占位",e.reference)}
        }
        if kind == .progress {n.progressCurrent=max(0,number(args["value"]) ?? 0.5);n.progressTotal=max(1,number(args["total"]) ?? 1)}
        if kind == .toggle {
            n.isOn=SwiftSourceSyntax.text(args["isOn"] ?? []).contains("false") ? false:true
            if n.text.isEmpty{n.text=e.children.flatMap{layout($0,width:width,style:style).nodes}.first(where:{$0.kind == .text})?.text ?? "〈开关标题〉"}
        }
        if e.type=="Picker" {
            let labels=e.children.flatMap{layout($0,width:width,style:style).nodes}.filter{$0.kind == .text}.map(\.text)
            n.items=(labels.isEmpty ? ["〈动态选项〉"]:labels).map{NavigationItem(title:$0,symbol:"")}
            if labels.isEmpty{builder.warn("选择器选项来自动态数据，需补充",e.reference)}
        }
        return SwiftImportBox(width:w,height:h,nodes:[n])
    }
}
