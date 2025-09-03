import SwiftUI

struct ExportOptionsSheet: View {
    @Binding var options: PdfExportOptions
    let onExport: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Компрессия") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Качество")
                            Spacer()
                            Text(String(format: "%.0f%%", options.jpegQuality * 100))
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: Binding(
                            get: { Double(options.jpegQuality) },
                            set: { options.jpegQuality = CGFloat($0) }
                        ), in: 0.3...0.95)
                        Text("Меньше качество → меньше размер файла").font(.caption).foregroundStyle(.secondary)
                    }
                }
                Section("Размер изображений") {
                    Picker("Длинная сторона", selection: Binding(
                        get: { options.maxLongSide },
                        set: { options.maxLongSide = $0 }
                    )) {
                        Text("Оригинал").tag(CGFloat(0))
                        Text("1600 px (мал.)").tag(CGFloat(1600))
                        Text("2400 px (сред.)").tag(CGFloat(2400))
                        Text("3200 px (крупн.)").tag(CGFloat(3200))
                    }
                }
            }
            .navigationTitle("Экспорт в PDF")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Экспорт") {
                        onExport()
                        dismiss()
                    }
                    .bold()
                }
            }
        }
    }
}
