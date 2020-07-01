//
//  StepDetailViewController.swift
//  Back App iOS
//
//  Created by Moritz Schaub on 27.06.20.
//  Copyright © 2020 Moritz Schaub. All rights reserved.
//

import SwiftUI

class StepDetailViewController: UITableViewController {
    
    // MARK: - Properties
    var step: Step! {
        willSet {
            if newValue != nil { if recipe != nil, recipeStore != nil {
                recipeStore.update(step: newValue, in: recipe)
                }
                title = newValue.formattedName
            }
        }
    }
    var recipe: Recipe!
    
    var recipeStore: RecipeStore!
    
    var initializing = true
    var creating = false
    var saveStep: ((Step, Recipe) -> Void)?
    
    var datePicker: UIDatePicker!
    
    // MARK: - Start functions
    
    override func loadView() {
        super.loadView()
        self.tableView = UITableView(frame: tableView.frame, style: .insetGrouped)
        registerCells()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addNavigationBarItems()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !initializing {
            self.step = recipeStore.stepForUpdate(oldStep: step, in: recipe)
            tableView.reloadData()
        }
        initializing = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if creating {
            recipeStore.save(recipe: recipe)
            recipeStore.save(step: step, to: recipe)
        }
    }
    
    // MARK: - navigationBarItems
    
    private func addNavigationBarItems() {
        if creating {
            navigationItem.rightBarButtonItem = .init(barButtonSystemItem: .save, target: self, action: #selector(addStep))
        } else {
            navigationItem.rightBarButtonItem = editButtonItem
        }
    }
    
    @objc private func addStep(_ sender: UIBarButtonItem) {
        if creating, let saveStep = saveStep {
            saveStep(step, recipe)
            navigationController?.popViewController(animated: true)
        }
    }

    // MARK: - Sections and rows

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 5
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 4 {
            return step.ingredients.count + 1 + step.subSteps.count
        } else {
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return NSLocalizedString("name", comment: "")
        case 1: return NSLocalizedString("notes", comment: "")
        case 2: return NSLocalizedString("duration", comment: "")
        case 3: return NSLocalizedString("temperature", comment: "")
        case 4: return NSLocalizedString("Zutaten", comment: "")
        default: return ""
        }
    }

    // MARK: - Cells
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0: return makeNameCell()
        case 1: return makeNotesCell()
        case 2: return makeDurationCell()
        case 3: return makeTempCell()
        case 4:
            if indexPath.row - step.subSteps.count == step.ingredients.count {
                return makeAddIngredientCell()
            } else if indexPath.row < step.subSteps.count{
                return makeSubstepCell(at: indexPath)
            } else {
                return makeIngredientCell(at: indexPath)
            }
        default: return UITableViewCell()
        }
    }

    private func registerCells() {
        tableView.register(TextFieldTableViewCell.self, forCellReuseIdentifier: "name")
        tableView.register(TextFieldTableViewCell.self, forCellReuseIdentifier: "notes")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "duration")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "temp")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "addIngredient")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "substep")
    }

    private func makeNameCell() -> TextFieldTableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "name") as! TextFieldTableViewCell
        cell.textField.text = step.name
        cell.textField.placeholder = NSLocalizedString("name", comment: "")
        cell.selectionStyle = .none
        cell.textChanged = { text in
            self.step.name = text
        }
        return cell
    }
    
    private func makeNotesCell() -> TextFieldTableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "notes") as! TextFieldTableViewCell
        cell.textField.text = step.notes
        cell.textField.placeholder = NSLocalizedString("notes", comment: "")
        cell.selectionStyle = .none
        cell.textChanged = { text in
            self.step.notes = text
        }
        return cell
    }
    
    private func makeDurationCell() -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "duration")!
        
        cell.textLabel?.text = step.formattedTime
        cell.accessoryType = .disclosureIndicator
            
        return cell
    }
    
    private func makeTempCell() -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "temp")!
        cell.textLabel?.text = step.formattedTemp
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    private func makeIngredientCell(at indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "ingredient")
        cell.prepareForReuse()
        
        let ingredient = step.ingredients[indexPath.row - step.subSteps.count]
        cell.textLabel?.text = ingredient.name
        cell.detailTextLabel?.text = ingredient.formattedAmount + (ingredient.isBulkLiquid ? " \(step.themperature(for: ingredient, roomThemperature: recipeStore.roomTemperature))° C" : "")
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    private func makeSubstepCell(at indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "substep")
        cell.prepareForReuse()
        
        let substep = step.subSteps[indexPath.row]
        cell.textLabel?.text = substep.name
        cell.detailTextLabel?.text = substep.totalFormattedAmount + " " + substep.formattedTemp
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    private func makeAddIngredientCell() -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "addIngredient")!
        
        cell.textLabel?.text = NSLocalizedString("addIngredient", comment: "")
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }

    // MARK: delete and move
    
    //conditional deletion
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        indexPath.section == 4 && indexPath.row < step.ingredients.count - step.subSteps.count
    }

    //delete cells
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            if indexPath.row < step.subSteps.count - 1 {
                step.subSteps.remove(at: indexPath.row)
            } else {
                step.ingredients.remove(at: indexPath.row - step.subSteps.count)
            }
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }

    // moving cells
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard destinationIndexPath.section == 4 else { return }
        guard sourceIndexPath.row < step.ingredients.count else { return }
        let movedObject = step.ingredients[sourceIndexPath.row]
        step.ingredients.remove(at: sourceIndexPath.row)
        step.ingredients.insert(movedObject, at: destinationIndexPath.row)
    }

    //conditional moving
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        indexPath.section == 4 && indexPath.row - step.subSteps.count < step.ingredients.count - step.subSteps.count
    }
    
    // MARK: - Navigation
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 2 {
            navigateToTimePicker()
        } else if indexPath.section == 3 {
            navigateToTempPicker()
        } else if indexPath.section == 4 {
            if indexPath.row >= step.ingredients.count + step.subSteps.count {
                let stepsWithIngredients = recipe.steps.filter({ step1 in step1.ingredients.count != 0 && step1.id != self.step.id && !self.step.subSteps.contains(where: {step1.id == $0.id})})
                if stepsWithIngredients.count > 0 {
                    let alert = UIAlertController(title: NSLocalizedString("ingredientOrStep", comment: ""), message: nil, preferredStyle: .actionSheet)
                    
                    alert.addAction(UIAlertAction(title: NSLocalizedString("newIngredient", comment: ""), style: .default, handler: { _ in
                        self.navigateToIngredientDetail(creating: true, indexPath: indexPath)
                    }))
                    alert.addAction(UIAlertAction(title: NSLocalizedString("step", comment: ""), style: .default, handler: { _ in
                        self.showSubstepsActionSheet(possibleSubsteps: stepsWithIngredients)
                    }))
                    alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: nil))
                    
                    present(alert, animated: true)
                } else {
                    navigateToIngredientDetail(creating: true, indexPath: indexPath)
                }
            } else if indexPath.row > step.ingredients.count - step.subSteps.count {
                navigateToIngredientDetail(creating: false, indexPath: indexPath)
            }
        }
    }
    
    private func navigateToTimePicker() {
        let timePickerVC = StepTimeTableViewController(style: .insetGrouped)
        timePickerVC.recipeStore = recipeStore
        timePickerVC.recipe = recipe
        timePickerVC.step = step
        
        navigationController?.pushViewController(timePickerVC, animated: true)
    }
    
    private func navigateToTempPicker() {
        let tempPickerVC = StepTempTableViewController(style: .insetGrouped)
        tempPickerVC.recipeStore = recipeStore
        tempPickerVC.recipe = recipe
        tempPickerVC.step = step
        
        navigationController?.pushViewController(tempPickerVC, animated: true)
    }
    
    private func navigateToIngredientDetail(creating: Bool, indexPath: IndexPath) {
        let ingredientDetailVC = IngredientDetailViewController()
        
        ingredientDetailVC.recipeStore = recipeStore
        ingredientDetailVC.step = step
        ingredientDetailVC.ingredient = creating ? Ingredient(name: "", amount: 0) : step.ingredients[indexPath.row - step.subSteps.count]
        ingredientDetailVC.creating = creating
        
        if creating {
            ingredientDetailVC.saveIngredient = save
        }
        
        navigationController?.pushViewController(ingredientDetailVC, animated: true)
    }
    
    private func save(ingredient: Ingredient, step: Step){
        recipeStore.add(ingredient: ingredient, step: step)
        tableView.reloadData()
    }
    
    private func showSubstepsActionSheet(possibleSubsteps: [Step]) {
        let actionSheet = UIAlertController(title: NSLocalizedString("selectStep", comment: ""), message: nil, preferredStyle: .actionSheet)
        
        for possibleSubstep in possibleSubsteps {
            actionSheet.addAction(UIAlertAction(title: possibleSubstep.formattedName, style: .default, handler: { _ in
                self.step.subSteps.append(possibleSubstep)
                self.tableView.reloadData()
            }))
        }
        
        actionSheet.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
    }

}
