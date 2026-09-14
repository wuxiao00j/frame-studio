import Foundation

struct SwiftImportContext {
    var owner:String
    var values:[String:[SwiftToken]]=[:]
    var slots:[String:SwiftImportSlot]=[:]
    var elements:[String:SwiftImportElement]=[:]
    var tuples:[String:[String]]=[:]
}
struct SwiftImportSlot {var tokens:[SwiftToken];var context:SwiftImportContext}
final class SwiftImportElement {
    var id=UUID().uuidString
    var type:String
    var args:[String:[SwiftToken]]
    var children:[SwiftImportElement]
    var reference:String
    var group=""
    var pinned=false
    init(_ type:String,args:[String:[SwiftToken]]=[:],children:[SwiftImportElement]=[],reference:String="") {
        self.type=type;self.args=args;self.children=children;self.reference=reference
    }
}
struct SwiftImportCall {
    var name:String
    var args:[String:[SwiftToken]]=[:]
    var closures:[String:[SwiftToken]]=[:]
    var line=1
}

final class SwiftViewBuilder {
    let index:SwiftViewIndex
    let options:SwiftImportOptions
    let overrides:[(key:[SwiftToken],value:[SwiftToken])]
    var warnings=Set<String>()
    var unmatched:[UnmatchedComponent]=[]
    var expanded=Set<String>()
    var active:[String]=[]
    var evaluating=Set<String>()
    var entryCache:[String:[String:[SwiftToken]]]=[:]
    var created=0
    let limit=1600
    init(index:SwiftViewIndex,options:SwiftImportOptions=SwiftImportOptions()){
        self.index=index;self.options=options
        var pairs=options.values.map{(key:SwiftSourceSyntax.compact(SwiftSourceSyntax.tokens($0.key)),value:SwiftSourceSyntax.tokens($0.value))}
        pairs += options.colors.map{(key:SwiftSourceSyntax.compact(SwiftSourceSyntax.tokens($0.key)),value:SwiftSourceSyntax.tokens("Color(hex:\"\($0.value)\")"))}
        overrides=pairs.filter{!$0.key.isEmpty}.sorted{$0.key.count>$1.key.count}
    }
    func boolean(_ value:String,depth:Int=0)->Bool? {
        guard depth<48,value.count<16000 else{return nil}
        let tokens=SwiftSourceSyntax.tokens(value)
        if tokens.first?.text=="(",SwiftSourceSyntax.end(tokens,0)==tokens.count-1{return boolean(SwiftSourceSyntax.text(Array(tokens.dropFirst().dropLast())),depth:depth+1)}
        for op in ["|","&"] {
            var i=0
            while i+1<tokens.count {
                if ["(","[","{"].contains(tokens[i].text){i=SwiftSourceSyntax.end(tokens,i)}
                else if tokens[i].text==op,tokens[i+1].text==op {
                    let a=boolean(SwiftSourceSyntax.text(Array(tokens.prefix(i))),depth:depth+1),b=boolean(SwiftSourceSyntax.text(Array(tokens.dropFirst(i+2))),depth:depth+1)
                    if op=="|" {if a==true || b==true{return true};if a==false && b==false{return false}}
                    else{if a==false || b==false{return false};if a==true && b==true{return true}}
                    return nil
                };i+=1
            }
        }
        if value=="true"{return true};if value=="false"{return false}
        if value.hasPrefix("!"),let inner=boolean(String(value.dropFirst()),depth:depth+1){return !inner}
        for op in ["==","!="] {
            var split:Int?,i=0
            while i+1<tokens.count {if ["(","[","{"].contains(tokens[i].text){i=SwiftSourceSyntax.end(tokens,i)}else if tokens[i].text==String(op.first!),tokens[i+1].text=="="{split=i;break};i+=1}
            let parts=split.map{[SwiftSourceSyntax.text(Array(tokens.prefix($0))),SwiftSourceSyntax.text(Array(tokens.dropFirst($0+2)))]} ?? []
            if parts.count==2,let a=enumValue(SwiftSourceSyntax.tokens(parts[0]),hint:enumValue(SwiftSourceSyntax.tokens(parts[1]))?.0),let b=enumValue(SwiftSourceSyntax.tokens(parts[1]),hint:a.0){return (a==b)==(op=="==")}
            if parts.count==2,parts.allSatisfy({["nil","true","false"].contains($0) || $0.hasPrefix(".") || $0.hasPrefix("\"") || Double($0) != nil}) {return (parts[0]==parts[1]) == (op=="==")}
        };return nil
    }
    func interpolation(_ token:SwiftToken,context:SwiftImportContext,depth:Int)->SwiftToken {
        guard token.string,token.text.contains("\\("),depth<8 else{return token}
        let chars=Array(token.text);var i=0,result=""
        while i<chars.count {
            if chars[i]=="\\",i+1<chars.count,chars[i+1]=="(" {
                let start=i;i+=2;let begin=i;var level=1
                while i<chars.count && level>0{if chars[i]=="("{level+=1};if chars[i]==")"{level-=1};i+=1}
                guard level==0 else{result+=String(chars[start...]);break}
                let expression=String(chars[begin..<(i-1)]),value=resolve(SwiftSourceSyntax.tokens(expression),context,depth:depth+1)
                if value.count==1,let literal=SwiftSourceSyntax.literal(value[0]) {result+=literal.replacingOccurrences(of:"\\",with:"\\\\").replacingOccurrences(of:"\"",with:"\\\"")}
                else if let number=Double(SwiftSourceSyntax.text(value)),number.isFinite {result+=number.rounded()==number ? String(format:"%.0f",number):String(number)}
                else{result+=String(chars[start..<i])}
            }else{result.append(chars[i]);i+=1}
        }
        var resultToken=token;resultToken.text=result;return resultToken
    }
    func warn(_ text:String,_ reference:String){warnings.insert("导入限制：\(text)（\(reference)）")}
    func reference(_ context:SwiftImportContext,_ line:Int)->String{"\(index.views[context.owner]?.file ?? context.owner):\(line)"}
    func build(_ name:String)->SwiftImportElement {
        guard let definition=index.views[name] else{return SwiftImportElement("Group")}
        var values=defaults(definition);values.merge(entryValues(name)){_,new in new}
        let context=SwiftImportContext(owner:name,values:values)
        return expand("body",context:context,args:[:],closures:[:])
    }
    func defaults(_ definition:SwiftViewDefinition)->[String:[SwiftToken]] {
        var values=definition.defaults
        for (property,type) in definition.collections {
            if let order=index.constants[type+".defaultOrder"] {
                values[property]=order
                warn("动态列表 \(property) 使用源码中的 \(type).defaultOrder 作为样例",definition.file+":"+String(definition.line))
            }
        };return values
    }
    func resolve(_ tokens:[SwiftToken],_ context:SwiftImportContext,depth:Int=0)->[SwiftToken] {
        var t=SwiftSourceSyntax.compact(tokens);guard depth<12,!t.isEmpty else{return t}
        t=t.map{interpolation($0,context:context,depth:depth)}
        var i=0,replaced:[SwiftToken]=[]
        while i<t.count {
            if !t[i].string,let pair=overrides.first(where:{pair in i+pair.key.count<=t.count && (i+pair.key.count==t.count || t[i+pair.key.count].text != ":") && zip(pair.key,t[i..<(i+pair.key.count)]).allSatisfy{$0.text==$1.text && $0.string==$1.string}}) {
                replaced+=pair.value;i+=pair.key.count
            }else{replaced.append(t[i]);i+=1}
        }
        t=replaced
        var expandedTokens:[SwiftToken]=[];i=0
        while i<t.count {
            var end=i+1
            if !t[i].string {while end+1<t.count && t[end].text=="."{end+=2}}
            let name=SwiftSourceSyntax.text(Array(t[i..<end]))
            if let constant=index.constants[name],SwiftSourceSyntax.text(constant) != name {expandedTokens+=resolve(constant,context,depth:depth+1);i=end}
            else {expandedTokens.append(t[i]);i+=1}
        }
        t=expandedTokens
        var opacityIndex=0
        while opacityIndex+2<t.count {
            if t[opacityIndex].text=="opacity",t[opacityIndex+1].text=="(" {
                let end=SwiftSourceSyntax.end(t,opacityIndex+1)
                let value=resolve(Array(t[(opacityIndex+2)..<end]),context,depth:depth+1)
                t.replaceSubrange((opacityIndex+2)..<end,with:value);opacityIndex+=value.count+3
            }else{opacityIndex+=1}
        }
        let key=SwiftSourceSyntax.text(t).replacingOccurrences(of:"self.",with:"").trimmingCharacters(in:CharacterSet(charactersIn:"$"))
        if let value=context.values[key],SwiftSourceSyntax.text(value) != key{return resolve(value,context,depth:depth+1)}
        if let value=index.constants[key],SwiftSourceSyntax.text(value) != key{return resolve(value,context,depth:depth+1)}
        if key.hasPrefix("Self."),let value=index.constants[context.owner+"."+key.dropFirst(5)]{return resolve(value,context,depth:depth+1)}
        if !key.contains("."),let value=index.constants[context.owner+"."+key],SwiftSourceSyntax.text(value) != key{return resolve(value,context,depth:depth+1)}
        if let value=sourceFunction(t,context:context,depth:depth),SwiftSourceSyntax.text(value) != key{return value}
        if let value=sourceInfoValue(t,context:context,depth:depth){return value}
        if let value=builtinValue(t,context:context,depth:depth){return value}
        if let value=scalarMember(t,context:context,depth:depth){return value}
        if let value=enumMember(t,context:context,depth:depth){return value}
        if t.first?.text=="!",let flag=boolean(SwiftSourceSyntax.text(resolve(Array(t.dropFirst()),context,depth:depth+1))){return SwiftSourceSyntax.tokens(flag ? "false":"true")}
        if t.count>=3,let value=context.values[t[0].text] {
            let list=resolve(value,context,depth:depth+1)
            if list.first?.text=="[",list.last?.text=="]" {
                let items=SwiftSourceSyntax.split(Array(list.dropFirst().dropLast()))
                if t[1].text=="." {
                    if t[2].text=="indices"{return SwiftSourceSyntax.tokens("["+items.indices.map{String($0)}.joined(separator:",")+"]")}
                    if t[2].text=="count"{return SwiftSourceSyntax.tokens(String(items.count))}
                    if t[2].text=="isEmpty"{return SwiftSourceSyntax.tokens(items.isEmpty ? "true":"false")}
                    if t[2].text=="map",t.count>4,t[3].text=="{" {
                        let (body,param)=closureBody(Array(t[4..<SwiftSourceSyntax.end(t,3)])),name=param ?? "$0"
                        var output=SwiftSourceSyntax.tokens("[")
                        for (i,item) in items.prefix(40).enumerated(){var scope=context;scope.values[name]=item;scope.tuples[name]=context.tuples[t[0].text];if i>0{output+=SwiftSourceSyntax.tokens(",")};output+=resolve(body,scope,depth:depth+1)}
                        output+=SwiftSourceSyntax.tokens("]");return output
                    }
                }
                if t[1].text=="[" {
                    let end=SwiftSourceSyntax.end(t,1)
                    if let index=Int(SwiftSourceSyntax.text(resolve(Array(t[2..<end]),context,depth:depth+1))),items.indices.contains(index){return resolve(items[index],context,depth:depth+1)}
                }
            }
        }
        if t.count>=3,t[1].text==".",let value=context.values[t[0].text] {
            let resolved=resolve(value,context,depth:depth+1)
            if t[2].text=="opacity" {return resolved+resolve(Array(t.dropFirst()),context,depth:depth+1)}
            if let open=resolved.firstIndex(where:{$0.text=="("}) {
                let args=SwiftSourceSyntax.arguments(Array(resolved[(open+1)..<SwiftSourceSyntax.end(resolved,open)]))
                if let field=args[t[2].text]{return resolve(field,context,depth:depth+1)}
                let type=SwiftSourceSyntax.text(Array(resolved.prefix(open)))
                if let field=index.valueDefaults[type]?[t[2].text]{return resolve(field,context,depth:depth+1)}
                if let fields=context.tuples[t[0].text],let position=fields.firstIndex(of:t[2].text),let field=args["$\(position)"]{return resolve(field,context,depth:depth+1)}
            }
        }
        if t.first?.text=="[",SwiftSourceSyntax.end(t,0)==t.count-1 {
            var output=SwiftSourceSyntax.tokens("[")
            let items=SwiftSourceSyntax.split(Array(t.dropFirst().dropLast())),hint=items.compactMap{enumValue($0)?.0}.first
            for (i,item) in items.enumerated(){if i>0{output+=SwiftSourceSyntax.tokens(",")};let value=resolve(item,context,depth:depth+1);if let e=enumValue(value,hint:hint){output+=SwiftSourceSyntax.tokens(e.0+"."+e.1)}else{output+=value}}
            output+=SwiftSourceSyntax.tokens("]");return output
        }
        if let open=t.firstIndex(where:{$0.text=="("}),open>0,SwiftSourceSyntax.end(t,open)==t.count-1,t[0].text.first?.isUppercase==true || t[0].text=="." {
            var output=Array(t.prefix(open+1))
            for (i,part) in SwiftSourceSyntax.split(Array(t[(open+1)..<(t.count-1)])).enumerated(){if i>0{output+=SwiftSourceSyntax.tokens(",")};if part.count>1,part[1].text==":"{output+=part.prefix(2);output+=resolve(Array(part.dropFirst(2)),context,depth:depth+1)}else{output+=resolve(part,context,depth:depth+1)}}
            output+=SwiftSourceSyntax.tokens(")");return output
        }
        var result:[SwiftToken]=[]
        for (i,token) in t.enumerated() {
            if !token.string,(i==0 || t[i-1].text != "."),(i+1==t.count || ![".",":"].contains(t[i+1].text)),let value=context.values[token.text],SwiftSourceSyntax.text(value) != token.text {
                result += resolve(value,context,depth:depth+1)
            }else if !token.string,(i==0 || t[i-1].text != "."),(i+1==t.count || ![".",":"].contains(t[i+1].text)),index.views[context.owner]?.computed[token.text] != nil {
                result += resolve([token],context,depth:depth+1)
            }else{result.append(token)}
            if result.count>4096{return Array(result.prefix(4096))}
        }
        var optional=0
        while optional+3<result.count {
            if result[optional].text=="nil",result[optional+1].text=="?",result[optional+2].text==".",result[optional+3].text.first?.isLetter==true {
                var end=optional+4
                while end+1<result.count,result[end].text==".",result[end+1].text.first?.isLetter==true{end+=2}
                if end==result.count || result[end].text != "(" {result.removeSubrange((optional+1)..<end)}
            };optional+=1
        }
        let arrays=SwiftSourceSyntax.split(result,separator:"+")
        if arrays.count>1,arrays.allSatisfy({$0.first?.text=="[" && $0.last?.text=="]"}) {
            var merged=SwiftSourceSyntax.tokens("[")
            for (i,array) in arrays.enumerated(){if i>0{merged+=SwiftSourceSyntax.tokens(",")};merged+=array.dropFirst().dropLast()}
            merged+=SwiftSourceSyntax.tokens("]");return merged
        }
        var q=0
        while q<result.count {
            if ["(","[","{"].contains(result[q].text){q=SwiftSourceSyntax.end(result,q)}
            else if result[q].text=="?",q+1<result.count,result[q+1].text=="?" {
                let lhs=resolve(Array(result.prefix(q)),context,depth:depth+1),key=SwiftSourceSyntax.text(lhs)
                if key=="nil" || (lhs.first?.text=="nil" && lhs.dropFirst().contains{$0.text=="?"}){return resolve(Array(result.dropFirst(q+2)),context,depth:depth+1)}
                if lhs.count==1,(lhs[0].string || Double(key) != nil || ["true","false"].contains(key)){return lhs}
            }
            else if result[q].text=="?",q+1<result.count,result[q+1].text != "?",result[q+1].text != ".",let condition=boolean(SwiftSourceSyntax.text(resolve(Array(result.prefix(q)),context,depth:depth+1))) {
                var colon=q+1
                while colon<result.count && result[colon].text != ":" {if ["(","[","{"].contains(result[colon].text){colon=SwiftSourceSyntax.end(result,colon)};colon+=1}
                if colon<result.count {return resolve(condition ? Array(result[(q+1)..<colon]):Array(result.dropFirst(colon+1)),context,depth:depth+1)}
            }
            q+=1
        }
        if let flag=boolean(SwiftSourceSyntax.text(result)){return SwiftSourceSyntax.tokens(flag ? "true":"false")}
        return result
    }
    func call(_ t:[SwiftToken],_ position:inout Int)->SwiftImportCall? {
        guard position<t.count else{return nil}
        while position<t.count && ["\n",";","return"].contains(t[position].text){position+=1}
        guard position<t.count,t[position].text.first?.isLetter==true || t[position].text.first=="_" || t[position].text=="." else{return nil}
        var value=SwiftImportCall(name:t[position].text,line:t[position].line);position+=1
        // Qualified names are contiguous; a dot on the next line starts a modifier.
        while position+1<t.count,t[position].text==".",t[position-1].line==t[position].line {
            if ["opacity","ignoresSafeArea","fill","stroke","strokeBorder","frame","padding","background","overlay","font","foregroundStyle","foregroundColor","offset","clipShape","shadow","onAppear","preference"].contains(t[position+1].text){break}
            value.name += "."+t[position+1].text;position+=2
        }
        if position<t.count,t[position].text=="(" {
            let end=SwiftSourceSyntax.end(t,position)
            value.args=SwiftSourceSyntax.arguments(Array(t[(position+1)..<end]));position=end+1
        }
        var cursor=position
        while cursor<t.count && t[cursor].text=="\n"{cursor+=1}
        if cursor<t.count,t[cursor].text=="{" {
            let end=SwiftSourceSyntax.end(t,cursor);value.closures["$body"]=Array(t[(cursor+1)..<end]);position=end+1
        }
        while position<t.count {
            var cursor=position;while cursor<t.count && t[cursor].text=="\n"{cursor+=1}
            guard cursor+2<t.count,t[cursor+1].text==":",t[cursor+2].text=="{" else{break}
            let end=SwiftSourceSyntax.end(t,cursor+2)
            value.closures[t[cursor].text]=Array(t[(cursor+3)..<end]);position=end+1
        }
        return value
    }
    func closureBody(_ t:[SwiftToken])->([SwiftToken],String?) {
        var i=0
        while i<t.count && !["{","(","\n"].contains(t[i].text) {
            if t[i].text=="in" {return(Array(t.dropFirst(i+1)),t.first?.text)};i+=1
        };return(t,nil)
    }
    func sequence(_ t:[SwiftToken],context:SwiftImportContext)->[SwiftImportElement] {
        guard active.count<28,created<limit else{warn("展开达到安全上限，需要进一步分拆视图",reference(context,t.first?.line ?? 1));return []}
        var context=context
        var nodes:[SwiftImportElement]=[],i=0
        while i<t.count && created<limit {
            if ["\n",";","return"].contains(t[i].text){i+=1;continue}
            if ["let","var"].contains(t[i].text),i+1<t.count {
                let key=t[i+1].text,end=index.statementEnd(t,i+2)
                if let eq=(i+2..<end).first(where:{t[$0].text=="="}) {context.values[key]=resolve(Array(t[(eq+1)..<end]),context)}
                i=end;continue
            }
            if ["guard","for","Task"].contains(t[i].text) {
                while i<t.count && t[i].text != "\n"{if ["(","[","{"].contains(t[i].text){i=SwiftSourceSyntax.end(t,i)};i+=1};continue
            }
            if t[i].text=="if" {
                let start=i
                guard let open=(i+1..<t.count).first(where:{t[$0].text=="{"}) else{break}
                let conditionTokens=resolve(Array(t[(i+1)..<open]),context)
                var condition=SwiftSourceSyntax.text(conditionTokens)
                if conditionTokens.contains(where:{$0.text=="let"}) && conditionTokens.contains(where:{$0.text=="nil"}){condition="false"}
                if let known=boolean(condition){condition=known ? "true":"false"}
                let end=SwiftSourceSyntax.end(t,open)
                var chosen=Array(t[(open+1)..<end]);i=end+1
                while i<t.count && t[i].text=="\n"{i+=1}
                if i<t.count,t[i].text=="else" {
                    let elseStart=i+1
                    if elseStart<t.count,t[elseStart].text=="{" {
                        let close=SwiftSourceSyntax.end(t,elseStart)
                        if condition=="false"{chosen=Array(t[(elseStart+1)..<close])};i=close+1
                    }else if elseStart<t.count,t[elseStart].text=="if" {
                        // Consume the entire alternative chain; only one branch is represented.
                        var cursor=elseStart
                        repeat {
                            guard let next=(cursor..<t.count).first(where:{t[$0].text=="{"}) else{break}
                            cursor=SwiftSourceSyntax.end(t,next)+1
                            while cursor<t.count && t[cursor].text=="\n"{cursor+=1}
                            if cursor<t.count && t[cursor].text=="else"{cursor+=1}else{break}
                        }while cursor<t.count
                        if condition=="false"{chosen=Array(t[elseStart..<cursor])}
                        i=cursor
                    }
                }else if condition=="false"{chosen=[]}
                if condition != "true" && condition != "false" {warn("条件分支仅展示一个静态样例：\(String(condition.prefix(70)))",reference(context,t[start].line))}
                nodes += sequence(chosen,context:context);continue
            }
            if t[i].text=="switch" {
                guard let open=(i+1..<t.count).first(where:{t[$0].text=="{"}) else{break}
                let value=SwiftSourceSyntax.text(resolve(Array(t[(i+1)..<open]),context)),close=SwiftSourceSyntax.end(t,open)
                var branches:[(String,[SwiftToken])]=[],j=open+1
                while j<close {
                    if ["case","default"].contains(t[j].text),let colon=(j+1..<close).first(where:{t[$0].text==":"}) {
                        let key=SwiftSourceSyntax.text(Array(t[(j+1)..<colon]));var end=colon+1
                        while end<close && !["case","default"].contains(t[end].text){if ["(","[","{"].contains(t[end].text){end=SwiftSourceSyntax.end(t,end)};end+=1}
                        branches.append((key,Array(t[(colon+1)..<end])));j=end
                    }else{j+=1}
                }
                let match=branches.first{$0.0==value || (!$0.0.isEmpty && value.hasSuffix($0.0))}
                if match==nil {warn("switch 仅展示首个分支：\(String(value.prefix(60)))",reference(context,t[i].line))}
                if let branch=match ?? branches.first {nodes += sequence(branch.1,context:context)}
                i=close+1;continue
            }
            let start=i
            guard let expression=call(t,&i) else{if ["(","[","{"].contains(t[i].text){i=SwiftSourceSyntax.end(t,i)};i+=1;continue}
            var element=element(expression,context:context)
            while i<t.count {
                var cursor=i;while cursor<t.count && t[cursor].text=="\n"{cursor+=1}
                guard cursor<t.count,t[cursor].text==".",cursor+1<t.count else{break}
                cursor+=1
                guard let modifier=call(t,&cursor) else{break};i=cursor
                if let current=element {element=modify(current,modifier,context:context)}
            }
            if let element{nodes.append(element);created+=1}
            if i<=start{i=start+1}
        };return nodes
    }
    func expand(_ name:String,context:SwiftImportContext,args:[String:[SwiftToken]],closures:[String:[SwiftToken]])->SwiftImportElement {
        let key=context.owner+"."+name
        guard !active.contains(key),active.count<28,let member=index.views[context.owner]?.members[name] else{
            warn("递归或无法展开的视图：\(key)",reference(context,1));return SwiftImportElement("Group")
        }
        var next=context;next.values.merge(member.defaults){_,new in new}
        next.tuples.merge(member.tupleFields){_,new in new}
        for (i,param) in member.parameters.enumerated(){if let arg=args[param] ?? args["$\(i)"]{next.values[param]=resolve(arg,context)}}
        active.append(key);defer{active.removeLast()}
        return SwiftImportElement("Group",children:sequence(member.body,context:next),reference:reference(context,member.body.first?.line ?? 1))
    }
    func element(_ call:SwiftImportCall,context:SwiftImportContext)->SwiftImportElement? {
        let name=call.name.replacingOccurrences(of:"SwiftUI.",with:""),ref=reference(context,call.line)
        var args=call.args.mapValues{resolve($0,context)}
        if ["Text","Label","Button","Menu","Picker","TextField","SecureField","DatePicker","LabeledContent","ContentUnavailableView","Toggle","NavigationLink","Section"].contains(name),localizedTitle(call.args){args["_localizeTitle"]=SwiftSourceSyntax.tokens("true")}
        func body(_ key:String="$body")->[SwiftImportElement] {sequence(closureBody(call.closures[key] ?? []).0,context:context)}
        if let element=context.elements[name]{return element}
        if index.constants[name] != nil {
            let value=resolve(SwiftSourceSyntax.tokens(name),context)
            return SwiftImportElement("Color",args:["$0":value],reference:ref)
        }
        if let value=context.values[name],let first=value.first,first.text != name,!first.string,(SwiftImporter.mappings[first.text] != nil || first.text=="Color" || index.views[first.text] != nil || index.views[context.owner]?.members[first.text] != nil) {
            return SwiftImportElement("Group",children:sequence(value,context:context),reference:ref)
        }
        if let slot=context.slots[name] {
            var capture=slot.context
            let (tokens,param)=closureBody(slot.tokens)
            if let param{capture.values[param]=args["$0"] ?? [SwiftToken(text:"〈item〉",line:call.line)]}
            return SwiftImportElement("Group",children:sequence(tokens,context:capture),reference:ref)
        }
        if index.views[context.owner]?.members[name] != nil {return expand(name,context:context,args:args,closures:call.closures)}
        if let definition=index.views[name] {
            var next=SwiftImportContext(owner:name,values:defaults(definition))
            for (key,value) in args {next.values[key]=value}
            for (key,value) in call.closures where key != "$body" {next.slots[key]=SwiftImportSlot(tokens:value,context:context)}
            if let content=call.closures["$body"] {
                let target=definition.slots.contains("content") && next.slots["content"]==nil ? "content":definition.slots.first{next.slots[$0]==nil} ?? "content"
                next.slots[target]=SwiftImportSlot(tokens:content,context:context)
            }
            for (key,value) in args where value.first?.text=="{" {next.slots[key]=SwiftImportSlot(tokens:Array(value.dropFirst().dropLast()),context:context)}
            expanded.insert(name)
            let result=expand("body",context:next,args:[:],closures:[:]);result.group=UUID().uuidString
            return result
        }
        if index.layouts.contains(name) {
            warn("自定义 Layout 采用换行流式布局近似：\(name)",ref)
            return SwiftImportElement("FlowLayout",args:args,children:body(),reference:ref)
        }
        if let control=nativeControl(call,args:args,context:context){return control}
        if ["VStack","HStack","ZStack","LazyVStack","LazyHStack","Group","NavigationStack","NavigationView","ScrollView","ScrollViewReader","List","Form","Section","GeometryReader","ViewThatFits","ToolbarItem","ToolbarItemGroup"].contains(name) {
            var children=body()
            if name=="List",args["$0"] != nil,closureBody(call.closures["$body"] ?? []).1 != nil {
                var loop=call;loop.name="ForEach";children=element(loop,context:context).map{[$0]} ?? []
            }
            if name=="Section" {
                if let header=call.closures["header"] ?? call.args["header"] {children.insert(SwiftImportElement("SectionHeader",children:sequence(header,context:context),reference:ref),at:0)}
                if let footer=call.closures["footer"] ?? call.args["footer"] {children.append(SwiftImportElement("SectionFooter",children:sequence(footer,context:context),reference:ref))}
            }
            if name=="GeometryReader"{warn("GeometryReader 按当前画布宽度估算",ref)}
            return SwiftImportElement(name,args:args,children:children,reference:ref)
        }
        if name=="ForEach" {
            let input=args["$0"] ?? [],(tokens,param)=closureBody(call.closures["$body"] ?? [])
            var values:[[SwiftToken]]=[]
            if input.first?.text=="[",input.last?.text=="]" {values=SwiftSourceSyntax.split(Array(input.dropFirst().dropLast()));if values.isEmpty{return SwiftImportElement("Group",reference:ref)}}
            if values.isEmpty {values=[[SwiftToken(text:"〈item〉",line:call.line)]];warn("动态列表展示一个样例，数量与内容需补充",ref)}
            var children:[SwiftImportElement]=[]
            for value in values.prefix(20){var next=context;if let param{next.values[param]=value};children += sequence(tokens,context:next)}
            return SwiftImportElement("Group",children:children,reference:ref)
        }
        if ["Button","NavigationLink","PhotosPicker"].contains(name) {
            let label=call.closures["label"] ?? (call.args["$0"]==nil && ["Button","PhotosPicker"].contains(name) ? call.closures["$body"]:nil)
            if let label{return SwiftImportElement("Group",args:["_buttonLabel":SwiftSourceSyntax.tokens("true")],children:sequence(label,context:context),reference:ref)}
            // Action / destination closures never become visible layers.
            var args=args
            let action=SwiftSourceSyntax.text(call.closures["$body"] ?? call.args["action"] ?? [])
            if ["dismiss()","self.dismiss()"].contains(action){args["_navigationBack"]=SwiftSourceSyntax.tokens("true")}
            return SwiftImportElement("Button",args:args,reference:ref)
        }
        if ["EmptyView","AnyView"].contains(name){return name=="EmptyView" ? nil:SwiftImportElement("Group",children:sequence(args["$0"] ?? [],context:context),reference:ref)}
        if name=="TabView" {return SwiftImportElement("Group",children:Array(body().prefix(1)),reference:ref)}
        if SwiftImporter.mappings[name] != nil || name.hasPrefix("Color.") || ["Color","Capsule","LinearGradient","RadialGradient"].contains(name) {
            var resolved=args
            if name.hasPrefix("Color."){resolved["$0"]=[SwiftToken(text:name,line:call.line)]}
            let children=["Toggle","Picker"].contains(name) ? body():[]
            return SwiftImportElement(name.hasPrefix("Color.") ? "Color":name,args:resolved,children:children,reference:ref)
        }
        if name.first?.isUppercase==true,!SwiftImporter.utilities.contains(name) {
            unmatched.append(UnmatchedComponent(typeName:name,sourceReference:ref))
            return SwiftImportElement("Unresolved",args:["$0":[SwiftToken(text:"\"\(name)\"",line:call.line,string:true)]],reference:ref)
        }
        if !["self","content"].contains(name){warn("无法静态展开的视图片段：\(name)",ref)}
        return nil
    }
    func modify(_ element:SwiftImportElement,_ modifier:SwiftImportCall,context:SwiftImportContext)->SwiftImportElement {
        let name=modifier.name,ref=reference(context,modifier.line)
        var args=modifier.args.mapValues{resolve($0,context)}
        if name=="navigationTitle",localizedTitle(modifier.args){args["_localizeTitle"]=SwiftSourceSyntax.tokens("true")}
        if name=="toolbar",let content=modifier.closures["$body"] {return SwiftImportElement(".toolbar",args:args,children:[element]+sequence(content,context:context),reference:ref)}
        if name=="toolbar",SwiftSourceSyntax.text(args["for"] ?? []).contains("navigationBar") {return SwiftImportElement(".navigationBarVisibility",args:args,children:[element],reference:ref)}
        let supported:Set<String>=["padding","frame","offset","position","font","foregroundStyle","foregroundColor","tint","background","overlay","clipShape","cornerRadius","fill","stroke","strokeBorder","opacity","shadow","bold","fontWeight","multilineTextAlignment","buttonStyle","blur","lineSpacing","lineLimit","minimumScaleFactor","tag","navigationTitle","toolbarBackground","listRowBackground","disabled","clipped","scaledToFit","scaledToFill","resizable","aspectRatio","fixedSize","layoutPriority"]
        if supported.contains(name) {
            var children=[element]
            if ["background","overlay"].contains(name),let tokens=modifier.closures["$body"] {
                children += sequence(tokens,context:context)
            }
            if ["background","overlay"].contains(name),let value=args["$0"],let first=value.first,let alias=context.values[first.text] {args["$0"]=alias+value.dropFirst()}
            if ["background","overlay"].contains(name),let value=args["$0"],let first=value.first,["ZStack","VStack","HStack","Rectangle","RoundedRectangle","Circle","Capsule"].contains(first.text) {
                children += sequence(value,context:context);args.removeValue(forKey:"$0")
            }
            return SwiftImportElement("."+name,args:args,children:children,reference:ref)
        }
        func isText(_ e:SwiftImportElement)->Bool {e.type=="Text" || (e.type.hasPrefix(".") && e.children.first.map(isText)==true)}
        let extensionFunction=(isText(element) ? index.textExtensions.members[name]:nil) ?? index.viewExtensions.members[name]
        if let function=extensionFunction,!active.contains("modifier."+name),active.count<40 {
            var environment=context
            environment.values.merge(function.defaults){_,new in new}
            for (i,param) in function.parameters.enumerated() {if let value=args[param] ?? args["$\(i)"]{environment.values[param]=value}}
            let tokens=SwiftSourceSyntax.compact(function.body)
            // Only a single, explicit modifier chain is accepted here. Do not
            // interpret arbitrary extension bodies or execute their source.
            var cursor=tokens.first?.text=="return" ? 1:0
            if cursor<tokens.count,tokens[cursor].text=="self" {cursor+=1;if cursor<tokens.count,tokens[cursor].text=="."{cursor+=1}}
            var chain:[SwiftImportCall]=[]
            while cursor<tokens.count {
                guard let part=call(tokens,&cursor),supported.contains(part.name) || ["truncationMode","allowsTightening"].contains(part.name) else{chain=[];break}
                chain.append(part)
                if cursor==tokens.count{break}
                guard tokens[cursor].text=="." else{chain=[];break};cursor+=1
            }
            if !chain.isEmpty,cursor==tokens.count {
                active.append("modifier."+name);defer{active.removeLast()}
                return chain.reduce(element){modify($0,$1,context:environment)}
            }
            if let start=tokens.firstIndex(where:{$0.text=="modifier"}),start+1<tokens.count,tokens[start+1].text=="(" {
                var position=start+2
                if let instance=call(tokens,&position),let definition=index.modifiers[instance.name],let body=definition.members["body"] {
                    var next=SwiftImportContext(owner:context.owner,values:definition.defaults,elements:["content":element])
                    for (key,value) in instance.args {next.values[key]=resolve(value,environment)}
                    active.append("modifier."+name);defer{active.removeLast()}
                    let built=sequence(body.body,context:next)
                    if !built.isEmpty{return SwiftImportElement("Group",children:built,reference:ref)}
                }
            }
        }
        let ignored:Set<String>=["onAppear","onDisappear","onChange","onReceive","onTapGesture","onLongPressGesture","task","animation","sheet","fullScreenCover","alert","confirmationDialog","navigationDestination","toolbar","navigationTitle","navigationBarTitleDisplayMode","environment","environmentObject","preference","onPreferenceChange","accessibilityLabel","accessibilityHidden","accessibilityIdentifier","id","tag","tabItem","contentShape","buttonStyle","textFieldStyle","pickerStyle","toggleStyle","listStyle","listRowSeparator","listRowBackground","listRowInsets","scrollIndicators","scrollDismissesKeyboard","lineLimit","lineSpacing","minimumScaleFactor","fixedSize","layoutPriority","allowsTightening","truncationMode","labelsHidden","disabled","ignoresSafeArea","clipped","safeAreaInset","alignmentGuide","gesture","simultaneousGesture","highPriorityGesture","transition","matchedGeometryEffect"]
        if !ignored.contains(name){warn("尚未还原修饰器：.\(name)",ref)}
        return element
    }
}
