//import SwiftUI
//import PDFKit
//
//struct ContentView: View {
//    @State private var showingScanner = false
//    @State private var scannedImages: [UIImage] = []
//    @State private var recognizedText: String = ""
//    @State private var pdfURL: URL?
//
//    var body: some View {
//        NavigationView {
//            VStack {
//                if let url = pdfURL {
//                    PDFKitView(url: url)
//                        .frame(maxHeight: 300)
//                }
//
//                Button("Scan Document") {
//                    showingScanner = true
//                }
//                .padding()
//
//                if !recognizedText.isEmpty {
//                    ScrollView {
//                        Text(recognizedText)
//                            .padding()
//                    }
//                }
//            }
//            .navigationTitle("Doc to PDF")
//            .sheet(isPresented: $showingScanner) {
//                CameraScannerView { images in
//                    scannedImages = images
//                    pdfURL = PDFGenerator.createPDF(from: images)
//                    OCRManager.recognizeText(from: images) { text in
//                        recognizedText = text
//                    }
//                }
//            }
//        }
//    }
//}
//
//struct PDFKitView: UIViewRepresentable {
//    let url: URL
//
//    func makeUIView(context: Context) -> PDFView {
//        let view = PDFView()
//        view.autoScales = true
//        view.document = PDFDocument(url: url)
//        return view
//    }
//
//    func updateUIView(_ uiView: PDFView, context: Context) {
//        uiView.document = PDFDocument(url: url)
//    }
//}
//
//#Preview {
//    ContentView()
//}
