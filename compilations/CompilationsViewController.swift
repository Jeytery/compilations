//
//  CompilationViewController.swift
//  compilations
//
//  Created by Dmytro Ostapchenko on 06.05.2025.
//

import Foundation
import UIKit
import AlertKit

final class CompilationsViewController: UIViewController {
    
    enum OutputEvent {
        case didTapCompilation(Compilation)
    }
    
    var onEvent: ((OutputEvent) -> Void)?
    
    private var compilations: [Compilation] = []
    private var filtered: [Compilation] = []
    private var isSearching = false
    
    private let storage = UserDefaultsStorage()
    
    private let tableView = UITableView()
    private let searchController = UISearchController(searchResultsController: nil)
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "No Compilations..."
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.isHidden = true
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Compilations"
        view.backgroundColor = .systemBackground
        
        navigationItem.rightBarButtonItem = .init(barButtonSystemItem: .add, target: self, action: #selector(didTapAdd))
        navigationItem.searchController = searchController
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Compilations"
        searchController.searchResultsUpdater = self
        tableView.frame = view.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.dataSource = self
        tableView.delegate = self
        navigationItem.hidesSearchBarWhenScrolling = false
        view.addSubview(tableView)
        view.addSubview(emptyLabel)
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        loadCompilations()
        updateEmptyView()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func appDidBecomeActive() {
        loadCompilations()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadCompilations()
    }

    private func loadCompilations() {
        switch storage.load() {
        case .success(let loaded):
            compilations = loaded
        case .failure:
            AlertKitAPI.present(
                title: "Error",
                subtitle: "Failed to load compilations.",
                icon: .error,
                style: .iOS17AppleMusic,
                haptic: .error
            )
        }
    }
    
    private func saveCompilations() {
        if let error = storage.save(compilations) {
            AlertKitAPI.present(
                title: "Error",
                subtitle: "Failed to save compilations.",
                icon: .error,
                style: .iOS17AppleMusic,
                haptic: .error
            )
        }
    }
    
    private func updateEmptyView() {
        emptyLabel.isHidden = !compilations.isEmpty
    }
    
    @objc private func didTapAdd() {
        let alert = UIAlertController(title: "New Compilation", message: "Enter name", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Name" }
        
        let addAction = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let self else { return }
            let name = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !name.isEmpty else {
                AlertKitAPI.present(
                    title: "Error",
                    subtitle: "Compilation name cannot be empty.",
                    icon: .error,
                    style: .iOS17AppleMusic,
                    haptic: .error
                )
                return
            }
            let newCompilation = Compilation(name: name, items: [])
            self.compilations.insert(newCompilation, at: 0)
            self.saveCompilations()
            self.tableView.insertRows(at: [.init(row: 0, section: 0)], with: .automatic)
            self.updateEmptyView()
            AlertKitAPI.present(
                title: "Added!",
                subtitle: "\(name) has been added",
                icon: .done,
                style: .iOS17AppleMusic,
                haptic: .success
            )
        }
        
        alert.addAction(addAction)
        alert.addAction(.init(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func editItem(at indexPath: IndexPath) {
        let model = isSearching ? filtered[indexPath.row] : compilations[indexPath.row]
        
        let alert = UIAlertController(title: "Edit Compilation", message: "Change name", preferredStyle: .alert)
        alert.addTextField { $0.text = model.name }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self,
                  let newName = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !newName.isEmpty else { return }
            
            if let i = self.compilations.firstIndex(where: { $0.id == model.id }) {
                self.compilations[i].name = newName
                self.saveCompilations()
                self.tableView.reloadRows(at: [IndexPath(row: i, section: 0)], with: .automatic)
            }
        }
        
        alert.addAction(saveAction)
        alert.addAction(.init(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

extension CompilationsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        isSearching ? filtered.count : compilations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = isSearching ? filtered[indexPath.row] : compilations[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var config = cell.defaultContentConfiguration()
        config.text = model.name
        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = isSearching ? filtered[indexPath.row] : compilations[indexPath.row]
        onEvent?(.didTapCompilation(model))
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool { true }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        let index = indexPath.row
        var targetArray = isSearching ? filtered : compilations
        let deleted = targetArray.remove(at: index)
        
        if !isSearching {
            compilations.removeAll { $0.id == deleted.id }
            saveCompilations()
        }
        
        tableView.deleteRows(at: [indexPath], with: .automatic)
        updateEmptyView()
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            let edit = UIAction(title: "Edit", image: UIImage(systemName: "pencil")) { _ in
                self?.editItem(at: indexPath)
            }
            return UIMenu(title: "", children: [edit])
        }
    }
}

extension CompilationsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let text = searchController.searchBar.text ?? ""
        isSearching = !text.isEmpty
        filtered = compilations.filter { $0.name.lowercased().contains(text.lowercased()) }
        tableView.reloadData()
    }
}
