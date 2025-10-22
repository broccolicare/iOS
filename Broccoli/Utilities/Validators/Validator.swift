//
//  Validator.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 14/10/25.
//


import Foundation

enum Validator {
    static func isValidEmail(_ input: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return input.range(of: pattern, options: .regularExpression) != nil
    }
    
    static func isValidPassword(_ input: String) -> Bool {
        return input.count >= 8
    }
}
