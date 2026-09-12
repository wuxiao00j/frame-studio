import Foundation

public enum SwiftExporter {
    public static func literal(_ s:String)->String {
        var out="\""
        for scalar in s.unicodeScalars {
            switch scalar.value {
            case 34:out += "\\\"";case 92:out += "\\\\";case 10:out += "\\n";case 13:out += "\\r";case 9:out += "\\t"
            case 0..<32:out += "\\u{\(String(scalar.value,radix:16))}"
            default:out.unicodeScalars.append(scalar)
            }
        }
        return out+"\""
    }
    static func number(_ n:Double)->String {String(format:"%.3f",locale:Locale(identifier:"en_US_POSIX"),n)}
    static func identifier(_ id:String)->String {"Page_"+id.utf8.map{String(format:"%02X",$0)}.joined()}
    public static func export(_ project:DesignProject,to directory:URL) throws -> URL {
        try ProjectStore.validate(project)
        let stamp=ISO8601DateFormatter().string(from:Date()).replacingOccurrences(of:":",with:"-")
        let destination=directory.appendingPathComponent("SwiftUI-\(stamp)-\(UUID().uuidString.prefix(4))")
        let sources=destination.appendingPathComponent("Sources/GeneratedUI")
        try FileManager.default.createDirectory(at:sources,withIntermediateDirectories:true)
        do {
            try (runtime+"\n"+advancedRuntime).write(to:sources.appendingPathComponent("DesignSupport.swift"),atomically:true,encoding:.utf8)
            try root(project).write(to:sources.appendingPathComponent("DesignedAppView.swift"),atomically:true,encoding:.utf8)
            for page in project.pages { try pageSource(page,project:project).write(to:sources.appendingPathComponent(identifier(page.id)+".swift"),atomically:true,encoding:.utf8) }
            let assets=sources.appendingPathComponent("Assets.xcassets")
            try FileManager.default.createDirectory(at:assets,withIntermediateDirectories:true)
            try "{\"info\":{\"version\":1,\"author\":\"xcode\"}}".write(to:assets.appendingPathComponent("Contents.json"),atomically:true,encoding:.utf8)
            for (name,raw) in DesignExporter.assetEntries(project) {
                guard let data=Data(base64Encoded:raw) else{throw StudioError.invalid("图片无法导出")}
                let set=assets.appendingPathComponent(name+".imageset");try FileManager.default.createDirectory(at:set,withIntermediateDirectories:true)
                try data.write(to:set.appendingPathComponent("image.png"))
                try "{\"images\":[{\"filename\":\"image.png\",\"idiom\":\"universal\"}],\"info\":{\"version\":1,\"author\":\"xcode\"}}".write(to:set.appendingPathComponent("Contents.json"),atomically:true,encoding:.utf8)
            }
            try "// swift-tools-version: 5.10\nimport PackageDescription\nlet package = Package(name: \"GeneratedUI\", platforms: [.iOS(.v17), .macOS(.v14)], products: [.library(name: \"GeneratedUI\", targets: [\"GeneratedUI\"])], targets: [.target(name: \"GeneratedUI\", resources: [.process(\"Assets.xcassets\")])])\n".write(to:destination.appendingPathComponent("Package.swift"),atomically:true,encoding:.utf8)
            let enc=JSONEncoder();enc.outputFormatting=[.prettyPrinted,.sortedKeys]
            try enc.encode(project).write(to:destination.appendingPathComponent("Design.framestudio"))
            try FileManager.default.createDirectory(at:destination.appendingPathComponent("App"),withIntermediateDirectories:true)
            try "import SwiftUI\n@main struct PreviewApp: App { var body: some Scene { WindowGroup { DesignedAppView() } } }\n".write(to:destination.appendingPathComponent("App/PreviewApp.swift"),atomically:true,encoding:.utf8)
            try writeXcodeProject(project,to:destination)
            let custom=project.pages.flatMap(\.nodes).filter{$0.kind == .custom}
            let readme="""
            # \(project.name) · SwiftUI 导出

            UI 源码交付：只生成 Swift 文件、资源和项目配置；不生成 IPA 或可安装 App。业务逻辑尚需实现。最低 iOS 17。
            UI source handoff only: Swift files, assets and project configuration. No IPA or installable mobile app is generated. Business logic still needs implementation.
            或把 Package.swift 作为本地 Swift Package 添加到已有项目，import GeneratedUI，使用 DesignedAppView()。
            每个页面有独立 Swift 文件，Assets.xcassets 包含所用图片。Design.framestudio 可重新导入编辑器，完整保留页面、属性和各画布布局。

            所有页面使用原生 SwiftUI 组件。Tab、侧栏和按钮按绑定页面跳转，开关、输入框、滑块和分段选择具有本地交互状态；业务接口需要在原项目中接入。
            标准屏模式导出标准横竖布局；阔屏模式按短边 \(Int((project.device.outer.width+project.device.inner.width)/2)) pt 阈值选择内外屏，并按方向切换。阈值是设计规则，不是设备型号检测，可修改 DesignedAppView.swift。
            布局以设计 pt 为基准，支持长页滚动、固定组件和适配锚点。请在目标机型检查布局和安全区域。
            自定义 SwiftUI 表达式数量：\(custom.count)。这些表达式不会在编辑器中执行，可能依赖你自己的视图和资源，需在 Xcode 编译确认。
            导出不会覆盖原有项目文件；每次创建独立目录。
            """
            try readme.write(to:destination.appendingPathComponent("README.md"),atomically:true,encoding:.utf8)
            try ExportContract.writeManifest(project,format:.swiftui,to:destination)
            return destination
        } catch {try? FileManager.default.removeItem(at:destination);throw error}
    }
    static func root(_ p:DesignProject)->String {
        let cases=p.pages.map{"case \(literal($0.id)): \(identifier($0.id))(variant: variant, navigate: go, openSidebar: { sidebar.toggle() })"}.joined(separator:"\n                    ")
        let routes=p.pages.map{"Button(\(literal($0.name))) { go(\(literal($0.id))) }.frame(maxWidth: .infinity, alignment: .leading).padding(12)"}.joined(separator:"\n                            ")
        return """
        import SwiftUI

        public struct DesignedAppView: View {
            @State private var selected = \(literal(p.pages[0].id))
            @State private var sidebar = false
            @State private var history: [String] = []
            public init() {}
            private func go(_ page:String) {
                if page=="__back" {if let previous=history.popLast(){selected=previous};sidebar=false;return}
                guard !page.isEmpty else{return}
                if selected != page {history.append(selected);selected=page};sidebar=false
            }
            public var body: some View {
                GeometryReader { proxy in
                    let landscape = proxy.size.width > proxy.size.height
                    let variant: Int = \(p.wideMode ? "(min(proxy.size.width, proxy.size.height) < \(number((p.device.outer.width+p.device.inner.width)/2)) ? 2 : 4) + (landscape ? 1 : 0)" : "landscape ? 1 : 0")
                    ZStack(alignment: .leading) {
                        Group {
                            switch selected {
                            \(cases)
                            default: \(identifier(p.pages[0].id))(variant: variant, navigate: go, openSidebar: { sidebar.toggle() })
                            }
                        }
                        if sidebar {
                            Color.black.opacity(0.18).onTapGesture { sidebar = false }
                            VStack(alignment: .leading, spacing: 12) {
                                HStack { Text("工作空间").font(.headline); Spacer(); Button { sidebar = false } label: { Image(systemName: "xmark") } }.padding(12)
                                \(routes)
                                Spacer()
                            }.padding(.top, 54).padding(.horizontal, 12).frame(width: min(280, proxy.size.width * 0.8)).frame(maxHeight: .infinity).background(Color.white)
                        }
                    }
                }.ignoresSafeArea().tint(Color(designHex: "7560D4"))
            }
        }
        """
    }
    static func pageSource(_ page:DesignPage,project:DesignProject)->String {
        let nodes=page.nodes.filter{!$0.hidden}
        func content(fixed:Bool)->String {
            nodes.enumerated().filter{$0.element.isFixed==fixed}.map{i,n in
                let frames=Variant.allCases.map{v in let r=n.frame(v,device:project.device);return "CGRect(x: \(number(r.x)), y: \(number(r.y)), width: \(number(r.width)), height: \(number(r.height)))"}.joined(separator:", ")
                let refs=Variant.allCases.map{v in let d=project.device.size(v);return "CGSize(width: \(number(d.width)), height: \(number(fixed ? d.height:page.contentHeight(v,device:project.device))))"}.joined(separator:", ")
                let size=fixed ? "proxy.size":"CGSize(width: proxy.size.width, height: contentHeight)"
                return "element\(i).designPlaced(frames: [\(frames)], references: [\(refs)], variant: variant, size: \(size), anchor: \(literal(n.anchor.rawValue)))"
            }.joined(separator:"\n")
        }
        let heights=Variant.allCases.map{number(page.contentHeight($0,device:project.device))}.joined(separator:", ")
        let scrollBody="ZStack(alignment: .topLeading) {\n"+content(fixed:false)+"\n}.frame(width: proxy.size.width, height: contentHeight)"
        let scrolling=page.isScrollable ? "ScrollView(.vertical) { \(scrollBody) }" : scrollBody
        let views=nodes.enumerated().map{i,n in
            let weight=["regular","medium","semibold","bold"].contains(n.fontWeight) ? n.fontWeight : "regular"
            let align=["leading","center","trailing"].contains(n.textAlignment) ? n.textAlignment : "leading"
            let radii=Variant.allCases.map{page.corners(n,variant:$0,device:project.device)}
            func values(_ key:KeyPath<CornerRadii,Double>)->String {"["+radii.map{number($0[keyPath:key])}.joined(separator:", ")+"][variant]"}
            let shape="UnevenRoundedRectangle(topLeadingRadius: \(values(\.tl)), bottomLeadingRadius: \(values(\.bl)), bottomTrailingRadius: \(values(\.br)), topTrailingRadius: \(values(\.tr)))"
            return """
                // \(n.name.replacingOccurrences(of:"\n",with:" ").replacingOccurrences(of:"\r",with:" "))
                private var element\(i): some View {
                    \(expression(n,pageID:page.id))
                        .font(.system(size: \(number(n.fontSize)), weight: .\(weight)))
                        .foregroundStyle(Color(designHex: \(literal(n.foreground))))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .\(align))
                        .background(Color(designHex: \(literal(n.fill))))
                        .clipShape(\(shape))
                        .overlay(\(shape).stroke(Color(designHex: \(literal(n.borderColor))), lineWidth: \(number(n.borderWidth))))
                        .shadow(color: .black.opacity(\(n.shadow>0 ? "0.09" : "0")), radius: \(number(n.shadow)), y: \(number(n.shadow/3)))
                        .opacity(\(number(n.opacity))).rotationEffect(.degrees(\(number(n.rotation))))
                }
            """
        }.joined(separator:"\n")
        return """
        import SwiftUI
        struct \(identifier(page.id)): View {
            let variant: Int
            let navigate: (String) -> Void
            let openSidebar: () -> Void
            var body: some View {
                GeometryReader { proxy in
                    let contentHeight = max(proxy.size.height, [\(heights)][variant])
                    ZStack(alignment: .topLeading) {
                        Color(designHex: \(literal(page.background)))
                        \(scrolling)
                        \(content(fixed:true))
                    }.frame(width: proxy.size.width, height: proxy.size.height).clipped()
                }
            }
        \(views)
        }
        """
    }
    static func expression(_ n:DesignNode,pageID:String)->String {
        let t=literal(n.text),sub=literal(n.subtitle),symbol=literal(n.symbol),pad=number(n.padding),gap=number(n.spacing),icon=number(n.iconSize),accent="Color(designHex: \(literal(n.accent)))"
        let media = n.imageData.isEmpty ? "Image(systemName: \(symbol)).resizable().scaledToFit().padding(12).foregroundStyle(\(accent))" : "Image(\(literal(DesignExporter.assetName(n))), bundle: .designAssets).resizable().scaledToFill().clipped()"
        let glyph = n.imageData.isEmpty ? "Image(systemName: \(symbol)).font(.system(size: \(icon)))" : "Image(\(literal(DesignExporter.assetName(n))), bundle: .designAssets).resizable().scaledToFit().frame(width: \(icon), height: \(icon))"
        let avatar="\(media).frame(width: \(number(n.avatarSize)), height: \(number(n.avatarSize))).background(\(accent).opacity(0.12)).clipShape(RoundedRectangle(cornerRadius: \(number(n.avatarSize/3))))"
        func glyphExpression(_ symbol:String,_ asset:String?,_ size:Double)->String {"DesignerGlyph(symbol: \(literal(symbol)), asset: \(literal(asset ?? "")), size: \(number(size)))"}
        let buttonLabel=n.hasLabel ? "Text(\(t))":"EmptyView()"
        let leadingIcon=glyphExpression(n.symbol,n.iconData?.isEmpty==false ? DesignExporter.iconAssetName(n,"icon"):nil,n.iconSize)
        let qr=glyphExpression("qrcode",n.qrIconData?.isEmpty==false ? DesignExporter.iconAssetName(n,"qr"):nil,20)
        let chevron=glyphExpression("chevron.right",n.chevronIconData?.isEmpty==false ? DesignExporter.iconAssetName(n,"chevron"):nil,12)
        let trailing=glyphExpression(n.trailingSymbol ?? "square.and.pencil",n.trailingIconData?.isEmpty==false ? DesignExporter.iconAssetName(n,"trailing"):nil,n.iconSize)
        switch n.kind {
        case .text:return "Text(\(t)).multilineTextAlignment(.\(["leading","center","trailing"].contains(n.textAlignment) ? n.textAlignment : "leading"))"
        case .icon:return "\(n.iconData != nil ? leadingIcon:glyph).frame(maxWidth: .infinity).onTapGesture { navigate(\(literal(n.targetPageID))) }"
        case .iconButton:return "Button(action: openSidebar) { \(n.iconData != nil ? leadingIcon:glyph).frame(maxWidth: .infinity, maxHeight: .infinity) }.buttonStyle(.plain)"
        case .button:return "Button { navigate(\(literal(n.targetPageID.isEmpty ? pageID : n.targetPageID))) } label: { HStack(spacing: \(gap)) { \(n.hasIcon ? leadingIcon+"; " : "")\(buttonLabel) }.frame(maxWidth: .infinity, maxHeight: .infinity) }.buttonStyle(.plain)"
        case .image:return media
        case .avatar:return "\(media).clipShape(RoundedRectangle(cornerRadius: \(number(n.avatarSize/3)))).aspectRatio(1, contentMode: .fit)"
        case .profileRow:return "HStack(spacing: \(gap)) { \(avatar); VStack(alignment: .leading, spacing: 8) { Text(\(t)).fontWeight(.semibold); Text(\(sub)).font(.system(size: \(number(max(10,n.fontSize-3))))).opacity(0.55) }; Spacer(minLength: 0); \(n.hasQRCode ? qr+".opacity(0.4);" : "") \(n.hasChevron ? chevron+".opacity(0.3)" : "") }.padding(\(pad))"
        case .navigationBar:return "HStack { Button { \(n.navigationAction=="back" ? "navigate(\"__back\")":"openSidebar()") } label: { \(leadingIcon) }.buttonStyle(.plain); Spacer(); Text(\(t)).fontWeight(.semibold); Spacer(); Button { navigate(\(literal(n.targetPageID.isEmpty ? pageID : n.targetPageID))) } label: { \(trailing) }.buttonStyle(.plain) }.padding(.horizontal, \(pad))"
        case .tabBar,.sidebar:
            let buttons=n.items.map{item -> String in
                let selected=item.pageID==pageID
                let selectedAsset=item.selectedIconData != nil ? DesignExporter.itemAssetName(n,item,true):(item.selectedSymbol==nil && item.iconData != nil ? DesignExporter.itemAssetName(n,item,false):nil)
                let image=glyphExpression(selected ? item.activeSymbol:item.symbol,selected ? selectedAsset:(item.iconData != nil ? DesignExporter.itemAssetName(n,item,false):nil),n.iconSize)
                let color=selected ? accent:"Color(designHex: \(literal(n.foreground))).opacity(0.5)"
                let label=n.kind == .tabBar ? "VStack(spacing: 6) { \(image); Text(\(literal(item.title))).font(.system(size: \(number(n.fontSize)))) }.frame(maxWidth: .infinity, maxHeight: .infinity)" : "HStack(spacing: \(gap)) { \(image); Text(\(literal(item.title))); Spacer() }.padding(12)"
                return "Button { navigate(\(literal(item.pageID.isEmpty ? pageID:item.pageID))) } label: { \(label).foregroundStyle(\(color)) }.buttonStyle(.plain)"
            }.joined(separator:"; ")
            return n.kind == .tabBar ? "HStack(spacing: 0) { \(buttons) }.padding(.horizontal, 6)" : "VStack(alignment: .leading, spacing: \(gap)) { Text(\(t)); \(buttons); Spacer(minLength: 0) }.padding(\(pad))"
        case .listRow:return "Button { navigate(\(literal(n.targetPageID.isEmpty ? pageID : n.targetPageID))) } label: { HStack(spacing: \(gap)) { \(n.hasIcon ? leadingIcon+".foregroundStyle(\(accent)); " : "")VStack(alignment: .leading, spacing: 5) { Text(\(t)); Text(\(sub)).font(.system(size: \(number(max(10,n.fontSize-4))))).opacity(0.45) }; Spacer(minLength: 0); \(n.hasChevron ? chevron+".opacity(0.3)":"EmptyView()") }.padding(\(pad)) }.buttonStyle(.plain)"
        case .card:return "VStack(alignment: .leading, spacing: \(gap)) { \(glyphExpression(n.symbol,n.iconData != nil ? DesignExporter.iconAssetName(n,"icon"):nil,n.iconSize+6)).foregroundStyle(\(accent)); Spacer(minLength: 0); Text(\(t)).fontWeight(.semibold); Text(\(sub)).font(.system(size: \(number(max(11,n.fontSize-5))))).opacity(0.5) }.frame(maxWidth: .infinity, alignment: .leading).padding(\(number(n.padding+4)))"
        case .divider:return "Color(designHex: \(literal(n.fill)))"
        case .toggle,.switchControl:return "DesignerToggle(title: \(t), initial: \(n.isOn), leading: \(n.position=="leading"), showLabel: \(n.hasLabel), showIcon: \(n.hasIcon), symbol: \(symbol), asset: \(literal(n.iconData != nil ? DesignExporter.iconAssetName(n,"icon"):"")), iconSize: \(icon), gap: \(gap), accent: \(accent)).padding(.horizontal, \(pad))"
        case .textField,.searchField:return "DesignInput(placeholder: \(t), symbol: \(literal(n.kind == .searchField ? n.symbol : "")), asset: \(literal(n.kind == .searchField && n.iconData != nil ? DesignExporter.iconAssetName(n,"icon"):""))).padding(.horizontal, \(pad))"
        case .badge:return "Text(\(t)).frame(maxWidth: .infinity, maxHeight: .infinity)"
        case .progress,.ringProgress:return "DesignerProgress(value: \(number(n.fraction)), label: \(literal(n.progressText)), style: \(literal(n.progressMode)), thickness: \(number(n.progressThickness ?? 6)), steps: \(n.progressSteps ?? 5), track: Color(designHex: \(literal(n.trackColor ?? "E5E2ED"))), accent: \(accent), fontSize: \(number(n.fontSize)))"
        case .slider:return "DesignSlider(initial: \(number(n.value)), accent: \(accent)).padding(.horizontal, 8)"
        case .segmented:return "DesignSegments(titles: [\(n.items.map{literal($0.title)}.joined(separator:", "))]).padding(3)"
        case .backButton:return "Button { navigate(\"__back\") } label: { HStack(spacing: \(gap)) { \(leadingIcon); \(buttonLabel) }.frame(maxWidth: .infinity, maxHeight: .infinity) }.buttonStyle(.plain)"
        case .iconLabel,.textButton,.outlinedButton:return "Button { navigate(\(literal(n.targetPageID))) } label: { HStack(spacing: \(gap)) { \(n.hasIcon ? leadingIcon+";":"")\(buttonLabel) }.frame(maxWidth: .infinity, maxHeight: .infinity) }.buttonStyle(.plain)"
        case .checkbox,.radio:return "DesignerChoice(title: \(t), initial: \(n.isOn), radio: \(n.kind == .radio), leading: \(n.position=="leading"), showLabel: \(n.hasLabel), showIcon: \(n.hasIcon), symbol: \(symbol), asset: \(literal(n.iconData != nil ? DesignExporter.iconAssetName(n,"icon"):"")), iconSize: \(icon), gap: \(gap), accent: \(accent)).padding(.horizontal, \(pad))"
        case .stepper:return "DesignerStepper(title: \(t), initial: \(number(n.number)), minimum: \(number(n.minimum)), maximum: \(number(n.maximum)), step: \(number(n.step))).padding(.horizontal, \(pad))"
        case .secureField,.textArea:return "HStack(spacing: \(gap)) { \(n.kind == .secureField && n.hasIcon ? leadingIcon+";":"")DesignerTextEntry(placeholder: \(t), secure: \(n.kind == .secureField), multiline: \(n.kind == .textArea)) }.padding(\(pad))"
        case .selectField:return "DesignerPicker(title: \(t), titles: [\(n.items.map{literal($0.title)}.joined(separator:", "))]).padding(.horizontal, \(pad))"
        case .dateField:return "DesignerDate(title: \(t), initial: \(literal(n.dateValue ?? "2026-01-01"))).padding(.horizontal, \(pad))"
        case .rating:return "DesignerRating(initial: \(number(n.number)), count: \(Int(n.maximum)), size: \(icon), gap: \(gap), accent: \(accent))"
        case .loading:return "ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)"
        case .rectangle:return "Color(designHex: \(literal(n.fill)))"
        case .circle:return "Circle().fill(Color(designHex: \(literal(n.fill))))"
        case .spacer:return "Color.clear"
        case .qrCode,.chevron:return "\(leadingIcon).frame(maxWidth: .infinity, maxHeight: .infinity).onTapGesture { navigate(\(literal(n.targetPageID))) }"
        case .statistic:return "VStack(alignment: .leading, spacing: 8) { HStack { \(n.hasIcon ? leadingIcon+";":"")Text(\(t)).font(.system(size: 13)) }; Text(\(sub)).font(.system(size: \(number(n.fontSize)), weight: .semibold)) }.padding(\(pad))"
        case .alertBanner:return "HStack(spacing: \(gap)) { \(n.hasIcon ? leadingIcon+";":"")VStack(alignment: .leading, spacing: 4) { Text(\(t)); Text(\(sub)).font(.system(size: \(number(max(10,n.fontSize-3))))).opacity(0.6) } }.padding(.horizontal, \(pad))"
        case .custom:return n.customCode
        }
    }
    static let runtime = #"""
    import SwiftUI
    extension Color {
        init(designHex: String) {
            let raw = designHex.replacingOccurrences(of: "#", with: "")
            let n = UInt64(raw, radix: 16) ?? 0
            let a = raw.count == 8
            self.init(.sRGB, red: Double((n >> (a ? 24 : 16)) & 255) / 255, green: Double((n >> (a ? 16 : 8)) & 255) / 255, blue: Double((n >> (a ? 8 : 0)) & 255) / 255, opacity: a ? Double(n & 255) / 255 : 1)
        }
    }
    extension Bundle {
        static var designAssets: Bundle {
            #if SWIFT_PACKAGE
            .module
            #else
            .main
            #endif
        }
    }
    extension View {
        func designPlaced(frames: [CGRect], references: [CGSize], variant: Int, size: CGSize, anchor: String) -> some View {
            let r = frames[variant], ref = references[variant]
            let dx = size.width - ref.width, dy = size.height - ref.height
            let width = anchor == "stretch" ? max(1, r.width + dx) : r.width
            let x = r.minX + ((anchor == "topRight" || anchor == "bottomRight") ? dx : (anchor == "center" ? dx / 2 : 0))
            let y = r.minY + ((anchor == "bottomLeft" || anchor == "bottomRight") ? dy : (anchor == "center" ? dy / 2 : 0))
            return frame(width: width, height: r.height).position(x: x + width / 2, y: y + r.height / 2)
        }
    }
    struct DesignToggle: View {
        let title: String; let initial: Bool; let accent: Color
        @State private var value = false
        var body: some View { Toggle(title, isOn: $value).toggleStyle(.switch).tint(accent).onAppear { value = initial } }
    }
    struct DesignInput: View {
        let placeholder: String; let symbol: String; let asset: String
        @State private var text = ""
        var body: some View { HStack(spacing: 10) { if !symbol.isEmpty || !asset.isEmpty { DesignerGlyph(symbol: symbol, asset: asset, size: 22).opacity(0.5) }; TextField(placeholder, text: $text).textFieldStyle(.plain) } }
    }
    struct DesignSlider: View {
        let initial: Double; let accent: Color
        @State private var value = 0.0
        var body: some View { Slider(value: $value).tint(accent).onAppear { value = initial } }
    }
    struct DesignSegments: View {
        let titles: [String]
        @State private var selected = 0
        var body: some View { Picker("", selection: $selected) { ForEach(titles.indices, id: \.self) { Text(titles[$0]).tag($0) } }.pickerStyle(.segmented).labelsHidden() }
    }
    """#
    static func writeXcodeProject(_ p:DesignProject,to root:URL) throws {
        let swiftFiles=["App/PreviewApp.swift","Sources/GeneratedUI/DesignSupport.swift","Sources/GeneratedUI/DesignedAppView.swift"]+p.pages.map{"Sources/GeneratedUI/"+identifier($0.id)+".swift"}
        let files=swiftFiles+["Sources/GeneratedUI/Assets.xcassets"]
        func id(_ n:Int)->String {String(format:"%024X",n)}
        var objects=""
        for (i,file) in files.enumerated(){objects += "\(id(100+i)) = {isa = PBXFileReference; lastKnownFileType = \(file.hasSuffix("swift") ? "sourcecode.swift" : "folder.assetcatalog"); path = \"\(file)\"; sourceTree = SOURCE_ROOT; };\n\(id(200+i)) = {isa = PBXBuildFile; fileRef = \(id(100+i)); };\n"}
        let text="""
        // !$*UTF8*$!
        { archiveVersion = 1; classes = {}; objectVersion = 56; objects = {
        \(objects)
        \(id(1)) = {isa = PBXProject; buildConfigurationList = \(id(10)); compatibilityVersion = "Xcode 14.0"; developmentRegion = en; mainGroup = \(id(2)); productRefGroup = \(id(3)); projectDirPath = ""; projectRoot = ""; targets = (\(id(4))); };
        \(id(2)) = {isa = PBXGroup; children = (\(files.indices.map{id(100+$0)}.joined(separator:",")),\(id(3))); sourceTree = "<group>"; };
        \(id(3)) = {isa = PBXGroup; children = (\(id(5))); name = Products; sourceTree = "<group>"; };
        \(id(4)) = {isa = PBXNativeTarget; buildConfigurationList = \(id(11)); buildPhases = (\(id(6)),\(id(7)),\(id(8))); buildRules = (); dependencies = (); name = GeneratedApp; productName = GeneratedApp; productReference = \(id(5)); productType = "com.apple.product-type.application"; };
        \(id(5)) = {isa = PBXFileReference; explicitFileType = wrapper.application; path = GeneratedApp.app; sourceTree = BUILT_PRODUCTS_DIR; };
        \(id(6)) = {isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = (\(swiftFiles.indices.map{id(200+$0)}.joined(separator:","))); runOnlyForDeploymentPostprocessing = 0; };
        \(id(7)) = {isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = (\(id(200+swiftFiles.count))); runOnlyForDeploymentPostprocessing = 0; };
        \(id(8)) = {isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; };
        \(id(10)) = {isa = XCConfigurationList; buildConfigurations = (\(id(12)),\(id(13))); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; };
        \(id(11)) = {isa = XCConfigurationList; buildConfigurations = (\(id(14)),\(id(15))); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; };
        \(id(12)) = {isa = XCBuildConfiguration; buildSettings = { ALWAYS_SEARCH_USER_PATHS = NO; SDKROOT = iphoneos; IPHONEOS_DEPLOYMENT_TARGET = 17.0; }; name = Debug; };
        \(id(13)) = {isa = XCBuildConfiguration; buildSettings = { ALWAYS_SEARCH_USER_PATHS = NO; SDKROOT = iphoneos; IPHONEOS_DEPLOYMENT_TARGET = 17.0; }; name = Release; };
        \(id(14)) = {isa = XCBuildConfiguration; buildSettings = { SWIFT_VERSION = 5.0; SWIFT_OPTIMIZATION_LEVEL = "-Onone"; PRODUCT_BUNDLE_IDENTIFIER = local.framestudio.generated; PRODUCT_NAME = "$(TARGET_NAME)"; GENERATE_INFOPLIST_FILE = YES; INFOPLIST_KEY_UILaunchScreen_Generation = YES; INFOPLIST_KEY_UISupportedInterfaceOrientations = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"; TARGETED_DEVICE_FAMILY = "1,2"; CODE_SIGN_STYLE = Automatic; }; name = Debug; };
        \(id(15)) = {isa = XCBuildConfiguration; buildSettings = { SWIFT_VERSION = 5.0; PRODUCT_BUNDLE_IDENTIFIER = local.framestudio.generated; PRODUCT_NAME = "$(TARGET_NAME)"; GENERATE_INFOPLIST_FILE = YES; INFOPLIST_KEY_UILaunchScreen_Generation = YES; INFOPLIST_KEY_UISupportedInterfaceOrientations = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"; TARGETED_DEVICE_FAMILY = "1,2"; CODE_SIGN_STYLE = Automatic; }; name = Release; };
        }; rootObject = \(id(1)); }
        """
        let dir=root.appendingPathComponent("GeneratedApp.xcodeproj");try FileManager.default.createDirectory(at:dir,withIntermediateDirectories:true)
        try text.write(to:dir.appendingPathComponent("project.pbxproj"),atomically:true,encoding:.utf8)
    }
}
