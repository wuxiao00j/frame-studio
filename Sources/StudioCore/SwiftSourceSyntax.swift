import Foundation

// A bounded, non-executing Swift lexer. Braces in comments and interpolated strings
// cannot escape their source expression. This is intentionally not a Swift compiler.
struct SwiftToken:Equatable {
    var text:String
    var line:Int
    var string=false
}
enum SwiftSourceSyntax {
    static func tokens(_ source:String)->[SwiftToken] {
        let chars=Array(source);var i=0,line=1,result:[SwiftToken]=[]
        func at(_ offset:Int=0)->Character {i+offset<chars.count ? chars[i+offset]:"\0"}
        func advance(){if at()=="\n"{line+=1};i+=1}
        func quoted() {
            let triple=at()=="\"" && at(1)=="\"" && at(2)=="\""
            let count=triple ? 3:1
            for _ in 0..<count{advance()}
            while i<chars.count {
                if at()=="\\" {
                    advance()
                    if at()=="(" {
                        advance();var depth=1
                        while i<chars.count && depth>0 {
                            if at()=="\""{quoted();continue}
                            if at()=="("{depth+=1};if at()==")"{depth-=1};advance()
                        }
                    }else if i<chars.count{advance()}
                }else if at()=="\"" && (!triple || (at(1)=="\"" && at(2)=="\"")) {
                    for _ in 0..<count{advance()};return
                }else{advance()}
            }
        }
        while i<chars.count {
            let c=at(),start=i,firstLine=line
            if c=="\n" {result.append(.init(text:"\n",line:line));advance();continue}
            if c.isWhitespace {advance();continue}
            if c=="/" && at(1)=="/" {while i<chars.count && at() != "\n"{advance()};continue}
            if c=="/" && at(1)=="*" {
                advance();advance();var depth=1
                while i<chars.count && depth>0 {
                    if at()=="/" && at(1)=="*"{depth+=1;advance();advance()}
                    else if at()=="*" && at(1)=="/"{depth-=1;advance();advance()}else{advance()}
                };continue
            }
            if c=="\"" {quoted();result.append(.init(text:String(chars[start..<i]),line:firstLine,string:true));continue}
            if c.isLetter || c=="_" || c=="$" {
                advance();while i<chars.count && (at().isLetter || at().isNumber || at()=="_" || at()=="$"){advance()}
            }else if c.isNumber {
                advance();while i<chars.count && (at().isNumber || (at()=="." && at(1).isNumber)){advance()}
            }else {advance()}
            result.append(.init(text:String(chars[start..<i]),line:firstLine))
        }
        return result
    }
    static func compact(_ t:[SwiftToken])->[SwiftToken]{t.filter{$0.text != "\n"}}
    static func text(_ t:[SwiftToken])->String{compact(t).map(\.text).joined()}
    static func end(_ t:[SwiftToken],_ start:Int)->Int {
        guard t.indices.contains(start),let closing=["(":")","[":"]","{":"}"][t[start].text] else{return start}
        var i=start+1
        while i<t.count {if t[i].text==closing{return i};if ["(","[","{"].contains(t[i].text){i=end(t,i)};i+=1}
        return t.count
    }
    static func split(_ t:[SwiftToken],separator:String=",")->[[SwiftToken]] {
        var result:[[SwiftToken]]=[],start=0,i=0
        while i<t.count {
            if ["(","[","{"].contains(t[i].text){i=end(t,i)}
            else if t[i].text==separator {result.append(Array(t[start..<i]));start=i+1};i+=1
        }
        if start<t.count {result.append(Array(t[start...]))};return result
    }
    static func arguments(_ tokens:[SwiftToken])->[String:[SwiftToken]] {
        var args:[String:[SwiftToken]]=[:],index=0
        for raw in split(tokens) {
            let part=compact(raw);guard !part.isEmpty else{continue}
            if part.count>2,part[1].text==":" {args[part[0].text]=Array(part.dropFirst(2))}
            else {args["$\(index)"]=part;index+=1}
        };return args
    }
    static func literal(_ token:SwiftToken)->String? {
        guard token.string else{return nil}
        let n=token.text.hasPrefix("\"\"\"") ? 3:1
        var s=String(token.text.dropFirst(n).dropLast(n))
        // Interpolation is display data, never code to execute.
        let chars=Array(s);var output="",i=0
        while i<chars.count {
            if chars[i]=="\\",i+1<chars.count,chars[i+1]=="(" {
                i+=2;var depth=1
                while i<chars.count && depth>0 {if chars[i]=="("{depth+=1};if chars[i]==")"{depth-=1};i+=1}
                output+="…"
            }else{output.append(chars[i]);i+=1}
        }
        s=output.replacingOccurrences(of:"\\n",with:"\n").replacingOccurrences(of:"\\\"",with:"\"").replacingOccurrences(of:"\\\\",with:"\\")
        return s
    }
}

struct SwiftViewMember {
    var body:[SwiftToken]
    var parameters:[String]=[]
    var defaults:[String:[SwiftToken]]=[:]
}
struct SwiftViewDefinition {
    var name:String
    var file:String
    var line:Int
    var members:[String:SwiftViewMember]=[:]
    var defaults:[String:[SwiftToken]]=[:]
    var slots:[String]=[]
    var collections:[String:String]=[:]
}

struct SwiftViewIndex {
    var views:[String:SwiftViewDefinition]=[:]
    var modifiers:[String:SwiftViewDefinition]=[:]
    var layouts=Set<String>()
    var viewExtensions=SwiftViewDefinition(name:"View",file:"",line:1)
    var constants:[String:[SwiftToken]]=[:]
    var files:[String]=[]
    init(files:[URL]) {
        var units:[(String,[SwiftToken])]=[]
        for file in files {
            guard let data=try? Data(contentsOf:file),data.count<2_000_000,let source=String(data:data,encoding:.utf8) else{continue}
            units.append((file.path,SwiftSourceSyntax.tokens(source)));self.files.append(file.path)
        }
        for (file,tokens) in units {scan(tokens,file:file,path:[],extensions:false)}
        for (file,tokens) in units {scan(tokens,file:file,path:[],extensions:true)}
    }
    mutating func scan(_ t:[SwiftToken],file:String,path:[String],extensions:Bool) {
        var i=0
        while i<t.count {
            if ["struct","enum","class","extension"].contains(t[i].text),i+1<t.count {
                let isExtension=t[i].text=="extension",name=t[i+1].text
                guard let open=(i+2..<t.count).first(where:{t[$0].text=="{"}) else{break}
                let close=SwiftSourceSyntax.end(t,open),header=Array(t[i..<open]),body=Array(t[(open+1)..<close])
                if isExtension && extensions,name=="View" {readMembers(body,into:&viewExtensions)}
                else if isExtension && extensions, var view=views[name] {readMembers(body,into:&view);views[name]=view}
                else if !isExtension && !extensions {
                    var view=SwiftViewDefinition(name:name,file:file,line:t[i].line)
                    readMembers(body,into:&view)
                    if header.contains(where:{$0.text=="View"}),view.members["body"] != nil {views[name]=view}
                    if header.contains(where:{$0.text=="ViewModifier"}),view.members["body"] != nil {modifiers[name]=view}
                    if header.contains(where:{$0.text=="Layout"}){layouts.insert(name)}
                    scan(body,file:file,path:path+[name],extensions:false)
                }
                i=close+1;continue
            }
            if !extensions,t[i].text=="static",i+2<t.count,["let","var"].contains(t[i+1].text) {
                let name=t[i+2].text;var j=i+3
                while j<t.count && !["=","{","\n"].contains(t[j].text){j+=1}
                if j<t.count,t[j].text=="=" {
                    let end=statementEnd(t,j+1);constants[(path+[name]).joined(separator:".")]=Array(t[(j+1)..<end]);i=end;continue
                }
                if j<t.count,t[j].text=="{" {
                    let end=SwiftSourceSyntax.end(t,j);constants[(path+[name]).joined(separator:".")]=Array(t[(j+1)..<end]);i=end+1;continue
                }
            }
            if ["(","[","{"].contains(t[i].text){i=SwiftSourceSyntax.end(t,i)};i+=1
        }
    }
    func statementEnd(_ t:[SwiftToken],_ start:Int)->Int {
        var i=start
        while i<t.count {if ["\n",";"].contains(t[i].text){return i};if ["(","[","{"].contains(t[i].text){i=SwiftSourceSyntax.end(t,i)};i+=1};return t.count
    }
    func parameters(_ t:[SwiftToken])->([String],[String:[SwiftToken]]) {
        var names:[String]=[],defaults:[String:[SwiftToken]]=[:]
        for raw in SwiftSourceSyntax.split(t) {
            let part=SwiftSourceSyntax.compact(raw)
            guard let colon=part.firstIndex(where:{$0.text==":"}),colon>0 else{continue}
            let name=part[colon-1].text;names.append(name)
            if let eq=part.firstIndex(where:{$0.text=="="}){defaults[name]=Array(part.dropFirst(eq+1))}
        };return(names,defaults)
    }
    func readMembers(_ t:[SwiftToken],into view:inout SwiftViewDefinition) {
        var i=0
        while i<t.count {
            let keyword=t[i].text
            if ["var","let","func","init"].contains(keyword),i+1<t.count {
                let name=keyword=="init" ? "init":t[i+1].text;var j=i+(keyword=="init" ? 1:2)
                var params:[String]=[],defaults:[String:[SwiftToken]]=[:]
                if ["func","init"].contains(keyword) {
                    while j<t.count && t[j].text != "(" && t[j].text != "{"{j+=1}
                    if j<t.count,t[j].text=="(" {let end=SwiftSourceSyntax.end(t,j);(params,defaults)=parameters(Array(t[(j+1)..<end]));j=min(end+1,t.count)}
                }
                let typeStart=j
                while j<t.count && !(["func","init"].contains(keyword) ? ["{","="].contains(t[j].text) : ["{","=","\n",";"].contains(t[j].text)){j+=1}
                if j<t.count,t[j].text=="{" {
                    let end=SwiftSourceSyntax.end(t,j),type=SwiftSourceSyntax.text(Array(t[typeStart..<j]))
                    if name=="body" || type.contains("someView") || type.contains("anyView") {
                        view.members[name]=SwiftViewMember(body:Array(t[(j+1)..<end]),parameters:params,defaults:defaults)
                    }
                    else if type.hasPrefix(":["),type.hasSuffix("]") {
                        view.collections[name]=String(type.dropFirst(2).dropLast())
                        let value=SwiftSourceSyntax.compact(Array(t[(j+1)..<end])).filter{$0.text != "return"}
                        if !value.contains(where:{["if","switch","for","var","let"].contains($0.text)}){view.defaults[name]=value}
                    }
                    if keyword=="init" {
                        view.defaults.merge(defaults){old,_ in old}
                        for p in params where (SwiftSourceSyntax.text(Array(t[i..<j])).contains(p+":()->") || SwiftSourceSyntax.text(Array(t[i..<j])).contains(p+":(")) && !view.slots.contains(p) {view.slots.append(p)}
                    }
                    i=end+1;continue
                }
                if j<t.count,t[j].text=="=" {let end=statementEnd(t,j+1);view.defaults[name]=Array(t[(j+1)..<end]);i=end;continue}
                let type=SwiftSourceSyntax.text(Array(t[typeStart..<min(j,t.count)]))
                if type.contains("Content") || type.contains("Accessory") || type.contains("HeaderAction") {if !view.slots.contains(name){view.slots.append(name)}}
                // Keep unset strings explicit so reusable templates remain editable.
                if type==":String" {view.defaults[name]=[SwiftToken(text:"\"〈\(name)〉\"",line:t[i].line,string:true)]}
                i=max(j,i+1);continue
            }
            if ["(","[","{"].contains(keyword){i=SwiftSourceSyntax.end(t,i)};i+=1
        }
    }
}
