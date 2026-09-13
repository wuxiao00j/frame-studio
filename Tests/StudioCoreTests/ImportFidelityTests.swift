import XCTest
@testable import StudioCore

final class ImportFidelityTests:XCTestCase {
    func testDecompositionRebasesMasksAndPreservesMaterial()throws {
        var n=DesignNode(kind:.card,frame:Rect(20,50,300,200));n.material="thin";n.visibleVariants=["standardPortrait"]
        n.clipMasks=["standardPortrait":[DesignClipMask(rect:Rect(0,0,1,1),radius:0.1)]]
        let parts=ComponentAssembly.decompose(n,device:DeviceProfile())
        XCTAssertEqual(parts.first?.material,"thin")
        for part in parts {
            let r=part.frame(.standardPortrait,device:DeviceProfile()),m=try XCTUnwrap(part.masks(in:.standardPortrait).first)
            XCTAssertEqual(r.x+m.rect.x*r.width,20,accuracy:0.001)
            XCTAssertEqual(r.y+m.rect.y*r.height,50,accuracy:0.001)
            XCTAssertEqual(m.rect.width*r.width,300,accuracy:0.001)
            XCTAssertEqual(part.visibleVariants,n.visibleVariants)
        }
    }
    func testAncestorMasksRetainNestedBoundsInAllVariants()throws {
        let report=try imported("""
        import SwiftUI
        struct DemoView:View {var body:some View {
            ZStack {Rectangle().fill(Color.red).frame(width:100,height:100).offset(x:70)}
                .frame(width:160,height:120).clipShape(RoundedRectangle(cornerRadius:20))
                .padding(10).clipShape(Circle())
        }}
        """)
        let node=try XCTUnwrap(report.pages[0].nodes.first)
        for variant in Variant.allCases {
            let masks=node.masks(in:variant)
            XCTAssertEqual(masks.count,2)
            XCTAssertEqual(masks[0].shape,"roundedRectangle")
            XCTAssertEqual(masks[0].rect.width,1.6,accuracy:0.001)
            XCTAssertLessThan(masks[0].rect.x,0)
            XCTAssertEqual(masks[1].shape,"ellipse")
            XCTAssertEqual(masks[1].rect.width,masks[1].rect.height,accuracy:0.001)
        }
        try ProjectStore.validate(report.project(named:"Mask fixture"))
    }
    func testTextExtensionChainPreservesLimitsAndScale()throws {
        let report=try imported("""
        import SwiftUI
        extension Text {
            func cardTitle(maxLines:Int=2,minimum:Double=0.75)->some View {
                lineLimit(maxLines).minimumScaleFactor(minimum).lineSpacing(6).multilineTextAlignment(.center)
            }
        }
        struct DemoView:View {var body:some View {Text("A title that wraps").cardTitle(maxLines:3).frame(width:100)}}
        """)
        let n=try XCTUnwrap(report.pages[0].nodes.first)
        XCTAssertEqual(n.lineLimit,3);XCTAssertEqual(n.lineSpacing,6)
        XCTAssertEqual(n.minimumScaleFactor,0.75);XCTAssertEqual(n.textAlignment,"center")
        XCTAssertFalse(report.warnings.contains{$0.contains("尚未还原修饰器：.cardTitle")})
    }
    func testImageAspectAndMaterialAreClassifiedWithoutPlaceholders()throws {
        let report=try imported("""
        import SwiftUI
        struct DemoView:View {var body:some View {VStack {
            Image("Photo").resizable().scaledToFit().frame(width:180,height:90)
            Text("Frosted").padding(12).background(.thinMaterial).clipShape(RoundedRectangle(cornerRadius:12))
        }}}
        """)
        let n=try XCTUnwrap(report.pages[0].nodes.first{$0.kind == .image})
        XCTAssertEqual(n.imageFit,"fit");XCTAssertEqual(n.frames["standardPortrait"]?.height,90)
        XCTAssertEqual(report.pages[0].nodes.first{$0.material != nil}?.material,"thin")
        XCTAssertFalse(report.warnings.contains{$0.contains("填充表达式")})
    }
    func testRenderingAttributesRejectInvalidAgentInputAndKeepLegacyDefaults()throws {
        var p=DesignProject.demo();var n=p.pages[0].nodes[0]
        for bad in [0.0,1.1,Double.infinity] {n.minimumScaleFactor=bad;p.pages[0].nodes[0]=n;XCTAssertThrowsError(try ProjectStore.validate(p))}
        n.minimumScaleFactor=nil;n.clipMasks=["standardPortrait":[DesignClipMask(rect:Rect(0,0,-1,1))]];p.pages[0].nodes[0]=n
        XCTAssertThrowsError(try ProjectStore.validate(p))
        n.clipMasks=nil;n.lineLimit=nil;p.pages[0].nodes[0]=n
        let decoded=try JSONDecoder().decode(DesignProject.self,from:JSONEncoder().encode(p))
        XCTAssertEqual(decoded,p);try ProjectStore.validate(decoded)
    }
    func imported(_ source:String)throws->ImportReport {
        let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true);defer{try? FileManager.default.removeItem(at:root)}
        try source.write(to:root.appendingPathComponent("DemoView.swift"),atomically:true,encoding:.utf8)
        return try SwiftImporter.inspect(root)
    }
    func testComputedTernaryPaintResolvesBeforeConstructorArguments()throws {
        let report=try imported("""
        import SwiftUI
        struct DemoView:View {
            private var isDark:Bool {false}
            private var badgeColor:Color {isDark ? Color.black.opacity(0.3):Color.white.opacity(0.5)}
            var body:some View {Text("Badge").padding(12).background(badgeColor)}
        }
        """)
        XCTAssertEqual(report.pages[0].nodes.first{$0.kind == .rectangle}?.fill,"FFFFFF7F")
    }
    func testThemeFunctionRetainsGradientAlphaAndBlur()throws {
        let report=try imported("""
        import SwiftUI
        enum Palette {
            static let background = Color.white
            static func surface(_ level: Int, accent: Color = Color.red) -> LinearGradient {
                let strength: Double
                switch level {
                case 0: strength = 0.25
                default: strength = 0.5
                }
                return LinearGradient(colors: [background, accent.opacity(strength)], startPoint: .top, endPoint: .bottom)
            }
        }
        struct DemoView: View {var body: some View {
            RoundedRectangle(cornerRadius: 20).fill(Palette.surface(0)).frame(width: 180, height: 80).blur(radius: 4)
        }}
        """)
        let node=try XCTUnwrap(report.pages[0].nodes.first),g=try XCTUnwrap(node.gradient)
        XCTAssertEqual(g.stops.map(\.color),["FFFFFF","FF3B303F"])
        XCTAssertEqual(g.startX,0.5);XCTAssertEqual(g.endY,1);XCTAssertEqual(node.blurRadius,4)
    }
    func testNamedTupleMapExpandsEveryPill()throws {
        let report=try imported("""
        import SwiftUI
        struct DemoView: View {var body:some View {pills(items:[("One", "heart"), ("Two", "star")])}
            func pills(items:[(text:String,icon:String)]) -> some View {
                HStack {ForEach(items.map { Entry(title:$0.text, symbol:$0.icon) }) {item in Label(item.title,systemImage:item.symbol)}}
            }
        }
        """)
        XCTAssertEqual(report.pages[0].nodes.map(\.text),["One","Two"])
        XCTAssertEqual(report.pages[0].nodes.map(\.symbol),["heart","star"])
        XCTAssertGreaterThan(report.pages[0].nodes[1].frames["standardPortrait"]!.x,report.pages[0].nodes[0].frames["standardPortrait"]!.x)
    }
    func testFixedTrailingControlLeavesRemainingWidthToFlexibleTitle()throws {
        let report=try imported("""
        import SwiftUI
        struct DemoView:View {var body:some View {
            HStack(spacing:14) {Text("Title").frame(maxWidth:.infinity,alignment:.leading);Circle().frame(width:88,height:88)}.padding(20)
        }}
        """)
        let circle=try XCTUnwrap(report.pages[0].nodes.first{$0.kind == .circle})
        XCTAssertEqual(circle.frames["standardPortrait"]?.x,285)
        XCTAssertEqual(circle.frames["standardPortrait"]?.width,88)
    }
    func testParentRadiusDoesNotReplaceSmallInnerRadius()throws {
        let report=try imported("""
        import SwiftUI
        struct DemoView:View {var body:some View {
            RoundedRectangle(cornerRadius:6).fill(Color.red).frame(width:40,height:40).padding(20).background(Color.white).clipShape(RoundedRectangle(cornerRadius:24))
        }}
        """)
        let nodes=report.pages[0].nodes
        XCTAssertEqual(nodes.first{$0.fill=="FF3B30"}?.cornerRadius,6)
        XCTAssertEqual(nodes.first{$0.fill=="FFFFFF"}?.cornerRadius,24)
    }
    func testViewThatFitsChoosesStackForNarrowScreen()throws {
        let report=try imported("""
        import SwiftUI
        struct DemoView:View {var body:some View {ViewThatFits {
            HStack {Text("Horizontal A").frame(width:250);Text("Horizontal B").frame(width:250)}
            VStack {Text("Vertical A");Text("Vertical B")}
        }}}
        """)
        XCTAssertEqual(report.pages[0].nodes.filter{$0.isVisible(in:.standardPortrait)}.map(\.text),["Vertical A","Vertical B"])
        XCTAssertEqual(report.pages[0].nodes.filter{$0.isVisible(in:.standardLandscape)}.map(\.text),["Horizontal A","Horizontal B"])
    }
    func testRadialStopsValidateAndExportToThreeSourceFormats()throws {
        let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer{try? FileManager.default.removeItem(at:root)}
        var p=DesignProject.demo();var n=DesignNode(kind:.rectangle)
        n.gradient=DesignGradient(kind:"radial",stops:[.init(color:"FF000080",location:0),.init(color:"0000FFFF",location:1)],startX:0.5,startY:0.5,startRadius:10,endRadius:80);n.blurRadius=3
        p.pages[0].nodes.append(n)
        for format in ExportFormat.allCases {
            let dir=try DesignExporter.export(p,format:format,to:root)
            let restored=try ProjectStore.load(dir.appendingPathComponent("Design.framestudio"))
            XCTAssertEqual(restored.pages[0].nodes.last?.gradient,n.gradient)
            XCTAssertEqual(restored.pages[0].nodes.last?.blurRadius,3)
        }
        n.gradient!.stops[1].location = -1;p.pages[0].nodes[p.pages[0].nodes.count-1]=n
        XCTAssertThrowsError(try ProjectStore.validate(p))
    }
    func testMultilineLocalColorAndShapeOverlayDoNotCoverContent()throws {
        let report=try imported("""
        import SwiftUI
        struct DemoView:View {var body:some View {
            let focused=false
            let edge=focused
                ? Color.red
                : Color.blue
            let shape=RoundedRectangle(cornerRadius:20)
            Text("Visible").padding(20).background(Color.white)
                .overlay(shape.stroke(edge,lineWidth:1))
                .overlay(Rectangle().fill(Color.red.opacity(focused ? 0.5 : 0)))
        }}
        """)
        XCTAssertEqual(report.pages[0].nodes.filter{$0.kind == .text}.map(\.text),["Visible"])
        XCTAssertEqual(report.pages[0].nodes.filter{$0.fill=="FFFFFF00" && $0.borderWidth==1}.count,1)
        XCTAssertEqual(report.pages[0].nodes.last?.fill,"FF3B3000")
    }
    func testTrailingHeaderAndContentSlotsBothRemainVisible()throws {
        let report=try imported("""
        import SwiftUI
        struct DemoView:View {var body:some View {
            Shell(title:"Card") { Text("Add") } content: { Text("Main") }
        }}
        struct Shell<HeaderAccessory:View,Content:View>:View {
            enum HeaderAccessoryLayout {case trailing}
            let title:String
            var headerAccessoryLayout:HeaderAccessoryLayout = .trailing
            @ViewBuilder var headerAccessory:HeaderAccessory
            @ViewBuilder var content:Content
            var body:some View {VStack {headerRow;content}}
            var headerRow:some View {HStack {Text(title);Spacer();headerAccessory}}
        }
        """)
        XCTAssertEqual(report.pages[0].nodes.filter{$0.kind == .text}.map(\.text),["Card","Add","Main"])
    }
}
