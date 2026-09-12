import XCTest
@testable import StudioCore

final class PlatformExportTests:XCTestCase {
    func testResizeChangesSizeWithoutMovingOrigin() {
        let r=LayoutEngine.resized(Rect(20,30,120,80),dx:60,dy:20)
        XCTAssertEqual(r,Rect(20,30,180,100))
    }
    func testProportionalResizeAndMinimumSize() {
        let r=LayoutEngine.resized(Rect(20,30,120,80),dx:60,dy:2,keepAspect:true)
        XCTAssertEqual(r,Rect(20,30,180,120))
        let minimum=LayoutEngine.resized(Rect(20,30,120,80),dx:-999,dy:-999,keepAspect:true)
        XCTAssertEqual(minimum.width,12,accuracy:0.0001)
        XCTAssertEqual(minimum.width/minimum.height,1.5,accuracy:0.0001)
        XCTAssertEqual(LayoutEngine.resized(Rect(),dx:-999,dy:-999).height,1)
    }
    func testOldProjectWithoutPlatformCustomFieldsDecodes() throws {
        let p=DesignProject.demo();let data=try JSONEncoder().encode(p)
        XCTAssertFalse(String(data:data,encoding:.utf8)!.contains("flutterCode"))
        XCTAssertEqual(try JSONDecoder().decode(DesignProject.self,from:data),p)
    }
    func testPlatformStringLiteralEscapesInterpolation() {
        XCTAssertEqual(DesignExporter.literal("${danger}\n\"\\"),"\"\\${danger}\\n\\\"\\\\\"")
    }
    func testBothExportFormatsContainCompletePlatformFilesAndWarnings() throws {
        let dir=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at:dir,withIntermediateDirectories:true)
        defer{try? FileManager.default.removeItem(at:dir)}
        var p=DesignProject.demo();p.pages[0].nodes.append(DesignNode(kind:.custom))
        for format in [ExportFormat.flutter,.android] {
            let out=try DesignExporter.export(p,format:format,to:dir)
            XCTAssertEqual(try ProjectStore.load(out.appendingPathComponent("Design.framestudio")),SharedTabBar.normalized(p))
            let report=try String(contentsOf:out.appendingPathComponent("EXPORT_REPORT.md"),encoding:.utf8)
            XCTAssertTrue(report.contains("自定义组件：1"))
            let path=format == .flutter ? "android/gradle/wrapper/gradle-wrapper.jar" : "gradle/wrapper/gradle-wrapper.jar"
            XCTAssertTrue(FileManager.default.fileExists(atPath:out.appendingPathComponent(path).path))
            XCTAssertFalse(FileManager.default.fileExists(atPath:out.appendingPathComponent("android/local.properties").path))
        }
    }
    func testSymbolMappingCoversNavigationAndProfile() {
        XCTAssertEqual(MaterialSymbols.key("sidebar.left"),"menu")
        XCTAssertEqual(MaterialSymbols.key("person.crop.circle.fill"),"person")
        XCTAssertEqual(MaterialSymbols.key("unknown.symbol"),"info")
    }
    func testLargeKotlinPayloadUsesRuntimeChunksInsteadOfOversizedConstants() {
        let text=String(repeating:"页面𐐷$",count:10000)
        let expression=DesignExporter.kotlinString(text)
        XCTAssertTrue(expression.hasPrefix("buildString"))
        XCTAssertGreaterThan(expression.components(separatedBy:"append(").count,4)
        XCTAssertFalse(expression.contains(" + "))
    }

    func testAllThreeFormatsAreSourceOnlyHandoffs() throws {
        let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true)
        defer{try? FileManager.default.removeItem(at:root)}
        for format in ExportFormat.allCases {
            let output=try DesignExporter.export(.demo(),format:format,to:root)
            try ExportContract.validateSourceOnly(output)
            let manifest=try JSONSerialization.jsonObject(with:Data(contentsOf:output.appendingPathComponent("export-manifest.json"))) as! [String:Any]
            XCTAssertEqual(manifest["exportKind"] as? String,"ui-source-only")
            XCTAssertEqual(manifest["includesMobileBinary"] as? Bool,false)
            XCTAssertEqual(manifest["businessLogicImplemented"] as? Bool,false)
            XCTAssertTrue(FileManager.default.fileExists(atPath:output.appendingPathComponent("UI_HANDOFF.md").path))
        }
    }

}
