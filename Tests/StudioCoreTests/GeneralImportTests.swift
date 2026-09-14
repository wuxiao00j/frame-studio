import XCTest
@testable import StudioCore

final class GeneralImportTests:XCTestCase {
    func inspect(_ source:String,files:[String:String]=[:],options:SwiftImportOptions=SwiftImportOptions())throws->ImportReport {
        let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true);defer{try? FileManager.default.removeItem(at:root)}
        try source.write(to:root.appendingPathComponent("DemoView.swift"),atomically:true,encoding:.utf8)
        for (name,text) in files {let file=root.appendingPathComponent(name);try FileManager.default.createDirectory(at:file.deletingLastPathComponent(),withIntermediateDirectories:true);try text.write(to:file,atomically:true,encoding:.utf8)}
        return try SwiftImporter.inspect(root,options:options)
    }
    func testLocalizedWrappersAndVerbatimTextResolveFromSourceValues()throws {
        let report=try inspect(#"""
        import SwiftUI
        struct DemoView:View {
            let title="关于应用"
            var body:some View {VStack {Text(LocalizedStringKey(title));Text(verbatim:"a == b && c != d");Text(String(12))}}
        }
        """#)
        XCTAssertEqual(report.pages[0].nodes.map(\.text),["关于应用","a == b && c != d","12"])
    }
    func testOptionalStateAndNumericConditionsAvoidFalseErrorAndEmptyListBranches()throws {
        let report=try inspect(#"""
        import SwiftUI
        struct DemoView:View {
            @State private var errorText:String?
            @State private var title=""
            @State private var items:[String]=[]
            var normalized:String {title.trimmingCharacters(in:.whitespacesAndNewlines)}
            var body:some View {VStack {
                if let errorText {Text(errorText)}
                if items.count > 0 {Text("Has items")}
                if !normalized.isEmpty && items.count >= 1 {Text("Ready")}
                if items.count <= 0 {Text("Empty")}
            }}
        }
        """#)
        XCTAssertEqual(report.pages[0].nodes.map(\.text),["Empty"])
    }
    func testNativeControlsBecomeEditablePresetsWithoutRunningActions()throws {
        let report=try inspect(#"""
        import SwiftUI
        struct DemoView:View {var body:some View {VStack {
            Capsule().fill(Color.red).frame(width:180,height:36)
            Ellipse().fill(Color.blue).frame(width:180,height:90)
            LabeledContent("版本",value:"1.0")
            Menu("更多") {Button("编辑"){dangerousOperation()};Button {} label:{Label("分享",systemImage:"square.and.arrow.up")}}
            ContentUnavailableView("暂无记录",systemImage:"tray",description:Text("请稍后再试"))
        }}}
        """#)
        let n=report.pages[0].nodes
        XCTAssertEqual(n.map(\.kind),[.capsule,.ellipse,.keyValueRow,.menuButton,.emptyState])
        XCTAssertEqual(n[2].subtitle,"1.0")
        XCTAssertEqual(n[3].items.map(\.title),["编辑","分享"])
        XCTAssertEqual(n[4].subtitle,"请稍后再试")
        XCTAssertFalse(n.contains{$0.text.contains("dangerous")})
        try ProjectStore.validate(report.project(named:"Controls"))
    }
    func testSectionClosuresAndDirectListDataRemainVisible()throws {
        let report=try inspect(#"""
        import SwiftUI
        struct DemoView:View {var body:some View {Form {
            Section {TextField("名称",text:.constant(""))} header:{Text("分组标题")} footer:{Text("分组说明")}
            List([Entry(title:"第一行"),Entry(title:"第二行")]) {item in Text(item.title)}
        }}}
        """#)
        let texts=report.pages[0].nodes.map(\.text)
        for text in ["分组标题","分组说明","第一行","第二行"]{XCTAssertTrue(texts.contains(text),text)}
        XCTAssertFalse(texts.contains{$0.contains("〈item")})
    }
    func testSourceLocalizationRespectsStringVersusVerbatimSemantics()throws {
        let catalog=#"{"sourceLanguage":"en","strings":{"hello":{"localizations":{"zh-Hans":{"stringUnit":{"state":"translated","value":"你好"}}}}}}"#
        let report=try inspect(#"""
        import SwiftUI
        struct DemoView:View {let key="hello"
            var body:some View {VStack {Text("hello");Text(key);Text(verbatim:"hello");Text(LocalizedStringKey(key));Text(String(localized:"hello"))}}
        }
        """#,files:["Localizable.xcstrings":catalog],options:SwiftImportOptions(language:"zh-Hans"))
        XCTAssertEqual(report.pages[0].nodes.map(\.text),["你好","hello","hello","你好","你好"])
    }
    func testBundleMetadataComesFromSourceProjectAndNotEditorProcess()throws {
        let info="""
        <?xml version="1.0" encoding="UTF-8"?><plist version="1.0"><dict><key>CFBundleDisplayName</key><string>Example Reader</string><key>CFBundleShortVersionString</key><string>4.2</string></dict></plist>
        """
        let report=try inspect(#"""
        import SwiftUI
        struct DemoView:View {
            var name:String {Bundle.main.object(forInfoDictionaryKey:"CFBundleDisplayName") as? String ?? "Fallback"}
            var version:String {Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"}
            var body:some View {VStack {Text(name);Text(version)}}
        }
        """#,files:["Info.plist":info])
        XCTAssertEqual(report.pages[0].nodes.map(\.text),["Example Reader","4.2"])
    }
    func testLocalFunctionsAndOptionalBindingsResolve()throws {
        let report=try inspect(#"""
        import SwiftUI
        enum Item:String {case first
            var title:String {"第一项"}
        }
        struct DemoView:View {
            let optionalTitle:String?="有内容"
            let unused:String?=nil
            var body:some View {VStack {Text(label(for:.first));Text(unwrapped)}}
            func label(for item:Item)->String {item.title}
            var unwrapped:String {if let value=optionalTitle, !value.isEmpty {return value};return "空"}
        }
        """#)
        XCTAssertEqual(report.pages[0].nodes.map(\.text),["第一项","有内容"])
    }
    func testKnownParentInputsPropagate()throws {
        let report=try inspect(#"""
        import SwiftUI
        struct RootView:View {
            @State var error:String?
            let name="账户"
            var body:some View {Text("Root").sheet(isPresented:.constant(true)){LoginView(title:name,error:error)}}
        }
        struct LoginView:View {
            let title:String
            let error:String?
            var body:some View {VStack {Text(title);if let error {Text(error)}}}
        }
        """#)
        let page=try XCTUnwrap(report.pages.first{$0.name=="LoginView"})
        XCTAssertEqual(page.nodes.map(\.text),["账户"])
    }
    func testDynamicLoopInputsDoNotBorrowShadowedParentDefaults()throws {
        let report=try inspect(#"""
        import SwiftUI
        struct RootView:View {
            let name="Wrong parent value"
            var body:some View {ForEach(["First","Second"],id:\.self){name in DetailView(title:name)}}
        }
        struct DetailView:View {let title:String;var body:some View {Text(title)}}
        """#)
        let page=try XCTUnwrap(report.pages.first{$0.name=="DetailView"})
        XCTAssertEqual(page.nodes.first?.text,"〈title〉")
        let root=try XCTUnwrap(report.pages.first{$0.name=="RootView"})
        XCTAssertEqual(root.nodes.map(\.text),["First","Second"])
    }
    func testKeyPathAndClosureCallbacksUseKnownArguments()throws {
        let report=try inspect(#"""
        import SwiftUI
        enum Entry:String {case first;var title:String {"First entry"}}
        struct DemoView:View {
            let title:(Entry)->String = \.title
            let label:(Entry)->String = {item in item.title}
            var body:some View {VStack {Text(title(.first));Text(label(.first))}}
        }
        """#)
        XCTAssertEqual(report.pages[0].nodes.map(\.text),["First entry","First entry"])
    }
    func testXcodeMetadataExpansionLocalizedNameAndGeneratedInfo()throws {
        let objects:[String:Any]=[
            "project":["buildConfigurationList":"shared"],
            "shared":["buildConfigurations":["base"]],
            "base":["name":"Debug","buildSettings":["MARKETING_VERSION":"2.8","CURRENT_PROJECT_VERSION":"12"]],
            "app":["isa":"PBXNativeTarget","name":"Reader","productType":"com.apple.product-type.application","buildConfigurationList":"configs"],
            "configs":["buildConfigurations":["debug"]],
            "debug":["name":"Debug","buildSettings":["PRODUCT_NAME":"$(TARGET_NAME)","PRODUCT_BUNDLE_IDENTIFIER":"org.example.reader"]],
            "widget":["isa":"PBXNativeTarget","productType":"com.apple.product-type.app-extension","buildConfigurationList":"widgetConfigs"],
            "widgetConfigs":["buildConfigurations":["widgetDebug"]],
            "widgetDebug":["name":"Debug","buildSettings":["PRODUCT_NAME":"Wrong Widget","MARKETING_VERSION":"99"]]
        ]
        let data=try PropertyListSerialization.data(fromPropertyList:["rootObject":"project","objects":objects],format:.xml,options:0)
        let source=#"""
        import SwiftUI
        struct DemoView:View {var body:some View {VStack {
            Text(Bundle.main.object(forInfoDictionaryKey:"CFBundleDisplayName") as? String ?? "Fallback")
            Text(Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "Fallback")
            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0")
            Text(Bundle.main.bundleIdentifier ?? "")
        }}}
        """#
        let report=try inspect(source,files:["Demo.xcodeproj/project.pbxproj":String(decoding:data,as:UTF8.self),"Info.plist":"<plist version=\"1.0\"><dict><key>CFBundleName</key><string>$(PRODUCT_NAME)</string></dict></plist>","zh-Hans.lproj/InfoPlist.strings":"\"CFBundleDisplayName\" = \"阅读器\";"],options:SwiftImportOptions(language:"zh-Hans"))
        XCTAssertEqual(report.pages[0].nodes.map(\.text),["阅读器","Reader","2.8","org.example.reader"])
    }
    func testComplexEmptyStateRetainsNestedEditableContent()throws {
        let report=try inspect(#"""
        import SwiftUI
        struct DemoView:View {var body:some View {
            ContentUnavailableView {Label("Nothing here",systemImage:"tray")} description:{VStack{Text("First hint");Text("Second hint")}} actions:{Button("Retry"){}}
        }}
        """#)
        let texts=report.pages[0].nodes.map(\.text)
        for title in ["Nothing here","First hint","Second hint","Retry"]{XCTAssertTrue(texts.contains(title),title)}
        XCTAssertFalse(report.pages[0].nodes.contains{$0.kind == .emptyState})
    }
    func testAmbiguousMetadataAndUnresolvedExplicitVersionsAreNotGuessed()throws {
        let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true);defer{try? FileManager.default.removeItem(at:root)}
        let objects:[String:Any]=["app":["isa":"PBXNativeTarget","productType":"com.apple.product-type.application","buildConfigurationList":"configs"],"configs":["buildConfigurations":["debug"]],"debug":["name":"Debug","buildSettings":["CURRENT_PROJECT_VERSION":"99"]]]
        let build=root.appendingPathComponent("project.pbxproj")
        try PropertyListSerialization.data(fromPropertyList:["objects":objects],format:.xml,options:0).write(to:build)
        var files=[build]
        for (target,name) in [("First","First app"),("Second","Second app")] {
            let dir=root.appendingPathComponent(target),localized=dir.appendingPathComponent("zh-Hans.lproj")
            try FileManager.default.createDirectory(at:localized,withIntermediateDirectories:true)
            let info=dir.appendingPathComponent("Info.plist"),strings=localized.appendingPathComponent("InfoPlist.strings")
            try PropertyListSerialization.data(fromPropertyList:["CFBundleName":name,"CFBundleVersion":"$(UNKNOWN_VERSION)"],format:.xml,options:0).write(to:info)
            try "\"CFBundleDisplayName\" = \"\(name)\";".write(to:strings,atomically:true,encoding:.utf8)
            files += [info,strings]
        }
        let resources=SwiftImportResources(files:files,language:"zh-Hans")
        XCTAssertNil(resources.info["CFBundleName"]);XCTAssertNil(resources.info["CFBundleDisplayName"]);XCTAssertNil(resources.info["CFBundleVersion"])
    }
    func testEmptyStateAndKeyValuePresetsDecomposeIntoReusableLayers()throws {
        var empty=DesignNode(kind:.emptyState);empty.actionTitle="Retry";empty.targetPageID="destination"
        let layers=ComponentAssembly.decompose(empty,device:DeviceProfile())
        XCTAssertTrue(layers.contains{$0.kind == .icon && $0.symbol==empty.symbol})
        XCTAssertTrue(layers.contains{$0.kind == .textButton && $0.text=="Retry" && $0.targetPageID=="destination"})
        XCTAssertTrue(layers.allSatisfy{$0.groupID.isEmpty})
        var row=DesignNode(kind:.keyValueRow);row.text="Version";row.subtitle="2.8"
        let parts=ComponentAssembly.decompose(row,device:DeviceProfile())
        XCTAssertEqual(parts.filter{$0.kind == .text}.map(\.text),["Version","2.8"])
    }
}
