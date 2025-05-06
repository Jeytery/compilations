//
//  UserDefaultsStorage.swift
//  compilations
//
//  Created by Dmytro Ostapchenko on 06.05.2025.
//

import Foundation

enum UserDefaultsStorageError: Error {
    case encodingFailed
    case decodingFailed
    case noData
}

final class UserDefaultsStorage {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func save<T: Codable>(_ value: T, forKey key: String) -> UserDefaultsStorageError? {
        do {
            let data = try JSONEncoder().encode(value)
            defaults.set(data, forKey: key)
            return nil
        } catch {
            return .encodingFailed
        }
    }

    func load<T: Codable>(forKey key: String, as type: T.Type) -> Result<T, UserDefaultsStorageError> {
        guard let data = defaults.data(forKey: key) else {
            return .failure(.noData)
        }
        do {
            let value = try JSONDecoder().decode(T.self, from: data)
            return .success(value)
        } catch {
            return .failure(.decodingFailed)
        }
    }
}
