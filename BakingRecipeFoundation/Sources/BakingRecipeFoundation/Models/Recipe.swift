//
//  Rezept.swift
//  BrotApp2
//
//  Created by Moritz Schaub on 29.09.19.
//  Copyright © 2019 Moritz Schaub. All rights reserved.
//

import Sqlable
import Foundation
import BakingRecipeStrings

public struct Recipe: Hashable, Codable, Identifiable, Equatable, Sqlable {
    
    /// id of the recipe
    public var id: Int
    
    ///name of the recipe
    public var name: String
    
    ///small text containing some Info about the recipe
    public var info: String = ""
    
    ///wether the recipe is a favourite
    public var isFavorite: Bool = false
    
    ///how difficult the recipe is
    public var difficulty: Difficulty = .easy
    
    ///wether the "date" property is the end date or the start date
    public var inverted: Bool = false
    
    ///for how many items eg breads, rolls, etc the the ingredients are set
    public var times: Decimal? = Decimal(integerLiteral: 1)
    
    ///date thats either the start or the end point of the recipe
    public var date: Date = Date()
    
    ///data of the image for the recipe
    public var imageData: Data?
    
}

///date formatter with custom dateFormat
public var dateFormatter: DateFormatter{
    let formatter = DateFormatter()
    formatter.dateFormat = "dd.MM.yy',' HH:mm"
    return formatter
}

public extension Recipe {
    
    /// steps of the recipe
    private func steps(db: SqliteDatabase) -> [Step] {
        (try? Step.read().filter(Step.recipeId == self.id).run(db)) ?? []
    }
    
    ///starting date
    private func startDate(db: SqliteDatabase) -> Date {
        if !inverted {
            return date
        } else {
            return date.addingTimeInterval(TimeInterval(-(totalDuration(db: db) * 60)))
        }
    }
    
    ///end date
    private func endDate(db: SqliteDatabase) -> Date {
        if inverted {
            return date
        } else {
            return date.addingTimeInterval(TimeInterval(totalDuration(db: db) * 60))
        }
    }
    
    /// total duration of all the steps in the brotValues array
    func totalDuration(db: SqliteDatabase) -> Int {
        var allTimes: Int = 0
        for step in steps(db: db) {
            allTimes += Int(step.duration/60)
        }
        return allTimes
    }
    
    ///number of all ingredients used in the recipe
    func numberOfAllIngredients(db: SqliteDatabase) -> Int {
        var counter = 0
        for step in steps(db: db) {
            counter += (try? Ingredient.count().filter(Ingredient.stepId == step.id).run(db)) ?? 0
        }
        return counter
    }
    
    // formatted text for times
    var timesText: String{
        get{
            if self.times != nil {
                return times!.description + " " +
                    (times!.description == "1" ? Strings.piece : Strings.pieces)
            } else {
                return "1 " + Strings.piece
            }
        }
        set{
            if let int = Int(newValue){
                self.times = Decimal(integerLiteral: int)
            } else{
                self.times = nil
            }
        }
    }
    
    //MARK: formatted Properties
    
    ///formatted total duration in the right unit
    func formattedTotalDuration(db: SqliteDatabase) -> String {
        totalDuration(db: db).formattedDuration
    }
    
    ///formatted Name with a standart value
    ///should be used when displaying the name
    var formattedName: String {
        name.trimmingCharacters(in: .whitespaces).isEmpty ? Strings.unnamedRecipe : name
    }
    
    /// startDate formatted using the dateFormatter
    func formattedStartDate(db: SqliteDatabase) -> String {
        dateFormatter.string(from: startDate(db: db))
    }
    
    /// endDate formatted using the dateFormatter
    func formattedEndDate(db: SqliteDatabase) -> String {
        dateFormatter.string(from: endDate(db: db))
    }
    
    /// formatted Datetext including start and end Text e. g. "Start: 01.01. 1970 18:00"
    func formattedDate(db: SqliteDatabase) -> String {
        if inverted {
            return "\(Strings.end) \(formattedEndDate(db: db))"
        } else{
            return "\(Strings.start)) \(formattedStartDate(db: db))"
        }
    }
    
    /// combination of formattedEndDate and formattedStartDate
    func formattedStartBisEnde(db: SqliteDatabase) -> String{
        "\(self.formattedStartDate(db: db)) bis \n\(self.formattedEndDate(db: db))"
    }
    
    /// the startDateText for a given Step in this recipe
    private func formattedStartDate(for item: Step, db: SqliteDatabase) -> String {
        let datesDict = startDatesDictionary(db: db)
        if let date = datesDict[item] {
            return dateFormatter.string(from: date)
        }
        return "error"
    }
    
    ///dictonary with the step and the corresponding startdate
    private func startDatesDictionary(db: SqliteDatabase) -> [Step : Date]{
        var dict = [Step : Date]()
        var h = startDate(db: db)
        for step in self.notSubsteps(db: db) {
            let stepDates = startDates(for: step, h: h, db: db)
            dict.append(contentsOf: stepDates.dict)
            h = stepDates.h
            
            h.addTimeInterval(step.duration)
        }
        return dict
    }
    
    ///Tuple with a start date and a startDates dictionary
    private func startDates(for step: Step, h: Date, db: SqliteDatabase) -> (h: Date, dict: [Step : Date]) {
        var dict = [Step : Date]()
        var h = h
        var sortedSubs = step.sortedSubsteps(db: db)
        if let first = sortedSubs.first { //get the longest sub
            sortedSubs.removeFirst() //remove so it does not get used twice
            let firstDates = startDates(for: first, h: h, db: db)
            dict.append(contentsOf: firstDates.dict)
            h = firstDates.h
            
            let subEndDate = h.addingTimeInterval(first.duration) //data when all substebs of the step should end
            for sub in sortedSubs {
                let subDates = startDates(for: sub, h: subEndDate.addingTimeInterval(-(sub.duration)), db: db)
                dict.append(contentsOf: subDates.dict)
            }
            
            h = subEndDate
        }
        dict[step] = h
        
        return (h,dict)
    }
    
    /// steps that are no substeps of any other step
    func notSubsteps(db: SqliteDatabase) -> [Step] {
        self.steps(db: db).filter({ $0.superStepId != nil })
    }
    
    static var example: (Recipe, [Step], [Ingredient]) {
        let vollkornMehl = Ingredient(stepId: 1, id: 1, name: "Vollkornmehl", amount: 50, type: .flour)
        let anstellgut = Ingredient(stepId: 1, id: 2, name: "Anstellgut TA 200", amount: 120, type: .ta200)
        let olivenöl = Ingredient(stepId: 1, id: 3, name: "Olivenöl", amount: 40, type: .bulkLiquid)
        let saaten = Ingredient(stepId: 1, id: 4, name: "Saaten", amount: 30, type: .other)
        let salz = Ingredient(stepId: 1, id: 5, name: "Salz", amount: 5, type: .other)
        
        let schritt1 = Step(id: 1, name: "Mischen", duration: 2*60, temperature: 20, recipeId: 1)
        
        let backen = Step(id: 2, name: "Backen", duration: 18*60, notes: "170˚ C", recipeId: 1)
        
        return (Recipe(id: 1, name: "Sauerteigcracker"), [schritt1,backen], [vollkornMehl, anstellgut, olivenöl, saaten, salz])
    }
    
//    static public var complexExample: Recipe {
//        let sub = Step(name: "Sauerteig", ingredients: [
//            Ingredient(name: "Mehl", amount: 200, type: .flour),
//            Ingredient(name: "Wasser", amount: 100, type: .bulkLiquid)
//        ], themperature: 30)
//        var step = Step(name: "Hauptteig", time: 1800, ingredients: [
//            Ingredient(name: "Mehl", amount: 200, type: .flour),
//            Ingredient(name: "Wasser", amount: 150, type: .bulkLiquid),
//            Ingredient(name: "Salz", amount: 20, type: .other)
//        ], themperature: 26)
//        step.subSteps.append(sub)
//        return Recipe(name: "Komplexes Rezept", brotValues: [sub, step])
//    }
    
    
    //reorderSteps to make sense
    func reorderedSteps(db: SqliteDatabase) -> [Step] {
        var steps = [Step]()
        for step in self.notSubsteps(db: db) {
            steps.append(contentsOf: step.stepsForReodering(db: db))
        }
        steps = Array<Step>(Set(steps)) // make them unique
        return steps
    }
    
    ///text for exporting
    func text(roomTemp: Int, scaleFactor: Double, db: SqliteDatabase) -> String {
        var h = startDate(db: db)
        var text = ""
        
        for step in notSubsteps(db: db) {
            text += step.text(startDate: h, roomTemp: roomTemp, scaleFactor: scaleFactor, db: db)
            h = h.addingTimeInterval(step.duration)
        }
        text += "Fertig: \(dateFormatter.string(from: endDate(db: db)))"
        return text
    }
    
    ///recipe prepared for exporting
    func neutralizedForExport() -> Recipe {
        var neutralized = self
        neutralized.inverted = false
        neutralized.isFavorite = false
        return neutralized
    }
}


//- MARK: - Sqlable
public extension Recipe {
    
    //create columns
    static let id = Column("id", .integer, PrimaryKey(autoincrement: true))
    static let name = Column("name", .text)
    static let info = Column("info", .text)
    static let isFavorite = Column("isFavorite", .boolean)
    static let difficulty = Column("difficulty", .integer)
    static let inverted = Column("inverted", .boolean)
    static let times = Column("times", .nullable(.real))
    static let date = Column("date", .date)
    static let imageData = Column("imageData", .nullable(.text))
    
    //create tableLayout from columns
    static var tableLayout: [Column] = [id, name, info, isFavorite, difficulty, inverted, times, date, imageData]
    
    ///get value from column
    func valueForColumn(_ column: Column) -> SqlValue? {
        switch column {
        case Recipe.id:
            return self.id
        case Recipe.name:
            return self.name
        case Recipe.info:
            return self.info
        case Recipe.isFavorite:
            return self.isFavorite
        case Recipe.difficulty:
            return self.difficulty.rawValue
        case Recipe.inverted:
            return self.inverted
        case Recipe.times:
            return (self.times as NSDecimalNumber?)?.doubleValue
        case Recipe.date:
            return self.date
        case Recipe.imageData:
            return self.imageData?.base64EncodedString()
        default:
            return nil
        }
    }
    
    /// initalizer from database
    init(row: ReadRow) throws {
        self.id = try row.get(Recipe.id)
        self.name = try row.get(Recipe.name)
        self.info = try row.get(Recipe.info)
        self.isFavorite = try row.get(Recipe.isFavorite)
        
        let difficultyNumber = try row.get(Recipe.difficulty) ?? 0
        self.difficulty = Difficulty(rawValue: difficultyNumber) ?? .easy
        
        self.inverted = try row.get(Recipe.inverted)
        
        if let timesDouble = try? row.get(Recipe.times) ?? 1.0 {
        self.times = Decimal(timesDouble)
        } else {
            self.times = nil
            
        }
        
        self.date = try row.get(Recipe.date)
        let imageText = try row.get(Recipe.imageData) ?? ""
        self.imageData = Data(base64Encoded: imageText)
    }
    
}

//    enum CodingKeys: CodingKey {
//        case name
//        case info
//        case steps
//        case inverted
//        case running
//        case dateString
//        case isFavourite
//        case imageString
//        case difficulty
//        case times
//        case id
//    }

//    public static func == (lhs: Recipe, rhs: Recipe) -> Bool {
//        return lhs.name == rhs.name &&
//            lhs.info == rhs.info &&
//            lhs.steps == rhs.steps &&
//            lhs.inverted == rhs.inverted &&
//            lhs.isFavourite == rhs.isFavourite &&
//            lhs.difficulty == rhs.difficulty &&
//            lhs.times == rhs.times &&
//            lhs.imageString == rhs.imageString &&
//            lhs.running == rhs.running &&
//            lhs.dateString == rhs.dateString
//    }
