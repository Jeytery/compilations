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
            [weak self] event in
            guard let self = self else { return }
            switch event {
            case .didTapCompilation(let compilation):
                navigationController.pushViewController(CompilationViewController(compilation: compilation), animated: true)
            default: break
            }
        }
        navigationController.pushViewController(compilationsVC, animated: false)
    }
}
