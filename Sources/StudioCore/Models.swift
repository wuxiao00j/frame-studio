import Foundation

public enum ComponentKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case text, icon, button, iconButton, image, avatar, profileRow, navigationBar, tabBar, sidebar, listRow, card, divider, toggle, textField, searchField, badge, progress, slider, segmented, custom
    case backButton, iconLabel, textButton, outlinedButton, checkbox, radio, stepper, secureField, textArea, selectField, dateField, rating, loading, rectangle, circle, spacer, statistic, alertBanner, qrCode, chevron, switchControl, ringProgress
    case capsule, ellipse, keyValueRow, menuButton, emptyState
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .capsule:"胶囊";case .ellipse:"椭圆";case .keyValueRow:"信息键值行";case .menuButton:"菜单按钮";case .emptyState:"空状态"
        case .backButton: "返回按钮"
        case .iconLabel: "图文标签"; case .textButton: "文字按钮"; case .outlinedButton: "描边按钮"
        case .checkbox: "复选框"; case .radio: "单选按钮"; case .stepper: "步进器"; case .secureField: "密码框"
        case .textArea: "多行输入"; case .selectField: "下拉选择"; case .dateField: "日期选择"; case .rating: "星级评分"
        case .loading: "加载指示"; case .rectangle: "矩形容器"; case .circle: "圆形"; case .spacer: "间隔占位"
        case .statistic: "数据指标"; case .alertBanner: "提示横幅"; case .qrCode: "二维码图标"; case .chevron: "箭头"
        case .switchControl: "独立开关"; case .ringProgress: "环形进度"
        case .text: "文本"; case .icon: "图标"; case .button: "按钮"; case .iconButton: "侧栏按钮"
        case .image: "图片"; case .avatar: "头像"; case .profileRow: "个人资料栏"; case .navigationBar: "导航栏"
        case .tabBar: "Tab 栏"; case .sidebar: "侧边栏"; case .listRow: "列表行"; case .card: "内容卡片"
        case .divider: "分割线"; case .toggle: "开关"; case .textField: "输入框"; case .searchField: "搜索栏"
        case .badge: "标签"; case .progress: "进度条"; case .slider: "滑块"; case .segmented: "分段选择"; case .custom: "自定义视图"
        }
    }
    public var symbol: String {
        switch self {
        case .capsule:"capsule";case .ellipse:"oval";case .keyValueRow:"text.justify.left";case .menuButton:"ellipsis.circle";case .emptyState:"tray"
        case .backButton: "chevron.left"
        case .iconLabel: "text.bubble"; case .textButton: "text.badge.plus"; case .outlinedButton: "rectangle"
        case .checkbox: "checkmark.square"; case .radio: "record.circle"; case .stepper: "plusminus"; case .secureField: "lock"
        case .textArea: "text.alignleft"; case .selectField: "chevron.up.chevron.down"; case .dateField: "calendar"; case .rating: "star.leadinghalf.filled"
        case .loading: "arrow.trianglehead.2.clockwise.rotate.90"; case .rectangle: "rectangle"; case .circle: "circle"; case .spacer: "arrow.up.and.down"
        case .statistic: "number"; case .alertBanner: "info.circle"; case .qrCode: "qrcode"; case .chevron: "chevron.right"
        case .switchControl: "switch.2"; case .ringProgress: "chart.donut"
        case .text: "textformat"; case .icon: "star"; case .button: "rectangle.and.hand.point.up.left"; case .iconButton: "sidebar.left"
        case .image: "photo"; case .avatar: "person.crop.circle"; case .profileRow: "person.crop.rectangle"; case .navigationBar: "rectangle.topthird.inset.filled"
        case .tabBar: "rectangle.bottomthird.inset.filled"; case .sidebar: "sidebar.squares.left"; case .listRow: "list.bullet.rectangle"; case .card: "rectangle.on.rectangle"
        case .divider: "minus"; case .toggle: "switch.2"; case .textField: "character.cursor.ibeam"; case .searchField: "magnifyingglass"
        case .badge: "tag"; case .progress: "chart.bar.fill"; case .slider: "slider.horizontal.3"; case .segmented: "rectangle.split.3x1"; case .custom: "curlybraces"
        }
    }
    public var category: String {
        switch self {
        case .capsule,.ellipse:"图形与媒体"
        case .menuButton:"按钮与操作"
        case .keyValueRow,.emptyState:"预置组合"
        case .text,.badge,.iconLabel: "文字与标签"
        case .icon,.image,.avatar,.rectangle,.circle,.spacer,.divider,.qrCode,.chevron: "图形与媒体"
        case .button,.iconButton,.textButton,.outlinedButton,.backButton: "按钮与操作"
        case .toggle,.switchControl,.checkbox,.radio,.stepper,.textField,.secureField,.textArea,.searchField,.selectField,.dateField,.segmented: "表单与选择"
        case .progress,.ringProgress,.slider,.rating,.loading,.statistic: "进度与数据"
        case .navigationBar,.tabBar,.sidebar: "导航"
        case .profileRow,.listRow,.card,.alertBanner: "预置组合"
        case .custom: "自定义代码"
        }
    }
    public var decomposable:Bool { [.profileRow,.listRow,.card,.toggle,.button,.outlinedButton,.textButton,.navigationBar,.tabBar,.sidebar,.iconLabel,.statistic,.alertBanner,.keyValueRow,.emptyState].contains(self) }
    public static let categories=["文字与标签","图形与媒体","按钮与操作","表单与选择","进度与数据","导航","预置组合","自定义代码"]

}
public enum Variant: String, Codable, CaseIterable, Identifiable, Sendable {
    case standardPortrait, standardLandscape, outerPortrait, outerLandscape, innerPortrait, innerLandscape
    public var id: String { rawValue }
    public var landscape: Bool { rawValue.hasSuffix("Landscape") }
    public var title: String { switch self { case .standardPortrait: "标准 · 竖屏"; case .standardLandscape: "标准 · 横屏"; case .outerPortrait: "外屏 · 竖屏"; case .outerLandscape: "外屏 · 横屏"; case .innerPortrait: "内屏 · 竖屏"; case .innerLandscape: "内屏 · 横屏" } }
}
public struct Dimensions: Codable, Equatable, Sendable {
    public var width: Double; public var height: Double
    public init(_ width: Double, _ height: Double) { self.width = width; self.height = height }
}
public struct DeviceProfile: Codable, Equatable, Sendable {
    public var name = "通用阔屏 · 1:1.4"
    public var standard = Dimensions(393, 852)
    public var outer = Dimensions(400, 560)
    public var inner = Dimensions(570, 798)
    public var note = "逻辑设计尺寸，可自定义；不是硬件像素或官方逻辑分辨率。"
    public init() {}
    public func size(_ variant: Variant) -> Dimensions {
        let d = variant.rawValue.hasPrefix("standard") ? standard : (variant.rawValue.hasPrefix("outer") ? outer : inner)
        return variant.landscape ? Dimensions(d.height, d.width) : d
    }

}
public struct Rect: Codable, Equatable, Sendable {
    public var x: Double; public var y: Double; public var width: Double; public var height: Double
    public init(_ x: Double = 24, _ y: Double = 120, _ width: Double = 160, _ height: Double = 48) { self.x=x; self.y=y; self.width=width; self.height=height }
    public var midX: Double { x+width/2 }; public var midY: Double { y+height/2 }
}
public enum Anchor: String, Codable, CaseIterable, Sendable { case topLeft, topRight, bottomLeft, bottomRight, center, stretch }
public struct NavigationItem: Codable, Equatable, Identifiable, Sendable {
    public var id = UUID().uuidString
    public var title: String; public var symbol: String; public var pageID: String
    public var iconData:String?
    public var selectedSymbol:String?
    public var selectedIconData:String?
    public var activeSymbol:String {selectedSymbol ?? symbol}
    public var activeIconData:String? {selectedIconData ?? (selectedSymbol == nil ? iconData:nil)}
    public init(title: String, symbol: String, pageID: String = "") { self.title=title; self.symbol=symbol; self.pageID=pageID }
}
public struct DesignNode: Codable, Equatable, Identifiable, Sendable {
    public var id = UUID().uuidString
    public var kind: ComponentKind
    public var name: String
    public var text = ""
    public var subtitle = ""
    public var symbol = "sparkles"
    public var imageData: String = ""
    public var fill = "FFFFFF"
    public var gradient:DesignGradient?
    public var material:String?
    public var clipMasks:[String:[DesignClipMask]]?
    public var lineLimit:Int?
    public var lineSpacing:Double?
    public var minimumScaleFactor:Double?
    public var imageFit:String?
    public var controlStyle:String?
    public var selectedIndex:Int?
    public var isEnabled:Bool?
    public var actionTitle:String?
    public var backgroundLayer:Bool?
    public var visibleVariants:[String]?
    public var blurRadius:Double?
    public var shadowColor:String?
    public var shadowX:Double?
    public var shadowY:Double?
    public var foreground = "252336"
    public var accent = "7560D4"
    public var borderColor = "E8E5F0"
    public var borderWidth: Double = 0
    public var cornerRadius: Double = 14
    public var fontSize: Double = 16
    public var fontWeight = "regular"
    public var textAlignment = "leading"
    public var opacity: Double = 1
    public var rotation: Double = 0
    public var shadow: Double = 0
    public var padding: Double = 16
    public var iconSize: Double = 22
    public var avatarSize: Double = 58
    public var spacing: Double = 12
    public var value: Double = 0.65
    public var isOn = true
    public var hidden = false
    public var locked = false
    public var groupID: String = ""
    public var anchor: Anchor = .topLeft
    public var targetPageID = ""
    public var items: [NavigationItem] = []
    public var customCode = "Text(\"自定义 SwiftUI\")"
    public var showIcon:Bool?
    public var showLabel:Bool?
    public var showQRCode:Bool?
    public var showChevron:Bool?
    public var controlPosition:String?
    public var navigationAction:String?
    public var syncTabIcons:Bool?
    public var iconData:String?
    public var qrIconData:String?
    public var chevronIconData:String?
    public var trailingSymbol:String?
    public var trailingIconData:String?
    public var progressStyle:String?
    public var progressLabel:String?
    public var progressCurrent:Double?
    public var progressTotal:Double?
    public var progressThickness:Double?
    public var progressSteps:Int?
    public var trackColor:String?
    public var numberValue:Double?
    public var minimumValue:Double?
    public var maximumValue:Double?
    public var stepValue:Double?
    public var dateValue:String?
    public var fixedToViewport:Bool?
    public var rowGroupID:String?
    public var flutterCode: String?
    public var composeCode: String?
    public var sourceReference = ""
    public var frames: [String: Rect] = [:]
    public init(kind: ComponentKind, frame: Rect? = nil) {
        self.kind=kind; name=kind.title; text=kind.title
        var r = frame ?? Rect()
        switch kind {
        case .capsule: text="";fill="EEEAF8";r.width=160;r.height=48;cornerRadius=0
        case .ellipse: text="";fill="EEEAF8";r.width=160;r.height=96;cornerRadius=0
        case .keyValueRow: text="名称";subtitle="详细信息";r.width=345;r.height=52;showIcon=false;showChevron=false
        case .menuButton: text="更多";symbol="ellipsis";r.width=120;r.height=44;showIcon=true;fill="FFFFFF00";items=[.init(title:"编辑",symbol:"pencil"),.init(title:"分享",symbol:"square.and.arrow.up")]
        case .emptyState: text="暂无内容";subtitle="添加内容后会在这里显示";symbol="tray";iconSize=44;showIcon=true;r.width=345;r.height=210;fill="FFFFFF00";fontSize=20;actionTitle=""
        case .text: fill="FFFFFF00"; text="为灵感，留一点空间。"; fontSize=24; fontWeight="semibold"; r.width=330; r.height=42
        case .icon: fill="FFFFFF00"; r.width=48
        case .iconButton: symbol="sidebar.left"; text="打开侧边栏"; r.width=44; r.height=44
        case .button: fill="7560D4"; foreground="FFFFFF"; text="开始探索"; r.width=345; r.height=50
        case .image: fill="EEEAF8"; symbol="photo.on.rectangle.angled"; r.width=345; r.height=160
        case .avatar: fill="E9E2FC"; symbol="person.fill"; r.width=68; r.height=68; cornerRadius=34
        case .profileRow: text="设计师"; subtitle="微信号：framestudio"; symbol="person.fill"; r.width=345; r.height=100
        case .navigationBar: text="我的空间"; symbol="sidebar.left"; r=Rect(16,52,361,50); fill="FFFFFF00"; fontSize=20; fontWeight="semibold"
        case .tabBar: r=Rect(12,764,369,64); anchor = .bottomLeft; shadow=8; fontSize=11; items=[.init(title:"首页",symbol:"square.grid.2x2"),.init(title:"消息",symbol:"bubble.left.and.bubble.right"),.init(title:"我的",symbol:"person.crop.circle")]
        case .sidebar: text="工作空间"; r=Rect(16,112,240,410); items=[.init(title:"新建对话",symbol:"square.and.pencil"),.init(title:"探索",symbol:"square.grid.2x2"),.init(title:"我的",symbol:"person")]; shadow=10
        case .listRow: text="收藏与灵感"; subtitle="把喜欢的事物留在这里"; symbol="bookmark"; r.width=345; r.height=68
        case .card: text="让想法自然发生"; subtitle="从一个小小的灵感，开始新的设计。"; symbol="sparkles"; fill="EEEAF8"; r.width=345; r.height=148
        case .divider: r.width=345; r.height=1; fill="E8E5F0"; cornerRadius=0
        case .toggle: text="接收通知"; r.width=345; r.height=52
        case .textField: text="输入一些文字"; r.width=345; r.height=48; borderWidth=1
        case .searchField: text="搜索灵感、项目…"; symbol="magnifyingglass"; fill="F0EEF5"; r.width=345; r.height=44
        case .badge: text="正在创作"; r.width=90; r.height=30; fontSize=12; fill="EEEAF8"; foreground="7560D4"
        case .progress: r.width=300; r.height=24; fill="FFFFFF00"
        case .slider: r.width=300; r.height=40; fill="FFFFFF00"
        case .segmented: r.width=345; r.height=38; items=[.init(title:"全部",symbol:""),.init(title:"收藏",symbol:"")]
        case .custom: text="自定义 SwiftUI"; r.width=200; r.height=100; borderWidth=1
        case .backButton: text="返回"; symbol="chevron.left"; fill="FFFFFF00"; r=Rect(16,52,80,44); anchor = .topLeft; fixedToViewport=true
        case .iconLabel: text="图文标签"; fill="FFFFFF00"; r.width=180; r.height=36; showIcon=true
        case .textButton: text="了解更多"; fill="FFFFFF00"; foreground="7560D4"; showIcon=false; r.width=140; r.height=44
        case .outlinedButton: text="次要操作"; fill="FFFFFF00"; borderWidth=1; borderColor="7560D4"; foreground="7560D4"; showIcon=false; r.width=200; r.height=48
        case .checkbox: text="同意条款"; r.width=220; r.height=44; controlPosition="leading"
        case .radio: text="选项"; r.width=200; r.height=44; controlPosition="leading"
        case .stepper: text="数量"; r.width=300; r.height=48; numberValue=1; minimumValue=0; maximumValue=99; stepValue=1
        case .secureField: text="请输入密码"; r.width=300; r.height=48; symbol="lock"; showIcon=true; borderWidth=1
        case .textArea: text="输入详细内容"; r.width=320; r.height=120; borderWidth=1
        case .selectField: text="选择选项"; r.width=280; r.height=48; items=[.init(title:"选项一",symbol:""),.init(title:"选项二",symbol:""),.init(title:"选项三",symbol:"")]
        case .dateField: text="选择日期"; r.width=300; r.height=48; dateValue="2026-01-01"; symbol="calendar"
        case .rating: text="评分"; r.width=200; r.height=40; numberValue=3; maximumValue=5; iconSize=24
        case .loading: text="加载中"; r.width=80; r.height=60; fill="FFFFFF00"
        case .rectangle: text=""; r.width=240; r.height=140; fill="EEEAF8"
        case .circle: text=""; r.width=80; r.height=80; fill="EEEAF8"; cornerRadius=40
        case .spacer: text=""; r.width=200; r.height=24; fill="FFFFFF00"; cornerRadius=0
        case .statistic: text="总访客"; subtitle="1,284"; r.width=180; r.height=110; symbol="chart.bar"; fontSize=28; showIcon=true
        case .alertBanner: text="温馨提示"; subtitle="在这里补充说明"; symbol="info.circle"; r.width=345; r.height=68; fill="EEEAF8"; showIcon=true; showChevron=false
        case .qrCode: text="二维码"; symbol="qrcode"; r.width=42; r.height=42; iconSize=30; fill="FFFFFF00"
        case .chevron: text="箭头"; symbol="chevron.right"; r.width=24; r.height=30; iconSize=14; fill="FFFFFF00"
        case .switchControl: text=""; showLabel=false; r.width=62; r.height=36; padding=0; fill="FFFFFF00"
        case .ringProgress: text="进度"; r.width=100; r.height=100; progressStyle="circular"; progressLabel="percent"; fill="FFFFFF00"

        }
        frames[Variant.standardPortrait.rawValue] = frame ?? r
    }
    public func frame(_ variant: Variant, device: DeviceProfile) -> Rect {
        if let r = frames[variant.rawValue] { return r }
        let r = frames[Variant.standardPortrait.rawValue] ?? Rect()
        let base=device.standard, size=device.size(variant)
        if anchor == .stretch { return Rect(r.x, r.y, max(20,size.width-(base.width-r.width)), r.height) }
        let x = anchor == .topRight || anchor == .bottomRight ? size.width-(base.width-r.x) : (anchor == .center ? size.width/2+r.x-base.width/2 : r.x)
        let y = anchor == .bottomLeft || anchor == .bottomRight ? size.height-(base.height-r.y) : (anchor == .center ? size.height/2+r.y-base.height/2 : r.y)
        return Rect(max(0,min(x,size.width-min(r.width,size.width-24))), (isFixed ? max(0,min(y,size.height-min(r.height,size.height-24)-24)) : max(0,y)), min(r.width,size.width-24), min(r.height,size.height-24))
    }
}
public struct DesignPage: Codable, Equatable, Identifiable, Sendable {
    public var id=UUID().uuidString
    public var name: String
    public var background="F8F7FB"
    public var nodes: [DesignNode]
    public var scrollEnabled:Bool?
    public var contentHeights:[String:Double]?
    public var autoJoinRows:Bool?
    public init(name: String, nodes: [DesignNode] = []) { self.name=name; self.nodes=nodes }
}
public struct ComponentTemplate: Codable, Equatable, Identifiable, Sendable {
    public var id=UUID().uuidString
    public var name: String
    public var nodes: [DesignNode]
    public var category:String?
    public init(name: String, nodes: [DesignNode], category:String?=nil) { self.name=name; self.nodes=nodes; self.category=category }
}
public struct DesignProject: Codable, Equatable, Sendable {
    public var schemaVersion=1
    public var id=UUID().uuidString
    public var revision=0
    public var name="我的第一个设计"
    public var device=DeviceProfile()
    public var wideMode=false
    public var pages: [DesignPage]=[]
    public var templates: [ComponentTemplate]=[]
    public var importNotes: [String]=[]
    public init() {}
    public static func demo() -> DesignProject {
        var p=DesignProject()
        var home=DesignPage(name:"灵感首页"), chat=DesignPage(name:"对话"), profile=DesignPage(name:"我的")
        let items=[NavigationItem(title:"发现",symbol:"square.grid.2x2",pageID:home.id),NavigationItem(title:"对话",symbol:"bubble.left.and.bubble.right",pageID:chat.id),NavigationItem(title:"我的",symbol:"person.crop.circle",pageID:profile.id)]
        var nav=DesignNode(kind:.navigationBar); nav.text="灵感空间"; nav.fill="FFFFFF00"
        var title=DesignNode(kind:.text,frame:Rect(24,132,345,70)); title.text="好设计，\n从一点灵感开始。"; title.fontSize=28
        var caption=DesignNode(kind:.text,frame:Rect(24,214,340,24)); caption.text="收集想法 · 探索可能 · 自由创造"; caption.fontSize=13; caption.foreground="8B879C"
        var card=DesignNode(kind:.card,frame:Rect(24,270,345,164)); card.text="今天，想创造什么？"; card.subtitle="让每一个想法，都找到自己的形状。"; card.fontSize=20
        var button=DesignNode(kind:.button,frame:Rect(24,454,345,50)); button.targetPageID=chat.id
        var row=DesignNode(kind:.listRow,frame:Rect(24,532,345,72)); row.targetPageID=profile.id
        var tabs=DesignNode(kind:.tabBar); tabs.items=items
        home.nodes=[nav,title,caption,card,button,row,tabs]
        nav.id=UUID().uuidString; nav.text="对话"
        var search=DesignNode(kind:.searchField,frame:Rect(24,128,345,44))
        search.text="搜索对话"
        var chatCard=DesignNode(kind:.card,frame:Rect(24,198,345,180)); chatCard.text="有什么可以帮你？"; chatCard.subtitle="在这里搭建你的 AI 对话体验。"; chatCard.symbol="bubble.left.and.text.bubble.right"
        tabs.id=UUID().uuidString
        chat.nodes=[nav,search,chatCard,tabs]
        nav.id=UUID().uuidString; nav.text="我的"
        var person=DesignNode(kind:.profileRow,frame:Rect(16,124,361,114)); person.text="设计师"; person.subtitle="账号：designer_demo"
        var settings=DesignNode(kind:.listRow,frame:Rect(16,264,361,68)); settings.text="设置"; settings.subtitle="让空间更适合你"; settings.symbol="gearshape"
        var toggle=DesignNode(kind:.toggle,frame:Rect(16,348,361,56)); toggle.text="灵感提醒"
        tabs.id=UUID().uuidString
        profile.nodes=[nav,person,settings,toggle,tabs]
        p.pages=[home,chat,profile]
        for pi in p.pages.indices {
            for ni in p.pages[pi].nodes.indices {
                let n=p.pages[pi].nodes[ni]
                for v in Variant.allCases where v != .standardPortrait {
                    let s=p.device.size(v), margin=24.0
                    var r=n.frame(v,device:p.device)
                    if n.kind == .navigationBar {r=Rect(16,48,s.width-32,50)}
                    else if n.kind == .tabBar {r=Rect(12,s.height-88,s.width-24,64)}
                    else if v.landscape {
                        let leftWidth=(s.width-72)/2
                        if pi==0 {
                            switch ni {
                            case 1:r=Rect(margin,s.height<450 ? 100 : 112,leftWidth,68)
                            case 2:r=Rect(margin,s.height<450 ? 174 : 190,leftWidth,20)
                            case 3:r=Rect(s.width/2+12,110,leftWidth,max(85,s.height-218))
                            case 4:r=Rect(margin,s.height<450 ? s.height-136 : s.height-150,leftWidth,s.height<450 ? 40 : 46)
                            case 5:r=Rect(margin,s.height<450 ? s.height-200 : 230,leftWidth,56)
                            default:break
                            }
                        }else if pi==1 {
                            r = ni==1 ? Rect(margin,114,leftWidth,44) : Rect(s.width/2+12,114,leftWidth,max(90,s.height-220))
                        }else {
                            switch ni {case 1:r=Rect(margin,112,leftWidth,100);case 2:r=Rect(s.width/2+12,112,leftWidth,68);case 3:r=Rect(s.width/2+12,196,leftWidth,56);default:break}
                        }
                    }else {
                        r.width=s.width-margin*2;r.x=margin
                        if v == .outerPortrait && pi==0 {
                            switch ni {case 1:r.y=110;r.height=68;case 2:r.y=184;case 3:r.y=220;r.height=106;case 4:r.y=346;r.height=44;case 5:r.y=404;r.height=52;default:break}
                        }
                    }
                    p.pages[pi].nodes[ni].frames[v.rawValue]=r
                }
            }
        }
        return p
    }
}
