//
//  TireAnalyticsView.swift
//  Tires
//
//  Created on 04.11.2025.
//

import SwiftUI
import Charts

struct TireAnalyticsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedType: TireAnalyticsType = .brand
    @State private var selectedBrand: String = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Period selector
                    Picker("Period", selection: $dataManager.selectedPeriod) {
                        ForEach(AnalyticsPeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Analytics type selector
                    Picker("Type", selection: $selectedType) {
                        ForEach(TireAnalyticsType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Chart based on selected type
                    switch selectedType {
                    case .brand:
                        BrandPieChart(period: dataManager.selectedPeriod, onBrandSelected: { brand in
                            selectedBrand = brand
                            selectedType = .model
                        })
                        
                    case .model:
                        if selectedBrand.isEmpty {
                            // If no brand selected, select first available
                            let allBrands = dataManager.getAllBrands()
                            if let firstBrand = allBrands.first {
                                ModelPieChart(brand: firstBrand, period: dataManager.selectedPeriod)
                                    .onAppear {
                                        selectedBrand = firstBrand
                                    }
                            } else {
                                EmptyChartView(message: "No brands in warehouse")
                            }
                        } else {
                            VStack(spacing: 12) {
                                // Brand selection - show all brands from warehouse
                                Menu {
                                    ForEach(dataManager.getAllBrands(), id: \.self) { brand in
                                        Button(brand) {
                                            selectedBrand = brand
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text("Brand: \(selectedBrand)")
                                            .font(.headline)
                                        Image(systemName: "chevron.down")
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                                }
                                .padding(.horizontal)
                                
                                ModelPieChart(brand: selectedBrand, period: dataManager.selectedPeriod)
                            }
                        }
                        
                    case .radius:
                        RadiusPieChart(period: dataManager.selectedPeriod)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Tire Analytics")
        }
    }
}

// Pie chart by brands
struct BrandPieChart: View {
    @EnvironmentObject var dataManager: DataManager
    let period: AnalyticsPeriod
    let onBrandSelected: (String) -> Void
    
    var data: [String: Int] {
        dataManager.getSalesByBrand(period: period)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sales by Brand")
                .font(.title2)
                .bold()
                .padding(.horizontal)
            
            if data.isEmpty {
                EmptyChartView(message: "No sales data")
            } else {
                if #available(iOS 16.0, *) {
                    Chart {
                        ForEach(Array(data.sorted(by: { $0.value > $1.value })), id: \.key) { item in
                            SectorMark(
                                angle: .value("Quantity", item.value),
                                innerRadius: .ratio(0.5),
                                angularInset: 2
                            )
                            .foregroundStyle(by: .value("Brand", item.key))
                            .annotation(position: .overlay) {
                                Text("\(item.value)")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .bold()
                            }
                        }
                    }
                    .frame(height: 300)
                    .padding(.horizontal)
                    
                    // Legend
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
                        ForEach(Array(data.sorted(by: { $0.value > $1.value })), id: \.key) { item in
                            Button(action: {
                                onBrandSelected(item.key)
                            }) {
                                HStack {
                                    Circle()
                                        .fill(Color.accentColor)
                                        .frame(width: 12, height: 12)
                                    Text(item.key)
                                        .font(.caption)
                                    Spacer()
                                    Text("\(item.value) pcs.")
                                        .font(.caption)
                                        .bold()
                                }
                                .foregroundColor(.primary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

// Pie chart by models
struct ModelPieChart: View {
    @EnvironmentObject var dataManager: DataManager
    let brand: String
    let period: AnalyticsPeriod
    
    var data: [String: Int] {
        dataManager.getSalesByModel(brand: brand, period: period)
    }
    
    var availableModels: [String] {
        dataManager.getAllModels(for: brand)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sales by Model")
                .font(.title2)
                .bold()
                .padding(.horizontal)
            
            if data.isEmpty {
                VStack(spacing: 12) {
                    EmptyChartView(message: "No sales data for \(brand)")
                    
                    // Show available models even without sales
                    if !availableModels.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Available models in warehouse:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            ForEach(availableModels, id: \.self) { model in
                                HStack {
                                    Circle()
                                        .fill(Color.secondary)
                                        .frame(width: 8, height: 8)
                                    Text(model)
                                        .font(.caption)
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding()
                        .background(Color(UIColor.tertiarySystemBackground))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                }
            } else {
                if #available(iOS 16.0, *) {
                    Chart {
                        ForEach(Array(data.sorted(by: { $0.value > $1.value })), id: \.key) { item in
                            SectorMark(
                                angle: .value("Quantity", item.value),
                                innerRadius: .ratio(0.5),
                                angularInset: 2
                            )
                            .foregroundStyle(by: .value("Model", item.key))
                            .annotation(position: .overlay) {
                                Text("\(item.value)")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .bold()
                            }
                        }
                    }
                    .frame(height: 300)
                    .padding(.horizontal)
                    
                    // Legend
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
                        ForEach(Array(data.sorted(by: { $0.value > $1.value })), id: \.key) { item in
                            HStack {
                                Circle()
                                    .fill(Color.accentColor)
                                    .frame(width: 12, height: 12)
                                Text(item.key)
                                    .font(.caption)
                                Spacer()
                                Text("\(item.value) pcs.")
                                    .font(.caption)
                                    .bold()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

// Pie chart by radius
struct RadiusPieChart: View {
    @EnvironmentObject var dataManager: DataManager
    let period: AnalyticsPeriod
    
    var data: [String: Int] {
        dataManager.getSalesByRadius(period: period)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sales by Radius")
                .font(.title2)
                .bold()
                .padding(.horizontal)
            
            if data.isEmpty {
                EmptyChartView(message: "No sales data")
            } else {
                if #available(iOS 16.0, *) {
                    Chart {
                        ForEach(Array(data.sorted(by: { $0.value > $1.value })), id: \.key) { item in
                            SectorMark(
                                angle: .value("Quantity", item.value),
                                innerRadius: .ratio(0.5),
                                angularInset: 2
                            )
                            .foregroundStyle(by: .value("Radius", item.key))
                            .annotation(position: .overlay) {
                                Text("\(item.value)")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .bold()
                            }
                        }
                    }
                    .frame(height: 300)
                    .padding(.horizontal)
                    
                    // Legend
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                        ForEach(Array(data.sorted(by: { $0.key < $1.key })), id: \.key) { item in
                            HStack {
                                Circle()
                                    .fill(Color.accentColor)
                                    .frame(width: 12, height: 12)
                                Text(item.key)
                                    .font(.caption)
                                Spacer()
                                Text("\(item.value) pcs.")
                                    .font(.caption)
                                    .bold()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

// Empty state for charts
struct EmptyChartView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.pie")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
    }
}

#Preview {
    TireAnalyticsView()
        .environmentObject(DataManager())
}
