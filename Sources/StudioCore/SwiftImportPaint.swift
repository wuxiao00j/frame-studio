import Foundation

extension SwiftImportLayout {
    func material(_ value:[SwiftToken]?,depth:Int=0)->String? {
        guard let value,depth<12 else{return nil}
        let key=SwiftSourceSyntax.text(resolved(value))
        if key.hasPrefix("AnyShapeStyle("){return material(arguments(value)["$0"],depth:depth+1)}
        for name in ["ultraThin","thin","regular","thick","ultraThick"] where key=="."+name+"Material" || key=="Material."+name {return name}
        return nil
    }
    func unitPoint(_ value:[SwiftToken]?,fallback:(Double,Double))->(Double,Double) {
        guard let value else{return fallback}
        let key=SwiftSourceSyntax.text(value),args=arguments(value)
        if let x=number(args["x"]),let y=number(args["y"]){return(x,y)}
        return [".topLeading":(0.0,0.0),".top":(0.5,0),".topTrailing":(1,0),".leading":(0,0.5),".center":(0.5,0.5),".trailing":(1,0.5),".bottomLeading":(0,1),".bottom":(0.5,1),".bottomTrailing":(1,1)][key] ?? fallback
    }
    func gradient(_ value:[SwiftToken]?,depth:Int=0)->DesignGradient? {
        guard let value,depth<12 else{return nil}
        let t=resolved(value),key=SwiftSourceSyntax.text(t),args=arguments(t)
        if key.hasPrefix("AnyShapeStyle("){return gradient(args["$0"],depth:depth+1)}
        guard key.hasPrefix("LinearGradient(") || key.hasPrefix("RadialGradient(") else{return nil}
        var stopTokens=args["stops"],colorTokens=args["colors"]
        if let wrapped=args["gradient"] {let inner=arguments(wrapped);stopTokens=inner["stops"];colorTokens=inner["colors"]}
        var stops:[DesignGradientStop]=[]
        if let stopTokens,stopTokens.first?.text=="[" {
            for stop in SwiftSourceSyntax.split(Array(stopTokens.dropFirst().dropLast())) {
                let a=arguments(stop)
                guard let c=color(a["color"]),let location=number(a["location"]) else{return nil}
                stops.append(.init(color:c,location:location))
            }
        }else if let colorTokens,colorTokens.first?.text=="[" {
            let colors=SwiftSourceSyntax.split(Array(colorTokens.dropFirst().dropLast()))
            for (i,value) in colors.enumerated(){guard let c=color(value) else{return nil};stops.append(.init(color:c,location:Double(i)/Double(max(1,colors.count-1))))}
        }
        guard stops.count>=2 else{return nil}
        let radial=key.hasPrefix("RadialGradient"),start=unitPoint(args[radial ? "center":"startPoint"],fallback:radial ? (0.5,0.5):(0,0)),end=unitPoint(args["endPoint"],fallback:(1,1))
        let result=DesignGradient(kind:radial ? "radial":"linear",stops:stops,startX:start.0,startY:start.1,endX:end.0,endY:end.1,startRadius:number(args["startRadius"]) ?? 0,endRadius:number(args["endRadius"]) ?? 200)
        return (try? result.validate()) != nil ? result:nil
    }
    func paint(_ value:[SwiftToken]?,on node:inout DesignNode,reference:String) {
        node.material=nil;node.gradient=nil
        if let material=material(value){node.material=material;node.gradient=nil;node.fill="FFFFFF00"}
        else if let gradient=gradient(value){node.gradient=gradient;node.fill=gradient.stops.first!.color}
        else if let color=color(value){node.fill=color;node.gradient=nil}
        else if SwiftSourceSyntax.text(value ?? []).contains("opacity") {node.fill="FFFFFF00";builder.warn("动态透明度未确定，装饰色暂按透明处理",reference)}
        else{node.fill="F2F2F7";builder.warn("填充表达式仍需提供运行时值",reference)}
    }
}
