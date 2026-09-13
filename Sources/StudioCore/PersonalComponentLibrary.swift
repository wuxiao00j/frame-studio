import Foundation

public enum PersonalComponentLibrary {
    public static var defaultURL:URL {ProjectStore.defaultURL.deletingLastPathComponent().appendingPathComponent("PersonalComponents.framestudio")}
    public static func load(_ url:URL)throws->DesignProject {
        if FileManager.default.fileExists(atPath:url.path){return try ProjectStore.load(url)}
        var p=DesignProject();p.name="个人组件库";p.pages=[DesignPage(name:"组件库")];return p
    }
    public static func update(_ url:URL,expectedRevision:Int,edit:(inout [ComponentTemplate])->Void)throws->DesignProject {
        try ProjectStore.updateLibrary(url,expectedRevision:expectedRevision,edit:edit)
    }
}
