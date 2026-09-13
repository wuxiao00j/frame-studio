import XCTest
import SwiftUI
import StudioCore
@testable import FrameStudio

final class GroupEditingTests:XCTestCase {
    @MainActor func session() -> EditorSession {EditorSession(projectURL:FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("Test.framestudio"))}
    func testMergeHasOneBoundsAndIndividualMemberSelectionIsPreserved() async throws {
        try await MainActor.run {
            let s=session();defer{try? FileManager.default.removeItem(at:s.url.deletingLastPathComponent())}
            s.change{p in var a=DesignNode(kind:.rectangle,frame:Rect(20,100,300,200)),b=DesignNode(kind:.text,frame:Rect(40,120,100,30));a.fixedToViewport=false;b.fixedToViewport=false;p.pages[0].nodes=[a,b]}
            s.selection=Set(s.page.nodes.map(\.id));s.group()
            let g=try XCTUnwrap(s.selectionGroup(in:s.variant));XCTAssertEqual(g.bounds,Rect(20,100,300,200))
            XCTAssertEqual(s.selectionGroup(in:s.variant,offset:60)?.bounds.y,40)
            XCTAssertFalse(CanvasNode(session:s,node:s.page.nodes[0],variant:s.variant,groupSelected:true).selected)
            s.select(s.page.nodes[1],includingGroup:false);XCTAssertNil(s.selectionGroup(in:s.variant))
            s.select(s.page.nodes[1]);XCTAssertNotNil(s.selectionGroup(in:s.variant))
            s.ungroup();XCTAssertTrue(s.page.nodes.allSatisfy{$0.groupID.isEmpty})
            s.undo();XCTAssertTrue(s.page.nodes.allSatisfy{!$0.groupID.isEmpty})
        }
    }
    func testWholeGroupResizeAndMoveCommitOnceAndUndoAllMembers() async throws {
        try await MainActor.run {
            let s=session();defer{try? FileManager.default.removeItem(at:s.url.deletingLastPathComponent())}
            s.change{p in var a=DesignNode(kind:.rectangle,frame:Rect(20,100,300,200)),b=DesignNode(kind:.text,frame:Rect(40,120,100,30));a.fixedToViewport=false;b.fixedToViewport=false;p.pages[0].nodes=[a,b]}
            s.selection=Set(s.page.nodes.map(\.id));s.group();s.zoom=1;s.snapping=false
            let before=s.project,undo=s.undoStack.count
            s.beginGroupTransform(resizing:true,offset:50);s.transformGroup(translation:CGSize(width:300,height:200));s.finishDrag()
            XCTAssertEqual(s.page.nodes[0].frame(s.variant,device:s.project.device),Rect(20,100,600,400))
            XCTAssertEqual(s.page.nodes[1].frame(s.variant,device:s.project.device),Rect(60,140,200,60))
            XCTAssertEqual(s.undoStack.count,undo+1);s.undo();XCTAssertEqual(s.project.pages,before.pages)
            s.selection=Set(s.page.nodes.map(\.id));s.beginGroupTransform(resizing:false,offset:50);s.transformGroup(translation:CGSize(width:15,height:25));s.finishDrag()
            XCTAssertEqual(s.page.nodes[1].frame(s.variant,device:s.project.device).x,55)
            XCTAssertEqual(s.page.nodes[1].frame(s.variant,device:s.project.device).y,145)
        }
    }
    func testLayerStepIsUndoableAndNoOpDoesNotSave() async throws {
        try await MainActor.run {
            let s=session();defer{try? FileManager.default.removeItem(at:s.url.deletingLastPathComponent())}
            s.change{p in p.pages[0].nodes=(0..<3).map{i in var n=DesignNode(kind:.rectangle);n.id="n\(i)";return n}}
            s.selection=["n1"];let before=s.project;s.reorder(.forward)
            XCTAssertEqual(s.page.nodes.map(\.id),["n0","n2","n1"])
            let rev=s.project.revision;s.reorder(.forward);XCTAssertEqual(s.project.revision,rev)
            s.undo();XCTAssertEqual(s.project.pages,before.pages)
        }
    }
    func testAdaptiveGroupsRemainMergedOnRotationCopyAndTemplateSave() async throws {
        try await MainActor.run {
            let s=session();defer{try? FileManager.default.removeItem(at:s.url.deletingLastPathComponent())}
            s.change{p in var a=DesignNode(kind:.rectangle),b=DesignNode(kind:.text),c=DesignNode(kind:.text);a.groupID="adaptive";b.groupID="adaptive";c.groupID="adaptive";b.visibleVariants=["standardPortrait"];c.visibleVariants=["standardLandscape"];p.pages[0].nodes=[a,b,c]}
            s.select(s.page.nodes[0]);XCTAssertEqual(s.selectionGroup(in:s.variant)?.ids.count,2)
            XCTAssertEqual(s.templateSelectionNodes.count,3)
            s.rotate();XCTAssertEqual(s.selectionGroup(in:s.variant)?.ids.count,2)
            s.duplicate();let copied=try XCTUnwrap(s.selectionGroup(in:s.variant))
            XCTAssertNotEqual(copied.id,"adaptive");XCTAssertEqual(s.page.nodes.filter{$0.groupID==copied.id}.count,3)
            s.updateNode(copied.ids.first!){$0.locked=true}
            XCTAssertEqual(s.selectionGroup(in:s.variant)?.canTransform,false)
            let before=s.project;s.beginGroupTransform(resizing:true,offset:0);s.transformGroup(translation:CGSize(width:100,height:100));s.finishDrag()
            XCTAssertEqual(s.project,before)
        }
    }
}
