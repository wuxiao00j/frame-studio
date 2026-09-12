import XCTest
@testable import StudioCore

final class StudioCoreTests:XCTestCase {
    func temporaryDirectory() throws -> URL {let url=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString);try FileManager.default.createDirectory(at:url,withIntermediateDirectories:true);addTeardownBlock{try? FileManager.default.removeItem(at:url)};return url}
    func testRoundTripPreservesVariantsAndNavigation() throws {
        var project=DesignProject.demo();project.wideMode=true
        project.pages[0].nodes[0].frames[Variant.innerLandscape.rawValue]=Rect(17,28,500,50)
        let url=try temporaryDirectory().appendingPathComponent("Design.framestudio")
        let saved=try ProjectStore.save(project,to:url,expectedRevision:nil)
        XCTAssertEqual(try ProjectStore.load(url),saved)
        XCTAssertEqual(saved.pages[0].nodes.last!.items[1].pageID,saved.pages[1].id)
    }
    func testConcurrentWriterCannotOverwrite() throws {
        let url=try temporaryDirectory().appendingPathComponent("Design.framestudio")
        let first=try ProjectStore.save(.demo(),to:url,expectedRevision:nil)
        let updated=try ProjectStore.update(url,expectedRevision:first.revision){$0.name="Agent change"}
        XCTAssertThrowsError(try ProjectStore.save(first,to:url,expectedRevision:first.revision))
        XCTAssertEqual(try ProjectStore.load(url),updated)
    }
    func testInvalidMutationRollsBack() throws {
        let url=try temporaryDirectory().appendingPathComponent("Design.framestudio")
        let before=try ProjectStore.save(.demo(),to:url,expectedRevision:nil)
        XCTAssertThrowsError(try ProjectStore.update(url,expectedRevision:before.revision){$0.pages[0].nodes[0].targetPageID="missing"})
        XCTAssertEqual(try ProjectStore.load(url),before)
    }
    func testSmartGuidesSnapToSiblingCenter() {
        let result=LayoutEngine.snap(Rect(48,200,104,40),others:[Rect(60,40,80,80)],size:Dimensions(393,852),threshold:3)
        XCTAssertEqual(result.frame.midX,100,accuracy:0.001)
        XCTAssertEqual(result.vertical,100)
    }
    func testAlignmentAndDistribution() {
        let device=DeviceProfile()
        var nodes=[DesignNode(kind:.text,frame:Rect(10,10,20,30)),DesignNode(kind:.text,frame:Rect(99,80,40,30)),DesignNode(kind:.text,frame:Rect(210,140,30,30))]
        let ids=Set(nodes.map(\.id))
        LayoutEngine.align(&nodes,ids:ids,variant:.standardPortrait,device:device,alignment:"distributeX")
        let r=nodes.map{$0.frame(.standardPortrait,device:device)}
        XCTAssertEqual(r[1].x-(r[0].x+r[0].width),r[2].x-(r[1].x+r[1].width),accuracy:0.001)
        LayoutEngine.align(&nodes,ids:[nodes[0].id],variant:.standardPortrait,device:device,alignment:"centerX")
        XCTAssertEqual(nodes[0].frame(.standardPortrait,device:device).midX,196.5,accuracy:0.001)
    }
    func testLockedNodeIsExcludedFromAlignment() {
        var n=DesignNode(kind:.text);n.locked=true;var nodes=[n]
        LayoutEngine.align(&nodes,ids:[n.id],variant:.standardPortrait,device:DeviceProfile(),alignment:"right")
        XCTAssertEqual(nodes,[n])
    }
    func testExportProducesEveryComponentAndRealFiles() throws {
        var p=DesignProject.demo();var page=DesignPage(name:"全部组件")
        page.nodes=ComponentKind.allCases.map{DesignNode(kind:$0)};p.pages.append(page)
        let dir=try temporaryDirectory();let out=try SwiftExporter.export(p,to:dir)
        XCTAssertTrue(FileManager.default.fileExists(atPath:out.appendingPathComponent("GeneratedApp.xcodeproj/project.pbxproj").path))
        XCTAssertEqual(try ProjectStore.load(out.appendingPathComponent("Design.framestudio")),SharedTabBar.normalized(p))
        let sources=try FileManager.default.contentsOfDirectory(at:out.appendingPathComponent("Sources/GeneratedUI"),includingPropertiesForKeys:nil)
        XCTAssertEqual(sources.filter{$0.pathExtension=="swift"}.count,p.pages.count+2)
        let second=try SwiftExporter.export(p,to:dir);XCTAssertNotEqual(out,second)
    }
    func testSwiftStringEscapingCannotInjectExpression() {
        let hostile="hi\"\n\\(fatalError())\u{0}";let escaped=SwiftExporter.literal(hostile)
        XCTAssertEqual(escaped,"\"hi\\\"\\n\\\\(fatalError())\\u{0}\"")
    }
    func testSourceImporterReportsLossAndNeverRunsCode() throws {
        let dir=try temporaryDirectory();let file=dir.appendingPathComponent("Legacy.swift")
        try #"import SwiftUI; struct Legacy: View {var body: some View {VStack {Text("Old UI"); Image(systemName: "star"); Toggle("Enabled", isOn: .constant(true))}}}"#.write(to:file,atomically:true,encoding:.utf8)
        let report=try SwiftImporter.inspect(dir)
        XCTAssertEqual(report.pages.count,1);XCTAssertEqual(report.pages[0].nodes.count,3)
        XCTAssertEqual(report.pages[0].nodes[1].symbol,"star");XCTAssertFalse(report.warnings.isEmpty)
    }
    func testLandscapeSwapsDimensionsAndExplicitLayoutWins() {
        let d=DeviceProfile();XCTAssertEqual(d.size(.innerLandscape),Dimensions(798,570))
        var n=DesignNode(kind:.button);n.frames[Variant.outerPortrait.rawValue]=Rect(9,11,222,44)
        XCTAssertEqual(n.frame(.outerPortrait,device:d),Rect(9,11,222,44))
        XCTAssertNotEqual(n.frame(.innerPortrait,device:d),Rect(9,11,222,44))
    }
    func testExportRejectsPathTraversalIdentifiers() throws {
        var p=DesignProject.demo();p.pages[0].nodes[0].id="../asset"
        XCTAssertThrowsError(try ProjectStore.validate(p))
    }
    func testExportIdentifiersDoNotCollideAfterNormalization() {
        XCTAssertNotEqual(SwiftExporter.identifier("a-b"),SwiftExporter.identifier("ab"))
    }
    func testSourceInventoryIncludesFlutterAndSkipsDependencies() throws {
        let dir=try temporaryDirectory()
        try "Widget build() => Text('old');".write(to:dir.appendingPathComponent("profile.dart"),atomically:true,encoding:.utf8)
        try FileManager.default.createDirectory(at:dir.appendingPathComponent("node_modules"),withIntermediateDirectories:true)
        try "ignored".write(to:dir.appendingPathComponent("node_modules/noise.tsx"),atomically:true,encoding:.utf8)
        let inventory=try SourceInspector.inventory(dir)
        XCTAssertEqual((inventory["sourceFiles"] as? [String])?.count,1)
        XCTAssertTrue(try SourceInspector.read(dir.appendingPathComponent("profile.dart"))["source"]!.contains("Widget"))
    }

}
