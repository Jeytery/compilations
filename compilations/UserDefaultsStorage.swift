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
    private let defaults = UserDefaults(suiteName: "group.com.jeytery.compilations")!
    private let key = "group.com.jeytery.compilations"
   
    func load() -> Result<[Compilation], UserDefaultsStorageError> {
        guard let data = defaults.data(forKey: key) else {
            return .failure(.noData)
        }

        do {
            let result = try JSONDecoder().decode([Compilation].self, from: data)
            return .success(result)
        } catch {
            return .failure(.decodeFailed)
        }
    }

    func save(_ compilations: [Compilation]) -> UserDefaultsStorageError? {
        do {
            let data = try JSONEncoder().encode(compilations)
            defaults.set(data, forKey: key)
            return nil
        } catch {
            return .encodeFailed
        }
    }
    
    func update(compilation: Compilation) {
        switch load() {
        case .success(let all):
            var filtered = all.filter({ $0.id != compilation.id })
            filtered.insert(compilation, at: 0)
            _ = save(filtered)
        case .failure(let error): break
        }
    }
}
