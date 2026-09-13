import XCTest
import SwiftUI
import StudioCore
@testable import FrameStudio

final class RenderingTests:XCTestCase {
    func testImportedChineseParagraphHasEnoughHeightForSwiftUI() async throws {
        try await MainActor.run {
            let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true);defer{try? FileManager.default.removeItem(at:root)}
            let text="这是一段需要自动换行的说明文字，导入以后应该完整显示所有内容。"
            try "import SwiftUI\nstruct DemoView:View {var body:some View {Text(\(SwiftExporter.literal(text))).font(.system(size:15)).lineSpacing(4).frame(width:200)}}".write(to:root.appendingPathComponent("DemoView.swift"),atomically:true,encoding:.utf8)
            let report=try SwiftImporter.inspect(root),n=try XCTUnwrap(report.pages.first?.nodes.first)
            let r=try XCTUnwrap(n.frames["standardPortrait"])
            let renderer=ImageRenderer(content:Text(text).font(.system(size:15)).lineSpacing(4).frame(width:r.width).fixedSize(horizontal:false,vertical:true));renderer.scale=1
            let measured=try XCTUnwrap(renderer.nsImage).size.height
            XCTAssertGreaterThanOrEqual(r.height,Double(measured))
        }
    }
    func testNestedMasksIntersectAndScaleWithNode() async {
        await MainActor.run {
            let masks=[DesignClipMask(shape:"rectangle",rect:Rect(0.2,0,0.8,1)),DesignClipMask(shape:"ellipse",rect:Rect(0,0,1,1))]
            let path=ImportedClipShape(masks:masks).path(in:CGRect(x:0,y:0,width:200,height:100))
            XCTAssertTrue(path.contains(CGPoint(x:100,y:50)))
            XCTAssertFalse(path.contains(CGPoint(x:20,y:50)))
            XCTAssertFalse(path.contains(CGPoint(x:190,y:5)))
            let scaled=ImportedClipShape(masks:masks).path(in:CGRect(x:0,y:0,width:400,height:200))
            XCTAssertTrue(scaled.contains(CGPoint(x:200,y:100)))
            XCTAssertFalse(scaled.contains(CGPoint(x:40,y:100)))
        }
    }
    func testRendererAppliesTheSelectedVariantMask() async throws {
        try await MainActor.run {
            var n=DesignNode(kind:.rectangle,frame:Rect(0,0,100,100));n.fill="FF0000";n.cornerRadius=0
            n.clipMasks=["standardPortrait":[DesignClipMask(shape:"rectangle",rect:Rect(0,0,0.5,1))],"standardLandscape":[DesignClipMask(shape:"rectangle",rect:Rect(0.5,0,0.5,1))]]
            for variant in [Variant.standardPortrait,.standardLandscape] {
                let renderer=ImageRenderer(content:ComponentPreview(node:n,variant:variant).frame(width:100,height:100));renderer.scale=1
                let image=try XCTUnwrap(renderer.nsImage),tiff=try XCTUnwrap(image.tiffRepresentation),bitmap=try XCTUnwrap(NSBitmapImageRep(data:tiff))
                let left=try XCTUnwrap(bitmap.colorAt(x:20,y:50)),right=try XCTUnwrap(bitmap.colorAt(x:80,y:50))
                XCTAssertEqual(left.alphaComponent,variant == .standardPortrait ? 1:0,accuracy:0.05)
                XCTAssertEqual(right.alphaComponent,variant == .standardPortrait ? 0:1,accuracy:0.05)
            }
        }
    }
}
