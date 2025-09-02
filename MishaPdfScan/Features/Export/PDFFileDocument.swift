//
//  PDFFileDocument.swift
//  MishaPdfScan
//
//  Created by mac air on 9/2/25.
//


// Features/Export/PDFFileDocument.swift
import SwiftUI
import UniformTypeIdentifiers

struct PDFFileDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.pdf] }
    var data: Data

    init(data: Data) { self.data = data }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
