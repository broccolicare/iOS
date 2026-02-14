//
//  SearchHistoryManager.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 14/02/26.
//

import Foundation

/// Manages search history for services using UserDefaults
struct SearchHistoryManager {
    
    // MARK: - Constants
    
    private static let key = "recentServiceSearches"
    private static let maxHistoryCount = 6
    
    // MARK: - Public Methods
    
    /// Save a service ID to search history (most recent first)
    static func saveSearch(serviceId: Int) {
        var history = getRecentSearches()
        
        // Remove existing entry if present
        history.removeAll { $0 == serviceId }
        
        // Add to front
        history.insert(serviceId, at: 0)
        
        // Keep only last 6 searches
        if history.count > maxHistoryCount {
            history = Array(history.prefix(maxHistoryCount))
        }
        
        // Save to UserDefaults
        UserDefaults.standard.set(history, forKey: key)
    }
    
    /// Get recent search service IDs (most recent first)
    static func getRecentSearches() -> [Int] {
        return UserDefaults.standard.array(forKey: key) as? [Int] ?? []
    }
    
    /// Clear all search history
    static func clearHistory() {
        UserDefaults.standard.removeObject(forKey: key)
    }
    
    /// Check if history exists
    static func hasHistory() -> Bool {
        return !getRecentSearches().isEmpty
    }
}
