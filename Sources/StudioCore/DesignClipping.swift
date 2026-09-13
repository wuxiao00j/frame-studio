import Foundation

/// A retained ancestor mask in node-local unit coordinates. Moving or resizing a
/// decomposed layer moves or scales its mask with it; grouping preserves the crop.
public struct DesignClipMask: Codable, Equatable, Sendable {
    public var shape: String
    public var rect: Rect
    public var radius: Double
    public init(shape:String="roundedRectangle",rect:Rect,radius:Double=0) {
        self.shape=shape;self.rect=rect;self.radius=radius
    }
    public func validate() throws {
        guard ["rectangle","roundedRectangle","ellipse"].contains(shape),
              [rect.x,rect.y,rect.width,rect.height,radius].allSatisfy({$0.isFinite && abs($0)<=100000}),
              rect.width>0,rect.height>0,radius>=0 else {throw StudioError.invalid("导入裁剪边界无效")}
    }
}

public extension DesignNode {
    func masks(in variant:Variant)->[DesignClipMask] {clipMasks?[variant.rawValue] ?? []}
    func validateRendering() throws {
        if let clipMasks {
            guard clipMasks.count<=6 else{throw StudioError.invalid("裁剪布局数量无效")}
            for (key,masks) in clipMasks {
                guard Variant(rawValue:key) != nil,masks.count<=32 else{throw StudioError.invalid("裁剪布局或嵌套数量无效")}
                for mask in masks {try mask.validate()}
            }
        }
        guard ["standard","formRow"].contains(controlStyle ?? "standard"),(0...1000).contains(selectedIndex ?? 0),
              (1...1000).contains(lineLimit ?? 1),
              (lineSpacing ?? 0).isFinite,(0...500).contains(lineSpacing ?? 0),
              (minimumScaleFactor ?? 1).isFinite,(0.1...1).contains(minimumScaleFactor ?? 1),
              ["fill","fit","stretch"].contains(imageFit ?? "fill"),
              ["ultraThin","thin","regular","thick","ultraThick"].contains(material ?? "regular")
        else{throw StudioError.invalid("文字、图片或材质参数无效")}
    }
}
