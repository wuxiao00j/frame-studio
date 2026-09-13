import XCTest
@testable import StudioCore

final class TemplateLibraryTests:XCTestCase {
    func testBundledTemplatesAreCategorizedPortableAndIndependent()throws {
        XCTAssertEqual(TemplateCatalog.bundled.count,7)
        for template in TemplateCatalog.bundled {
            XCTAssertTrue(TemplateCatalog.categories.contains(template.categoryTitle))
            for node in template.nodes{XCTAssertEqual(node.frames.count,6)}
            let first=ComponentAssembly.instantiate(template,origin:Rect(24,120),variant:.standardPortrait,device:DeviceProfile(),pages:[])
            let second=ComponentAssembly.instantiate(template,origin:Rect(24,120),variant:.standardPortrait,device:DeviceProfile(),pages:[])
            XCTAssertTrue(Set(first.map(\.id)).isDisjoint(with:second.map(\.id)))
            var p=DesignProject();p.pages=[DesignPage(name:"Test",nodes:first+second)];p.templates=[template];try ProjectStore.validate(p)
        }
    }
    func testPersonalLibrarySurvivesReloadAndRejectsStaleOrInvalidWrites()throws {
        let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString),url=root.appendingPathComponent("Library.framestudio")
        defer{try? FileManager.default.removeItem(at:root)}
        XCTAssertEqual(try PersonalComponentLibrary.load(url).revision,0)
        XCTAssertFalse(FileManager.default.fileExists(atPath:url.path))
        let t=TemplateCatalog.bundled[0]
        let saved=try PersonalComponentLibrary.update(url,expectedRevision:0){$0.append(t)}
        XCTAssertEqual(try PersonalComponentLibrary.load(url).templates,[t])
        XCTAssertThrowsError(try PersonalComponentLibrary.update(url,expectedRevision:0){$0=[]})
        XCTAssertThrowsError(try PersonalComponentLibrary.update(url,expectedRevision:saved.revision){$0[0].nodes[0].fontSize = -5})
        XCTAssertEqual(try PersonalComponentLibrary.load(url),saved)
        let changed=try PersonalComponentLibrary.update(url,expectedRevision:saved.revision){$0[0].category="我的表单"}
        XCTAssertEqual(changed.templates[0].categoryTitle,"我的表单")
    }
    func testLegacyTemplateCategoryAndAllRenderingPropertiesSurviveCopy()throws {
        var n=DesignNode(kind:.selectField);n.controlStyle="formRow";n.selectedIndex=1;n.isEnabled=false;n.material="thin"
        n.clipMasks=["standardPortrait":[DesignClipMask(rect:Rect(0,0,1,1),radius:0.1)]]
        let legacy=ComponentTemplate(name:"Picker",nodes:[n])
        let decoded=try JSONDecoder().decode(ComponentTemplate.self,from:JSONEncoder().encode(legacy))
        XCTAssertNil(decoded.category);XCTAssertEqual(decoded.categoryTitle,"表单与选择")
        let copied=TemplateCatalog.portable(decoded,device:DeviceProfile())
        XCTAssertEqual(copied.nodes[0].clipMasks,n.clipMasks);XCTAssertEqual(copied.nodes[0].material,"thin")
        XCTAssertEqual(copied.nodes[0].selectedIndex,1);XCTAssertEqual(copied.nodes[0].isEnabled,false)
        XCTAssertEqual(copied.nodes[0].frames.count,6)
    }
}
