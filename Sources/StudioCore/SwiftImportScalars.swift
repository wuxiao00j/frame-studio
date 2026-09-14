import Foundation

extension SwiftViewBuilder {
    /// Resolves a small set of pure language expressions. Source is never compiled or run.
    func builtinValue(_ t:[SwiftToken],context:SwiftImportContext,depth:Int)->[SwiftToken]? {
        guard depth<12,!t.isEmpty else{return nil}
        if t.count>=4,t[0].string,t[1].text=="as",["?","!"].contains(t[2].text),["String","NSString"].contains(t[3].text){return resolve([t[0]]+Array(t.dropFirst(4)),context,depth:depth+1)}
        if t.first?.text=="(",SwiftSourceSyntax.end(t,0)==t.count-1 {
            let inner=Array(t.dropFirst().dropLast())
            if SwiftSourceSyntax.split(inner).count==1{return resolve(inner,context,depth:depth+1)}
        }
        if t.count>3,t[1].text==".",["map","flatMap"].contains(t[2].text),t[3].text=="{" {let receiver=resolve([t[0]],context,depth:depth+1);if SwiftSourceSyntax.text(receiver)=="nil"{return receiver}}
        var top:[Int]=[],cursor=0
        while cursor<t.count {
            if ["(","[","{"].contains(t[cursor].text){cursor=SwiftSourceSyntax.end(t,cursor)}
            else{top.append(cursor)};cursor+=1
        }
        let ternary=top.contains{i in t[i].text=="?" && (i==0 || t[i-1].text != "?") && i+1<t.count && !["?","."].contains(t[i+1].text)}
        if !ternary {
            for op in ["||","&&","==","!=",">=","<=",">","<"] {
                let chars=op.map(String.init)
                guard let at=top.first(where:{i in i>0 && i+chars.count<t.count && Array(t[i..<(i+chars.count)]).map(\.text)==chars && (chars.count>1 || (i+1<t.count && t[i+1].text != "="))}) else{continue}
                let left=resolve(Array(t.prefix(at)),context,depth:depth+1),right=resolve(Array(t.dropFirst(at+chars.count)),context,depth:depth+1)
                let a=SwiftSourceSyntax.text(left),b=SwiftSourceSyntax.text(right)
                if let value=boolean(a+op+b){return SwiftSourceSyntax.tokens(value ? "true":"false")}
                if let x=Double(a),let y=Double(b),x.isFinite,y.isFinite {
                    let value:Bool
                    switch op {case ">=":value=x>=y;case "<=":value=x<=y;case ">":value=x>y;case "<":value=x<y;default:return nil}
                    return SwiftSourceSyntax.tokens(value ? "true":"false")
                }
                return nil
            }
        }
        guard let open=t.firstIndex(where:{$0.text=="("}),SwiftSourceSyntax.end(t,open)==t.count-1 else{return nil}
        let name=SwiftSourceSyntax.text(Array(t.prefix(open))).replacingOccurrences(of:"SwiftUI.",with:"")
        let args=SwiftSourceSyntax.arguments(Array(t[(open+1)..<(t.count-1)]))
        if ["LocalizedStringKey","LocalizedStringResource","String"].contains(name),let raw=args["localized"] ?? args["$0"] {
            let value=resolve(raw,context,depth:depth+1)
            if value.count==1,value[0].string {
                if args["localized"] != nil || name=="LocalizedStringResource",let text=SwiftSourceSyntax.literal(value[0]) {
                    let table=args["table"]?.first.flatMap(SwiftSourceSyntax.literal) ?? "Localizable"
                    return SwiftSourceSyntax.tokens(SwiftExporter.literal(index.resources.localized(text,table:table)))
                }
                return value
            }
            if name=="String",let n=Double(SwiftSourceSyntax.text(value)),n.isFinite{return SwiftSourceSyntax.tokens(SwiftExporter.literal(DesignNode.displayNumber(n)))}
        }
        return nil
    }
}
