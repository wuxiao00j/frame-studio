import Foundation
import Darwin

public enum StudioError: LocalizedError {
    case invalid(String), conflict
    public var errorDescription: String? { switch self { case .invalid(let s): s; case .conflict: "项目已被另一个编辑器或 Agent 更新。已保留磁盘版本，请刷新后重试。" } }
}
public enum ProjectStore {
    public static var defaultURL: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/FrameStudio/Workspace.framestudio")
    }
    public static func load(_ url: URL) throws -> DesignProject {
        let p=try JSONDecoder().decode(DesignProject.self,from:Data(contentsOf:url)); try validate(p); return SharedTabBar.normalized(p)
    }
    public static func validate(_ p: DesignProject) throws {
        guard p.schemaVersion == 1, !p.pages.isEmpty, p.pages.count <= 200 else { throw StudioError.invalid("项目版本不支持或页面数量无效（1–200）。") }
        guard Set(p.pages.map(\.id)).count == p.pages.count else { throw StudioError.invalid("页面 ID 重复") }
        let nodes=p.pages.flatMap(\.nodes)
        let ids=[p.id]+p.pages.map(\.id)+nodes.map(\.id)+nodes.flatMap{ $0.items.map(\.id) }
        guard ids.allSatisfy({$0.range(of:"^[A-Za-z0-9_][A-Za-z0-9_-]{0,63}$",options:.regularExpression) != nil}) else {throw StudioError.invalid("ID 只能包含字母、数字、下划线和短横线，长度 1–64") }
        guard nodes.count <= 20000, Set(nodes.map(\.id)).count == nodes.count else { throw StudioError.invalid("组件过多或 ID 重复") }
        for size in [p.device.standard,p.device.outer,p.device.inner] {
            guard size.width.isFinite, size.height.isFinite, (200...3000).contains(size.width), (200...3000).contains(size.height) else { throw StudioError.invalid("画布尺寸需在 200–3000 pt 范围") }
        }
        let pages=Set(p.pages.map(\.id))
        for n in nodes {
            try n.validateRendering()
            try n.gradient?.validate()
            if let variants=n.visibleVariants, !variants.allSatisfy({Variant(rawValue:$0) != nil}){throw StudioError.invalid("组件可见布局无效")}
            if let color=n.shadowColor{try validateColor(color)}
            guard [n.blurRadius ?? 0,n.shadowX ?? 0,n.shadowY ?? 0].allSatisfy({$0.isFinite && abs($0)<=500}), (n.blurRadius ?? 0)>=0 else{throw StudioError.invalid("模糊或阴影参数无效")}
            guard n.targetPageID.isEmpty || pages.contains(n.targetPageID), n.items.allSatisfy({$0.pageID.isEmpty || pages.contains($0.pageID)}) else { throw StudioError.invalid("组件引用了不存在的页面") }
            guard Set(n.items.map(\.id)).count == n.items.count else { throw StudioError.invalid("导航项目 ID 重复") }
            for (key,r) in n.frames {
                guard Variant(rawValue:key) != nil, [r.x,r.y,r.width,r.height].allSatisfy({$0.isFinite && abs($0)<50000}), r.width>=1,r.height>=1 else { throw StudioError.invalid("组件坐标无效") }
            }
            guard [n.fontSize,n.iconSize,n.avatarSize,n.padding,n.cornerRadius,n.spacing,n.shadow,n.borderWidth,n.rotation,n.opacity,n.value].allSatisfy({$0.isFinite}), (1...300).contains(n.fontSize), (1...500).contains(n.iconSize), (1...1000).contains(n.avatarSize), (0...1).contains(n.opacity), (0...1).contains(n.value), (0...500).contains(n.padding), (0...500).contains(n.cornerRadius), (0...500).contains(n.spacing), (0...100).contains(n.shadow), (0...100).contains(n.borderWidth) else { throw StudioError.invalid("属性数值超出范围") }
            guard ["leading","trailing"].contains(n.position),["linear","circular","steps"].contains(n.progressMode),["none","percent","fraction"].contains(n.progressLabelMode),[n.current,n.total,n.number,n.minimum,n.maximum,n.step,n.progressThickness ?? 6].allSatisfy({$0.isFinite}),n.total>0,n.current>=0,n.maximum>=n.minimum,n.number>=n.minimum,n.number<=n.maximum,n.step>0,(1...50).contains(n.progressSteps ?? 5),(1...100).contains(n.progressThickness ?? 6) else{throw StudioError.invalid("组件选项或数值范围无效")}
            if let total=n.progressTotal,total<=0{throw StudioError.invalid("进度总量必须大于零")}
            if n.kind == .rating && !(1...20).contains(n.maximum){throw StudioError.invalid("评分星数为 1–20")}
            for image in [n.iconData,n.qrIconData,n.chevronIconData,n.trailingIconData]+n.items.flatMap({[$0.iconData,$0.selectedIconData]}) {
                if let image {guard image.count<30_000_000,image.isEmpty || Data(base64Encoded:image) != nil else{throw StudioError.invalid("图标图片无效或超过 20 MB")}}
            }
            if let color=n.trackColor{try validateColor(color)}
            for color in [n.fill,n.foreground,n.accent,n.borderColor] { try validateColor(color) }
            guard n.imageData.count < 30_000_000, n.imageData.isEmpty || Data(base64Encoded:n.imageData) != nil else { throw StudioError.invalid("图片无效或超过 20 MB") }
        }
        for page in p.pages {
            try validateColor(page.background)
            if let heights=page.contentHeights {guard heights.allSatisfy({Variant(rawValue:$0.key) != nil && $0.value.isFinite && (200...40000).contains($0.value)}) else{throw StudioError.invalid("页面内容高度必须在 200–40000 范围")}}
        }
        guard p.templates.count<=1000,Set(p.templates.map(\.id)).count==p.templates.count else{throw StudioError.invalid("组件模板数量或 ID 无效")}
        for t in p.templates {
            guard t.id.range(of:"^[A-Za-z0-9_][A-Za-z0-9_-]{0,63}$",options:.regularExpression) != nil,!t.name.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty,t.name.count<=200,(t.category?.count ?? 0)<=64,!t.nodes.isEmpty,t.nodes.count<=2000 else{throw StudioError.invalid("组件模板名称、分类或图层数量无效")}
            var sample=DesignProject();sample.device=p.device
            let nodes=t.nodes.map{n in var n=n;n.targetPageID="";n.items=n.items.map{item in var item=item;item.pageID="";return item};return n}
            sample.pages=[DesignPage(name:"模板检查",nodes:nodes)];try validate(sample)
        }
    }
    static func validateColor(_ color: String) throws {
        let c=color.replacingOccurrences(of:"#",with:"")
        guard [6,8].contains(c.count), UInt64(c,radix:16) != nil else { throw StudioError.invalid("颜色请使用 6 或 8 位十六进制值") }
    }
    @discardableResult public static func save(_ project: DesignProject, to url: URL, expectedRevision: Int?) throws -> DesignProject {
        try withLock(url) {
            var previous:DesignProject?
            if let expectedRevision, FileManager.default.fileExists(atPath:url.path) {
                let disk=try load(url)
                guard disk.revision == expectedRevision, disk.id == project.id else { throw StudioError.conflict }
                previous=disk
            }
            var p=project; try validate(p); SharedTabBar.reconcile(&p,before:previous); try validate(p); p.revision += 1
            let enc=JSONEncoder(); enc.outputFormatting=[.prettyPrinted,.sortedKeys,.withoutEscapingSlashes]
            try enc.encode(p).write(to:url,options:.atomic)
            return p
        }
    }
    public static func update(_ url: URL, expectedRevision: Int? = nil, mutation: (inout DesignProject) throws -> Void) throws -> DesignProject {
        try withLock(url) {
            var p=try load(url)
            if let expectedRevision, p.revision != expectedRevision { throw StudioError.conflict }
            let before=p
            try mutation(&p); try validate(p); SharedTabBar.reconcile(&p,before:before); try validate(p); p.revision += 1
            let enc=JSONEncoder(); enc.outputFormatting=[.prettyPrinted,.sortedKeys,.withoutEscapingSlashes]
            try enc.encode(p).write(to:url,options:.atomic); return p
        }
    }
    static func updateLibrary(_ url:URL,expectedRevision:Int,edit:(inout [ComponentTemplate])->Void)throws->DesignProject {
        try withLock(url) {
            var p=try PersonalComponentLibrary.load(url)
            guard p.revision==expectedRevision else{throw StudioError.conflict}
            edit(&p.templates);try validate(p);p.revision+=1
            let encoder=JSONEncoder();encoder.outputFormatting=[.prettyPrinted,.sortedKeys,.withoutEscapingSlashes]
            try encoder.encode(p).write(to:url,options:.atomic);return p
        }
    }
    private static func withLock<T>(_ url: URL, _ body: () throws -> T) throws -> T {
        try FileManager.default.createDirectory(at:url.deletingLastPathComponent(),withIntermediateDirectories:true)
        let fd=open(url.path+".lock",O_CREAT|O_RDWR,0o600)
        guard fd>=0 else { throw StudioError.invalid("无法锁定项目") }; defer { close(fd) }
        guard flock(fd,LOCK_EX)==0 else { throw StudioError.invalid("项目锁定失败") }; defer { flock(fd,LOCK_UN) }
        return try body()
    }
}
public struct SnapResult: Sendable { public var frame: Rect; public var vertical: Double?; public var horizontal: Double? }
public enum LayoutEngine {
    public static func resized(_ rect:Rect, dx:Double, dy:Double, keepAspect:Bool=false) -> Rect {
        var result=rect
        if keepAspect {
            let scale=abs(dx/max(1,rect.width)) >= abs(dy/max(1,rect.height)) ? (rect.width+dx)/rect.width : (rect.height+dy)/rect.height
            let clamped=max(max(12/rect.width,1/rect.height),scale)
            result.width=rect.width*clamped;result.height=rect.height*clamped
        }else{result.width=max(12,rect.width+dx);result.height=max(1,rect.height+dy)}
        return result
    }

    public static func snap(_ rect: Rect, others: [Rect], size: Dimensions, threshold: Double = 5, grid: Bool = false) -> SnapResult {
        var r=rect
        let xs: [Double] = [0,size.width/2,size.width] + others.flatMap { r -> [Double] in [r.x,r.midX,r.x+r.width] }
        let ys: [Double] = [0,size.height/2,size.height] + others.flatMap { r -> [Double] in [r.y,r.midY,r.y+r.height] }
        func closest(_ targets:[Double], _ edges:[Double]) -> (Double,Double)? {
            var best:(Double,Double)?
            for target in targets { for edge in edges { let delta=target-edge
                if abs(delta)<=threshold && (best == nil || abs(delta)<abs(best!.0)) {best=(delta,target)}
            }}
            return best
        }
        let dx=closest(xs,[r.x,r.midX,r.x+r.width])
        let dy=closest(ys,[r.y,r.midY,r.y+r.height])
        if let dx { r.x += dx.0 } else if grid { r.x=(r.x/8).rounded()*8 }
        if let dy { r.y += dy.0 } else if grid { r.y=(r.y/8).rounded()*8 }
        return SnapResult(frame:r,vertical:dx?.1,horizontal:dy?.1)
    }
    public static func align(_ nodes: inout [DesignNode], ids: Set<String>, variant: Variant, device: DeviceProfile, alignment: String) {
        let indices=nodes.indices.filter{ids.contains(nodes[$0].id) && !nodes[$0].locked}
        guard !indices.isEmpty else { return }
        let rs=indices.map{nodes[$0].frame(variant,device:device)}
        let size=device.size(variant)
        let left=rs.map(\.x).min()!, top=rs.map(\.y).min()!, right=rs.map{$0.x+$0.width}.max()!, bottom=rs.map{$0.y+$0.height}.max()!
        let single=indices.count==1
        for i in indices {
            var r=nodes[i].frame(variant,device:device)
            switch alignment {
            case "left": r.x=single ? 0 : left
            case "right": r.x=(single ? size.width : right)-r.width
            case "centerX": r.x=(single ? size.width/2 : (left+right)/2)-r.width/2
            case "top": r.y=single ? 0 : top
            case "bottom": r.y=(single ? size.height : bottom)-r.height
            case "centerY": r.y=(single ? size.height/2 : (top+bottom)/2)-r.height/2
            default: break
            }
            nodes[i].frames[variant.rawValue]=r
        }
        if ["distributeX","distributeY"].contains(alignment), indices.count>2 {
            let horizontal=alignment=="distributeX"
            let sorted=indices.sorted{ horizontal ? nodes[$0].frame(variant,device:device).x<nodes[$1].frame(variant,device:device).x : nodes[$0].frame(variant,device:device).y<nodes[$1].frame(variant,device:device).y }
            let occupied=rs.reduce(0){$0+(horizontal ? $1.width : $1.height)}
            let gap=((horizontal ? right-left : bottom-top)-occupied)/Double(sorted.count-1)
            var cursor=horizontal ? left : top
            for i in sorted { var r=nodes[i].frame(variant,device:device); if horizontal { r.x=cursor; cursor += r.width+gap } else { r.y=cursor; cursor += r.height+gap }; nodes[i].frames[variant.rawValue]=r }
        }
    }
}
