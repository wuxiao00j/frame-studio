import XCTest
@testable import StudioCore

final class SharedTabBarTests:XCTestCase {
    func tabs(_ project:DesignProject)->[DesignNode] {project.pages.flatMap(\.nodes).filter{$0.kind == .tabBar}}
    func assertShared(_ project:DesignProject,file:StaticString=#filePath,line:UInt=#line) {
        let values=tabs(project).map{SharedTabBar.configuration($0)}
        for value in values {XCTAssertEqual(value,values.first,file:file,line:line)}
    }
    func temporaryURL()->URL {FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("Design.framestudio")}

    func testEditingLastPageSharesCompleteConfigurationAndPreservesIdentity() {
        let before=SharedTabBar.normalized(.demo());var project=before
        let pi=project.pages.count-1,ni=project.pages[pi].nodes.firstIndex{$0.kind == .tabBar}!
        project.pages[pi].nodes[ni].items.reverse()
        project.pages[pi].nodes[ni].items[0].title="Profile"
        project.pages[pi].nodes[ni].items[0].selectedSymbol="star.fill"
        project.pages[pi].nodes[ni].items[0].iconData="YWJj"
        project.pages[pi].nodes[ni].items[0].selectedIconData="ZGVm"
        project.pages[pi].nodes[ni].items.append(NavigationItem(title:"Extra",symbol:"plus",pageID:project.pages[0].id))
        project.pages[pi].nodes[ni].fill="010203";project.pages[pi].nodes[ni].accent="F12345"
        project.pages[pi].nodes[ni].cornerRadius=32;project.pages[pi].nodes[ni].fontSize=15
        project.pages[pi].nodes[ni].iconSize=26;project.pages[pi].nodes[ni].spacing=8
        project.pages[pi].nodes[ni].borderWidth=2;project.pages[pi].nodes[ni].shadow=3
        project.pages[pi].nodes[ni].fixedToViewport=false;project.pages[pi].nodes[ni].hidden=true
        project.pages[pi].nodes[ni].locked=true;project.pages[pi].nodes[ni].syncTabIcons=false
        project.pages[pi].nodes[ni].groupID="page-local-group"
        project.pages[pi].nodes[ni].sourceReference="imported-source"
        let source=project.pages[pi].nodes[ni]
        SharedTabBar.reconcile(&project,before:before)
        assertShared(project)
        XCTAssertEqual(SharedTabBar.configuration(tabs(project)[0]),SharedTabBar.configuration(source))
        XCTAssertEqual(tabs(project).map(\.id),tabs(before).map(\.id))
        XCTAssertEqual(tabs(project)[0].groupID,tabs(before)[0].groupID)
        XCTAssertEqual(tabs(project).last?.groupID,"page-local-group")
        XCTAssertEqual(tabs(project).last?.sourceReference,"imported-source")
        XCTAssertTrue(tabs(project).allSatisfy{$0.syncTabIcons == true})
    }

    func testNewTabInheritsEvenIfInsertedBeforeExistingTabs() {
        let before=SharedTabBar.normalized(.demo());var project=before
        var new=DesignNode(kind:.tabBar);new.fill="FF0000"
        project.pages.insert(DesignPage(name:"New",nodes:[new]),at:0)
        project.pages.append(DesignPage(name:"No Tab",nodes:[DesignNode(kind:.text)]))
        SharedTabBar.reconcile(&project,before:before)
        assertShared(project)
        XCTAssertEqual(tabs(project)[0].fill,tabs(before)[0].fill)
        XCTAssertEqual(tabs(project)[0].id,new.id)
        XCTAssertEqual(project.pages.last?.nodes.count,1)
        XCTAssertFalse(project.pages.last!.nodes.contains{$0.kind == .tabBar})
    }

    func testVariantResizeDoesNotFlattenOtherScreens() {
        let before=SharedTabBar.normalized(.demo());var project=before
        let index=project.pages[1].nodes.firstIndex{$0.kind == .tabBar}!
        let frame=Rect(32,350,450,80)
        project.pages[1].nodes[index].frames[Variant.innerLandscape.rawValue]=frame
        SharedTabBar.reconcile(&project,before:before)
        for tab in tabs(project) {
            XCTAssertEqual(tab.frame(.innerLandscape,device:project.device),frame)
            for v in Variant.allCases where v != .innerLandscape {
                XCTAssertEqual(tab.frame(v,device:project.device),tabs(before)[0].frame(v,device:project.device))
            }
        }
    }

    func testRemovingTabOrPageDoesNotRecreateItOrKeepDeadRoutes() {
        let before=SharedTabBar.normalized(.demo());var project=before
        project.pages[0].nodes.removeAll{$0.kind == .tabBar}
        let removed=project.pages.removeLast().id
        for pi in project.pages.indices {for ni in project.pages[pi].nodes.indices {project.pages[pi].nodes[ni].items.removeAll{$0.pageID==removed}}}
        SharedTabBar.reconcile(&project,before:before)
        XCTAssertEqual(tabs(project).count,1)
        XCTAssertFalse(project.pages[0].nodes.contains{$0.kind == .tabBar})
        XCTAssertFalse(tabs(project)[0].items.contains{$0.pageID==removed})
    }

    func testPersistenceRevisionAndHistoryKeepAllTabsConsistent() throws {
        let url=temporaryURL();defer{try? FileManager.default.removeItem(at:url.deletingLastPathComponent())}
        let original=try ProjectStore.save(.demo(),to:url,expectedRevision:nil)
        let changed=try ProjectStore.update(url,expectedRevision:original.revision){p in
            let index=p.pages[2].nodes.firstIndex{$0.kind == .tabBar}!
            p.pages[2].nodes[index].cornerRadius=41
            p.pages[2].nodes[index].items.removeFirst()
        }
        assertShared(changed);XCTAssertEqual(tabs(changed)[0].cornerRadius,41)
        XCTAssertEqual(changed.revision,original.revision+1)
        XCTAssertThrowsError(try ProjectStore.save(original,to:url,expectedRevision:original.revision))
        var undo=original;undo.revision=changed.revision
        let restored=try ProjectStore.save(undo,to:url,expectedRevision:changed.revision)
        assertShared(restored);XCTAssertEqual(tabs(restored)[0].items,tabs(original)[0].items)
        var redo=changed;redo.revision=restored.revision
        let redone=try ProjectStore.save(redo,to:url,expectedRevision:restored.revision)
        XCTAssertEqual(try ProjectStore.load(url),redone);assertShared(redone)
        XCTAssertEqual(tabs(redone)[0].cornerRadius,41)
    }

    func testLegacyLoadAndAllExportsNormalizeWithoutRewritingInput() throws {
        let url=temporaryURL();defer{try? FileManager.default.removeItem(at:url.deletingLastPathComponent())}
        var legacy=DesignProject.demo()
        let index=legacy.pages[2].nodes.firstIndex{$0.kind == .tabBar}!
        legacy.pages[2].nodes[index].fill="FF0000";legacy.pages[2].nodes[index].syncTabIcons=false
        try FileManager.default.createDirectory(at:url.deletingLastPathComponent(),withIntermediateDirectories:true)
        let raw=try JSONEncoder().encode(legacy);try raw.write(to:url)
        let loaded=try ProjectStore.load(url);assertShared(loaded)
        XCTAssertEqual(loaded.revision,legacy.revision);XCTAssertEqual(try Data(contentsOf:url),raw)
        for format in ExportFormat.allCases {
            let output=try DesignExporter.export(legacy,format:format,to:url.deletingLastPathComponent())
            let exported=try JSONDecoder().decode(DesignProject.self,from:Data(contentsOf:output.appendingPathComponent("Design.framestudio")))
            assertShared(exported);XCTAssertEqual(exported,loaded)
        }
        XCTAssertEqual(try Data(contentsOf:url),raw)
    }

    func testBulkConflictUsesDocumentOrderAndMetadataDoesNotOverrideAnEdit() {
        let before=SharedTabBar.normalized(.demo());var project=before
        let first=project.pages[0].nodes.firstIndex{$0.kind == .tabBar}!
        let last=project.pages[2].nodes.firstIndex{$0.kind == .tabBar}!
        project.pages[0].nodes[first].groupID="local"
        project.pages[2].nodes[last].padding=7
        SharedTabBar.reconcile(&project,before:before)
        XCTAssertEqual(tabs(project)[0].padding,7)
        project.pages[0].nodes[first].padding=9
        project.pages[2].nodes[last].padding=11
        SharedTabBar.reconcile(&project,before:before)
        assertShared(project);XCTAssertEqual(tabs(project)[0].padding,9)
    }

    func testBackButtonStartsAtTopLeftAndDecompositionUngroupsWithoutMoving() {
        let device=DeviceProfile(),back=DesignNode(kind:.backButton)
        XCTAssertTrue(back.isFixed);XCTAssertEqual(back.anchor,.topLeft)
        for v in Variant.allCases {XCTAssertEqual(back.frame(v,device:device),Rect(16,52,80,44))}
        var nav=DesignNode(kind:.navigationBar);nav.navigationAction="back";nav.groupID="old-group"
        nav.frames[Variant.innerLandscape.rawValue]=Rect(30,24,650,56)
        let parts=ComponentAssembly.decompose(nav,device:device)
        XCTAssertTrue(parts.allSatisfy{$0.groupID.isEmpty})
        let button=parts.first{$0.kind == .backButton}!
        for v in Variant.allCases {
            let source=nav.frame(v,device:device),frame=button.frame(v,device:device)
            XCTAssertEqual(frame.x,source.x+nav.padding);XCTAssertEqual(frame.y,source.y)
            XCTAssertEqual(frame.width,44);XCTAssertEqual(frame.height,source.height)
        }
        let template=ComponentTemplate(name:"Recombined",nodes:parts)
        let merged=ComponentAssembly.instantiate(template,origin:Rect(20,200),variant:.standardPortrait,device:device,pages:[])
        XCTAssertEqual(Set(merged.map(\.groupID)).count,1);XCTAssertFalse(merged[0].groupID.isEmpty)
    }
}
