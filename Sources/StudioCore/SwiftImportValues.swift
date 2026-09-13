import Foundation

extension SwiftViewBuilder {
    /// Evaluates only literal expressions and selected source branches; never runs Swift code.
    func valueBody(_ tokens:[SwiftToken],context:SwiftImportContext,depth:Int)->[SwiftToken]? {
        guard depth<12 else{return nil}
        var context=context,i=0
        while i<tokens.count {
            if ["\n",";"].contains(tokens[i].text){i+=1;continue}
            if tokens[i].text=="if" || tokens[i].text=="switch" {
                let isSwitch=tokens[i].text=="switch"
                guard let open=(i+1..<tokens.count).first(where:{tokens[$0].text=="{"}) else{return nil}
                let end=SwiftSourceSyntax.end(tokens,open),condition=resolve(Array(tokens[(i+1)..<open]),context,depth:depth+1)
                if isSwitch {
                    let key=SwiftSourceSyntax.text(condition);var cursor=open+1,selected:[SwiftToken]?
                    while cursor<end {
                        if ["case","default"].contains(tokens[cursor].text),let colon=(cursor+1..<end).first(where:{tokens[$0].text==":"}) {
                            let label=SwiftSourceSyntax.text(Array(tokens[(cursor+1)..<colon]));var next=colon+1
                            while next<end && !["case","default"].contains(tokens[next].text){if ["(","[","{"].contains(tokens[next].text){next=SwiftSourceSyntax.end(tokens,next)};next+=1}
                            if label==key || (label.hasPrefix(".") && key.hasSuffix(label)) || (tokens[cursor].text=="default" && selected==nil) {selected=Array(tokens[(colon+1)..<next])}
                            cursor=next
                        }else{cursor+=1}
                    }
                    guard let selected else{return nil}
                    if let value=valueBody(selected,context:context,depth:depth+1),selected.contains(where:{$0.text=="return"}) {return value}
                    applyAssignments(selected,to:&context,depth:depth+1)
                }else {
                    let raw=SwiftSourceSyntax.text(condition)
                    guard let flag=boolean(raw) ?? (condition.contains{$0.text=="let"} && condition.contains{$0.text=="nil"} ? false:nil) else{return nil}
                    if flag,let result=valueBody(Array(tokens[(open+1)..<end]),context:context,depth:depth+1){return result}
                    var next=end+1;while next<tokens.count && tokens[next].text=="\n"{next+=1}
                    if next<tokens.count,tokens[next].text=="else" {
                        if !flag{return valueBody(Array(tokens.dropFirst(next+1)),context:context,depth:depth+1)}
                        if next+1<tokens.count,tokens[next+1].text=="{" {i=SwiftSourceSyntax.end(tokens,next+1)+1;continue}
                    }
                }
                i=end+1;continue
            }
            if tokens[i].text=="{" {let end=SwiftSourceSyntax.end(tokens,i);return valueBody(Array(tokens[(i+1)..<end]),context:context,depth:depth+1)}
            if tokens[i].text=="return" {let end=index.statementEnd(tokens,i+1);return resolve(Array(tokens[(i+1)..<end]),context,depth:depth+1)}
            if ["let","var"].contains(tokens[i].text) {
                let end=index.statementEnd(tokens,i+1)
                applyAssignments(Array(tokens[i..<end]),to:&context,depth:depth+1);i=end;continue
            }
            let end=index.statementEnd(tokens,i)
            if end>i {return resolve(Array(tokens[i..<end]),context,depth:depth+1)}
            i+=1
        };return nil
    }
    func applyAssignments(_ tokens:[SwiftToken],to context:inout SwiftImportContext,depth:Int) {
        var i=0
        while i<tokens.count {
            if ["\n",";"].contains(tokens[i].text){i+=1;continue}
            let end=index.statementEnd(tokens,i)
            if let eq=(i..<end).first(where:{tokens[$0].text=="="}),eq>i {
                let name=["let","var"].contains(tokens[i].text) && i+1<eq ? tokens[i+1].text:tokens[i].text
                context.values[name]=resolve(Array(tokens[(eq+1)..<end]),context,depth:depth+1)
            };i=max(end,i+1)
        }
    }
    func sourceFunction(_ t:[SwiftToken],context:SwiftImportContext,depth:Int)->[SwiftToken]? {
        guard evaluating.count<8 else{return nil}
        let full=SwiftSourceSyntax.text(t)
        if let member=index.views[context.owner]?.computed[full] {
            let key=context.owner+"."+full
            guard evaluating.insert(key).inserted else{return nil};defer{evaluating.remove(key)}
            return valueBody(member.body,context:context,depth:0)
        }
        guard let open=t.firstIndex(where:{$0.text=="("}),SwiftSourceSyntax.end(t,open)==t.count-1 else{return nil}
        let name=SwiftSourceSyntax.text(Array(t.prefix(open))),qualified=index.functions[name] != nil ? name:context.owner+"."+name
        guard let member=index.functions[qualified],evaluating.insert(qualified).inserted else{return nil}
        defer{evaluating.remove(qualified)}
        let args=SwiftSourceSyntax.arguments(Array(t[(open+1)..<(t.count-1)]))
        var environment=SwiftImportContext(owner:qualified.split(separator:".").dropLast().joined(separator:"."),values:member.defaults)
        for (i,param) in member.parameters.enumerated(){if let value=args[param] ?? args["$\(i)"]{environment.values[param]=resolve(value,context,depth:depth+1)}}
        return valueBody(member.body,context:environment,depth:0)
    }
}
