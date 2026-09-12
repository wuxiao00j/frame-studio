import XCTest
@testable import StudioCore

final class ComponentBehaviorTests:XCTestCase {
    func testLegacyDefaultsStayUsable() throws {
        let p=try JSONDecoder().decode(DesignProject.self,from:JSONEncoder().encode(DesignProject.demo()))
        XCTAssertTrue(p.pages[0].isScrollable)
        let toggle=DesignNode(kind:.toggle)
        XCTAssertEqual(toggle.position,"trailing");XCTAssertFalse(toggle.hasIcon)
        XCTAssertTrue(DesignNode(kind:.profileRow).hasQRCode)
    }
    func testListRowsJoinAndOnlyOuterCornersRemain() {
        let d=DeviceProfile();var page=DesignPage(name:"列表")
        page.appendComponent(DesignNode(kind:.listRow,frame:Rect(20,120,300,60)),device:d)
        page.appendComponent(DesignNode(kind:.listRow),device:d)
        page.appendComponent(DesignNode(kind:.listRow),device:d)
        for v in Variant.allCases {
            let r=page.nodes.map{$0.frame(v,device:d)}
            XCTAssertEqual(r[1].x,r[0].x);XCTAssertEqual(r[1].y,r[0].y+r[0].height)
            XCTAssertEqual(r[2].y,r[1].y+r[1].height)
            XCTAssertEqual(page.corners(page.nodes[0],variant:v,device:d).bl,0)
            XCTAssertEqual(page.corners(page.nodes[1],variant:v,device:d),CornerRadii(0))
            XCTAssertEqual(page.corners(page.nodes[2],variant:v,device:d).br,14)
        }
        page.nodes.remove(at:1)
        XCTAssertEqual(page.corners(page.nodes[0],variant:.standardPortrait,device:d).bl,14)
    }
    func testLongContentExcludesFixedBarsAndReservesFooter() {
        let d=DeviceProfile();var page=DesignPage(name:"长页",nodes:[DesignNode(kind:.listRow,frame:Rect(24,1500,345,68)),DesignNode(kind:.tabBar)])
        XCTAssertEqual(page.contentHeight(.standardPortrait,device:d),1672)
        page.contentHeights=[Variant.standardPortrait.rawValue:2200]
        XCTAssertEqual(page.contentHeight(.standardPortrait,device:d),2200)
        page.scrollEnabled=false;XCTAssertEqual(page.contentHeight(.standardPortrait,device:d),852)
    }
    func testProgressValuesAndLabels() {
        var n=DesignNode(kind:.progress);n.progressCurrent=25;n.progressTotal=80;n.progressLabel="fraction"
        XCTAssertEqual(n.fraction,0.3125);XCTAssertEqual(n.progressText,"25/80")
        n.progressLabel="percent";XCTAssertEqual(n.progressText,"31%")
        n.progressCurrent=160;XCTAssertEqual(n.fraction,1)
    }
    func testProfileDecompositionAndTemplateAreEditable() {
        var profile=DesignNode(kind:.profileRow);profile.showQRCode=false
        let parts=ComponentAssembly.decompose(profile,device:DeviceProfile())
        XCTAssertFalse(parts.contains{$0.kind == .qrCode})
        XCTAssertTrue(parts.allSatisfy{$0.groupID.isEmpty})
        XCTAssertTrue(parts.contains{$0.kind == .avatar});XCTAssertEqual(parts.filter{$0.kind == .text}.count,2)
        let template=ComponentTemplate(name:"我的资料卡",nodes:parts)
        let inserted=ComponentAssembly.instantiate(template,origin:Rect(40,1200),variant:.standardPortrait,device:DeviceProfile(),pages:[])
        XCTAssertTrue(Set(inserted.map(\.id)).isDisjoint(with:Set(parts.map(\.id))))
        XCTAssertEqual(Set(inserted.map(\.groupID)).count,1)
        XCTAssertEqual(inserted.map{$0.frame(.standardPortrait,device:DeviceProfile()).y}.min(),1200)
    }
    func testSelectedSymbolOverridesDefaultUploadedIcon() {
        var item=NavigationItem(title:"我的",symbol:"person");item.iconData="YWJj";item.selectedSymbol="star.fill"
        XCTAssertNil(item.activeIconData);XCTAssertEqual(item.activeSymbol,"star.fill")
        item.selectedIconData="ZGVm";XCTAssertEqual(item.activeIconData,"ZGVm")
    }
    func testImportClassifiesKnownAndReportsUnknown() throws {
        let dir=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at:dir,withIntermediateDirectories:true);defer{try? FileManager.default.removeItem(at:dir)}
        let source="import SwiftUI\nstruct Demo: View { var body: some View { VStack { Toggle(\"通知\", isOn: .constant(true)); ProgressView(value: 25, total: 80); SpecialOrbitWidget() } } }"
        try source.write(to:dir.appendingPathComponent("Demo.swift"),atomically:true,encoding:.utf8)
        let report=try SwiftImporter.inspect(dir)
        XCTAssertTrue(report.classifications.contains{$0.sourceType=="Toggle" && $0.componentKind=="toggle"})
        XCTAssertTrue(report.unmatched.contains{$0.typeName=="SpecialOrbitWidget"})
        XCTAssertTrue(report.pages[0].nodes.contains{$0.kind == .custom && $0.name.contains("SpecialOrbitWidget")})
    }
    func testTabIconUpdatesFollowDestinationAcrossPages() {
        var p=DesignProject.demo()
        let index=p.pages[0].nodes.firstIndex{$0.kind == .tabBar}!
        let previous=p
        let before=p.pages[0].nodes[index]
        var after=before;after.items[2].selectedSymbol="star.fill";after.items[2].iconData="YWJj"
        p.pages[0].nodes[index]=after
        SharedTabBar.reconcile(&p,before:previous)
        for page in p.pages {let tab=page.nodes.first{$0.kind == .tabBar}!;XCTAssertEqual(tab.items[2].selectedSymbol,"star.fill");XCTAssertEqual(tab.items[2].iconData,"YWJj")}
    }

}
