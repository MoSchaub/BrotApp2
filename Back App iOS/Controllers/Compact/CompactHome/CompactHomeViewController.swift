//
//  CompactHomeViewController.swift
//  Back App iOS
//
//  Created by Moritz Schaub on 26.06.20.
//  Copyright © 2020 Moritz Schaub. All rights reserved.
//

import SwiftUI
import MobileCoreServices

//class HomeDataSource: UITableViewDiffableDataSource<HomeSection,HomeItem> {
//    var recipeStore: RecipeStore
//
//    init(recipeStore: RecipeStore, tableView: UITableView) {
//        self.recipeStore = recipeStore
//        super.init(tableView: tableView) { (tableView, indexPath, HomeItem) -> UITableViewCell? in
//
//        }
//        setUp()
//    }
//
//    private func setUp() {
//
//    }
//
//
//}

class DetailTableViewCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class CompactHomeViewController: UITableViewController {
    
    typealias DataSource = UITableViewDiffableDataSource<HomeSection,HomeItem>
    typealias Snapshot = NSDiffableDataSourceSnapshot<HomeSection,HomeItem>
    
    private lazy var dataSource = makeDataSource()
    private lazy var subscripton = makeSubscribtion()
    private var recipeStore: RecipeStore
    private lazy var documentPicker = UIDocumentPickerViewController(
        documentTypes: [kUTTypeJSON as String], in: .open
    )
    
    init(recipeStore: RecipeStore) {
        self.recipeStore = recipeStore
        super.init(style: .insetGrouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        tableView.dataSource = dataSource
        registerCells()
        configureNavigationBar()
        updateTableView()
    }

}

private extension CompactHomeViewController {
    private func registerCells() {
        tableView.register(BetterTableViewCell.self, forCellReuseIdentifier: "recipe")
        tableView.register(DetailTableViewCell.self, forCellReuseIdentifier: "detail")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "plain")
    }
    
    private func configureNavigationBar() {
        title = NSLocalizedString("appTitle", comment: "apptitle")
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.leftBarButtonItem = editButtonItem
        navigationItem.rightBarButtonItem = .init(barButtonSystemItem: .add, target: self, action: #selector(presentAddRecipePopover))
    }
    
    @objc private func presentAddRecipePopover(_ sender: UIBarButtonItem) {
           let vc = RecipeDetailViewController(style: .insetGrouped) // create vc
           vc.recipeStore = recipeStore
           vc.creating = true
           vc.saveRecipe = { recipe in
               self.recipeStore.save(recipe: recipe)
           }
           let nv = UINavigationController(rootViewController: vc)

           present(nv, animated: true)
       }
}

private extension CompactHomeViewController {
    private func makeDataSource() -> DataSource {
        DataSource(tableView: tableView) { (tableView, indexPath, homeItem) -> UITableViewCell? in
            // Configuring each cells Content
            if let recipeItem = homeItem as? RecipeItem, let recipeCell = tableView.dequeueReusableCell(withIdentifier: "recipe", for: indexPath) as? BetterTableViewCell {
                recipeCell.textLabel?.text = recipeItem.name
                recipeCell.detailTextLabel?.text = recipeItem.minuteLabel
                recipeCell.setImage(fromData: recipeItem.imageData, placeholder: Images.photo)
                recipeCell.accessoryType = .disclosureIndicator
                
                return recipeCell
            } else if let detailItem = homeItem as? DetailItem {
                let cell = tableView.dequeueReusableCell(withIdentifier: "detail", for: indexPath)
                cell.textLabel?.text = detailItem.name
                cell.detailTextLabel?.text = detailItem.detailLabel
                cell.accessoryType = .disclosureIndicator
                
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "plain", for: indexPath)
                cell.textLabel?.text = homeItem.name
                cell.accessoryView = UIImageView(image: UIImage(systemName: "chevron.up"))
                cell.accessoryView?.tintColor = .tertiaryLabel
                
                return cell
            }
        }
    }
    
    private func updateTableView() {
        var snapshot = NSDiffableDataSourceSnapshot<HomeSection, HomeItem>()
        snapshot.appendSections(HomeSection.allCases)
        snapshot.appendItems(recipeStore.recipeItems, toSection: .recipes)
        snapshot.appendItems(recipeStore.settingsItems, toSection: .settings)
        dataSource.apply(snapshot)
    }
}

extension CompactHomeViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return}
        
        if let recipeItem = item as? RecipeItem {
            navigateToRecipe(recipeItem: recipeItem)
        } else if item.name == NSLocalizedString("raumtemperatur", comment: "") {
            navigateToRoomTempPicker(item: item)
        } else if item.name == NSLocalizedString("importFile", comment: "") {
            openImportFilePopover()
        } else if item.name == NSLocalizedString("exportAll", comment: "") {
            openExportAllShareSheet()
        } else if item.name == NSLocalizedString("about", comment: "") {
            navigateToAboutView()
        }
    }
    
    private func navigateToRecipe(recipeItem: RecipeItem) {
        if let recipe = recipeStore.recipes.first(where: { $0.id == recipeItem.id}) {
            let vc = RecipeDetailViewController(style: .insetGrouped)
            vc.recipe = recipe
            vc.recipeStore = recipeStore
            
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    private func navigateToRoomTempPicker(item: HomeItem) {
        let vc = RoomTempTableViewController(style: .insetGrouped)
        
        vc.recipeStore = recipeStore
        vc.updateTemp = { [self] temp in
            self.recipeStore.roomTemperature = temp
            self.updateTableView()
        }
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func openImportFilePopover() {
        self.documentPicker.delegate = self
        // Present the document picker.
        self.present(documentPicker, animated: true)
    }
    
    private func openExportAllShareSheet() {
        present(UIActivityViewController(activityItems: [recipeStore.exportToUrl()], applicationActivities: nil),animated: true)
    }
    
    private func navigateToAboutView() {
        navigationController?.pushViewController(UIHostingController(rootView: AboutView()), animated: true)
    }
    
}

extension CompactHomeViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        for url in urls {
            recipeStore.open(url)
        }
        var snapshot = dataSource.snapshot()
        snapshot.reloadSections([.recipes])
        dataSource.apply(snapshot)
        
        let alert = UIAlertController(title: recipeStore.inputAlertTitle, message: recipeStore.inputAlertMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            alert.dismiss(animated: true, completion: nil)
        }))
        
        present(alert, animated: true)
    }
}


import Combine

private extension CompactHomeViewController {
    private func makeSubscribtion() -> AnyCancellable {
        recipeStore.objectWillChange.sink { object in
            self.updateTableView()
        }
    }
}
    
//    var recipeStore = RecipeStore()
//
//    lazy private var documentPicker =
//        UIDocumentPickerViewController(documentTypes: [kUTTypeJSON as String],
//                                       in: .open)
//
//    // MARK: - Start functions
//
//    override func loadView() {
//        super.loadView()
//        configureTableView()
//        configureTitle()
//        configureNavigationBarItems()
//    }
//
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        recipeStore.update()
//        tableView.reloadData()
//    }
//
//    private func deselectSelectedRow() {
//        if let indexPath = self.tableView.indexPathForSelectedRow {
//            self.tableView.deselectRow(at: indexPath, animated: true)
//        }
//    }
//
//    private func configureTableView() {
//        tableView  = UITableView(frame: tableView.frame, style: .insetGrouped)
//        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "plain")
//        tableView.register(BetterTableViewCell.self, forCellReuseIdentifier: "recipe")
//    }
//
//    private func configureTitle() {
//        title = NSLocalizedString("appTitle", comment: "apptitle")
//        navigationController?.navigationBar.prefersLargeTitles = true
//    }
//
//    private func configureNavigationBarItems() {
//        navigationItem.leftBarButtonItem = editButtonItem
//        navigationItem.rightBarButtonItem = .init(barButtonSystemItem: .add, target: self, action: #selector(presentAddRecipePopover))
//    }
//
//    // MARK: - rows and sections
//
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        if section == 0 {
//            return recipeStore.recipes.count
//        } else {
//            return 4
//        }
//    }
//
//    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        if section == 0 {
//            return NSLocalizedString("recipes", comment: "")
//        }
//        return nil
//    }
//
//    override func numberOfSections(in tableView: UITableView) -> Int {
//        2
//    }
//
//    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        if indexPath.section == 0 {
//            return 80
//        } else {
//            return 40
//        }
//    }
//
//    // MARK: - Cells
//
//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        if indexPath.section == 0, recipeStore.recipes.count > indexPath.row{ //recipe section
//            return recipeCell(at: indexPath)
//        } else {
//            let cell = tableView.dequeueReusableCell(withIdentifier: "plain", for: indexPath)
//            switch indexPath.row {
//            case 0:
//                cell.textLabel?.text = "\(NSLocalizedString("raumtemperatur", comment: "")): \(recipeStore.roomTemperature)ºC"
//                cell.accessoryType = .disclosureIndicator
//            case 1:
//                cell.textLabel?.text = NSLocalizedString("importFile", comment: "")
//                cell.accessoryView = UIImageView(image: UIImage(systemName: "chevron.up"))
//                cell.accessoryView?.tintColor = .tertiaryLabel
//            case 2:
//                cell.textLabel?.text = NSLocalizedString("exportAll", comment: "")
//                cell.accessoryView = UIImageView(image: UIImage(systemName: "chevron.up"))
//                cell.accessoryView?.tintColor = .tertiaryLabel
//            case 3:
//                cell.textLabel?.text = NSLocalizedString("about", comment: "")
//            default:
//                cell.textLabel?.text = "\(indexPath.row)"
//            }
//
//            return cell
//        }
//    }
//
//    private func recipeCell(at indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "recipe") as! BetterTableViewCell
//        let recipe = recipeStore.recipes[indexPath.row]
//        cell.textLabel?.text = recipe.formattedName
//        cell.textLabel?.font = .preferredFont(forTextStyle: .headline)
//        cell.detailTextLabel?.text = recipe.formattedTotalTime
//        cell.detailTextLabel?.font = .preferredFont(forTextStyle: .footnote)
//        cell.accessoryType = .disclosureIndicator
//
//        cell.setImage(fromData: recipe.imageString, placeholder: Images.photo)
//        return cell
//    }
//
//    // MARK: - Editing
//
//    //delete recipes
//    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
//        if editingStyle == .delete, indexPath.section == 0, recipeStore.recipes.count > indexPath.row {
//            recipeStore.deleteRecipe(at: indexPath.row)
//            tableView.deleteRows(at: [indexPath], with: .automatic)
//        }
//    }
//
//    // move recipes
//    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
//        guard destinationIndexPath.row > recipeStore.recipes.count else { tableView.reloadData(); return }
//        guard destinationIndexPath.section == 0 else { tableView.reloadData(); return }
//        guard recipeStore.recipes.count > sourceIndexPath.row else { tableView.reloadData(); return }
//        recipeStore.moveRecipe(from: sourceIndexPath.row, to: destinationIndexPath.row)
//    }
//
//    //wether a row can be deleted or not
//    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
//        if indexPath.section == 0 {
//            return true
//        } else {return false}
//    }
//
//    //wether a row can be moved or not
//    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
//        if indexPath.section == 0 {
//            return true
//        } else {return false}
//    }
//
//
//    // MARK: - Navigation
//
//    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        if indexPath.section == 0, recipeStore.recipes.count > indexPath.row {
//            // 1: try loading the "Detail" view controller and typecasting it to be RecipeDetailViewController
//            let vc = RecipeDetailViewController(style: .insetGrouped)
//            // 2: success! Set its recipe property
//            vc.recipe = recipeStore.recipes[indexPath.row]
//            vc.recipeStore = recipeStore
//
//            // 3: now push it onto the navigation controller
//            navigationController?.pushViewController(vc, animated: true)
//        } else if indexPath.section == 1 {
//            let row = indexPath.row
//            if row == 0 {
//                let vc = RoomTempTableViewController(style: .insetGrouped)
//
//                vc.recipeStore = recipeStore
//                vc.updateTemp = { temp in
//                    self.recipeStore.roomTemperature = temp
//                    self.tableView.reloadData()
//                }
//
//                navigationController?.pushViewController(vc, animated: true)
//            } else if row == 1 {
//                self.documentPicker.delegate = self
//                // Present the document picker.
//                self.present(documentPicker, animated: true, completion: deselectSelectedRow)
//            } else if row == 2 {
//                let vc = UIActivityViewController(activityItems: [recipeStore.exportToUrl()], applicationActivities: nil)
//
//                present(vc,animated: true, completion: deselectSelectedRow)
//
//            } else if row == 3 {
//                navigationController?.pushViewController(UIHostingController(rootView: AboutView()), animated: true)
//            }
//
//        }
//    }
//
//    @objc private func presentAddRecipePopover(_ sender: UIBarButtonItem) {
//        let vc = RecipeDetailViewController(style: .insetGrouped) // create vc
//        vc.recipeStore = recipeStore
//        vc.creating = true
//        vc.saveRecipe = { recipe in
//            self.recipeStore.save(recipe: recipe)
//            self.tableView.reloadData()
//        }
//        let nv = UINavigationController(rootViewController: vc)
//
//        present(nv, animated: true)
//    }
//
//
//}
//
//extension CompactHomeViewController: UIDocumentPickerDelegate {
//    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
//        for url in urls {
//            recipeStore.open(url)
//        }
//        self.tableView.reloadData()
//
//        let alert = UIAlertController(title: recipeStore.inputAlertTitle, message: recipeStore.inputAlertMessage, preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
//            alert.dismiss(animated: true, completion: nil)
//            if let selectedRowIndex = self.tableView.indexPathForSelectedRow {
//                self.tableView.deselectRow(at: selectedRowIndex, animated: true)
//            }
//        }))
//
//        present(alert, animated: true)
//    }
//}

