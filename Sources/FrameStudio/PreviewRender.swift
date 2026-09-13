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
    var body:some View {
        let size=project.device.size(variant)
        ZStack(alignment:.topLeading) {
            Color(hex:page.background)
            ForEach(page.nodes.filter{$0.isVisible(in:variant) && $0.isFixed && $0.backgroundLayer==true}+page.nodes.filter{$0.isVisible(in:variant) && !$0.isFixed}+page.nodes.filter{$0.isVisible(in:variant) && $0.isFixed && $0.backgroundLayer != true}){node in
                let r=node.frame(variant,device:project.device)
                ComponentPreview(node:node,corners:page.corners(node,variant:variant,device:project.device),activePage:page.id)
                    .frame(width:r.width,height:r.height)
                    .position(x:r.midX,y:r.midY-(node.isFixed ? 0:offset))
            }
        }.frame(width:size.width,height:size.height).clipped()
    }
}
