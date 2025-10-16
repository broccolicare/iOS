//
//  String+Extensions.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 15/10/25.
//

import Foundation

extension String {
    /// Converts the string to lowercase (similar to JS `.toLowerCase()`).
    func toLowerCase() -> String {
        return self.lowercased()
    }
    
    /// Converts the string to uppercase (for symmetry).
    func toUpperCase() -> String {
        return self.uppercased()
    }
}
