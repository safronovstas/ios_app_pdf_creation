// Features/Export/PDFDocTransferable.swift
import SwiftUI
import UniformTypeIdentifiers

struct PDFDoc: Transferable {
    let data: Data
    let filename: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .pdf) { $0.data }
            .suggestedFileName { $0.filename }
    }
}
