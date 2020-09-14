//
//  RecipeDetailViewController.swift
//  Back App iOS
//
//  Created by Moritz Schaub on 25.06.20.
//  Copyright © 2020 Moritz Schaub. All rights reserved.
//

import SwiftUI
import BakingRecipe

class RecipeDetailViewController: UITableViewController {
    
    typealias SaveRecipe = ((Recipe) -> ())
    typealias DeleteRecipe = ((Recipe) -> Bool)
    
    private lazy var dataSource = makeDataSource()
    
    private var imagePickerController: UIImagePickerController?
    
    private var recipe: Recipe {
        didSet {
            setUpNavigationBar()
            update(oldValue: oldValue)
        }
    }
    private var creating: Bool
    private var saveRecipe: SaveRecipe
    private var deleteRecipe: DeleteRecipe
    
    private func update(oldValue: Recipe) {
        DispatchQueue.global(qos: .utility).async {
            if !self.creating, oldValue != self.recipe {
                self.saveRecipe(self.recipe)
            }
        }
    }
    
    init(recipe: Recipe, creating: Bool, saveRecipe: @escaping SaveRecipe, deleteRecipe: @escaping DeleteRecipe) {
        self.recipe = recipe
        self.creating = creating
        self.saveRecipe = saveRecipe
        self.deleteRecipe = deleteRecipe
        super.init(style: .insetGrouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError(Strings.init_coder_not_implemented)
    }
}

extension RecipeDetailViewController {
    override func loadView() {
        super.loadView()
        setUpNavigationBar()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        registerCells()
        self.tableView.separatorStyle = .none
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dataSource.update(animated: false)
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 250
    }
    
}

private extension RecipeDetailViewController {
    private func makeDataSource() -> RecipeDetailDataSource {
        RecipeDetailDataSource(recipe: Binding(get: {
            return self.recipe
        }, set: { newValue in
            self.recipe = newValue
        }), creating: creating, tableView: tableView, nameChanged: { name in
            self.recipe.name = name
        }, formatAmount: { timesText in
            guard Double(timesText.trimmingCharacters(in: .letters).trimmingCharacters(in: .whitespacesAndNewlines)) != nil else { return self.recipe.timesText}
            self.recipe.times = Decimal(floatLiteral: Double(timesText.trimmingCharacters(in: .letters).trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0)
            return self.recipe.timesText
        }, updateInfo: { info in
            self.recipe.info = info
        })
    }
}

private extension RecipeDetailViewController {
    private func setUpNavigationBar() {
        if creating {
            navigationItem.rightBarButtonItems = [UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveRecipeWrapper))]
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        } else {
            let favourite = UIBarButtonItem(image: UIImage(systemName: recipe.isFavourite ? "star.fill" : "star"), style: .plain, target: self, action: #selector(favouriteRecipe))
            let share = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareRecipeFile))
            let delete = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteRecipeWrapper))
            DispatchQueue.main.async {
                self.navigationItem.rightBarButtonItems = [favourite, share, delete]
            }
        }
        DispatchQueue.main.async {
            self.title = self.recipe.formattedName
        }
    }
    
    private func registerCells() {
        tableView.register(DetailTableViewCell.self, forCellReuseIdentifier: Strings.detailCell)
        tableView.register(ImageTableViewCell.self, forCellReuseIdentifier: Strings.imageCell)
        tableView.register(StepTableViewCell.self, forCellReuseIdentifier: Strings.stepCell)
        tableView.register(TextFieldTableViewCell.self, forCellReuseIdentifier: Strings.textFieldCell)
        tableView.register(InfoStripTableViewCell.self, forCellReuseIdentifier: Strings.infoStripCell)
        tableView.register(AmountTableViewCell.self, forCellReuseIdentifier: Strings.amountCell)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Strings.plainCell)
        tableView.register(TextViewTableViewCell.self, forCellReuseIdentifier: Strings.infoCell)
    }
}

private extension RecipeDetailViewController {
    
    @objc private func favouriteRecipe(_ sender: UIBarButtonItem) {
        recipe.isFavourite.toggle()
    }
    
    @objc private func shareRecipeFile(sender: UIBarButtonItem) {
        let vc = UIActivityViewController(activityItems: [recipe.createFile()], applicationActivities: nil)
        vc.popoverPresentationController?.barButtonItem = sender
        present(vc, animated: true)
    }
    
    @objc private func saveRecipeWrapper() {
        if creating {
            saveRecipe(self.recipe)
            dissmiss()
        }
    }
    
    @objc private func cancel() {
        dissmiss()
    }
    
    @objc private func deleteRecipeWrapper() {
        navigationController?.popToRootViewController(animated: true)
        if !creating, self.deleteRecipe(recipe) {
            navigationController?.popToRootViewController(animated: true)
        }
    }
    
    private func dissmiss() {
        navigationController?.dismiss(animated: true, completion: nil)
    }
}


extension RecipeDetailViewController {
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard RecipeDetailSection.allCases[section] == .steps else { return nil }
        let frame = tableView.frame
        
        let editButton = UIButton(frame: CGRect(x: frame.size.width - 60, y: 10, width: 50, height: 30))
        editButton.setAttributedTitle(attributedTitleForEditButton(), for: .normal)
        editButton.addTarget(self, action: #selector(toggleEditMode(sender:)), for: .touchDown)
        
        let titleLabel = UILabel(frame: CGRect(x: 10, y: 10, width: 100, height: 30))
        let attributes = [
            NSAttributedString.Key.font : UIFont.preferredFont(forTextStyle: .footnote),
            .foregroundColor : UIColor.secondaryLabel,
        ]
        titleLabel.attributedText = NSAttributedString(string: Strings.steps.uppercased(), attributes: attributes)
        
        let stackView = UIStackView(frame: CGRect(x: 5, y: 0, width: frame.size.width - 10, height: frame.size.height))
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(editButton)
        
        return stackView
    }
    
    private func attributedTitleForEditButton() -> NSAttributedString {
        let attributes: [NSAttributedString.Key: Any] = [
            .font : UIFont.preferredFont(forTextStyle: .subheadline, compatibleWith: .current),
            .foregroundColor : UIColor(named: Strings.backgroundColorName)!
        ]
        let titleString = isEditing ? Strings.EditButton_Done : Strings.EditButton_Edit
        return NSAttributedString(string: titleString, attributes: attributes)
    }
    
    @objc private func toggleEditMode(sender: UIButton) {
        if recipe.steps.count > 0 {
            setEditing(!isEditing, animated: true)
            sender.setAttributedTitle(attributedTitleForEditButton(), for: .normal)
        }
    }
    
}

private extension Recipe {
    func createFile() -> URL {
        let url = getDocumentsDirectory().appendingPathComponent("\(self.formattedName).bakingAppRecipe")
        DispatchQueue.global(qos: .userInitiated).async {
            if let encoded = try? JSONEncoder().encode(self.neutralizedForExport()) {
                do {
                    try encoded.write(to: url)
                } catch {
                    print(error)
                }
            }
        }
        return url
    }
}

extension RecipeDetailViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let item = dataSource.itemIdentifier(for: indexPath) {
            if item is ImageItem {
                imageTapped(sender: indexPath)
            } else if let stepItem = item as? StepItem {
                showStepDetail(id: stepItem.id)
            } else if let detailItem = item as? DetailItem {
                if detailItem.text == Strings.startRecipe {
                    startRecipe()
                } else if detailItem.text == Strings.addStep {
                    addStep()
                }
            }
        }
    }
}

private extension RecipeDetailViewController {
    private func imageTapped(sender: IndexPath) {
        if imagePickerController != nil {
            imagePickerController?.delegate = nil
            imagePickerController = nil
        }
        imagePickerController = UIImagePickerController()
        
        let alert = UIAlertController(title: Strings.image_alert_title, message: nil, preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: Strings.take_picture, style: .default, handler: { (_) in
                self.presentImagePicker(controller: self.imagePickerController!, for: .camera)
            }))
        }
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            alert.addAction(UIAlertAction(title: Strings.select_image, style: .default, handler: { (_) in
                self.presentImagePicker(controller: self.imagePickerController!, for: .photoLibrary)
            }))
        }
        
        alert.addAction(UIAlertAction(title: Strings.Alert_ActionRemove, style: .destructive, handler: { (_) in
            self.recipe.imageString = nil
            self.dataSource.update(animated: false)
        }))
        alert.addAction(UIAlertAction(title: Strings.Alert_ActionCancel, style: .cancel, handler: { (_) in
            if let indexPath = self.tableView.indexPathForSelectedRow {
                self.tableView.cellForRow(at: indexPath)?.isSelected = false
            }
        }))
        
        alert.popoverPresentationController?.sourceView = tableView.cellForRow(at: sender)
        
        present(alert, animated: true)
        
    }
    
    private func showStepDetail(id: UUID) {
        if let step = recipe.steps.first(where: { $0.id == id }) {
            let stepDetailVC = StepDetailViewController(step: step, creating: false, recipe: recipe) { step in
                if let index = self.recipe.steps.firstIndex(where: { $0.id == step.id }) {
                    self.recipe.steps[index] = step
                    self.dataSource.update(animated: false)
                }
            }
            navigationController?.pushViewController(stepDetailVC, animated: true)
        }
    }
    
    private func startRecipe() {
//        let roomTemp = UserDefaults.standard.integer(forKey: Strings.roomTempKey)
        let recipeBinding = Binding(get: {
            return self.recipe
        }) { (newValue) in
            self.recipe = newValue
        }
        let scheduleForm = ScheduleFormViewController(recipe: recipeBinding)
        
        navigationController?.pushViewController(scheduleForm, animated: true)
    }
    
    private func addStep() {
        let step = Step(time: 60)
        let stepDetailVC = StepDetailViewController(step: step, creating: true, recipe: recipe) { step in
            self.recipe.steps.append(step)
            DispatchQueue.main.async {
                self.dataSource.update(animated: false)
            }
        }
        
        navigationController?.pushViewController(stepDetailVC, animated: true)
    }
}

extension RecipeDetailViewController {
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let _ = dataSource.itemIdentifier(for: indexPath) as? InfoItem {
            return 80
        } else if let _ = dataSource.itemIdentifier(for: indexPath) as? ImageItem {
            return 250
        }
        return UITableView.automaticDimension
    }
}

extension RecipeDetailViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private func presentImagePicker(controller: UIImagePickerController, for source: UIImagePickerController.SourceType) {
        controller.delegate = self
        controller.sourceType = source
        
        present(controller, animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { //cant be private
        picker.dismiss(animated: true, completion: {
            self.terminate(picker)
        })
    }
    
    private func terminate(_ picker: UIImagePickerController) {
        picker.delegate = nil
        imagePickerController = nil
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) { // can't be private
        if let uiImage = info[.originalImage] as? UIImage {
            recipe.imageString = uiImage.jpegData(compressionQuality: 0.3)
            self.dataSource.update(animated: false)
            
            picker.dismiss(animated: true) {
                self.terminate(picker)
            }
        } else {
            imagePickerControllerDidCancel(picker)
        }
    }
}
