import SwiftUI
import StudioCore

extension Color {
    init(hex:String) {
        let raw=hex.replacingOccurrences(of:"#",with:"");let n=UInt64(raw,radix:16) ?? 0
        if raw.count==8 {self.init(.sRGB,red:Double((n>>24)&255)/255,green:Double((n>>16)&255)/255,blue:Double((n>>8)&255)/255,opacity:Double(n&255)/255)}
        else {self.init(.sRGB,red:Double((n>>16)&255)/255,green:Double((n>>8)&255)/255,blue:Double(n&255)/255,opacity:1)}
    }
    var hex:String {guard let c=NSColor(self).usingColorSpace(.sRGB) else{return "000000"};let a=Int(c.alphaComponent*255);return String(format:a==255 ? "%02X%02X%02X" : "%02X%02X%02X%02X",Int(c.redComponent*255),Int(c.greenComponent*255),Int(c.blueComponent*255),a)}
}
let studioAccent=Color(hex:"7560D4")
let studioInk=Color(hex:"292638")
let studioMuted=Color(hex:"938DA6")
let studioLine=Color(hex:"EAE7F0")

@MainActor struct ComponentPreview: View {
    let node:DesignNode
    var corners:CornerRadii?
    var activePage=""
    var interactive=false
    var navigate:(String)->Void={_ in}
    var openSidebar:()->Void={}
    @State private var text=""
    @State private var toggle=true
    @State private var value=0.65
    @State private var segment=""
    var weight:Font.Weight {node.fontWeight=="bold" ? .bold : node.fontWeight=="semibold" ? .semibold : node.fontWeight=="medium" ? .medium : .regular}
    var alignment:Alignment {node.textAlignment=="center" ? .center : node.textAlignment=="trailing" ? .trailing : .leading}
    var body:some View {
        content
            .font(.system(size:node.fontSize,weight:weight))
            .foregroundStyle(Color(hex:node.foreground))
            .frame(maxWidth:.infinity,maxHeight:.infinity,alignment:alignment)
            .background(node.kind == .circle ? Color.clear:Color(hex:node.fill))
            .clipShape(shape)
            .overlay(shape.stroke(Color(hex:node.borderColor),lineWidth:node.borderWidth))
            .shadow(color:.black.opacity(node.shadow>0 ? 0.09 : 0),radius:node.shadow,y:node.shadow/3)
            .opacity(node.opacity)
            .rotationEffect(.degrees(node.rotation))
            .onTapGesture{if interactive && !node.targetPageID.isEmpty && [.text,.icon,.image,.avatar,.rectangle,.circle,.spacer,.qrCode,.chevron,.profileRow,.card,.statistic,.alertBanner].contains(node.kind){navigate(node.targetPageID)}}
            .onAppear{toggle=node.isOn;value=node.value}
            .onChange(of:node.isOn){_,v in toggle=v}
            .onChange(of:node.value){_,v in value=v}
    }
    @ViewBuilder var content:some View {
        switch node.kind {
        case .text: Text(node.text).multilineTextAlignment(node.textAlignment=="center" ? .center : node.textAlignment=="trailing" ? .trailing : .leading).frame(maxWidth:.infinity,alignment:alignment)
        case .icon: icon.frame(maxWidth:.infinity)
        case .iconButton: Button(action:openSidebar){icon.frame(maxWidth:.infinity,maxHeight:.infinity)}.buttonStyle(.plain)
        case .button: Button{navigate(node.targetPageID)}label:{HStack(spacing:node.spacing){if node.hasIcon{UploadedIcon(data:node.iconData,symbol:node.symbol,size:node.iconSize)};if node.hasLabel{Text(node.text)}}.frame(maxWidth:.infinity,maxHeight:.infinity)}.buttonStyle(.plain)
        case .image: media
        case .avatar: avatar
        case .profileRow: HStack(spacing:node.spacing){avatar.frame(width:node.avatarSize,height:node.avatarSize);VStack(alignment:.leading,spacing:8){Text(node.text).fontWeight(.semibold);Text(node.subtitle).font(.system(size:max(10,node.fontSize-3))).opacity(0.55)};Spacer(minLength:0);if node.hasQRCode{UploadedIcon(data:node.qrIconData,symbol:"qrcode",size:20).opacity(0.4)};if node.hasChevron{UploadedIcon(data:node.chevronIconData,symbol:"chevron.right",size:12).opacity(0.3)}}.padding(node.padding)
        case .navigationBar: HStack{Button{node.navigationAction=="back" ? navigate("__back"):openSidebar()}label:{UploadedIcon(data:node.iconData,symbol:node.symbol,size:node.iconSize)}.buttonStyle(.plain);Spacer();Text(node.text).fontWeight(.semibold);Spacer();Button{navigate(node.targetPageID)}label:{UploadedIcon(data:node.trailingIconData,symbol:node.trailingSymbol ?? "square.and.pencil",size:node.iconSize)}.buttonStyle(.plain)}.padding(.horizontal,node.padding)
        case .tabBar: HStack(spacing:0){ForEach(node.items){item in Button{navigate(item.pageID)}label:{VStack(spacing:6){UploadedIcon(data:item.pageID==activePage ? item.activeIconData:item.iconData,symbol:item.pageID==activePage ? item.activeSymbol:item.symbol,size:node.iconSize);Text(item.title).font(.system(size:node.fontSize))}.foregroundStyle(item.pageID==activePage ? Color(hex:node.accent) : Color(hex:node.foreground).opacity(0.5)).frame(maxWidth:.infinity,maxHeight:.infinity)}.buttonStyle(.plain)}}.padding(.horizontal,6)
        case .sidebar: VStack(alignment:.leading,spacing:node.spacing){Text(node.text).fontWeight(.semibold).padding(.bottom,12);ForEach(node.items){item in Button{navigate(item.pageID)}label:{HStack(spacing:12){UploadedIcon(data:item.pageID==activePage ? item.activeIconData:item.iconData,symbol:item.pageID==activePage ? item.activeSymbol:item.symbol,size:node.iconSize);Text(item.title);Spacer()}.padding(12).background(item.pageID==activePage ? Color(hex:node.accent).opacity(0.1) : .clear).clipShape(RoundedRectangle(cornerRadius:10))}.buttonStyle(.plain)};Spacer(minLength:0)}.padding(node.padding)
        case .listRow: Button{navigate(node.targetPageID)}label:{HStack(spacing:node.spacing){if node.hasIcon{UploadedIcon(data:node.iconData,symbol:node.symbol,size:node.iconSize).foregroundStyle(Color(hex:node.accent))};VStack(alignment:.leading,spacing:5){Text(node.text);if !node.subtitle.isEmpty{Text(node.subtitle).font(.system(size:max(10,node.fontSize-4))).opacity(0.45)}};Spacer(minLength:0);if node.hasChevron{UploadedIcon(data:node.chevronIconData,symbol:"chevron.right",size:11).opacity(0.3)}}.padding(node.padding)}.buttonStyle(.plain)
        case .card: VStack(alignment:.leading,spacing:node.spacing){if node.hasIcon{UploadedIcon(data:node.iconData,symbol:node.symbol,size:node.iconSize+6).foregroundStyle(Color(hex:node.accent))};Spacer(minLength:0);Text(node.text).fontWeight(.semibold);Text(node.subtitle).font(.system(size:max(11,node.fontSize-5))).opacity(0.5)}.frame(maxWidth:.infinity,alignment:.leading).padding(node.padding+4)
        case .divider: Color(hex:node.fill)
        case .toggle: DetailedSwitch(node:node,isOn:interactive ? $toggle:.constant(node.isOn))
        case .textField,.searchField: HStack(spacing:10){if node.kind == .searchField{UploadedIcon(data:node.iconData,symbol:node.symbol,size:node.iconSize).opacity(0.5)};TextField(node.text,text:interactive ? $text : .constant("")).textFieldStyle(.plain)}.padding(.horizontal,node.padding)
        case .badge: Text(node.text).frame(maxWidth:.infinity,maxHeight:.infinity)
        case .progress: DetailedProgress(node:node)
        case .slider: Slider(value:interactive ? $value : .constant(node.value)).tint(Color(hex:node.accent)).padding(.horizontal,8)
        case .segmented: Picker("",selection:$segment){ForEach(node.items){Text($0.title).tag($0.id)}}.pickerStyle(.segmented).labelsHidden().padding(3).onAppear{segment=node.items.first?.id ?? ""}
        case .backButton,.iconLabel,.textButton,.outlinedButton,.checkbox,.radio,.stepper,.secureField,.textArea,.selectField,.dateField,.rating,.loading,.rectangle,.circle,.spacer,.statistic,.alertBanner,.qrCode,.chevron,.switchControl,.ringProgress: ExtraComponentPreview(node:node,interactive:interactive,navigate:navigate)
        case .custom: VStack(spacing:8){Image(systemName:"curlybraces").font(.title2);Text(node.text).font(.caption);Text("自定义 SwiftUI · 导出时生效").font(.system(size:10)).opacity(0.4)}.frame(maxWidth:.infinity)
        }
    }
    var shape:UnevenRoundedRectangle {let c=corners ?? CornerRadii(node.cornerRadius);return UnevenRoundedRectangle(topLeadingRadius:c.tl,bottomLeadingRadius:c.bl,bottomTrailingRadius:c.br,topTrailingRadius:c.tr)}
    @ViewBuilder var icon:some View {
        if let image=PreviewImages.image(node.iconData ?? node.imageData) {Image(nsImage:image).resizable().scaledToFit().frame(width:node.iconSize,height:node.iconSize)}else{Image(systemName:node.symbol).font(.system(size:node.iconSize))}
    }
    @ViewBuilder var media:some View {
        if let image=PreviewImages.image(node.imageData){Image(nsImage:image).resizable().scaledToFill().clipped()}
        else{ZStack{Color(hex:node.fill);Image(systemName:node.symbol).font(.system(size:node.iconSize+12)).foregroundStyle(Color(hex:node.accent).opacity(0.6))}}
    }
    var avatar:some View {media.clipShape(RoundedRectangle(cornerRadius:node.avatarSize/3)).aspectRatio(1,contentMode:.fit)}
}
