// =====================================
// Core/Models/Page.swift
// =====================================
import UIKit


public struct Page: Identifiable, Equatable {
    public let id: UUID
    public var image: UIImage
    public init(id: UUID = UUID(), image: UIImage) {
        self.id = id
        self.image = image
    }
}
