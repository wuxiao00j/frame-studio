import Foundation

public struct DesignGradientStop:Codable,Equatable,Sendable {
    public var color:String
    public var location:Double
    public init(color:String,location:Double){self.color=color;self.location=location}
}
public struct DesignGradient:Codable,Equatable,Sendable {
    public var kind:String
    public var stops:[DesignGradientStop]
    public var startX:Double
    public var startY:Double
    public var endX:Double
    public var endY:Double
    public var startRadius:Double
    public var endRadius:Double
    public init(kind:String="linear",stops:[DesignGradientStop],startX:Double=0,startY:Double=0,endX:Double=1,endY:Double=1,startRadius:Double=0,endRadius:Double=200) {
        self.kind=kind;self.stops=stops;self.startX=startX;self.startY=startY;self.endX=endX;self.endY=endY;self.startRadius=startRadius;self.endRadius=endRadius
    }
    public func validate()throws {
        guard ["linear","radial"].contains(kind),(2...32).contains(stops.count),[startX,startY,endX,endY].allSatisfy({$0.isFinite && abs($0)<=10}),startRadius.isFinite,endRadius.isFinite,startRadius>=0,endRadius>startRadius,endRadius<=5000 else{throw StudioError.invalid("渐变参数无效")}
        var previous = -1.0
        for stop in stops {try ProjectStore.validateColor(stop.color);guard stop.location.isFinite,(0...1).contains(stop.location),stop.location>=previous else{throw StudioError.invalid("渐变色标位置无效")};previous=stop.location}
    }
}
