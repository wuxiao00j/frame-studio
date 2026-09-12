import Foundation
import AppKit

public enum LocalImageAsset {
    public static func readPNG(_ file:URL)throws->String {
        guard let image=NSImage(contentsOf:file),let raw=image.tiffRepresentation,let bitmap=NSBitmapImageRep(data:raw),let png=bitmap.representation(using:.png,properties:[:]),png.count<20_000_000 else{throw StudioError.invalid("无法读取图标，或图片超过 20 MB")}
        return png.base64EncodedString()
    }
}
