import Foundation

public enum TemplateCatalog {
    public static let categories=["表单与选择","导航与页头","列表与卡片","按钮与标签","背景与装饰","图片与媒体","其他组合"]
    public static func suggested(name:String,nodes:[DesignNode])->String {
        let name=name.lowercased(),kinds=Set(nodes.map(\.kind))
        if !kinds.isDisjoint(with:[.textField,.textArea,.secureField,.selectField,.dateField,.toggle,.checkbox,.radio,.switchControl,.stepper]) || ["picker","option","preference","cadence"].contains(where:name.contains){return categories[0]}
        if !kinds.isDisjoint(with:[.navigationBar,.tabBar,.sidebar,.backButton]) || ["header","hero"].contains(where:name.contains){return categories[1]}
        if ["background","atmosphere","swatch"].contains(where:name.contains){return categories[4]}
        if ["avatar","photo","image"].contains(where:name.contains){return categories[5]}
        if !kinds.isDisjoint(with:[.listRow,.card,.profileRow,.keyValueRow,.emptyState]) || ["card","row","section","slip"].contains(where:name.contains){return categories[2]}
        if !kinds.isDisjoint(with:[.button,.textButton,.iconButton,.badge]) || ["button","pill","label","tag","toast","menu","badge","capsule"].contains(where:name.contains){return categories[3]}
        return categories[6]
    }
    public static func portable(_ template:ComponentTemplate,device:DeviceProfile)->ComponentTemplate {
        var result=template;result.category=template.categoryTitle
        for i in result.nodes.indices {for variant in Variant.allCases{result.nodes[i].frames[variant.rawValue]=template.nodes[i].frame(variant,device:device)}}
        return result
    }
    public static let bundled:[ComponentTemplate] = {
        func node(_ kind:ComponentKind,_ text:String,_ frame:Rect)->DesignNode {
            var n=DesignNode(kind:kind,frame:frame);n.text=text;n.padding=0;n.fill="FFFFFF00";n.borderWidth=0;n.cornerRadius=0;n.fontSize=16
            for v in Variant.allCases{n.frames[v.rawValue]=frame};return n
        }
        var text=node(.textField,"名称",Rect(16,12,321,32));text.controlStyle="formRow"
        var date=node(.dateField,"日期",Rect(16,12,321,32));date.controlStyle="formRow"
        var choice=node(.selectField,"类型",Rect(16,12,321,32));choice.controlStyle="formRow";choice.items=[NavigationItem(title:"选项一",symbol:""),NavigationItem(title:"选项二",symbol:"")];choice.selectedIndex=0
        var note=node(.textArea,"补充说明（可选）",Rect(16,12,321,64));note.controlStyle="formRow"
        func card(_ height:Double)->DesignNode {var n=node(.rectangle,"",Rect(0,0,353,height));n.fill="FFFFFF";n.cornerRadius=20;return n}
        var first=node(.outlinedButton,"提醒一次",Rect(0,0,171,44));first.fill="F4F1FC";first.cornerRadius=14;first.borderWidth=1;first.showIcon=false
        var second=node(.outlinedButton,"重复提醒",Rect(181,0,172,44));second.fill="EAE4F8";second.cornerRadius=14;second.foreground="7560D4";second.showIcon=false
        var group=[card(56*3+88)]
        for (index,source) in [text,date,choice,note].enumerated(){var n=source;for v in Variant.allCases{var r=n.frames[v.rawValue]!;r.y+=Double(index)*56;n.frames[v.rawValue]=r};group.append(n)
            if index<3{var line=node(.divider,"",Rect(16,Double(index+1)*56,321,1));line.fill="E8E5F0";group.append(line)}
        }
        var cancel=node(.textButton,"取消",Rect(16,0,56,44));cancel.navigationAction="back";cancel.showIcon=false
        var title=node(.text,"新建内容",Rect(80,0,193,44));title.fontWeight="semibold";title.textAlignment="center"
        var save=node(.textButton,"保存",Rect(281,0,56,44));save.showIcon=false;save.isEnabled=false
        var nav=[card(44),cancel,title,save];for i in nav.indices{nav[i].fixedToViewport=true}
        let entries:[(String,String,String,[DesignNode])]=[
            ("form_text","手机表单 · 文本行",categories[0],[card(56),text]),
            ("form_date","手机表单 · 日期行",categories[0],[card(56),date]),
            ("form_choice","手机表单 · 选择行",categories[0],[card(56),choice]),
            ("form_note","手机表单 · 多行备注",categories[0],[card(88),note]),
            ("form_options","提醒方式 · 双选项",categories[0],[first,second]),
            ("form_group","手机表单 · 分组卡片",categories[0],group),
            ("form_navigation","弹窗导航 · 取消与保存",categories[1],nav)]
        return entries.map{id,name,category,nodes in var t=ComponentTemplate(name:name,nodes:nodes,category:category);t.id="builtin_"+id;return t}
    }()
}
public extension ComponentTemplate {
    var categoryTitle:String {
        let value=category?.trimmingCharacters(in:.whitespacesAndNewlines) ?? ""
        return value.isEmpty ? TemplateCatalog.suggested(name:name,nodes:nodes):value
    }
}
