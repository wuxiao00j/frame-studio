import SwiftUI
import StudioCore

struct ImportedClipShape:Shape {
    let masks:[DesignClipMask]
    func path(in rect:CGRect)->Path {
        var result:Path?
        for mask in masks {
            let r=CGRect(x:mask.rect.x*rect.width,y:mask.rect.y*rect.height,width:mask.rect.width*rect.width,height:mask.rect.height*rect.height)
            let radius=mask.radius*min(rect.width,rect.height)
            let p=mask.shape=="ellipse" ? Path(ellipseIn:r):Path(roundedRect:r,cornerRadius:mask.shape=="rectangle" ? 0:radius)
            result=result.map{$0.intersection(p)} ?? p
        }
        return result ?? Path(rect)
    }
}
@MainActor struct ImportedMaskModifier:ViewModifier {
    let masks:[DesignClipMask]
    @ViewBuilder func body(content:Content)->some View {
        if masks.isEmpty{content}else{content.clipShape(ImportedClipShape(masks:masks))}
    }
}
