//
//  ShareViewController.swift
//  CompilationsShareExtension
//
//  Created by Dmytro Ostapchenko on 06.05.2025.
//

import UIKit
import Social
import MobileCoreServices

final class ShareViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let storageKey = "group.com.jeytery.compilation"
    private let storage = UserDefaultsStorage()
    private var compilations: [Compilation] = []
    private var sharedURL: String?
    
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let navBarHeight: CGFloat = 56

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupNavigationEmulation()
        loadSharedURL()
        loadCompilations()
    }

    private func setupNavigationEmulation() {
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
        blur.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(blur)
        
        let label = UILabel()
        label.text = "Select a compilation to save"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        blur.contentView.addSubview(label)
        
        let closeButton = UIButton(type: .system)
        let icon = UIImage(systemName: "xmark")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 11, weight: .bold))
        closeButton.setImage(icon, for: .normal)
        closeButton.tintColor = .systemGray
        closeButton.backgroundColor = .label.withAlphaComponent(0.1)
        closeButton.layer.cornerRadius = 28 / 2
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        blur.contentView.addSubview(closeButton)

        let separator = UIView()
        separator.backgroundColor = UIColor.separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        blur.contentView.addSubview(separator)
        
        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: view.topAnchor),
            blur.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blur.heightAnchor.constraint(equalToConstant: navBarHeight),
            
            closeButton.leadingAnchor.constraint(equalTo: blur.leadingAnchor, constant: 12),
            closeButton.centerYAnchor.constraint(equalTo: blur.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 28),
            closeButton.heightAnchor.constraint(equalToConstant: 28),

            label.centerXAnchor.constraint(equalTo: blur.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: blur.centerYAnchor),

            separator.heightAnchor.constraint(equalToConstant: 0.5),
            separator.leadingAnchor.constraint(equalTo: blur.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: blur.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: blur.bottomAnchor)
        ])
    }

    @objc private func closeTapped() {
        extensionContext?.cancelRequest(withError: NSError(domain: "UserCanceled", code: 0, userInfo: nil))
    }


    private func loadSharedURL() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem else { return }
        guard let attachments = extensionItem.attachments else { return }
        for attachment in attachments {
            if attachment.hasItemConformingToTypeIdentifier(kUTTypeURL as String) {
                attachment.loadItem(forTypeIdentifier: kUTTypeURL as String, options: nil) { [weak self] (data, _) in
                    if let url = data as? URL {
                        self?.sharedURL = url.absoluteString
                        DispatchQueue.main.async {
                            self?.tableView.reloadData()
                        }
                    }
                }
                break
            }
        }
    }

    private func loadCompilations() {
        switch storage.load(forKey: storageKey, as: [Compilation].self) {
        case .success(let list):
            compilations = list
        case .failure:
            compilations = []
        }
        tableView.reloadData()
    }

    private func setupTableView() {
        view.addSubview(tableView)
        tableView.frame = view.bounds
        tableView.contentInset = .init(top: navBarHeight, left: 0, bottom: 0, right: 0)
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        compilations.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let compilation = compilations[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var config = cell.defaultContentConfiguration()
        config.text = compilation.name
        cell.accessoryType = .disclosureIndicator
        cell.contentConfiguration = config
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let url = sharedURL else { return }

        let selected = compilations[indexPath.row]
        let updated = Compilation(name: selected.name, items: selected.items + [
            CompilationItem(id: UUID(), name: nil, content: .link(url))
        ])

        compilations.removeAll { $0.name == selected.name }
        compilations.insert(updated, at: 0)
        _ = storage.save(compilations, forKey: storageKey)

        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
}
