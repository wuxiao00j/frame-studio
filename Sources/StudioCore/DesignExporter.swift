import Foundation
import CryptoKit

public enum ExportFormat:String,CaseIterable,Identifiable,Sendable {
    case swiftui, android, flutter
    public var id:String{rawValue}
    public var title:String{switch self{case .swiftui:"SwiftUI";case .android:"Android 原生";case .flutter:"Flutter"}}
    public var detail:String{switch self{case .swiftui:"SwiftUI · UI 源码";case .android:"Android 原生 · Compose UI 源码";case .flutter:"Flutter · Dart UI 源码"}}
    public var symbol:String{switch self{case .swiftui:"swift";case .android:"apps.iphone";case .flutter:"square.stack.3d.up"}}
}
private final class ExportResourceMarker:NSObject {}

public enum DesignExporter {
    public static func export(_ project:DesignProject,format:ExportFormat,to directory:URL)throws->URL {
        try ProjectStore.validate(project)
        let project=SharedTabBar.normalized(project)
        if format == .swiftui{return try SwiftExporter.export(project,to:directory)}
        try ProjectStore.validate(project)
        let date=ISO8601DateFormatter().string(from:Date()).replacingOccurrences(of:":",with:"-")
        let output=directory.appendingPathComponent("\(format == .android ? "Android-Compose" : "Flutter")-\(date)-\(UUID().uuidString.prefix(4))")
        try FileManager.default.createDirectory(at:output,withIntermediateDirectories:true)
        do {
            if format == .flutter{try FlutterExporter.write(project,to:output)}else{try ComposeExporter.write(project,to:output)}
            let encoder=JSONEncoder();encoder.outputFormatting=[.prettyPrinted,.sortedKeys,.withoutEscapingSlashes]
            try encoder.encode(project).write(to:output.appendingPathComponent("Design.framestudio"))
            try writeText(report(project,format:format),at:output,path:"EXPORT_REPORT.md")
            try ExportContract.writeManifest(project,format:format,to:output)
            return output
        }catch{try? FileManager.default.removeItem(at:output);throw error}
    }
    static var resources:URL {
        let executable=URL(fileURLWithPath:CommandLine.arguments[0]).resolvingSymlinksInPath()
        let bundled=executable.deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Resources/ExportTemplates")
        if FileManager.default.fileExists(atPath:bundled.path){return bundled}
        for location in [executable.deletingLastPathComponent(),Bundle(for:ExportResourceMarker.self).bundleURL] {
            var directory=location
            for _ in 0..<6 {
                let candidate=directory.appendingPathComponent("FrameStudio_StudioCore.bundle/ExportTemplates")
                if FileManager.default.fileExists(atPath:candidate.path){return candidate}
                directory=directory.deletingLastPathComponent()
            }
        }
        return bundled // File reads report a normal error if a distribution is incomplete.
    }
    static func copyTemplate(_ name:String,to root:URL)throws {
        let source=resources.appendingPathComponent(name)
        for item in try FileManager.default.contentsOfDirectory(at:source,includingPropertiesForKeys:nil){try FileManager.default.copyItem(at:item,to:root.appendingPathComponent(item.lastPathComponent))}
        if let files=FileManager.default.enumerator(at:root,includingPropertiesForKeys:nil) {
            let rules=files.compactMap{$0 as? URL}.filter{$0.lastPathComponent=="gitignore.template"}
            for file in rules{try FileManager.default.moveItem(at:file,to:file.deletingLastPathComponent().appendingPathComponent(".gitignore"))}
        }
    }
    static func writeText(_ text:String,at root:URL,path:String)throws {
        let file=root.appendingPathComponent(path);try FileManager.default.createDirectory(at:file.deletingLastPathComponent(),withIntermediateDirectories:true)
        try text.write(to:file,atomically:true,encoding:.utf8)
    }
    static func assetName(_ node:DesignNode)->String{"asset_"+node.id.utf8.map{String(format:"%02x",$0)}.joined()}
    static func pageName(_ page:DesignPage)->String{SwiftExporter.identifier(page.id)}
    public static func literal(_ text:String)->String {
        let data=try! JSONEncoder().encode(text)
        return String(data:data,encoding:.utf8)!.replacingOccurrences(of:"\\/",with:"/").replacingOccurrences(of:"$",with:"\\$")
    }
    static func kotlinString(_ text:String)->String {
        guard text.utf8.count>16000 else{return literal(text)}
        var chunks:[String]=[],part="",count=0
        for scalar in text.unicodeScalars {
            let str=String(scalar),bytes=str.utf8.count
            if count+bytes>16000 {chunks.append(part);part="";count=0}
            part += str;count += bytes
        }
        if !part.isEmpty {chunks.append(part)}
        return "buildString {\n"+chunks.map{"append(\(literal($0)))"}.joined(separator:"\n")+"\n}"
    }
    static func iconAssetName(_ node:DesignNode,_ slot:String)->String {assetName(node)+"_"+slot}
    static func itemAssetName(_ node:DesignNode,_ item:NavigationItem,_ selected:Bool)->String {"nav_"+SHA256.hash(data:Data((node.id+item.id+String(selected)).utf8)).prefix(16).map{String(format:"%02x",$0)}.joined()}
    static func assetEntries(_ project:DesignProject)->[(String,String)] {
        var result:[(String,String)]=[]
        for node in project.pages.flatMap(\.nodes) {
            if !node.imageData.isEmpty{result.append((assetName(node),node.imageData))}
            for (slot,data) in [("icon",node.iconData),("qr",node.qrIconData),("chevron",node.chevronIconData),("trailing",node.trailingIconData)] {if let data,!data.isEmpty{result.append((iconAssetName(node,slot),data))}}
            for item in node.items {if let data=item.iconData,!data.isEmpty{result.append((itemAssetName(node,item,false),data))};if let data=item.selectedIconData,!data.isEmpty{result.append((itemAssetName(node,item,true),data))}}
        }
        return result
    }
    static func data(_ node:DesignNode,device:DeviceProfile,page:DesignPage)throws->[String:Any] {
        var json=try JSONSerialization.jsonObject(with:JSONEncoder().encode(node)) as! [String:Any]
        for key in ["imageData","customCode","flutterCode","composeCode","iconData","qrIconData","chevronIconData","trailingIconData"]{json.removeValue(forKey:key)}
        json["asset"]=node.imageData.isEmpty ? "" : "assets/\(assetName(node)).png"
        for (slot,data) in [("icon",node.iconData),("qr",node.qrIconData),("chevron",node.chevronIconData),("trailing",node.trailingIconData)]{json[slot+"Asset"]=(data?.isEmpty==false) ? "assets/\(iconAssetName(node,slot)).png":""}
        json["symbol"]=MaterialSymbols.key(node.symbol);json["trailingSymbol"]=MaterialSymbols.key(node.trailingSymbol ?? "square.and.pencil")
        if let variants=node.visibleVariants{json["visibleVariants"]=variants.compactMap{Variant(rawValue:$0)}.compactMap{Variant.allCases.firstIndex(of:$0)}}
        json["clipMasks"]=try JSONSerialization.jsonObject(with:JSONEncoder().encode(Variant.allCases.map{node.masks(in:$0)}))
        json["fixed"]=node.isFixed;json["showIcon"]=node.hasIcon;json["showLabel"]=node.hasLabel;json["showQRCode"]=node.hasQRCode;json["showChevron"]=node.hasChevron;json["controlPosition"]=node.position
        json["progressStyle"]=node.progressMode;json["progressText"]=node.progressText;json["fraction"]=node.fraction;json["progressThickness"]=node.progressThickness ?? 6;json["progressSteps"]=node.progressSteps ?? 5;json["trackColor"]=node.trackColor ?? "E5E2ED"
        json["numberValue"]=node.number;json["minimumValue"]=node.minimum;json["maximumValue"]=node.maximum;json["stepValue"]=node.step;json["dateValue"]=node.dateValue ?? "2026-01-01"
        json["items"]=node.items.map{item -> [String:Any] in
            let asset=item.iconData?.isEmpty==false ? "assets/\(itemAssetName(node,item,false)).png":""
            let selectedAsset=item.selectedIconData?.isEmpty==false ? "assets/\(itemAssetName(node,item,true)).png" : (item.selectedSymbol == nil ? asset:"")
            return ["id":item.id,"title":item.title,"symbol":item.symbol.isEmpty ? "":MaterialSymbols.key(item.symbol),"pageID":item.pageID,"iconAsset":asset,"selectedSymbol":item.activeSymbol.isEmpty ? "":MaterialSymbols.key(item.activeSymbol),"selectedAsset":selectedAsset]
        }
        json["layouts"]=Variant.allCases.map{variant -> [String:Double] in
            let r=node.frame(variant,device:device),s=device.size(variant),c=page.corners(node,variant:variant,device:device)
            return ["x":r.x,"y":r.y,"width":r.width,"height":r.height,"refWidth":s.width,"refHeight":node.isFixed ? s.height:page.contentHeight(variant,device:device),"tl":c.tl,"tr":c.tr,"bl":c.bl,"br":c.br]
        }
        return json
    }
    static func writeAssets(_ project:DesignProject,at root:URL,path:String)throws {
        let assets=root.appendingPathComponent(path);try FileManager.default.createDirectory(at:assets,withIntermediateDirectories:true)
        for (name,raw) in assetEntries(project) {guard let data=Data(base64Encoded:raw) else{throw StudioError.invalid("图片格式无效")};try data.write(to:assets.appendingPathComponent(name+".png"))}
        try "Generated image assets".write(to:assets.appendingPathComponent("README.txt"),atomically:true,encoding:.utf8)
    }
    static func report(_ project:DesignProject,format:ExportFormat)->String {
        let nodes=project.pages.flatMap(\.nodes).filter{!$0.hidden}
        let custom=nodes.filter{$0.kind == .custom && (format == .flutter ? $0.flutterCode : $0.composeCode)?.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty != false}
        let unmatched=Set(nodes.flatMap{[$0.symbol]+$0.items.map(\.symbol)}.filter{!$0.isEmpty && MaterialSymbols.key($0)=="info" && $0 != "info.circle"}).sorted()
        return """
        # \(format.title) 导出报告

        页面：\(project.pages.count)，可见组件：\(nodes.count)。包含原生控件、页面导航、头像和图片资源、六种画布尺寸、适配锚点及源设计文件。
        标准 / 阔屏选择与设计一致；根据容器方向和短边阈值选择已保存的布局。系统控件的字体度量、最小触控尺寸和 SF Symbols / Material 图标存在平台差异，请在目标设备验收。
        未提供对应平台表达式的自定义组件：\(custom.count)。这些位置保留可见占位，并在代码中标注 TODO；SwiftUI 表达式不会被当成 Dart / Kotlin 执行。
        \(custom.map{"- \($0.name)（\($0.id)）：请补充 \(format == .flutter ? "flutterCode" : "composeCode")。"}.joined(separator:"\n"))
        无精确映射的图标：\(unmatched.isEmpty ? "无" : unmatched.joined(separator:", "))。已映射为 Material Info 占位，可以替换为自己的图标资源。
        材质组件：\(nodes.filter{$0.material != nil}.count)。SwiftUI 使用系统 Material，Flutter 使用背景模糊；Android Compose 使用半透明底色替代背景模糊。系统 Liquid Glass 的折射和交互动画不在此静态设计模型内。
        Materials: SwiftUI uses system Material; Flutter uses backdrop blur; Android Compose falls back to a translucent fill. System Liquid Glass refraction and interactive animations are not reproduced.
        业务网络、支付、登录等逻辑不属于页面设计文件，需要在原项目接入。
        Design.framestudio 可完整重新导入原境编辑器。本次导出新建文件夹，不覆盖已有工程。
        """
    }
}
public enum MaterialSymbols {
    public static func key(_ symbol:String)->String {
        let s=symbol.replacingOccurrences(of:".fill",with:"")
        if s.hasPrefix("person"){return "person"};if s.contains("bubble"){return "chat"};if s.contains("sidebar") || s=="line.3.horizontal"{return "menu"}
        if s.contains("square.grid"){return "grid"};if s.contains("photo"){return "image"};if s.contains("gear"){return "settings"};if s.contains("pencil"){return "edit"}
        let map=["sparkles":"star","star":"star","heart":"favorite","house":"home","plus":"add","xmark":"close","magnifyingglass":"search","bookmark":"bookmark","bell":"notifications","qrcode":"qr","chevron.right":"chevronRight","chevron.left":"back","arrow.left":"back","arrow.right":"forward","checkmark":"check","checkmark.circle":"check","ellipsis":"more","ellipsis.circle":"more","paperplane":"send","envelope":"mail","phone":"phone","calendar":"calendar","clock":"clock","location":"location","map":"location","play.circle":"play","folder":"folder","doc":"file","doc.text":"file","camera":"camera","mic":"mic","lock":"lock","eye":"eye","cart":"cart","bag":"cart","creditcard":"payment","wallet.pass":"payment","moon":"moon","sun.max":"sun","globe":"globe","link":"link","arrow.up":"up","arrow.down":"down","music.note":"music","wifi":"wifi","video":"video","hand.thumbsup":"like","paintpalette":"palette","slider.horizontal.3":"tune","rectangle.stack":"layers","square.stack.3d.up":"layers","curlybraces":"code"]
        return map[s] ?? "info"
    }
}
