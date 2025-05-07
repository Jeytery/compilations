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
    
    private let tableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        loadSharedURL()
        loadCompilations()
        
        
        let label = UILabel()
        label.text = "share test"
        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
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
        cell.contentConfiguration = config
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let url = sharedURL else { return }

        let selected = compilations[indexPath.row]
        let updated = Compilation(name: selected.name, items: selected.items + [
            CompilationItem(id: UUID(), name: url, content: .link(url))
        ])

        compilations.removeAll { $0.name == selected.name }
        compilations.insert(updated, at: 0)
        _ = storage.save(compilations, forKey: storageKey)

        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
}
