import SwiftUI
import StudioCore

extension DesignNode {
    @MainActor var paintStyle:AnyShapeStyle {
        guard let g=gradient else{return AnyShapeStyle(Color(hex:fill))}
        let gradient=Gradient(stops:g.stops.map{.init(color:Color(hex:$0.color),location:$0.location)})
        if g.kind=="radial" {return AnyShapeStyle(RadialGradient(gradient:gradient,center:UnitPoint(x:g.startX,y:g.startY),startRadius:g.startRadius,endRadius:g.endRadius))}
        return AnyShapeStyle(LinearGradient(gradient:gradient,startPoint:UnitPoint(x:g.startX,y:g.startY),endPoint:UnitPoint(x:g.endX,y:g.endY)))
    }
}
