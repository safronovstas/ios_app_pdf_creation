import UIKit
import Vision

enum OCRManager {
    static func recognizeText(from images: [UIImage], completion: @escaping (String) -> Void) {
        var fullText = ""
        let group = DispatchGroup()

        for image in images {
            guard let cgImage = image.cgImage else { continue }
            group.enter()
            let request = VNRecognizeTextRequest { request, error in
                defer { group.leave() }
                guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
                let text = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
                fullText += text + "\n"
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }

        group.notify(queue: .main) {
            completion(fullText)
        }
    }
}
