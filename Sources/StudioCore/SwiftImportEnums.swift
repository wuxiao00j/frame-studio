import Foundation

struct SwiftEnumDefinition {
    var definition:SwiftViewDefinition
    var cases:[String]=[]
    var rawValues:[String:[SwiftToken]]=[:]
}
extension SwiftViewIndex {
    mutating func readEnum(_ tokens:[SwiftToken],definition:SwiftViewDefinition,iterable:Bool) {
        var result=SwiftEnumDefinition(definition:definition),i=0
        while i<tokens.count {
            if tokens[i].text=="case" {
                let end=statementEnd(tokens,i+1)
                for part in SwiftSourceSyntax.split(Array(tokens[(i+1)..<end])) {
                    let t=SwiftSourceSyntax.compact(part)
                    guard let name=t.first?.text,!t.contains(where:{$0.text=="("}) else{continue}
                    result.cases.append(name)
                    result.rawValues[name]=t.count>2 && t[1].text=="=" ? Array(t.dropFirst(2)):SwiftSourceSyntax.tokens(SwiftExporter.literal(name))
                };i=end;continue
            }
            if ["{","(","["].contains(tokens[i].text){i=SwiftSourceSyntax.end(tokens,i)};i+=1
        }
        enums[definition.name]=result
        if iterable,constants[definition.name+".allCases"]==nil {
            constants[definition.name+".allCases"]=SwiftSourceSyntax.tokens("["+result.cases.map{definition.name+"."+$0}.joined(separator:",")+"]")
        }
    }
}
extension SwiftViewBuilder {
    func enumValue(_ t:[SwiftToken],hint:String?=nil)->(String,String)? {
        let key=SwiftSourceSyntax.text(t),parts=key.split(separator:".").map(String.init)
        if parts.count==2,let e=index.enums[parts[0]],e.cases.contains(parts[1]){return(parts[0],parts[1])}
        if key.hasPrefix("."),parts.count==1 {
            if let hint,index.enums[hint]?.cases.contains(parts[0])==true{return(hint,parts[0])}
            let types=index.enums.filter{$0.value.cases.contains(parts[0])}.map(\.key)
            if types.count==1{return(types[0],parts[0])}
        };return nil
    }
    func enumMember(_ t:[SwiftToken],context:SwiftImportContext,depth:Int)->[SwiftToken]? {
        guard t.count>=3,t[t.count-2].text=="." else{return nil}
        let property=t.last!.text,receiver=resolve(Array(t.dropLast(2)),context,depth:depth+1)
        guard let (type,value)=enumValue(receiver),let e=index.enums[type] else{return nil}
        if property=="rawValue"{return e.rawValues[value]}
        guard let member=e.definition.computed[property],evaluating.insert(type+"."+property).inserted else{return nil}
        defer{evaluating.remove(type+"."+property)}
        var environment=SwiftImportContext(owner:type,values:e.definition.defaults)
        environment.values["self"]=SwiftSourceSyntax.tokens(type+"."+value)
        environment.values["rawValue"]=e.rawValues[value]
        return valueBody(member.body,context:environment,depth:depth+1)
    }
    func scalarMember(_ t:[SwiftToken],context:SwiftImportContext,depth:Int)->[SwiftToken]? {
        if t.count>2,t[t.count-2].text==".",["isEmpty","count"].contains(t.last!.text) {
            let value=resolve(Array(t.dropLast(2)),context,depth:depth+1)
            var count:Int?
            if value.count==1,let string=SwiftSourceSyntax.literal(value[0]){count=string.count}
            else if value.first?.text=="[",value.last?.text=="]"{count=SwiftSourceSyntax.split(Array(value.dropFirst().dropLast())).count}
            if let count{return SwiftSourceSyntax.tokens(t.last!.text=="count" ? String(count):count==0 ? "true":"false")}
        }
        if let dot=t.firstIndex(where:{$0.text=="."}),dot+1<t.count,t[dot+1].text=="trimmingCharacters",SwiftSourceSyntax.text(Array(t.dropFirst(dot))).contains(".whitespacesAndNewlines") {
            let value=resolve(Array(t.prefix(dot)),context,depth:depth+1)
            if value.count==1,let string=SwiftSourceSyntax.literal(value[0]){return SwiftSourceSyntax.tokens(SwiftExporter.literal(string.trimmingCharacters(in:.whitespacesAndNewlines)))}
        }
        return nil
    }
}
