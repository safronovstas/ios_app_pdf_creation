# Document Scanner to PDF

This iOS application scans paper documents, enhances their quality with on‑device machine learning, performs OCR, and exports a searchable PDF. All processing happens on the device to preserve privacy.

## Features
- Scan multi-page documents using `VNDocumentCameraViewController`.
- Enhance each page with Core Image's `CIDocumentEnhancer` filter.
- Recognize text on device via `Vision` framework.
- Generate a combined PDF using `PDFKit` and preview the result.

## Requirements
- iOS 17+
- Xcode 15+

## Running
Open `DocScanToPDF` in Xcode and run on a device. Grant camera access when prompted.

