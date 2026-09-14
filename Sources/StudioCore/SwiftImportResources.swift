import Foundation

struct SwiftImportResources {
    var info:[String:String]=[:]
    var strings:[String:[String:String]]=[:]
    init() {}
    init(files:[URL],language:String?) {
        let keys=["CFBundleDisplayName","CFBundleName","CFBundleShortVersionString","CFBundleVersion","CFBundleIdentifier"]
        let settings=Self.buildSettings(files)
        var candidates:[String:Set<String>]=[:],declared=Set<String>()
        var localizedInfo:[String:[String:Set<String>]]=[:],sourceLanguage:String?
        for file in files.sorted(by:{$0.path<$1.path}).prefix(100) {
            guard let data=try? Data(contentsOf:file),data.count<=2_000_000 else{continue}
            if file.lastPathComponent=="Info.plist",let p=(try? PropertyListSerialization.propertyList(from:data,format:nil)) as? [String:Any] {
                for key in keys {if p[key] != nil{declared.insert(key)};if let raw=p[key] as? String,let value=Self.expand(raw,values:settings){candidates[key,default:[]].insert(value)}}
            }
            if file.lastPathComponent=="InfoPlist.strings",let values=(try? PropertyListSerialization.propertyList(from:data,format:nil)) as? [String:String] {
                let locale=file.deletingLastPathComponent().deletingPathExtension().lastPathComponent
                for (key,value) in values where keys.contains(key){localizedInfo[locale,default:[:]][key,default:[]].insert(value)}
            }
            if file.pathExtension=="xcstrings",let root=(try? JSONSerialization.jsonObject(with:data)) as? [String:Any],let entries=root["strings"] as? [String:Any] {
                let locale=language ?? root["sourceLanguage"] as? String ?? "en",table=file.deletingPathExtension().lastPathComponent
                if table=="Localizable"{sourceLanguage=root["sourceLanguage"] as? String}
                for (key,value) in entries {
                    guard let entry=value as? [String:Any],let localizations=entry["localizations"] as? [String:Any] else{continue}
                    let code=localizations[locale] != nil ? locale:localizations.keys.first{$0.replacingOccurrences(of:"_",with:"-")==locale.replacingOccurrences(of:"_",with:"-")}
                    if let code,let localization=localizations[code] as? [String:Any],let unit=localization["stringUnit"] as? [String:Any],let text=unit["value"] as? String {strings[table,default:[:]][key]=text}
                }
            }
        }
        // Multiple targets can have different metadata. Ambiguous values stay unresolved.
        for (key,values) in candidates where values.count==1{info[key]=values.first}
        let generated=["CFBundleDisplayName":"INFOPLIST_KEY_CFBundleDisplayName","CFBundleName":"INFOPLIST_KEY_CFBundleName","CFBundleShortVersionString":"MARKETING_VERSION","CFBundleVersion":"CURRENT_PROJECT_VERSION","CFBundleIdentifier":"PRODUCT_BUNDLE_IDENTIFIER"]
        for (key,setting) in generated where !declared.contains(key) {info[key]=settings[setting]}
        if !declared.contains("CFBundleName"),info["CFBundleName"]==nil{info["CFBundleName"]=settings["PRODUCT_NAME"]}
        if let values=localizedInfo[language ?? sourceLanguage ?? "en"]{for (key,choices) in values{info[key]=choices.count==1 ? choices.first:nil}}
    }
    func localized(_ text:String,table:String="Localizable")->String {strings[table]?[text] ?? text}
}

extension SwiftViewBuilder {
    func sourceInfoValue(_ t:[SwiftToken],context:SwiftImportContext,depth:Int)->[SwiftToken]? {
        guard depth<12 else{return nil}
        let key=SwiftSourceSyntax.text(t)
        if key.hasPrefix("Bundle.main.bundleIdentifier"),let value=index.resources.info["CFBundleIdentifier"] {
            let prefix=SwiftSourceSyntax.tokens("Bundle.main.bundleIdentifier").count
            return resolve(SwiftSourceSyntax.tokens(SwiftExporter.literal(value))+Array(t.dropFirst(prefix)),context,depth:depth+1)
        }
        if key.hasPrefix("Bundle.main.object("),let open=t.firstIndex(where:{$0.text=="("}) {
            let end=SwiftSourceSyntax.end(t,open)
            let args=SwiftSourceSyntax.arguments(Array(t[(open+1)..<end]))
            if let token=args["forInfoDictionaryKey"]?.first,let name=SwiftSourceSyntax.literal(token),let value=index.resources.info[name] {
                return resolve(SwiftSourceSyntax.tokens(SwiftExporter.literal(value))+Array(t.dropFirst(end+1)),context,depth:depth+1)
            }
        }
        if key.hasPrefix("Bundle.main.infoDictionary?["),let open=t.firstIndex(where:{$0.text=="["}) {
            let end=SwiftSourceSyntax.end(t,open)
            if open+1<end,let name=SwiftSourceSyntax.literal(t[open+1]),let value=index.resources.info[name] {
                return resolve(SwiftSourceSyntax.tokens(SwiftExporter.literal(value))+Array(t.dropFirst(end+1)),context,depth:depth+1)
            }
        }
        return nil
    }
    func localizedTitle(_ args:[String:[SwiftToken]])->Bool {
        guard args["verbatim"]==nil,let value=args["$0"] else{return false}
        return value.first?.string==true || SwiftSourceSyntax.text(value).hasPrefix("LocalizedStringKey(") || SwiftSourceSyntax.text(value).hasPrefix("LocalizedStringResource(")
    }
}
