import Foundation
import AppKit

public struct SwiftImportOptions:Codable,Sendable {
    public var values:[String:String]
    public var colors:[String:String]
    public init(values:[String:String]=[:],colors:[String:String]=[:]){self.values=values;self.colors=colors}
}
public struct UnmatchedComponent:Codable,Sendable {public var typeName:String;public var sourceReference:String}
public struct ImportClassification:Codable,Sendable {public var sourceType:String;public var componentKind:String;public var count:Int}
public struct ImportReport:Codable,Sendable {
    public var pages:[DesignPage]
    public var warnings:[String]
    public var files:[String]
    public var unmatched:[UnmatchedComponent]=[]
    public var classifications:[ImportClassification]=[]
    public var templates:[ComponentTemplate]=[]
    public func project(named name:String)->DesignProject {
        var project=DesignProject();project.name=name;project.pages=pages;project.templates=templates;project.importNotes=warnings
        return SharedTabBar.normalized(project)
    }
}
public enum SwiftImporter {
    static let mappings:[String:ComponentKind] = [
        "Text":.text,"Label":.iconLabel,"Image":.image,"Icon":.icon,"Button":.button,"ElevatedButton":.button,"FilledButton":.button,
        "TextButton":.textButton,"OutlinedButton":.outlinedButton,"IconButton":.iconButton,"BackButton":.backButton,
        "Toggle":.toggle,"SwitchListTile":.toggle,"Switch":.switchControl,"CheckboxListTile":.checkbox,"Checkbox":.checkbox,"RadioListTile":.radio,"Radio":.radio,
        "TextField":.textField,"TextFormField":.textField,"SecureField":.secureField,"TextEditor":.textArea,"Slider":.slider,
        "Stepper":.stepper,"Picker":.selectField,"DropdownButton":.selectField,"DropdownMenu":.selectField,"DatePicker":.dateField,"RatingBar":.rating,
        "ProgressView":.progress,"LinearProgressIndicator":.progress,"CircularProgressIndicator":.ringProgress,"CircularProgress":.ringProgress,"LinearProgress":.progress,
        "CircleAvatar":.avatar,"Avatar":.avatar,"ListTile":.listRow,"Card":.card,"Container":.rectangle,"RoundedRectangle":.rectangle,"Rectangle":.rectangle,"Circle":.circle,"Divider":.divider,"Spacer":.spacer,"SizedBox":.spacer,
        "AppBar":.navigationBar,"TopAppBar":.navigationBar,"NavigationBar":.tabBar,"BottomNavigationBar":.tabBar,"TabView":.tabBar,"Tabs":.tabBar,"Drawer":.sidebar,"NavigationDrawer":.sidebar,
        "Badge":.badge,"Chip":.badge,"Alert":.alertBanner,"AlertDialog":.alertBanner,
        "button":.button,"input":.textField,"textarea":.textArea,"select":.selectField,"progress":.progress,"img":.image,"h1":.text,"h2":.text,"h3":.text,"p":.text,"span":.text
    ]
    static let structure:Set<String>=["VStack","HStack","ZStack","Group","GeometryReader","ForEach","NavigationStack","NavigationView","ScrollView","List","Form","Section","Column","Row","Stack","Positioned","Padding","Align","Center","Expanded","Flexible","SafeArea","Scaffold","MaterialApp","Material","SingleChildScrollView","Box","BoxWithConstraints","LazyColumn","LazyRow","Surface"]
    static let utilities:Set<String>=["Color","Font","TextStyle","ThemeData","ColorScheme","Size","Offset","Rect","CGRect","CGSize","EdgeInsets","BorderRadius","BoxDecoration","RoundedRectangleBorder","Date","DateTime","Calendar","URL","State","Binding","ObservedObject","StateObject","CGFloat","Double","Int","String","List","Set","Map","ValueKey","Key","IconData","NavigationItem","Modifier"]
    public static func inspect(_ url:URL,options:SwiftImportOptions=SwiftImportOptions())throws->ImportReport {
        guard options.values.count+options.colors.count<=300,options.values.allSatisfy({$0.key.count<512 && $0.value.count<8000}),options.colors.keys.allSatisfy({$0.count<512}) else{throw StudioError.invalid("导入参数过多或过长")}
        for color in options.colors.values{try ProjectStore.validateColor(color)}
        var isDir:ObjCBool=false;guard FileManager.default.fileExists(atPath:url.path,isDirectory:&isDir) else{throw StudioError.invalid("导入路径不存在")}
        let root=isDir.boolValue ? url:url.deletingLastPathComponent()
        let inventory=try SourceInspector.inventory(root)
        let accepted:Set<String>=["swift","dart","tsx","jsx","vue","html","kt"]
        let files=isDir.boolValue ? (inventory["sourceFiles"] as? [String] ?? []).map{URL(fileURLWithPath:$0)}.filter{accepted.contains($0.pathExtension)} : [url]
        let assetFiles=(inventory["assets"] as? [String] ?? []).map{URL(fileURLWithPath:$0)}
        var report=ImportReport(pages:[],warnings:[],files:files.map(\.path).sorted())
        let swiftFiles=files.filter{$0.pathExtension=="swift"}
        if !swiftFiles.isEmpty {
            report=SwiftStructuredImporter.inspect(files:Array(swiftFiles.prefix(500)),assets:assetFiles,options:options)
            report.files=files.map(\.path).sorted()
        }
        var counts:[String:Int]=[:]
        for file in files.filter({$0.pathExtension != "swift"}).prefix(500) {
            guard let data=try? Data(contentsOf:file),data.count<2_000_000,let source=String(data:data,encoding:.utf8) else{continue}
            if file.pathExtension=="swift" && !source.contains("import SwiftUI") && source.range(of:#":\s*(?:SwiftUI\.)?View\b"#,options:.regularExpression)==nil{continue}
            if file.pathExtension=="dart" && !source.contains("Widget") && !source.contains("package:flutter"){continue}
            if file.pathExtension=="kt" && !source.contains("@Composable") && !source.contains("setContent"){continue}
            let markup=["tsx","jsx","vue","html"].contains(file.pathExtension)
            let pattern=markup ? #"<([A-Za-z][A-Za-z0-9_]*)\b"# : #"\b([A-Z][A-Za-z0-9_]*)(?:\.(?:asset|network|file))?\s*\("#
            let regex=try NSRegularExpression(pattern:pattern),ns=source as NSString
            var page=DesignPage(name:file.deletingPathExtension().lastPathComponent),consumedEnd=0
            for match in regex.matches(in:source,range:NSRange(location:0,length:ns.length)) {
                let type=ns.substring(with:match.range(at:1)),start=match.range.location
                if structure.contains(type){if ["ScrollView","List","SingleChildScrollView","LazyColumn"].contains(type){page.scrollEnabled=true};continue}
                if utilities.contains(type) || (markup && ["div","section","main","header","footer","nav","ul","li","a","form","label","svg","path","body","html","head","meta","link","script","style"].contains(type)){continue}
                let line=ns.substring(to:start).components(separatedBy:"\n").count
                let reference="\(file.path):\(line)"
                let excerpt=ns.substring(with:NSRange(location:start,length:min(1600,ns.length-start)))
                let end=markup ? markupEnd(ns,start:start,type:type) : callEnd(ns,start:start)
                let call=ns.substring(with:NSRange(location:start,length:min(end-start,ns.length-start)))
                let strings=quotedStrings(call)
                var mapped=mappings[type]
                if type=="Image" && call.contains("systemName:"){mapped = .icon}
                if type=="ProgressView" && !call.contains("value:"){mapped = .loading}
                if type=="input" && excerpt.contains("password"){mapped = .secureField}
                if type=="input" && excerpt.contains("checkbox"){mapped = .checkbox}
                if type=="input" && excerpt.contains("radio"){mapped = .radio}
                guard let kind=mapped else {
                    if type.first?.isUppercase==true {
                        report.unmatched.append(UnmatchedComponent(typeName:type,sourceReference:reference))
                        if start>=consumedEnd {var n=DesignNode(kind:.custom,frame:Rect(24,80+Double(page.nodes.count)*72,345,60));n.name="未匹配 · \(type)";n.text="待添加预设：\(type)";n.customCode="Text(\(SwiftExporter.literal(n.text)))";n.sourceReference=reference;page.nodes.append(n)}
                    }
                    continue
                }
                if start<consumedEnd{continue}
                counts[type+"|"+kind.rawValue,default:0]+=1
                var n=DesignNode(kind:kind)
                let inner=call.replacingOccurrences(of:#"<[^>]+>"#,with:"",options:.regularExpression).trimmingCharacters(in:.whitespacesAndNewlines)
                let title=markup && !inner.isEmpty && !inner.contains("{") ? inner:(strings.first ?? kind.title)
                n.name="\(kind.title) · \(type)";n.text=title;n.sourceReference=reference+" · "+type
                if kind == .text {n.fontSize=16}
                if [.icon,.iconButton,.avatar].contains(kind) {
                    n.symbol=extract(#"(?:systemName|systemImage)\s*:\s*[\"']([^\"']+)"#,in:call) ?? symbolFromMaterial(call) ?? (kind == .icon ? title : n.symbol)
                }
                if [.button,.outlinedButton,.textButton,.iconLabel,.toggle,.listRow].contains(kind),let label=extract(#"(?:Text|title|label)\s*\(?\s*[\"']([^\"']+)"#,in:call){n.text=label}
                if kind == .iconLabel,let symbol=extract(#"systemImage\s*:\s*[\"']([^\"']+)"#,in:call){n.symbol=symbol}
                if kind == .image || kind == .avatar {
                    let assetName=extract(#"src\s*=\s*[\"']([^\"']+)"#,in:call) ?? strings.first ?? ""
                    if let asset=assetFiles.first(where:{$0.lastPathComponent==URL(fileURLWithPath:assetName).lastPathComponent || $0.deletingLastPathComponent().lastPathComponent==assetName+".imageset" || $0.deletingPathExtension().lastPathComponent==assetName}),let image=NSImage(contentsOf:asset),let tiff=image.tiffRepresentation,let bmp=NSBitmapImageRep(data:tiff),let png=bmp.representation(using:.png,properties:[:]),png.count<20_000_000{n.imageData=png.base64EncodedString()}
                }
                if [.progress,.ringProgress].contains(kind),let value=number("value",in:call){n.value=min(1,max(0,value));if let total=number("total",in:call){n.progressCurrent=value;n.progressTotal=total;n.progressLabel="fraction"}}
                var r=n.frame(.standardPortrait,device:DeviceProfile());r.x=24;r.y=80+Double(page.nodes.count)*72
                if let width=number("width",in:excerpt),width>0{r.width=min(3000,width)}
                if let height=number("height",in:excerpt),height>0{r.height=min(3000,height)}
                n.frames[Variant.standardPortrait.rawValue]=r
                page.nodes.append(n)
                if [.button,.outlinedButton,.textButton,.toggle,.listRow,.profileRow,.card,.alertBanner,.navigationBar,.tabBar,.sidebar].contains(kind){consumedEnd=end}
                if page.nodes.count>=200{report.warnings.append("\(file.lastPathComponent)：静态导入最多 200 个组件，请按页面拆分源文件。");break}
            }
            if !page.nodes.isEmpty {report.pages.append(page);report.warnings.append("\(file.lastPathComponent)：已分类 \(page.nodes.count) 个组件。当前为可编辑草稿；动态布局、条件、状态和业务动作需 Agent 对照源码继续还原。")}
        }
        let additional=counts.keys.sorted().map{let parts=$0.split(separator:"|");return ImportClassification(sourceType:String(parts[0]),componentKind:String(parts[1]),count:counts[$0]!)}
        report.classifications += additional
        for row in additional {report.warnings.append("分类：\(row.sourceType) → \(ComponentKind(rawValue:row.componentKind)?.title ?? row.componentKind) × \(row.count)")}
        var seen=Set<String>();report.unmatched=report.unmatched.filter{seen.insert($0.typeName+"|"+$0.sourceReference).inserted}
        for unknown in report.unmatched where !report.warnings.contains(where:{$0.hasPrefix("未匹配预设："+unknown.typeName+"（"+unknown.sourceReference)}) {report.warnings.append("未匹配预设：\(unknown.typeName)（\(unknown.sourceReference)）。已保留信息，可以指定添加此预设。")}
        if report.pages.isEmpty{report.warnings.append("未找到可识别 UI 控件。可用 MCP 读取源码并重建页面。")}
        return report
    }
    static func markupEnd(_ source:NSString,start:Int,type:String)->Int {
        let tail=source.substring(from:start) as NSString
        let opening=tail.range(of:">")
        guard opening.location != NSNotFound else{return min(source.length,start+100)}
        let head=tail.substring(to:opening.location+1)
        if head.hasSuffix("/>") || ["input","img","hr","br"].contains(type){return start+opening.location+1}
        let closing=tail.range(of:"</"+type+">")
        return closing.location != NSNotFound ? start+closing.location+closing.length : start+opening.location+1
    }
    static func callEnd(_ source:NSString,start:Int)->Int {
        let limit=min(source.length,start+12000);var depth=0;var quote:unichar=0;var escape=false;var begun=false
        for i in start..<limit {let c=source.character(at:i);if quote != 0 {if escape{escape=false}else if c==92{escape=true}else if c==quote{quote=0};continue};if c==34 || c==39{quote=c;continue};if c==40{depth+=1;begun=true};if c==41{depth-=1;if begun && depth==0{return i+1}}}
        return min(source.length,start+200)
    }
    static func extract(_ pattern:String,in source:String)->String? {guard let re=try? NSRegularExpression(pattern:pattern),let m=re.firstMatch(in:source,range:NSRange(location:0,length:(source as NSString).length)),m.numberOfRanges>1 else{return nil};return (source as NSString).substring(with:m.range(at:1))}
    static func number(_ name:String,in text:String)->Double?{extract("\\b"+name+"\\s*[:=]\\s*([0-9]+(?:\\.[0-9]+)?)",in:text).flatMap(Double.init)}
    static func quotedStrings(_ source:String)->[String] {let re=try! NSRegularExpression(pattern:#"[\"']((?:\\.|[^\"'\\])*)[\"']"#),ns=source as NSString;return re.matches(in:source,range:NSRange(location:0,length:ns.length)).map{ns.substring(with:$0.range(at:1)).replacingOccurrences(of:"\\n",with:"\n").replacingOccurrences(of:"\\\"",with:"\"")}}
    static func symbolFromMaterial(_ call:String)->String? {guard let name=extract(#"Icons\.(?:Default\.|Filled\.)?(\w+)"#,in:call) else{return nil};let key=name.lowercased().replacingOccurrences(of:"_outlined",with:"");return ["home":"house","star":"star","favorite":"heart","person":"person","account_circle":"person.crop.circle","menu":"line.3.horizontal","search":"magnifyingglass","settings":"gearshape","arrow_back":"chevron.left","arrowback":"chevron.left","chat":"bubble.left","info":"info.circle"][key] ?? "square"}
}
