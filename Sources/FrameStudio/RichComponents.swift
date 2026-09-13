import SwiftUI
import StudioCore

@MainActor struct UploadedIcon:View {
    let data:String?
    let symbol:String
    let size:Double
    var body:some View {
        if let image=PreviewImages.image(data) {Image(nsImage:image).resizable().scaledToFit().frame(width:size,height:size)}
        else {Image(systemName:symbol).font(.system(size:size)).frame(width:size,height:size)}
    }
}
@MainActor struct DetailedProgress:View {
    let node:DesignNode
    var body:some View {
        let thickness=node.progressThickness ?? 6
        let track=Color(hex:node.trackColor ?? "E5E2ED")
        let accent=Color(hex:node.accent)
        if node.progressMode == "circular" {
            ZStack {
                Circle().stroke(track,lineWidth:thickness)
                Circle().trim(from:0,to:node.fraction).stroke(accent,style:StrokeStyle(lineWidth:thickness,lineCap:.round)).rotationEffect(.degrees(-90))
                if !node.progressText.isEmpty {Text(node.progressText).font(.system(size:node.fontSize,weight:.medium)).minimumScaleFactor(0.5).lineLimit(1).padding(thickness+2)}
            }.padding(thickness/2+2).aspectRatio(1,contentMode:.fit).frame(maxWidth:.infinity,maxHeight:.infinity)
        }else {
            VStack(spacing:4) {
                if !node.progressText.isEmpty {Text(node.progressText).font(.system(size:min(14,node.fontSize))).frame(maxWidth:.infinity,alignment:.trailing)}
                if node.progressMode == "steps" {
                    HStack(spacing:4) {ForEach(0..<(node.progressSteps ?? 5),id:\.self){i in Capsule().fill(Double(i)<node.fraction*Double(node.progressSteps ?? 5) ? accent:track)}}.frame(height:thickness)
                }else {
                    GeometryReader { proxy in ZStack(alignment:.leading){Capsule().fill(track);Capsule().fill(accent).frame(width:proxy.size.width*node.fraction)}}.frame(height:thickness)
                }
            }.frame(maxWidth:.infinity,maxHeight:.infinity).padding(.horizontal,2)
        }
    }
}
@MainActor struct DetailedSwitch:View {
    let node:DesignNode
    var interactive=false
    @Binding var isOn:Bool
    var body:some View {
        HStack(spacing:node.spacing) {
            if node.position=="leading" {control}
            if node.hasIcon {UploadedIcon(data:node.iconData,symbol:node.symbol,size:node.iconSize).foregroundStyle(Color(hex:node.accent))}
            if node.hasLabel {Text(node.text)}
            Spacer(minLength:0)
            if node.position != "leading" {control}
        }.padding(.horizontal,node.padding)
    }
    @ViewBuilder var control:some View {
        if interactive {Toggle("",isOn:$isOn).toggleStyle(.switch).labelsHidden().fixedSize().tint(Color(hex:node.accent))}
        else {Capsule().fill(isOn ? Color(hex:node.accent):Color(hex:"E4E4E9"))
            .overlay(alignment:isOn ? .trailing:.leading){Circle().fill(.white).frame(width:27,height:27).padding(2).shadow(color:.black.opacity(0.08),radius:1,y:1)}
            .frame(width:51,height:31).accessibilityLabel(node.text).accessibilityValue(isOn ? "开启":"关闭")}
    }
}
@MainActor struct ExtraComponentPreview:View {
    let node:DesignNode
    let interactive:Bool
    let navigate:(String)->Void
    @State private var checked=false
    @State private var number=1.0
    @State private var text=""
    @State private var selection=""
    @State private var date=Date()
    var body:some View {
        content.onAppear{checked=node.isOn;number=node.number;selection=node.items.indices.contains(node.selectedIndex ?? 0) ? node.items[node.selectedIndex ?? 0].id:"";date=Self.date(node.dateValue)}
            .onChange(of:node.number){_,v in number=v}.onChange(of:node.isOn){_,v in checked=v}
            .onChange(of:node.dateValue){_,v in date=Self.date(v)}
            .onChange(of:node.selectedIndex){_,v in selection=node.items.indices.contains(v ?? 0) ? node.items[v ?? 0].id:""}
    }
    @ViewBuilder var content:some View {
        switch node.kind {
        case .backButton:Button{navigate("__back")}label:{HStack(spacing:node.spacing){glyph; if node.hasLabel {Text(node.text)}}.frame(maxWidth:.infinity,maxHeight:.infinity)}.buttonStyle(.plain)
        case .iconLabel,.textButton,.outlinedButton:Button{navigate(node.navigationAction=="back" ? "__back":node.targetPageID)}label:{HStack(spacing:node.spacing){if node.hasIcon{glyph};if node.hasLabel{Text(node.text)}}.frame(maxWidth:.infinity,maxHeight:.infinity)}.buttonStyle(.plain)
        case .checkbox,.radio:
            HStack(spacing:node.spacing){if node.position=="leading"{choice};if node.hasIcon{glyph};if node.hasLabel{Text(node.text)};Spacer(minLength:0);if node.position != "leading"{choice}}.padding(.horizontal,node.padding)
        case .stepper:Stepper(value:interactive ? $number:.constant(node.number),in:node.minimum...node.maximum,step:node.step){Text("\(node.text)  \(DesignNode.displayNumber(interactive ? number:node.number))")}.padding(.horizontal,node.padding)
        case .secureField:HStack(spacing:node.spacing){if node.hasIcon{glyph};SecureField(node.text,text:interactive ? $text:.constant("")).textFieldStyle(.plain)}.padding(.horizontal,node.padding)
        case .textArea:TextField(node.text,text:interactive ? $text:.constant(""),axis:.vertical).lineLimit(3...10).textFieldStyle(.plain).padding(node.padding)
        case .selectField:Picker(node.text,selection:$selection){ForEach(node.items){Text($0.title).tag($0.id)}}.padding(.horizontal,node.padding)
        case .dateField:DatePicker(node.text,selection:interactive ? $date:.constant(Self.date(node.dateValue)),displayedComponents:.date).padding(.horizontal,node.padding)
        case .rating:HStack(spacing:node.spacing){ForEach(1...max(1,Int(node.maximum)),id:\.self){i in Button{if interactive{number=Double(i)}}label:{Image(systemName:Double(i)<=(interactive ? number:node.number) ? "star.fill":"star").font(.system(size:node.iconSize)).foregroundStyle(Color(hex:node.accent))}.buttonStyle(.plain)}}.frame(maxWidth:.infinity,maxHeight:.infinity)
        case .loading:ProgressView().controlSize(.small).frame(maxWidth:.infinity,maxHeight:.infinity)
        case .rectangle:Rectangle().fill(node.paintStyle)
        case .circle:Circle().fill(node.paintStyle)
        case .spacer:Color.clear
        case .statistic:VStack(alignment:.leading,spacing:8){HStack{if node.hasIcon{glyph};Text(node.text).font(.system(size:13))};Text(node.subtitle).font(.system(size:node.fontSize,weight:.semibold))}.padding(node.padding).frame(maxWidth:.infinity,alignment:.leading)
        case .alertBanner:HStack(spacing:node.spacing){if node.hasIcon{glyph};VStack(alignment:.leading,spacing:4){Text(node.text).fontWeight(.medium);Text(node.subtitle).font(.system(size:max(10,node.fontSize-3))).opacity(0.6)}}.padding(.horizontal,node.padding)
        case .qrCode,.chevron:glyph.frame(maxWidth:.infinity,maxHeight:.infinity).onTapGesture{if interactive{navigate(node.targetPageID)}}
        case .switchControl:DetailedSwitch(node:node,interactive:interactive,isOn:interactive ? $checked:.constant(node.isOn))
        case .ringProgress:DetailedProgress(node:node)
        default:EmptyView()
        }
    }
    var glyph:some View {UploadedIcon(data:node.iconData,symbol:node.symbol,size:node.iconSize).foregroundStyle(Color(hex:node.foreground))}
    var choice:some View {Button{if interactive{checked.toggle()}}label:{Image(systemName:node.kind == .radio ? (checked ? "largecircle.fill.circle":"circle") : (checked ? "checkmark.square.fill":"square")).font(.system(size:node.iconSize)).foregroundStyle(Color(hex:node.accent))}.buttonStyle(.plain)}
    static func date(_ value:String?)->Date {let f=DateFormatter();f.dateFormat="yyyy-MM-dd";return f.date(from:value ?? "2026-01-01") ?? Date(timeIntervalSince1970:0)}
}

@MainActor enum PreviewImages {
    static let cache:NSCache<NSString,NSImage> = {let cache=NSCache<NSString,NSImage>();cache.totalCostLimit=64*1024*1024;cache.countLimit=96;return cache}()
    static func image(_ raw:String?)->NSImage? {
        guard let raw,!raw.isEmpty else{return nil};let key=raw as NSString
        if let image=cache.object(forKey:key){return image}
        guard let data=Data(base64Encoded:raw),let image=NSImage(data:data) else{return nil}
        cache.setObject(image,forKey:key,cost:data.count);return image
    }
}
