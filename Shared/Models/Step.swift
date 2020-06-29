//
//  Step.swift
//  BrotApp2
//
//  Created by Moritz Schaub on 29.09.19.
//  Copyright © 2019 Moritz Schaub. All rights reserved.
//

import Foundation

struct Step: Equatable, Identifiable, Hashable, Codable {

    var id: String
    
    var time : TimeInterval
    
    var name: String
    
    var ingredients: [Ingredient]
    
    var temperature : Int
    
    var notes: String
    
    var subSteps: [Step]
    
    var isDynamicTemperature: Bool {
        willSet {
            secondTemp = temperature
        }
    }
    
    var secondTemp: Int
    
    init(name: String, time: TimeInterval, ingredients: [Ingredient] = [] , themperature: Int = 20, notes: String = "") {
        self.id = UUID().uuidString
        self.time = time
        self.name = name
        self.ingredients = ingredients
        self.temperature = themperature
        self.notes = notes
        self.subSteps = []
        self.isDynamicTemperature = false
        self.secondTemp = temperature
    }
    
    var formattedTime: String{
        "\(Int(time/60))" + "\(time == 60 ? " Minute" : " Minuten" )"
    }
    
    var formattedTemp: String{
        if isDynamicTemperature {
            return "Beginn: \(temperature) ºC, Ende: \(secondTemp) °C"
        } else {
            return String(self.temperature) + " °C"
        }
    }
    
    var formattedName: String {
        name.trimmingCharacters(in: .whitespaces).isEmpty ? "unbenannter Schritt" : name
    }
    
    var totalAmount: Double{
        var amount = 0.0
        for ingredient in self.ingredients{
            amount += ingredient.amount
        }
        return amount
    }
    
    var totalFormattedAmount: String{
        Ingredient.formattedAmount(for: self.totalAmount)
    }
    
    
    ///Themperature for bulk liquids so the step has the right Temperature
    func themperature(for bulkLiquid: Ingredient, roomThemperature: Int) -> Int {
        
        var summOfMassTempProductOfNonBulkLiquids = 0.0
        
        for ingredient in self.ingredients{
            if !ingredient.isBulkLiquid{
                summOfMassTempProductOfNonBulkLiquids += ingredient.amount * Double(roomThemperature)
            }
        }
        var totalAmount = self.totalAmount
        for substep in subSteps{
            summOfMassTempProductOfNonBulkLiquids += substep.totalAmount * Double(isDynamicTemperature ? substep.secondTemp : substep.temperature)
            totalAmount += substep.totalAmount
        }
        
        let diff = Double(self.temperature) * totalAmount - summOfMassTempProductOfNonBulkLiquids
        if bulkLiquid.amount != 0{
            return Int( diff / bulkLiquid.amount)
        } else {
            return 0
        }
        
    }
    
    func text(startDate: Date, roomTemp: Int, scaleFactor: Double) -> String{
        var text = ""
        text += "\(self.name) am \(dateFormatter.string(from: startDate))"
        text += "\n"
        
        for ingredient in self.ingredients{
            text += ingredient.name + ": " + ingredient.scaledFormattedAmount(with: scaleFactor) + " \(ingredient.isBulkLiquid ? String(self.themperature(for: ingredient, roomThemperature: roomTemp)) + "° C" : "" )"
            text += "\n"
        }
        for subStep in self.subSteps{
            text += subStep.name + ": " + "\(self.totalAmount)" + "\(subStep.temperature)" + "° C"
            text += "\n"
        }
        if !self.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty{
            text += self.notes
            text += "\n"
        }
        return text
    }
    
    //MARK: init from Json and ==
    
    enum CodingKeys: CodingKey{
        case time
        case name
        case ingredients
        case temperature
        case notes
        case subSteps
        case isDynamicTemperature
        case secondTemp
        case id
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.time = try container.decode(TimeInterval.self, forKey: .time)
        self.name = try container.decode(String.self, forKey: .name)
        self.ingredients = try container.decode([Ingredient].self, forKey: .ingredients)
        self.temperature = try container.decode(Int.self, forKey: .temperature)
        self.notes = try container.decode(String.self, forKey: .notes)
        self.subSteps = try container.decode([Step].self, forKey: .subSteps)
        self.isDynamicTemperature = try container.decode(Bool.self, forKey: .isDynamicTemperature)
        self.secondTemp = try container.decode(Int.self, forKey: .secondTemp)
    }
    
    static func == (lhs: Step, rhs: Step) -> Bool {
        return lhs.name == rhs.name &&
            lhs.time == rhs.time &&
            lhs.ingredients == rhs.ingredients &&
            lhs.temperature == rhs.temperature &&
            lhs.notes == rhs.notes &&
            lhs.subSteps == rhs.subSteps &&
            lhs.isDynamicTemperature == rhs.isDynamicTemperature &&
            lhs.secondTemp == rhs.secondTemp
    }

}
