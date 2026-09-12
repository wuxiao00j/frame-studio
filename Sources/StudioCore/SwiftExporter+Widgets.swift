import Foundation

extension SwiftExporter {
    static let advancedRuntime = #"""
    struct DesignerGlyph: View {
        let symbol: String; let asset: String; let size: Double
        var body: some View {
            if !asset.isEmpty { Image(asset, bundle: .designAssets).resizable().scaledToFit().frame(width: size, height: size) }
            else if !symbol.isEmpty { Image(systemName: symbol).font(.system(size: size)).frame(width: size, height: size) }
        }
    }
    struct DesignerToggle: View {
        let title: String; let initial: Bool; let leading: Bool; let showLabel: Bool; let showIcon: Bool
        let symbol: String; let asset: String; let iconSize: Double; let gap: Double; let accent: Color
        @State private var on = false
        var body: some View { HStack(spacing: gap) {
            if leading { control }
            if showIcon { DesignerGlyph(symbol: symbol, asset: asset, size: iconSize).foregroundStyle(accent) }
            if showLabel { Text(title) }; Spacer(minLength: 0)
            if !leading { control }
        }.onAppear { on = initial } }
        var control: some View { Toggle("", isOn: $on).toggleStyle(.switch).labelsHidden().fixedSize().tint(accent) }
    }
    struct DesignerChoice: View {
        let title: String; let initial: Bool; let radio: Bool; let leading: Bool; let showLabel: Bool; let showIcon: Bool
        let symbol: String; let asset: String; let iconSize: Double; let gap: Double; let accent: Color
        @State private var on = false
        var body: some View { HStack(spacing: gap) {
            if leading { control }
            if showIcon { DesignerGlyph(symbol: symbol, asset: asset, size: iconSize) }
            if showLabel { Text(title) }; Spacer(minLength: 0)
            if !leading { control }
        }.onAppear { on = initial } }
        var control: some View { Button { on.toggle() } label: { Image(systemName: radio ? (on ? "largecircle.fill.circle" : "circle") : (on ? "checkmark.square.fill" : "square")).font(.system(size: iconSize)).foregroundStyle(accent) }.buttonStyle(.plain) }
    }
    struct DesignerProgress: View {
        let value: Double; let label: String; let style: String; let thickness: Double; let steps: Int; let track: Color; let accent: Color; let fontSize: Double
        var body: some View {
            if style == "circular" {
                ZStack {
                    Circle().stroke(track, lineWidth: thickness)
                    Circle().trim(from: 0, to: value).stroke(accent, style: StrokeStyle(lineWidth: thickness, lineCap: .round)).rotationEffect(.degrees(-90))
                    if !label.isEmpty { Text(label).font(.system(size: fontSize, weight: .medium)).lineLimit(1).minimumScaleFactor(0.5).padding(thickness + 2) }
                }.padding(thickness / 2 + 2).aspectRatio(1, contentMode: .fit).frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 4) {
                    if !label.isEmpty { Text(label).font(.system(size: min(14, fontSize))).frame(maxWidth: .infinity, alignment: .trailing) }
                    if style == "steps" {
                        HStack(spacing: 4) { ForEach(0..<steps, id: \.self) { index in Capsule().fill(Double(index) < value * Double(steps) ? accent : track) } }.frame(height: thickness)
                    } else {
                        GeometryReader { proxy in ZStack(alignment: .leading) { Capsule().fill(track); Capsule().fill(accent).frame(width: proxy.size.width * value) } }.frame(height: thickness)
                    }
                }.frame(maxWidth: .infinity, maxHeight: .infinity).padding(.horizontal, 2)
            }
        }
    }
    struct DesignerStepper: View {
        let title: String; let initial: Double; let minimum: Double; let maximum: Double; let step: Double
        @State private var value = 0.0
        var body: some View { Stepper(value: $value, in: minimum...maximum, step: step) { Text("\(title)  \(value.formatted())") }.onAppear { value = initial } }
    }
    struct DesignerTextEntry: View {
        let placeholder: String; let secure: Bool; let multiline: Bool
        @State private var text = ""
        var body: some View { Group {
            if secure { SecureField(placeholder, text: $text) }
            else { TextField(placeholder, text: $text, axis: multiline ? .vertical : .horizontal).lineLimit(multiline ? 3...10 : 1...1) }
        }.textFieldStyle(.plain) }
    }
    struct DesignerPicker: View {
        let title: String; let titles: [String]
        @State private var selected = 0
        var body: some View { Picker(title, selection: $selected) { ForEach(titles.indices, id: \.self) { Text(titles[$0]).tag($0) } } }
    }
    struct DesignerDate: View {
        let title: String; let initial: String
        @State private var date = Date()
        var body: some View { DatePicker(title, selection: $date, displayedComponents: .date).onAppear { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; date = f.date(from: initial) ?? Date(timeIntervalSince1970: 0) } }
    }
    struct DesignerRating: View {
        let initial: Double; let count: Int; let size: Double; let gap: Double; let accent: Color
        @State private var value = 0.0
        var body: some View { HStack(spacing: gap) { ForEach(1...max(1, count), id: \.self) { index in Button { value = Double(index) } label: { Image(systemName: Double(index) <= value ? "star.fill" : "star").font(.system(size: size)).foregroundStyle(accent) }.buttonStyle(.plain) } }.frame(maxWidth: .infinity, maxHeight: .infinity).onAppear { value = initial } }
    }
    """#
}
