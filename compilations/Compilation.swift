//
//  Compilation.swift
//  compilations
//
//  Created by Dmytro Ostapchenko on 04.05.2025.
//

import Foundation
import UIKit

struct Compilation: Codable {
    let name: String
    let items: [CompilationItem]
}

struct CompilationItem: Codable {
    let id: UUID
    let name: String
    let content: CompilationItemData
}

enum CompilationItemData: Codable {
    case link(String)
    case image(Data)
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
            let value = try container.decode(Data.self, forKey: .value)
            self = .image(value)
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
        case .image(let data):
            try container.encode(DataType.image, forKey: .type)
            try container.encode(data, forKey: .value)
        case .text(let value):
            try container.encode(DataType.text, forKey: .type)
            try container.encode(value, forKey: .value)
        }
    }
}
