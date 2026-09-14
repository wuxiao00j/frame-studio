import Foundation

extension SwiftViewBuilder {
    func knownValue(_ t:[SwiftToken])->Bool {
        let key=SwiftSourceSyntax.text(t)
        return (t.count==1 && (t[0].string || Double(key) != nil || ["true","false"].contains(key))) || enumValue(t) != nil || (t.first?.text=="[" && t.last?.text=="]")
    }
    func condition(_ tokens:[SwiftToken],context:inout SwiftImportContext,depth:Int)->Bool? {
        for raw in SwiftSourceSyntax.split(tokens) {
            let t=SwiftSourceSyntax.compact(raw)
            guard !t.isEmpty else{return nil}
            if ["let","var"].contains(t[0].text),t.count>=2 {
                let name=t[1].text,rhs=t.firstIndex(where:{$0.text=="="}).map{Array(t.dropFirst($0+1))} ?? [t[1]]
                let value=resolve(rhs,context,depth:depth+1)
                if SwiftSourceSyntax.text(value)=="nil"{return false}
                guard knownValue(value) else{return nil}
                context.values[name]=value
            }else {
                guard let flag=boolean(SwiftSourceSyntax.text(resolve(t,context,depth:depth+1))) else{return nil}
                if !flag{return false}
            }
        }
        return true
    }
}
