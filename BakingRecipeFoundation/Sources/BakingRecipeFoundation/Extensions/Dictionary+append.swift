//
//  Dictionary+append.swift
//  BakingRecipe
//
//  Created by Moritz Schaub on 14.09.20.
//

import Foundation

extension Dictionary {
    mutating func append(_ value: Value, forKey key: Key) {
        self[key] = value
    }
    
    mutating func append(contentsOf dictionary: Dictionary) {
        for (key, value) in dictionary {
            self.append(value, forKey: key)
        }
    }
}