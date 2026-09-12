import Foundation

/// Exports are development handoffs, never signed or packaged mobile applications.
public enum ExportContract {
    public static let forbiddenExtensions:Set<String> = ["apk","aab","ipa","app","dmg","keystore","jks","p12","mobileprovision"]
    public static func validateSourceOnly(_ root:URL)throws {
        guard let files=FileManager.default.enumerator(at:root,includingPropertiesForKeys:nil) else {throw StudioError.invalid("无法检查导出目录 / Cannot inspect export directory")}
        for case let file as URL in files where forbiddenExtensions.contains(file.pathExtension.lowercased()) {
            throw StudioError.invalid("导出中不允许手机安装包或签名文件 / Mobile packages and signing files are not permitted in UI exports: \(file.lastPathComponent)")
        }
    }
    public static func writeManifest(_ project:DesignProject,format:ExportFormat,to root:URL)throws {
        try validateSourceOnly(root)
        let manifest:[String:Any] = ["exportKind":"ui-source-only","format":format.rawValue,"projectID":project.id,"projectRevision":project.revision,"pageCount":project.pages.count,"includesAssets":true,"includesProjectConfiguration":true,"includesMobileBinary":false,"businessLogicImplemented":false,"prototypeInteractionsOnly":true]
        try JSONSerialization.data(withJSONObject:manifest,options:[.prettyPrinted,.sortedKeys]).write(to:root.appendingPathComponent("export-manifest.json"))
        let notice="""
        # UI 源码交付 / UI Source Handoff

        本目录仅包含 UI 源码、资源、项目配置与设计文件，不包含 APK、AAB、IPA 或可安装手机 App。Tab、返回、开关等交互用于界面原型演示。业务逻辑、网络、登录、支付、数据存储、异常处理、测试和发布需要在项目中继续实现。

        This directory contains UI source code, assets, project configuration and the design file. It does not contain an APK, AAB, IPA or installable mobile app. Navigation, toggles and similar interactions are UI prototypes. Production state, services, authentication, payments, persistence, error handling, tests and distribution remain application development work.

        `export-manifest.json` records this source-only contract. Platform scaffold files are included to help integration; they are not a finished application.
        """
        try notice.write(to:root.appendingPathComponent("UI_HANDOFF.md"),atomically:true,encoding:.utf8)
    }
}
