//
//  ShareViewController.swift
//  CompilationsShareExtension
//
//  Created by Dmytro Ostapchenko on 06.05.2025.
//

import UIKit
import Social
import MobileCoreServices
import Vision

fileprivate func classifyImage(_ image: UIImage, completion: @escaping (String?) -> Void) {
    guard let cgImage = image.cgImage else {
        completion(nil)
        return
    }

    let request = VNClassifyImageRequest { request, error in
        if let results = request.results as? [VNClassificationObservation],
           let best = results.first {
            completion("\(best.identifier)")
        } else {
            completion(nil)
        }
    }

    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    DispatchQueue.global(qos: .userInitiated).async {
        do {
            try handler.perform([request])
        } catch {
            completion(nil)
        }
    }
}

final class ShareViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let storageKey = "group.com.jeytery.compilations"
    private let storage = UserDefaultsStorage()
    private var compilations: [Compilation] = []
    private var sharedURL: String?
    private var sharedImage: UIImage?
    private var sharedText: String?
    
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
            if attachment.hasItemConformingToTypeIdentifier(kUTTypeImage as String) {
                attachment.loadItem(forTypeIdentifier: kUTTypeImage as String, options: nil) { [weak self] (data, _) in
                    if let url = data as? URL, let imageData = try? Data(contentsOf: url), let image = UIImage(data: imageData) {
                        self?.sharedImage = image
                        DispatchQueue.main.async {
                            self?.tableView.reloadData()
                        }
                    } else if let image = data as? UIImage {
                        self?.sharedImage = image
                        DispatchQueue.main.async {
                            self?.tableView.reloadData()
                        }
                    }
                }
            } else if attachment.hasItemConformingToTypeIdentifier(kUTTypeURL as String) {
                attachment.loadItem(forTypeIdentifier: kUTTypeURL as String, options: nil) { [weak self] (data, _) in
                    if let url = data as? URL {
                        self?.sharedURL = url.absoluteString
                        DispatchQueue.main.async {
                            self?.tableView.reloadData()
                        }
                    }
                }
            } else if attachment.hasItemConformingToTypeIdentifier(kUTTypeText as String) {
                attachment.loadItem(forTypeIdentifier: kUTTypeText as String, options: nil) { [weak self] (data, _) in
                    if let text = data as? String {
                        self?.sharedText = text
                        DispatchQueue.main.async {
                            self?.tableView.reloadData()
                        }
                    }
                }
            }
        }
    }

    private func loadCompilations() {
        switch storage.load() {
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
        let selected = compilations[indexPath.row]
        var updatedItems = selected.items
        if let image = sharedImage {
            classifyImage(image, completion: { [weak self] text in
                guard let self = self else { return }
                updatedItems.append(CompilationItem(id: UUID(), name: text ?? "Unnamed picture", content: .image(image)))
                let updated = selected.updated(items: updatedItems)
                storage.update(compilation: updated)
                extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            })
            return
        }

        if let url = sharedURL {
            updatedItems.append(CompilationItem(id: UUID(), name: nil, content: .link(url)))
        }
        
        if let text = sharedText {
            updatedItems.append(CompilationItem(id: UUID(), name: text, content: .text(text)))
        }

        let updated = selected.updated(items: updatedItems)

        storage.update(compilation: updated)

        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
}
