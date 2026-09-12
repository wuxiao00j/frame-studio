import XCTest
import SwiftUI
import StudioCore
@testable import FrameStudio

final class EditorSessionTests:XCTestCase {
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
