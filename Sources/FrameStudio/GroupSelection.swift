import SwiftUI
import StudioCore

struct GroupSelection:Identifiable {
    let id:String
    let ids:Set<String>
    let bounds:Rect
    let canTransform:Bool
}
@MainActor extension EditorSession {
    var templateSelectionNodes:[DesignNode] {if let id=completeSelectionGroupID(in:variant){return page.nodes.filter{$0.groupID==id}};return page.nodes.filter{selection.contains($0.id)}}
    func completeSelectionGroupID(in v:Variant)->String? {
        let picked=page.nodes.filter{selection.contains($0.id)}
        guard let id=picked.first?.groupID,!id.isEmpty,picked.allSatisfy({$0.groupID==id}) else{return nil}
        let members=page.nodes.filter{$0.groupID==id && ($0.visibleVariants?.contains(v.rawValue) ?? true)}
        return !members.isEmpty && Set(members.map(\.id)).isSubset(of:selection) ? id:nil
    }
    func selectionGroup(in v:Variant,offset:Double=0)->GroupSelection? {
        guard !selection.isEmpty,!preview,v==variant else{return nil}
        let picked=page.nodes.filter{selection.contains($0.id)}
        guard let id=picked.first?.groupID,!id.isEmpty,picked.allSatisfy({$0.groupID==id}) else{return nil}
        let members=page.nodes.filter{$0.groupID==id && ($0.visibleVariants?.contains(v.rawValue) ?? true)}
        guard members.count>1,Set(members.map(\.id)).isSubset(of:selection) else{return nil}
        let frames=members.filter{!$0.hidden}.map{n->Rect in var r=n.frame(v,device:project.device);if !n.isFixed{r.y-=offset};return r}
        guard let left=frames.map(\.x).min(),let top=frames.map(\.y).min(),let right=frames.map({$0.x+$0.width}).max(),let bottom=frames.map({$0.y+$0.height}).max() else{return nil}
        return GroupSelection(id:id,ids:Set(members.map(\.id)),bounds:Rect(left,top,max(1,right-left),max(1,bottom-top)),canTransform:members.allSatisfy{!$0.locked})
    }
    func canReorder(_ move:LayerMove)->Bool {if selectionGroup(in:variant)?.canTransform==false{return false};return LayoutEngine.reordered(page.nodes,ids:selection,move:move,variant:variant) != page.nodes}
    func reorder(_ move:LayerMove) {
        guard canReorder(move) else{return}
        let ids=selection,v=variant
        change{p in guard let i=p.pages.firstIndex(where:{$0.id==pageID}) else{return};p.pages[i].nodes=LayoutEngine.reordered(p.pages[i].nodes,ids:ids,move:move,variant:v)}
    }
    func setGroupBounds(_ requested:Rect) {
        var target=requested;target.width=max(12,target.width);target.height=max(1,target.height)
        guard let group=selectionGroup(in:variant),group.canTransform else{return}
        let source=group.bounds,v=variant,ids=group.ids,device=project.device
        change{p in guard let pi=p.pages.firstIndex(where:{$0.id==pageID}) else{return}
            for i in p.pages[pi].nodes.indices where ids.contains(p.pages[pi].nodes[i].id) {
                let r=p.pages[pi].nodes[i].frame(v,device:device)
                p.pages[pi].nodes[i].frames[v.rawValue]=Self.transformed(r,from:source,to:target)
            }
        }
    }
    static func transformed(_ r:Rect,from source:Rect,to target:Rect)->Rect {
        let sx=max(1,target.width)/source.width,sy=max(1,target.height)/source.height
        return Rect(target.x+(r.x-source.x)*sx,target.y+(r.y-source.y)*sy,max(1,r.width*sx),max(1,r.height*sy))
    }
    func beginGroupTransform(resizing:Bool,offset:Double) {
        guard let group=selectionGroup(in:variant,offset:offset),group.canTransform else{return}
        dragging=true;isResizing=resizing;dragSnapshot=project;groupStart=group.bounds;groupScrollOffset=offset
        dragFrames=Dictionary(uniqueKeysWithValues:page.nodes.filter{group.ids.contains($0.id)}.map{($0.id,$0.frame(variant,device:project.device))})
    }
    func transformGroup(translation:CGSize,keepAspect:Bool=false) {
        guard dragging,let source=groupStart,let pi=project.pages.firstIndex(where:{$0.id==pageID}) else{return}
        var target=source
        if isResizing {target=LayoutEngine.resized(source,dx:translation.width/zoom,dy:translation.height/zoom,keepAspect:keepAspect)}
        else {
            target.x+=translation.width/zoom;target.y+=translation.height/zoom
            if snapping {
                let others=page.nodes.filter{!selection.contains($0.id) && $0.isVisible(in:variant)}.map{n->Rect in var r=n.frame(variant,device:project.device);if !n.isFixed{r.y-=groupScrollOffset};return r}
                let snap=LayoutEngine.snap(target,others:others,size:project.device.size(variant),threshold:5/zoom,grid:showGrid)
                target=snap.frame;guideX=snap.vertical;guideY=snap.horizontal
            }
        }
        let before=project
        for i in project.pages[pi].nodes.indices {
            let node=project.pages[pi].nodes[i]
            if var r=dragFrames[node.id] {
                if !node.isFixed{r.y-=groupScrollOffset}
                r=Self.transformed(r,from:source,to:target)
                if !node.isFixed{r.y+=groupScrollOffset}
                project.pages[pi].nodes[i].frames[variant.rawValue]=r
            }
        }
        SharedTabBar.reconcile(&project,before:before)
    }
}
