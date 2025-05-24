//
//  Compilation.swift
//  compilations
//
//  Created by Dmytro Ostapchenko on 04.05.2025.
//

import Foundation
import UIKit
import AlertKit

struct Compilation: Codable, Equatable, Identifiable {
    internal init(name: String, items: [CompilationItem], id: UUID = UUID()) {
        self.name = name
        self.items = items
        self.id = id
    }
    
    static func == (lhs: Compilation, rhs: Compilation) -> Bool {
        return lhs.id == rhs.id
    }
    
    let id: UUID
    var name: String
    let items: [CompilationItem]
    
    func updated(items: [CompilationItem]) -> Compilation {
        Compilation(name: name, items: items, id: self.id)
    }
}

struct CompilationItem: Codable {
    let id: UUID
    let name: String?
    let content: CompilationItemData
}

enum CompilationItemData: Codable {
    case link(String)
    case image(UIImage)
    case text(String)
    
    private enum CodingKeys: String, CodingKey {
        case type
        case value
    }
    
    private enum DataType: String, Codable {
        case link
        case image
        case text
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(DataType.self, forKey: .type)
        
        switch type {
        case .link:
            let value = try container.decode(String.self, forKey: .value)
            self = .link(value)
        case .image:
            let dataString = try container.decode(String.self, forKey: .value)
            guard let data = Data(base64Encoded: dataString),
                  let image = UIImage(data: data) else {
                throw DecodingError.dataCorruptedError(forKey: .value, in: container, debugDescription: "Invalid Base64 image data")
            }
            self = .image(image)
        case .text:
            let value = try container.decode(String.self, forKey: .value)
            self = .text(value)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .link(let value):
            try container.encode(DataType.link, forKey: .type)
            try container.encode(value, forKey: .value)
        case .image(let image):
            if let data = image.pngData() {
                let dataString = data.base64EncodedString()
                try container.encode(DataType.image, forKey: .type)
                try container.encode(dataString, forKey: .value)
            } else {
                throw EncodingError.invalidValue(image, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Failed to encode UIImage as PNG"))
            }
        case .text(let value):
            try container.encode(DataType.text, forKey: .type)
            try container.encode(value, forKey: .value)
        }
    }
}
