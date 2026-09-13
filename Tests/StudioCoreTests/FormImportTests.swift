import XCTest
@testable import StudioCore

final class FormImportTests:XCTestCase {
    func inspect(_ text:String)throws->ImportReport {
        let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true);defer{try? FileManager.default.removeItem(at:root)}
        try text.write(to:root.appendingPathComponent("Form.swift"),atomically:true,encoding:.utf8)
        return try SwiftImporter.inspect(root)
    }
    let fixture=#"""
    import SwiftUI
    enum Category:String,CaseIterable {
        case birthday="生日"
        case countdown="倒计时"
        case custom="纪念日"
        var label:String {switch self {case .birthday:return "生日";case .countdown:return "倒计时";case .custom:return "纪念日"}}
    }
    enum OtherCadence:String {case yearly}
    enum Cadence:String {case once
        case yearly
        var label:String {switch self {case .once:return "只记住这一次";case .yearly:return "每年提醒"}}
    }
    struct DemoView:View {
        @State var category:Category
        @State var cadence:Cadence
        @State var title:String
        @State var hasDate:Bool
        let categories:[Category]
        init(existing:Item?=nil,categories:[Category]=Category.allCases) {
            self.categories=categories
            _category=State(initialValue:existing?.category ?? .custom)
            _cadence=State(initialValue:existing?.cadence ?? .yearly)
            _title=State(initialValue:existing?.title ?? "")
            _hasDate=State(initialValue:existing?.date != nil)
        }
        var isCountdown:Bool {category == .countdown}
        var canSave:Bool {!title.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty}
        var body:some View {Form {
            Section("信息") {
                TextField("名称",text:$title)
                Picker("类型",selection:$category) {ForEach(categories,id:\.rawValue){item in Text(item.label).tag(item)}}
                HStack {ForEach([Cadence.once,.yearly],id:\.rawValue){item in Text(item.label).foregroundStyle(cadence == item && !isCountdown ? Color.red:Color.black)}}
                if isCountdown {Text("倒计时专用提示")}
                if canSave {Text("可以保存")}
                Toggle("补日期",isOn:$hasDate)
                if hasDate {Text("可选日期")}
            }
        }}
    }
    """#
    func testEnumLabelsAndStateInitializersDoNotCreateFalseBranches()throws {
        let report=try inspect(fixture),nodes=report.pages[0].nodes
        let picker=try XCTUnwrap(nodes.first{$0.kind == .selectField})
        XCTAssertEqual(picker.items.map(\.title),["生日","倒计时","纪念日"])
        XCTAssertEqual(picker.selectedIndex,2)
        XCTAssertEqual(picker.controlStyle,"formRow")
        XCTAssertTrue(nodes.contains{$0.text=="只记住这一次"})
        XCTAssertEqual(nodes.first{$0.text=="每年提醒"}?.foreground,"FF3B30")
        XCTAssertFalse(nodes.contains{$0.text=="倒计时专用提示" || $0.text=="可以保存"})
        XCTAssertFalse(nodes.contains{$0.text=="可选日期"})
        XCTAssertEqual(nodes.first{$0.kind == .toggle}?.isOn,false)
        XCTAssertFalse(nodes.contains{$0.text.contains("〈item")})
    }
    func testComparisonTextRemainsData()throws {
        let report=try inspect("struct DemoView:View {var body:some View {Text(\"a == b && c != d\")}}")
        XCTAssertEqual(report.pages[0].nodes.first?.text,"a == b && c != d")
    }
    func testHiddenNavigationDoesNotAddAHeaderOrShiftContent()throws {
        let report=try inspect("""
        struct DemoView:View {var body:some View {NavigationStack {
            Text("Content").navigationTitle("Hidden title").toolbar(.hidden,for:.navigationBar)
        }}}
        """)
        XCTAssertEqual(report.pages[0].nodes.map(\.text),["Content"])
        XCTAssertEqual(report.pages[0].nodes[0].frames["standardPortrait"]?.y,52)
    }
    func testFormGroupsAndToolbarRemainEditableAndCorrectlyPositioned()throws {
        let report=try inspect("""
        import SwiftUI
        struct DemoView:View {var body:some View {NavigationStack {
            Form {Section("信息") {TextField("名称",text:.constant(""));TextField("备注",text:.constant(""),axis:.vertical)}}
                .background(Color.white).navigationTitle("新增记录")
                .toolbar {ToolbarItem(placement:.topBarLeading){Button("取消") {dismiss()}}
                    ToolbarItem(placement:.topBarTrailing){Button("保存") {}.disabled(true)}}
        }}}
        """)
        let nodes=report.pages[0].nodes
        XCTAssertEqual(nodes.first{$0.text=="新增记录"}?.frames["standardPortrait"]?.y,52)
        XCTAssertTrue(try XCTUnwrap(nodes.first{$0.text=="新增记录"}).isFixed)
        XCTAssertEqual(nodes.first{$0.text=="保存"}?.isEnabled,false)
        XCTAssertEqual(nodes.first{$0.text=="取消"}?.navigationAction,"back")
        XCTAssertEqual(nodes.first{$0.text=="备注"}?.kind,.textArea)
        XCTAssertEqual(nodes.first{$0.text=="名称"}?.controlStyle,"formRow")
        XCTAssertGreaterThan(try XCTUnwrap(nodes.first{$0.text=="名称"}?.frames["standardPortrait"]?.y),96)
        XCTAssertTrue(nodes.contains{$0.name=="表单分组背景" && $0.cornerRadius==24})
        XCTAssertTrue(nodes.contains{$0.kind == .divider})
        try ProjectStore.validate(report.project(named:"Form fixture"))
    }
}
