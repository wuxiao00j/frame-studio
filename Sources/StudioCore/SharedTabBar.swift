import Foundation

/// A project has one Tab configuration, materialized on pages that contain a Tab bar.
/// Node identity and assembly/source metadata belong to each page; all other fields are shared.
public enum SharedTabBar {
    public static func configuration(_ node:DesignNode)->DesignNode {
        var value=node
        value.id="";value.groupID="";value.rowGroupID=nil;value.sourceReference=""
        value.syncTabIcons=true // Decode legacy opt-outs, but never allow divergent Tab settings.
        return value
    }

    public static func normalized(_ project:DesignProject)->DesignProject {
        var result=project;reconcile(&result);return result
    }

    /// A changed existing Tab wins. Insertions inherit a surviving Tab. For legacy documents
    /// or conflicting bulk replacements, the first eligible Tab in document order wins.
    public static func reconcile(_ project:inout DesignProject,before:DesignProject?=nil) {
        let tabs=project.pages.flatMap(\.nodes).filter{$0.kind == .tabBar}
        guard let first=tabs.first else{return}
        let previous=before?.pages.flatMap(\.nodes).filter{$0.kind == .tabBar} ?? []
        // Do not trap on invalid duplicate IDs: ProjectStore validation reports those normally.
        var old:[String:DesignNode]=[:]
        for node in previous {old[node.id]=node}
        let changed=tabs.first { node in
            guard let prior=old[node.id] else{return false}
            return configuration(node) != configuration(prior)
        }
        let shared=configuration(changed ?? tabs.first{old[$0.id] != nil} ?? first)
        for pi in project.pages.indices {
            for ni in project.pages[pi].nodes.indices where project.pages[pi].nodes[ni].kind == .tabBar {
                let local=project.pages[pi].nodes[ni]
                var node=shared
                node.id=local.id;node.groupID=local.groupID
                node.rowGroupID=local.rowGroupID;node.sourceReference=local.sourceReference
                project.pages[pi].nodes[ni]=node
            }
        }
    }
}
