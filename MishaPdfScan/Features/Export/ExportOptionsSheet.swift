import SwiftUI

struct ExportOptionsSheet: View {
    @Binding var options: PdfExportOptions
    let onExport: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("export.compression") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("export.quality")
                            Spacer()
                            Text(String(format: "%.0f%%", options.jpegQuality * 100))
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: Binding(
                            get: { Double(options.jpegQuality) },
                            set: { options.jpegQuality = CGFloat($0) }
                        ), in: 0.3...0.95)
                        Text("export.quality_hint").font(.caption).foregroundStyle(.secondary)
                    }
                }
                Section("export.image_size") {
                    Picker("export.long_side", selection: Binding(
                        get: { options.maxLongSide },
                        set: { options.maxLongSide = $0 }
                    )) {
                        Text("export.size.original").tag(CGFloat(0))
                        Text("export.size.1600").tag(CGFloat(1600))
                        Text("export.size.2400").tag(CGFloat(2400))
                        Text("export.size.3200").tag(CGFloat(3200))
                    }
                }
            }
            .navigationTitle("export.title")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("export.button") {
                        onExport()
                        dismiss()
                    }
                    .bold()
                }
            }
        }
    }
}

#if DEBUG
struct ExportOptionsSheet_Previews: PreviewProvider {
    struct Host: View {
        @State var options: PdfExportOptions = .default
        var body: some View { ExportOptionsSheet(options: $options) { } }
    }
    static var previews: some View { Host() }
}
#endif
