//
//  CompactHomeViewController.swift
//  Back App iOS
//
//  Created by Moritz Schaub on 26.06.20.
//  Copyright © 2020 Moritz Schaub. All rights reserved.
//

import SwiftUI
import MobileCoreServices

class CompactHomeViewController: UITableViewController {
    
    typealias DataSource = HomeDataSource
    typealias Snapshot = NSDiffableDataSourceSnapshot<HomeSection,TextItem>

    private lazy var dataSource = makeDataSource()
    private var recipeStore: RecipeStore
    private lazy var documentPicker = UIDocumentPickerViewController(
        documentTypes: [kUTTypeJSON as String], in: .open
    )
    
    init(recipeStore: RecipeStore) {
        self.recipeStore = recipeStore
        super.init(style: .insetGrouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError(Strings.init_coder_not_implemented)
    }
    
    override func viewDidLoad() {
        registerCells()
        configureNavigationBar()
        self.tableView.separatorStyle = .none
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        dataSource.update(animated: false)
    }

}


import BakingRecipe

private extension CompactHomeViewController {
    private func registerCells() {
        tableView.register(RecipeTableViewCell.self, forCellReuseIdentifier: Strings.recipeCell)
        tableView.register(DetailTableViewCell.self, forCellReuseIdentifier: Strings.detailCell)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Strings.plainCell)
    }
    
    private func configureNavigationBar() {
        title = Strings.appTitle
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.leftBarButtonItem = editButtonItem
        navigationItem.rightBarButtonItem = .init(barButtonSystemItem: .add, target: self, action: #selector(presentAddRecipePopover))
    }
    
    @objc private func presentAddRecipePopover(_ sender: UIBarButtonItem) {
        let recipe = Recipe(name: "", brotValues: [])
        let vc = RecipeDetailViewController(recipe: recipe, creating: true) { recipe in
            self.recipeStore.save(recipe: recipe)
            DispatchQueue.main.async {
                self.dataSource.update()
            }
        }
        let nv = UINavigationController(rootViewController: vc)
        present(nv, animated: true)
       }
}

private extension CompactHomeViewController {
    private func makeDataSource() -> DataSource {
        HomeDataSource(recipeStore: recipeStore, tableView: tableView)
    }
}

extension CompactHomeViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return}
        
        if let recipeItem = item as? RecipeItem {
            navigateToRecipe(recipeItem: recipeItem)
        } else if item.text == Strings.roomTemperature {
            navigateToRoomTempPicker(item: item)
        } else if item.text == Strings.importFile {
            openImportFilePopover()
        } else if item.text == Strings.exportAll {
            openExportAllShareSheet()
        } else if item.text == Strings.about {
            navigateToAboutView()
        }
    }
    
    private func navigateToRecipe(recipeItem: RecipeItem) {
        if let recipe = recipeStore.recipes.first(where: { $0.id == recipeItem.id}) {
            let vc = RecipeDetailViewController(recipe: recipe, creating: false) { recipe in
                self.recipeStore.update(recipe: recipe)
                DispatchQueue.main.async {
                     self.dataSource.update(animated: false)
                }
            }
            splitViewController?.showDetailViewController(UINavigationController(rootViewController: vc), sender: self)
        }
    }
    
    private func navigateToRoomTempPicker(item: TextItem) {
        let vc = RoomTempTableViewController(style: .insetGrouped)
        
        vc.recipeStore = recipeStore
        vc.updateTemp = { [self] temp in
            self.recipeStore.roomTemperature = temp
            self.updateSettings()
        }
        splitViewController?.showDetailViewController(UINavigationController(rootViewController: vc), sender: self)
    }
    
    private func updateSettings() {
        DispatchQueue.global(qos: .background).async {
            var snapshot = self.dataSource.snapshot()
            snapshot.deleteSections([.settings])
            snapshot.appendSections([.settings])
            snapshot.appendItems(self.recipeStore.settingsItems, toSection: .settings)
            DispatchQueue.main.async {
                self.dataSource.apply(snapshot, animatingDifferences: false)
            }
        }
    }
    
    private func openImportFilePopover() {
        self.documentPicker.delegate = self
        // Present the document picker.
        self.present(documentPicker, animated: true, completion: deselectRow)
    }
    
    private func openExportAllShareSheet() {
        present(UIActivityViewController(activityItems: [recipeStore.exportToUrl()], applicationActivities: nil),animated: true, completion: deselectRow)
    }
    
    private func navigateToAboutView() {
        let hostingController = UIHostingController(rootView: AboutView())
        splitViewController?.showDetailViewController(UINavigationController(rootViewController: hostingController), sender: self)
    }
    
    private func deselectRow() {
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
}

extension CompactHomeViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        for url in urls {
            recipeStore.open(url)
        }
        
        let alert = UIAlertController(title: recipeStore.inputAlertTitle, message: recipeStore.inputAlertMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Strings.Alert_ActionOk, style: .default, handler: { _ in
            alert.dismiss(animated: true)
            if alert.title == "Erfolg" {
                self.dataSource.update(animated: true)
            }
        }))
        
        present(alert, animated: true)
    }
}
