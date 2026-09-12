import XCTest
@testable import StudioCore

final class SwiftStructuredImportTests:XCTestCase {
    func inspect(_ sources:[String:String],options:SwiftImportOptions=SwiftImportOptions())throws->ImportReport {
        let directory=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true)
        defer{try? FileManager.default.removeItem(at:directory)}
        for (file,source) in sources {try source.write(to:directory.appendingPathComponent(file),atomically:true,encoding:.utf8)}
        return try SwiftImporter.inspect(directory,options:options)
    }
    func testOnlyViewBodyCreatesLayersAndModelsNeverBecomePages()throws {
        let report=try inspect(["DemoView.swift":"""
        import SwiftUI
        struct DemoView: View {
            @AppStorage("key") var enabled = false
            @State var store = DataStore()
            var body: some View {
                VStack {
                    Text("Visible")
                    Button("Save") { SecretModel(); NetworkService(); Text("Not a label") }
                }.onAppear { LoadOperation(); Text("Not visible") }
                 .sheet(isPresented: $enabled) { Text("Hidden sheet") }
            }
            func unused() { Text("Unused"); GhostWidget() }
        }
        ""","Models.swift":"import SwiftUI\nstruct Data { var value = Store(); func save() { Text(\"Not UI\") } }"])
        XCTAssertEqual(report.pages.map(\.name),["DemoView"])
        XCTAssertEqual(report.pages[0].nodes.map(\.text),["Visible","Save"])
        XCTAssertTrue(report.unmatched.isEmpty)
    }
    func testCustomViewsExpandParametersAndBecomeReusableTemplates()throws {
        let report=try inspect(["DemoView.swift":"""
        import SwiftUI
        struct DemoView: View { var body: some View {
            VStack(spacing: 20) { CaptionCard(title: "First", symbol: "heart"); CaptionCard(title: "Second", symbol: "star") }
        } }
        ""","CaptionCard.swift":"""
        import SwiftUI
        struct CaptionCard: View {
            let title: String
            let symbol: String
            var body: some View {
                HStack(spacing: 12) { Image(systemName: symbol); Text(title).font(.system(size: 24)) }
            }
        }
        """])
        let nodes=report.pages[0].nodes
        XCTAssertEqual(report.pages.count,1)
        XCTAssertEqual(nodes.filter{$0.kind == .text}.map(\.text),["First","Second"])
        XCTAssertEqual(nodes.filter{$0.kind == .icon}.map(\.symbol),["heart","star"])
        XCTAssertTrue(nodes.filter{$0.kind == .text}.allSatisfy{$0.fontSize==24})
        XCTAssertTrue(report.unmatched.isEmpty)
        XCTAssertEqual(report.templates.map(\.name),["CaptionCard"])
        XCTAssertNotEqual(nodes[0].groupID,nodes[2].groupID)
    }
    func testLayoutScopesSiblingModifiersAndResolvesConstants()throws {
        let report=try inspect(["DemoView.swift":"""
        import SwiftUI
        enum Metrics { static let gap: CGFloat = 18 }
        struct DemoView: View { var body: some View {
            VStack(alignment: .leading, spacing: Metrics.gap) {
                Text("A").font(.system(size: 30)).foregroundStyle(Color.red)
                Text("B").frame(width: 120, height: 40).background(Color.blue)
            }.padding(.leading, 20)
        } }
        """])
        let page=report.pages[0],a=page.nodes.first{$0.text=="A"}!,b=page.nodes.first{$0.text=="B"}!
        XCTAssertEqual(a.foreground,"FF3B30");XCTAssertEqual(a.fontSize,30)
        XCTAssertEqual(b.fontSize,17);XCTAssertNotEqual(b.foreground,"FF3B30")
        let background=page.nodes.first{$0.fill=="007AFF"}!
        let d=DeviceProfile()
        for v in Variant.allCases {
            let ar=a.frame(v,device:d),br=background.frame(v,device:d)
            XCTAssertEqual(ar.x,20);XCTAssertEqual(br.width,120);XCTAssertEqual(br.height,40)
            XCTAssertEqual(br.y,ar.y+ar.height+18,accuracy:0.01)
        }
    }
    func testViewBuilderClosuresAndComputedExtensionMembersExpand()throws {
        let report=try inspect(["DemoView.swift":"""
        import SwiftUI
        struct DemoView: View { var body: some View { Shell { content } } }
        extension DemoView { var content: some View { Text("Inside").padding(8) } }
        struct Shell<Content: View>: View {
            var content: Content
            init(@ViewBuilder content: () -> Content) { self.content = content() }
            var body: some View { VStack { content }.padding(12).background(Color.white) }
        }
        """])
        let node=report.pages[0].nodes.first{$0.text=="Inside"}!
        XCTAssertEqual(node.frame(.standardPortrait,device:DeviceProfile()).x,20)
        XCTAssertTrue(report.unmatched.isEmpty)
    }
    func testTabDestinationsDoNotFlattenAllPagesIntoOne()throws {
        let report=try inspect(["Views.swift":"""
        import SwiftUI
        struct RootView: View { var body: some View {
            TabView { HomeView().tabItem { Label("Home", systemImage: "house") }; SettingsView().tabItem { Label("Settings", systemImage: "gear") } }
        } }
        struct HomeView: View { var body: some View { Text("Only home") } }
        struct SettingsView: View { var body: some View { Text("Only settings") } }
        """])
        XCTAssertEqual(report.pages.map(\.name),["Home","Settings"])
        XCTAssertEqual(report.pages[0].nodes.filter{$0.kind == .text}.map(\.text),["Only home"])
        let tab=report.pages[0].nodes.first{$0.kind == .tabBar}!
        XCTAssertEqual(tab.items.map(\.pageID),report.pages.map(\.id))
        XCTAssertEqual(tab.items.map(\.symbol),["house","gear"])
        var p=DesignProject();p.pages=report.pages;try ProjectStore.validate(p)
    }
    func testCommentsStringsAndUnknownViewsAreNotConflated()throws {
        let report=try inspect(["DemoView.swift":"""
        import SwiftUI
        struct DemoView: View { var body: some View {
            VStack { /* ImaginaryWidget() { */ Text("FakeWidget() { }"); SpecialOrbitWidget() }
        } }
        """])
        XCTAssertEqual(report.unmatched.map(\.typeName),["SpecialOrbitWidget"])
        XCTAssertEqual(report.pages[0].nodes.count,2)
    }
    func testStaticListExpandsDataWithoutCreatingModelWidgets()throws {
        let report=try inspect(["DemoView.swift":"""
        import SwiftUI
        struct DemoView: View {
            let items = [Item(title: "One"), Item(title: "Two")]
            var body: some View { VStack { ForEach(items) { item in Text(item.title) } } }
        }
        """])
        XCTAssertEqual(report.pages[0].nodes.map(\.text),["One","Two"])
        XCTAssertTrue(report.unmatched.isEmpty)
    }
    func testLocalizedArgumentsAndOptionalLabelsExpandWithoutLeakingIdentifiers()throws {
        let report=try inspect(["DemoView.swift":"""
        import SwiftUI
        struct DemoView: View {var body: some View { Header(title: String(localized: "Hello"), subtitle: nil) }}
        struct Header: View {
            let title: String
            let subtitle: String?
            var body: some View {VStack {Text(LocalizedStringKey(title)); if let subtitle {Text(LocalizedStringKey(subtitle))} }}
        }
        """])
        XCTAssertEqual(report.pages[0].nodes.map(\.text),["Hello"])
    }
    func testSingleTrailingClosureUsesContentInAnOverloadedCard()throws {
        let report=try inspect(["DemoView.swift":"""
        import SwiftUI
        struct DemoView: View { var body: some View { CardShell { Text("Visible content") } } }
        struct CardShell<HeaderAccessory: View, Content: View>: View {
            var headerAccessory: HeaderAccessory
            var content: Content
            var body: some View { VStack { headerAccessory; content } }
        }
        """])
        XCTAssertEqual(report.pages[0].nodes.map(\.text),["Visible content"])
    }
    func testSourceViewModifierKeepsContentAndBackground()throws {
        let report=try inspect(["DemoView.swift":"""
        import SwiftUI
        struct DemoView: View {var body: some View {Text("Card").cardSurface()}}
        struct CardPaint: ViewModifier {
            func body(content: Content) -> some View {content.background(Color.red).padding(8)}
        }
        extension View {func cardSurface() -> some View {modifier(CardPaint())}}
        """])
        XCTAssertEqual(report.pages[0].nodes.filter{$0.kind == .text}.map(\.text),["Card"])
        XCTAssertTrue(report.pages[0].nodes.contains{$0.fill=="FF3B30"})
        XCTAssertTrue(report.unmatched.isEmpty)
    }
    func testIncompleteSourceDoesNotCrashTheImporter()throws {
        let report=try inspect(["DraftView.swift":"import SwiftUI\nstruct DraftView: View {var body: some View { VStack { Text(\"Draft\")"])
        XCTAssertEqual(report.pages.first?.nodes.first?.text,"Draft")
    }
    func testPickerAndToggleUseSourceContentInsteadOfPresetDemoValues()throws {
        let report=try inspect(["DemoView.swift":"""
        import SwiftUI
        struct DemoView: View {
            @State var enabled = false
            @State var choice = 0
            var body: some View { VStack {
                Toggle(isOn: $enabled) { Text("Notifications") }
                Picker("Scope", selection: $choice) { Text("Private").tag(0); Text("Shared").tag(1) }
            } }
        }
        """])
        let nodes=report.pages[0].nodes
        XCTAssertEqual(nodes.first{$0.kind == .toggle}?.text,"Notifications")
        XCTAssertEqual(nodes.first{$0.kind == .toggle}?.isOn,false)
        XCTAssertEqual(nodes.first{$0.kind == .selectField}?.items.map(\.title),["Private","Shared"])
    }
    func testObservedStateChoosesEmptyAndLoggedOutBranchesAndColors()throws {
        let report=try inspect(["DemoView.swift":"""
        import SwiftUI
        struct DemoView: View {var body: some View {
            VStack {
                Text(session.loggedIn ? "Profile" : "Login").foregroundStyle(Theme.tint)
                if let latest { Text("Has data") } else if !items.isEmpty {Text("Other data")} else {Text("Empty")}
                ForEach(items) { item in Text("Sample row") }
            }
        }}
        """],options:SwiftImportOptions(values:["session.loggedIn":"false","latest":"nil","items.isEmpty":"true","items":"[]"],colors:["Theme.tint":"875F64"]))
        XCTAssertEqual(report.pages[0].nodes.map(\.text),["Login","Empty"])
        XCTAssertEqual(report.pages[0].nodes[0].foreground,"875F64")
    }
    func testInvalidColorOverrideIsRejected()throws {
        XCTAssertThrowsError(try inspect(["DemoView.swift":"import SwiftUI\nstruct DemoView: View {var body:some View {Text(\"X\")}}"],options:SwiftImportOptions(colors:["Theme.tint":"not-a-color"])))
    }
    func testStaticIndicesAndObservedInterpolationRenderActualValues()throws {
        let report=try inspect(["DemoView.swift":#"""
        import SwiftUI
        struct DemoView: View {
            var items: [Item] { [Item(title: "Settings"), Item(title: "Privacy")] }
            var body: some View {VStack {
                Text("Count: \(count)")
                ForEach(items.indices, id: \.self) { index in
                    let item = items[index]
                    Text(item.title)
                }
            }}
        }
        """#],options:SwiftImportOptions(values:["count":"0"]))
        XCTAssertEqual(report.pages[0].nodes.map(\.text),["Count: 0","Settings","Privacy"])
    }
    func testComputedArrayAliasesAndConcatenationKeepEverySettingsRow()throws {
        let report=try inspect(["DemoView.swift":"""
        import SwiftUI
        enum SampleData {static let other = [Item(title: "Privacy")]}
        struct DemoView: View {
            var items: [Item] {[Item(title: "Account")] + SampleData.other}
            var body: some View {VStack {ForEach(items.indices, id: \\.self) { index in
                let item = items[index]
                Text(item.title)
            }}}
        }
        """])
        XCTAssertEqual(report.pages[0].nodes.map(\.text),["Account","Privacy"])
    }
    func testConstructorLabelsAreNotReplacedByParentProperties()throws {
        let report=try inspect(["DemoView.swift":"""
        import SwiftUI
        struct DemoView: View {var body:some View {Rows(title:"Header",items:[Item(title:"Settings"),Item(title:"Privacy")])}}
        struct Rows: View {
            let title:String
            let items:[Item]
            var body:some View {VStack {ForEach(items.indices,id: \\.self) {index in
                let item=items[index]
                Text(item.title)
            }}}
        }
        """])
        XCTAssertEqual(report.pages[0].nodes.map(\.text),["Settings","Privacy"])
    }
}
