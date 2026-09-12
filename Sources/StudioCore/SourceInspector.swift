import Foundation

public enum SourceInspector {
    public static let sourceExtensions:Set<String> = ["swift","dart","tsx","jsx","vue","html","css","scss","xml","xib","storyboard","qml","kt","java","json"]
    public static func inventory(_ directory:URL)throws->[String:Any] {
        var isDirectory:ObjCBool=false
        guard FileManager.default.fileExists(atPath:directory.path,isDirectory:&isDirectory),isDirectory.boolValue else{throw StudioError.invalid("请选择原项目文件夹")}
        let excluded:Set<String>=[".git",".build","Pods","Carthage","DerivedData","node_modules","build","dist",".dart_tool",".next","vendor"]
        guard let iterator=FileManager.default.enumerator(at:directory,includingPropertiesForKeys:[.isSymbolicLinkKey],options:[.skipsHiddenFiles]) else{throw StudioError.invalid("无法枚举项目")}
        var sources:[String]=[],assets:[String]=[]
        for case let f as URL in iterator {
            if excluded.contains(f.lastPathComponent) || (try? f.resourceValues(forKeys:[.isSymbolicLinkKey]).isSymbolicLink)==true {iterator.skipDescendants();continue}
            if sourceExtensions.contains(f.pathExtension.lowercased()){sources.append(f.path)}
            else if ["png","jpg","jpeg","webp","svg","heic"].contains(f.pathExtension.lowercased()){assets.append(f.path)}
            if sources.count+assets.count>=2000{break}
        }
        return ["root":directory.path,"sourceFiles":sources.sorted(),"assets":assets.sorted(),"limit":2000,"instructions":"Use read_ui_source to inspect selected UI files. Reconstruct editable DesignProject pages/nodes through create_page/add_component/update_component or replace_project. Flutter/React layouts are agent-assisted, not automatically translated. Original files are read-only; export creates a separate SwiftUI folder."]
    }
    public static func read(_ file:URL)throws->[String:String] {
        guard sourceExtensions.contains(file.pathExtension.lowercased()) else{throw StudioError.invalid("不支持此源文件类型")}
        let data=try Data(contentsOf:file)
        guard data.count<=2_000_000,let text=String(data:data,encoding:.utf8) else{throw StudioError.invalid("文件超过 2 MB 或不是 UTF-8")}
        return ["path":file.path,"source":text]
    }
}
