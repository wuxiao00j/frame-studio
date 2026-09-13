import SwiftUI
import StudioCore

@MainActor struct FormControlPreview:View {
    let node:DesignNode
    let interactive:Bool
    @State private var text=""
    @State private var selected=0
    @State private var date=Date()
    @State private var calendar=false
    var index:Int {min(max(0,interactive ? selected:node.selectedIndex ?? 0),max(0,node.items.count-1))}
    var label:String {node.items.indices.contains(index) ? node.items[index].title:""}
    var body:some View {
        content.onAppear{selected=node.selectedIndex ?? 0;date=ExtraComponentPreview.date(node.dateValue)}
            .onChange(of:node.selectedIndex){_,v in selected=v ?? 0}
            .onChange(of:node.dateValue){_,v in date=ExtraComponentPreview.date(v)}
    }
    @ViewBuilder var content:some View {
        switch node.kind {
        case .selectField:
            HStack {Text(node.text);Spacer(minLength:12)
                if interactive {Menu {ForEach(Array(node.items.enumerated()),id:\.element.id){i,item in Button(item.title){selected=i}}} label:{choiceLabel}.menuStyle(.borderlessButton).fixedSize()}
                else{choiceLabel}
            }
        case .dateField:
            HStack {Text(node.text);Spacer(minLength:12);Button{if interactive{calendar=true}}label:{Text(dateLabel).padding(.horizontal,10).padding(.vertical,5).background(Color.black.opacity(0.05),in:Capsule())}.buttonStyle(.plain).popover(isPresented:$calendar){DatePicker("日期",selection:$date,displayedComponents:.date).datePickerStyle(.graphical).padding().frame(width:300)}}
        case .textArea:
            if interactive {TextField(node.text,text:$text,axis:.vertical).lineLimit(2...4).textFieldStyle(.plain).frame(maxWidth:.infinity,maxHeight:.infinity,alignment:.topLeading)}
            else{Text(node.text).foregroundStyle(Color(hex:node.foreground).opacity(0.3)).frame(maxWidth:.infinity,maxHeight:.infinity,alignment:.topLeading)}
        default:
            if interactive{TextField(node.text,text:$text).textFieldStyle(.plain)}
            else{Text(node.text).foregroundStyle(Color(hex:node.foreground).opacity(0.3)).frame(maxWidth:.infinity,alignment:.leading)}
        }
    }
    var choiceLabel:some View {HStack(spacing:4){Text(label);Image(systemName:"chevron.up.chevron.down").font(.system(size:10))}.foregroundStyle(Color(hex:node.foreground).opacity(0.55))}
    var dateLabel:String {
        let f=DateFormatter();f.locale=Locale(identifier:"zh_CN");f.dateFormat="yyyy年M月d日"
        return f.string(from:interactive ? date:ExtraComponentPreview.date(node.dateValue))
    }
}
