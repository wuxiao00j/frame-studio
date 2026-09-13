import SwiftUI
import StudioCore

extension DesignNode {
    @MainActor var paintStyle:AnyShapeStyle {
        if let material {
            switch material {
            case "ultraThin":return AnyShapeStyle(Material.ultraThin)
            case "thin":return AnyShapeStyle(Material.thin)
            case "thick":return AnyShapeStyle(Material.thick)
            case "ultraThick":return AnyShapeStyle(Material.ultraThick)
            default:return AnyShapeStyle(Material.regular)
            }
        }
        guard let g=gradient else{return AnyShapeStyle(Color(hex:fill))}
        let gradient=Gradient(stops:g.stops.map{.init(color:Color(hex:$0.color),location:$0.location)})
        if g.kind=="radial" {return AnyShapeStyle(RadialGradient(gradient:gradient,center:UnitPoint(x:g.startX,y:g.startY),startRadius:g.startRadius,endRadius:g.endRadius))}
        return AnyShapeStyle(LinearGradient(gradient:gradient,startPoint:UnitPoint(x:g.startX,y:g.startY),endPoint:UnitPoint(x:g.endX,y:g.endY)))
    }
}
