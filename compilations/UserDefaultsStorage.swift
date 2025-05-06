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
    
    func update<T: Codable & Identifiable & Equatable>(object: T, inArrayForKey key: String) -> UserDefaultsStorageError? where T.ID: Equatable {
        switch load(forKey: key, as: [T].self) {
        case .success(var array):
            array.removeAll { $0.id == object.id }
            array.insert(object, at: 0)
            return save(array, forKey: key)
        case .failure(let error):
            if error == .noData {
                return save([object], forKey: key)
            } else {
                return error
            }
        }
    }
}
