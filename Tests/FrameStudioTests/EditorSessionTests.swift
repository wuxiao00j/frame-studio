import XCTest
import SwiftUI
import StudioCore
@testable import FrameStudio

final class EditorSessionTests:XCTestCase {
    func testSavedPersonalTemplateIsReusableInANewProject() async throws {
        try await MainActor.run {
            let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            defer{try? FileManager.default.removeItem(at:root)}
            let library=root.appendingPathComponent("Library.framestudio")
            let a=EditorSession(projectURL:root.appendingPathComponent("A.framestudio"),libraryURL:library)
            a.selection=Set(a.page.nodes.prefix(2).map(\.id));a.saveTemplate();a.templateCategory="导航与页头";a.confirmTemplate()
            XCTAssertNil(a.error)
            let b=EditorSession(projectURL:root.appendingPathComponent("B.framestudio"),libraryURL:library)
            let template=try XCTUnwrap(b.personalLibrary?.templates.first)
            XCTAssertEqual(template.category,"导航与页头");XCTAssertEqual(template.nodes.count,2)
            let count=b.page.nodes.count;b.insertTemplate(template)
            XCTAssertEqual(b.page.nodes.count,count+2);XCTAssertNil(b.error)
            b.undo();XCTAssertEqual(b.page.nodes.count,count)
            XCTAssertEqual(try PersonalComponentLibrary.load(library).templates.count,1)
        }
    }
    func testLayerListSelectsMembersWithoutChangingTheirGroup() async throws {
        try await MainActor.run {try withSession {session in
            let ids=session.page.nodes.prefix(2).map(\.id)
            session.selection=Set(ids);session.group()
            let members=session.page.nodes.filter{ids.contains($0.id)},saved=session.project
            session.select(members[0]);XCTAssertEqual(session.selection,Set(ids))
            session.select(members[0],includingGroup:false);XCTAssertEqual(session.selection,[ids[0]])
            session.select(members[1],additive:true,includingGroup:false);XCTAssertEqual(session.selection,Set(ids))
            session.select(members[0],additive:true,includingGroup:false);XCTAssertEqual(session.selection,[ids[1]])
            XCTAssertEqual(session.project,saved)
            XCTAssertEqual(try ProjectStore.load(session.url),saved)
        }}
    }
    @MainActor func withSession(_ body:(EditorSession)throws->Void)throws {
        let directory=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer{try? FileManager.default.removeItem(at:directory)}
        let session=EditorSession(projectURL:directory.appendingPathComponent("Test.framestudio"))
        XCTAssertNil(session.error)
        try body(session)
    }

    func testCoordinateBindingsAllowReadingProjectDuringMutation() async throws {
        try await MainActor.run {try withSession {session in
            let node=session.page.nodes.first!
            let inspector=NodeInspector(session:session,node:node)
            let binding=inspector.rectBinding(\.x)
            // macOS number fields can write their current value simply when gaining focus.
            let revision=session.project.revision
            binding.wrappedValue=binding.wrappedValue
            XCTAssertEqual(session.project.revision,revision)
            XCTAssertFalse(session.canUndo)
            binding.wrappedValue=36
            XCTAssertEqual(binding.wrappedValue,36)
            XCTAssertNil(session.error)
            XCTAssertEqual(try ProjectStore.load(session.url),session.project)
        }}
    }

    func testAllCoordinateFieldsAcrossSixVariantsKeepTabsAndHistoryConsistent() async throws {
        try await MainActor.run {try withSession {session in
            session.selectPage(session.project.pages.last!.id)
            let tab=session.page.nodes.first{$0.kind == .tabBar}!
            let inspector=NodeInspector(session:session,node:tab)
            let keys:[WritableKeyPath<Rect,Double>]=[\.x,\.y,\.width,\.height]
            for (index,variant) in Variant.allCases.enumerated() {
                session.variant=variant
                for (key,value) in zip(keys,[Double(20+index),120,280,60]) {
                    let field=inspector.rectBinding(key)
                    let before=session.project
                    field.wrappedValue=value
                    XCTAssertNil(session.error)
                    XCTAssertEqual(field.wrappedValue,value)
                    let edited=session.project
                    for page in edited.pages {
                        let other=page.nodes.first{$0.kind == .tabBar}!
                        XCTAssertEqual(other.frame(variant,device:edited.device)[keyPath:key],value)
                    }
                    session.undo();XCTAssertEqual(session.project.pages,before.pages)
                    session.redo();XCTAssertEqual(session.project.pages,edited.pages)
                }
            }
            XCTAssertEqual(try ProjectStore.load(session.url),session.project)
        }}
    }

    func testCoordinateGestureCommitsOnceAndRemainsUndoable() async throws {
        try await MainActor.run {try withSession {session in
            let node=session.page.nodes.first!
            let inspector=NodeInspector(session:session,node:node)
            let before=session.project
            session.beginPropertyGesture()
            inspector.rectBinding(\.x).wrappedValue=70
            inspector.rectBinding(\.y).wrappedValue=90
            XCTAssertEqual(session.project.revision,before.revision)
            XCTAssertEqual(try ProjectStore.load(session.url),before)
            XCTAssertEqual(inspector.rectBinding(\.x).wrappedValue,70)
            session.finishDrag()
            XCTAssertEqual(session.project.revision,before.revision+1)
            XCTAssertEqual(session.undoStack.count,1)
            XCTAssertEqual(try ProjectStore.load(session.url),session.project)
            session.undo();XCTAssertEqual(session.project.pages,before.pages)
        }}
    }

    func testProgressStyleAndLayoutCopyCanReadEditorContext() async throws {
        try await MainActor.run {try withSession {session in
            session.add(.progress)
            let progress=session.selected!
            let inspector=ProgressInspector(session:session,node:progress)
            inspector.changeStyle("circular")
            XCTAssertEqual(session.selected!.frame(session.variant,device:session.project.device).width,100)
            inspector.changeStyle("linear")
            XCTAssertEqual(session.selected!.frame(session.variant,device:session.project.device).width,300)
            session.setWide(true)
            session.copyLayout()
            XCTAssertNil(session.error)
            XCTAssertEqual(try ProjectStore.load(session.url),session.project)
        }}
    }

    func testInvalidCoordinateRollsBackWithoutAddingHistory() async throws {
        try await MainActor.run {try withSession {session in
            let node=session.page.nodes.first!
            let inspector=NodeInspector(session:session,node:node)
            let before=session.project
            inspector.rectBinding(\.width).wrappedValue = -10
            XCTAssertNotNil(session.error)
            XCTAssertEqual(session.project,before)
            XCTAssertEqual(try ProjectStore.load(session.url),before)
            XCTAssertFalse(session.canUndo)
        }}
    }

    func testStaleCoordinateEditRefreshesInsteadOfOverwritingAgentChanges() async throws {
        try await MainActor.run {try withSession {session in
            let node=session.page.nodes.first!
            let inspector=NodeInspector(session:session,node:node)
            let updated=try ProjectStore.update(session.url,expectedRevision:session.project.revision){p in
                p.pages[0].nodes[0].frames[Variant.standardPortrait.rawValue]?.x=88
            }
            inspector.rectBinding(\.x).wrappedValue=55
            XCTAssertNotNil(session.error)
            XCTAssertEqual(session.project,updated)
            XCTAssertEqual(inspector.rectBinding(\.x).wrappedValue,88)
            XCTAssertEqual(try ProjectStore.load(session.url),updated)
            XCTAssertFalse(session.canUndo)
        }}
    }
}
