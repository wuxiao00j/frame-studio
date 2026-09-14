import Foundation

extension SwiftViewBuilder {
    /// Use only unanimous, known constructor inputs. Dynamic loop/closure inputs
    /// stay unresolved; no call-site-specific application names are encoded here.
    func entryValues(_ name:String)->[String:[SwiftToken]] {
        if let cached=entryCache[name]{return cached}
        var calls:[[String:[SwiftToken]]]=[]
        for owner in index.views.values where owner.name != name {
            for member in owner.members.values {
                let tokens=member.body
                var shadowed=Set(member.parameters)
                for i in tokens.indices {
                    if ["let","var"].contains(tokens[i].text),i+1<tokens.count{shadowed.insert(tokens[i+1].text)}
                    if tokens[i].text=="in",i>0{shadowed.insert(tokens[i-1].text)}
                }
                let context=SwiftImportContext(owner:owner.name,values:defaults(owner).filter{!shadowed.contains($0.key)})
                for i in tokens.indices where tokens[i].text==name {
                    var at=i
                    guard let call=call(tokens,&at),call.name==name else{continue}
                    calls.append(call.args.mapValues{resolve($0,context)})
                }
            }
        }
        var result:[String:[SwiftToken]]=[:]
        if let first=calls.first {
            for (key,value) in first where knownValue(value) || SwiftSourceSyntax.text(value)=="nil" {
                if calls.allSatisfy({$0[key].map{SwiftSourceSyntax.text($0)==SwiftSourceSyntax.text(value)} ?? false}){result[key]=value}
            }
        }
        entryCache[name]=result;return result
    }
}
