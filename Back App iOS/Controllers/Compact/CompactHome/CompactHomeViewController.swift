//
//  CompactHomeViewController.swift
//  Back App iOS
//
//  Created by Moritz Schaub on 26.06.20.
//  Copyright © 2020 Moritz Schaub. All rights reserved.
//

import SwiftUI
import MobileCoreServices
import BackAppCore
import BakingRecipeStrings
import BakingRecipeSections
import BakingRecipeItems
import BakingRecipeCells
import BakingRecipeFoundation

class CompactHomeViewController: UITableViewController {
    
    typealias DataSource = HomeDataSource
    typealias Snapshot = NSDiffableDataSourceSnapshot<HomeSection,TextItem>

    private(set) lazy var dataSource = makeDataSource()
    private var appData: BackAppData
    private lazy var documentPicker = UIDocumentPickerViewController(
        documentTypes: [kUTTypeJSON as String], in: .open
    )
    
    init(appData: BackAppData) {
        self.appData = appData
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


import BakingRecipeFoundation

private extension CompactHomeViewController {
    private func registerCells() {
        tableView.register(RecipeCell.self, forCellReuseIdentifier: Strings.recipeCell)
        tableView.register(DetailCell.self, forCellReuseIdentifier: Strings.detailCell)
        tableView.register(CustomCell.self, forCellReuseIdentifier: Strings.plainCell)
    }
    
    private func configureNavigationBar() {
        title = Strings.appTitle
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.leftBarButtonItem = editButtonItem
        navigationItem.rightBarButtonItem = .init(barButtonSystemItem: .add, target: self, action: #selector(presentAddRecipePopover))
    }
    
    ///present popover for creating new recipe
    @objc private func presentAddRecipePopover(_ sender: UIBarButtonItem) {
        
        // the new fresh recipe
        let recipe = Recipe.init(id: 1)
        
        //the vc
        let vc = RecipeDetailViewController(recipe: recipe, creating: true, saveRecipe: { recipe in
            
            //insert the new recipe when saving
            //first make its id unique
            var newRecipe = recipe
            newRecipe.id = self.appData.newId(for: Recipe.self)
            
            
            if self.appData.insert(newRecipe) {
                DispatchQueue.main.async {
                    self.dataSource.update(animated: false)
                }
            }
        }, deleteRecipe: { _ in return false }) // no need to delete something if it does not exits yet
        
        // navigation Controller
        let nv = UINavigationController(rootViewController: vc)
        nv.modalPresentationStyle = .fullScreen //to prevent data loss
        
        present(nv, animated: true)
       }
}

private extension CompactHomeViewController {
    private func makeDataSource() -> DataSource {
        HomeDataSource(appData: appData, tableView: tableView)
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
//            openImportFilePopover()
        } else if item.text == Strings.exportAll {
            openExportAllShareSheet(sender: tableView.cellForRow(at: indexPath)!)
        } else if item.text == Strings.about {
            navigateToAboutView()
        }
    }
    
    private func navigateToRecipe(recipeItem: RecipeItem) {
        
        // get the recipe from the database
        if let recipe = appData.recipe(with: recipeItem.id) {
            
            //create the vc
            let vc = RecipeDetailViewController(recipe: recipe, creating: false, saveRecipe: { recipe in
                
                //update in the database if it changes
                if self.appData.update(recipe) {
                    DispatchQueue.main.async {
                        self.dataSource.update(animated: false)
                    }
                }
            }) { recipe in //delete recipe
                let result: Bool
                if self.splitViewController?.isCollapsed ?? false { //no splitvc visible
                    result = self.appData.delete(recipe)
                    self.navigationController?.popViewController(animated: true)
                } else { //splitvc
                    let _ = self.splitViewController?.viewControllers.popLast()
                    result = self.appData.delete(recipe)
                    self.dataSource.update()
                }
                return result
            }
            
            //push to the view controller
            splitViewController?.showDetailViewController(UINavigationController(rootViewController: vc), sender: self)
        }
    }
    
    private func navigateToRoomTempPicker(item: TextItem) {
        let vc = RoomTempTableViewController(style: .insetGrouped)
        
        vc.appData = appData
        vc.updateTemp = { [self] temp in
            Standarts.standardRoomTemperature = temp
            self.updateStandarts()
        }
        splitViewController?.showDetailViewController(UINavigationController(rootViewController: vc), sender: self)
    }
    
    private func updateStandarts() {
        DispatchQueue.global(qos: .background).async {
            var snapshot = self.dataSource.snapshot()
            snapshot.deleteSections([.settings])
            snapshot.appendSections([.settings])
            snapshot.appendItems(self.appData.settingsItems, toSection: .settings)
            DispatchQueue.main.async {
                self.dataSource.apply(snapshot, animatingDifferences: false)
            }
        }
    }
    
//    private func openImportFilePopover() {
//        self.documentPicker.delegate = self
//        // Present the document picker.
//        self.present(documentPicker, animated: true, completion: deselectRow)
//    }
    
    private func openExportAllShareSheet(sender: UIView) {
//        let ac = UIActivityViewController(activityItems: [appData.exportToURL()], applicationActivities: nil)
//        ac.popoverPresentationController?.sourceView = sender
//        present(ac,animated: true, completion: deselectRow)
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

//extension CompactHomeViewController: UIDocumentPickerDelegate {
//    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
//        
//        //load recipes
//        for url in urls {
//            recipeStore.open(url)
//        }
//        
//        //update cells
//        self.dataSource.update(animated: true)
//        
//        //alert
//        let alert = UIAlertController(title: recipeStore.inputAlertTitle, message: recipeStore.inputAlertMessage, preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: Strings.Alert_ActionOk, style: .default, handler: { _ in
//            alert.dismiss(animated: true)
//        }))
//        
//        present(alert, animated: true)
//    }
//}
