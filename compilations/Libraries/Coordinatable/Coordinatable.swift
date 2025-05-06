//
//  Coordinatable.swift
//  compilations
//
//  Created by Dmytro Ostapchenko on 06.05.2025.
//

import Foundation

class Coordinatable {
    func add(coordinatable: Coordinatable) {
        guard !childCoordinators.contains(where: {
            $0 === coordinatable
        }) else {
            return
        }
        childCoordinators.append(coordinatable)
        coordinatable.startCoordinator()
    }
    
    func remove(coordinatable: Coordinatable) {
        if childCoordinators.isEmpty { return }
        if !coordinatable.childCoordinators.isEmpty {
            coordinatable.childCoordinators
                .filter {
                    $0 !== coordinatable
                }
                .forEach {
                    coordinatable.remove(coordinatable: $0)
                }
        }
        for (index, element) in childCoordinators.enumerated() where element === coordinatable {
            childCoordinators.remove(at: index)
            break
        }
    }
    
    func startCoordinator() {}
    var childCoordinators: [Coordinatable] = []
}
