import SwiftUI
import StudioCore
import AppKit

@main @MainActor enum FrameStudioEntry {
    static func main() {
        guard CommandLine.arguments.contains("--render-preview") else{FrameStudioApp.main();return}
        func value(_ name:String)->String?{guard let i=CommandLine.arguments.firstIndex(of:name),i+1<CommandLine.arguments.count else{return nil};return CommandLine.arguments[i+1]}
        do {
            guard let path=value("--project"),let output=value("--output") else{throw StudioError.invalid("Use --render-preview --project FILE --output PNG [--page 0] [--variant standardPortrait] [--offset 0]")}
            let project=try ProjectStore.load(URL(fileURLWithPath:path)),index=Int(value("--page") ?? "0") ?? 0
            guard project.pages.indices.contains(index) else{throw StudioError.invalid("Page index out of range")}
            let variant=Variant(rawValue:value("--variant") ?? "standardPortrait") ?? .standardPortrait
            let view=DesignPagePreview(project:project,page:project.pages[index],variant:variant,offset:Double(value("--offset") ?? "0") ?? 0)
            let renderer=ImageRenderer(content:view.environment(\.colorScheme,.light));renderer.scale=2
            guard let image=renderer.nsImage,let tiff=image.tiffRepresentation,let bitmap=NSBitmapImageRep(data:tiff),let png=bitmap.representation(using:.png,properties:[:]) else{throw StudioError.invalid("Preview render failed")}
            let url=URL(fileURLWithPath:output);try FileManager.default.createDirectory(at:url.deletingLastPathComponent(),withIntermediateDirectories:true);try png.write(to:url,options:.atomic)
            print("PREVIEW_RENDERED \(url.path)")
        }catch{FileHandle.standardError.write(Data((error.localizedDescription+"\n").utf8));exit(1)}
    }
}
@MainActor struct DesignPagePreview:View {
    let project:DesignProject
    let page:DesignPage
    let variant:Variant
    var offset:Double=0
    var size:Dimensions {project.device.size(variant)}
    var orderedNodes:[DesignNode] {
        let visible=page.nodes.filter{$0.isVisible(in:variant)}
        let background=visible.filter{$0.isFixed && $0.backgroundLayer==true}
        let content=visible.filter{!$0.isFixed}
        let overlay=visible.filter{$0.isFixed && $0.backgroundLayer != true}
        return background+content+overlay
    }
    var body:some View {
        ZStack(alignment:.topLeading) {
            Color(hex:page.background)
            ForEach(orderedNodes){node in
                DesignPreviewNode(node:node,page:page,device:project.device,variant:variant,offset:offset)
            }
        }.frame(width:CGFloat(size.width),height:CGFloat(size.height)).clipped()
    }
}
@MainActor private struct DesignPreviewNode:View {
    let node:DesignNode
    let page:DesignPage
    let device:DeviceProfile
    let variant:Variant
    let offset:Double
    var rect:Rect {node.frame(variant,device:device)}
    var body:some View {
        ComponentPreview(node:node,corners:page.corners(node,variant:variant,device:device),activePage:page.id)
            .frame(width:CGFloat(rect.width),height:CGFloat(rect.height))
            .position(x:CGFloat(rect.midX),y:CGFloat(rect.midY-(node.isFixed ? 0:offset)))
    }
}
