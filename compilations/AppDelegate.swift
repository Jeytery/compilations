//
//  AppDelegate.swift
//  compilations
//
//  Created by Dmytro Ostapchenko on 23.03.2025.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    private let mainCoordinator = MainCoordinator()
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = mainCoordinator.navigationController
        window?.makeKeyAndVisible()
        mainCoordinator.startCoordinator()
        return true
    }
}

