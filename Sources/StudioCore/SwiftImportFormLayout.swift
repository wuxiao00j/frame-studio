import Foundation

extension SwiftImportLayout {
    func form(_ e:SwiftImportElement,width:Double,height:Double?,style:SwiftImportStyle)->SwiftImportBox {
        var style=style;style.inForm=true
        var y=20.0,nodes:[DesignNode]=[]
        for entry in children(e.children) {
            var box=layout(entry.0,width:max(1,width-32),style:style)
            box.move(16,y);nodes+=box.nodes;y+=box.height+24
        }
        return SwiftImportBox(width:width,height:max(height ?? 0,y),nodes:nodes)
    }
    func section(_ e:SwiftImportElement,width:Double,style:SwiftImportStyle)->SwiftImportBox {
        var y=0.0,nodes:[DesignNode]=[]
        let title=text(e.args["$0"],reference:e.reference)
        if !title.isEmpty {
            var s=style;s.font=13;s.foreground="8E8E93"
            var n=node(e,kind:.text,style:s,width:max(1,width-32),height:20);n.id=e.id+"-heading";n.text=title
            n.frames["standardPortrait"]=Rect(16,0,max(1,width-32),20);nodes.append(n);y=30
        }
        let top=y,entries=children(e.children),fill=style.formRowFill
        for (i,entry) in entries.enumerated() {
            var box=layout(entry.0,width:max(1,width-32),style:style)
            let rowHeight=max(48,box.height+20)
            box.move(16,y+(rowHeight-box.height)/2);nodes+=box.nodes;y+=rowHeight
            if i<entries.count-1,fill != "FFFFFF00" {
                var line=node(e,kind:.divider,style:style,width:max(1,width-32),height:0.5);line.id=e.id+"-line\(i)";line.fill="E5E5EA";line.frames["standardPortrait"]=Rect(16,y,max(1,width-32),1);nodes.append(line)
            }
        }
        if fill != "FFFFFF00",y>top {
            var bg=node(e,kind:.rectangle,style:style,width:width,height:y-top);bg.id=e.id+"-group";bg.name="表单分组背景";bg.fill=fill;bg.cornerRadius=24;bg.frames["standardPortrait"]=Rect(0,top,width,y-top);nodes.insert(bg,at:0)
        }
        return SwiftImportBox(width:width,height:y,nodes:nodes)
    }
    func navigation(_ e:SwiftImportElement,width:Double,height:Double?,style:SwiftImportStyle)->SwiftImportBox? {
        var style=style
        var title:SwiftImportElement?,leading:[SwiftImportElement]=[],trailing:[SwiftImportElement]=[],background:String?,visible:Bool?
        func inspect(_ item:SwiftImportElement) {
            if item !== e, ["NavigationStack","NavigationView"].contains(item.type){return}
            if item.type==".navigationBarVisibility",visible==nil {let value=SwiftSourceSyntax.text(item.args["$0"] ?? []);if value==".hidden"{visible=false}else if value==".visible"{visible=true}}
            if item.type==".tint",let color=color(item.args["$0"]){style.accent=color}
            if item.type==".navigationTitle"{title=item}
            if item.type==".toolbarBackground",let c=color(item.args["$0"]){background=c}
            if item.type=="ToolbarItem" || item.type=="ToolbarItemGroup" {
                let placement=SwiftSourceSyntax.text(item.args["placement"] ?? [])
                if placement.contains("Leading") || placement.contains("cancellationAction"){leading+=item.children}
                else if placement.contains("Trailing") || placement.contains("confirmationAction"){trailing+=item.children}
                return
            }
            for c in item.children{inspect(c)}
        }
        inspect(e)
        guard visible != false else{return nil}
        guard title != nil || !leading.isEmpty || !trailing.isEmpty else{return nil}
        var nodes:[DesignNode]=[],y=0.0
        for child in e.children {var b=layout(child,width:width,height:height.map{max(1,$0-44)},style:style);b.move(0,44);y=max(y,b.height+44)
            for i in b.nodes.indices where b.nodes[i].backgroundLayer==true {var r=rect(b.nodes[i]);r.y=0;r.height=max(r.height,height ?? 0);b.nodes[i].frames["standardPortrait"]=r}
            nodes+=b.nodes
        }
        var bg=node(e,kind:.rectangle,style:style,width:width,height:44);bg.id=e.id+"-navbg";bg.fill=background ?? "FFFFFFF0";bg.fixedToViewport=true;bg.name="导航背景";nodes.append(bg)
        if let title {
            var s=style;s.font=17;s.weight="semibold";s.alignment="center"
            var n=node(title,kind:.text,style:s,width:max(1,width-160),height:44);n.text=text(title.args["$0"],reference:title.reference);n.frames["standardPortrait"]=Rect(80,0,max(1,width-160),44);n.fixedToViewport=true;nodes.append(n)
        }
        for (items,isLeading) in [(leading,true),(trailing,false)] {
            var x=isLeading ? 16.0:width-80
            for item in items {
                var b=layout(item,width:64,height:44,style:style)
                b.move(x,(44-b.height)/2)
                for i in b.nodes.indices{b.nodes[i].fixedToViewport=true;if b.nodes[i].kind == .button{b.nodes[i].kind = .textButton;b.nodes[i].showIcon=false};b.nodes[i].foreground=style.accent}
                nodes+=b.nodes;x+=b.width+8
            }
        }
        return SwiftImportBox(width:width,height:max(height ?? 0,y),nodes:nodes)
    }
}
