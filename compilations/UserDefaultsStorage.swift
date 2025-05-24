//
//  UserDefaultsStorage.swift
//  compilations
//
//  Created by Dmytro Ostapchenko on 06.05.2025.
//

import Foundation

enum UserDefaultsStorageError: Error {
    case noData
    case decodeFailed
    case encodeFailed
}

final class UserDefaultsStorage {
    private let fileName = "compilations.json"

    private var fileURL: URL {
        let directory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.jeytery.compilations")!
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent(fileName)
    }

    func load() -> Result<[Compilation], UserDefaultsStorageError> {
        do {
            let data = try Data(contentsOf: fileURL)
            let result = try JSONDecoder().decode([Compilation].self, from: data)
            return .success(result)
        } catch let error as NSError where error.domain == NSCocoaErrorDomain && error.code == NSFileReadNoSuchFileError {
            return .failure(.noData)
        } catch {
            return .failure(.decodeFailed)
        }
    }

    func save(_ compilations: [Compilation]) -> UserDefaultsStorageError? {
        do {
            let data = try JSONEncoder().encode(compilations)
            try data.write(to: fileURL, options: .atomic)
            return nil
        } catch {
            return .encodeFailed
        }
    }

    func update(compilation: Compilation) {
        switch load() {
        case .success(var all):
            all.removeAll { $0.id == compilation.id }
            all.insert(compilation, at: 0)
            _ = save(all)
        case .failure:
            _ = save([compilation])
        }
    }
}
