import Foundation

extension SwiftExporter {
    static func masksExpression(_ n:DesignNode)->String {
        let variants=Variant.allCases.map{variant in
            "["+n.masks(in:variant).map{m in "DesignClipRegion(shape: \(literal(m.shape)), rect: CGRect(x: \(number(m.rect.x)), y: \(number(m.rect.y)), width: \(number(m.rect.width)), height: \(number(m.rect.height))), radius: \(number(m.radius)))"}.joined(separator:",")+"]"
        }
        return "["+variants.joined(separator:",")+"]"
    }
    static let renderingRuntime = #"""
    struct DesignClipRegion {
        let shape: String; let rect: CGRect; let radius: CGFloat
    }
    struct DesignImportedClipShape: Shape {
        let masks: [DesignClipRegion]
        func path(in rect: CGRect) -> Path {
            var result: Path?
            for mask in masks {
                let r = CGRect(x: mask.rect.minX * rect.width, y: mask.rect.minY * rect.height, width: mask.rect.width * rect.width, height: mask.rect.height * rect.height)
                let radius = mask.radius * min(rect.width, rect.height)
                let p = mask.shape == "ellipse" ? Path(ellipseIn: r) : Path(roundedRect: r, cornerRadius: mask.shape == "rectangle" ? 0 : radius)
                result = result.map { $0.intersection(p) } ?? p
            }
            return result ?? Path(rect)
        }
    }
    extension View {
        @ViewBuilder func designClipped(_ masks: [DesignClipRegion]) -> some View {
            if masks.isEmpty { self } else { clipShape(DesignImportedClipShape(masks: masks)) }
        }
    }
    """#
}
