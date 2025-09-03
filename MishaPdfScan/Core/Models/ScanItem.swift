//
//  ScanItem.swift
//  MishaPdfScan
//
//  Created by mac air on 9/3/25.
//


// =====================================
// Core/Models/ScanItem.swift
// =====================================
import Foundation


public struct ScanItem: Identifiable, Equatable {
    public let id = UUID()
    public let url: URL
    public let name: String
    public let sizeBytes: Int
    public let createdAt: Date
}
