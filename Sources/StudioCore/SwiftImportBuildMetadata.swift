import Foundation

extension SwiftImportResources {
    static func buildSettings(_ files:[URL])->[String:String] {
        let permitted=["PRODUCT_NAME","MARKETING_VERSION","CURRENT_PROJECT_VERSION","PRODUCT_BUNDLE_IDENTIFIER","INFOPLIST_KEY_CFBundleDisplayName","INFOPLIST_KEY_CFBundleName"]
        var values:[String:Set<String>]=[:]
        for file in files.sorted(by:{$0.path<$1.path}).prefix(100) where file.lastPathComponent=="project.pbxproj" {
            guard let data=try? Data(contentsOf:file),data.count<=2_000_000,let root=(try? PropertyListSerialization.propertyList(from:data,format:nil)) as? [String:Any],let objects=root["objects"] as? [String:[String:Any]] else{continue}
            func configs(_ id:String?)->[(String,[String:Any])] {
                guard let id,let list=objects[id]?["buildConfigurations"] as? [String] else{return []}
                return list.compactMap{key in guard let c=objects[key],let settings=c["buildSettings"] as? [String:Any] else{return nil};return(c["name"] as? String ?? "",settings)}
            }
            let project=(root["rootObject"] as? String).flatMap{objects[$0]},shared=configs(project?["buildConfigurationList"] as? String)
            for target in objects.values where target["isa"] as? String=="PBXNativeTarget" && target["productType"] as? String=="com.apple.product-type.application" {
                for (name,settings) in configs(target["buildConfigurationList"] as? String) {
                    var merged=shared.first{$0.0==name}?.1 ?? [:];merged.merge(settings){_,new in new}
                    var env:[String:String]=["TARGET_NAME":target["name"] as? String ?? ""]
                    for key in permitted {if let value=merged[key] as? String{env[key]=value}else if let value=merged[key] as? NSNumber{env[key]=value.stringValue}}
                    if env["PRODUCT_NAME"]==nil{env["PRODUCT_NAME"]=target["productName"] as? String ?? env["TARGET_NAME"]}
                    for key in permitted {if let raw=env[key],let value=expand(raw,values:env){values[key,default:[]].insert(value)}}
                }
            }
        }
        return values.compactMapValues{$0.count==1 ? $0.first:nil}
    }
    static func expand(_ raw:String,values:[String:String])->String? {
        var result=raw
        for _ in 0..<4 {for (key,value) in values{result=result.replacingOccurrences(of:"$("+key+")",with:value).replacingOccurrences(of:"${"+key+"}",with:value)}}
        return result.isEmpty || result.contains("$(") || result.contains("${") ? nil:result
    }
}
