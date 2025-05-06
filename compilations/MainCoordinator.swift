//
//  MainCoordinator.swift
//  compilations
//
//  Created by Dmytro Ostapchenko on 06.05.2025.
//

import Foundation
import UIKit

final class MainCoordinator: Coordinatable {
    var navigationController: UINavigationController = UINavigationController()
    
    override func startCoordinator() {
        let compilationsVC = CompilationsViewController()
        compilationsVC.onEvent = {
            event in
        }
        navigationController.pushViewController(compilationsVC, animated: false)
    }
}
