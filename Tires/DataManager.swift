//
//  DataManager.swift
//  Tires
//
//  Created on 04.11.2025.
//

import Foundation
import SwiftUI
import Combine

class DataManager: ObservableObject {
    @Published var tires: [Tire] = []
    @Published var sales: [Sale] = []
    @Published var selectedPeriod: AnalyticsPeriod = .month
    
    // Ключи для UserDefaults
    private let tiresKey = "tires_data"
    private let salesKey = "sales_data"
    
    init() {
        loadData()
    }
    
    // MARK: - Tire Management
    func addTire(_ tire: Tire) {
        tires.append(tire)
        saveData()
    }
    
    func updateTire(_ tire: Tire) {
        if let index = tires.firstIndex(where: { $0.id == tire.id }) {
            tires[index] = tire
            saveData()
        }
    }
    
    func deleteTire(_ tire: Tire) {
        tires.removeAll { $0.id == tire.id }
        saveData()
    }
    
    func updateTireQuantity(_ tire: Tire, newQuantity: Int) {
        if let index = tires.firstIndex(where: { $0.id == tire.id }) {
            tires[index].quantity = max(0, newQuantity)
            saveData()
        }
    }
    
    // MARK: - Sales Management
    func addSale(_ sale: Sale) {
        sales.append(sale)
        // Decrease stock quantity
        if let index = tires.firstIndex(where: { $0.id == sale.tire.id }) {
            tires[index].quantity = max(0, tires[index].quantity - sale.quantity)
        }
        saveData()
    }
    
    // MARK: - Analytics
    
    // Get date range for period filtering
    private func getDateRange(for period: AnalyticsPeriod) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        let end = now
        
        let start: Date
        switch period {
        case .month:
            start = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .quarter:
            start = calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .year:
            start = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
        
        return (start, end)
    }
    
    // Top 3 sales for the month
    func getTop3Sales() -> [(tire: Tire, totalQuantity: Int, channels: [SalesChannel])] {
        let dateRange = getDateRange(for: .month)
        let monthSales = sales.filter { $0.date >= dateRange.start && $0.date <= dateRange.end }
        
        // Group by tire ID
        var salesByTire: [UUID: (tire: Tire, quantity: Int, channels: Set<SalesChannel>)] = [:]
        
        for sale in monthSales {
            if var existing = salesByTire[sale.tire.id] {
                existing.quantity += sale.quantity
                existing.channels.insert(sale.channel)
                salesByTire[sale.tire.id] = existing
            } else {
                salesByTire[sale.tire.id] = (tire: sale.tire, quantity: sale.quantity, channels: [sale.channel])
            }
        }
        
        // Sort and take top 3
        let sorted = salesByTire.values.sorted { $0.quantity > $1.quantity }
        return Array(sorted.prefix(3)).map { ($0.tire, $0.quantity, Array($0.channels)) }
    }
    
    // Get inventory sorted by quantity (ascending)
    func getTiresSortedByQuantity() -> [Tire] {
        return tires.sorted { $0.quantity < $1.quantity }
    }
    
    // Analytics by brand
    func getSalesByBrand(period: AnalyticsPeriod) -> [String: Int] {
        let dateRange = getDateRange(for: period)
        let filteredSales = sales.filter { $0.date >= dateRange.start && $0.date <= dateRange.end }
        
        var result: [String: Int] = [:]
        for sale in filteredSales {
            result[sale.tire.brand, default: 0] += sale.quantity
        }
        return result
    }
    
    // Analytics by model (for selected brand)
    func getSalesByModel(brand: String, period: AnalyticsPeriod) -> [String: Int] {
        let dateRange = getDateRange(for: period)
        let filteredSales = sales.filter {
            $0.date >= dateRange.start &&
            $0.date <= dateRange.end &&
            $0.tire.brand == brand
        }
        
        var result: [String: Int] = [:]
        for sale in filteredSales {
            result[sale.tire.model, default: 0] += sale.quantity
        }
        return result
    }
    
    // Analytics by radius
    func getSalesByRadius(period: AnalyticsPeriod) -> [String: Int] {
        let dateRange = getDateRange(for: period)
        let filteredSales = sales.filter { $0.date >= dateRange.start && $0.date <= dateRange.end }
        
        var result: [String: Int] = [:]
        for sale in filteredSales {
            let key = "R\(sale.tire.radius)"
            result[key, default: 0] += sale.quantity
        }
        return result
    }
    
    // Analytics by sales channel
    func getSalesByChannel(period: AnalyticsPeriod) -> [SalesChannel: Int] {
        let dateRange = getDateRange(for: period)
        let filteredSales = sales.filter { $0.date >= dateRange.start && $0.date <= dateRange.end }
        
        var result: [SalesChannel: Int] = [:]
        for sale in filteredSales {
            result[sale.channel, default: 0] += sale.quantity
        }
        return result
    }
    
    // Get all unique brands from warehouse
    func getAllBrands() -> [String] {
        let uniqueBrands = Set(tires.map { $0.brand })
        return Array(uniqueBrands).sorted()
    }
    
    // Get all unique models for a brand
    func getAllModels(for brand: String) -> [String] {
        let models = tires.filter { $0.brand == brand }.map { $0.model }
        return Array(Set(models)).sorted()
    }
    
    // MARK: - Settings
    func deleteTopData() {
        // Delete top sales data (last month)
        let dateRange = getDateRange(for: .month)
        sales.removeAll { $0.date >= dateRange.start && $0.date <= dateRange.end }
        saveData()
    }
    
    func deleteAllData() {
        tires.removeAll()
        sales.removeAll()
        saveData()
    }
    
    // MARK: - Save/Load
    private func saveData() {
        if let tiresData = try? JSONEncoder().encode(tires) {
            UserDefaults.standard.set(tiresData, forKey: tiresKey)
        }
        
        if let salesData = try? JSONEncoder().encode(sales) {
            UserDefaults.standard.set(salesData, forKey: salesKey)
        }
    }
    
    private func loadData() {
        if let tiresData = UserDefaults.standard.data(forKey: tiresKey),
           let decodedTires = try? JSONDecoder().decode([Tire].self, from: tiresData) {
            tires = decodedTires
        }
        
        if let salesData = UserDefaults.standard.data(forKey: salesKey),
           let decodedSales = try? JSONDecoder().decode([Sale].self, from: salesData) {
            sales = decodedSales
        }
    }
}

