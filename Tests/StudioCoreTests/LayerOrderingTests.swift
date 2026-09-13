import XCTest
@testable import StudioCore

final class LayerOrderingTests:XCTestCase {
    func nodes()->[DesignNode]{["a","b","c","d"].map{id in var n=DesignNode(kind:.rectangle);n.id=id;return n}}
    func testSingleStepAndMultipleSelectionKeepRelativeOrder() {
        let n=nodes()
        XCTAssertEqual(LayoutEngine.reordered(n,ids:["b"],move:.forward,variant:.standardPortrait).map(\.id),["a","c","b","d"])
        XCTAssertEqual(LayoutEngine.reordered(n,ids:["a","b"],move:.forward,variant:.standardPortrait).map(\.id),["c","a","b","d"])
        XCTAssertEqual(LayoutEngine.reordered(n,ids:["b","d"],move:.backward,variant:.standardPortrait).map(\.id),["b","a","d","c"])
        XCTAssertEqual(LayoutEngine.reordered(n,ids:["d"],move:.forward,variant:.standardPortrait),n)
    }
    func testDrawingPlanesInactiveVariantsAndLocksRemainRespected() {
        var n=nodes();n[1].fixedToViewport=true;n[3].visibleVariants=["standardLandscape"]
        XCTAssertEqual(LayoutEngine.reordered(n,ids:["a"],move:.forward,variant:.standardPortrait).map(\.id),["c","b","a","d"])
        n[0].locked=true
        XCTAssertEqual(LayoutEngine.reordered(n,ids:["a"],move:.front,variant:.standardPortrait),n)
    }
}
