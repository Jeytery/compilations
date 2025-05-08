//
//  EditLinkViewController.swift
//  compilations
//
//  Created by Dmytro Ostapchenko on 08.05.2025.
//

import Foundation
import UIKit
import AlertKit

final class EditLinkViewController: UIViewController {
    
    private let existingName: String
    private let existingLink: String
    private let onSave: (String, String) -> Void
    
    init(name: String, link: String, onSave: @escaping (String, String) -> Void) {
        self.existingName = name
        self.existingLink = link
        self.onSave = onSave
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let nameField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Name"
        tf.borderStyle = .roundedRect
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let linkField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Link"
        tf.borderStyle = .roundedRect
        tf.keyboardType = .URL
        tf.autocapitalizationType = .none
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Edit Link"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .close, primaryAction: UIAction(handler: { [weak self] _ in
            self?.dismiss(animated: true)
        }), menu: nil)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneTapped))
        
        nameField.text = existingName
        linkField.text = existingLink
        
        let stack = UIStackView(arrangedSubviews: [nameField, linkField])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    @objc private func doneTapped() {
        guard let name = nameField.text,
              let link = linkField.text
        else { return }
        if link.isEmpty {
            AlertKitAPI.present(title: "Error", subtitle: "URL couldn't be empty", icon: .error, style: .iOS16AppleMusic, haptic: .error)
            view.endEditing(true)
            return
        }
        onSave(name, link)
        dismiss(animated: true)
    }
}
