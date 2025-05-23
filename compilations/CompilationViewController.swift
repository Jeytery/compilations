//
//  CompilationViewController.swift
//  compilations
//
//  Created by Dmytro Ostapchenko on 06.05.2025.
//

import Foundation
import UIKit

final class CompilationViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private let storage = UserDefaultsStorage()
    private let storageKey: String = "group.com.jeytery.compilations"
    private var compilation: Compilation
    private var items: [CompilationItem]
    private var pictureCounter: Int
    
    private let tableView = UITableView()
    
    private let toolBarHeight: CGFloat = 100
    
    private lazy var toolbar: FakeToolBar = {
        let toolbar = FakeToolBar(blurStyle: .regular, style: .flyingCapsule)

        let label = UILabel()
        label.text = "Add content:"
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textAlignment = .left

        let buttons = UIStackView()
        buttons.axis = .horizontal
        buttons.spacing = 16
        buttons.distribution = .fillEqually
        buttons.alignment = .fill
        buttons.addArrangedSubview(makeButton(title: "Text", imageName: "text.alignleft", action: #selector(addText)))
        buttons.addArrangedSubview(makeButton(title: "Link", imageName: "link", action: #selector(addLink)))
        buttons.addArrangedSubview(makeButton(title: "Image", imageName: "photo", action: #selector(addImage)))

        let contentStack = UIStackView(arrangedSubviews: [label, buttons])
        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.alignment = .fill
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        toolbar.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: toolbar.topAnchor, constant: 12),
            contentStack.bottomAnchor.constraint(equalTo: toolbar.bottomAnchor, constant: -12),
            contentStack.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: toolbar.trailingAnchor, constant: -16),
        ])

        return toolbar
    }()
    
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "No items..."
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.isHidden = true
        return label
    }()
    
    init(compilation: Compilation?) {
        if let compilation {
            self.compilation = compilation
            self.items = compilation.items
            self.pictureCounter = compilation.items.filter {
                if case .image = $0.content { return true }
                return false
            }.count + 1
        } else {
            let new = Compilation(name: "Compilation", items: [])
            self.compilation = new
            self.items = []
            self.pictureCounter = 1
        }
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func getButton(title: String) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "ellipsis.circle")
        config.imagePadding = 6
        config.baseForegroundColor = .systemBlue
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        config.attributedTitle = AttributedString(
            title,
            attributes: .init([
                .font: UIFont.systemFont(ofSize: 16, weight: .medium)
            ])
        )
        config.titleAlignment = .center
        config.imagePlacement = .trailing
        config.baseBackgroundColor = .clear
        let buttonRef = UIButton(configuration: config)
        return buttonRef
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let titleButton = getButton(title: compilation.name)
        titleButton.addTarget(self, action: #selector(didTapTitle), for: .touchUpInside)
        navigationItem.titleView = titleButton
        view.backgroundColor = .systemBackground
        
        tableView.frame = view.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.dataSource = self
        tableView.delegate = self
        
        view.addSubview(tableView)
        view.addSubview(emptyLabel)
        setupToolbar()
        setupEmptyLabel()
        updateEmptyState()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func appDidBecomeActive() {
        switch storage.load() {
        case .success(let all):
            if let first = all.first(where: { $0.id == compilation.id }) {
                self.compilation = first
                updateEmptyState()
                self.items = compilation.items
                tableView.reloadData()
            }
        case .failure(_): break
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc private func didTapTitle() {
        let alert = UIAlertController(title: "Edit Title", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = self.compilation.name
            textField.placeholder = "Enter new title"
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { [weak self] _ in
            guard let self = self,
                  let newName = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !newName.isEmpty else { return }
            self.compilation = Compilation(name: newName, items: self.items)
            self.storage.update(compilation: compilation)
            if let titleButton = self.navigationItem.titleView as? UIButton {
                titleButton.setTitle(newName + " ", for: .normal)
            }
        }))
        present(alert, animated: true)
    }
    
    private func setupToolbar() {
        view.addSubview(toolbar)
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: toolBarHeight)
        ])
        tableView.contentInset.bottom = toolBarHeight + 20
    }
    
    private func setupEmptyLabel() {
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func updateEmptyState() {
        emptyLabel.isHidden = !items.isEmpty
    }
    
    private func makeButton(title: String, imageName: String, action: Selector) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = title
        // Use a smaller SF Symbol icon size
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        config.image = UIImage(systemName: imageName)?.withConfiguration(symbolConfig)
        config.imagePlacement = .leading
        config.imagePadding = 8
        config.baseBackgroundColor = UIColor.systemBlue.withAlphaComponent(0.15)
        config.baseForegroundColor = .systemBlue
        config.cornerStyle = .capsule
        config.titleAlignment = .center
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var newAttributes = attributes
            newAttributes.font = UIFont.boldSystemFont(ofSize: 16)
            return newAttributes
        }
        let button = UIButton(configuration: config)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
    
    @objc private func addText() {
        let alert = UIAlertController(title: "Add Text", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Enter text" }
        alert.addAction(.init(title: "Add", style: .default) { [weak self] _ in
            guard let text = alert.textFields?.first?.text, !text.isEmpty else { return }
            self?.addItem(.text(text), shouldSave: true)
        })
        alert.addAction(.init(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    @objc private func addLink() {
        let alert = UIAlertController(title: "Add Link", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Enter URL" }
        alert.addAction(.init(title: "Add", style: .default) { [weak self] _ in
            guard let link = alert.textFields?.first?.text, !link.isEmpty else { return }
            self?.addItem(.link(link), shouldSave: true)
        })
        alert.addAction(.init(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    @objc private func addImage() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }
    
    private func addItem(_ data: CompilationItemData, shouldSave: Bool) {
        let item = CompilationItem(
            id: UUID(),
            name: makeItemName(for: data),
            content: data
        )
        items.append(item)
        tableView.insertRows(at: [IndexPath(row: items.count - 1, section: 0)], with: .automatic)
        updateEmptyState()
        
        if shouldSave {
            self.compilation = self.compilation.updated(items: self.items)
            self.storage.update(compilation: self.compilation)
        }
    }
     
    private func makeItemName(for data: CompilationItemData) -> String? {
        switch data {
        case .text(let str): return str
        case .link(let url): return nil
        case .image: let name = "picture\(pictureCounter)"; pictureCounter += 1; return name
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.text = item.name
        content.textProperties.numberOfLines = 3

        if item.name == nil {
            switch item.content {
            case .link(let link):
                content.text = link
            default: break
            }
            content.textProperties.numberOfLines = 3
        }

        content.image = icon(for: item.content)
        cell.contentConfiguration = content
        cell.accessoryType = {
            switch item.content {
            case .text: return .none
            default: return .disclosureIndicator
            }
        }()
        return cell
    }
    
    private func icon(for data: CompilationItemData) -> UIImage? {
        switch data {
        case .text: return UIImage(systemName: "text.alignleft")
        case .link: return UIImage(systemName: "link")
        case .image: return UIImage(systemName: "photo")
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
        switch item.content {
        case .link(let str):
            if let url = URL(string: str) {
                UIApplication.shared.open(url)
            }
        case .image(let image):
            let vc = UIViewController()
            vc.view.backgroundColor = .black
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            imageView.frame = vc.view.bounds
            imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            vc.view.addSubview(imageView)
            present(vc, animated: true)
        case .text:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool { true }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            items.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            updateEmptyState()
            self.compilation = self.compilation.updated(items: self.items)
            storage.update(compilation: self.compilation)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        if let image = info[.originalImage] as? UIImage {
            addItem(.image(image), shouldSave: true)
        }
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let item = items[indexPath.row]
        guard case .link = item.content else { return nil }
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            guard let self else { return nil }
            let edit = UIAction(title: "Edit", image: UIImage(systemName: "pencil")) { _ in
                self.presentEditLinkController(for: indexPath)
            }
            let delete = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                self.items.remove(at: indexPath.row)
                self.compilation = self.compilation.updated(items: self.items)
                self.storage.update(compilation: self.compilation)
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
                self.updateEmptyState()
            }
            return UIMenu(title: "", children: [edit, delete])
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let item = items[indexPath.row]
        guard case .link = item.content else { return nil }
        
        let edit = UIContextualAction(style: .normal, title: "Edit") { [weak self] _, _, completion in
            self?.presentEditLinkController(for: indexPath)
            completion(true)
        }
        
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            guard let self = self else { return }
            self.items.remove(at: indexPath.row)
            self.compilation = self.compilation.updated(items: self.items)
            self.storage.update(compilation: self.compilation)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            self.updateEmptyState()
            completion(true)
        }
        
        return UISwipeActionsConfiguration(actions: [delete, edit])
    }
    
    private func presentEditLinkController(for indexPath: IndexPath) {
        let item = items[indexPath.row]
        guard case .link(let url) = item.content else { return }

        let editVC = EditLinkViewController(name: item.name ?? "", link: url) { [weak self] name, link in
            guard let self else { return }
            let updated = CompilationItem(id: item.id, name: name, content: .link(link))
            self.items[indexPath.row] = updated
            self.compilation = self.compilation.updated(items: self.items)
            self.storage.update(compilation: self.compilation)
            self.tableView.reloadRows(at: [indexPath], with: .automatic)
        }

        let nav = UINavigationController(rootViewController: editVC)
        present(nav, animated: true)
    }
}
