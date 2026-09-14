import SwiftUI
import StudioCore

struct ComponentOutline:Shape {
    let kind:ComponentKind
    let corners:CornerRadii
    func path(in rect:CGRect)->Path {
        if kind == .ellipse{return Path(ellipseIn:rect)}
        if kind == .capsule{return Capsule().path(in:rect)}
        if kind == .circle{return Circle().path(in:rect)}
        return UnevenRoundedRectangle(topLeadingRadius:corners.tl,bottomLeadingRadius:corners.bl,bottomTrailingRadius:corners.br,topTrailingRadius:corners.tr).path(in:rect)
    }
}
@MainActor struct UniversalComponentPreview:View {
    let node:DesignNode
    let interactive:Bool
    let navigate:(String)->Void
    @ViewBuilder var body:some View {
        switch node.kind {
        case .ellipse:Ellipse().fill(node.paintStyle)
        case .capsule:Capsule().fill(node.paintStyle)
        case .keyValueRow:
            HStack(spacing:node.spacing){if node.hasIcon{glyph};Text(node.text);Spacer(minLength:8);Text(node.subtitle).foregroundStyle(Color(hex:node.foreground).opacity(0.55));if node.hasChevron{UploadedIcon(data:node.chevronIconData,symbol:"chevron.right",size:12).opacity(0.4)}}.padding(.horizontal,node.padding)
        case .menuButton:
            if interactive {Menu{ForEach(node.items){item in Button{navigate(item.pageID)}label:{HStack{if !item.symbol.isEmpty || item.iconData != nil {UploadedIcon(data:item.iconData,symbol:item.symbol,size:node.iconSize)};Text(item.title)}}}}label:{menuLabel}.menuStyle(.borderlessButton)}
            else{menuLabel}
        case .emptyState:
            VStack(spacing:node.spacing){if node.hasIcon{glyph.foregroundStyle(Color(hex:node.accent))};Text(node.text).fontWeight(.semibold).multilineTextAlignment(.center);if !node.subtitle.isEmpty{Text(node.subtitle).font(.system(size:max(11,node.fontSize-5))).multilineTextAlignment(.center).opacity(0.55)};if let title=node.actionTitle,!title.isEmpty{Button{navigate(node.targetPageID)}label:{Text(title).font(.system(size:15,weight:.medium)).foregroundStyle(Color(hex:node.accent))}.buttonStyle(.plain)}}.frame(maxWidth:.infinity,maxHeight:.infinity).padding(node.padding)
        default:EmptyView()
        }
    }
    var glyph:some View {UploadedIcon(data:node.iconData,symbol:node.symbol,size:node.iconSize)}
    var menuLabel:some View {HStack(spacing:node.spacing){if node.hasIcon{glyph};if node.hasLabel{Text(node.text)}}.frame(maxWidth:.infinity,maxHeight:.infinity).padding(.horizontal,node.padding)}
}
