//
//  PageRow.swift
//  Misha Pdf Scan
//
//  Created by mac air on 9/1/25.
//
import SwiftUI


/// Отдельная ячейка — проще для компилятора
struct PageRow: View {
    @Binding var page: ScannedPage
    let index: Int
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Image(uiImage: page.image)
                .resizable()
                .scaledToFill()
                .frame(width: 64, height: 96)
                .clipped()
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))

            Text("Page \(index)")
            Spacer()

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
            }
        }
        // ✅ Поворот на 90° / -90° прямо из свайпов
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                rotate(90)
            } label: {
                Label("Rotate 90°", systemImage: "rotate.right")
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button {
                rotate(-90)
            } label: {
                Label("Rotate -90°", systemImage: "rotate.left")
            }
        }
        // (опционально) Контекстное меню долгим тапом
        .contextMenu {
            Button { rotate(90) }  label: { Label("Rotate 90°",  systemImage: "rotate.right") }
            Button { rotate(-90) } label: { Label("Rotate -90°", systemImage: "rotate.left")  }
        }
    }

    private func rotate(_ degrees: CGFloat) {
        if let r = page.image.rotated(byDegrees: degrees) {
            page.image = r
        }
    }
}
